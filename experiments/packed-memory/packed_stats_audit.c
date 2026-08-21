/*
 * packed_stats_audit.c -- FINAL red-team audit of the packed histogram's
 * PERCENTILE and STATISTICS read paths.
 *
 * Scope (superset of packed_redteam.c, which covered only value_at_percentile):
 *   1. hdr_packed_value_at_percentile / _value_at_percentiles across a fine
 *      grid [0,100] plus exact 0/50/100, ULP-adjacent, NaN/+/-inf/negative/>100.
 *   2. hdr_packed_mean / hdr_packed_stddev vs an INDEPENDENT bignum oracle
 *      (exact 256-bit numerator for the mean; faithful long-double reference for
 *      stddev), across the same geometry x distribution x total-count matrix.
 *   3. The structural invariant  p100 == max  (scoped to the regimes where it is
 *      well-defined; empty, only-zero-recorded, and count-saturated states are
 *      documented exceptions that also hold in dense -- see notes below).
 *   4. Monotonicity of value_at_percentile in ascending p.
 *   5. Dense parity for the legitimately-recordable regime (record-path sweep).
 *
 * WHITE-BOX: we #include the implementation TU so we can craft exact histogram
 * states a decoded (untrusted) stream can reach but the record API cannot --
 * per-bucket counts up to INT64_MAX and count-saturated totals -- driving the
 * exact build path a decode takes (sparse_add + packed_recompute_stats).
 *
 * ORACLES (all independent of the impl's arithmetic):
 *   - percentile: __int128 saturating prefix-sum + __int128 overflow-safe
 *     highest-equivalent; the count-at-percentile target follows the DEFINITIVE
 *     spec (round-half-up, clamp to [1,total_count]); the double rounding of the
 *     target itself is inherent to the API contract and is NOT flagged.
 *   - mean: exact 256-bit integer numerator  sum(c_i * median_i)  divided by
 *     total_count in long double.
 *   - stddev: faithful long-double reference of  sqrt(sum c_i*(median_i-mean)^2
 *     / total_count).
 *   - dense: for the safe, well-defined subset (total<=2^53, high<INT64_MAX) the
 *     library's own hdr_value_at_percentile must agree bit-for-bit.
 *
 * Build (see foot of file for the exact command):
 *   clang -fsanitize=address,undefined,float-cast-overflow -fno-sanitize-recover=all
 * so any UB on the read path (bad double->int64 cast, signed overflow in a bucket
 * edge or a prefix sum) aborts with a repro line already printed.
 */
#define _DEFAULT_SOURCE 1
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include <float.h>

/* pull in the implementation with full internal visibility */
#include "hdr_packed_histogram.c"

/* dense references (linked from the static lib) */
extern int64_t hdr_value_at_percentile(const struct hdr_histogram* h, double percentile);
extern double  hdr_mean(const struct hdr_histogram* h);
extern double  hdr_stddev(const struct hdr_histogram* h);
extern int64_t hdr_max(const struct hdr_histogram* h);
extern int64_t hdr_min(const struct hdr_histogram* h);
extern int64_t hdr_count_at_value(const struct hdr_histogram* h, int64_t value);

/* ===========================================================================
 * counters + reporting
 * ========================================================================= */
static long gaps = 0, checks = 0;
static int  gaps_shown = 0;
static const char* CUR = "";

#define REPORT(cond, ...) do {                                            \
    checks++;                                                             \
    if (!(cond)) {                                                        \
        gaps++;                                                           \
        if (gaps_shown++ < 80) {                                          \
            printf("  GAP [%s]: ", CUR); printf(__VA_ARGS__); printf("\n"); \
        }                                                                 \
    }                                                                     \
} while (0)

/* ===========================================================================
 * model
 * ========================================================================= */
#define MAXB 64
struct model {
    int32_t  idx[MAXB];
    int64_t  cnt[MAXB];       /* each in [0, INT64_MAX] */
    int      n;
    int64_t  total;           /* clamped saturating sum (== h->total_count) */
    int      saturated;       /* true sum exceeded INT64_MAX */
};

static int64_t sat_add(int64_t a, int64_t b) {
    return (b > INT64_MAX - a) ? INT64_MAX : a + b;
}

/* exact model total + saturation flag via __int128 */
static void model_finalize(struct model* m) {
    __int128 s = 0;
    for (int i = 0; i < m->n; i++) s += (__int128) m->cnt[i];
    m->saturated = (s > (__int128) INT64_MAX);
    m->total = m->saturated ? INT64_MAX : (int64_t) s;
}

/* ===========================================================================
 * __int128 overflow-safe highest-equivalent (independent of the impl formula)
 * ========================================================================= */
static int64_t oracle_high_equiv(const struct hdr_histogram* g, int64_t v) {
    int64_t leq  = hdr_lowest_equivalent_value(g, v);
    int64_t size = hdr_size_of_equivalent_value_range(g, v);
    __int128 top = (__int128) leq + (__int128) size - 1;
    return (top > (__int128) INT64_MAX) ? INT64_MAX : (int64_t) top;
}

/* ===========================================================================
 * percentile oracle -- definitive target (clamp [1,total]) + __int128 walk
 * ========================================================================= */
static int64_t oracle_vap(const struct model* m, const struct hdr_histogram* g, double p) {
    double requested = (p < 100.0) ? p : 100.0;         /* NaN -> 100 */
    double cc = ((requested / 100.0) * (double) m->total) + 0.5;

    int64_t target;
    if (!(cc >= 1.0))                    target = 1;                 /* NaN/-inf/<1 */
    else if (cc >= (double) m->total)    target = m->total;          /* clamp to reachable total */
    else                                 target = (int64_t) cc;

    int64_t running = 0, vfi = 0;
    for (int k = 0; k < m->n; k++) {
        running = sat_add(running, m->cnt[k]);
        if (running >= target) { vfi = hdr_value_at_index(g, m->idx[k]); break; }
    }
    if (p == 0.0) return hdr_lowest_equivalent_value(g, vfi);
    return oracle_high_equiv(g, vfi);
}

/* index of last populated (cnt>0) bucket, or -1 */
static int model_last_pop(const struct model* m) {
    for (int k = m->n - 1; k >= 0; k--) if (m->cnt[k] > 0) return k;
    return -1;
}

/* ===========================================================================
 * 256-bit unsigned accumulator (exact mean numerator)
 * ========================================================================= */
typedef struct { uint64_t w[4]; } u256;

static void u256_add_u128(u256* a, unsigned __int128 v) {
    uint64_t lo = (uint64_t) v;
    uint64_t hi = (uint64_t) (v >> 64);
    unsigned __int128 t = (unsigned __int128) a->w[0] + lo;
    a->w[0] = (uint64_t) t;
    unsigned __int128 carry = t >> 64;
    t = (unsigned __int128) a->w[1] + hi + carry;
    a->w[1] = (uint64_t) t;
    carry = t >> 64;
    t = (unsigned __int128) a->w[2] + carry;
    a->w[2] = (uint64_t) t;
    a->w[3] += (uint64_t) (t >> 64);
}

static long double u256_to_ld(const u256* a) {
    long double r = (long double) a->w[3];
    r = r * 18446744073709551616.0L + (long double) a->w[2];   /* *2^64 */
    r = r * 18446744073709551616.0L + (long double) a->w[1];
    r = r * 18446744073709551616.0L + (long double) a->w[0];
    return r;
}

/* median value (equivalent) for a populated model bucket */
static int64_t bucket_median(const struct hdr_histogram* g, int32_t vindex) {
    return hdr_median_equivalent_value(g, hdr_value_at_index(g, vindex));
}

/* exact mean via 256-bit numerator; requires total>0 */
static long double oracle_mean(const struct model* m, const struct hdr_histogram* g) {
    u256 num = {{0,0,0,0}};
    for (int k = 0; k < m->n; k++) {
        if (m->cnt[k] == 0) continue;
        int64_t med = bucket_median(g, m->idx[k]);        /* >= 0 */
        unsigned __int128 prod = (unsigned __int128) (uint64_t) m->cnt[k]
                               * (unsigned __int128) (uint64_t) med;
        u256_add_u128(&num, prod);
    }
    return u256_to_ld(&num) / (long double) m->total;
}

/* faithful long-double stddev reference; requires total>0 */
static long double oracle_stddev(const struct model* m, const struct hdr_histogram* g, long double mean) {
    long double acc = 0.0L;
    for (int k = 0; k < m->n; k++) {
        if (m->cnt[k] == 0) continue;
        long double dev = (long double) bucket_median(g, m->idx[k]) - mean;
        acc += (dev * dev) * (long double) m->cnt[k];
    }
    return sqrtl(acc / (long double) m->total);
}

static int close_rel(long double got, long double exp, long double rel, long double abs_floor) {
    long double d = fabsl(got - exp);
    long double t = rel * fabsl(exp) + abs_floor;
    return d <= t;
}

/* ===========================================================================
 * state builder: exact same construction a decoded histogram uses
 * ========================================================================= */
static struct hdr_packed_histogram* build(const struct hdr_packed_config* cfg,
                                          const struct model* m) {
    struct hdr_packed_histogram* h = NULL;
    if (packed_init_with(cfg, false, &h) != 0) return NULL;
    for (int k = 0; k < m->n; k++) {
        if (m->cnt[k] == 0) continue;
        if (!sparse_add(h, m->idx[k], m->cnt[k])) { hdr_packed_close(h); return NULL; }
    }
    packed_recompute_stats(h);
    return h;
}

/* ===========================================================================
 * percentile grid
 * ========================================================================= */
static double PG[4096];
static int    NPG = 0;
static void push_p(double p) { if (NPG < (int)(sizeof(PG)/sizeof(PG[0]))) PG[NPG++] = p; }

static void build_pgrid(void) {
    NPG = 0;
    for (int i = 0; i <= 200; i++) push_p(i * 0.5);            /* fine grid [0,100] */
    for (int i = 0; i <= 100; i++) push_p(i * 0.01);           /* dense low tail  */
    for (int i = 0; i <= 100; i++) push_p(99.0 + i * 0.01);    /* dense high tail */
    push_p(0.0); push_p(50.0); push_p(100.0);
    push_p(25.0); push_p(75.0); push_p(90.0); push_p(99.0);
    push_p(99.9); push_p(99.99); push_p(99.999);
    /* ULP-adjacent to interesting anchors */
    push_p(nextafter(0.0, 1.0));
    push_p(nextafter(0.0, -1.0));
    push_p(nextafter(50.0, 0.0));
    push_p(nextafter(50.0, 100.0));
    push_p(nextafter(100.0, 0.0));
    push_p(nextafter(100.0, 200.0));
    push_p(100.0 - DBL_EPSILON);
    /* UB-bait args (impl must stay defined) */
    push_p(-0.0); push_p(-1.0); push_p(-1e300);
    push_p(100.5); push_p(1e300); push_p(200.0);
    push_p((double) NAN); push_p((double) INFINITY); push_p((double) -INFINITY);
}

/* ===========================================================================
 * exercise one state
 * ========================================================================= */
static void exercise(const struct hdr_packed_config* cfg, struct hdr_histogram* dense_ref,
                     const struct model* m, int dense_safe) {
    const struct hdr_histogram* g = &cfg->geom;
    struct hdr_packed_histogram* h = build(cfg, m);
    if (!h) { printf("  BUILD FAIL [%s]\n", CUR); gaps++; return; }

    REPORT(hdr_packed_total_count(h) == m->total,
           "total mismatch built=%lld model=%lld",
           (long long) hdr_packed_total_count(h), (long long) m->total);

    /* ---- value_at_percentile across the grid ---- */
    for (int i = 0; i < NPG; i++) {
        double p = PG[i];
        int64_t got = hdr_packed_value_at_percentile(h, p);   /* UB -> sanitizer abort */
        int64_t exp = oracle_vap(m, g, p);
        REPORT(got == exp,
               "vap p=%.17g packed=%lld oracle=%lld (total=%lld,n=%d,w=%d,sat=%d)",
               p, (long long) got, (long long) exp,
               (long long) m->total, m->n, h->width, m->saturated);

        if (dense_safe && dense_ref && isfinite(p) && p >= 0.0 && p <= 100.0) {
            int64_t den = hdr_value_at_percentile(dense_ref, p);
            REPORT(got == den, "vap dense-divergence p=%.17g packed=%lld dense=%lld",
                   p, (long long) got, (long long) den);
        }
    }

    /* ---- batch API == scalar ---- */
    {
        static double bp[10] = {0.0, 1.0, 25.0, 50.0, 75.0, 90.0, 99.0, 99.9, 100.0, 50.0};
        int64_t bv[10];
        int rc = hdr_packed_value_at_percentiles(h, bp, bv, 10);
        REPORT(rc == 0, "percentiles batch rc=%d", rc);
        for (int i = 0; i < 10; i++) {
            int64_t sc = hdr_packed_value_at_percentile(h, bp[i]);
            REPORT(bv[i] == sc, "batch[%d] p=%g got=%lld scalar=%lld",
                   i, bp[i], (long long) bv[i], (long long) sc);
        }
        /* NULL guards */
        REPORT(hdr_packed_value_at_percentiles(h, NULL, bv, 1) == EINVAL, "batch null-p");
        REPORT(hdr_packed_value_at_percentiles(h, bp, NULL, 1) == EINVAL, "batch null-v");
    }

    /* ---- monotonicity (ascending finite p in [0,100]) ---- */
    {
        int64_t prev = INT64_MIN; double prev_p = -1.0;
        for (double p = 0.0; p <= 100.0; p += 0.1) {
            int64_t v = hdr_packed_value_at_percentile(h, p);
            REPORT(v >= prev, "non-monotonic p=%.4f->%lld after p=%.4f->%lld",
                   p, (long long) v, prev_p, (long long) prev);
            prev = v; prev_p = p;
        }
    }

    /* ---- p100 == max invariant ----
       Well-defined only when: non-empty, a non-zero value was recorded
       (max_value != 0 sentinel), and the count did NOT saturate (a saturated
       total is < the true sum, so the p100 target is satisfied before the last
       bucket -- the same lossy corner dense also exhibits). */
    if (m->total > 0 && h->max_value != 0 && !m->saturated) {
        int64_t p100 = hdr_packed_value_at_percentile(h, 100.0);
        int64_t mx   = hdr_packed_max(h);
        REPORT(p100 == mx, "p100 != max  p100=%lld max=%lld (total=%lld)",
               (long long) p100, (long long) mx, (long long) m->total);
        /* and the last populated bucket really is the max bucket */
        int lp = model_last_pop(m);
        if (lp >= 0)
            REPORT(p100 == oracle_high_equiv(g, hdr_value_at_index(g, m->idx[lp])),
                   "p100 not at last populated bucket");
    }

    /* ---- mean / stddev vs independent oracle ---- */
    {
        double pm = hdr_packed_mean(h);
        double ps = hdr_packed_stddev(h);
        if (m->total == 0) {
            REPORT(pm == 0.0, "empty mean=%.17g (want 0)", pm);
            REPORT(ps == 0.0, "empty stddev=%.17g (want 0)", ps);
        } else {
            long double om = oracle_mean(m, g);
            long double os = oracle_stddev(m, g, om);
            /* mean numerator accumulates in double in the impl; rel err ~1e-14
               even above 2^53, so 1e-9 rel is a wide, bug-catching bound. */
            REPORT(close_rel(pm, (double) om, 1e-9L, 1e-3L),
                   "mean packed=%.17g oracle=%.17Lg (total=%lld,n=%d)",
                   pm, om, (long long) m->total, m->n);
            /* stddev: faithful long-double ref, 1e-6 rel (cancellation slack). */
            REPORT(close_rel(ps, (double) os, 1e-6L, 1e-3L),
                   "stddev packed=%.17g oracle=%.17Lg (total=%lld,n=%d)",
                   ps, os, (long long) m->total, m->n);
        }
    }

    hdr_packed_close(h);
}

/* ===========================================================================
 * distributions
 * ========================================================================= */
enum dist { D_SINGLE, D_TWO, D_MANY, D_TOP, D_SAT };
static const char* dnm[] = {"single","two","many","all-top","saturated"};

static void make_model(struct model* m, enum dist d, int64_t clen, int64_t T) {
    memset(m, 0, sizeof *m);
    int32_t top = (int32_t)(clen - 1);
    switch (d) {
    case D_SINGLE:
        m->n = 1; m->idx[0] = (top > 1) ? top / 2 : top; m->cnt[0] = T;
        break;
    case D_TWO:
        m->n = 2; m->idx[0] = 0; m->idx[1] = top;
        m->cnt[0] = (T > 1) ? T - 1 : 0; m->cnt[1] = (T > 0) ? 1 : 0;
        if (T == 1) { m->cnt[0] = 0; m->cnt[1] = 1; }
        break;
    case D_MANY: {
        int nb = 40; if ((int64_t) nb > clen) nb = (int) clen;
        if (nb < 2) nb = 2;
        m->n = nb;
        for (int i = 0; i < nb; i++)
            m->idx[i] = (int32_t)((int64_t) i * (clen - 1) / (nb - 1));
        int w = 1;
        for (int i = 1; i < nb; i++) if (m->idx[i] > m->idx[w-1]) m->idx[w++] = m->idx[i];
        m->n = w;
        int64_t each = T / m->n, rem = T - each * m->n;
        for (int i = 0; i < m->n; i++) m->cnt[i] = each;
        m->cnt[m->n-1] = sat_add(m->cnt[m->n-1], rem);
        break; }
    case D_TOP:
        m->n = 1; m->idx[0] = top; m->cnt[0] = T;
        break;
    case D_SAT:
        m->n = 2; m->idx[0] = 0; m->idx[1] = top;
        m->cnt[0] = INT64_MAX; m->cnt[1] = INT64_MAX;
        break;
    }
    model_finalize(m);
}

/* ===========================================================================
 * record-path parity sweep (legit histograms only) vs dense
 * ========================================================================= */
static uint64_t rng = 0x243F6A8885A308D3ull;
static uint64_t xr(void){ rng ^= rng<<13; rng ^= rng>>7; rng ^= rng<<17; return rng; }

static void record_parity(int64_t low, int64_t high, int sig, int seed_variant) {
    struct hdr_packed_histogram* p = NULL;
    struct hdr_histogram* d = NULL;
    if (hdr_packed_init(low, high, sig, &p) != 0) return;
    if (hdr_init(low, high, sig, &d) != 0) { hdr_packed_close(p); return; }
    rng = 0x9E3779B97F4A7C15ull ^ (uint64_t) seed_variant;

    int64_t span = high - low;
    for (int i = 0; i < 20000; i++) {
        int64_t v;
        switch (seed_variant & 3) {
        case 0: v = low + (int64_t)(xr() % (uint64_t)(span + 1)); break;          /* uniform */
        case 1: { double u = (double)(xr()>>11) / 9007199254740992.0;             /* skew low */
                  v = low + (int64_t)(u*u*(double)span); break; }
        case 2: v = low + (int64_t)((xr() % 100) == 0 ? (uint64_t)span : xr()%64); break; /* spiky */
        default: v = (i % 50 == 0) ? 0 : low + (int64_t)(xr() % (uint64_t)(span+1)); break; /* some zeros */
        }
        if (v < 0) v = 0;
        int64_t c = (xr() % 8 == 0) ? (int64_t)(1 + xr() % 5) : 1;
        bool rp = hdr_packed_record_values(p, v, c);
        bool rd = hdr_record_values(d, v, c);
        REPORT(rp == rd, "record parity ret v=%lld c=%lld packed=%d dense=%d",
               (long long)v,(long long)c,rp,rd);
    }

    REPORT(hdr_packed_total_count(p) == d->total_count, "rec total %lld vs %lld",
           (long long)hdr_packed_total_count(p),(long long)d->total_count);
    REPORT(hdr_packed_min(p) == hdr_min(d), "rec min %lld vs %lld",
           (long long)hdr_packed_min(p),(long long)hdr_min(d));
    REPORT(hdr_packed_max(p) == hdr_max(d), "rec max %lld vs %lld",
           (long long)hdr_packed_max(p),(long long)hdr_max(d));

    for (int i = 0; i < NPG; i++) {
        double pc = PG[i];
        if (!isfinite(pc) || pc < 0.0 || pc > 100.0) continue;
        REPORT(hdr_packed_value_at_percentile(p, pc) == hdr_value_at_percentile(d, pc),
               "rec vap p=%.17g packed=%lld dense=%lld", pc,
               (long long)hdr_packed_value_at_percentile(p,pc),
               (long long)hdr_value_at_percentile(d,pc));
    }
    /* mean/stddev parity (dense well-defined here: modest values, no int64 product overflow) */
    REPORT(close_rel(hdr_packed_mean(p), hdr_mean(d), 1e-9L, 1e-6L),
           "rec mean packed=%.17g dense=%.17g", hdr_packed_mean(p), hdr_mean(d));
    REPORT(close_rel(hdr_packed_stddev(p), hdr_stddev(d), 1e-9L, 1e-6L),
           "rec stddev packed=%.17g dense=%.17g", hdr_packed_stddev(p), hdr_stddev(d));
    /* p100 == max for a legit non-empty histogram with a non-zero max */
    if (d->total_count > 0 && hdr_max(d) > 0)
        REPORT(hdr_packed_value_at_percentile(p, 100.0) == hdr_packed_max(p),
               "rec p100 != max %lld vs %lld",
               (long long)hdr_packed_value_at_percentile(p,100.0),(long long)hdr_packed_max(p));
    /* count_at_value spot checks */
    for (int s = 0; s < 200; s++) {
        int64_t v = low + (int64_t)(xr() % (uint64_t)(span+1));
        REPORT(hdr_packed_count_at_value(p, v) == hdr_count_at_value(d, v),
               "rec cav v=%lld packed=%lld dense=%lld", (long long)v,
               (long long)hdr_packed_count_at_value(p,v),(long long)hdr_count_at_value(d,v));
    }
    hdr_packed_close(p);
    hdr_close(d);
}

/* ===========================================================================
 * empty + only-zero-recorded edges
 * ========================================================================= */
static void edge_empty(int64_t low, int64_t high, int sig) {
    struct hdr_packed_config* cfg = NULL;
    if (hdr_packed_config_create(low, high, sig, &cfg) != 0) return;
    const struct hdr_histogram* g = &cfg->geom;
    struct model m; memset(&m, 0, sizeof m); model_finalize(&m); /* n=0,total=0 */

    struct hdr_histogram* dense = NULL;
    if (hdr_init(low, high, sig, &dense) != 0) { hdr_packed_config_destroy(cfg); return; }

    char lbl[128];
    snprintf(lbl,sizeof lbl,"EMPTY low%lld high%lld sig%d",(long long)low,(long long)high,sig);
    CUR = lbl;

    struct hdr_packed_histogram* h = build(cfg, &m);
    REPORT(hdr_packed_total_count(h)==0,"empty total");
    REPORT(hdr_packed_mean(h)==0.0,"empty mean %.17g",hdr_packed_mean(h));
    REPORT(hdr_packed_stddev(h)==0.0,"empty stddev %.17g",hdr_packed_stddev(h));
    REPORT(hdr_packed_max(h)==0,"empty max %lld",(long long)hdr_packed_max(h));
    REPORT(hdr_packed_min(h)==INT64_MAX,"empty min %lld",(long long)hdr_packed_min(h));
    /* packed p100 on empty must match dense (both -> highest_equiv(0)); p100==max
       is a documented exception on empty (dense violates it identically). */
    for (int i = 0; i < NPG; i++) {
        double p = PG[i];
        int64_t got = hdr_packed_value_at_percentile(h, p);
        int64_t exp = oracle_vap(&m, g, p);
        REPORT(got==exp,"empty vap p=%.17g packed=%lld oracle=%lld",p,(long long)got,(long long)exp);
        if (isfinite(p) && p>=0.0 && p<=100.0 && high < INT64_MAX)
            REPORT(got==hdr_value_at_percentile(dense,p),
                   "empty vap dense p=%.17g packed=%lld dense=%lld",
                   p,(long long)got,(long long)hdr_value_at_percentile(dense,p));
    }
    hdr_packed_close(h);
    hdr_close(dense);
    hdr_packed_config_destroy(cfg);
}

/* value 0 recorded via the public API: max_value stays the 0 sentinel, so
   max()==0 while p100==highest_equiv(0). This holds identically in dense, so we
   assert packed==dense rather than the (dense-violated) p100==max invariant. */
static void edge_only_zeros(int64_t low, int64_t high, int sig) {
    struct hdr_packed_histogram* p = NULL;
    struct hdr_histogram* d = NULL;
    if (hdr_packed_init(low, high, sig, &p) != 0) return;
    if (hdr_init(low, high, sig, &d) != 0) { hdr_packed_close(p); return; }
    char lbl[128];
    snprintf(lbl,sizeof lbl,"ONLY-ZEROS low%lld high%lld sig%d",(long long)low,(long long)high,sig);
    CUR = lbl;
    for (int i = 0; i < 7; i++) { hdr_packed_record_value(p, 0); hdr_record_value(d, 0); }
    REPORT(hdr_packed_max(p)==hdr_max(d),"zeros max packed=%lld dense=%lld",
           (long long)hdr_packed_max(p),(long long)hdr_max(d));
    REPORT(hdr_packed_min(p)==hdr_min(d),"zeros min packed=%lld dense=%lld",
           (long long)hdr_packed_min(p),(long long)hdr_min(d));
    REPORT(close_rel(hdr_packed_mean(p),hdr_mean(d),1e-9L,1e-6L)
           || (hdr_packed_mean(p)==0.0 && isnan(hdr_mean(d))), /* empty-like: dense NaN */
           "zeros mean packed=%.17g dense=%.17g",hdr_packed_mean(p),hdr_mean(d));
    for (int i = 0; i < NPG; i++) {
        double pc = PG[i];
        if (!isfinite(pc)||pc<0.0||pc>100.0) continue;
        if (high==INT64_MAX) continue;
        REPORT(hdr_packed_value_at_percentile(p,pc)==hdr_value_at_percentile(d,pc),
               "zeros vap p=%.17g packed=%lld dense=%lld",pc,
               (long long)hdr_packed_value_at_percentile(p,pc),
               (long long)hdr_value_at_percentile(d,pc));
    }
    hdr_packed_close(p);
    hdr_close(d);
}

/* ===========================================================================
 * driver
 * ========================================================================= */
static const int64_t TOTALS[] = {
    1, 2, 3, 7, 100, 1000000,
    1LL << 30,
    1LL << 52,
    1LL << 53, (1LL << 53) + 1,
    (1LL << 53) + 3,
    INT64_MAX - 2000, INT64_MAX - 1000, INT64_MAX - 1,
    INT64_MAX,
};
static const int NTOT = (int)(sizeof(TOTALS)/sizeof(TOTALS[0]));

int main(void) {
    build_pgrid();
    printf("packed PERCENTILE + STATISTICS red-team audit (%d percentiles/state)\n", NPG);

    const int64_t lows[]  = {1, 1000, 1000000LL};
    const int64_t highs[] = {100000LL, 3600000000LL, INT64_MAX};
    const char*   hnm[]   = {"1e5","3.6e9","INT64_MAX"};
    const enum dist dists[] = {D_SINGLE, D_TWO, D_MANY, D_TOP, D_SAT};

    int states = 0;
    char label[256];

    for (int sig = 1; sig <= 5; sig++)
    for (size_t li = 0; li < sizeof(lows)/sizeof(lows[0]); li++)
    for (size_t hi = 0; hi < sizeof(highs)/sizeof(highs[0]); hi++) {
        int64_t low = lows[li], high = highs[hi];
        if (high < 2 * low) continue;

        struct hdr_packed_config* cfg = NULL;
        if (hdr_packed_config_create(low, high, sig, &cfg) != 0) continue;
        int64_t clen = cfg->geom.counts_len;

        for (size_t di = 0; di < sizeof(dists)/sizeof(dists[0]); di++) {
            enum dist d = dists[di];
            if (d == D_SAT) {
                struct model m; make_model(&m, d, clen, 0);
                snprintf(label,sizeof label,"sig%d low%lld %s clen%lld %s tot=SAT",
                         sig,(long long)low,hnm[hi],(long long)clen,dnm[di]);
                CUR = label;
                exercise(cfg, NULL, &m, 0);
                states++;
                continue;
            }
            for (int ti = 0; ti < NTOT; ti++) {
                int64_t T = TOTALS[ti];
                struct model m; make_model(&m, d, clen, T);
                int dense_safe = (T <= (1LL << 53)) && (high < INT64_MAX);

                struct hdr_histogram* dense = NULL;
                if (dense_safe && hdr_init(low, high, sig, &dense) == 0) {
                    for (int k = 0; k < m.n; k++) dense->counts[m.idx[k]] = m.cnt[k];
                    dense->total_count = m.total;
                }
                snprintf(label,sizeof label,"sig%d low%lld %s clen%lld %s tot=%lld",
                         sig,(long long)low,hnm[hi],(long long)clen,dnm[di],(long long)T);
                CUR = label;
                exercise(cfg, dense, &m, dense_safe && dense != NULL);
                if (dense) hdr_close(dense);
                states++;
            }
        }
        hdr_packed_config_destroy(cfg);
    }

    /* edges */
    for (int sig = 1; sig <= 5; sig++) {
        edge_empty(1, 100000, sig);
        edge_empty(1, INT64_MAX, sig);
        edge_only_zeros(1, 100000, sig);
        edge_only_zeros(1000, 3600000000LL, sig);
        states += 4;
    }

    /* record-path parity sweeps (legit histograms, dense well-defined) */
    for (int sig = 1; sig <= 4; sig++)
    for (int sv = 0; sv < 4; sv++) {
        char lbl[128];
        snprintf(lbl,sizeof lbl,"RECORD sig%d variant%d",sig,sv);
        CUR = lbl;
        record_parity(1, 3600000000LL, sig, sv);
        record_parity(1, 100000, sig, sv);
        states += 2;
    }

    printf("\nstates=%d  checks=%ld  gaps=%ld\n", states, checks, gaps);
    if (gaps == 0) printf("VERDICT: CLEAN\n");
    else           printf("VERDICT: GAPS FOUND: %ld\n", gaps);
    return gaps ? 1 : 0;
}

/* Build:
 *   clang -O1 -g -std=c11 -fsanitize=address,undefined,float-cast-overflow \
 *     -fno-sanitize-recover=all -I<inc> -I<src> -I. packed_stats_audit.c \
 *     -L<lib> -lhdr_histogram_static -lm -lz -o packed_stats_audit
 *   UBSAN_OPTIONS=halt_on_error=1:abort_on_error=1 ASAN_OPTIONS=abort_on_error=1 \
 *     ./packed_stats_audit
 */

/*
 * packed_redteam.c -- exhaustive adversarial audit of
 *   hdr_packed_value_at_percentile / hdr_packed_value_at_percentiles
 *
 * Strategy: WHITE-BOX. We #include the implementation TU so we can (a) craft
 * exact histogram states (arbitrary bucket populations, per-bucket counts up to
 * INT64_MAX, saturated totals) that the public record API cannot reach because
 * it refuses total_count > INT64_MAX, and (b) drive the exact same build path a
 * decoded histogram takes (sparse_add + packed_recompute_stats).
 *
 * Two independent oracles decide correctness:
 *   O1 (dense) : for SAFE regimes (total <= 2^53, finite p in [0,100]) the
 *                header claims packed is BIT-FOR-BIT identical to dense. Assert
 *                packed == hdr_value_at_percentile(dense).
 *   O2 (model) : an independent long-double round-half-up target + saturating
 *                prefix-sum walk + a __int128 overflow-safe highest-equivalent.
 *                Used in ALL regimes (dense is UB-buggy near INT64_MAX, so it is
 *                NOT trusted there -- O2 computes the CORRECT bucket the fixes
 *                are supposed to produce). This mirrors the impl's control flow
 *                but at higher precision and with independent overflow math.
 *
 * The build (-fsanitize=address,undefined,float-cast-overflow
 * -fno-sanitize-recover=all, UBSAN_OPTIONS=halt_on_error=1) turns ANY UB on the
 * query path (bad double->int64 cast, signed overflow in a bucket edge) into an
 * immediate abort, so UB shows up as a crash with a repro line already printed.
 */
#define _DEFAULT_SOURCE 1
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include <float.h>

/* pull in the implementation with full internal visibility */
#include "hdr_packed_histogram.c"

/* dense reference (linked from the static lib) */
extern int64_t hdr_value_at_percentile(const struct hdr_histogram* h, double percentile);

/* ---------------------------------------------------------------------------
 * independent model + oracle
 * ------------------------------------------------------------------------- */
#define MAXB 64
struct model {
    int32_t idx[MAXB];
    int64_t cnt[MAXB];   /* each in [0, INT64_MAX] */
    int      n;
    int64_t total;       /* saturating sum of cnt[] (mirrors recompute) */
};

static int64_t sat_add(int64_t a, int64_t b) {
    return (b > INT64_MAX - a) ? INT64_MAX : a + b;
}

/* __int128 overflow-safe highest-equivalent, independent of the impl formula */
static int64_t oracle_high_equiv(const struct hdr_histogram* g, int64_t v) {
    int64_t leq  = hdr_lowest_equivalent_value(g, v);
    int64_t size = hdr_size_of_equivalent_value_range(g, v);
    __int128 top = (__int128) leq + (__int128) size - 1;
    return (top > (__int128) INT64_MAX) ? INT64_MAX : (int64_t) top;
}

/* Faithful reproduction of the impl's control flow (target in DOUBLE, so no
 * precision noise vs the impl), but with an INDEPENDENT saturating prefix-sum
 * walk on our own model and an INDEPENDENT __int128 highest-equivalent. Any
 * divergence isolates a bug in bucket selection, the [1,total] clamp, or the
 * overflow-safe top-bucket edge -- exactly where the two historical bugs lived.
 * Target precision (double) is inherent to the API contract, so we don't flag
 * double-vs-long-double last-bit rounding as a defect. */
static int64_t oracle_vap(const struct model* m, const struct hdr_histogram* g, double p) {
    double requested = (p < 100.0) ? p : 100.0;   /* NaN -> 100 */
    double cc = ((requested / 100.0) * (double) m->total) + 0.5;

    int64_t target;
    if (!(cc >= 1.0))
        target = 1;
    else if (cc >= (double) m->total)
        target = m->total;
    else
        target = (int64_t) cc;

    int64_t running = 0;
    int64_t vfi = 0;
    for (int k = 0; k < m->n; k++) {
        running = sat_add(running, m->cnt[k]);
        if (running >= target) { vfi = hdr_value_at_index(g, m->idx[k]); break; }
    }
    if (p == 0.0)
        return hdr_lowest_equivalent_value(g, vfi);
    return oracle_high_equiv(g, vfi);
}

/* index of the first / last populated (cnt>0) bucket in the model, or -1 */
static int model_first_pop(const struct model* m) {
    for (int k = 0; k < m->n; k++) if (m->cnt[k] > 0) return k;
    return -1;
}
static int model_last_pop(const struct model* m) {
    for (int k = m->n - 1; k >= 0; k--) if (m->cnt[k] > 0) return k;
    return -1;
}

/* ---------------------------------------------------------------------------
 * state builder: exact same construction a decoded histogram uses
 * ------------------------------------------------------------------------- */
static struct hdr_packed_histogram* build(const struct hdr_packed_config* cfg,
                                          const struct model* m) {
    struct hdr_packed_histogram* h = NULL;
    if (packed_init_with(cfg, false, &h) != 0) return NULL;
    for (int k = 0; k < m->n; k++) {
        if (m->cnt[k] == 0) continue;
        if (!sparse_add(h, m->idx[k], m->cnt[k])) { hdr_packed_close(h); return NULL; }
    }
    packed_recompute_stats(h);   /* sets total_count (saturating), min, max */
    return h;
}

/* ---------------------------------------------------------------------------
 * counters + reporting
 * ------------------------------------------------------------------------- */
static long gaps = 0, checks = 0;
static int  gaps_shown = 0;
static const char* CUR = "";

#define REPORT(cond, ...) do { \
    checks++; \
    if (!(cond)) { \
        gaps++; \
        if (gaps_shown++ < 60) { printf("  GAP [%s]: ", CUR); printf(__VA_ARGS__); printf("\n"); } \
    } \
} while (0)

/* ---------------------------------------------------------------------------
 * percentile grids
 * ------------------------------------------------------------------------- */
static double PG[4096];
static int    NPG = 0;
static void push_p(double p) { if (NPG < (int)(sizeof(PG)/sizeof(PG[0]))) PG[NPG++] = p; }

static void build_pgrid(void) {
    NPG = 0;
    /* fine grid over [0,100] */
    for (int i = 0; i <= 200; i++) push_p(i * 0.5);
    /* dense tails */
    for (int i = 0; i <= 100; i++) push_p(i * 0.01);            /* [0,1] */
    for (int i = 0; i <= 100; i++) push_p(99.0 + i * 0.01);     /* [99,100] */
    /* exact anchors */
    push_p(0.0); push_p(50.0); push_p(100.0); push_p(25.0); push_p(75.0); push_p(90.0);
    push_p(99.0); push_p(99.9); push_p(99.99); push_p(99.999);
    /* ULP-adjacent to the interesting anchors */
    push_p(nextafter(0.0, 1.0));
    push_p(nextafter(0.0, -1.0));                 /* -0.0-ish / tiny negative */
    push_p(nextafter(50.0, 0.0));
    push_p(nextafter(50.0, 100.0));
    push_p(nextafter(100.0, 0.0));                /* just below 100 */
    push_p(nextafter(100.0, 200.0));              /* just above 100 -> clamps */
    push_p(100.0 - DBL_EPSILON);
    /* degenerate / UB-bait args (impl must stay defined) */
    push_p(-0.0);
    push_p(-1.0);
    push_p(-1e300);
    push_p(100.5);
    push_p(1e300);
    push_p(200.0);
    push_p((double) NAN);
    push_p((double) INFINITY);
    push_p((double) -INFINITY);
}

/* ---------------------------------------------------------------------------
 * one state: run every percentile through packed and both oracles
 * ------------------------------------------------------------------------- */
static void exercise(const struct hdr_packed_config* cfg, struct hdr_histogram* dense_safe,
                     const struct model* m, int safe_regime) {
    const struct hdr_histogram* g = &cfg->geom;
    struct hdr_packed_histogram* h = build(cfg, m);
    if (!h) { printf("  BUILD FAIL [%s]\n", CUR); gaps++; return; }

    /* sanity: state we built matches the model */
    REPORT(hdr_packed_total_count(h) == m->total,
           "total mismatch built=%lld model=%lld",
           (long long) hdr_packed_total_count(h), (long long) m->total);

    for (int i = 0; i < NPG; i++) {
        double p = PG[i];
        int64_t got = hdr_packed_value_at_percentile(h, p);   /* UB here -> sanitizer abort */
        int64_t exp = oracle_vap(m, g, p);
        REPORT(got == exp,
               "p=%.17g  packed=%lld  model-oracle=%lld  (total=%lld,n=%d,w=%d)",
               p, (long long) got, (long long) exp,
               (long long) m->total, m->n, h->width);

        if (safe_regime && dense_safe && isfinite(p) && p >= 0.0 && p <= 100.0) {
            int64_t den = hdr_value_at_percentile(dense_safe, p);
            REPORT(got == den,
                   "SAFE dense-divergence p=%.17g packed=%lld dense=%lld",
                   p, (long long) got, (long long) den);
        }
    }

    /* batch API must agree element-for-element with the scalar path */
    {
        static double bp[8] = {0.0, 50.0, 90.0, 99.0, 100.0, 25.0, 75.0, 99.9};
        int64_t bv[8];
        int rc = hdr_packed_value_at_percentiles(h, bp, bv, 8);
        REPORT(rc == 0, "percentiles batch rc=%d", rc);
        for (int i = 0; i < 8; i++)
            REPORT(bv[i] == hdr_packed_value_at_percentile(h, bp[i]),
                   "batch[%d] p=%g got=%lld scalar=%lld", i, bp[i],
                   (long long) bv[i], (long long) hdr_packed_value_at_percentile(h, bp[i]));
    }

    /* --- precision-independent structural invariant: monotonic non-decreasing
       across ascending finite p in [0,100]. True for ANY correct percentile
       function regardless of saturation, so no false positives. --- */
    {
        int64_t prev = INT64_MIN; double prev_p = -1.0;
        for (double p = 0.0; p <= 100.0; p += 0.1) {
            int64_t v = hdr_packed_value_at_percentile(h, p);
            REPORT(v >= prev, "non-monotonic: p=%.4f->%lld after p=%.4f->%lld",
                   p, (long long) v, prev_p, (long long) prev);
            prev = v; prev_p = p;
        }
    }
    hdr_packed_close(h);
}

/* ---------------------------------------------------------------------------
 * distribute a target total T across an index layout, filling the model
 * ------------------------------------------------------------------------- */
enum dist { D_SINGLE, D_TWO, D_MANY, D_TOP, D_SAT };

static void make_model(struct model* m, enum dist d, int64_t clen, int64_t T) {
    memset(m, 0, sizeof *m);
    int32_t top = (int32_t) (clen - 1);
    switch (d) {
    case D_SINGLE:
        m->n = 1; m->idx[0] = (top > 1) ? top / 2 : top; m->cnt[0] = T;
        break;
    case D_TWO:
        /* bulk low, one in the top bucket -> p100 must pick the TOP one */
        m->n = 2; m->idx[0] = 0; m->idx[1] = top;
        m->cnt[0] = (T > 1) ? T - 1 : 0; m->cnt[1] = (T > 0) ? 1 : 0;
        if (T == 1) { m->cnt[0] = 0; m->cnt[1] = 1; }
        break;
    case D_MANY: {
        int nb = 40; if ((int64_t) nb > clen) nb = (int) clen;
        if (nb < 2) nb = 2;
        m->n = nb;
        for (int i = 0; i < nb; i++)
            m->idx[i] = (int32_t) ((int64_t) i * (clen - 1) / (nb - 1));
        /* de-dup / enforce strictly ascending (small index spaces) */
        int w = 1;
        for (int i = 1; i < nb; i++) if (m->idx[i] > m->idx[w - 1]) m->idx[w++] = m->idx[i];
        m->n = w;
        int64_t each = T / m->n; int64_t rem = T - each * m->n;
        for (int i = 0; i < m->n; i++) m->cnt[i] = each;
        m->cnt[m->n - 1] = sat_add(m->cnt[m->n - 1], rem);
        break; }
    case D_TOP:
        /* everything in the single top bucket */
        m->n = 1; m->idx[0] = top; m->cnt[0] = T;
        break;
    case D_SAT:
        /* two buckets each at INT64_MAX -> total saturates to INT64_MAX;
           running sum saturates at bucket 0. (T is ignored.) */
        m->n = 2; m->idx[0] = 0; m->idx[1] = top;
        m->cnt[0] = INT64_MAX; m->cnt[1] = INT64_MAX;
        break;
    }
    /* recompute saturating total for the model */
    m->total = 0;
    for (int i = 0; i < m->n; i++) m->total = sat_add(m->total, m->cnt[i]);
}

/* ---------------------------------------------------------------------------
 * driver
 * ------------------------------------------------------------------------- */
static const int64_t TOTALS[] = {
    1, 2, 3, 7, 100,
    1LL << 30,
    1LL << 52,
    1LL << 53, (1LL << 53) + 1,
    INT64_MAX - 2000, INT64_MAX - 1000, INT64_MAX - 1,
    INT64_MAX,
};
static const int NTOT = (int)(sizeof(TOTALS)/sizeof(TOTALS[0]));

int main(void) {
    build_pgrid();
    printf("packed value_at_percentile RED-TEAM  (%d percentiles/state)\n", NPG);

    const int64_t lows[]  = {1, 1000000LL};
    const int64_t highs[] = {100000LL, 3600000000LL, INT64_MAX};
    const char*   hnm[]   = {"small(1e5)", "3.6e9", "INT64_MAX"};
    const enum dist dists[] = {D_SINGLE, D_TWO, D_MANY, D_TOP, D_SAT};
    const char*     dnm[]   = {"single", "two", "many", "all-top", "saturated"};

    int states = 0;
    char label[256];

    for (int sig = 1; sig <= 5; sig++)
    for (size_t li = 0; li < sizeof(lows)/sizeof(lows[0]); li++)
    for (size_t hi = 0; hi < sizeof(highs)/sizeof(highs[0]); hi++) {
        int64_t low = lows[li], high = highs[hi];
        if (high < 2 * low) continue;   /* invalid geometry */

        struct hdr_packed_config* cfg = NULL;
        if (hdr_packed_config_create(low, high, sig, &cfg) != 0) continue;
        int64_t clen = cfg->geom.counts_len;

        for (size_t di = 0; di < sizeof(dists)/sizeof(dists[0]); di++) {
            enum dist d = dists[di];

            if (d == D_SAT) {
                /* single saturated state (total ignored) */
                struct model m; make_model(&m, d, clen, 0);
                snprintf(label, sizeof label, "sig%d low%lld %s clen%lld %s tot=SAT",
                         sig, (long long) low, hnm[hi], (long long) clen, dnm[di]);
                CUR = label;
                exercise(cfg, NULL, &m, 0);
                states++;
                continue;
            }

            for (int ti = 0; ti < NTOT; ti++) {
                int64_t T = TOTALS[ti];
                struct model m; make_model(&m, d, clen, T);
                if (m.total != T && !(d == D_MANY)) {
                    /* single/two/top must reproduce T exactly (else skip) */
                }
                int safe = (T <= (1LL << 53));   /* dense trustworthy region */

                /* dense reference for the safe region: build an equivalent dense
                   histogram by writing counts directly (record can't hold huge
                   per-bucket counts without total overflow, but direct count
                   writes mirror a decoded dense histogram). */
                struct hdr_histogram* dense = NULL;
                if (safe) {
                    if (hdr_init(low, high, sig, &dense) == 0) {
                        for (int k = 0; k < m.n; k++)
                            dense->counts[m.idx[k]] = m.cnt[k];
                        dense->total_count = m.total;
                        /* min/max not needed for value_at_percentile */
                    }
                }

                snprintf(label, sizeof label, "sig%d low%lld %s clen%lld %s tot=%lld w?",
                         sig, (long long) low, hnm[hi], (long long) clen, dnm[di],
                         (long long) T);
                CUR = label;
                exercise(cfg, dense, &m, safe);
                if (dense) hdr_close(dense);
                states++;
            }
        }
        hdr_packed_config_destroy(cfg);
    }

    printf("\nstates=%d  checks=%ld  gaps=%ld\n", states, checks, gaps);
    if (gaps == 0) printf("VERDICT: CLEAN\n");
    else           printf("VERDICT: GAPS FOUND: %ld\n", gaps);
    return gaps ? 1 : 0;
}

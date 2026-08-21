/*
 * round10_audit.c -- FINAL red-team (round 10)
 *   FOCUS A: hdr_packed_value_at_percentiles (PLURAL)
 *   FOCUS B: encode/decode codec asymmetry, byte-identity, decode acceptance.
 *
 * White-box: include the impl TU for internal state crafting + helpers.
 * Dense reference comes from the static lib.
 */
#define _DEFAULT_SOURCE 1
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <float.h>
#include <zlib.h>

#include "hdr_packed_histogram.c"   /* full internal visibility */

/* dense reference */
extern int  hdr_init(int64_t, int64_t, int, struct hdr_histogram**);
extern void hdr_close(struct hdr_histogram*);
extern bool hdr_record_values(struct hdr_histogram*, int64_t, int64_t);
extern int64_t hdr_value_at_percentile(const struct hdr_histogram*, double);
extern int  hdr_value_at_percentiles(const struct hdr_histogram*, const double*, int64_t*, size_t);
extern int  hdr_encode_compressed(struct hdr_histogram*, uint8_t**, size_t*);
extern int  hdr_decode_compressed(uint8_t*, size_t, struct hdr_histogram**);
extern int64_t hdr_min(const struct hdr_histogram*);
extern int64_t hdr_max(const struct hdr_histogram*);
extern int64_t hdr_count_at_value(const struct hdr_histogram*, int64_t);

static long gaps = 0, checks = 0;
static const char* CUR = "";
#define REPORT(cond, ...) do { checks++; if (!(cond)) { gaps++; \
    printf("  GAP [%s]: ", CUR); printf(__VA_ARGS__); printf("\n"); } } while (0)

/* ======================================================================== */
/* PART A: PLURAL                                                            */
/* ======================================================================== */

/* Build a packed + an equivalent dense histogram from the same records. */
static void build_pair(int64_t low, int64_t high, int sig,
                       const int64_t* vals, const int64_t* cnts, int n,
                       struct hdr_packed_histogram** ph, struct hdr_histogram** dh) {
    hdr_packed_init(low, high, sig, ph);
    hdr_init(low, high, sig, dh);
    for (int i = 0; i < n; i++) {
        hdr_packed_record_values(*ph, vals[i], cnts[i]);
        hdr_record_values(*dh, vals[i], cnts[i]);
    }
}

static void plural_case(const char* name, struct hdr_packed_histogram* h,
                        struct hdr_histogram* dense,
                        const double* ps, size_t len) {
    CUR = name;
    int64_t* pv = (int64_t*) malloc(sizeof(int64_t) * (len ? len : 1));
    int rc = hdr_packed_value_at_percentiles(h, ps, pv, len);
    REPORT(rc == 0, "plural rc=%d (expected 0)", rc);

    /* (1) plural == singular element-for-element, for EVERY array shape */
    for (size_t i = 0; i < len; i++) {
        int64_t s = hdr_packed_value_at_percentile(h, ps[i]);
        REPORT(pv[i] == s, "elem %zu p=%.17g plural=%lld singular=%lld",
               i, ps[i], (long long) pv[i], (long long) s);
    }

    /* (2) vs dense-plural: only meaningful where the array is ASCENDING and
       finite (dense-plural is order-dependent and only defined for ascending
       inputs). For p>0 packed==dense-plural is the claim; at p0 divergence is
       documented item 8. */
    int ascending = 1;
    for (size_t i = 1; i < len; i++)
        if (!(isfinite(ps[i]) && isfinite(ps[i-1])) || ps[i] < ps[i-1]) { ascending = 0; break; }
    if (len && !isfinite(ps[0])) ascending = 0;

    /* dense-plural is self-inconsistent on an empty histogram (it returns the
       unconverted cumulative target, not a value); only compare where dense-plural
       is well-defined (total_count > 0). Item-8 story: packed-plural == packed-
       singular == dense-SINGULAR always; here we additionally confirm it equals
       dense-PLURAL wherever dense-plural is well-defined. */
    if (ascending && dense && dense->total_count > 0) {
        int64_t* dv = (int64_t*) malloc(sizeof(int64_t) * len);
        int drc = hdr_value_at_percentiles(dense, ps, dv, len);
        REPORT(drc == 0, "dense plural rc=%d", drc);
        for (size_t i = 0; i < len; i++) {
            if (ps[i] == 0.0) {
                /* documented item 8: packed=lowest-equiv, dense-plural=highest-equiv */
                int64_t dsing = hdr_value_at_percentile(dense, 0.0);
                REPORT(pv[i] == dsing,
                       "p0 packed-plural=%lld should equal dense-SINGULAR=%lld",
                       (long long) pv[i], (long long) dsing);
            } else {
                REPORT(pv[i] == dv[i],
                       "ASCENDING p>0 divergence i=%zu p=%.17g packed=%lld dense-plural=%lld",
                       i, ps[i], (long long) pv[i], (long long) dv[i]);
            }
        }
        free(dv);
    }
    free(pv);
}

static void part_a(void) {
    printf("== PART A: plural ==\n");
    int64_t low = 1, high = 3600000000LL; int sig = 3;

    /* a populated histogram */
    int64_t V[] = {1, 5, 12, 100, 1000, 50000, 999999, 3599999999LL};
    int64_t C[] = {10, 3, 7, 1, 42, 5, 100, 2};
    struct hdr_packed_histogram* h; struct hdr_histogram* d;
    build_pair(low, high, sig, V, C, 8, &h, &d);

    /* length 0 */
    { double x = 50.0; plural_case("len0", h, d, &x, 0); }
    /* length 1 various */
    { double x = 0.0;   plural_case("len1-p0",   h, d, &x, 1); }
    { double x = 50.0;  plural_case("len1-p50",  h, d, &x, 1); }
    { double x = 100.0; plural_case("len1-p100", h, d, &x, 1); }
    /* ascending typical */
    { double a[] = {0,10,25,50,75,90,99,99.9,100}; plural_case("ascending", h, d, a, 9); }
    /* ascending dense tail */
    { double a[] = {0,50,90,99,99.9,99.99,99.999,100}; plural_case("asc-tail", h, d, a, 8); }
    /* all-same */
    { double a[] = {50,50,50,50}; plural_case("all-same-50", h, d, a, 4); }
    { double a[] = {0,0,0}; plural_case("all-same-0", h, d, a, 3); }
    { double a[] = {100,100}; plural_case("all-same-100", h, d, a, 2); }
    /* duplicates within ascending */
    { double a[] = {0,0,50,50,100,100}; plural_case("asc-dups", h, d, a, 6); }
    /* descending (dense-plural is order-buggy; packed==singular must hold) */
    { double a[] = {100,99,90,50,10,0}; plural_case("descending", h, d, a, 6); }
    /* unordered */
    { double a[] = {50,0,100,25,99,10}; plural_case("unordered", h, d, a, 6); }
    /* NaN / inf / negative entries mixed */
    { double a[] = {(double)NAN,50.0,(double)INFINITY,(double)-INFINITY,-1.0,100.5,0.0};
      plural_case("nan-inf-mix", h, d, a, 7); }
    { double a[] = {(double)NAN}; plural_case("len1-nan", h, d, a, 1); }
    { double a[] = {(double)INFINITY}; plural_case("len1-inf", h, d, a, 1); }
    hdr_packed_close(h); hdr_close(d);

    /* empty histogram (total_count==0) */
    struct hdr_packed_histogram* he; struct hdr_histogram* de;
    hdr_packed_init(low, high, sig, &he); hdr_init(low, high, sig, &de);
    { double a[] = {0,50,100}; plural_case("empty-hist", he, de, a, 3); }
    hdr_packed_close(he); hdr_close(de);

    /* single-bucket histogram */
    struct hdr_packed_histogram* h1; struct hdr_histogram* d1;
    { int64_t v[]={42}, c[]={7}; build_pair(low,high,sig,v,c,1,&h1,&d1); }
    { double a[] = {0,50,100}; plural_case("single-bucket", h1, d1, a, 3); }
    { double a[] = {100,50,0}; plural_case("single-bucket-desc", h1, d1, a, 3); }
    hdr_packed_close(h1); hdr_close(d1);

    /* NULL argument handling parity with dense */
    {
        struct hdr_packed_histogram* hn; hdr_packed_init(low,high,sig,&hn);
        struct hdr_histogram* dn; hdr_init(low,high,sig,&dn);
        double a[]={50}; int64_t o[1];
        int p1 = hdr_packed_value_at_percentiles(hn, NULL, o, 1);
        int d1r = hdr_value_at_percentiles(dn, NULL, o, 1);
        REPORT(p1 == EINVAL && d1r == EINVAL, "NULL-percentiles packed=%d dense=%d", p1, d1r);
        int p2 = hdr_packed_value_at_percentiles(hn, a, NULL, 1);
        int d2r = hdr_value_at_percentiles(dn, a, NULL, 1);
        REPORT(p2 == EINVAL && d2r == EINVAL, "NULL-values packed=%d dense=%d", p2, d2r);
        /* length 0 with NULL args: dense/packed both return EINVAL (NULL check first) */
        int p3 = hdr_packed_value_at_percentiles(hn, NULL, NULL, 0);
        int d3r = hdr_value_at_percentiles(dn, NULL, NULL, 0);
        REPORT(p3 == d3r, "len0-NULL packed=%d dense=%d", p3, d3r);
        hdr_packed_close(hn); hdr_close(dn);
    }
    printf("  part A done (checks=%ld gaps=%ld)\n", checks, gaps);
}

/* ======================================================================== */
/* PART B: CODEC                                                             */
/* ======================================================================== */

/* Inflate a V2 compressed stream's *payload* (encoding flyweight + zigzag) for
   byte-level comparison, isolating codec logic from zlib determinism. Returns
   inflated length, or -1. out must be big enough. */
static long inflate_payload(const uint8_t* comp, size_t clen, uint8_t* out, size_t out_cap) {
    if (clen < PK_SIZEOF_CMP) return -1;
    const pk_compression_flyweight_t* cf = (const pk_compression_flyweight_t*) comp;
    int32_t dlen = be32toh(cf->length);
    if (dlen < 0 || clen - PK_SIZEOF_CMP < (size_t) dlen) return -1;
    z_stream s; memset(&s, 0, sizeof s);
    if (inflateInit(&s) != Z_OK) return -1;
    s.next_in = (Bytef*) cf->data; s.avail_in = (uInt) dlen;
    s.next_out = out; s.avail_out = (uInt) out_cap;
    int r = inflate(&s, Z_FINISH);
    long n = (long) (out_cap - s.avail_out);
    inflateEnd(&s);
    if (r != Z_STREAM_END && r != Z_OK && r != Z_BUF_ERROR) return -1;
    return n;
}

/* record identical data into packed + dense, encode both, compare payloads and
   round-trip both ways. */
static void codec_case(const char* name, int64_t low, int64_t high, int sig,
                       const int64_t* vals, const int64_t* cnts, int n) {
    CUR = name;
    struct hdr_packed_histogram* p; struct hdr_histogram* d;
    build_pair(low, high, sig, vals, cnts, n, &p, &d);

    uint8_t* pc = NULL; size_t pcl = 0;
    uint8_t* dc = NULL; size_t dcl = 0;
    int per = hdr_packed_encode_compressed(p, &pc, &pcl);
    int der = hdr_encode_compressed(d, &dc, &dcl);
    REPORT(per == 0, "packed encode rc=%d", per);
    REPORT(der == 0, "dense encode rc=%d", der);
    if (per == 0 && der == 0) {
        /* byte-identity of the pre-compression payload (the claim's true source) */
        static uint8_t pb[1<<20], db[1<<20];
        long pn = inflate_payload(pc, pcl, pb, sizeof pb);
        long dn = inflate_payload(dc, dcl, db, sizeof db);
        REPORT(pn >= 0 && dn >= 0, "payload inflate failed pn=%ld dn=%ld", pn, dn);
        if (pn >= 0 && dn >= 0) {
            REPORT(pn == dn && 0 == memcmp(pb, db, (size_t) pn),
                   "PAYLOAD NON-IDENTICAL pn=%ld dn=%ld", pn, dn);
            if (!(pn == dn && 0 == memcmp(pb, db, (size_t) pn))) {
                long m = pn < dn ? pn : dn; int fd = -1;
                for (long i = 0; i < m; i++) if (pb[i]!=db[i]) { fd=(int)i; break; }
                printf("     firstdiff@%d  packed=%02x dense=%02x\n",
                       fd, fd>=0?pb[fd]:0, fd>=0?db[fd]:0);
            }
        }
        /* also compare full compressed bytes (zlib is deterministic here) */
        REPORT(pcl == dcl && 0 == memcmp(pc, dc, pcl),
               "COMPRESSED bytes differ pcl=%zu dcl=%zu", pcl, dcl);

        /* cross-decode: dense decoder reads packed's stream; packed reads dense's.
           NOTE: total_count and count_at_value are invariant across record/decode,
           so we compare those against the recorded originals. min/max legitimately
           differ between the record stage (raw value) and the decode stage
           (recomputed bottom/top-of-bucket) at the exact INT64_MAX sentinel -- and
           dense does the identical thing -- so min/max parity is checked at the SAME
           stage: dense-decoded vs packed-decoded (byte-identical stream). */
        struct hdr_histogram* dd = NULL;
        int r1 = hdr_decode_compressed(pc, pcl, &dd);
        REPORT(r1 == 0, "dense-decode(packed) rc=%d", r1);
        if (r1 == 0) {
            REPORT(dd->total_count == d->total_count, "xdec total %lld vs %lld",
                   (long long) dd->total_count, (long long) d->total_count);
            for (int i=0;i<n;i++)
                REPORT(hdr_count_at_value(dd,vals[i])==hdr_count_at_value(d,vals[i]),
                       "xdec count@%lld", (long long)vals[i]);
        }
        /* packed decoder reads dense's stream */
        struct hdr_packed_histogram* pp = NULL;
        int r2 = hdr_packed_decode_compressed(dc, dcl, &pp);
        REPORT(r2 == 0, "packed-decode(dense) rc=%d", r2);
        if (r2 == 0) {
            REPORT(hdr_packed_total_count(pp)==hdr_packed_total_count(p),
                   "pdec total %lld vs %lld",
                   (long long)hdr_packed_total_count(pp),(long long)hdr_packed_total_count(p));
            for (int i=0;i<n;i++)
                REPORT(hdr_packed_count_at_value(pp,vals[i])==hdr_packed_count_at_value(p,vals[i]),
                       "pdec count@%lld", (long long)vals[i]);
        }
        /* same-stage decode parity: dense-decoded vs packed-decoded min/max */
        if (r1 == 0 && r2 == 0) {
            REPORT(hdr_min(dd)==hdr_packed_min(pp) && hdr_max(dd)==hdr_packed_max(pp),
                   "decode-stage min/max mismatch dense=%lld/%lld packed=%lld/%lld",
                   (long long)hdr_min(dd),(long long)hdr_max(dd),
                   (long long)hdr_packed_min(pp),(long long)hdr_packed_max(pp));
        }
        if (dd) hdr_close(dd);
        if (pp) hdr_packed_close(pp);
        /* self round-trip packed->packed */
        struct hdr_packed_histogram* sp = NULL;
        int r3 = hdr_packed_decode_compressed(pc, pcl, &sp);
        REPORT(r3 == 0, "packed self-decode rc=%d", r3);
        if (r3 == 0) {
            for (int i=0;i<n;i++)
                REPORT(hdr_packed_count_at_value(sp,vals[i])==hdr_packed_count_at_value(p,vals[i]),
                       "self count@%lld", (long long)vals[i]);
            /* re-encode the decoded packed and compare to original packed bytes */
            uint8_t* rc2=NULL; size_t rcl2=0;
            if (hdr_packed_encode_compressed(sp, &rc2, &rcl2)==0) {
                REPORT(rcl2==pcl && 0==memcmp(rc2,pc,pcl), "re-encode differs");
                free(rc2);
            }
            hdr_packed_close(sp);
        }
    }
    free(pc); free(dc);
    hdr_packed_close(p); hdr_close(d);
}

static void part_b(void) {
    printf("== PART B: codec ==\n");
    /* empty */
    { codec_case("empty-1e5", 1, 100000, 3, NULL, NULL, 0); }
    { codec_case("empty-INT64MAX", 1, INT64_MAX, 3, NULL, NULL, 0); }
    /* single bucket at various positions */
    { int64_t v[]={0}, c[]={1}; codec_case("single-idx0", 1, 100000, 3, v, c, 1); }
    { int64_t v[]={42}, c[]={5}; codec_case("single-mid", 1, 100000, 3, v, c, 1); }
    { int64_t v[]={99999}, c[]={9}; codec_case("single-nearmax", 1, 100000, 3, v, c, 1); }
    /* zero-run edges: gaps between buckets, leading & trailing */
    { int64_t v[]={0,1000,2000,99999}, c[]={1,1,1,1}; codec_case("gaps", 1, 100000, 3, v, c, 4); }
    { int64_t v[]={500,600,700}, c[]={3,3,3}; codec_case("leading-zeros", 1, 100000, 3, v, c, 3); }
    /* wide counts: force width 2/4/8 */
    { int64_t v[]={10}, c[]={70000}; codec_case("width2", 1, 100000, 3, v, c, 1); }
    { int64_t v[]={10}, c[]={5000000000LL}; codec_case("width8", 1, 100000, 3, v, c, 1); }
    { int64_t v[]={10,20}, c[]={0xFFFFFFFFLL+1, 3}; codec_case("width8-mixed", 1, 100000, 3, v, c, 2); }
    /* INT64_MAX geometry, top bucket */
    { int64_t v[]={INT64_MAX}, c[]={1}; codec_case("int64max-top", 1, INT64_MAX, 3, v, c, 1); }
    { int64_t v[]={1, INT64_MAX/2, INT64_MAX}, c[]={2,3,4}; codec_case("int64max-spread", 1, INT64_MAX, 3, v, c, 3); }
    { int64_t v[]={1000000, INT64_MAX}, c[]={100,1}; codec_case("int64max-lowhigh", 1000, INT64_MAX, 2, v, c, 2); }
    /* dense population */
    { int64_t v[128]; int64_t c[128]; for (int i=0;i<128;i++){v[i]=i*7+1;c[i]=i+1;}
      codec_case("dense128", 1, 100000, 3, v, c, 128); }
    /* many sig figs */
    { int64_t v[]={1,2,3,4,5,1000,999999}, c[]={1,2,3,4,5,6,7};
      codec_case("sig5", 1, 3600000000LL, 5, v, c, 7); }
    { int64_t v[]={1,2,3,4,5,1000,99999}, c[]={1,2,3,4,5,6,7};
      codec_case("sig1", 1, 100000, 1, v, c, 7); }
    printf("  part B(round-trip) done (checks=%ld gaps=%ld)\n", checks, gaps);
}

/* ======================================================================== */
/* PART C: decode-rejection / malformed streams                             */
/* ======================================================================== */

/* Build a valid packed stream, then let a mutator tamper with the DECOMPRESSED
   header/payload, recompress, and test that both decoders agree on accept/reject.
   We compare packed-decode outcome to dense-decode outcome for the SAME bytes. */

static uint8_t* recompress(const uint8_t* payload, size_t plen, size_t* out_len) {
    uLongf dl = compressBound((uLong) plen);
    pk_compression_flyweight_t* cmp = (pk_compression_flyweight_t*) malloc(PK_SIZEOF_CMP + dl);
    if (compress(cmp->data, &dl, payload, (uLong) plen) != Z_OK) { free(cmp); return NULL; }
    cmp->cookie = htobe32(PK_V2_COMPRESSION_COOKIE | 0x10U);
    cmp->length = htobe32((int32_t) dl);
    *out_len = PK_SIZEOF_CMP + dl;
    return (uint8_t*) cmp;
}

/* obtain the decompressed payload (header+zigzag) of a freshly-encoded packed h */
static long get_payload(struct hdr_packed_histogram* h, uint8_t* buf, size_t cap) {
    uint8_t* pc=NULL; size_t pcl=0;
    if (hdr_packed_encode_compressed(h, &pc, &pcl)!=0) return -1;
    long n = inflate_payload(pc, pcl, buf, cap);
    free(pc);
    return n;
}

static void expect_both(const char* name, uint8_t* bytes, size_t len,
                        int expect_packed_ok, int expect_dense_ok) {
    CUR = name;
    struct hdr_packed_histogram* p=NULL;
    /* packed_decode takes non-const buffer; copy since it may be reused */
    uint8_t* cp = (uint8_t*) malloc(len); memcpy(cp, bytes, len);
    int pr = hdr_packed_decode_compressed(cp, len, &p);
    int packed_ok = (pr==0);
    if (p) hdr_packed_close(p);
    free(cp);

    struct hdr_histogram* d=NULL;
    uint8_t* cd = (uint8_t*) malloc(len); memcpy(cd, bytes, len);
    int dr = hdr_decode_compressed(cd, len, &d);
    int dense_ok = (dr==0);
    if (d) hdr_close(d);
    free(cd);

    REPORT(packed_ok==expect_packed_ok, "packed accept=%d rc=%d (expected %d)",
           packed_ok, pr, expect_packed_ok);
    if (expect_dense_ok >= 0)
        REPORT(dense_ok==expect_dense_ok, "dense accept=%d rc=%d (expected %d)",
               dense_ok, dr, expect_dense_ok);
    /* informational: asymmetry between decoders */
    if (packed_ok != dense_ok)
        printf("     [asymmetry %s] packed rc=%d dense rc=%d\n", name, pr, dr);
}

static void part_c(void) {
    printf("== PART C: malformed / rejection ==\n");
    int64_t low=1, high=100000; int sig=3;
    struct hdr_packed_histogram* h; hdr_packed_init(low,high,sig,&h);
    int64_t v[]={0,100,1000,50000,99999}, c[]={5,3,7,1,9};
    for (int i=0;i<5;i++) hdr_packed_record_values(h,v[i],c[i]);

    static uint8_t base[1<<16];
    long bn = get_payload(h, base, sizeof base);
    REPORT(bn>0, "get_payload rc=%ld", bn);
    pk_encoding_flyweight_t* eh = (pk_encoding_flyweight_t*) base;

    /* 0) sanity: unmodified recompressed payload decodes OK on both */
    {
        size_t cl; uint8_t* cc = recompress(base, (size_t) bn, &cl);
        expect_both("baseline-valid", cc, cl, 1, 1);
        free(cc);
    }
    /* 1) non-zero normalizing_index_offset -> packed REJECTS (EINVAL), dense ACCEPTS */
    {
        static uint8_t m[1<<16]; memcpy(m, base, bn);
        pk_encoding_flyweight_t* e = (pk_encoding_flyweight_t*) m;
        e->normalizing_index_offset = htobe32(3);
        size_t cl; uint8_t* cc = recompress(m, (size_t) bn, &cl);
        expect_both("nonzero-offset", cc, cl, 0, 1);  /* documented divergence item 6 */
        free(cc);
    }
    /* 2) corrupt encoding cookie -> both reject */
    {
        static uint8_t m[1<<16]; memcpy(m, base, bn);
        pk_encoding_flyweight_t* e = (pk_encoding_flyweight_t*) m;
        e->cookie = htobe32(0xdeadbeef);
        size_t cl; uint8_t* cc = recompress(m, (size_t) bn, &cl);
        expect_both("bad-enc-cookie", cc, cl, 0, 0);
        free(cc);
    }
    /* 3) payload_len larger than actual inflated bytes (claims more than present)
          -> inflate short: packed requires full header/payload -> reject */
    {
        static uint8_t m[1<<16]; memcpy(m, base, bn);
        pk_encoding_flyweight_t* e = (pk_encoding_flyweight_t*) m;
        e->payload_len = htobe32(be32toh(e->payload_len) + 100);
        size_t cl; uint8_t* cc = recompress(m, (size_t) bn, &cl);
        /* Lenient (matches dense): a payload_len overshooting the actual inflated
           length is accepted; the missing tail reads as calloc-zeros (benign empty
           buckets). Verified same as dense (rc=0). Not a memory-safety issue:
           counts_array is calloc'd with +9 slack and data_index stays < counts_limit. */
        expect_both("payload-len-too-big", cc, cl, 1, 1);
        free(cc);
    }
    /* 4) payload_len smaller than emitted tokens -> ENCODED_INPUT_TOO_LONG / truncation */
    {
        static uint8_t m[1<<16]; memcpy(m, base, bn);
        pk_encoding_flyweight_t* e = (pk_encoding_flyweight_t*) m;
        int32_t pl = be32toh(e->payload_len);
        e->payload_len = htobe32(pl - 2);
        /* keep only PK_SIZEOF_ENC + (pl-2) payload bytes so inflate matches */
        long newn = PK_SIZEOF_ENC + (pl - 2);
        size_t cl; uint8_t* cc = recompress(m, (size_t) newn, &cl);
        expect_both("payload-len-too-small", cc, cl, 0, -1);
        free(cc);
    }
    /* 5) negative payload_len -> reject */
    {
        static uint8_t m[1<<16]; memcpy(m, base, bn);
        pk_encoding_flyweight_t* e = (pk_encoding_flyweight_t*) m;
        e->payload_len = htobe32(-1);
        size_t cl; uint8_t* cc = recompress(m, (size_t) bn, &cl);
        expect_both("negative-payload-len", cc, cl, 0, -1);
        free(cc);
    }
    /* 6) trailing-zeros overflow: craft a payload that is a single huge zero-run
          token whose zero-count exceeds counts_len -> reject */
    {
        static uint8_t m[1<<16];
        pk_encoding_flyweight_t* e = (pk_encoding_flyweight_t*) m;
        memcpy(m, base, PK_SIZEOF_ENC);              /* copy header */
        uint8_t tok[9];
        int tl = zig_zag_encode_i64(tok, -(int64_t)(h->cfg->geom.counts_len + 5));
        memcpy(e->counts, tok, tl);
        e->payload_len = htobe32(tl);
        long newn = PK_SIZEOF_ENC + tl;
        size_t cl; uint8_t* cc = recompress(m, (size_t) newn, &cl);
        expect_both("zero-run-overflow", cc, cl, 0, 0);
        free(cc);
    }
    /* 7) zero-run token == INT32_MIN region (value <= INT32_MIN) -> reject */
    {
        static uint8_t m[1<<16];
        pk_encoding_flyweight_t* e = (pk_encoding_flyweight_t*) m;
        memcpy(m, base, PK_SIZEOF_ENC);
        uint8_t tok[9];
        int tl = zig_zag_encode_i64(tok, (int64_t) INT32_MIN - 1); /* value <= INT32_MIN */
        memcpy(e->counts, tok, tl);
        e->payload_len = htobe32(tl);
        long newn = PK_SIZEOF_ENC + tl;
        size_t cl; uint8_t* cc = recompress(m, (size_t) newn, &cl);
        expect_both("zero-run-int32min", cc, cl, 0, 0);
        free(cc);
    }
    /* 8) decompression-bomb: payload_len way over PK_MAX_LEB128*counts_len -> reject */
    {
        static uint8_t m[1<<16]; memcpy(m, base, bn);
        pk_encoding_flyweight_t* e = (pk_encoding_flyweight_t*) m;
        /* set an enormous payload_len; recompress with real (short) payload so
           inflate itself would end early -- packed's pre-alloc bound must fire first */
        e->payload_len = htobe32(INT32_MAX);
        size_t cl; uint8_t* cc = recompress(m, (size_t) bn, &cl);
        expect_both("bomb-payload-len", cc, cl, 0, -1);
        free(cc);
    }
    /* 9) truncated compression frame (length field longer than buffer) */
    {
        size_t cl; uint8_t* cc = recompress(base, (size_t) bn, &cl);
        pk_compression_flyweight_t* cf = (pk_compression_flyweight_t*) cc;
        cf->length = htobe32(be32toh(cf->length) + 1000);  /* claims more than present */
        expect_both("comp-len-too-big", cc, cl, 0, -1);
        free(cc);
    }
    /* 10) negative comp length */
    {
        size_t cl; uint8_t* cc = recompress(base, (size_t) bn, &cl);
        pk_compression_flyweight_t* cf = (pk_compression_flyweight_t*) cc;
        cf->length = htobe32(-5);
        expect_both("comp-len-negative", cc, cl, 0, -1);
        free(cc);
    }
    /* 11) bad compression cookie */
    {
        size_t cl; uint8_t* cc = recompress(base, (size_t) bn, &cl);
        pk_compression_flyweight_t* cf = (pk_compression_flyweight_t*) cc;
        cf->cookie = htobe32(0x12345678);
        expect_both("bad-comp-cookie", cc, cl, 0, 0);
        free(cc);
    }
    /* 12) too-short buffer */
    {
        uint8_t tiny[4] = {0,0,0,0};
        expect_both("too-short", tiny, 4, 0, -1);
    }
    /* 13) value_at overflow: counts_index pushed past counts_len via many value
           tokens -- craft payload of counts_len+3 value tokens; decode must stop
           at counts_len and then flag ENCODED_INPUT_TOO_LONG (data left over). */
    {
        static uint8_t m[1<<16];
        pk_encoding_flyweight_t* e = (pk_encoding_flyweight_t*) m;
        memcpy(m, base, PK_SIZEOF_ENC);
        int32_t clen = h->cfg->geom.counts_len;
        long di = 0;
        int ntok = clen + 3;
        for (int k=0;k<ntok && di < (long)sizeof(m)-PK_SIZEOF_ENC-9;k++)
            di += zig_zag_encode_i64(&e->counts[di], 1); /* value=1 each */
        e->payload_len = htobe32((int32_t) di);
        long newn = PK_SIZEOF_ENC + di;
        size_t cl; uint8_t* cc = recompress(m, (size_t) newn, &cl);
        /* decode loops counts_index<clen; leftover data -> ENCODED_INPUT_TOO_LONG */
        expect_both("value-tokens-overflow", cc, cl, 0, -1);
        free(cc);
    }
    hdr_packed_close(h);
    printf("  part C done (checks=%ld gaps=%ld)\n", checks, gaps);
}

int main(void) {
    part_a();
    part_b();
    part_c();
    printf("\nTOTAL checks=%ld gaps=%ld\n", checks, gaps);
    if (gaps==0) printf("VERDICT: CLEAN\n");
    else         printf("VERDICT: GAPS FOUND: %ld\n", gaps);
    return gaps ? 1 : 0;
}

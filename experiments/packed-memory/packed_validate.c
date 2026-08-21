/*
 * packed_validate.c -- correctness gate: packed variant must match dense
 * bucket-for-bucket over randomized workloads. Any mismatch is a hard failure.
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <inttypes.h>
#include "hdr/hdr_histogram.h"
#include "hdr_packed_histogram.h"

static uint64_t rng_state = 0x9e3779b97f4a7c15ULL;
static uint64_t xr(void) { /* xorshift64* -- deterministic, no time/rand dep */
    uint64_t x = rng_state;
    x ^= x >> 12; x ^= x << 25; x ^= x >> 27;
    rng_state = x;
    return x * 0x2545F4914F6CDD1DULL;
}

static int failures = 0;
#define CHECK(cond, fmt, ...) do { \
    if (!(cond)) { printf("  FAIL: " fmt "\n", __VA_ARGS__); failures++; } \
} while (0)

static void run_case(const char* name, int64_t low, int64_t high, int sig,
                     int n_records, int distinct, uint64_t seed)
{
    rng_state = seed ? seed : 1;
    struct hdr_histogram* dense = NULL;
    struct hdr_packed_histogram* packed = NULL;
    if (hdr_init(low, high, sig, &dense) != 0) { printf("  dense init failed\n"); failures++; return; }
    if (hdr_packed_init(low, high, sig, &packed) != 0) { printf("  packed init failed\n"); failures++; return; }

    /* pick `distinct` base values, then record n_records draws among them with
       random counts -- exercises inserts, hits, and multi-count adds. */
    int64_t* bases = malloc((size_t)distinct * sizeof(int64_t));
    for (int i = 0; i < distinct; i++)
    {
        bases[i] = (int64_t)(xr() % (uint64_t)high) + low;
        if (bases[i] > high) bases[i] = high;
    }
    for (int r = 0; r < n_records; r++)
    {
        int64_t v = bases[xr() % (uint64_t)distinct];
        int64_t c = 1 + (int64_t)(xr() % 5);
        bool rd = hdr_record_values(dense, v, c);
        bool rp = hdr_packed_record_values(packed, v, c);
        CHECK(rd == rp, "%s: record return mismatch v=%" PRId64 " dense=%d packed=%d", name, v, rd, rp);
    }

    CHECK(hdr_packed_total_count(packed) == dense->total_count,
          "%s: total_count dense=%" PRId64 " packed=%" PRId64, name,
          dense->total_count, hdr_packed_total_count(packed));
    CHECK(hdr_packed_min(packed) == hdr_min(dense),
          "%s: min dense=%" PRId64 " packed=%" PRId64, name, hdr_min(dense), hdr_packed_min(packed));
    CHECK(hdr_packed_max(packed) == hdr_max(dense),
          "%s: max dense=%" PRId64 " packed=%" PRId64, name, hdr_max(dense), hdr_packed_max(packed));

    for (int i = 0; i < distinct; i++)
    {
        int64_t cd = hdr_count_at_value(dense, bases[i]);
        int64_t cp = hdr_packed_count_at_value(packed, bases[i]);
        CHECK(cd == cp, "%s: count_at_value v=%" PRId64 " dense=%" PRId64 " packed=%" PRId64,
              name, bases[i], cd, cp);
    }

    const double pcts[] = {0.0, 1.0, 10.0, 25.0, 50.0, 75.0, 90.0, 99.0, 99.9, 100.0};
    for (size_t i = 0; i < sizeof(pcts)/sizeof(pcts[0]); i++)
    {
        int64_t vd = hdr_value_at_percentile(dense, pcts[i]);
        int64_t vp = hdr_packed_value_at_percentile(packed, pcts[i]);
        CHECK(vd == vp, "%s: p%.1f dense=%" PRId64 " packed=%" PRId64, name, pcts[i], vd, vp);
    }

    printf("  %-28s records=%-7d distinct=%-5d populated=%-5d  %s\n",
           name, n_records, distinct, hdr_packed_populated(packed),
           failures == 0 ? "ok" : "SEE FAILURES");

    free(bases);
    hdr_close(dense);
    hdr_packed_close(packed);
}

/* exercise count-width widening (1->2->4->8) and huge single-bucket counts */
static void run_widths(void)
{
    struct hdr_histogram* dense = NULL;
    struct hdr_packed_histogram* packed = NULL;
    hdr_init(1, 3600000000LL, 3, &dense);
    hdr_packed_init(1, 3600000000LL, 3, &packed);

    const int64_t big[] = {200, 300, 70000, 5000000000LL, 1};
    const int64_t vals[] = {5, 5, 777, 4242, 999999};
    for (size_t i = 0; i < sizeof(big)/sizeof(big[0]); i++)
    {
        hdr_record_values(dense, vals[i], big[i]);
        hdr_packed_record_values(packed, vals[i], big[i]);
    }
    CHECK(hdr_packed_total_count(packed) == dense->total_count,
          "widths: total dense=%" PRId64 " packed=%" PRId64, dense->total_count,
          hdr_packed_total_count(packed));
    for (size_t i = 0; i < sizeof(vals)/sizeof(vals[0]); i++)
    {
        CHECK(hdr_count_at_value(dense, vals[i]) == hdr_packed_count_at_value(packed, vals[i]),
              "widths: count v=%" PRId64 " dense=%" PRId64 " packed=%" PRId64, vals[i],
              hdr_count_at_value(dense, vals[i]), hdr_packed_count_at_value(packed, vals[i]));
    }
    const double pcts[] = {0, 50, 90, 99, 100};
    for (size_t i = 0; i < sizeof(pcts)/sizeof(pcts[0]); i++)
        CHECK(hdr_value_at_percentile(dense, pcts[i]) == hdr_packed_value_at_percentile(packed, pcts[i]),
              "widths: p%.0f mismatch", pcts[i]);
    printf("  %-28s width=%dB populated=%d  %s\n", "count-width widening",
           hdr_packed_count_width(packed), hdr_packed_populated(packed),
           failures == 0 ? "ok" : "SEE FAILURES");
    hdr_close(dense); hdr_packed_close(packed);
}

/* shared config backing many histograms */
static void run_shared(void)
{
    struct hdr_packed_config* cfg = NULL;
    if (hdr_packed_config_create(1, 3600000000LL, 3, &cfg) != 0) { failures++; return; }
    rng_state = 0xABCD;
    int mismatches = 0;
    for (int k = 0; k < 8; k++)
    {
        struct hdr_histogram* dense = NULL;
        struct hdr_packed_histogram* packed = NULL;
        hdr_init(1, 3600000000LL, 3, &dense);
        hdr_packed_init_shared(cfg, &packed);
        for (int r = 0; r < 5000; r++)
        {
            int64_t v = (int64_t)(xr() % 3600000000ULL) + 1;
            hdr_record_value(dense, v);
            hdr_packed_record_value(packed, v);
        }
        for (double p = 0; p <= 100; p += 12.5)
            if (hdr_value_at_percentile(dense, p) != hdr_packed_value_at_percentile(packed, p))
                mismatches++;
        hdr_close(dense); hdr_packed_close(packed);
    }
    CHECK(mismatches == 0, "shared-config: %d percentile mismatches", mismatches);
    printf("  %-28s 8 histos, 1 shared config  %s\n", "shared config",
           mismatches == 0 && failures == 0 ? "ok" : "SEE FAILURES");
    hdr_packed_config_destroy(cfg);
}

/* exported from the hdr static lib (declared in src/hdr_tests.h, not shipped) */
extern int hdr_encode_compressed(struct hdr_histogram*, uint8_t**, size_t*);
extern int hdr_decode_compressed(uint8_t*, size_t, struct hdr_histogram**);

static void cmp_dense_full(const char* name, struct hdr_histogram* a, struct hdr_histogram* b)
{
    CHECK(a->counts_len == b->counts_len, "%s: counts_len %d vs %d", name, a->counts_len, b->counts_len);
    CHECK(a->total_count == b->total_count, "%s: total %" PRId64 " vs %" PRId64, name, a->total_count, b->total_count);
    int32_t lim = a->counts_len < b->counts_len ? a->counts_len : b->counts_len;
    int diffs = 0;
    for (int32_t i = 0; i < lim; i++)
        if (a->counts[i] != b->counts[i]) diffs++;
    CHECK(diffs == 0, "%s: %d bucket-count diffs", name, diffs);
}

/* Serialization interop: packed <-> standard V2 <-> dense, both directions,
   plus a byte-identical-stream assertion. */
static void run_serialize(const char* name, int64_t low, int64_t high, int sig,
                          int n_records, int distinct, uint64_t seed)
{
    rng_state = seed ? seed : 1;
    struct hdr_histogram* dense = NULL;
    struct hdr_packed_histogram* packed = NULL;
    hdr_init(low, high, sig, &dense);
    hdr_packed_init(low, high, sig, &packed);
    for (int r = 0; r < n_records; r++)
    {
        int64_t v = (int64_t)(xr() % (uint64_t)high) + low;
        int64_t c = 1 + (int64_t)(xr() % 7);
        if (v > high) v = high;
        hdr_record_values(dense, v, c);
        hdr_packed_record_values(packed, v, c);
    }

    /* (1) packed-native encode -> decode with the DENSE library decoder */
    uint8_t* sp = NULL; size_t sp_len = 0;
    int e1 = hdr_packed_encode_compressed(packed, &sp, &sp_len);
    CHECK(e1 == 0, "%s: packed encode rc=%d", name, e1);
    struct hdr_histogram* dfp = NULL;
    int d1 = sp ? hdr_decode_compressed(sp, sp_len, &dfp) : -1;
    CHECK(d1 == 0, "%s: dense decode of packed stream rc=%d", name, d1);
    if (dfp) cmp_dense_full(name, dense, dfp);

    /* (2) dense encode -> decode with the PACKED decoder, compare queries */
    uint8_t* sd = NULL; size_t sd_len = 0;
    int e2 = hdr_encode_compressed(dense, &sd, &sd_len);
    CHECK(e2 == 0, "%s: dense encode rc=%d", name, e2);
    struct hdr_packed_histogram* prt = NULL;
    int d2 = sd ? hdr_packed_decode_compressed(sd, sd_len, &prt) : -1;
    CHECK(d2 == 0, "%s: packed decode of dense stream rc=%d", name, d2);
    if (prt)
    {
        CHECK(hdr_packed_total_count(prt) == dense->total_count, "%s: rt total", name);
        CHECK(hdr_packed_min(prt) == hdr_min(dense), "%s: rt min", name);
        CHECK(hdr_packed_max(prt) == hdr_max(dense), "%s: rt max", name);
        const double pc[] = {0, 1, 50, 90, 99, 99.9, 100};
        for (size_t i = 0; i < sizeof(pc)/sizeof(pc[0]); i++)
            CHECK(hdr_packed_value_at_percentile(prt, pc[i]) == hdr_value_at_percentile(dense, pc[i]),
                  "%s: rt p%.1f", name, pc[i]);
    }

    /* (3) byte-identical stream: same pre-compression payload -> same bytes */
    CHECK(sp && sd && sp_len == sd_len && memcmp(sp, sd, sp_len) == 0,
          "%s: stream not byte-identical (packed %zu vs dense %zu)", name, sp_len, sd_len);

    printf("  %-28s records=%-7d stream=%-5zuB  %s\n", name, n_records, sp_len,
           failures == 0 ? "ok" : "SEE FAILURES");

    free(sp); free(sd);
    if (dfp) hdr_close(dfp);
    if (prt) hdr_packed_close(prt);
    hdr_close(dense); hdr_packed_close(packed);
}

int main(void)
{
    printf("packed vs dense correctness gate\n");
    run_case("latency-1h-us sparse",   1, 3600000000LL, 3, 1000,   10,  0x1111);
    run_case("latency-1h-us moderate", 1, 3600000000LL, 3, 100000, 500, 0x2222);
    run_case("latency-1h-us dense",    1, 3600000000LL, 3, 500000, 5000,0x3333);
    run_case("small-range sig5",       1, 100000LL,     5, 50000,  2000,0x4444);
    run_case("low>1 unit_mag",         1000, 3600000000LL, 3, 20000, 300, 0x5555);
    run_case("single-distinct",        1, 3600000000LL, 3, 1000,   1,   0x6666);
    run_case("empty",                  1, 3600000000LL, 3, 0,      1,   0x7777);
    run_widths();
    run_shared();
    printf("serialization interop (packed <-> V2 <-> dense)\n");
    run_serialize("ser sparse",   1, 3600000000LL, 3, 1000,   10,  0xA1);
    run_serialize("ser moderate", 1, 3600000000LL, 3, 100000, 500, 0xB2);
    run_serialize("ser dense",    1, 3600000000LL, 3, 500000, 5000,0xC3);
    run_serialize("ser sig5",     1, 100000LL,     5, 50000,  2000,0xD4);
    run_serialize("ser low>1",    1000, 3600000000LL, 3, 20000, 300,0xE5);
    run_serialize("ser empty",    1, 3600000000LL, 3, 0,      1,   0xF6);

    if (failures == 0) { printf("\nALL PASS\n"); return 0; }
    printf("\n%d FAILURES\n", failures);
    return 1;
}

/* Differential dump: prints hdr_value_at_percentile for a fixed-seed corpus. Build once per variant, diff the outputs. */
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <hdr/hdr_histogram.h>

int32_t counts_index_for(const struct hdr_histogram* h, int64_t value); /* exported by the library, not in the public header */
static uint64_t s = 88172645463325252ULL;
static uint64_t rnd(void) { s ^= s << 13; s ^= s >> 7; s ^= s << 17; return s; }
static const double PCT[] = {0, 1e-300, 0.5, 25, 50, 75, 90, 99, 99.9, 99.99, 99.999999, 100, 100.0000001,
                             1e308, INFINITY, -1, -INFINITY, NAN};
#define NP (sizeof PCT / sizeof PCT[0])

static void dump(const char* tag, const struct hdr_histogram* h)
{
    printf("%s total=%lld", tag, (long long)h->total_count);
    for (size_t i = 0; i < NP; i++) printf(" %lld", (long long)hdr_value_at_percentile(h, PCT[i]));
    int64_t pv = 0;
    for (int k = 1; k <= 200; k++) { /* sweep incl. rank boundaries */
        double p = (k - 0.5) * 100.0 / (h->total_count > 0 ? (double)h->total_count : 1.0);
        pv += hdr_value_at_percentile(h, p) ^ k;
    }
    printf(" sweep=%lld\n", (long long)pv);
}

static struct hdr_histogram* mk(int64_t lo, int64_t hi, int sig)
{
    struct hdr_histogram* h = NULL;
    if (hdr_init(lo, hi, sig, &h)) exit(1);
    return h;
}

/* rotate counts by k and set the offset, as a decoded/rotated histogram would look */
static struct hdr_histogram* rotated(const struct hdr_histogram* src, int32_t k)
{
    struct hdr_histogram* h = mk(src->lowest_discernible_value, src->highest_trackable_value, src->significant_figures);
    for (int32_t i = 0; i < src->counts_len; i++) h->counts[(i + k) % src->counts_len] = src->counts[i];
    h->normalizing_index_offset = k;
    h->total_count = src->total_count; h->min_value = src->min_value; h->max_value = src->max_value;
    return h;
}

int main(void)
{
    char tag[64];
    const int64_t HI = 3600000000LL;
    for (int it = 0; it < 600; it++) {
        struct hdr_histogram* h = mk(it % 5 == 0 ? 100 : 1, HI, 2 + it % 3);
        int shape = it % 12, n = 1 + (int)(rnd() % 400);
        switch (shape) {
        case 0: break;                                              /* empty */
        case 1: hdr_record_values(h, 0, 5); break;                  /* zeros only */
        case 2: hdr_record_values(h, 0, 3); hdr_record_values(h, 1000 + rnd() % 9000, 7); break;
        case 3: hdr_record_values(h, 12345, 1 + rnd() % 50); break; /* single bucket */
        case 4: hdr_record_value(h, HI); break;                     /* last bucket */
        case 5: for (int i = 0; i < n; i++) hdr_record_value(h, 800 + rnd() % 3000);
                hdr_record_value(h, 5000000); break;                /* body + outlier */
        case 6: for (int i = 0; i < 1000000 / 50; i++) hdr_record_value(h, 800 + rnd() % 3000);
                hdr_record_value(h, 900000000); break;              /* big body + far outlier */
        case 7: for (int i = 0; i < n; i++) hdr_record_value(h, 1 + rnd() % HI); break;
        case 8: for (int i = 0; i < n; i++) hdr_record_values(h, 1 + rnd() % 5000, 1 + rnd() % 40); break;
        case 9: hdr_record_values(h, 1000, 10); hdr_record_values(h, 900000, 90); break;
        case 10: hdr_record_values(h, 7, INT64_C(1) << 40); hdr_record_value(h, HI / 2); break;
        default: for (int i = 0; i < n; i++) hdr_record_value_atomic(h, 100 + rnd() % 100000); break;
        }
        snprintf(tag, sizeof tag, "plain%d_%d", shape, it);
        dump(tag, h);
        if (h->total_count > 0) {
            int32_t ks[3] = {1, 37 % h->counts_len, h->counts_len - 1};
            for (int j = 0; j < 3; j++) {
                struct hdr_histogram* r = rotated(h, ks[j]);
                snprintf(tag, sizeof tag, "rot%d_%d_%d", shape, it, ks[j]);
                dump(tag, r);
                hdr_close(r);
            }
        }
        hdr_close(h);
    }
    /* hostile / inconsistent states: results may legitimately be discussed, but must not crash or hit UB */
    for (int it = 0; it < 160; it++) {
        struct hdr_histogram* h = mk(1, HI, 3);
        for (int i = 0; i < 50; i++) hdr_record_value(h, 100 + rnd() % 100000);
        switch (it % 8) {
        case 0: h->total_count += 7; break;                         /* total larger than counts */
        case 1: h->total_count -= 3; break;                         /* smaller */
        case 2: h->max_value = 0; break;                            /* stale low */
        case 3: h->max_value = HI * 4; break;                       /* beyond range */
        case 4: hdr_record_values(h, 5000, -2); break;              /* negative count below the top */
        case 5: hdr_record_values(h, HI / 2, -2); break;            /* negative count in the top bucket */
        case 6: h->max_value = HI / 2; break;                       /* stale high, in range, empty bucket */
        default: h->counts[counts_index_for(h, HI / 2)] = INT64_MIN; h->max_value = HI / 2; break; /* extreme top count: total - cm would overflow */
        }
        snprintf(tag, sizeof tag, "hostile%d_%d", it % 8, it);
        dump(tag, h);
        hdr_close(h);
    }
    return 0;
}

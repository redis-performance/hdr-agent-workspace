/* Supplemental probe, NOT the immutable referee: the repository drivers measure only the
 * single-percentile query. This times hdr_value_at_percentiles (batch) against the same
 * percentiles queried one at a time. Public domain. Builds against 0.11.10 and later. */
#define _POSIX_C_SOURCE 200809L
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <hdr/hdr_histogram.h>

static double now(void)
{
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec / 1e9;
}

static int cmp(const void* a, const void* b)
{
    double x = *(const double*) a, y = *(const double*) b;
    return (x > y) - (x < y);
}

int main(void)
{
    static const double pct[] = {50.0, 75.0, 90.0, 95.0, 99.0, 99.9, 99.99, 99.999, 99.9999, 100.0};
    const int np = (int) (sizeof(pct) / sizeof(pct[0]));
    const int calls = 2000, passes = 7;
    struct hdr_histogram* h = NULL;
    uint64_t x = 88172645463325252ULL;
    double batch[16], single[16];
    int64_t out[16], sink = 0;
    int i, p, q;

    if (hdr_init(1, INT64_C(3600000000), 3, &h) != 0) return 1;
    for (i = 0; i < 2000000; i++)
    {
        int64_t v;
        x ^= x << 13; x ^= x >> 7; x ^= x << 17;
        v = (int64_t) (x % 1000) + 1;
        if ((x >> 20) % 16 == 0) v *= 100;
        if ((x >> 30) % 256 == 0) v *= 10000;
        hdr_record_value(h, v);
    }
    for (p = 0; p < passes; p++)
    {
        double t = now();
        for (q = 0; q < calls; q++) { hdr_value_at_percentiles(h, pct, out, (size_t) np); sink += out[q % np]; }
        batch[p] = (now() - t) * 1e9 / calls;
        t = now();
        for (q = 0; q < calls; q++) { for (i = 0; i < np; i++) sink += hdr_value_at_percentile(h, pct[i]); }
        single[p] = (now() - t) * 1e9 / calls;
    }
    qsort(batch, passes, sizeof(double), cmp);
    qsort(single, passes, sizeof(double), cmp);
    printf("counts_len=%d percentiles=%d | batch median %.1f ns/call-set | one-at-a-time median %.1f ns/call-set | sink=%" PRId64 "\n",
           h->counts_len, np, batch[passes / 2], single[passes / 2], sink);
    hdr_close(h);
    return 0;
}

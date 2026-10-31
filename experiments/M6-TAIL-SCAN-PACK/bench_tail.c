/* Out-of-tree timing for the tail-scan candidates (the repository drivers stay the immutable referee).
 * One line per case: TAIL <shape> <pct> <ns_per_call>   (best of REPS, single calls). */
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>
#include <hdr/hdr_histogram.h>

static uint64_t s = 88172645463325252ULL;
static double rnd(void) { s ^= s << 13; s ^= s >> 7; s ^= s << 17; return (s >> 11) * (1.0 / 9007199254740992.0); }
static double now(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return t.tv_sec * 1e9 + t.tv_nsec; }
static int64_t lognormal(double median, double sigma)
{
    double g = sqrt(-2.0 * log(rnd() + 1e-12)) * cos(6.283185307179586 * rnd());
    return (int64_t)(median * exp(sigma * g)) + 1;
}

enum { REPS = 7, CALLS = 20000 };
static const double PCT[] = {50.0, 90.0, 99.0, 99.9, 100.0};

static void run(const char* shape, struct hdr_histogram* h)
{
    volatile int64_t sink = 0;
    for (size_t p = 0; p < sizeof PCT / sizeof PCT[0]; p++) {
        double best = 1e30;
        for (int rep = 0; rep < REPS; rep++) {
            double t0 = now();
            for (int i = 0; i < CALLS; i++) sink += hdr_value_at_percentile(h, PCT[p]);
            double t = (now() - t0) / CALLS;
            if (t < best) best = t;
        }
        printf("TAIL %s p%g %.2f\n", shape, PCT[p], best);
    }
    if (sink == 0x7fffffff) puts("");
}

int main(void)
{
    struct hdr_histogram* h;
    /* 1: 1M-sample lognormal body (the shape used in the 0.12.1 release benchmarks) */
    hdr_init(1, 3600000000LL, 3, &h);
    for (int i = 0; i < 1000000; i++) hdr_record_value(h, lognormal(10000.0, 0.6));
    run("body1M", h);
    /* 2: same body plus one slow outlier far above it */
    hdr_record_value(h, 2000000000LL);
    run("body1M_outlier", h);
    hdr_close(h);
    /* 3: valkey-like INFO latencystats: 200 samples, 1ns..1s at 2 digits, one slow call */
    hdr_init(1, 1000000000LL, 2, &h);
    for (int i = 0; i < 200; i++) hdr_record_value(h, 800 + (int64_t)(rnd() * 3000));
    hdr_record_value(h, 5000000);
    run("valkey200_outlier", h);
    hdr_close(h);
    /* 4: same, no outlier (rank rarely in the top bucket) */
    hdr_init(1, 1000000000LL, 2, &h);
    for (int i = 0; i < 200; i++) hdr_record_value(h, 800 + (int64_t)(rnd() * 3000));
    run("valkey200", h);
    hdr_close(h);
    /* 5: narrow band far from index 0 (what skipping leading zeros would target) */
    hdr_init(1, 3600000000LL, 3, &h);
    for (int i = 0; i < 100000; i++) hdr_record_value(h, 50000000 + (int64_t)(rnd() * 1000000));
    run("band_far", h);
    hdr_close(h);
    return 0;
}

/* Matched microbench for HdrHistogram_c, mirroring the Go/Java workload so the C
 * port reports in the same format. Hand-rolled kbest (best of REPS x TARGET s),
 * which is the fair method for AOT code (no warmup/JIT to account for).
 *
 *   write_const  -> recordValue(100) in a loop (constant; lets any optimizer hoist the index)
 *   write_varied -> recordValue(vals[i]) from a shuffled 0..1e6 array (real ingestion; index recomputed)
 *   read         -> value_at_percentile(random pct) over a 1M log-normal(0,0.5) histogram
 *
 * volatile sink defeats dead-code elimination (the C analogue of JMH Blackhole).
 */
#define _GNU_SOURCE
#include "hdr_histogram.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <float.h>
#include <stdint.h>

static volatile int64_t sink;

static double now_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double) ts.tv_sec * 1e9 + (double) ts.tv_nsec;
}

static double gauss(void) { /* Box-Muller standard normal */
    double u1 = drand48(), u2 = drand48();
    if (u1 < 1e-300) u1 = 1e-300;
    return sqrt(-2.0 * log(u1)) * cos(2.0 * M_PI * u2);
}

int main(int argc, char** argv) {
    double TARGET = argc>1?atof(argv[1]):30.0;
    int REPS = argc>2?atoi(argv[2]):5;
    const int    N      = 1000000;
    const long   HI_W   = 10000000L;
    const long   HI_R   = 1000000L;

    /* write histogram: same params + pre-fill as BenchmarkHistogramRecordValue */
    struct hdr_histogram *wh;
    hdr_init(1, HI_W, 3, &wh);
    for (long i = 0; i < 1000000L; i++) hdr_record_value(wh, i);

    /* varied values in [0, 1e6) for the honest ingestion loop */
    int64_t *vals = malloc((size_t) N * sizeof(int64_t));
    srand48(999);
    for (int i = 0; i < N; i++) vals[i] = (int64_t) (drand48() * 1000000.0);

    /* read histogram: 1M log-normal(mu=0, sigma=0.5) scaled to [.., 1e6] */
    struct hdr_histogram *rh;
    hdr_init(1, HI_R, 3, &rh);
    double *raw = malloc((size_t) N * sizeof(double));
    double mn = DBL_MAX, mx = 0.0;
    srand48(12345);
    for (int i = 0; i < N; i++) {
        raw[i] = exp(gauss() * 0.5);
        if (raw[i] < mn) mn = raw[i];
        if (raw[i] > mx) mx = raw[i];
    }
    double k = (double) HI_R / (mx - mn);
    for (int i = 0; i < N; i++) {
        long v = (long) (k * raw[i]);
        if (v < 0) v = 0;
        if (v > HI_R) v = HI_R;
        hdr_record_value(rh, v);
    }
    double *pct = malloc((size_t) N * sizeof(double));
    srand48(67890);
    for (int i = 0; i < N; i++) pct[i] = drand48() * 100.0;

    double best_wc = 1e18, best_wv = 1e18, best_r = 1e18;
    for (int rep = 0; rep < REPS; rep++) {
        /* write constant */
        { double t0 = now_ns(); int64_t ops = 0;
          do { for (int j = 0; j < 1000000; j++) hdr_record_value(wh, 100);
               ops += 1000000; } while (now_ns() - t0 < TARGET * 1e9);
          double ns = (now_ns() - t0) / (double) ops; if (ns < best_wc) best_wc = ns; }
        /* write varied */
        { double t0 = now_ns(); int64_t ops = 0; int idx = 0;
          do { for (int j = 0; j < 1000000; j++) { hdr_record_value(wh, vals[idx]); if (++idx == N) idx = 0; }
               ops += 1000000; } while (now_ns() - t0 < TARGET * 1e9);
          double ns = (now_ns() - t0) / (double) ops; if (ns < best_wv) best_wv = ns; }
        /* read */
        { double t0 = now_ns(); int64_t ops = 0; int idx = 0;
          do { for (int j = 0; j < 100000; j++) { sink = hdr_value_at_percentile(rh, pct[idx]); if (++idx == N) idx = 0; }
               ops += 100000; } while (now_ns() - t0 < TARGET * 1e9);
          double ns = (now_ns() - t0) / (double) ops; if (ns < best_r) best_r = ns; }
        fprintf(stderr, "  rep %d done\n", rep);
    }

    printf("C_write_const_ns=%.4f\n", best_wc);
    printf("C_write_varied_ns=%.4f\n", best_wv);
    printf("C_read_ns=%.4f\n", best_r);
    return 0;
}

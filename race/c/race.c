/* Cross-port race driver — C. Identical workload to race/go and race/rust.
 * WRITE : record v=1..50M into New(1,3.6e9,3), 5 reps, best ops/sec.
 * READ  : populate 1M Fibonacci-spread values, query 7 percentiles x 1M (singular), best Mq/s.
 * BATCH : value_at_percentiles(all 7) x 100k calls, best batch-calls/sec.
 * sink/bsink are cross-port correctness checks (must match Go/Rust). */
#include <hdr/hdr_histogram.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>

static double now_sec(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec + (double)t.tv_nsec / 1e9;
}

int main(void) {
    struct hdr_histogram* h;
    if (hdr_init(1, 3600000000LL, 3, &h) != 0) { fprintf(stderr, "init failed\n"); return 1; }

    const int64_t NW = 50000000LL;
    double best_ops = 0;
    for (int rep = 0; rep < 5; rep++) {
        hdr_reset(h);
        double t0 = now_sec();
        for (int64_t v = 1; v <= NW; v++) hdr_record_value(h, v);
        double dt = now_sec() - t0;
        double ops = (double)NW / dt;
        if (ops > best_ops) best_ops = ops;
    }
    printf("WRITE_OPS_PER_SEC %.0f\n", best_ops);

    hdr_reset(h);
    for (int64_t v = 1; v <= 1000000LL; v++) {
        int64_t value = (int64_t)(((uint64_t)v * 2654435761ULL) % 1000000000ULL) + 1;
        hdr_record_value(h, value);
    }
    const double pcts[7] = {50.0, 75.0, 90.0, 95.0, 99.0, 99.9, 99.99};

    /* READ — singular value_at_percentile */
    const int64_t NQ = 1000000LL;
    double best_qps = 0;
    int64_t sink = 0;
    for (int run = 0; run < 13; run++) {
        double t0 = now_sec();
        for (int64_t i = 0; i < NQ; i++) sink += hdr_value_at_percentile(h, pcts[i % 7]);
        double dt = now_sec() - t0;
        if (run >= 3) { double qps = (double)NQ / dt; if (qps > best_qps) best_qps = qps; }
    }
    printf("READ_MQ_PER_SEC %.4f sink=%lld\n", best_qps / 1e6, (long long)sink);

    /* BATCH — value_at_percentiles: all 7 percentiles per call (single pass) */
    const int NB = 100000;
    double best_bops = 0;
    int64_t bsink = 0;
    int64_t vals[7];
    for (int run = 0; run < 7; run++) {
        double t0 = now_sec();
        for (int i = 0; i < NB; i++) {
            hdr_value_at_percentiles(h, pcts, vals, 7);
            for (int k = 0; k < 7; k++) bsink += vals[k];
        }
        double dt = now_sec() - t0;
        if (run >= 2) { double bops = (double)NB / dt; if (bops > best_bops) best_bops = bops; }
    }
    printf("BATCH_OPS_PER_SEC %.0f bsink=%lld\n", best_bops, (long long)bsink);
    return 0;
}

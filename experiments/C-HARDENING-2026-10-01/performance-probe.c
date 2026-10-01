/* Supplemental bounded workload; immutable acceptance drivers remain unchanged. */
#define _POSIX_C_SOURCE 200809L
#include <assert.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>
#include <hdr/hdr_histogram.h>

static double now(void)
{
    struct timespec t;
    assert(clock_gettime(CLOCK_MONOTONIC, &t) == 0);
    return (double)t.tv_sec + (double)t.tv_nsec / 1e9;
}

int main(void)
{
    const int writes = 2000000;
    const int reads = 20000;
    const double percentiles[] = {50, 99, 99.9};
    for (int digits = 2; digits <= 3; digits++) {
        struct hdr_histogram *h = NULL;
        assert(hdr_init(1, INT64_C(1000000000), digits, &h) == 0);
        for (int run = 0; run < 9; run++) {
            hdr_reset(h);
            double start = now();
            for (int i = 1; i <= writes; i++)
                hdr_record_value(h, i);
            double write_ns = (now() - start) * 1e9 / writes;
            assert(h->total_count == writes);
            hdr_reset(h);
            for (int i = 0; i < 100000; i++) {
                int64_t value = 1 + (uint64_t)i * 7919 % 1000000000;
                assert(hdr_record_value(h, value));
            }
            int64_t sum = 0;
            start = now();
            for (int i = 0; i < reads; i++)
                sum += hdr_value_at_percentile(h, percentiles[i % 3]);
            double read_ns = (now() - start) * 1e9 / reads;
            printf("%d,%d,%.3f,%.3f,%" PRId64 "\n", digits, run, write_ns, read_ns, sum);
        }
        hdr_close(h);
    }
    return 0;
}

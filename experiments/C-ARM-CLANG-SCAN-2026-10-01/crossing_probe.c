/* Supplemental distribution probe; immutable acceptance drivers are unchanged.
 * Released to the public domain.
 */
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
    return t.tv_sec + t.tv_nsec / 1e9;
}

int main(void)
{
    const int64_t positions[] = {0, 1, 2, 3, 4, 7, 15, 31, 63, 127, 255, 511, 1023};
    const int queries = 2000000;
    for (int digits = 2; digits <= 3; digits++)
    {
        struct hdr_histogram* h = NULL;
        assert(hdr_init(1, INT64_C(1000000000), digits, &h) == 0);
        for (unsigned position = 0; position < sizeof(positions) / sizeof(positions[0]); position++)
        {
            hdr_reset(h);
            int64_t value = hdr_value_at_index(h, positions[position]);
            assert(hdr_record_values(h, value, 100000));
            for (int run = 0; run < 7; run++)
            {
                int64_t sum = 0;
                double start = now();
                for (int q = 0; q < queries; q++)
                    sum += hdr_value_at_percentile(h, 99.0);
                double ns = (now() - start) * 1e9 / queries;
                printf("%d,%" PRId64 ",%d,%.3f,%" PRId64 "\n", digits, positions[position], run, ns, sum);
            }
        }
        hdr_close(h);
    }
    return 0;
}

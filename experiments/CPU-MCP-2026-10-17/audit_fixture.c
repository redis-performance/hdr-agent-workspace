/* Untimed reconstruction of the preserved packed write fixture's working set. */
#include <inttypes.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <hdr/hdr_histogram.h>
#include "hdr_histogram_internal.h"

static uint64_t state;
static int64_t sample(double spread)
{
    state ^= state << 13;
    state ^= state >> 7;
    state ^= state << 17;
    double u = (double)(state % 1000000) / 1e6;
    double v = 200.0 * exp(spread * u);
    if (v > 1e9) v = 1e9;
    if (v < 1) v = 1;
    return (int64_t)v;
}

int main(void)
{
    const double spreads[] = {1.2, 2.2, 3.2};
    struct hdr_histogram *h = NULL;
    if (hdr_init(1, 1000000000, 2, &h)) return 1;
    unsigned char *seen = calloc((size_t)h->counts_len, 1);
    if (!seen) { hdr_close(h); return 1; }
    puts("spread,populated,active_index_bytes,index_capacity_bytes,query_prefix,same_bucket,adjacent_virtual_bucket,unpopulated_queries,historical_sample_bytes");
    for (size_t s = 0; s < sizeof spreads / sizeof *spreads; ++s)
    {
        for (int32_t i = 0; i < h->counts_len; ++i) seen[i] = 0;
        state = 99;
        int32_t populated = 0;
        for (int i = 0; i < 500000; ++i)
        {
            int32_t idx = counts_index_for(h, sample(spreads[s]));
            if (idx < 0 || idx >= h->counts_len) return 2;
            if (!seen[idx]) { seen[idx] = 1; ++populated; }
        }
        int32_t capacity = 4;
        while (capacity < populated) capacity *= 2;
        state = 12345;
        int32_t previous = -1;
        int same = 0, adjacent = 0, missing = 0;
        /* This is a bounded prefix audit, not a timed execution of the benchmark. */
        for (int i = 0; i < 8192; ++i)
        {
            int32_t idx = counts_index_for(h, sample(spreads[s]));
            if (idx < 0 || idx >= h->counts_len) return 2;
            missing += !seen[idx];
            if (i) {
                same += idx == previous;
                adjacent += idx == previous + 1 || idx == previous - 1;
            }
            previous = idx;
        }
        printf("%.1f,%" PRId32 ",%" PRId32 ",%" PRId32 ",8192,%d,%d,%d,64000000\n",
               spreads[s], populated, populated * 4, capacity * 4,
               same, adjacent, missing);
    }
    free(seen);
    hdr_close(h);
    return 0;
}

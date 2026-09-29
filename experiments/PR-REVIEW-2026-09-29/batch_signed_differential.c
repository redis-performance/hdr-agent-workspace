/* Released to the public domain under CC0. */
#include <hdr/hdr_histogram.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static uint64_t state = UINT64_C(0x29102026);
static uint64_t next_random(void)
{
    state ^= state << 13;
    state ^= state >> 7;
    state ^= state << 17;
    return state;
}
int main(void)
{
    struct hdr_histogram *h = NULL, *rotated = NULL;
    const double pcts[] = {0, 1, 10, 50, 90, 99, 100};
    int64_t expected[7], actual[7];
    if (hdr_init(1, 1000, 3, &h) || hdr_init(1, 1000, 3, &rotated)) return 1;
    for (unsigned test = 0; test < 10000; test++)
    {
        hdr_reset(h);
        for (unsigned j = 0; j < 64; j++)
            if (!hdr_record_values(h, (int64_t)(next_random() % 512),
                                   (int64_t)(next_random() % 11) - 5)) abort();
        if (!hdr_record_values(h, 900, 100 + llabs(h->total_count))) abort();
        for (unsigned p = 0; p < 7; p++)
        {
            int64_t target = (int64_t) ((pcts[p] / 100.0) * h->total_count + 0.5);
            int64_t running = 0;
            if (target < 1) target = 1;
            expected[p] = 0;
            for (int32_t j = 0; j < h->counts_len; j++)
            {
                running += h->counts[j];
                if (running >= target)
                {
                    /* All recorded values use exact unit-width buckets. */
                    expected[p] = hdr_value_at_index(h, j);
                    break;
                }
            }
        }
        rotated->normalizing_index_offset = 37;
        rotated->total_count = h->total_count;
        for (int32_t j = 0; j < h->counts_len; j++)
            rotated->counts[j] = h->counts[(j + 37) % h->counts_len];
        for (int mode = 0; mode < 2; mode++)
        {
            if (hdr_value_at_percentiles(mode ? rotated : h, pcts, actual, 7) ||
                memcmp(expected, actual, sizeof(expected)))
            {
                fprintf(stderr, "Mismatch case=%u offset=%d\n", test, mode ? 37 : 0);
                return 1;
            }
        }
    }
    hdr_close(h);
    hdr_close(rotated);
    puts("PASS 10000 signed-count distributions x 2 offsets x 7 percentiles; seed 0x29102026");
    return 0;
}

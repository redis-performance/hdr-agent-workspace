/* Locate the exact crossing indices for the unchanged read driver's input. */
#include <hdr/hdr_histogram.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

int main(void)
{
    struct hdr_histogram* h = NULL;
    const double percentiles[] = {50.0, 75.0, 90.0, 95.0, 99.0, 99.9, 99.99};
    if (hdr_init(1, INT64_C(3600000000), 3, &h) != 0)
        return 1;

    for (int64_t v = 1; v <= 1000000; v++)
    {
        int64_t value = (int64_t)(((uint64_t)v * 2654435761u) % 1000000000u) + 1;
        if (!hdr_record_value(h, value))
            return 2;
    }

    printf("counts_len=%d total_count=%" PRId64 "\n", h->counts_len, h->total_count);
    for (unsigned p = 0; p < sizeof(percentiles) / sizeof(percentiles[0]); p++)
    {
        int64_t target = (int64_t)(((percentiles[p] / 100.0) * h->total_count) + 0.5);
        if (target < 1)
            target = 1;
        int64_t running = 0;
        for (int32_t i = 0; i < h->counts_len; i++)
        {
            running += hdr_count_at_index(h, i);
            if (running >= target)
            {
                printf("percentile=%.2f crossing_index=%d full_four_count_blocks=%d\n",
                       percentiles[p], i, i / 4);
                break;
            }
        }
    }
    hdr_close(h);
    return 0;
}

/* Read-only behavioral probe for population review; no performance timing.
 * Released to the public domain. */
#include <hdr/hdr_histogram.h>
#include <inttypes.h>
#include <stdio.h>

int main(void)
{
    struct hdr_histogram* h = NULL;
    if (hdr_init(1, 1000000000, 3, &h)) return 1;
    int accepted = hdr_record_values(h, 16, 2) &&
        hdr_record_values(h, 20, -2) && hdr_record_values(h, 48, 2);
    printf("negative_bucket: accepted=%d total=%"PRId64" p50=%"PRId64"\n",
        accepted, h->total_count, hdr_value_at_percentile(h, 50));
    const double median[] = {50};
    int64_t median_out[1];
    if (hdr_value_at_percentiles(h, median, median_out, 1)) return 1;
    printf("negative_bucket_batch: p50=%"PRId64"\n", median_out[0]);
    hdr_reset(h);
    accepted = hdr_record_values(h, 20, -2) && hdr_record_values(h, 48, 4);
    if (hdr_value_at_percentiles(h, median, median_out, 1)) return 1;
    printf("negative_prefix_batch: accepted=%d total=%"PRId64" p50=%"PRId64"\n",
        accepted, h->total_count, median_out[0]);
    hdr_reset(h);
    accepted = hdr_record_values(h, 16, 2) && hdr_record_values(h, 20, -2);
    if (hdr_value_at_percentiles(h, median, median_out, 1)) return 1;
    printf("zero_sum_nonempty_batch: accepted=%d total=%"PRId64" p50=%"PRId64"\n",
        accepted, h->total_count, median_out[0]);
    hdr_close(h);
    if (hdr_init(1024, 1000000000, 3, &h)) return 1;
    const double pcts[] = {0, 50, 100};
    int64_t batch[3];
    if (hdr_value_at_percentiles(h, pcts, batch, 3)) return 1;
    printf("coarse_empty: p0=%"PRId64" p50=%"PRId64" p100=%"PRId64
        " batch=%"PRId64",%"PRId64",%"PRId64"\n",
        hdr_value_at_percentile(h, 0), hdr_value_at_percentile(h, 50),
        hdr_value_at_percentile(h, 100), batch[0], batch[1], batch[2]);
    hdr_close(h);
    if (hdr_init(1, 1000000000, 3, &h)) return 1;
    if (!hdr_record_values(h, 16, INT64_C(9007199254740995))) return 1;
    const double top[] = {100};
    if (hdr_value_at_percentiles(h, top, median_out, 1)) return 1;
    printf("large_nonnegative: total=%"PRId64" singular_p100=%"PRId64
        " batch_p100=%"PRId64"\n", h->total_count,
        hdr_value_at_percentile(h, 100), median_out[0]);
    hdr_close(h);
    return 0;
}

/* Prints every behaviour the 0.12.1 notes claim, so old (0.12.0) and new (main) can be diffed. Build against each release's static library. */
#include <inttypes.h>
#include <math.h>
#include <stdio.h>
#include <hdr/hdr_histogram.h>
#include <hdr/hdr_packed_histogram.h>
static int64_t b1(struct hdr_histogram *h, double p) { int64_t v = -999; hdr_value_at_percentiles(h, &p, &v, 1); return v; }
int main(void) {
    struct hdr_histogram *h = NULL; struct hdr_packed_histogram *pk = NULL;
    int64_t lows[] = {1, 100};
    for (int i = 0; i < 2; i++) {
        hdr_init(lows[i], 10000000, 3, &h);
        printf("empty lowest=%" PRId64 ": single p0/p50/p100 = %" PRId64 "/%" PRId64 "/%" PRId64 "  batch p0/p50/p100 = %" PRId64 "/%" PRId64 "/%" PRId64 "\n", lows[i],
               hdr_value_at_percentile(h, 0), hdr_value_at_percentile(h, 50), hdr_value_at_percentile(h, 100), b1(h, 0), b1(h, 50), b1(h, 100));
        hdr_close(h);
    }
    hdr_init(1, 3600000000LL, 3, &h); hdr_packed_init(1, 3600000000LL, 3, &pk);
    printf("empty: hdr_min=%" PRId64 " packed_min=%" PRId64 " max=%" PRId64 " dense mean_nan=%d stddev_nan=%d packed mean=%.1f\n", hdr_min(h), hdr_packed_min(pk), hdr_max(h), !!isnan(hdr_mean(h)), !!isnan(hdr_stddev(h)), hdr_packed_mean(pk));
    hdr_close(h); hdr_packed_close(pk);
    hdr_init(100, 10000000, 3, &h); hdr_record_value(h, 5000);
    printf("one value 5000, lowest=100: single p0=%" PRId64 " batch p0=%" PRId64 " batch p50=%" PRId64 " min=%" PRId64 "\n", hdr_value_at_percentile(h, 0), b1(h, 0), b1(h, 50), hdr_min(h));
    hdr_close(h);
    hdr_init(1, 1000000000, 3, &h); hdr_record_values(h, 10001, (INT64_C(1) << 53) + 3);
    printf("2^53+3 of 10001: single p100=%" PRId64 " batch p100=%" PRId64 " max=%" PRId64 "\n", hdr_value_at_percentile(h, 100), b1(h, 100), hdr_max(h));
    hdr_reset(h); hdr_record_values(h, 10001, INT64_C(1) << 53); hdr_record_value(h, 20001);
    printf("2^53 of 10001 + one 20001: single p100=%" PRId64 " batch p100=%" PRId64 " max=%" PRId64 "\n", hdr_value_at_percentile(h, 100), b1(h, 100), hdr_max(h));
    hdr_close(h);
    hdr_init(1, 1000000000, 3, &h); hdr_record_value(h, 10001);
    printf("-inf (UB cast before): single=%" PRId64 " batch=%" PRId64 "   NaN: single=%" PRId64 " batch=%" PRId64 "\n", hdr_value_at_percentile(h, -INFINITY), b1(h, -INFINITY), hdr_value_at_percentile(h, NAN), b1(h, NAN));
    hdr_close(h);
    hdr_init(1, 1000000000, 3, &h); hdr_record_values(h, 10001, INT64_MAX);
    printf("INT64_MAX obs p100 (UB cast before): single=%" PRId64 " batch=%" PRId64 "\n", hdr_value_at_percentile(h, 100), b1(h, 100));
    hdr_close(h);
    return 0;
}

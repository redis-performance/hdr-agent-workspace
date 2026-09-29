/* Released to the public domain under CC0. Review-only API probes. */
#include <hdr/hdr_histogram.h>
#include <hdr/hdr_time.h>
#include <inttypes.h>
#include <math.h>
#include <stdio.h>
#include <string.h>

static void iterator_probe(void)
{
    struct hdr_histogram *h = NULL;
    struct hdr_iter it;
    if (hdr_init(1, INT64_MAX, 3, &h)) return;
    hdr_record_value(h, 5);
    hdr_record_value(h, INT64_MAX);
    for (int mode = 0; mode < 2; mode++)
    {
        int steps = 0;
        int64_t last = -1, emitted = 0;
        if (mode) hdr_iter_log_init(&it, h, 1, 2.0);
        else hdr_iter_linear_init(&it, h, (int64_t)(UINT64_C(1) << 62));
        while (hdr_iter_next(&it) && steps < 1000)
        {
            steps++;
            last = it.value_iterated_to;
            emitted += mode ? it.specifics.log.count_added_in_this_iteration_step
                            : it.specifics.linear.count_added_in_this_iteration_step;
        }
        printf("%s steps=%d last=%" PRId64 " emitted=%" PRId64 " total=%" PRId64 "\n",
               mode ? "log" : "linear", steps, last, emitted, h->total_count);
    }
    hdr_close(h);
}

static void batch_probe(void)
{
    struct hdr_histogram *h = NULL;
    double p = 50;
    int64_t value = -1;
    if (hdr_init(1, 1000, 3, &h)) return;
    int accepted = hdr_record_values(h, 16, 2) && hdr_record_values(h, 20, -2)
                   && hdr_record_values(h, 48, 2);
    hdr_value_at_percentiles(h, &p, &value, 1);
    printf("signed-prefix accepted=%d total=%" PRId64 " singular=%" PRId64 " batch=%" PRId64 "\n",
           accepted, h->total_count, hdr_value_at_percentile(h, p), value);
    hdr_reset(h);
    hdr_record_values(h, 16, 1);
    hdr_record_values(h, 20, -1);
    hdr_value_at_percentiles(h, &p, &value, 1);
    printf("zero-total signed state batch=%" PRId64 "\n", value);
    hdr_close(h);
}

static void time_probe(void)
{
    const double values[] = {-0.0005, -0.0015, -1.0005, -2.5, 1.9996, 2147483648.0};
    for (size_t i = 0; i < sizeof(values) / sizeof(values[0]); i++)
    {
        hdr_timespec ts;
        hdr_timespec_from_double(&ts, values[i]);
        printf("%.17g -> {%.0f,%ld} -> %.17g\n", values[i],
               (double)ts.tv_sec, ts.tv_nsec, hdr_timespec_as_double(&ts));
    }
}

int main(int argc, char **argv)
{
    if (argc != 2) return 2;
    if (!strcmp(argv[1], "iterator")) iterator_probe();
    else if (!strcmp(argv[1], "batch")) batch_probe();
    else if (!strcmp(argv[1], "time")) time_probe();
    else return 2;
    return 0;
}

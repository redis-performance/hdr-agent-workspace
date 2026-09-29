/* Released to the public domain under CC0. */
#include <hdr/hdr_histogram.h>
#include <inttypes.h>
#include <stdio.h>
int main(void)
{
    struct hdr_histogram* h = NULL;
    const double bases[] = {1.5, 2.0, 2.5};
    if (hdr_init(1, 1000, 3, &h)) return 1;
    hdr_record_value(h, 100);
    for (unsigned i = 0; i < sizeof(bases)/sizeof(bases[0]); i++)
    {
        struct hdr_iter it;
        int steps = 0;
        int64_t last = 0, counted = 0;
        hdr_iter_log_init(&it, h, 1, bases[i]);
        while (steps < 100 && hdr_iter_next(&it))
        {
            steps++;
            last = it.value_iterated_to;
            counted += it.specifics.log.count_added_in_this_iteration_step;
        }
        printf("base=%.1f steps=%d last=%" PRId64 " counted=%" PRId64 " max=%" PRId64 "\n",
               bases[i], steps, last, counted, hdr_max(h));
    }
    hdr_close(h);
    return 0;
}

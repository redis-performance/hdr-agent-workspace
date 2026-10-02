/* Supplemental probe: memory of N sparsely populated histograms, dense vs hdr_packed_histogram.
 * Needs 0.12.0 or later. Public domain. */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <hdr/hdr_histogram.h>
#include <hdr/hdr_packed_histogram.h>

int main(void)
{
    const int n = 1000, distinct = 10;
    struct hdr_packed_config* cfg = NULL;
    struct hdr_histogram* d = NULL;
    size_t dense_each, packed_total = 0;
    int i, j;

    if (hdr_init(1, INT64_C(3600000000), 3, &d)) return 1;
    dense_each = hdr_get_memory_size(d);
    hdr_close(d);
    if (hdr_packed_config_create(1, INT64_C(3600000000), 3, &cfg)) return 2;
    packed_total = hdr_packed_config_memory_size(cfg);
    for (i = 0; i < n; i++)
    {
        struct hdr_packed_histogram* p = NULL;
        if (hdr_packed_init_shared(cfg, &p)) return 3;
        for (j = 0; j < distinct; j++) hdr_packed_record_value(p, (int64_t) (j + 1) * 1000 + i % 7);
        packed_total += hdr_packed_get_memory_size(p);
        hdr_packed_close(p);
    }
    printf("%d histograms x %d distinct buckets: dense %.2f MB, packed %.2f KB (shared geometry included) -> %.0fx smaller\n",
           n, distinct, dense_each * (double) n / 1e6, packed_total / 1e3, dense_each * (double) n / (double) packed_total);
    hdr_packed_config_destroy(cfg);
    return 0;
}

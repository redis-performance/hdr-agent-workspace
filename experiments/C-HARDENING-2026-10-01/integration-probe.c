/* Supplemental consumer contract check; not a benchmark driver. */
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "hdr_histogram.h"

#ifdef VALKEY_ALLOCATORS
#define zmalloc valkey_malloc
#define zrealloc valkey_realloc
#define zfree valkey_free
#endif

static int live_allocations;
static int allocation_calls;

void *zmalloc(size_t size)
{
    void *p = malloc(size);
    assert(p);
    live_allocations++;
    allocation_calls++;
    return p;
}

void *zcalloc_num(size_t count, size_t size)
{
    void *p = calloc(count, size);
    assert(p);
    live_allocations++;
    allocation_calls++;
    return p;
}

void *zrealloc(void *p, size_t size)
{
    if (!p) return zmalloc(size);
    p = realloc(p, size);
    assert(p);
    return p;
}

void zfree(void *p)
{
    if (p) live_allocations--;
    free(p);
}

int main(void)
{
    struct hdr_histogram *h = NULL;
    assert(hdr_init(1, INT64_C(1000000000), 2, &h) == 0);
    assert(allocation_calls >= 2 && live_allocations == 2);
    assert(hdr_record_value(h, 5000000));
    struct hdr_iter iter;
    hdr_iter_linear_init(&iter, h, 100);
    while (hdr_iter_next(&iter) && iter.highest_equivalent_value <= 2000) {}
    hdr_iter_linear_set_value_units_per_bucket(&iter, 1000);
    assert(iter.specifics.linear.value_units_per_bucket == 1000);
    int64_t count = iter.cumulative_count;
    while (hdr_iter_next(&iter)) count = iter.cumulative_count;
    assert(count == 1);
    printf("allocator adapters and iterator extension: PASS; bytes=%zu\n",
           hdr_get_memory_size(h));
    hdr_close(h);
    assert(live_allocations == 0);
    return 0;
}

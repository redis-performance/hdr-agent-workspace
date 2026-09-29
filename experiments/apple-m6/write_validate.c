/* Supplemental recording oracle and physical-rotation metamorphism.
 * Correctness only; released to the public domain. */
#include <hdr/hdr_histogram.h>
#include <inttypes.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static uint64_t operations, bucket_checks, cases;
static void require(int ok, const char* what)
{
    if (!ok) { fprintf(stderr, "write validation: %s\n", what); exit(1); }
}

/* Deliberately use repeated division, not the production CLZ/index helper. */
static int index_for(const struct hdr_histogram* h, int64_t value)
{
    uint64_t sub = (uint64_t)value / (UINT64_C(1) << (unsigned)h->unit_magnitude);
    int bucket = 0;
    while (sub >= (uint64_t)h->sub_bucket_count) { sub /= 2; bucket++; }
    return bucket * h->sub_bucket_half_count + (int)sub;
}

static void reverse(int64_t* a, int begin, int end)
{
    while (begin < --end) { int64_t t = a[begin]; a[begin++] = a[end]; a[end] = t; }
}

/* A physical left rotation, independently of normalize_index's wrap branches. */
static void rotate(int64_t* a, int n, int offset)
{
    int left = offset % n;
    if (left < 0) left += n;
    reverse(a, 0, left); reverse(a, left, n); reverse(a, 0, n);
}

static int record(struct hdr_histogram* h, int api, int64_t value, int64_t count)
{
    switch (api)
    {
        case 0: return hdr_record_value(h, value);
        case 1: return hdr_record_value_atomic(h, value);
        case 2: return hdr_record_values(h, value, count);
        default: return hdr_record_values_atomic(h, value, count);
    }
}

static void apply(struct hdr_histogram* h, struct hdr_histogram* logical,
    int64_t* expected, int api, int64_t value, int64_t count,
    int64_t* total, int64_t* min, int64_t* max)
{
    if (api < 2) count = 1;
    int valid = value >= 0 && value <= h->highest_trackable_value;
    require(record(h, api, value, count) == valid, "accept/reject rotated");
    require(record(logical, api, value, count) == valid, "accept/reject logical");
    if (valid)
    {
        int idx = index_for(h, value);
        require(idx >= 0 && idx < h->counts_len, "oracle index");
        expected[idx] += count;
        *total += count;
        if (value != 0 && value < *min) *min = value;
        if (value > *max) *max = value;
    }
    operations += 2;
    require(h->total_count == *total && logical->total_count == *total, "total");
    require(h->min_value == *min && logical->min_value == *min, "raw min");
    require(h->max_value == *max && logical->max_value == *max, "raw max");
}

static void compare(struct hdr_histogram* h, struct hdr_histogram* logical,
    const int64_t* expected, int64_t* scratch)
{
    size_t bytes = (size_t)h->counts_len * sizeof(*expected);
    require(memcmp(logical->counts, expected, bytes) == 0, "logical buckets");
    memcpy(scratch, expected, bytes);
    rotate(scratch, h->counts_len, h->normalizing_index_offset);
    require(memcmp(h->counts, scratch, bytes) == 0, "rotated physical buckets");
    bucket_checks += (uint64_t)h->counts_len * 2;
}

static void geometry(int sig, int64_t low, int64_t high)
{
    struct hdr_histogram *h = NULL, *logical = NULL;
    require(hdr_init(low, high, sig, &h) == 0, "init");
    require(hdr_init(low, high, sig, &logical) == 0, "logical init");
    size_t bytes = (size_t)h->counts_len * sizeof(int64_t);
    int64_t* expected = calloc((size_t)h->counts_len, sizeof(*expected));
    int64_t* scratch = malloc(bytes);
    require(expected && scratch, "allocation");
    int offsets[] = {0, 1, -1, h->counts_len - 1, 1 - h->counts_len};
    for (int api = 0; api < 4; api++)
    for (unsigned o = 0; o < sizeof(offsets) / sizeof(offsets[0]); o++)
    {
        hdr_reset(h); hdr_reset(logical); memset(expected, 0, bytes);
        h->normalizing_index_offset = 0;
        logical->normalizing_index_offset = 0;
        int64_t total = 0, min = INT64_MAX, max = 0;
        /* Seed a nonempty logical state, then physically rotate it. */
        apply(h, logical, expected, api, low, 4, &total, &min, &max);
        apply(h, logical, expected, api, high / 2, 4, &total, &min, &max);
        rotate(h->counts, h->counts_len, offsets[o]);
        h->normalizing_index_offset = offsets[o];
        compare(h, logical, expected, scratch);
        /* Rejected calls must preserve every bucket, metadata and geometry. */
        const int64_t invalid[] = {INT64_MIN, -1, high < INT64_MAX ? high + 1 : -2};
        for (unsigned i = 0; i < sizeof(invalid) / sizeof(invalid[0]); i++)
        {
            struct hdr_histogram before;
            memcpy(&before, h, sizeof(before));
            apply(h, logical, expected, api, invalid[i], -7, &total, &min, &max);
            require(memcmp(&before, h, sizeof(before)) == 0, "rejection header mutation");
            compare(h, logical, expected, scratch);
        }
        if (api >= 2)
        {
            apply(h, logical, expected, api, 1, 0, &total, &min, &max);
            apply(h, logical, expected, api, high, 0, &total, &min, &max);
            compare(h, logical, expected, scratch);
        }
        apply(h, logical, expected, api, 0, 3, &total, &min, &max);
        apply(h, logical, expected, api, 1, 3, &total, &min, &max);
        apply(h, logical, expected, api, high, 3, &total, &min, &max);
        /* Powers of two and neighbors, including coarse-unit boundaries. */
        for (unsigned bit = 0; bit < 63; bit++)
        {
            int64_t edge = (int64_t)(UINT64_C(1) << bit);
            if (edge > high) break;
            for (int delta = -1; delta <= 1; delta++)
            {
                int64_t value = edge + delta;
                if (value > high) continue;
                apply(h, logical, expected, api, value, 3, &total, &min, &max);
                if (api >= 2)
                {
                    apply(h, logical, expected, api, value, 0, &total, &min, &max);
                    apply(h, logical, expected, api, value, -1, &total, &min, &max);
                }
            }
        }
        /* Sample bin boundaries across the whole allocated geometry. */
        int stride = h->counts_len / 97 + 1;
        for (int idx = 0; idx < h->counts_len; idx += stride)
        {
            int64_t edge = hdr_value_at_index(logical, idx);
            if (edge < 0 || edge > high) continue;
            apply(h, logical, expected, api, edge, 3, &total, &min, &max);
            if (edge > 0) apply(h, logical, expected, api, edge - 1, 3, &total, &min, &max);
        }
        compare(h, logical, expected, scratch);
        require(h->normalizing_index_offset == offsets[o], "offset mutation");
        cases++;
    }
    free(scratch); free(expected); hdr_close(logical); hdr_close(h);
}

int main(void)
{
    const int64_t lows[] = {1, 16, 1024};
    for (int sig = 1; sig <= 5; sig++)
        for (unsigned i = 0; i < sizeof(lows) / sizeof(lows[0]); i++)
            geometry(sig, lows[i], INT64_C(1000000000));
    geometry(1, 1, INT64_MAX);
    geometry(3, 1024, INT64_MAX);
    printf("{\"write_cases\":%"PRIu64",\"record_calls\":%"PRIu64
        ",\"bucket_comparisons\":%"PRIu64"}\n", cases, operations, bucket_checks);
    return 0;
}

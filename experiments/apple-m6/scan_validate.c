/* Seeded scan-boundary and valid-removal oracle checks, suitable for sanitizers.
 * Released to the public domain. */
#define main common_bench_main
#include "bench.c"
#undef main

int main(void)
{
    static const double pcts[] = {0, 0.001, 0.1, 1, 10, 25, 50, 75, 90, 99, 99.9, 100};
    uint64_t checks = 0;
    for (int sig = 1; sig <= 5; sig++)
    {
        struct hdr_histogram* h = make_hist(sig);
        for (int trial = 0; trial < 64; trial++)
        {
            hdr_reset(h); h->normalizing_index_offset = 0;
            for (int j = 0; j < 128; j++)
            {
                int32_t idx;
                if (trial < 8) idx = (trial * 16 + j % 3) % h->counts_len;
                else if (trial < 16) idx = h->counts_len - 1 - j % 40;
                else idx = (int32_t)(next_random() % (uint32_t)h->counts_len);
                uint64_t count = next_random() % 1000000U + 1;
                /* Public layout allows direct construction without assuming an
                   inverse record mapping for the partially populated top bucket. */
                h->counts[idx] += (int64_t)count;
                h->total_count += (int64_t)count;
            }
            int32_t offsets[] = {0, 1, -1, h->counts_len - 1, 1 - h->counts_len};
            for (size_t o = 0; o < sizeof(offsets)/sizeof(offsets[0]); o++)
            {
                h->normalizing_index_offset = offsets[o];
                for (size_t p = 0; p < sizeof(pcts)/sizeof(pcts[0]); p++)
                {
                    if (hdr_value_at_percentile(h, pcts[p]) != oracle(h, pcts[p]))
                        fail("scan boundary mismatch");
                    checks++;
                }
            }
        }
        hdr_reset(h); h->normalizing_index_offset = 0;
        if (!hdr_record_values(h, 1000, 10000) || !hdr_record_values(h, 1000, -5000) ||
            !hdr_record_values(h, 500000, 10000)) fail("valid removal");
        for (size_t p = 0; p < sizeof(pcts)/sizeof(pcts[0]); p++)
        {
            if (hdr_value_at_percentile(h, pcts[p]) != oracle(h, pcts[p])) fail("removal oracle");
            checks++;
        }
        /* Exhaust every early crossing, including all quartet/wide boundaries.
           Direct counts make this independent of min/max metadata shortcuts. */
        hdr_reset(h); h->normalizing_index_offset = 0;
        for (int idx = 0; idx < 256 && idx < h->counts_len; idx++)
        {
            h->counts[idx] = 17;
            h->total_count = 17;
            for (size_t p = 0; p < sizeof(pcts)/sizeof(pcts[0]); p++)
            {
                if (hdr_value_at_percentile(h, pcts[p]) != oracle(h, pcts[p]))
                    fail("exhaustive early crossing");
                checks++;
            }
            h->counts[idx] = 0;
        }
        /* Stay below dense's known floating-point percentile target overflow.
           This total fits exactly in double and exercises large block sums. */
        h->counts[16] = INT64_C(1125899906842624);
        h->counts[47] = INT64_C(1125899906842624);
        h->counts[h->counts_len - 1] = INT64_C(1125899906842624);
        h->total_count = INT64_C(3377699720527872);
        for (size_t p = 0; p < sizeof(pcts)/sizeof(pcts[0]); p++)
        {
            if (hdr_value_at_percentile(h, pcts[p]) != oracle(h, pcts[p]))
                fail("large-count crossing");
            checks++;
        }
        hdr_close(h);
    }
    printf("PASS: %"PRIu64" scan boundary/offset/removal checks, seed=0x6a09e667\n", checks);
    return 0;
}

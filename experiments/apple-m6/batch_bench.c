/* Supplemental ordered-batch benchmark and independent semantic checks.
 * Released to the public domain. Reuse timing/output helpers from bench.c. */
#define main common_bench_main
#include "bench.c"
#undef main

static void batch_reference(const struct hdr_histogram* h, const double* pcts,
    int64_t* out, size_t length)
{
    for (size_t p = 0; p < length; p++)
    {
        double bounded = pcts[p] < 100 ? pcts[p] : 100;
        int64_t target = (int64_t)((bounded / 100 * h->total_count) + 0.5);
        if (target < 1) target = 1;
        out[p] = target; /* Existing API leaves unresolved targets on empty input. */
        int64_t total = 0;
        for (int i = 0; i < h->counts_len && total < h->total_count; i++)
        {
            int physical = i - h->normalizing_index_offset;
            if (physical < 0) physical += h->counts_len;
            if (physical >= h->counts_len) physical -= h->counts_len;
            total += h->counts[physical];
            if (total >= target)
            {
                int64_t value = hdr_value_at_index(h, i);
                out[p] = hdr_next_non_equivalent_value(h, value) - 1;
                break;
            }
        }
    }
}

static void batch_validate(void)
{
    double pcts[32];
    int64_t expected[32], actual[32];
    uint64_t checks = 0;
    for (int sig = 1; sig <= 5; sig++)
    for (int shape = 0; shape < 4; shape++)
    {
        struct hdr_histogram* h = make_hist(sig);
        for (int i = 0; i < (shape == 0 ? 0 : shape == 1 ? 10 : 2000); i++)
            hdr_record_value(h, shape == 1 ? i : next_random() % 1000000000U + 1);
        int offsets[] = {0, 1, -1, h->counts_len - 1, 1 - h->counts_len};
        for (size_t o = 0; o < sizeof(offsets)/sizeof(offsets[0]); o++)
        {
            h->normalizing_index_offset = offsets[o];
            for (int length = 1; length <= 32; length++)
            {
                for (int p = 0; p < length; p++) pcts[p] = length == 1 ? 99 : 100.0 * p / (length - 1);
                batch_reference(h, pcts, expected, (size_t)length);
                if (hdr_value_at_percentiles(h, pcts, actual, (size_t)length)) fail("batch return");
                for (int p = 0; p < length; p++)
                    if (actual[p] != expected[p]) fail("batch oracle mismatch");
                checks += (uint64_t)length;
            }
            for (int p = 0; p < 32; p++) pcts[p] = p < 16 ? 50 : 99;
            batch_reference(h, pcts, expected, 32);
            if (hdr_value_at_percentiles(h, pcts, actual, 32)) fail("batch duplicate return");
            if (memcmp(expected, actual, sizeof(actual))) fail("batch duplicates");
        }
        hdr_close(h);
    }
    printf("{\"batch_validation_checks\":%"PRIu64"}\n", checks);
}

static void batches(void)
{
    int lengths[] = {1, 7, 32};
    double pcts[32];
    int64_t out[32], expected[32];
    for (int shape = 0; shape < 3; shape++)
    {
        struct hdr_histogram* h = make_hist(3);
        for (int i = 0; i < (shape == 0 ? 0 : shape == 1 ? 10 : 100000); i++)
            hdr_record_value(h, shape == 1 ? i : next_random() % 1000000000U + 1);
        for (int k = 0; k < 3; k++)
        {
            int length = lengths[k];
            uint64_t expected_sum = 0, result = 0;
            for (int p = 0; p < length; p++) pcts[p] = length == 1 ? 99 : 100.0 * p / (length - 1);
            batch_reference(h, pcts, expected, (size_t)length);
            for (int p = 0; p < length; p++) expected_sum += (uint64_t)expected[p];
            uint64_t iters = shape < 2 ? 20000000U / (unsigned)length + 1000000U : 20000;
            for (int i = 0; i < 100; i++) hdr_value_at_percentiles(h, pcts, out, (size_t)length);
            double start = now();
            for (uint64_t i = 0; i < iters; i++)
            {
                hdr_value_at_percentiles(h, pcts, out, (size_t)length);
                for (int p = 0; p < length; p++) result += (uint64_t)out[p];
            }
            double elapsed = now() - start;
            if (result != expected_sum * iters) fail("batch checksum");
            char name[64]; snprintf(name, sizeof(name), "batch_s%d_n%d", shape, length);
            emit(name, iters, elapsed, result, h);
        }
        hdr_close(h);
    }
}

int main(int argc, char** argv)
{
#ifdef __APPLE__
    if (pthread_set_qos_class_self_np(QOS_CLASS_USER_INITIATED, 0)) fail("set QoS");
#endif
    if (argc != 2) fail("usage: batch-bench validate|batch");
    if (!strcmp(argv[1], "validate")) batch_validate();
    else if (!strcmp(argv[1], "batch")) batches();
    else fail("unknown mode");
    return 0;
}

/* Supplemental ordered-batch benchmark and independent semantic checks.
 * Released to the public domain. Reuse timing/output helpers from bench.c. */
#define main common_bench_main
#include "bench.c"
#undef main
#include <errno.h>

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
    uint64_t checks = 0, equivalent_checks = 0;
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
                {
                    if (actual[p] != expected[p]) fail("batch oracle mismatch");
                    /* Empty output and p0 bucket-end conventions differ between
                       the existing APIs. Compare only equivalent requests. */
                    if (h->total_count > 0 && pcts[p] > 0)
                    {
                        if (hdr_value_at_percentile(h, pcts[p]) != expected[p])
                            fail("batch/singular equivalence");
                        equivalent_checks++;
                    }
                }
                checks += (uint64_t)length;
            }
            for (int p = 0; p < 32; p++) pcts[p] = p < 16 ? 50 : 99;
            batch_reference(h, pcts, expected, 32);
            if (hdr_value_at_percentiles(h, pcts, actual, 32)) fail("batch duplicate return");
            if (memcmp(expected, actual, sizeof(actual))) fail("batch duplicates");
        }
        hdr_close(h);
    }
    printf("{\"batch_validation_checks\":%"PRIu64",\"equivalent_singular_checks\":%"PRIu64"}\n",
        checks, equivalent_checks);
}

static void batch_edges(void)
{
    const double pcts[] = {-10, 0, 0.01, 50, 99, 100, 110};
    const size_t length = sizeof(pcts) / sizeof(pcts[0]);
    int64_t actual[7], expected[7];
    uint64_t checks = 0;
    for (int sig = 1; sig <= 5; sig++)
    {
        struct hdr_histogram* h = make_hist(sig);
        /* Preserve observed baseline errors, not the stale ENOMEM header text. */
        if (hdr_value_at_percentiles(h, NULL, actual, length) != EINVAL ||
            hdr_value_at_percentiles(h, pcts, NULL, length) != EINVAL)
            fail("batch null arguments");
        actual[0] = 1234567;
        if (hdr_value_at_percentiles(h, pcts, actual, 0) || actual[0] != 1234567)
            fail("batch zero length");
        for (int idx = 0; idx < 256 && idx < h->counts_len; idx++)
        {
            h->counts[idx] = 17;
            h->total_count = 17;
            batch_reference(h, pcts, expected, length);
            if (hdr_value_at_percentiles(h, pcts, actual, length) ||
                memcmp(actual, expected, sizeof(actual))) fail("batch crossing edge");
            checks += length;
            h->counts[idx] = 0;
        }
        h->counts[16] = INT64_C(1125899906842624);
        h->counts[47] = INT64_C(1125899906842624);
        h->counts[h->counts_len - 1] = INT64_C(1125899906842624);
        h->total_count = INT64_C(3377699720527872);
        batch_reference(h, pcts, expected, length);
        if (hdr_value_at_percentiles(h, pcts, actual, length) ||
            memcmp(actual, expected, sizeof(actual))) fail("batch large counts");
        checks += length;
        hdr_reset(h);
        if (!hdr_record_values(h, 1000, 10000) || !hdr_record_values(h, 1000, -5000) ||
            !hdr_record_values(h, 500000, 10000)) fail("batch valid removal setup");
        batch_reference(h, pcts, expected, length);
        if (hdr_value_at_percentiles(h, pcts, actual, length) ||
            memcmp(actual, expected, sizeof(actual))) fail("batch valid removal");
        checks += length;
        hdr_close(h);
    }
    printf("{\"batch_edge_checks\":%"PRIu64"}\n", checks);
}

static void equivalent_batches(int reverse_order, int validate_only)
{
    const int lengths[] = {1, 7, 32};
    double pcts[32];
    int64_t out[32], expected[32];
    /* Nonempty inputs and strictly positive percentiles make the two public
       APIs semantically equivalent without adapters in the timed region. */
    for (int shape = 1; shape <= 2; shape++)
    {
        struct hdr_histogram* h = make_hist(3);
        for (int i = 0; i < (shape == 1 ? 10 : 100000); i++)
            if (!hdr_record_value(h, shape == 1 ? i : next_random() % 1000000000U + 1))
                fail("equivalent batch setup");
        for (int k = 0; k < 3; k++)
        {
            int length = lengths[k];
            uint64_t expected_sum = 0;
            for (int p = 0; p < length; p++) pcts[p] = length == 1 ? 99 : 1 + 99.0 * p / (length - 1);
            batch_reference(h, pcts, expected, (size_t)length);
            if (hdr_value_at_percentiles(h, pcts, out, (size_t)length)) fail("equivalent batch return");
            for (int p = 0; p < length; p++)
            {
                if (out[p] != expected[p] || hdr_value_at_percentile(h, pcts[p]) != expected[p])
                    fail("equivalent benchmark oracle");
                expected_sum += (uint64_t)expected[p];
            }
            const uint64_t iters = validate_only ? 2 :
                shape == 1 ? 20000000U / (unsigned)length + 1000000U : 20000;
            for (int order = 0; order < 2; order++)
            {
                int singles = order ^ reverse_order;
                uint64_t result = 0;
                for (int warm = 0; warm < (validate_only ? 0 : 100); warm++)
                {
                    if (singles)
                        for (int p = 0; p < length; p++) out[p] = hdr_value_at_percentile(h, pcts[p]);
                    else hdr_value_at_percentiles(h, pcts, out, (size_t)length);
                }
                double start = validate_only ? 0 : now();
                if (singles)
                    for (uint64_t i = 0; i < iters; i++)
                    {
                        for (int p = 0; p < length; p++) out[p] = hdr_value_at_percentile(h, pcts[p]);
                        for (int p = 0; p < length; p++) result += (uint64_t)out[p];
                    }
                else
                    for (uint64_t i = 0; i < iters; i++)
                    {
                        hdr_value_at_percentiles(h, pcts, out, (size_t)length);
                        for (int p = 0; p < length; p++) result += (uint64_t)out[p];
                    }
                double seconds = validate_only ? 0 : now() - start;
                if (result != expected_sum * iters) fail("equivalent batch checksum");
                if (validate_only) continue;
                char name[80];
                snprintf(name, sizeof(name), "%s_s%d_n%d", singles ? "singles_equivalent" : "batch_equivalent", shape, length);
                emit(name, iters, seconds, result, h);
            }
        }
        hdr_close(h);
    }
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
    if (argc != 2) fail("usage: batch-bench validate|validate-equivalent|batch|batch-equivalent|batch-equivalent-reverse");
    if (!strcmp(argv[1], "validate"))
    {
        batch_validate(); batch_edges();
        equivalent_batches(0, 1); equivalent_batches(1, 1);
        puts("{\"equivalent_benchmark_group_checks\":24}");
    }
    else if (!strcmp(argv[1], "validate-equivalent"))
    {
        equivalent_batches(0, 1); equivalent_batches(1, 1);
        puts("{\"equivalent_benchmark_group_checks\":24}");
    }
    else if (!strcmp(argv[1], "batch")) batches();
    else if (!strcmp(argv[1], "batch-equivalent")) equivalent_batches(0, 0);
    else if (!strcmp(argv[1], "batch-equivalent-reverse")) equivalent_batches(1, 0);
    else fail("unknown mode");
    return 0;
}

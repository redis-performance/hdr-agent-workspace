/* Packed read-width diagnostic, checked against an independent dense oracle.
 * Released to the public domain. */
#define main common_bench_main
#include "bench.c"
#undef main
#include <hdr/hdr_packed_histogram.h>

static void packed_cases(int validate_only)
{
    const int widths[] = {1, 2, 4, 8};
    const int64_t counts[] = {1, 256, 65536, INT64_C(4294967296)};
    const int populations[] = {4, 64, 4096};
    const double pcts[] = {0, 50, 99, 100};
    uint64_t checks = 0;
    for (int w = 0; w < 4; w++)
    for (int shape = 0; shape < 3; shape++)
    {
        struct hdr_histogram* dense = make_hist(3);
        struct hdr_packed_histogram* packed = NULL;
        if (hdr_packed_init(1, 1000000000, 3, &packed)) fail("packed init");
        int32_t valid = dense->counts_len;
        while (hdr_value_at_index(dense, valid - 1) > 1000000000) valid--;
        for (int i = 0; i < populations[shape]; i++) {
            int32_t idx = 1 + (int32_t)((int64_t)(valid - 2) * i / populations[shape]);
            int64_t value = hdr_value_at_index(dense, idx);
            if (!hdr_record_values(dense, value, counts[w]) ||
                !hdr_packed_record_values(packed, value, counts[w])) fail("packed record");
        }
        if (hdr_packed_count_width(packed) != widths[w] ||
            hdr_packed_populated(packed) != populations[shape] ||
            hdr_packed_total_count(packed) != dense->total_count) fail("packed shape");
        for (int p = 0; p < 4; p++) {
            int64_t expected = oracle(dense, pcts[p]);
            if (hdr_packed_value_at_percentile(packed, pcts[p]) != expected)
                fail("packed oracle");
            checks++;
            if (validate_only) continue;
            uint64_t iterations = shape < 2 || p == 0 ? 5000000 : 200000;
            uint64_t result = 0;
            double start = now();
            for (uint64_t i = 0; i < iterations; i++)
                result += (uint64_t)hdr_packed_value_at_percentile(packed, pcts[p]);
            double seconds = now() - start;
            if (result != (uint64_t)expected * iterations) fail("packed checksum");
            printf("{\"case\":\"packed_w%d_n%d_p%.0f\",\"ops\":%"PRIu64","
                "\"seconds\":%.9f,\"ns_per_op\":%.6f,\"checksum\":%"PRIu64","
                "\"width\":%d,\"populated\":%d,\"packed_bytes\":%zu,\"dense_bytes\":%zu}\n",
                widths[w], populations[shape], pcts[p], iterations, seconds,
                seconds * 1e9 / iterations, result, widths[w], populations[shape],
                hdr_packed_get_memory_size(packed), sizeof(*dense) + (size_t)dense->counts_len * 8);
        }
        hdr_packed_close(packed);
        hdr_close(dense);
    }
    if (validate_only) printf("{\"packed_oracle_checks\":%"PRIu64"}\n", checks);
}

int main(int argc, char** argv)
{
#ifdef __APPLE__
    if (pthread_set_qos_class_self_np(QOS_CLASS_USER_INITIATED, 0)) fail("set QoS");
#endif
    if (argc != 2 || (strcmp(argv[1], "packed") && strcmp(argv[1], "validate")))
        fail("usage: packed-bench validate|packed");
    packed_cases(!strcmp(argv[1], "validate"));
    return 0;
}

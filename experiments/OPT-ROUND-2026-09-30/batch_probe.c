/* Bounded supplemental batch benchmark. Released to the public domain.
 * The immutable project benchmark drivers remain untouched.
 */
#include <hdr/hdr_histogram.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#ifdef __APPLE__
#include <pthread/qos.h>
#endif

static volatile uint64_t sink;
static uint32_t random_state;

static uint32_t next_random(void)
{
    random_state ^= random_state << 13U;
    random_state ^= random_state >> 17U;
    random_state ^= random_state << 5U;
    return random_state;
}

static double seconds_now(void)
{
    struct timespec t;
    if (clock_gettime(CLOCK_MONOTONIC, &t) != 0) abort();
    return (double)t.tv_sec + (double)t.tv_nsec * 1e-9;
}

static void check(int condition, const char* message)
{
    if (!condition) { fprintf(stderr, "%s\n", message); exit(1); }
}

static double run_calls(struct hdr_histogram* h, const double* pcts,
    int64_t* out, int length, size_t iterations, int singles)
{
    uint64_t local_sink = 0;
    double start = seconds_now();
    for (size_t i = 0; i < iterations; i++)
    {
        if (singles)
        {
            for (int j = 0; j < length; j++)
                out[j] = hdr_value_at_percentile(h, pcts[j]);
        }
        else check(hdr_value_at_percentiles(h, pcts, out, (size_t)length) == 0,
            "batch call failed");
        local_sink += (uint64_t)out[i % (size_t)length];
    }
    double elapsed = seconds_now() - start;
    sink += local_sink;
    return elapsed;
}

static int compare_double(const void* a, const void* b)
{
    double x = *(const double*)a, y = *(const double*)b;
    return (x > y) - (x < y);
}

static void one_case(int dense, int length, int validate_only)
{
    struct hdr_histogram* h = NULL;
    double pcts[32];
    int64_t expected[32], out[32];
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    const int count = dense ? 100000 : 10;
    random_state = UINT32_C(0x6a09e667);
    check(hdr_init(1, 1000000000, 3, &h) == 0, "histogram init failed");
    for (int i = 0; i < count; i++)
    {
        int64_t value = dense ? (int64_t)(next_random() % UINT32_C(1000000000)) + 1 : i + 1;
        check(hdr_record_value(h, value), "record failed");
    }
    for (int j = 0; j < length; j++)
    {
        pcts[j] = length == 7 ? (const double[]){50, 75, 90, 95, 99, 99.9, 99.99}[j]
            : 1.0 + 99.0 * j / (length - 1);
        expected[j] = hdr_value_at_percentile(h, pcts[j]);
        fingerprint ^= (uint64_t)expected[j];
        fingerprint *= UINT64_C(1099511628211);
    }
    check(hdr_value_at_percentiles(h, pcts, out, (size_t)length) == 0,
        "batch validation call failed");
    check(memcmp(out, expected, (size_t)length * sizeof(out[0])) == 0,
        "batch/singular mismatch");
    if (validate_only)
    {
        printf("{\"shape\":\"%s\",\"length\":%d,\"fingerprint\":%" PRIu64 "}\n",
            dense ? "dense" : "sparse", length, fingerprint);
        hdr_close(h);
        return;
    }
    for (int singles = 0; singles <= 1; singles++)
    {
        double samples[7], trial;
        size_t iterations = 1;
        for (int warm = 0; warm < 16; warm++)
            (void)run_calls(h, pcts, out, length, 1, singles);
        do
        {
            trial = run_calls(h, pcts, out, length, iterations, singles);
            if (trial >= 0.03 || iterations >= 1000000) break;
            iterations *= 2;
        } while (1);
        if (trial > 0)
        {
            double scaled = (double)iterations * 0.2 / trial;
            iterations = scaled >= 2000000 ? 2000000 :
                scaled < 1 ? 1 : (size_t)scaled;
        }
        for (int s = 0; s < 7; s++)
            samples[s] = run_calls(h, pcts, out, length, iterations, singles)
                * 1e9 / (double)iterations;
        qsort(samples, 7, sizeof(samples[0]), compare_double);
        printf("{\"shape\":\"%s\",\"length\":%d,\"mode\":\"%s\","
            "\"iterations\":%zu,\"median_ns\":%.3f,\"min_ns\":%.3f,"
            "\"max_ns\":%.3f,\"fingerprint\":%" PRIu64 "}\n",
            dense ? "dense" : "sparse", length, singles ? "singles" : "batch",
            iterations, samples[3], samples[0], samples[6], fingerprint);
    }
    hdr_close(h);
}

int main(int argc, char** argv)
{
    int validate_only = argc == 2 && strcmp(argv[1], "validate") == 0;
    check(argc == 1 || validate_only, "usage: batch_probe [validate]");
#ifdef __APPLE__
    check(pthread_set_qos_class_self_np(QOS_CLASS_USER_INITIATED, 0) == 0,
        "set QoS failed");
#endif
    for (int dense = 0; dense <= 1; dense++)
        for (int length = 7; length <= 32; length += 25)
            one_case(dense, length, validate_only);
    if (!validate_only) fprintf(stderr, "timing sink: %" PRIu64 "\n", sink);
    return 0;
}

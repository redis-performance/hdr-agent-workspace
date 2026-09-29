/* Supplemental ARM experiment harness. Immutable referee drivers stay unchanged.
 * Released to the public domain. */
#include <hdr/hdr_histogram.h>
#include <stdint.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <pthread.h>
#ifdef __APPLE__
#include <pthread/qos.h>
#endif

static volatile uint64_t sink;
static uint32_t state = 0x6a09e667U;
static uint32_t next_random(void)
{
    state ^= state << 13U; state ^= state >> 17U; state ^= state << 5U;
    return state;
}
static double now(void)
{
    struct timespec t;
    if (clock_gettime(CLOCK_MONOTONIC, &t)) abort();
    return (double)t.tv_sec + (double)t.tv_nsec * 1e-9;
}
static void fail(const char* message)
{
    fprintf(stderr, "%s\n", message); exit(1);
}
static struct hdr_histogram* make_hist(int sig)
{
    struct hdr_histogram* h = NULL;
    if (hdr_init(1, 1000000000, sig, &h)) fail("init failed");
    return h;
}
static int64_t oracle(const struct hdr_histogram* h, double pct)
{
    double bounded = pct < 100 ? pct : 100;
    int64_t target = (int64_t)((bounded / 100 * h->total_count) + 0.5);
    if (target < 1) target = 1;
    int64_t running = 0, value = 0;
    for (int32_t i = 0; i < h->counts_len; i++)
    {
        int32_t physical = i - h->normalizing_index_offset;
        if (physical < 0) physical += h->counts_len;
        if (physical >= h->counts_len) physical -= h->counts_len;
        running += h->counts[physical];
        if (running >= target) { value = hdr_value_at_index(h, i); break; }
    }
    return pct == 0 ? value : hdr_next_non_equivalent_value(h, value) - 1;
}
static void validate(void)
{
    static const double pcts[] = {0, 0.01, 1, 10, 50, 90, 99, 99.99, 100};
    uint64_t checks = 0;
    for (int sig = 1; sig <= 5; sig++)
    {
        struct hdr_histogram* h = make_hist(sig);
        for (int scenario = 0; scenario < 12; scenario++)
        {
            hdr_reset(h); h->normalizing_index_offset = 0;
            int population = scenario == 0 ? 0 : scenario == 1 ? 1 : 2000;
            for (int i = 0; i < population; i++)
                if (!hdr_record_value(h, next_random() % 1000000001U)) fail("record");
            int32_t offsets[] = {0, 1, -1, h->counts_len - 1, 1 - h->counts_len};
            for (size_t o = 0; o < sizeof(offsets)/sizeof(offsets[0]); o++)
            {
                h->normalizing_index_offset = offsets[o];
                for (size_t p = 0; p < sizeof(pcts)/sizeof(pcts[0]); p++)
                {
                    if (hdr_value_at_percentile(h, pcts[p]) != oracle(h, pcts[p]))
                        fail("singular oracle mismatch");
                    checks++;
                }
            }
        }
        hdr_close(h);
    }
    printf("{\"validation_checks\":%"PRIu64"}\n", checks);
}
static void emit(const char* name, uint64_t ops, double seconds, uint64_t checksum,
    const struct hdr_histogram* h)
{
    printf("{\"case\":\"%s\",\"ops\":%"PRIu64",\"seconds\":%.9f,"
        "\"ns_per_op\":%.6f,\"checksum\":%"PRIu64",\"counts_bytes\":%zu,"
        "\"hist_alignment_mod128\":%zu,\"counts_alignment_mod128\":%zu}\n",
        name, ops, seconds, seconds * 1e9 / ops, checksum,
        (size_t)h->counts_len * sizeof(int64_t), (size_t)((uintptr_t)h % 128),
        (size_t)((uintptr_t)h->counts % 128));
}
static void writes(void)
{
    enum { N = 65536, REPS = 1024 };
    int64_t* inputs = malloc(N * sizeof(*inputs));
    if (!inputs) fail("inputs");
    const char* names[] = {"increasing", "constant", "iid", "correlated", "extremes"};
    for (int atomic = 0; atomic <= 1; atomic++)
    for (int dist = 0; dist < 5; dist++)
    {
        struct hdr_histogram* h = make_hist(3);
        int64_t current = 100000;
        for (int i = 0; i < N; i++)
        {
            uint32_t r = next_random();
            current += (int64_t)(r % 201) - 100;
            if (current < 1) current = 1;
            inputs[i] = dist == 0 ? i + 1 : dist == 1 ? 100000 :
                dist == 2 ? r % 1000000000U + 1 : dist == 3 ? current :
                (i & 1) ? 1000000000 : 1;
        }
        for (int i = 0; i < N; i++) hdr_record_value(h, inputs[i]);
        hdr_reset(h);
        int reps = atomic ? REPS / 2 : REPS;
        double start = now();
        if (atomic)
            for (int rep = 0; rep < reps; rep++)
                for (int i = 0; i < N; i++) hdr_record_value_atomic(h, inputs[i]);
        else
            for (int rep = 0; rep < reps; rep++)
                for (int i = 0; i < N; i++) hdr_record_value(h, inputs[i]);
        double elapsed = now() - start;
        uint64_t ops = (uint64_t)reps * N;
        if ((uint64_t)h->total_count != ops) fail("record total");
        uint64_t total = 0;
        for (int i = 0; i < h->counts_len; i++) total += (uint64_t)h->counts[i];
        if (total != ops) fail("bucket total");
        char name[64]; snprintf(name, sizeof(name), "%s_%s", atomic ? "atomic" : "write", names[dist]);
        emit(name, ops, elapsed, (uint64_t)hdr_value_at_percentile(h, 99), h);
        hdr_close(h);
    }
    free(inputs);
}
static void reads(void)
{
    for (int shape = 0; shape < 4; shape++)
    {
        struct hdr_histogram* h = make_hist(shape == 3 ? 1 : 3);
        int n = shape == 0 ? 0 : shape == 1 ? 10 : 100000;
        for (int i = 0; i < n; i++)
            hdr_record_value(h, shape == 1 ? i : next_random() % 1000000000U + 1);
        double pcts[] = {0, 50, 99, 100};
        for (int p = 0; p < 4; p++)
        {
            int64_t expected = oracle(h, pcts[p]);
            if (hdr_value_at_percentile(h, pcts[p]) != expected) fail("read oracle");
            uint64_t iterations = shape == 1 ? 40000000 : shape == 3 ? 1000000 :
                (shape == 2 && p == 0) ? 100000 : 20000;
            uint64_t result = 0;
            for (int i = 0; i < 100; i++) sink += (uint64_t)hdr_value_at_percentile(h, pcts[p]);
            double start = now();
            for (uint64_t i = 0; i < iterations; i++) result += (uint64_t)hdr_value_at_percentile(h, pcts[p]);
            double elapsed = now() - start;
            if (result != (uint64_t)expected * iterations) fail("read checksum");
            sink += result;
            char name[64]; snprintf(name, sizeof(name), "read_s%d_p%.0f", shape, pcts[p]);
            emit(name, iterations, elapsed, result, h);
        }
        hdr_close(h);
    }
}
static void multi_writes(void)
{
    enum { N = 65536, REPS = 128 };
    int64_t* input = malloc(N * sizeof(*input));
    uint32_t* select = malloc(N * sizeof(*select));
    if (!input || !select) fail("multi inputs");
    int sizes[] = {1, 64, 1024};
    for (int s = 0; s < 3; s++)
    for (int correlated = 0; correlated < 2; correlated++)
    {
        int count = sizes[s];
        struct hdr_histogram** hs = calloc((size_t)count, sizeof(*hs));
        if (!hs) fail("hist array");
        for (int i = 0; i < count; i++) hs[i] = make_hist(3);
        for (int i = 0; i < N; i++)
        {
            uint32_t r = next_random();
            input[i] = correlated ? 100000 + r % 201 :
                (int64_t)(UINT64_C(1) << (r % 29)) + (next_random() % 1000);
            select[i] = next_random() % (uint32_t)count;
        }
        for (int i = 0; i < N; i++) hdr_record_value(hs[select[i]], input[i]);
        for (int i = 0; i < count; i++) hdr_reset(hs[i]);
        double start = now();
        for (int rep = 0; rep < REPS; rep++)
            for (int i = 0; i < N; i++) hdr_record_value(hs[select[i]], input[i]);
        double elapsed = now() - start;
        uint64_t total = 0, buckets = 0;
        for (int i = 0; i < count; i++)
        {
            total += (uint64_t)hs[i]->total_count;
            for (int j = 0; j < hs[i]->counts_len; j++) buckets += (uint64_t)hs[i]->counts[j];
        }
        if (total != (uint64_t)N * REPS || buckets != total) fail("multi total");
        char name[64]; snprintf(name, sizeof(name), "multi_h%d_%s", count,
            correlated ? "correlated" : "logspread");
        emit(name, total, elapsed, buckets, hs[0]);
        for (int i = 0; i < count; i++) hdr_close(hs[i]);
        free(hs);
    }
    free(input); free(select);
}

int main(int argc, char** argv)
{
#ifdef __APPLE__
    if (pthread_set_qos_class_self_np(QOS_CLASS_USER_INITIATED, 0)) fail("set QoS");
#endif
    if (argc != 2) fail("usage: bench validate|write|read|write-multi");
    if (!strcmp(argv[1], "validate")) validate();
    else if (!strcmp(argv[1], "write")) writes();
    else if (!strcmp(argv[1], "read")) reads();
    else if (!strcmp(argv[1], "write-multi")) multi_writes();
    else fail("unknown mode");
    return 0;
}

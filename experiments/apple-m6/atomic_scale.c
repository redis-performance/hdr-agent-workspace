/* Bounded atomic scaling diagnostic. No changes to library memory ordering.
 * Released to the public domain. */
#define main common_bench_main
#include "bench.c"
#undef main

struct start_gate {
    pthread_mutex_t lock;
    pthread_cond_t cond;
    int ready, start;
};
struct writer {
    struct start_gate* gate;
    struct hdr_histogram* h;
    uint64_t iterations;
    int64_t value;
    int failed;
};

static void* record_thread(void* opaque)
{
    struct writer* w = opaque;
#ifdef __APPLE__
    if (pthread_set_qos_class_self_np(QOS_CLASS_USER_INITIATED, 0))
        w->failed = 1;
#endif
    pthread_mutex_lock(&w->gate->lock);
    w->gate->ready++;
    pthread_cond_broadcast(&w->gate->cond);
    while (!w->gate->start) pthread_cond_wait(&w->gate->cond, &w->gate->lock);
    pthread_mutex_unlock(&w->gate->lock);
    for (uint64_t i = 0; i < w->iterations; i++)
        if (!hdr_record_value_atomic(w->h, w->value)) w->failed = 1;
    return NULL;
}

static void run_case(int threads, int strategy, uint64_t iterations, int output)
{
    struct start_gate gate = {PTHREAD_MUTEX_INITIALIZER, PTHREAD_COND_INITIALIZER, 0, 0};
    struct writer workers[12];
    pthread_t ids[12];
    struct hdr_histogram* histograms[12];
    const int count = strategy == 2 ? threads : 1;
    for (int i = 0; i < count; i++) histograms[i] = make_hist(3);
    for (int i = 0; i < threads; i++) {
        workers[i] = (struct writer){&gate, histograms[strategy == 2 ? i : 0],
            iterations, 100000 + (strategy == 1 ? i * 1000000 : 0), 0};
        if (pthread_create(&ids[i], NULL, record_thread, &workers[i])) fail("pthread_create");
    }
    pthread_mutex_lock(&gate.lock);
    while (gate.ready < threads) pthread_cond_wait(&gate.cond, &gate.lock);
    double start = now();
    gate.start = 1;
    pthread_cond_broadcast(&gate.cond);
    pthread_mutex_unlock(&gate.lock);
    for (int i = 0; i < threads; i++)
        if (pthread_join(ids[i], NULL) || workers[i].failed) fail("atomic writer");
    double elapsed = now() - start;
    uint64_t total = 0;
    for (int i = 0; i < count; i++) {
        int64_t sum = 0;
        for (int j = 0; j < histograms[i]->counts_len; j++) sum += histograms[i]->counts[j];
        if (sum != histograms[i]->total_count || sum != (int64_t)(iterations * threads / count))
            fail("lost atomic counts");
        total += (uint64_t)sum;
    }
    for (int i = 0; i < threads; i++) {
        int64_t expected = (int64_t)(iterations * (strategy == 0 ? threads : 1));
        if (hdr_count_at_value(workers[i].h, workers[i].value) != expected)
            fail("atomic bucket mismatch");
    }
    if (output) {
        const char* names[] = {"shared_same", "shared_disjoint", "separate_same"};
        printf("{\"case\":\"%s_t%d\",\"threads\":%d,\"histograms\":%d,"
            "\"ops\":%"PRIu64",\"seconds\":%.9f,\"ns_per_op\":%.6f,\"checksum\":%"PRIu64"}\n",
            names[strategy], threads, threads, count, total, elapsed, elapsed * 1e9 / total, total);
    }
    for (int i = 0; i < count; i++) hdr_close(histograms[i]);
    pthread_cond_destroy(&gate.cond);
    pthread_mutex_destroy(&gate.lock);
}

int main(int argc, char** argv)
{
    if (argc != 2 || (strcmp(argv[1], "scale") && strcmp(argv[1], "validate")))
        fail("usage: atomic-scale validate|scale");
    int counts[] = {1, 2, 4, 6, 12};
    int validate_only = !strcmp(argv[1], "validate");
    for (int strategy = 0; strategy < 3; strategy++)
    for (size_t i = 0; i < sizeof(counts)/sizeof(counts[0]); i++)
        run_case(counts[i], strategy,
            validate_only ? 1000 : (33554432U + (unsigned)counts[i] - 1) / (unsigned)counts[i],
            !validate_only);
    return 0;
}

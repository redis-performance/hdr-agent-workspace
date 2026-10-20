#define _DARWIN_C_SOURCE
#include <hdr/hdr_histogram.h>
#include <hdr/hdr_packed_histogram.h>
#include <inttypes.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static volatile uint64_t sink;
static double now_ns(void)
{
    struct timespec t;
    if (clock_gettime(CLOCK_MONOTONIC_RAW, &t)) exit(2);
    return (double)t.tv_sec * 1e9 + t.tv_nsec;
}

struct fixture {
    struct hdr_histogram *dense;
    struct hdr_packed_histogram *packed;
    int population;
};

static struct fixture make_fixture(int width, int n)
{
    struct fixture f = {0};
    const int64_t count = width == 1 ? 1 : width == 2 ? 256 :
                          width == 4 ? 65536 : INT64_C(4294967296);
    if (hdr_init(1, INT64_C(1000000000), 3, &f.dense) ||
        hdr_packed_init(1, INT64_C(1000000000), 3, &f.packed)) exit(2);
    for (int i = 0; i < n; ++i) {
        int64_t value = hdr_value_at_index(f.dense, i);
        if (!hdr_record_values(f.dense, value, count) ||
            !hdr_packed_record_values(f.packed, value, count)) exit(2);
    }
    if (hdr_packed_count_width(f.packed) != width ||
        hdr_packed_populated(f.packed) != n) exit(2);
    f.population = n;
    return f;
}

static double percentile(int n, int position)
{
    return 100.0 * ((double)position + 0.75) / n;
}

static void validate(struct fixture *f)
{
    /* Every populated crossing, not just the timed selection. */
    for (int i = 0; i < f->population; ++i) {
        double p = percentile(f->population, i);
        int64_t expected = hdr_value_at_percentile(f->dense, p);
        int64_t actual = hdr_packed_value_at_percentile(f->packed, p);
        if (actual != expected) {
            fprintf(stderr, "oracle mismatch at %d: %" PRId64 " != %" PRId64 "\n",
                    i, actual, expected);
            exit(3);
        }
    }
    const double edge[] = {0, 100};
    for (int i = 0; i < 2; ++i)
        if (hdr_packed_value_at_percentile(f->packed, edge[i]) !=
            hdr_value_at_percentile(f->dense, edge[i])) exit(3);
}

static double measure(struct fixture *f, int position, uint64_t iterations)
{
    double p = percentile(f->population, position);
    uint64_t sum = 0;
    for (int i = 0; i < 512; ++i)
        sum += (uint64_t)hdr_packed_value_at_percentile(f->packed, p);
    sink = sum;
    sum = 0;
    double start = now_ns();
    for (uint64_t i = 0; i < iterations; ++i)
        sum += (uint64_t)hdr_packed_value_at_percentile(f->packed, p);
    double elapsed = now_ns() - start;
    sink = sum;
    uint64_t expected = (uint64_t)hdr_value_at_percentile(f->dense, p) * iterations;
    if (sum != expected) exit(3);
    return elapsed / (double)iterations;
}

int main(int argc, char **argv)
{
    if (argc < 2) return 2;
    int qos_error = pthread_set_qos_class_self_np(QOS_CLASS_USER_INITIATED, 0);
    qos_class_t actual_qos;
    if (pthread_get_qos_class_np(pthread_self(), &actual_qos, NULL)) return 2;
    fprintf(stderr, "qos_request_error=%d qos_actual=%u\n", qos_error,
            (unsigned)actual_qos);
    if (qos_error) return 2;
    const int widths[] = {1, 2, 4, 8};
    const int populations[] = {64, 4096};
    struct fixture fixtures[8];
    for (int w = 0; w < 4; ++w)
        for (int n = 0; n < 2; ++n) {
            fixtures[w * 2 + n] = make_fixture(widths[w], populations[n]);
            validate(&fixtures[w * 2 + n]);
        }
    if (!strcmp(argv[1], "validate")) {
        puts("PASS: 16640 populated crossings plus 16 p0/p100 checks");
    } else if (!strcmp(argv[1], "calibrate")) {
        const int positions[] = {0, 1, 3, 7, 15, 16, 17, 31, 32, 63, 127, 1023, 4095};
        puts("width,population,position,iterations");
        for (int f = 0; f < 8; ++f)
            for (size_t p = 0; p < sizeof positions / sizeof *positions; ++p) {
                if (positions[p] >= fixtures[f].population) continue;
                double ns = measure(&fixtures[f], positions[p], 20000);
                uint64_t count = (uint64_t)(20000000.0 / ns);
                if (count < 1000) count = 1000;
                if (count > 5000000) count = 5000000;
                printf("%d,%d,%d,%" PRIu64 "\n", widths[f / 2], fixtures[f].population,
                       positions[p], count);
            }
    } else if (!strcmp(argv[1], "run") && argc == 3) {
        FILE *plan = fopen(argv[2], "r");
        if (!plan) return 2;
        char header[128];
        if (!fgets(header, sizeof header, plan)) return 2;
        puts("width,population,position,iterations,ns_per_call,checksum");
        int width, n, position;
        uint64_t iterations;
        while (fscanf(plan, "%d,%d,%d,%" SCNu64, &width, &n, &position, &iterations) == 4) {
            int index = -1;
            for (int f = 0; f < 8; ++f)
                if (widths[f / 2] == width && fixtures[f].population == n) index = f;
            if (index < 0 || position < 0 || position >= n || !iterations) return 2;
            double ns = measure(&fixtures[index], position, iterations);
            printf("%d,%d,%d,%" PRIu64 ",%.6f,%" PRIu64 "\n",
                   width, n, position, iterations, ns, sink);
        }
        if (!feof(plan)) return 2;
        fclose(plan);
    } else return 2;
    for (int f = 0; f < 8; ++f) {
        hdr_close(fixtures[f].dense);
        hdr_packed_close(fixtures[f].packed);
    }
    return 0;
}

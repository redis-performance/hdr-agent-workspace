/* Supplemental Apple-silicon diagnostic. The project benchmark drivers stay
 * unchanged. C library is linked separately so hot-path calls remain real.
 */
#include <hdr/hdr_histogram.h>
#include <pthread/qos.h>
#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <random>
#include <vector>

static volatile uint64_t sink;

static double now()
{
    return std::chrono::duration<double>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
}

static qos_class_t choose_qos(const char* name)
{
    if (strcmp(name, "interactive") == 0) return QOS_CLASS_USER_INTERACTIVE;
    if (strcmp(name, "initiated") == 0) return QOS_CLASS_USER_INITIATED;
    if (strcmp(name, "default") == 0) return QOS_CLASS_DEFAULT;
    if (strcmp(name, "utility") == 0) return QOS_CLASS_UTILITY;
    if (strcmp(name, "background") == 0) return QOS_CLASS_BACKGROUND;
    std::fprintf(stderr, "unknown QoS class\n");
    std::exit(2);
}

static void write_case(bool shuffled)
{
    hdr_histogram* h = nullptr;
    if (hdr_init(1, INT64_C(86400000000), 4, &h) != 0) std::abort();
    std::vector<int64_t> input;
    if (shuffled)
    {
        uint32_t state = UINT32_C(0x6a09e667);
        input.resize(1000000);
        for (auto& value : input)
        {
            state ^= state << 13U;
            state ^= state >> 17U;
            state ^= state << 5U;
            value = (int64_t)(state % UINT32_C(400000000)) + 1;
        }
    }
    std::vector<double> samples;
    for (int sample = 0; sample < 5; sample++)
    {
        double start = now();
        if (shuffled)
        {
            for (int cycle = 0; cycle < 40; cycle++)
                for (int64_t value : input)
                    if (!hdr_record_value(h, value)) std::abort();
        }
        else
        {
            for (int64_t value = 1; value < 400000000; value++)
                if (!hdr_record_value(h, value)) std::abort();
        }
        double ns = (now() - start) * 1e9 / (shuffled ? 40000000.0 : 399999999.0);
        samples.push_back(ns);
        sink += (uint64_t)h->total_count;
    }
    std::sort(samples.begin(), samples.end());
    int64_t populated = 0;
    int32_t max_nonzero = -1;
    for (int32_t i = 0; i < h->counts_len; i++)
    {
        if (h->counts[i] != 0) { populated++; max_nonzero = i; }
    }
    std::printf("mode=%s count_bytes=%zu active_span_bytes=%zu populated=%lld input_bytes=%zu median_ns=%.3f min_ns=%.3f max_ns=%.3f total=%lld\n",
        shuffled ? "write_shuffled" : "write_sequential",
        (size_t)h->counts_len * sizeof(h->counts[0]),
        (size_t)(max_nonzero + 1) * sizeof(h->counts[0]),
        (long long)populated, input.size() * sizeof(input[0]),
        samples[2], samples[0], samples[4], (long long)h->total_count);
    hdr_close(h);
}

static void list_case()
{
    hdr_histogram* h = nullptr;
    if (hdr_init(1, 86400000, 3, &h) != 0) std::abort();
    std::minstd_rand engine;
    std::gamma_distribution<double> distribution(1.0, 100000.0);
    for (int64_t i = 1; i < 10000000; i++)
    {
        int64_t value = std::min<int64_t>((int64_t)distribution(engine) + 1, 86400000);
        if (!hdr_record_value(h, value)) std::abort();
    }
    const double pcts[4] = {50, 95, 99, 99.9};
    int64_t out[4];
    if (hdr_value_at_percentiles(h, pcts, out, 4) != 0) std::abort();
    const int64_t expected[4] = {out[0], out[1], out[2], out[3]};
    std::vector<double> samples;
    for (int sample = 0; sample < 5; sample++)
    {
        double start = now();
        for (int i = 0; i < 300000; i++)
        {
            if (hdr_value_at_percentiles(h, pcts, out, 4) != 0) std::abort();
            sink += (uint64_t)out[i & 3];
        }
        samples.push_back((now() - start) * 1e9 / 300000.0);
    }
    std::sort(samples.begin(), samples.end());
    if (!std::equal(out, out + 4, expected)) std::abort();
    int64_t running = 0;
    int32_t crossing_index = -1;
    const int64_t target = (h->total_count * 999 + 999) / 1000;
    for (int32_t i = 0; i < h->counts_len; i++)
    {
        running += h->counts[i];
        if (running >= target) { crossing_index = i; break; }
    }
    std::printf("mode=list4 count_bytes=%zu p999_scan_bytes=%zu median_ns=%.3f min_ns=%.3f max_ns=%.3f outputs=%lld,%lld,%lld,%lld\n",
        (size_t)h->counts_len * sizeof(h->counts[0]),
        (size_t)(crossing_index + 1) * sizeof(h->counts[0]),
        samples[2], samples[0], samples[4],
        (long long)out[0], (long long)out[1], (long long)out[2], (long long)out[3]);
    hdr_close(h);
}

int main(int argc, char** argv)
{
    if (argc != 3)
    {
        std::fprintf(stderr, "usage: probe <qos> <write_sequential|write_shuffled|list4>\n");
        return 2;
    }
    qos_class_t qos = choose_qos(argv[1]);
    if (pthread_set_qos_class_self_np(qos, 0) != 0) std::abort();
    std::printf("requested_qos=%s actual_qos=%u ", argv[1], (unsigned)qos_class_self());
    if (strcmp(argv[2], "write_sequential") == 0) write_case(false);
    else if (strcmp(argv[2], "write_shuffled") == 0) write_case(true);
    else if (strcmp(argv[2], "list4") == 0) list_case();
    else return 2;
    std::fprintf(stderr, "sink=%llu\n", (unsigned long long)sink);
    return 0;
}

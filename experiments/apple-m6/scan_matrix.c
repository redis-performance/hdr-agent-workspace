/* Extended early-crossing and precision performance controls.
 * Released to the public domain. */
#define main common_bench_main
#include "bench.c"
#undef main

static void matrix(void)
{
    const int indices[] = {0, 15, 16, 31, 32, 47, 48, 63, 64, 127, 128};
    for (int sig = 1; sig <= 5; sig++)
    for (int shape = 0; shape < 13; shape++)
    {
        struct hdr_histogram* h = make_hist(sig);
        int32_t valid = h->counts_len;
        while (hdr_value_at_index(h, valid - 1) > 1000000000) valid--;
        int32_t last_index = shape < 11 ? indices[shape] : valid - 1;
        if (shape < 12) {
            if (!hdr_record_value(h, hdr_value_at_index(h, last_index))) fail("matrix single");
        } else {
            for (int i = 0; i < 10000; i++)
                if (!hdr_record_value(h, next_random() % 1000000000U + 1)) fail("matrix record");
        }
        const double pcts[] = {99, 50};
        for (int p = 0; p < (shape == 12 ? 2 : 1); p++) {
            int64_t expected = oracle(h, pcts[p]);
            if (hdr_value_at_percentile(h, pcts[p]) != expected) fail("matrix oracle");
            uint64_t iterations = UINT64_C(500000000) / ((unsigned)last_index + 1);
            if (iterations > 10000000) iterations = 10000000;
            if (iterations < 200) iterations = 200;
            uint64_t sum = 0;
            double start = now();
            for (uint64_t i = 0; i < iterations; i++)
                sum += (uint64_t)hdr_value_at_percentile(h, pcts[p]);
            double seconds = now() - start;
            if (sum != iterations * (uint64_t)expected) fail("matrix checksum");
            char name[80];
            snprintf(name, sizeof(name), "sig%d_shape%d_index%d_p%.0f", sig, shape, last_index, pcts[p]);
            emit(name, iterations, seconds, sum, h);
        }
        hdr_close(h);
    }
}

int main(int argc, char** argv)
{
#ifdef __APPLE__
    if (pthread_set_qos_class_self_np(QOS_CLASS_USER_INITIATED, 0)) fail("set QoS");
#endif
    if (argc != 2) fail("usage: scan-matrix validate|matrix");
    if (!strcmp(argv[1], "validate")) validate();
    else if (!strcmp(argv[1], "matrix")) matrix();
    else fail("unknown mode");
    return 0;
}

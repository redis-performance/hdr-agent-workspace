#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <math.h>
#include "hdr/hdr_packed_histogram.h"

#define N 4000000

static int64_t* gen_random(void)
{
    /* exp-spread over [1, 1e9], deterministic */
    int64_t* v = malloc(sizeof(int64_t) * N);
    unsigned long s = 0x9e3779b97f4a7c15UL;
    for (int i = 0; i < N; i++) {
        s ^= s << 13; s ^= s >> 7; s ^= s << 17;
        double u = (double)(s >> 11) / (double)(1UL << 53); /* [0,1) */
        double x = exp(u * log(1e9));                        /* 1 .. 1e9 */
        int64_t val = (int64_t)x;
        if (val < 1) val = 1; if (val > 1000000000) val = 1000000000;
        v[i] = val;
    }
    return v;
}

static int cmp_i64(const void* a, const void* b)
{
    int64_t x = *(const int64_t*)a, y = *(const int64_t*)b;
    return (x > y) - (x < y);
}

static int64_t* gen_clustered(int64_t* base)
{
    int64_t* v = malloc(sizeof(int64_t) * N);
    for (int i = 0; i < N; i++) v[i] = base[i];
    qsort(v, N, sizeof(int64_t), cmp_i64); /* sorted -> consecutive same-bucket runs */
    return v;
}

static int64_t* gen_hot90(int64_t* base)
{
    int64_t* v = malloc(sizeof(int64_t) * N);
    unsigned long s = 0x1234567;
    for (int i = 0; i < N; i++) {
        s ^= s << 13; s ^= s >> 7; s ^= s << 17;
        v[i] = ((s % 100) < 90) ? 42 : base[i];
    }
    return v;
}

static double run(const int64_t* vals, int64_t* out_total, int32_t* out_pop)
{
    struct hdr_packed_histogram* h = NULL;
    if (hdr_packed_init(1, 1000000000, 3, &h)) { fprintf(stderr, "init fail\n"); exit(1); }
    struct timespec t0, t1;
    clock_gettime(CLOCK_MONOTONIC, &t0);
    for (int i = 0; i < N; i++) hdr_packed_record_values(h, vals[i], 1);
    clock_gettime(CLOCK_MONOTONIC, &t1);
    double ns = (t1.tv_sec - t0.tv_sec) * 1e9 + (t1.tv_nsec - t0.tv_nsec);
    *out_total = hdr_packed_total_count(h);
    *out_pop = hdr_packed_populated(h);
    hdr_packed_close(h);
    return ns / (double)N;
}

static double median3(const int64_t* v, int64_t* tot, int32_t* pop)
{
    double a = run(v, tot, pop), b = run(v, tot, pop), c = run(v, tot, pop);
    double lo = a<b?a:b, hi = a<b?b:a;
    return c<lo?lo:(c>hi?hi:c);
}

int main(void)
{
    int64_t* rnd = gen_random();
    int64_t* clu = gen_clustered(rnd);
    int64_t* hot = gen_hot90(rnd);
    int64_t tot; int32_t pop;
    double r = median3(rnd, &tot, &pop);
    printf("random    %8.3f ns/op  total=%lld pop=%d\n", r, (long long)tot, pop);
    double c = median3(clu, &tot, &pop);
    printf("clustered %8.3f ns/op  total=%lld pop=%d\n", c, (long long)tot, pop);
    double ho = median3(hot, &tot, &pop);
    printf("hot90     %8.3f ns/op  total=%lld pop=%d\n", ho, (long long)tot, pop);
    return 0;
}

/*
 * packed_mem_bench.c  --  Phase-1 memory microbench for a hypothetical
 * sparse/packed HdrHistogram_c variant.
 *
 * Goal: quantify the memory win of a packed backing BEFORE committing to the
 * ~2k-line port, by comparing three numbers for N sparsely-populated histograms:
 *
 *   1. DENSE committed   = N * hdr_get_memory_size()          (VSZ-style upper bound)
 *   2. DENSE resident    = measured RSS delta                 (the FAIR baseline:
 *                          untouched calloc'd zero pages are NOT resident on Linux)
 *   3. PACKED modelled    = analytic projection of a PackedArrayContext-style
 *                          backing, printed as optimistic / realistic / pessimistic
 *
 * The packed numbers are a MODEL (no implementation exists yet). Assumptions are
 * printed and tunable so the crossover point is auditable, not asserted.
 *
 * Usage:
 *   packed_mem_bench [N] [D] [low] [high] [sigfig]
 *     N      number of histograms to keep live      (default 100000)
 *     D      distinct values recorded per histogram (default 10)
 *     low    lowest_discernible_value               (default 1)
 *     high   highest_trackable_value                (default 3600000000 = 1h in us)
 *     sigfig significant figures                    (default 3)
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include "hdr/hdr_histogram.h"
#include "hdr_packed_histogram.h"

/* ---- resident-set measurement (Linux /proc/self/statm, field 2 = RSS pages) ---- */
static void mem_bytes(size_t* vsz, size_t* rss)
{
    *vsz = *rss = 0;
    FILE* f = fopen("/proc/self/statm", "r");
    if (!f) return;
    long total_pages = 0, resident_pages = 0;
    if (fscanf(f, "%ld %ld", &total_pages, &resident_pages) != 2) { fclose(f); return; }
    fclose(f);
    *vsz = (size_t)total_pages * 4096u;
    *rss = (size_t)resident_pages * 4096u;
}

/* ---- PACKED footprint model -------------------------------------------------
 * Models a Gil-Tene PackedArrayContext-style backing (as in Java's
 * PackedHistogram). Physical storage is a long[] that starts at a minimum size
 * and grows by doubling; populated virtual entries consume physical slots plus
 * amortised set-tree index slots. Empty ranges cost nothing.
 *
 * per-histo(D) = CTX_STRUCT + roundup_pow2( max(MIN_PHYS, D_pop * SLOTS_PER_ENTRY * 8) )
 *
 * SLOTS_PER_ENTRY folds count-slot + amortised tree overhead into one knob and
 * is the dominant uncertainty, so we sweep it: optimistic / realistic / pessimistic.
 * ------------------------------------------------------------------------- */
#define PACKED_CTX_STRUCT   64u     /* context struct + malloc header, bytes   */
#define PACKED_MIN_PHYS    128u     /* minimum initial physical array, bytes   */

static size_t roundup_pow2_bytes(size_t n)
{
    size_t p = 1;
    while (p < n) p <<= 1;
    return p;
}

static size_t packed_per_histo(int32_t d_pop, double slots_per_entry)
{
    double raw = (double)d_pop * slots_per_entry * 8.0;
    size_t phys = roundup_pow2_bytes((size_t)(raw < PACKED_MIN_PHYS ? PACKED_MIN_PHYS : raw));
    return PACKED_CTX_STRUCT + phys;
}

static void human(size_t bytes, char* out, size_t outlen)
{
    const char* u[] = {"B", "KB", "MB", "GB", "TB"};
    double v = (double)bytes; int i = 0;
    while (v >= 1024.0 && i < 4) { v /= 1024.0; i++; }
    snprintf(out, outlen, "%.2f %s", v, u[i]);
}

int main(int argc, char** argv)
{
    long    N      = argc > 1 ? atol(argv[1]) : 100000;
    int32_t D      = argc > 2 ? atoi(argv[2]) : 10;
    int64_t low    = argc > 3 ? atoll(argv[3]) : 1;
    int64_t high   = argc > 4 ? atoll(argv[4]) : 3600000000LL;
    int     sigfig = argc > 5 ? atoi(argv[5]) : 3;

    /* one throwaway histogram to learn the config geometry */
    struct hdr_histogram* probe = NULL;
    if (hdr_init(low, high, sigfig, &probe) != 0) {
        fprintf(stderr, "hdr_init failed (check low/high/sigfig)\n");
        return 1;
    }
    int32_t counts_len = probe->counts_len;
    size_t  per_histo_committed = hdr_get_memory_size(probe);
    hdr_close(probe);

    /* distinct virtual indices actually populatable is capped by counts_len */
    int32_t d_pop = D < counts_len ? D : counts_len;

    /* geometric spread of D distinct sample values across [low, high] so they
     * land in distinct buckets (the realistic sparse-population case). */
    int64_t* samples = (int64_t*)malloc((size_t)D * sizeof(int64_t));
    for (int32_t i = 0; i < D; i++) {
        double frac = D > 1 ? (double)i / (double)(D - 1) : 0.0;
        double lv = log((double)(low < 1 ? 1 : low));
        double hv = log((double)high);
        samples[i] = (int64_t)exp(lv + frac * (hv - lv));
        if (samples[i] < low)  samples[i] = low;
        if (samples[i] > high) samples[i] = high;
    }

    size_t vsz_before, rss_before;
    mem_bytes(&vsz_before, &rss_before);

    struct hdr_histogram** hs = (struct hdr_histogram**)malloc((size_t)N * sizeof(*hs));
    if (!hs) { fprintf(stderr, "OOM on pointer array\n"); return 1; }

    long ok = 0;
    for (long n = 0; n < N; n++) {
        struct hdr_histogram* h = NULL;
        if (hdr_init(low, high, sigfig, &h) != 0) {
            fprintf(stderr, "hdr_init failed at n=%ld (out of memory?) -- "
                            "reduce N; got %ld allocated\n", n, ok);
            N = n;  /* report on what we actually built */
            break;
        }
        for (int32_t i = 0; i < D; i++) hdr_record_value(h, samples[i]);
        hs[n] = h;
        ok++;
    }

    size_t vsz_after, rss_after;
    mem_bytes(&vsz_after, &rss_after);
    size_t rss_delta    = rss_after > rss_before ? rss_after - rss_before : 0;
    size_t vsz_delta    = vsz_after > vsz_before ? vsz_after - vsz_before : 0;
    size_t dense_commit = (size_t)N * per_histo_committed;

    /* ---- report ---- */
    char b1[32], b2[32], b3[32], b4[32], b5[32], b6[32];
    printf("=============================================================\n");
    printf(" PACKED vs DENSE memory microbench (HdrHistogram_c)\n");
    printf("=============================================================\n");
    printf("config:  low=%lld high=%lld sigfig=%d\n", (long long)low, (long long)high, sigfig);
    printf("         counts_len=%d  -> dense per-histo committed=%zu B (%s)\n",
           counts_len, per_histo_committed, (human(per_histo_committed,b1,sizeof b1), b1));
    printf("workload: N=%ld histograms, D=%d distinct values each (d_populatable=%d)\n\n",
           N, D, d_pop);

    human(dense_commit, b1, sizeof b1);
    human(rss_delta,    b2, sizeof b2);
    char bv[32]; human(vsz_delta, bv, sizeof bv);
    printf("DENSE committed (N * hdr_get_memory_size) : %14zu B  (%s)  <- hard VSZ floor\n",
           dense_commit, b1);
    printf("  measured VSZ delta (address space)      : %14zu B  (%s)\n", vsz_delta, bv);
    printf("DENSE resident  (measured RSS delta)      : %14zu B  (%s)  <- allocator-dependent\n",
           rss_delta, b2);
    if (dense_commit)
        printf("   -> resident is %.1f%% of committed. NOTE: resident fraction is a glibc\n"
               "      artifact (calloc from heap memsets -> fully resident; fresh mmap stays\n"
               "      lazy). Under real many-histogram churn it trends toward 100%%. The VSZ\n"
               "      floor above is the unconditional cost packed eliminates.\n\n",
               100.0 * (double)rss_delta / (double)dense_commit);

    printf("PACKED modelled per-histo (D_pop=%d, +ctx=%uB, min_phys=%uB):\n",
           d_pop, PACKED_CTX_STRUCT, PACKED_MIN_PHYS);
    struct { const char* name; double spe; } scen[] = {
        {"optimistic  (2B/entry, tight)", 0.25},
        {"realistic   (8B/entry, 1 long/entry + tree)", 1.0},
        {"pessimistic (16B/entry, tree-heavy)", 2.0},
    };
    for (size_t s = 0; s < sizeof scen / sizeof scen[0]; s++) {
        size_t per = packed_per_histo(d_pop, scen[s].spe);
        size_t tot = (size_t)N * per;
        human(per, b3, sizeof b3);
        human(tot, b4, sizeof b4);
        double vs_commit = dense_commit ? 100.0 * (double)tot / (double)dense_commit : 0;
        double vs_res    = rss_delta    ? 100.0 * (double)tot / (double)rss_delta    : 0;
        printf("   %-44s per=%9s tot=%9s  (%.1f%% of committed, %.0f%% of resident)\n",
               scen[s].name, b3, b4, vs_commit, vs_res);
    }

    /* ---- MEASURED packed: build the real Phase-1 variant, sum exact bytes held.
       hdr_packed_get_memory_size is the precise heap request (struct + live
       sparse arrays), so this is allocator-noise-free -- the model's "realistic"
       column becomes a measured number. Dense is freed first to bound RSS. */
    for (long n = 0; n < N; n++) hdr_close(hs[n]);

    struct hdr_packed_config* pcfg = NULL;
    if (hdr_packed_config_create(low, high, sigfig, &pcfg) != 0) {
        fprintf(stderr, "packed config create failed\n"); return 1;
    }
    struct hdr_packed_histogram** ph =
        (struct hdr_packed_histogram**)malloc((size_t)N * sizeof(*ph));
    size_t vsz_p0, rss_p0; mem_bytes(&vsz_p0, &rss_p0);
    size_t packed_exact = hdr_packed_config_memory_size(pcfg);  /* shared, counted once */
    int32_t populated_last = 0, width_last = 1;
    for (long n = 0; n < N; n++) {
        struct hdr_packed_histogram* p = NULL;
        if (hdr_packed_init_shared(pcfg, &p) != 0) { N = n; break; }
        for (int32_t i = 0; i < D; i++) hdr_packed_record_value(p, samples[i]);
        packed_exact += hdr_packed_get_memory_size(p);
        populated_last = hdr_packed_populated(p);
        width_last = hdr_packed_count_width(p);
        ph[n] = p;
    }
    size_t vsz_p1, rss_p1; mem_bytes(&vsz_p1, &rss_p1);
    size_t packed_rss = rss_p1 > rss_p0 ? rss_p1 - rss_p0 : 0;

    printf("\nMEASURED packed (Phase-2: shared geom + %dB counts, %d populated/histo):\n",
           width_last, populated_last);
    human(packed_exact, b5, sizeof b5);
    char bpr[32]; human(packed_rss, bpr, sizeof bpr);
    printf("   exact bytes held (shared config once + N * per-histo) : %s\n", b5);
    printf("   measured RSS delta (allocator incl. overhead)         : %s\n", bpr);

    printf("\nverdict (measured packed exact vs dense):\n");
    human(dense_commit, b6, sizeof b6);
    printf("   packed=%s  vs  dense committed=%s  -> %.1fx smaller (VSZ floor)\n",
           b5, b6, dense_commit ? (double)dense_commit / (double)packed_exact : 0);
    if (rss_delta) {
        human(rss_delta, b4, sizeof b4);
        printf("   packed=%s  vs  dense resident =%s  -> %.1fx smaller\n",
               b5, b4, (double)rss_delta / (double)packed_exact);
    }

    for (long n = 0; n < N; n++) hdr_packed_close(ph[n]);
    hdr_packed_config_destroy(pcfg);
    free(ph); free(hs); free(samples);
    return 0;
}

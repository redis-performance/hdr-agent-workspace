/*
 * packed_fuzzer.c -- libFuzzer harness for the packed HdrHistogram variant.
 *
 * Three modes, chosen by data[0] % 3:
 *   0 DIFFERENTIAL : replay a byte-driven op stream into BOTH a dense
 *                    hdr_histogram and a packed one; assert every query result
 *                    is identical and that their V2 encodings are byte-identical
 *                    (which validates the entire count distribution at once).
 *   1 RAW DECODE   : feed the raw fuzz bytes to hdr_packed_decode_compressed.
 *                    Must never crash / OOB / UB on hostile input.
 *   2 CORRUPT RT   : build a valid packed histogram, encode it, splice fuzz
 *                    bytes into the compressed stream, then decode. Exercises
 *                    "almost valid" streams (the dangerous case).
 *
 * Build (libFuzzer + ASan + UBSan; -fno-sanitize-recover makes UB ABORT so the
 * fuzzer records a crashing input instead of logging-and-continuing):
 *   clang -O1 -g -std=c11 -fsanitize=fuzzer,address,undefined -fno-sanitize-recover=all \
 *     -I<inc> -I<hdrsrc> -I. packed_fuzzer.c hdr_packed_histogram.c \
 *     -L<lib> -lhdr_histogram_static -lz -lm -o packed_fuzzer
 * (or run with UBSAN_OPTIONS=halt_on_error=1)
 */
#define _DEFAULT_SOURCE 1
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <hdr/hdr_histogram.h>
#include "hdr_packed_histogram.h"

extern int hdr_encode_compressed(struct hdr_histogram*, uint8_t**, size_t*);
extern int hdr_decode_compressed(uint8_t*, size_t, struct hdr_histogram**);

#define LOW 1
#define HIGH 3600000000LL
#define SIG 3

/* little byte-cursor over the fuzz input */
typedef struct { const uint8_t* p; size_t n, i; } cur_t;
static uint64_t take(cur_t* c, int bytes)
{
    uint64_t v = 0;
    for (int b = 0; b < bytes; b++)
        v = (v << 8) | (c->i < c->n ? c->p[c->i++] : 0);
    return v;
}

static void die(const char* what) { fprintf(stderr, "DIFF FAIL: %s\n", what); abort(); }

static void differential(cur_t* c)
{
    /* Vary the config: HIGH (3.6e9) or INT64_MAX. The INT64_MAX case reaches the
       top bucket whose upper edge exceeds INT64_MAX -- the highest-equivalent
       overflow path a red-team review found. */
    int64_t high = (take(c, 1) & 1) ? INT64_MAX : HIGH;
    struct hdr_histogram* d = NULL;
    struct hdr_packed_histogram* p = NULL;
    if (hdr_init(LOW, high, SIG, &d) != 0) return;
    if (hdr_packed_init(LOW, high, SIG, &p) != 0) { hdr_close(d); return; }

    /* replay ops until the input is exhausted. Cap kept modest: the sparse
       insert is O(n) per new bucket, so thousands of random-order inserts are
       O(n^2) and would throttle fuzz throughput under ASan. */
    for (int ops = 0; ops < 512 && c->i < c->n; ops++)
    {
        int64_t value = (int64_t)(take(c, 8) % (uint64_t)high); /* [0, high) */
        /* counts: usually small, sometimes huge to exercise width widening */
        uint8_t k = (uint8_t) take(c, 1);
        int64_t count;
        switch (k & 3) {
            case 0:  count = 1 + (k >> 2); break;                 /* 1..64 */
            case 1:  count = 1 + (int64_t)(take(c, 2)); break;    /* up to 65536 */
            case 2:  count = 1 + (int64_t)(take(c, 5)); break;    /* up to ~2^40 */
            default: count = 1; break;
        }
        bool rd = hdr_record_values(d, value, count);
        bool rp = hdr_packed_record_values(p, value, count);
        if (rd != rp) die("record return differs");
    }

    if (hdr_min(d) != hdr_packed_min(p)) die("min");
    if (hdr_max(d) != hdr_packed_max(p)) die("max");
    if (d->total_count != hdr_packed_total_count(p)) die("total");

    const double pcts[] = {0, 1, 10, 25, 50, 75, 90, 99, 99.9, 100};
    for (size_t j = 0; j < sizeof(pcts)/sizeof(pcts[0]); j++)
        if (hdr_value_at_percentile(d, pcts[j]) != hdr_packed_value_at_percentile(p, pcts[j]))
            die("percentile");

    /* Compare mean/stddev only when dense's int64 accumulation cannot overflow
       (dense c*median is int64; packed uses double). Otherwise dense returns
       overflow garbage and the mismatch would be a false positive. */
    if (d->total_count > 0 && high <= HIGH && d->total_count < INT64_MAX / (HIGH + 1)) {
        double md = hdr_mean(d), mp = hdr_packed_mean(p);
        if (fabs(md - mp) > fabs(md) * 1e-6 + 1e-3) die("mean");
        double sd = hdr_stddev(d), sp = hdr_packed_stddev(p);
        if (fabs(sd - sp) > fabs(sd) * 1e-6 + 1e-3) die("stddev");
    }

    /* strongest invariant: identical V2 encodings => identical distributions */
    uint8_t *sd = NULL, *sp = NULL; size_t ld = 0, lp = 0;
    int ed = hdr_encode_compressed(d, &sd, &ld);
    int ep = hdr_packed_encode_compressed(p, &sp, &lp);
    if (ed == 0 && ep == 0) {
        if (ld != lp || memcmp(sd, sp, ld) != 0) die("encoding not byte-identical");
        /* and packed's stream decodes back through the dense reader */
        struct hdr_histogram* dr = NULL;
        if (hdr_decode_compressed(sp, lp, &dr) == 0 && dr) {
            if (dr->total_count != d->total_count) die("roundtrip total");
            hdr_close(dr);
        }
        /* dense stream decodes through the packed reader */
        struct hdr_packed_histogram* pr = NULL;
        if (hdr_packed_decode_compressed(sd, ld, &pr) == 0 && pr) {
            if (hdr_packed_total_count(pr) != d->total_count) die("packed roundtrip total");
            hdr_packed_close(pr);
        }
    }
    free(sd); free(sp);
    hdr_close(d); hdr_packed_close(p);
}

static void raw_decode(const uint8_t* data, size_t size)
{
    struct hdr_packed_histogram* out = NULL;
    /* copy so the decoder gets a writable, exactly-sized buffer */
    uint8_t* buf = (uint8_t*) malloc(size ? size : 1);
    if (!buf) return;
    memcpy(buf, data, size);
    if (hdr_packed_decode_compressed(buf, size, &out) == 0 && out) {
        /* exercise the query API on the decoded (attacker-shaped) histogram */
        hdr_packed_min(out); hdr_packed_max(out); hdr_packed_mean(out);
        hdr_packed_stddev(out); hdr_packed_value_at_percentile(out, 99.0);
        hdr_packed_get_memory_size(out);
        hdr_packed_close(out);
    }
    free(buf);
}

static void corrupt_roundtrip(cur_t* c)
{
    /* vary geometry (INT64_MAX reaches the top bucket) and count width, so the
       spliced/corrupted stream exercises hostile decode of wide-count and
       top-bucket shapes -- not just HIGH-geometry width-1. */
    int64_t high = (take(c, 1) & 1) ? INT64_MAX : HIGH;
    struct hdr_packed_histogram* p = NULL;
    if (hdr_packed_init(LOW, high, SIG, &p) != 0) return;
    for (int ops = 0; ops < 256 && c->i < c->n; ops++)
    {
        int64_t v = (int64_t)(take(c, 8) % (uint64_t) high);
        uint8_t k = (uint8_t) take(c, 1);
        int64_t cnt = (k & 3) ? 1 : 1 + (int64_t) take(c, 5); /* sometimes wide */
        hdr_packed_record_values(p, v, cnt);
    }

    uint8_t* enc = NULL; size_t len = 0;
    if (hdr_packed_encode_compressed(p, &enc, &len) == 0 && enc && len) {
        /* splice remaining fuzz bytes over the encoded stream */
        for (size_t k = 0; k < len && c->i < c->n; k++)
            if (c->p[c->i] & 1) enc[k] ^= c->p[c->i++]; else c->i++;
        struct hdr_packed_histogram* out = NULL;
        if (hdr_packed_decode_compressed(enc, len, &out) == 0 && out) {
            hdr_packed_value_at_percentile(out, 50.0);
            hdr_packed_close(out);
        }
    }
    free(enc);
    hdr_packed_close(p);
}

int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size)
{
    if (size < 1) return 0;
    cur_t c = { data + 1, size - 1, 0 };
    switch (data[0] % 3) {
        case 0: differential(&c); break;
        case 1: raw_decode(data + 1, size - 1); break;
        default: corrupt_roundtrip(&c); break;
    }
    return 0;
}

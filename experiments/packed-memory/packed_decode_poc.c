/*
 * packed_decode_poc.c -- FINAL untrusted-input decode PoC.
 *
 * Crafts hostile *compressed V2 streams* (not white-box in-memory states) and
 * feeds them to hdr_packed_decode_compressed, then queries every percentile,
 * mean, stddev, min, max, count_at_value, memory_size, and re-encode on any
 * histogram that decodes successfully. Streams cover:
 *   - INT64_MAX geometry (top bucket edge exceeds INT64_MAX)
 *   - wide counts (width-8), single top-bucket value at INT64_MAX count
 *   - saturated totals (multiple buckets each INT64_MAX -> sum overflows int64)
 *   - malformed: huge payload_len (decode-bomb), zero-run == INT32_MIN
 *     (-INT64_MIN negation UB bait), zero-run overflowing counts_len,
 *     truncated / trailing-garbage payloads, non-zero normalizing_index_offset,
 *     bogus geometry, short buffers, bad cookies, corrupt zlib.
 *   - fully random byte streams.
 *
 * Include the impl TU for the flyweight layout + PK_COMPRESS + zig-zag, exactly
 * as the redteam does. Build with clang -fsanitize=address,undefined,
 * float-cast-overflow -fno-sanitize-recover=all, UBSAN_OPTIONS=halt_on_error=1.
 */
#define _DEFAULT_SOURCE 1
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <zlib.h>

#include "hdr_packed_histogram.c"   /* full internal visibility: flyweights, PK_COMPRESS */

static long decoded_ok = 0, rejected = 0, crafted = 0;

/* Wrap an already-built encoding-flyweight image (raw, uncompressed bytes:
 * PK_SIZEOF_ENC header + payload) into a compression flyweight and hand it to
 * the packed decoder. Optionally mangle the compression header. */
static int feed(const uint8_t* enc_img, size_t enc_len,
                int bad_ccookie, int lie_clen, int32_t clen_override)
{
    uLongf dest = compressBound((uLong) enc_len);
    uint8_t* cmp = (uint8_t*) malloc(PK_SIZEOF_CMP + dest);
    if (!cmp) return -1;
    pk_compression_flyweight_t* c = (pk_compression_flyweight_t*) cmp;
    if (compress(c->data, &dest, enc_img, (uLong) enc_len) != Z_OK) { free(cmp); return -1; }
    c->cookie = htobe32(PK_V2_COMPRESSION_COOKIE | (bad_ccookie ? 0x0U : 0x10U));
    if (bad_ccookie) c->cookie = htobe32(0xdeadbeefU);
    c->length = htobe32(lie_clen ? clen_override : (int32_t) dest);

    crafted++;
    struct hdr_packed_histogram* out = NULL;
    int rc = hdr_packed_decode_compressed(cmp, PK_SIZEOF_CMP + dest, &out);
    if (rc == 0 && out)
    {
        decoded_ok++;
        /* hammer every read path on the attacker-shaped histogram */
        volatile uint64_t sink = 0;   /* unsigned: wrap is defined, no harness UB */
        sink += (uint64_t) hdr_packed_min(out);
        sink += (uint64_t) hdr_packed_max(out);
        sink += (uint64_t) hdr_packed_total_count(out);
        sink += (uint64_t) hdr_packed_count_at_value(out, 0);
        sink += (uint64_t) hdr_packed_count_at_value(out, INT64_MAX);
        volatile double dsink = hdr_packed_mean(out) + hdr_packed_stddev(out);
        (void) dsink;
        for (int i = 0; i <= 10000; i++)
        {
            double p = (double) i / 100.0;              /* 0.00 .. 100.00 */
            sink += (uint64_t) hdr_packed_value_at_percentile(out, p);
        }
        /* UB-bait percentiles */
        double bait[] = {-0.0, -1.0, -1e300, 1e300, 200.0, 100.5,
                         (double) NAN, (double) INFINITY, (double) -INFINITY};
        for (size_t i = 0; i < sizeof(bait)/sizeof(bait[0]); i++)
            sink += (uint64_t) hdr_packed_value_at_percentile(out, bait[i]);
        (void) sink;
        hdr_packed_get_memory_size(out);
        /* re-encode the hostile histogram (exercises encode over crafted state) */
        uint8_t* re = NULL; size_t rl = 0;
        if (hdr_packed_encode_compressed(out, &re, &rl) == 0) free(re);
        hdr_packed_close(out);
    }
    else
    {
        rejected++;
    }
    free(cmp);
    return rc;
}

/* Build an encoding-flyweight image for geometry (low,high,sig) carrying the
 * given (gap-encoded) payload bytes. offset lets us inject a non-zero
 * normalizing_index_offset. Returns malloc'd image + length via out params. */
static uint8_t* build_enc(int64_t low, int64_t high, int32_t sig,
                          const uint8_t* payload, int32_t payload_len,
                          int32_t offset, int32_t payload_len_override,
                          int use_override, size_t* out_len)
{
    size_t len = PK_SIZEOF_ENC + (size_t)(payload_len > 0 ? payload_len : 0);
    uint8_t* img = (uint8_t*) calloc(1, len ? len : 1);
    if (!img) return NULL;
    pk_encoding_flyweight_t* e = (pk_encoding_flyweight_t*) img;
    e->cookie                   = htobe32(PK_V2_ENCODING_COOKIE | 0x10U);
    e->payload_len              = htobe32(use_override ? payload_len_override : payload_len);
    e->normalizing_index_offset = htobe32(offset);
    e->significant_figures      = htobe32(sig);
    e->lowest_discernible_value = htobe64(low);
    e->highest_trackable_value  = htobe64(high);
    e->conversion_ratio_bits    = htobe64(pk_dbl_to_bits(1.0));
    if (payload && payload_len > 0)
        memcpy(img + PK_SIZEOF_ENC, payload, (size_t) payload_len);
    *out_len = len;
    return img;
}

/* Append one (index,count) as decode expects it: gap zero-run then the count.
 * prev tracks the next expected index. */
static int32_t emit_bucket(uint8_t* buf, int32_t di, int32_t idx, int32_t* prev, int64_t count)
{
    int32_t gap = idx - *prev;
    if (gap > 0) di += zig_zag_encode_i64(&buf[di], -(int64_t) gap);
    di += zig_zag_encode_i64(&buf[di], count);
    *prev = idx + 1;
    return di;
}

/* Craft & feed a valid-but-hostile stream: buckets given as (idx,count) pairs. */
static void hostile(const char* what, int64_t low, int64_t high, int32_t sig,
                    const int32_t* idxs, const int64_t* cnts, int n)
{
    struct hdr_packed_config* cfg = NULL;
    if (hdr_packed_config_create(low, high, sig, &cfg) != 0) return;
    int32_t clen = cfg->geom.counts_len;
    hdr_packed_config_destroy(cfg);

    uint8_t payload[4096];
    int32_t di = 0, prev = 0;
    for (int k = 0; k < n; k++)
    {
        int32_t ix = idxs[k] < 0 ? (clen + idxs[k]) : idxs[k];   /* negative = from top */
        if (ix < 0 || ix >= clen) continue;
        if (di > (int32_t) sizeof(payload) - 16) break;
        di = emit_bucket(payload, di, ix, &prev, cnts[k]);
    }
    size_t elen = 0;
    uint8_t* img = build_enc(low, high, sig, payload, di, 0, 0, 0, &elen);
    if (!img) return;
    int rc = feed(img, elen, 0, 0, 0);
    printf("  [%s] low=%lld high=%lld sig=%d clen=%d rc=%d\n",
           what, (long long) low, (long long) high, sig, clen, rc);
    free(img);
}

int main(void)
{
    printf("packed decode PoC -- hostile compressed streams\n\n");

    const int64_t highs[] = {100000LL, 3600000000LL, INT64_MAX};
    const int64_t lows[]  = {1, 1000000LL};

    printf("== valid-but-hostile decodable streams ==\n");
    for (size_t hi = 0; hi < 3; hi++)
    for (size_t li = 0; li < 2; li++)
    for (int sig = 1; sig <= 5; sig++)
    {
        int64_t high = highs[hi], low = lows[li];
        if (high < 2 * low) continue;

        /* single top-bucket value with INT64_MAX count (width-8) */
        { int32_t ix[] = {-1}; int64_t cn[] = {INT64_MAX};
          hostile("top-INT64_MAX", low, high, sig, ix, cn, 1); }

        /* bulk low + single top -> p100 must land on top bucket */
        { int32_t ix[] = {0, -1}; int64_t cn[] = {1000, 1};
          hostile("two-p100-top", low, high, sig, ix, cn, 2); }

        /* saturated total: two buckets each INT64_MAX -> sum overflows int64 */
        { int32_t ix[] = {0, -1}; int64_t cn[] = {INT64_MAX, INT64_MAX};
          hostile("saturated-total", low, high, sig, ix, cn, 2); }

        /* many buckets, large per-bucket counts near saturation */
        { int32_t ix[] = {0, -4, -3, -2, -1};
          int64_t cn[] = {INT64_MAX/2, INT64_MAX/2, INT64_MAX/2, INT64_MAX/2, INT64_MAX/2};
          hostile("many-near-sat", low, high, sig, ix, cn, 5); }

        /* bucket 0 populated (min == 0 path) + top */
        { int32_t ix[] = {0, -1}; int64_t cn[] = {5, 7};
          hostile("zero-and-top", low, high, sig, ix, cn, 2); }
    }

    printf("\n== malformed streams (must be rejected, no UB) ==\n");
    {
        /* payload_len lies larger than the geometry allows (decode bomb) */
        uint8_t pl[16]; int32_t p=0, prev=0; p = emit_bucket(pl, p, 0, &prev, 1);
        size_t el; uint8_t* img = build_enc(1, INT64_MAX, 3, pl, p, 0, INT32_MAX, 1, &el);
        int rc = feed(img, el, 0, 0, 0); printf("  [bomb payload_len=INT32_MAX] rc=%d\n", rc); free(img);
    }
    {
        /* zero-run == INT32_MIN encoded: -value would be UB if negated pre-check */
        uint8_t pl[16]; int32_t p=0; p += zig_zag_encode_i64(&pl[p], (int64_t) INT32_MIN);
        size_t el; uint8_t* img = build_enc(1, INT64_MAX, 3, pl, p, 0, 0, 0, &el);
        int rc = feed(img, el, 0, 0, 0); printf("  [zero-run INT32_MIN] rc=%d\n", rc); free(img);
    }
    {
        /* huge negative zero-run overflowing counts_len */
        uint8_t pl[16]; int32_t p=0; p += zig_zag_encode_i64(&pl[p], -(int64_t)2000000000);
        size_t el; uint8_t* img = build_enc(1, 100000, 3, pl, p, 0, 0, 0, &el);
        int rc = feed(img, el, 0, 0, 0); printf("  [zero-run > counts_len] rc=%d\n", rc); free(img);
    }
    {
        /* trailing garbage: value token whose count spills, plus extra len */
        uint8_t pl[16]; int32_t p=0, prev=0; p = emit_bucket(pl, p, 0, &prev, 1);
        size_t el; uint8_t* img = build_enc(1, 100000, 3, pl, p, 0, p + 3, 1, &el);
        int rc = feed(img, el, 0, 0, 0); printf("  [payload_len too long] rc=%d\n", rc); free(img);
    }
    {
        /* truncated: payload_len shorter than actual token (mid-varint stop) */
        uint8_t pl[16]; int32_t p=0, prev=0; p = emit_bucket(pl, p, 5, &prev, 300000); /* multi-byte */
        size_t el; uint8_t* img = build_enc(1, 100000, 3, pl, p, 0, 1, 1, &el);
        int rc = feed(img, el, 0, 0, 0); printf("  [payload_len truncated] rc=%d\n", rc); free(img);
    }
    {
        /* non-zero normalizing_index_offset -> must be EINVAL */
        uint8_t pl[16]; int32_t p=0, prev=0; p = emit_bucket(pl, p, 0, &prev, 1);
        size_t el; uint8_t* img = build_enc(1, 100000, 3, pl, p, 7, 0, 0, &el);
        int rc = feed(img, el, 0, 0, 0); printf("  [nonzero offset] rc=%d (want EINVAL=%d)\n", rc, EINVAL); free(img);
    }
    {
        /* negative payload_len */
        uint8_t pl[16]; int32_t p=0, prev=0; p = emit_bucket(pl, p, 0, &prev, 1);
        size_t el; uint8_t* img = build_enc(1, 100000, 3, pl, p, 0, -5, 1, &el);
        int rc = feed(img, el, 0, 0, 0); printf("  [negative payload_len] rc=%d\n", rc); free(img);
    }
    {
        /* bogus geometry: high < 2*low -> config_create must fail */
        uint8_t pl[16]; int32_t p=0, prev=0; p = emit_bucket(pl, p, 0, &prev, 1);
        size_t el; uint8_t* img = build_enc(1000000, 1000, 3, pl, p, 0, 0, 0, &el);
        int rc = feed(img, el, 0, 0, 0); printf("  [bad geometry] rc=%d\n", rc); free(img);
    }
    {
        /* bad significant_figures (out of 1..5) */
        uint8_t pl[16]; int32_t p=0, prev=0; p = emit_bucket(pl, p, 0, &prev, 1);
        size_t el; uint8_t* img = build_enc(1, 100000, 99, pl, p, 0, 0, 0, &el);
        int rc = feed(img, el, 0, 0, 0); printf("  [bad sig] rc=%d\n", rc); free(img);
    }
    {
        /* bad encoding cookie */
        uint8_t pl[16]; int32_t p=0, prev=0; p = emit_bucket(pl, p, 0, &prev, 1);
        size_t el; uint8_t* img = build_enc(1, 100000, 3, pl, p, 0, 0, 0, &el);
        pk_encoding_flyweight_t* e = (pk_encoding_flyweight_t*) img;
        e->cookie = htobe32(0x11112222U);
        int rc = feed(img, el, 0, 0, 0); printf("  [bad enc cookie] rc=%d\n", rc); free(img);
    }
    {
        /* bad compression cookie */
        uint8_t pl[16]; int32_t p=0, prev=0; p = emit_bucket(pl, p, 0, &prev, 1);
        size_t el; uint8_t* img = build_enc(1, 100000, 3, pl, p, 0, 0, 0, &el);
        int rc = feed(img, el, 1, 0, 0); printf("  [bad cmp cookie] rc=%d\n", rc); free(img);
    }
    {
        /* compression length field lies (negative / oversized) */
        uint8_t pl[16]; int32_t p=0, prev=0; p = emit_bucket(pl, p, 0, &prev, 1);
        size_t el; uint8_t* img = build_enc(1, 100000, 3, pl, p, 0, 0, 0, &el);
        int rc1 = feed(img, el, 0, 1, -1);          printf("  [cmp.length=-1] rc=%d\n", rc1);
        int rc2 = feed(img, el, 0, 1, INT32_MAX);   printf("  [cmp.length=INT32_MAX] rc=%d\n", rc2);
        free(img);
    }

    printf("\n== short / raw byte streams (must be rejected, no UB) ==\n");
    for (size_t len = 0; len < 40; len++)
    {
        uint8_t* buf = (uint8_t*) malloc(len ? len : 1);
        for (size_t i = 0; i < len; i++) buf[i] = (uint8_t)(0xA5 ^ (i * 31));
        struct hdr_packed_histogram* out = NULL;
        int rc = hdr_packed_decode_compressed(buf, len, &out);
        if (rc == 0 && out) hdr_packed_close(out);
        crafted++; if (rc) rejected++; else decoded_ok++;
        free(buf);
    }

    printf("\n== random fuzz of the raw decode entry ==\n");
    srand(12345);
    for (int t = 0; t < 200000; t++)
    {
        size_t len = (size_t)(rand() % 96);
        uint8_t* buf = (uint8_t*) malloc(len ? len : 1);
        for (size_t i = 0; i < len; i++) buf[i] = (uint8_t) rand();
        /* half the time, stamp a valid compression cookie to reach deeper code */
        if ((t & 1) && len >= PK_SIZEOF_CMP)
        {
            pk_compression_flyweight_t* c = (pk_compression_flyweight_t*) buf;
            c->cookie = htobe32(PK_V2_COMPRESSION_COOKIE | 0x10U);
            c->length = htobe32((int32_t)(len - PK_SIZEOF_CMP));
        }
        struct hdr_packed_histogram* out = NULL;
        int rc = hdr_packed_decode_compressed(buf, len, &out);
        if (rc == 0 && out)
        {
            hdr_packed_value_at_percentile(out, 99.9);
            hdr_packed_mean(out); hdr_packed_stddev(out);
            hdr_packed_close(out);
        }
        crafted++; if (rc) rejected++; else decoded_ok++;
        free(buf);
    }

    printf("\ncrafted=%ld decoded_ok=%ld rejected=%ld\n", crafted, decoded_ok, rejected);
    printf("PoC completed without sanitizer abort.\n");
    return 0;
}

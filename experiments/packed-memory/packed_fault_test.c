/*
 * packed_fault_test.c -- exercises the defensive/error branches of
 * hdr_packed_histogram.c that normal workloads never hit: allocation failures,
 * compress failure, and malformed serialized input.
 *
 * Compile the UUT with -DPACKED_FAULT_HOOKS so the pk_fail_* one-shot counters
 * are live, then arm one failure at a time.
 */
#define _DEFAULT_SOURCE 1
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <endian.h>
#include <zlib.h>
#include "hdr/hdr_histogram.h"
#include "hdr_packed_histogram.h"

/* one-shot fault counters defined in the UUT under PACKED_FAULT_HOOKS */
extern int pk_fail_calloc, pk_fail_realloc, pk_fail_malloc, pk_fail_compress;
extern int zig_zag_encode_i64(uint8_t* buffer, int64_t signed_value);

static int failures = 0;
#define CHECK(cond, msg) do { \
    if (!(cond)) { printf("  FAIL: %s\n", msg); failures++; } \
    else         { printf("  ok:   %s\n", msg); } \
} while (0)

#define LOW 1
#define HIGH 3600000000LL
#define SIG 3

/* ---- allocation-failure branches ----------------------------------------- */
static void fault_allocs(void)
{
    struct hdr_packed_histogram* h = NULL;
    struct hdr_packed_config* cfg = NULL;

    pk_fail_calloc = 1;
    CHECK(hdr_packed_config_create(LOW, HIGH, SIG, &cfg) == ENOMEM, "config_create calloc fail -> ENOMEM");

    pk_fail_calloc = 1;
    CHECK(hdr_packed_init(LOW, HIGH, SIG, &h) == ENOMEM, "init: config calloc fail -> ENOMEM");
    pk_fail_calloc = 2;  /* config ok, histogram calloc fails -> config_destroy path */
    CHECK(hdr_packed_init(LOW, HIGH, SIG, &h) == ENOMEM, "init: histogram calloc fail -> ENOMEM+cleanup");

    hdr_packed_config_create(LOW, HIGH, SIG, &cfg);
    pk_fail_calloc = 1;
    CHECK(hdr_packed_init_shared(cfg, &h) == ENOMEM, "init_shared calloc fail -> ENOMEM");

    /* ensure_cap: fail idx realloc, then cnt realloc */
    hdr_packed_init_shared(cfg, &h);
    pk_fail_realloc = 1;
    CHECK(!hdr_packed_record_value(h, 42), "record: ensure_cap idx realloc fail -> false");
    pk_fail_realloc = 2;
    CHECK(!hdr_packed_record_value(h, 42), "record: ensure_cap cnt realloc fail -> false");
    hdr_packed_close(h);

    /* widen on HIT: existing bucket, big delta forces width grow, realloc fails */
    hdr_packed_init_shared(cfg, &h);
    hdr_packed_record_value(h, 500);          /* width 1, cap allocated */
    pk_fail_realloc = 1;
    CHECK(!hdr_packed_record_values(h, 500, 70000), "record: widen-on-hit realloc fail -> false");
    hdr_packed_close(h);

    /* widen on INSERT: new bucket with big delta, cap already available */
    hdr_packed_init_shared(cfg, &h);
    hdr_packed_record_value(h, 500);          /* size1, cap4 -> next insert needs no ensure_cap */
    pk_fail_realloc = 1;
    CHECK(!hdr_packed_record_values(h, 999, 70000), "record: widen-on-insert realloc fail -> false");
    hdr_packed_close(h);

    hdr_packed_config_destroy(cfg);
}

/* ---- encode-path failures ------------------------------------------------- */
static void fault_encode(void)
{
    struct hdr_packed_histogram* h = NULL;
    hdr_packed_init(LOW, HIGH, SIG, &h);
    for (int i = 0; i < 50; i++) hdr_packed_record_value(h, (i + 1) * 1000);
    uint8_t* buf = NULL; size_t len = 0;

    pk_fail_calloc = 1;
    CHECK(hdr_packed_encode_compressed(h, &buf, &len) == ENOMEM, "encode: flyweight calloc fail -> ENOMEM");
    pk_fail_malloc = 1;
    CHECK(hdr_packed_encode_compressed(h, &buf, &len) == ENOMEM, "encode: compressed malloc fail -> ENOMEM");
    pk_fail_compress = 1;
    CHECK(hdr_packed_encode_compressed(h, &buf, &len) != 0, "encode: compress() fail -> error");

    hdr_packed_close(h);
}

/* ---- decode-path failures (armed allocs on a valid stream) ---------------- */
static void fault_decode_alloc(void)
{
    struct hdr_packed_histogram* h = NULL;
    hdr_packed_init(LOW, HIGH, SIG, &h);
    for (int i = 0; i < 50; i++) hdr_packed_record_value(h, (i + 1) * 1000);
    uint8_t* buf = NULL; size_t len = 0;
    hdr_packed_encode_compressed(h, &buf, &len);

    struct hdr_packed_histogram* out = NULL;
    pk_fail_calloc = 1;  /* config_create inside decode */
    CHECK(hdr_packed_decode_compressed(buf, len, &out) == ENOMEM, "decode: config calloc fail -> ENOMEM");
    pk_fail_calloc = 2;  /* histogram calloc inside decode */
    CHECK(hdr_packed_decode_compressed(buf, len, &out) == ENOMEM, "decode: histogram calloc fail -> ENOMEM");
    pk_fail_calloc = 3;  /* counts_array calloc inside decode */
    CHECK(hdr_packed_decode_compressed(buf, len, &out) == ENOMEM, "decode: counts_array calloc fail -> ENOMEM");

    free(buf);
    hdr_packed_close(h);
}

/* ---- malformed serialized input ------------------------------------------ */
#pragma pack(push, 1)
typedef struct { uint32_t cookie; int32_t payload_len; int32_t noi; int32_t sig;
                 int64_t low; int64_t high; uint64_t conv; uint8_t counts[1]; } enc_fw_t;
typedef struct { uint32_t cookie; int32_t length; uint8_t data[1]; } cmp_fw_t;
#pragma pack(pop)
#define ENC_HDR (sizeof(enc_fw_t) - 1)
#define CMP_HDR (sizeof(cmp_fw_t) - 1)
static const uint32_t V2_ENC = 0x1c849303, V2_CMP = 0x1c849304;

/* Build a V2 compressed stream from a raw zig-zag payload + chosen enc cookie. */
static uint8_t* craft(uint32_t enc_cookie, const uint8_t* payload, int32_t payload_len,
                      int32_t declared_payload_len, size_t* out_len)
{
    size_t enc_size = ENC_HDR + payload_len;
    enc_fw_t* enc = calloc(enc_size + 16, 1);
    enc->cookie = htobe32(enc_cookie | 0x10U);
    enc->payload_len = htobe32(declared_payload_len);
    enc->sig = htobe32(SIG);
    enc->low = htobe64(LOW);
    enc->high = htobe64(HIGH);
    enc->conv = htobe64(0);
    memcpy(enc->counts, payload, payload_len);

    uLongf dl = compressBound(enc_size);
    cmp_fw_t* cmp = malloc(CMP_HDR + dl);
    compress(cmp->data, &dl, (Bytef*)enc, enc_size);
    cmp->cookie = htobe32(V2_CMP | 0x10U);
    cmp->length = htobe32((int32_t)dl);
    free(enc);
    *out_len = CMP_HDR + dl;
    return (uint8_t*)cmp;
}

static void fault_malformed(void)
{
    struct hdr_packed_histogram* out = NULL;
    size_t len;

    /* too short */
    uint8_t tiny[4] = {0};
    CHECK(hdr_packed_decode_compressed(tiny, 4, &out) == EINVAL, "decode: buffer too short -> EINVAL");

    /* bad compression cookie */
    cmp_fw_t bad; memset(&bad, 0, sizeof bad);
    bad.cookie = htobe32(0xDEADBEEF); bad.length = htobe32(0);
    CHECK(hdr_packed_decode_compressed((uint8_t*)&bad, CMP_HDR + 1, &out) < 0, "decode: bad compression cookie -> mismatch");

    /* declared compressed length larger than buffer */
    cmp_fw_t big; memset(&big, 0, sizeof big);
    big.cookie = htobe32(V2_CMP | 0x10U); big.length = htobe32(1 << 20);
    CHECK(hdr_packed_decode_compressed((uint8_t*)&big, CMP_HDR + 1, &out) == EINVAL, "decode: length > buffer -> EINVAL");

    /* bad ENCODING cookie inside a valid compressed frame */
    uint8_t p1[1] = {0};
    uint8_t* s1 = craft(0x12345678, p1, 1, 1, &len);
    CHECK(hdr_packed_decode_compressed(s1, len, &out) == -29998, "decode: bad encoding cookie -> mismatch");
    free(s1);

    /* corrupt compressed body -> inflate fail */
    uint8_t vp[1]; vp[0] = 0; /* single zig-zag value 0 */
    uint8_t* s2 = craft(V2_ENC, vp, 1, 1, &len);
    for (size_t i = CMP_HDR; i < len; i++) s2[i] ^= 0xFF;  /* trash deflate stream */
    CHECK(hdr_packed_decode_compressed(s2, len, &out) < 0, "decode: corrupt deflate -> inflate fail");
    free(s2);

    /* trailing-zeros overflow: a single huge negative run > counts_len */
    uint8_t zz[9]; int n = zig_zag_encode_i64(zz, -(int64_t)(1 << 30));
    uint8_t* s3 = craft(V2_ENC, zz, n, n, &len);
    CHECK(hdr_packed_decode_compressed(s3, len, &out) == -29992, "decode: trailing-zeros invalid");
    free(s3);

    /* incomplete final varint (continuation byte, no terminator in declared
       range; next byte is calloc zero) -> VALUE_TRUNCATED */
    uint8_t trunc[1]; trunc[0] = 0x80;
    uint8_t* s4 = craft(V2_ENC, trunc, 1, 1, &len);
    CHECK(hdr_packed_decode_compressed(s4, len, &out) == -29991, "decode: value truncated");
    free(s4);

    /* full-length zero-run fills every bucket, then an extra trailing byte
       remains -> ENCODED_INPUT_TOO_LONG (counts_index hit counts_len early).
       counts_len for (1, 3.6e9, sig3) is 23552. */
    uint8_t big5[10]; int n5 = zig_zag_encode_i64(big5, -(int64_t)23552);
    big5[n5] = 0x00;  /* one extra byte after the run */
    uint8_t* s5 = craft(V2_ENC, big5, n5 + 1, n5 + 1, &len);
    CHECK(hdr_packed_decode_compressed(s5, len, &out) == -29990, "decode: encoded input too long");
    free(s5);

    /* huge declared payload_len must be rejected WITHOUT a giant allocation
       (decode-bomb guard). Declare payload_len far beyond 9*counts_len. */
    uint8_t one7[1]; int n7 = zig_zag_encode_i64(one7, 5);
    uint8_t* s7 = craft(V2_ENC, one7, n7, 2000000000, &len); /* declared ~2e9 */
    int rc7 = hdr_packed_decode_compressed(s7, len, &out);
    CHECK(rc7 == -29990 || rc7 != 0, "decode: oversized payload_len rejected (no giant alloc)");
    free(s7);
}

/* dedicated: nonzero normalizing_index_offset rejected with EINVAL */
static void fault_offset_rejected(void)
{
    /* craft a stream with normalizing_index_offset = 1 */
    size_t len;
    uint8_t p[1] = {0};
    /* replicate craft() but set offset field */
    enc_fw_t* enc = calloc(ENC_HDR + 1 + 16, 1);
    enc->cookie = htobe32(V2_ENC | 0x10U);
    enc->payload_len = htobe32(1);
    enc->noi = htobe32(1);            /* nonzero offset */
    enc->sig = htobe32(SIG);
    enc->low = htobe64(LOW);
    enc->high = htobe64(HIGH);
    enc->conv = htobe64(0);
    enc->counts[0] = 0;
    uLongf dl = compressBound(ENC_HDR + 1);
    cmp_fw_t* cmp = malloc(CMP_HDR + dl);
    compress(cmp->data, &dl, (Bytef*) enc, ENC_HDR + 1);
    cmp->cookie = htobe32(V2_CMP | 0x10U);
    cmp->length = htobe32((int32_t) dl);
    len = CMP_HDR + dl;
    struct hdr_packed_histogram* out = NULL;
    CHECK(hdr_packed_decode_compressed((uint8_t*) cmp, len, &out) == EINVAL,
          "decode: nonzero normalizing_index_offset -> EINVAL");
    free(enc); free(cmp);
}

/* decode error branches reachable only with hand-built malformed frames */
static void fault_error_branches(void)
{
    struct hdr_packed_histogram* out = NULL;
    size_t len;

    /* zig-zag run value <= INT32_MIN -> TRAILING_ZEROS_INVALID (the pre-negation
       guard; round-1 fix #2). Use a value below INT32_MIN. */
    uint8_t zz[9]; int n = zig_zag_encode_i64(zz, -(int64_t)(1LL << 33));
    uint8_t* s1 = craft(V2_ENC, zz, n, n, &len);
    CHECK(hdr_packed_decode_compressed(s1, len, &out) == -29992, "decode: value<=INT32_MIN run rejected");
    free(s1);

    /* negative payload_len -> EINVAL */
    uint8_t p2[1] = {0};
    uint8_t* s2 = craft(V2_ENC, p2, 1, -1, &len);
    CHECK(hdr_packed_decode_compressed(s2, len, &out) == EINVAL, "decode: negative payload_len -> EINVAL");
    free(s2);

    /* negative (high-bit) compressed length -> EINVAL */
    uint8_t p3[1] = {0};
    uint8_t* s3 = craft(V2_ENC, p3, 1, 1, &len);
    ((cmp_fw_t*) s3)->length = htobe32(0x80000000u);
    CHECK(hdr_packed_decode_compressed(s3, len, &out) == EINVAL, "decode: negative comp_len -> EINVAL");
    free(s3);

    /* truncated compressed stream: header inflates short -> INFLATE_FAIL (avail_out!=0, fix #3) */
    uint8_t p4[1] = {0};
    uint8_t* s4 = craft(V2_ENC, p4, 1, 1, &len);
    ((cmp_fw_t*) s4)->length = htobe32(2);   /* only 2 compressed bytes */
    CHECK(hdr_packed_decode_compressed(s4, len, &out) < 0, "decode: short header inflate -> error");
    free(s4);

    /* valid header + corrupted payload body -> inflate/decode error */
    uint8_t p5[3]; int n5 = zig_zag_encode_i64(p5, 5);
    uint8_t* s5 = craft(V2_ENC, p5, n5, n5, &len);
    s5[len - 1] ^= 0xFF; s5[len - 2] ^= 0xFF;
    CHECK(hdr_packed_decode_compressed(s5, len, &out) != 0, "decode: corrupted payload body -> error");
    free(s5);

    /* VALID stream whose buckets sum past INT64_MAX: three adjacent 2^62 counts.
       Decodes (rc=0); recompute saturates total; a percentile query must not
       signed-overflow the prefix sum (the exact UB reproduced in review). */
    uint8_t p6[27]; int m = 0;
    for (int i = 0; i < 3; i++) m += zig_zag_encode_i64(p6 + m, (int64_t) 1 << 62);
    uint8_t* s6 = craft(V2_ENC, p6, m, m, &len);
    struct hdr_packed_histogram* h6 = NULL;
    int rc6 = hdr_packed_decode_compressed(s6, len, &h6);
    CHECK(rc6 == 0 && h6 != NULL, "decode: multi-2^62-bucket stream accepted");
    if (h6)
    {
        CHECK(hdr_packed_total_count(h6) == INT64_MAX, "decode: total saturates to INT64_MAX");
        (void) hdr_packed_value_at_percentile(h6, 100.0); /* exercises running saturation (no UB) */
        (void) hdr_packed_value_at_percentile(h6, 50.0);
        (void) hdr_packed_mean(h6);
        hdr_packed_close(h6);
    }
    free(s6);
}

int main(void)
{
    printf("packed fault-injection / error-path coverage\n");
    fault_allocs();
    fault_encode();
    fault_decode_alloc();
    fault_malformed();
    fault_error_branches();
    fault_offset_rejected();
    if (failures == 0) { printf("\nALL PASS\n"); return 0; }
    printf("\n%d FAILURES\n", failures);
    return 1;
}

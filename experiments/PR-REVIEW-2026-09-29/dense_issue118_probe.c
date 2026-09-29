/* Issue #118 reproduction; released to the public domain under CC0. */
#include <hdr/hdr_histogram.h>
#include "hdr_endian.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>
#define LOW 1
#define HIGH 3600000000LL
#define SIG 3
extern int zig_zag_encode_i64(uint8_t*, int64_t);
extern int hdr_decode_compressed(uint8_t*, size_t, struct hdr_histogram**);
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

int main(void)
{
    uint8_t payload[27];
    int used = 0;
    size_t len = 0;
    for (int i = 0; i < 3; i++)
        used += zig_zag_encode_i64(payload + used, (int64_t)(UINT64_C(1) << 62));
    uint8_t* stream = craft(V2_ENC, payload, used, used, &len);
    struct hdr_histogram* h = NULL;
    int rc = hdr_decode_compressed(stream, len, &h);
    printf("decode result %d\n", rc);
    hdr_close(h);
    free(stream);
    return 0;
}

/* Structured decoder offset fuzzer. Released to the public domain. */
#include <hdr/hdr_histogram.h>
#include <hdr/hdr_histogram_log.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <zlib.h>

int hdr_decode_compressed(uint8_t* buffer, size_t length, struct hdr_histogram** histogram);

static void be32(uint8_t* dst, uint32_t x)
{
    dst[0] = (uint8_t)(x >> 24U); dst[1] = (uint8_t)(x >> 16U);
    dst[2] = (uint8_t)(x >> 8U); dst[3] = (uint8_t)x;
}

int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size)
{
    if (size < 5) return 0;
    uint32_t u = ((uint32_t)data[0] << 24U) | ((uint32_t)data[1] << 16U) |
        ((uint32_t)data[2] << 8U) | data[3];
    int32_t offset = (int32_t)u;
    int v1 = data[4] & 1;
    uint8_t raw[42] = {0}, compressed[256] = {0};
    uLongf length = sizeof(compressed) - 8;
    be32(raw, v1 ? 0x1c849321U : 0x1c849313U);
    be32(raw + 4, v1 ? 2 : 1); be32(raw + 8, u);
    be32(raw + 12, 1 + data[4] % 3);
    be32(raw + 20, 1); be32(raw + 28, 1000000);
    be32(raw + 32, 0x3ff00000U); raw[40] = v1 ? 0 : 2; raw[41] = 1;
    if (compress(compressed + 8, &length, raw, v1 ? 42 : 41) != Z_OK) abort();
    be32(compressed, v1 ? 0x1c849322U : 0x1c849314U);
    be32(compressed + 4, (uint32_t)length);
    struct hdr_histogram* h = NULL;
    if (hdr_decode_compressed(compressed, length + 8, &h) != 0) abort();
    if (h->normalizing_index_offset != offset % h->counts_len) abort();
    int32_t logical = offset % h->counts_len;
    if (logical < 0) logical += h->counts_len;
    int64_t value = hdr_value_at_index(h, logical);
    if (hdr_count_at_index(h, logical) != 1 || hdr_value_at_percentile(h, 100.0) !=
        hdr_next_non_equivalent_value(h, value) - 1) abort();
    hdr_close(h);
    return 0;
}

#ifdef STANDALONE
int main(void)
{
    uint32_t state = 0x6a09e667U;
    for (int i = 0; i < 50000; i++)
    {
        uint8_t input[5];
        for (size_t j = 0; j < sizeof(input); j++)
        {
            state ^= state << 13U; state ^= state >> 17U; state ^= state << 5U;
            input[j] = (uint8_t)state;
        }
        LLVMFuzzerTestOneInput(input, sizeof(input));
    }
    puts("PASS: 50000 structured V1/V2 offset cases; seed=0x6a09e667");
    return 0;
}
#endif

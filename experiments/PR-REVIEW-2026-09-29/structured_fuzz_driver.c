/* Deterministic structured fuzz replay; this is not coverage-guided fuzzing.
 * Released to the public domain.
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
int LLVMFuzzerTestOneInput(const uint8_t*, size_t);
int main(int argc, char** argv)
{
    uint64_t state = UINT64_C(0x29102026);
    uint8_t data[4096];
    unsigned cases = argc > 1 ? (unsigned) strtoul(argv[1], NULL, 10) : 10000;
    for (unsigned i = 0; i < cases; i++)
    {
        size_t size = i % sizeof(data);
        for (size_t j = 0; j < size; j++)
        {
            state ^= state << 13;
            state ^= state >> 7;
            state ^= state << 17;
            data[j] = (uint8_t) state;
        }
        LLVMFuzzerTestOneInput(data, size);
    }
    printf("PASS %u deterministic cases, seed 0x29102026\n", cases);
    return 0;
}

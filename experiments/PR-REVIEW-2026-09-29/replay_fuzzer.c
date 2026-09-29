/* Released to the public domain under CC0. Replay exact inputs without libFuzzer. */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

int LLVMFuzzerTestOneInput(const uint8_t *, size_t);

int main(int argc, char **argv)
{
    for (int i = 1; i < argc; i++)
    {
        FILE *f = fopen(argv[i], "rb");
        if (!f) return 2;
        if (fseek(f, 0, SEEK_END)) return 2;
        long length = ftell(f);
        if (length < 0 || length > 4 * 1024 * 1024) return 2;
        rewind(f);
        uint8_t *data = malloc((size_t)length + 1);
        if (!data) return 2;
        if (fread(data, 1, (size_t)length, f) != (size_t)length) return 2;
        fclose(f);
        LLVMFuzzerTestOneInput(data, (size_t)length);
        free(data);
        printf("replayed input %d (%ld bytes)\n", i, length);
    }
    return 0;
}

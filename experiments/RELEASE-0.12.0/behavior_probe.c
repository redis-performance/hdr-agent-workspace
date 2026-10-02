/* Prints observable behaviours that differ between 0.11.10 and 0.12.0. Public domain.
 * Only calls functions that exist in both versions. Run each build with the same input file. */
#include <errno.h>
#include <inttypes.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <hdr/hdr_histogram.h>
#include <hdr/hdr_histogram_log.h>
#include <hdr/hdr_time.h>

/* Declared in the private src/hdr_tests.h, exported by the library; used here to feed a raw compressed blob. */
int hdr_decode_compressed(uint8_t* buffer, size_t length, struct hdr_histogram** histogram);

int main(int argc, char** argv)
{
    struct hdr_histogram* h = NULL;
    hdr_timespec ts;
    int rc;

    hdr_init(1, 1000000, 3, &h);
    hdr_record_values(h, 100, 5);
    {
        bool accepted = hdr_record_values(h, 100, -1);   /* sequenced: C leaves argument order unspecified */
        printf("hdr_record_values(count=-1)            -> %s, total_count %" PRId64 " (was 5)\n",
               accepted ? "true " : "false", h->total_count);
    }
    hdr_close(h);

    ts.tv_sec = 7; ts.tv_nsec = 7;
    hdr_timespec_from_double(&ts, NAN);
    printf("hdr_timespec_from_double(NaN)          -> tv_sec=%ld tv_nsec=%ld\n", (long) ts.tv_sec, (long) ts.tv_nsec);
    ts.tv_sec = 7; ts.tv_nsec = 7;
    hdr_timespec_from_double(&ts, 0.9996);
    printf("hdr_timespec_from_double(0.9996)       -> tv_sec=%ld tv_nsec=%ld (tv_nsec must be < 1e9)\n", (long) ts.tv_sec, (long) ts.tv_nsec);

    if (argc > 1)
    {
        unsigned char buf[4096];
        FILE* f = fopen(argv[1], "rb");
        size_t n = f ? fread(buf, 1, sizeof buf, f) : 0;
        struct hdr_histogram* d = NULL;
        if (f) fclose(f);
        rc = hdr_decode_compressed(buf, n, &d);
        printf("decode of a log with a negative count  -> rc=%d%s%s\n", rc, rc == 0 ? " (accepted)" : " (rejected)",
               d ? ", histogram returned" : ", no histogram");
        if (d) hdr_close(d);
    }
    return 0;
}

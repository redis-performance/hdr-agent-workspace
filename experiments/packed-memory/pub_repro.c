#include <stdio.h>
#include <stdint.h>
#include "hdr_packed_histogram.h"
int main(void){
    struct hdr_packed_histogram* h = NULL;
    hdr_packed_init(1, 3600000000LL, 3, &h);         /* 1us..1h, 3 sig figs */
    /* 2^53 samples near 1ms, then ONE sample at ~1 hour */
    hdr_packed_record_values(h, 1000, (1LL<<53));    /* bulk low bucket */
    hdr_packed_record_value(h, 3600000000LL);        /* one max sample */
    printf("total_count = %lld\n", (long long)hdr_packed_total_count(h));
    printf("max         = %lld  (true max bucket top)\n", (long long)hdr_packed_max(h));
    printf("p100        = %lld  <-- should equal max\n", (long long)hdr_packed_value_at_percentile(h,100.0));
    printf("p99.9999    = %lld\n", (long long)hdr_packed_value_at_percentile(h,99.9999));
    hdr_packed_close(h);
    return 0;
}

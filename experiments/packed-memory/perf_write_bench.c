#define _POSIX_C_SOURCE 199309L
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include "hdr/hdr_histogram.h"
#include "hdr_packed_histogram.h"
static uint64_t rs=99;
static uint64_t xr(void){ rs^=rs<<13; rs^=rs>>7; rs^=rs<<17; return rs; }
static double now_ns(void){ struct timespec t; clock_gettime(CLOCK_MONOTONIC,&t); return t.tv_sec*1e9+t.tv_nsec; }
static int64_t samp(double spread){ double u=(double)(xr()%1000000)/1e6; double v=200.0*exp(spread*u); if(v>1e9)v=1e9; if(v<1)v=1; return (int64_t)v; }
static void bench(const char* label,double spread){
    struct hdr_packed_histogram* p=NULL; hdr_packed_init(1,1000000000L,2,&p);
    rs=99; for(int i=0;i<500000;i++) hdr_packed_record_value(p,samp(spread)); /* populate all buckets (steady state) */
    int D=hdr_packed_populated(p);
    const int N=8000000;
    /* precompute samples to remove RNG from timed loop */
    int64_t* s=malloc(sizeof(int64_t)*N); rs=12345; for(int i=0;i<N;i++) s[i]=samp(spread);
    volatile int r=0;
    double t=now_ns(); for(int i=0;i<N;i++) r+=hdr_packed_record_value(p,s[i]); double ns=(now_ns()-t)/N;
    printf("  %-9s D=%-4d | record(hit) = %5.1f ns/op\n",label,D,ns);
    free(s); hdr_packed_close(p);
}
int main(void){ printf("PACKED write path (config 1,1e9,2), steady-state hits:\n"); bench("tight",1.2); bench("moderate",2.2); bench("wide",3.2); return 0; }

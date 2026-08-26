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
static const double PCTS[3]={50.0,99.0,99.9};
static void bench(const char* label,double spread){
    struct hdr_packed_histogram* p=NULL; hdr_packed_init(1,1000000000L,2,&p);
    rs=99; for(int i=0;i<500000;i++){ double u=(double)(xr()%1000000)/1e6; double v=200.0*exp(spread*u); if(v>1e9)v=1e9; if(v<1)v=1; hdr_packed_record_value(p,(int64_t)v);}
    int D=hdr_packed_populated(p); const int Q=300000; volatile int64_t sink=0; int64_t out[3];
    double t=now_ns(); for(int i=0;i<Q;i++) sink+=hdr_packed_value_at_percentile(p,PCTS[i%3]); double sg=(now_ns()-t)/Q;
    t=now_ns(); for(int i=0;i<Q;i++){ hdr_packed_value_at_percentiles(p,PCTS,out,3); sink+=out[0]; } double pl=(now_ns()-t)/Q;
    printf("  %-9s D=%-4d | single=%6.1f ns | plural3=%6.1f ns\n",label,D,sg,pl);
}
int main(void){ printf("PACKED read path (config 1,1e9,2):\n"); bench("tight",1.2); bench("moderate",2.2); bench("wide",3.2); return 0; }

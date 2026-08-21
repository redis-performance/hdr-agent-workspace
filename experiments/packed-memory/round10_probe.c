#define _DEFAULT_SOURCE 1
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <zlib.h>
#include "hdr_packed_histogram.c"

extern int  hdr_init(int64_t,int64_t,int,struct hdr_histogram**);
extern void hdr_close(struct hdr_histogram*);
extern bool hdr_record_values(struct hdr_histogram*,int64_t,int64_t);
extern int  hdr_encode_compressed(struct hdr_histogram*,uint8_t**,size_t*);
extern int  hdr_decode_compressed(uint8_t*,size_t,struct hdr_histogram**);
extern int64_t hdr_min(const struct hdr_histogram*);
extern int64_t hdr_max(const struct hdr_histogram*);

int main(void){
    int64_t low=1, high=INT64_MAX; int sig=3;

    /* --- Probe 1: lone INT64_MAX min, packed vs dense at RECORD and DECODE --- */
    struct hdr_packed_histogram* p; hdr_packed_init(low,high,sig,&p);
    struct hdr_histogram* d; hdr_init(low,high,sig,&d);
    hdr_packed_record_values(p, INT64_MAX, 1);
    hdr_record_values(d, INT64_MAX, 1);
    printf("RECORD lone INT64_MAX:\n");
    printf("  packed min=%lld max=%lld\n",(long long)hdr_packed_min(p),(long long)hdr_packed_max(p));
    printf("  dense  min=%lld max=%lld\n",(long long)hdr_min(d),(long long)hdr_max(d));
    printf("  RECORD-STAGE parity min:%s max:%s\n",
        hdr_packed_min(p)==hdr_min(d)?"OK":"DIVERGE",
        hdr_packed_max(p)==hdr_max(d)?"OK":"DIVERGE");

    /* encode both, decode both, compare at DECODE stage */
    uint8_t* pc=NULL; size_t pcl=0; hdr_packed_encode_compressed(p,&pc,&pcl);
    uint8_t* dc=NULL; size_t dcl=0; hdr_encode_compressed(d,&dc,&dcl);
    struct hdr_packed_histogram* pp=NULL; hdr_packed_decode_compressed(pc,pcl,&pp);
    struct hdr_histogram* dd=NULL; hdr_decode_compressed(dc,dcl,&dd);
    printf("DECODE lone INT64_MAX:\n");
    printf("  packed min=%lld max=%lld\n",(long long)hdr_packed_min(pp),(long long)hdr_packed_max(pp));
    printf("  dense  min=%lld max=%lld\n",(long long)hdr_min(dd),(long long)hdr_max(dd));
    printf("  DECODE-STAGE parity min:%s max:%s\n",
        hdr_packed_min(pp)==hdr_min(dd)?"OK":"DIVERGE",
        hdr_packed_max(pp)==hdr_max(dd)?"OK":"DIVERGE");
    free(pc); free(dc);
    hdr_packed_close(p); hdr_close(d); hdr_packed_close(pp); hdr_close(dd);

    /* Also a normal (non-sentinel) value to confirm min parity there */
    struct hdr_packed_histogram* p2; hdr_packed_init(low,high,sig,&p2);
    struct hdr_histogram* d2; hdr_init(low,high,sig,&d2);
    hdr_packed_record_values(p2, INT64_MAX/2, 1);
    hdr_record_values(d2, INT64_MAX/2, 1);
    printf("RECORD lone INT64_MAX/2: packed min=%lld dense min=%lld  %s\n",
        (long long)hdr_packed_min(p2),(long long)hdr_min(d2),
        hdr_packed_min(p2)==hdr_min(d2)?"OK":"DIVERGE");
    hdr_packed_close(p2); hdr_close(d2);

    /* --- Probe 2: payload_len larger than actual inflated bytes.
           Does DENSE accept or reject? --- */
    printf("\nPayload-len-too-big leniency:\n");
    struct hdr_packed_histogram* h; hdr_packed_init(1,100000,3,&h);
    int64_t v[]={0,100,1000,50000,99999}, c[]={5,3,7,1,9};
    for(int i=0;i<5;i++) hdr_packed_record_values(h,v[i],c[i]);
    /* get payload */
    uint8_t* hc=NULL; size_t hcl=0; hdr_packed_encode_compressed(h,&hc,&hcl);
    static uint8_t pay[1<<16];
    { z_stream s; memset(&s,0,sizeof s); inflateInit(&s);
      pk_compression_flyweight_t* cf=(pk_compression_flyweight_t*)hc;
      s.next_in=cf->data; s.avail_in=be32toh(cf->length);
      s.next_out=pay; s.avail_out=sizeof pay; inflate(&s,Z_FINISH);
      long pn=sizeof pay - s.avail_out; inflateEnd(&s);
      pk_encoding_flyweight_t* e=(pk_encoding_flyweight_t*)pay;
      int32_t orig_pl = be32toh(e->payload_len);
      e->payload_len = htobe32(orig_pl + 100);   /* claim 100 more bytes */
      /* recompress the ORIGINAL pn bytes (real payload shorter than claim) */
      uLongf dl=compressBound(pn);
      pk_compression_flyweight_t* out=malloc(PK_SIZEOF_CMP+dl);
      compress(out->data,&dl,pay,pn);
      out->cookie=htobe32(PK_V2_COMPRESSION_COOKIE|0x10U);
      out->length=htobe32((int32_t)dl);
      size_t olen=PK_SIZEOF_CMP+dl;
      uint8_t* cpk=malloc(olen); memcpy(cpk,out,olen);
      uint8_t* cdn=malloc(olen); memcpy(cdn,out,olen);
      struct hdr_packed_histogram* rp=NULL; int prc=hdr_packed_decode_compressed(cpk,olen,&rp);
      struct hdr_histogram* rd=NULL; int drc=hdr_decode_compressed(cdn,olen,&rd);
      printf("  packed rc=%d (%s)  dense rc=%d (%s)\n",
             prc, prc==0?"ACCEPT":"reject", drc, drc==0?"ACCEPT":"reject");
      if(prc==0){ printf("  packed decoded total=%lld pop=%d\n",
             (long long)hdr_packed_total_count(rp), hdr_packed_populated(rp)); }
      printf("  orig total=%lld\n",(long long)hdr_packed_total_count(h));
      if(rp) hdr_packed_close(rp); if(rd) hdr_close(rd);
      free(out); free(cpk); free(cdn);
    }
    free(hc); hdr_packed_close(h);
    return 0;
}

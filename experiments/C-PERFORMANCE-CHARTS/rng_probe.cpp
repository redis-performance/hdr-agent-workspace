/* Supplemental diagnostic: does the C++ default engine change this batch
 * benchmark's histogram shape or timing? The project benchmark is untouched.
 */
#include <hdr/hdr_histogram.h>
#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <cstdint>
#include <cstdio>
#include <random>
#include <type_traits>
#include <vector>

static volatile int64_t sink;

template <class Engine> void run(const char* name) {
    Engine generator;
    std::gamma_distribution<double> distribution(1.0, 100000.0);
    hdr_histogram* h = nullptr;
    if (hdr_init(1, 86400000, 3, &h) != 0) std::abort();
    uint64_t input_hash = UINT64_C(1469598103934665603);
    for (int64_t i=1; i<10000000; i++) {
        int64_t value = (int64_t)distribution(generator)+1;
        value = std::min<int64_t>(value,86400000);
        if (i<=10000) {input_hash ^= (uint64_t)value; input_hash *= UINT64_C(1099511628211);}
        if (!hdr_record_value(h,value)) std::abort();
    }
    const double pcts[4]={50.0,95.0,99.0,99.9};
    int64_t out[4];
    if (hdr_value_at_percentiles(h,pcts,out,4)!=0) std::abort();
    int populated=0;
    for(int i=0;i<h->counts_len;i++) populated += h->counts[i]!=0;
    printf("%s input_hash=%llu populated=%d len=%d outputs=%lld,%lld,%lld,%lld\n",name,(unsigned long long)input_hash,populated,h->counts_len,(long long)out[0],(long long)out[1],(long long)out[2],(long long)out[3]);
    std::vector<double> samples;
    for(int rep=0;rep<5;rep++) {
      auto start=std::chrono::steady_clock::now();
      for(int i=0;i<300000;i++) {if(hdr_value_at_percentiles(h,pcts,out,4)!=0) std::abort(); sink += out[i&3];}
      auto end=std::chrono::steady_clock::now();
      samples.push_back(std::chrono::duration<double,std::nano>(end-start).count()/300000.0);
    }
    std::sort(samples.begin(),samples.end());
    printf("%s batch_ns_median=%.2f batch_ns_range=%.2f..%.2f\n",name,samples[2],samples[0],samples[4]);
    hdr_close(h);
}
int main(){
    printf("default_is_minstd_rand=%d default_is_minstd_rand0=%d\n",
        (int)std::is_same<std::default_random_engine,std::minstd_rand>::value,
        (int)std::is_same<std::default_random_engine,std::minstd_rand0>::value);
    run<std::minstd_rand>("minstd_rand");
    run<std::minstd_rand0>("minstd_rand0");
    printf("sink=%lld\n",(long long)sink);
}

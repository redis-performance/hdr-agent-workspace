#!/bin/bash
# Run on a fleet VM:  ssh HOST 'A=0.12.0 B=<sha-or-tag> bash -s' < scripts/fleet-c-bench.sh
# Builds HdrHistogram_c at refs A (baseline) and B (gcc Release, as CI), runs the correctness suite for each, then times
#   write  : hdr_histogram_perf   (immutable driver, ops/sec)
#   read   : hdr_percentile_bench (immutable driver, M queries/sec)
#   batch  : out-of-tree bench_batch.c below (hdr_value_at_percentiles, 4 percentiles; ns/call), plus the same 4 percentiles as single calls
# pinned to CPU 2 in order A B B A repeated BLOCKS times, after an idle check before every run. Detaches; poll $OUT/DONE, read $OUT/summary.txt.
# Only files under ~/hdrfuzz. Needs git, cmake, gcc, python3 (already on the fleet VMs).
set -eu
A=${A:-0.12.0}; B=${B:-main}; BLOCKS=${BLOCKS:-3}; CPU=${CPU:-2}
OUT=$HOME/hdrfuzz/cbench-$(date -u +%Y%m%dT%H%M%SZ); mkdir -p "$OUT/bin" "$OUT/raw"
git clone -q https://github.com/HdrHistogram/HdrHistogram_c "$OUT/src"
cat > "$OUT/bench_batch.c" <<'CSRC'
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>
#include <hdr/hdr_histogram.h>
static uint64_t s = 88172645463325252ULL;
static double rnd(void) { s ^= s << 13; s ^= s >> 7; s ^= s << 17; return (s >> 11) * (1.0 / 9007199254740992.0); }
static double now(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return t.tv_sec * 1e9 + t.tv_nsec; }
int main(void) {
    struct hdr_histogram *h = NULL;
    if (hdr_init(1, 3600000000LL, 3, &h)) return 1;
    for (int i = 0; i < 1000000; i++) {
        double g = sqrt(-2.0 * log(rnd() + 1e-12)) * cos(6.283185307179586 * rnd());
        hdr_record_value(h, (int64_t)(10000.0 * exp(0.6 * g)) + 1);
    }
    const double p[4] = {50.0, 90.0, 99.0, 99.9};
    int64_t out[4]; volatile int64_t sink = 0; double bestb = 1e30, bests = 1e30;
    for (int rep = 0; rep < 7; rep++) {
        double t0 = now();
        for (int i = 0; i < 20000; i++) { hdr_value_at_percentiles(h, p, out, 4); sink += out[i & 3]; }
        double tb = (now() - t0) / 20000; if (tb < bestb) bestb = tb;
        t0 = now();
        for (int i = 0; i < 20000; i++) { for (int k = 0; k < 4; k++) sink += hdr_value_at_percentile(h, p[k]); }
        double ts = (now() - t0) / 20000; if (ts < bests) bests = ts;
    }
    printf("BATCH_NS %.1f SINGLE4_NS %.1f\n", bestb, bests);
    hdr_close(h); return (int)(sink == 0x7fffffff);
}
CSRC
cd "$OUT/src"
for r in A B; do
  ref=${!r}; git checkout -q "$ref"; echo "$r=$ref $(git rev-parse HEAD)" >> "$OUT/refs"
  rm -rf "$OUT/build-$r"; cmake -S . -B "$OUT/build-$r" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc > "$OUT/cfg-$r.log" 2>&1
  cmake --build "$OUT/build-$r" -j8 > "$OUT/build-$r.log" 2>&1
  { echo "== $r=$ref"; (cd "$OUT/build-$r" && ctest -j4 2>&1 | tail -3); } >> "$OUT/tests.txt"
  cp "$OUT/build-$r/test/hdr_histogram_perf" "$OUT/bin/perf_$r"
  gcc -O3 -DNDEBUG -std=gnu99 -Iinclude test/hdr_percentile_bench.c "$OUT/build-$r/src/libhdr_histogram_static.a" -lm -lz -lpthread -o "$OUT/bin/read_$r"
  gcc -O2 -std=gnu99 -Iinclude "$OUT/bench_batch.c" "$OUT/build-$r/src/libhdr_histogram_static.a" -lm -lz -lpthread -o "$OUT/bin/batch_$r"
done
{ echo "arch: $(uname -m)"; grep -m1 'model name' /proc/cpuinfo || lscpu | grep -m1 'Model name'; echo "cores: $(nproc)"; gcc --version | head -1
  echo "governor: $(cat /sys/devices/system/cpu/cpu$CPU/cpufreq/scaling_governor 2>/dev/null || echo n/a)"; echo "pinned cpu: $CPU, blocks=$BLOCKS (A B B A each)"; } > "$OUT/meta"
cat > "$OUT/summarize.py" <<'PY'
import re,sys,statistics as st,collections,glob
d=collections.defaultdict(list)
for f in glob.glob(sys.argv[1]+"/raw/*.txt"):
    n=f.split("/")[-1][:-4]; kind,v=n.split("_")[1],n.split("_")[2]; t=open(f).read()
    if kind=="perf":
        xs=[float(x.replace(",","")) for x in re.findall(r"ops/sec: ([\d,\.]+)",t)]
        if xs: d[("write ops/s (higher better)",v)].append(st.median(xs))
    elif kind=="read":
        m=re.search(r"best: ([\d.]+) M queries/sec",t)
        if m: d[("read M q/s (higher better)",v)].append(float(m.group(1)))
    elif kind=="batch":
        m=re.search(r"BATCH_NS ([\d.]+) SINGLE4_NS ([\d.]+)",t)
        if m: d[("batch ns/call, 4 pct (lower better)",v)].append(float(m.group(1))); d[("same 4 pct as single calls, ns (lower better)",v)].append(float(m.group(2)))
print("%-48s %14s %14s %9s  spread A | B"%("metric","A","B","B/A"))
for k in sorted({k[0] for k in d}):
    a,b=d.get((k,"A")),d.get((k,"B"))
    if not(a and b): continue
    sp=lambda x:"%.1f%%"%(100*(max(x)-min(x))/st.median(x))
    print("%-48s %14.2f %14.2f %8.3fx  %s | %s  (n=%d|%d)"%(k,st.median(a),st.median(b),st.median(b)/st.median(a),sp(a),sp(b),len(a),len(b)))
PY
cat > "$OUT/run.sh" <<RUN
set -u
cd "$OUT"
idle(){ for i in \$(seq 1 120); do
  read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat; sleep 3; read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
  t=\$(( (u2+n2+s2+i2+w2+q2+sq2)-(u1+n1+s1+i1+w1+q1+sq1) )); idl=\$(( (i2+w2)-(i1+w1) ))
  [ \$(( (t-idl)*100 )) -le \$(( t*8 )) ] && return 0; sleep 5; done; return 1; }
n=0
for blk in \$(seq 1 $BLOCKS); do for r in A B B A; do n=\$((n+1))
  for kind in perf read batch; do
    idle || { echo "not idle, abort before \$n\$r \$kind" >> notes; exit 1; }
    taskset -c $CPU ./bin/\${kind}_\$r > raw/\${n}_\${kind}_\${r}.txt 2>&1
    echo "\$n \$kind \$r exit \$?" >> notes
  done
done; done
python3 summarize.py "$OUT" > summary.txt; touch DONE
RUN
setsid nohup bash "$OUT/run.sh" > "$OUT/run.log" 2>&1 < /dev/null &
sleep 1; cat "$OUT/refs" "$OUT/meta" "$OUT/tests.txt"; echo "OUT=$OUT"

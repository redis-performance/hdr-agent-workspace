#!/bin/bash
# Run on a fleet VM:  ssh HOST 'A=v1.3.0 B=1608007 bash -s' < scripts/fleet-go-bench.sh
# Builds hdrhistogram-go test binaries at refs A (baseline) and B, then runs every Benchmark* of each pinned to CPU 2
# in order A B B A A B B A (COUNT repetitions each), after an idle check. Detaches; poll $OUT/DONE and read $OUT/summary.txt.
# Only user-directory files under ~/hdrfuzz. Needs nothing installed (reuses or fetches a Go toolchain).
set -eu
A=${A:-v1.3.0}; B=${B:-1608007}; COUNT=${COUNT:-5}; CPU=${CPU:-2}; BENCH=${BENCH:-.}; FORK=${FORK:-}   # FORK=https://github.com/USER/hdrhistogram-go to fetch branch refs from a fork
case "$(uname -m)" in x86_64) GA=amd64;; aarch64) GA=arm64;; *) echo unsupported arch; exit 1;; esac
mkdir -p ~/hdrfuzz && cd ~/hdrfuzz
if [ ! -x gotool/go/bin/go ]; then
  V=$(curl -fsS 'https://go.dev/VERSION?m=text' | head -1)
  curl -fsSL "https://go.dev/dl/$V.linux-$GA.tar.gz" -o go.tgz && mkdir -p gotool && tar -C gotool -xzf go.tgz && rm go.tgz
fi
export PATH=$HOME/hdrfuzz/gotool/go/bin:$PATH GOTOOLCHAIN=local
OUT=$HOME/hdrfuzz/bench-$(date -u +%Y%m%dT%H%M%SZ); mkdir -p "$OUT/bin" "$OUT/raw"
export GOCACHE=$OUT/gocache GOPATH=$OUT/gopath
git clone -q https://github.com/HdrHistogram/hdrhistogram-go "$OUT/src" && cd "$OUT/src"
[ -n "$FORK" ] && git remote add fork "$FORK" && git fetch -q fork
for r in A B; do ref=${!r}; git checkout -q "$ref" 2>/dev/null || git checkout -q "fork/$ref"; echo "$r=$ref $(git rev-parse HEAD)" >> "$OUT/refs"; { echo "== $r=$ref"; gofmt -l . ; go vet . 2>&1 | tail -3; go test -count=1 -timeout 20m . 2>&1 | tail -3; } >> "$OUT/tests.txt"; go test -c -o "$OUT/bin/$r.test" . ; done
{ echo "arch: $(uname -m)"; grep -m1 'model name' /proc/cpuinfo || lscpu | grep -m1 'Model name'; echo "cores: $(nproc)"; go version
  echo "governor: $(cat /sys/devices/system/cpu/cpu$CPU/cpufreq/scaling_governor 2>/dev/null || echo n/a)"; echo "pinned cpu: $CPU, GOMAXPROCS=1, count=$COUNT"; } > "$OUT/meta"
cat > "$OUT/summarize.py" <<'PY'
import re,sys,statistics as st,collections,glob
d=collections.defaultdict(list)
for f in glob.glob(sys.argv[1]+"/raw/*.txt"):
    v=f.split("/")[-1].split("_")[1][0]
    for l in open(f):
        m=re.match(r"(Benchmark\S+?)(?:-\d+)?\s+\d+\s+([\d.]+) ns/op",l)
        if m: d[(m.group(1),v)].append(float(m.group(2)))
names=sorted({k[0] for k in d})
print("%-52s %12s %12s %9s  %s"%("benchmark","A ns/op","B ns/op","A/B","spread A | B (min-max/median)"))
for n in names:
    a,b=d.get((n,"A")),d.get((n,"B"))
    sp=lambda x:"%.1f%%"%(100*(max(x)-min(x))/st.median(x)) if x else "-"
    if a and b: print("%-52s %12.1f %12.1f %8.2fx  %s | %s"%(n,st.median(a),st.median(b),st.median(a)/st.median(b),sp(a),sp(b)))
    else: print("%-52s %12s %12s %9s"%(n,("%.1f"%st.median(a)) if a else "-",("%.1f"%st.median(b)) if b else "-","only "+("A" if a else "B")))
PY
cat > "$OUT/run.sh" <<RUN
set -u
cd "$OUT"; export PATH=$PATH GOTOOLCHAIN=local
idle(){ for i in \$(seq 1 120); do
  read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat; sleep 3; read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
  t=\$(( (u2+n2+s2+i2+w2+q2+sq2)-(u1+n1+s1+i1+w1+q1+sq1) )); idl=\$(( (i2+w2)-(i1+w1) ))
  [ \$(( (t-idl)*100 )) -le \$(( t*8 )) ] && return 0; sleep 5; done; return 1; }
n=0
for r in A B B A A B B A; do n=\$((n+1))
  idle || { echo "not idle, abort before \$n\$r" >> notes; exit 1; }
  taskset -c $CPU env GOMAXPROCS=1 ./bin/\$r.test -test.run='^\$' -test.bench='$BENCH' -test.benchmem -test.count=$COUNT -test.timeout=40m > raw/\${n}_\${r}.txt 2>&1
  echo "\$n \$r exit \$?" >> notes
done
python3 summarize.py "$OUT" > summary.txt; touch DONE
RUN
setsid nohup bash "$OUT/run.sh" > "$OUT/run.log" 2>&1 < /dev/null &
sleep 1; cat "$OUT/refs" "$OUT/meta"; echo "OUT=$OUT"

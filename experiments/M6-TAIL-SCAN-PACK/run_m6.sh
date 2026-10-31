#!/bin/bash
# Run on the Apple M6 (macOS, Apple clang). Usage:  scripts from this folder:  ./run_m6.sh [path/to/HdrHistogram_c clone with tag 0.12.1]
# 1) builds baseline 0.12.1, candidate A and candidate B from the patches in this folder
# 2) correctness: differential dump (ASan+UBSan) of every candidate against 0.12.1; stops on any diff outside the documented hostile cases
# 3) timing: bench_tail, ABBA x BLOCKS per candidate, QoS user-interactive via the repository shim (a scheduler request, not core pinning)
# 4) writes results/ (raw logs, machine.txt, summary.txt, summary.csv). Nothing is committed or pushed.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=${1:-$HERE/../../HdrHistogram_c}
BLOCKS=${BLOCKS:-3}
OUT=$HERE/results/$(date -u +%Y%m%dT%H%M%SZ); WORK=${TMPDIR:-/tmp}/m6-tail-$$
mkdir -p "$OUT/raw" "$WORK"
git -C "$SRC" rev-parse 0.12.1 >/dev/null
for v in base A B; do mkdir -p "$WORK/$v"; git -C "$SRC" archive 0.12.1 | tar -x -C "$WORK/$v"; done
(cd "$WORK/A" && patch -p1 < "$HERE/candidate-A-capped-tail-walk.patch")
(cd "$WORK/B" && patch -p1 < "$HERE/candidate-B-top-bucket-shortcut.patch")
for v in base A B; do
  clang -std=gnu99 -O2 -DNDEBUG ${EXTRA_CFLAGS:-} -I"$WORK/$v/include" -o "$WORK/bench_$v" "$HERE/bench_tail.c" "$WORK/$v/src/hdr_histogram.c" -lm
  clang -std=c99 -O1 -g -fsanitize=address,undefined -fno-sanitize-recover=undefined -I"$WORK/$v/include" -o "$WORK/dump_$v" "$HERE/tail_dump.c" "$WORK/$v/src/hdr_histogram.c" -lm
done
clang -dynamiclib -o "$WORK/qos.dylib" "$HERE/../C-M6-MASTER-2026-10-02/qos_interpose.c"
{ echo "machine: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || uname -m)"; echo "macos: $(sw_vers -productVersion)"; clang --version | head -1
  echo "base: 0.12.1 $(git -C "$SRC" rev-parse 0.12.1)"; echo "power: $(pmset -g batt | head -1)"; echo "blocks: $BLOCKS (ABBA per candidate)"; } > "$OUT/machine.txt"
echo "== correctness (differential vs 0.12.1, ASan+UBSan)"
"$WORK/dump_base" > "$WORK/out_base.txt"
for v in A B; do
  "$WORK/dump_$v" > "$WORK/out_$v.txt"
  bad=$(diff "$WORK/out_base.txt" "$WORK/out_$v.txt" | grep '^<' | awk '{print $2}' | grep -vc '^hostile[01]_' || true)
  echo "candidate $v: differing cases outside hostile0/1 = $bad"
  [ "$bad" = 0 ] || { echo "STOP: candidate $v differs from 0.12.1 on a valid histogram"; diff "$WORK/out_base.txt" "$WORK/out_$v.txt" | head; exit 1; }
done | tee "$OUT/correctness.txt"
echo "== timing (close other apps; keep on AC power; ~1-2 min per run)"
n=0
for cand in A B; do
  for blk in $(seq 1 "$BLOCKS"); do
    for r in base $cand $cand base; do
      n=$((n+1)); log="$OUT/raw/${n}_${cand}_${r}.txt"
      DYLD_INSERT_LIBRARIES="$WORK/qos.dylib" LC_ALL=C "$WORK/bench_$r" > "$log" 2>&1
      grep -q '^benchmark_qos requested=33 observed=33' "$log" || { echo "QoS check failed in $log"; exit 1; }
      echo "run $n $cand/$r done"
    done
  done
done
python3 "$HERE/summarize.py" "$OUT" | tee "$OUT/summary.txt"
echo "Results in $OUT  (send me summary.txt, summary.csv, machine.txt, correctness.txt)"
rm -rf "$WORK"

#!/usr/bin/env bash
# Measure line coverage of the added code (hdr_packed_histogram.c) across all
# packed test binaries. The UUT is instrumented once; each test binary links it
# and runs, accumulating .gcda. Prints per-line misses so we can drive to 100%.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
inc="$root/HdrHistogram_c/include"
lib="$root/HdrHistogram_c/build/gcc/src"
cc="${CC:-cc}"

# test files to run (default: all three); override by passing them as args
TESTS=("$@")
if [ ${#TESTS[@]} -eq 0 ]; then
  TESTS=("$here/packed_test.c" "$here/packed_fault_test.c")
fi

cov="$here/.cov"
rm -rf "$cov"; mkdir -p "$cov"

# UUT: instrumented, fault hooks enabled
"$cc" -O0 -g --coverage -DPACKED_FAULT_HOOKS -std=c99 -I"$inc" -I"$root/HdrHistogram_c/src" -I"$here" -I"$root/HdrHistogram_c/test" \
    -c "$here/hdr_packed_histogram.c" -o "$cov/hdr_packed_histogram.o"

for t in "${TESTS[@]}"; do
  [ -f "$t" ] || { echo "skip (missing): $t"; continue; }
  name="$(basename "$t" .c)"
  "$cc" -O0 -g -std=c99 -I"$inc" -I"$root/HdrHistogram_c/src" -I"$here" -I"$root/HdrHistogram_c/test" -c "$t" -o "$cov/$name.o"
  "$cc" --coverage "$cov/$name.o" "$cov/hdr_packed_histogram.o" \
      -L"$lib" -lhdr_histogram_static -lm -lz -o "$cov/$name"
  echo ">>> $name"
  ( cd "$cov" && "./$name" ) | tail -2
  echo
done

( cd "$cov" && gcov -b -o . hdr_packed_histogram.c >/dev/null 2>&1 || true )
report="$cov/hdr_packed_histogram.c.gcov"
[ -f "$report" ] || { echo "no gcov report produced"; exit 1; }

exec_lines=$(grep -cE '^\s*[0-9]+:\s*[0-9]+:' "$report" || true)
missed=$(grep -cE '^\s*#####:\s*[0-9]+:' "$report" || true)
# One reviewed defensive line is excluded from the REACHABLE denominator: a
# bounds guard that mirrors dense hdr_record_values and cannot be reached via the
# public API. It is tagged in-source with GCOV_EXCL_DEFENSIVE (auditable, capped).
excluded=$(grep -E '^\s*#####:\s*[0-9]+:' "$report" | grep -c 'GCOV_EXCL_DEFENSIVE' || true)
real_missed=$((missed - excluded))
denom=$((exec_lines + real_missed))
raw_denom=$((exec_lines + missed))
# branch coverage from gcov -b summary. Report "Taken at least once" (both
# directions exercised), NOT "Branches executed" (branch points merely reached).
gcov_summary=$(cd "$cov" && gcov -b -o . hdr_packed_histogram.c 2>/dev/null | grep -A4 "File .*hdr_packed_histogram.c")
branch_line=$(echo "$gcov_summary" | grep "Taken at least once" | head -1)
[ -z "$branch_line" ] && branch_line=$(echo "$gcov_summary" | grep "Branches" | head -1)
echo "=============================================================="
echo " Coverage of hdr_packed_histogram.c (added code)"
echo "=============================================================="
if [ "$raw_denom" -gt 0 ]; then
  printf " raw line coverage      : %d / %d  (%.2f%%)\n" "$exec_lines" "$raw_denom" \
    "$(echo "scale=4; 100*$exec_lines/$raw_denom" | bc)"
fi
if [ "$denom" -gt 0 ]; then
  printf " reachable line coverage: %d / %d  (%.2f%%)  [%d reviewed defensive line(s) excluded]\n" \
    "$exec_lines" "$denom" "$(echo "scale=4; 100*$exec_lines/$denom" | bc)" "$excluded"
fi
[ -n "$branch_line" ] && echo " branch coverage:$branch_line"
if [ "$excluded" -gt 2 ]; then
  echo " ERROR: more than 2 defensive exclusions ($excluded) — review required."; fi
echo
echo "--- UNCOVERED lines (excluding reviewed defensive) ---"
u=$(grep -nE '^\s*#####:\s*[0-9]+:' "$report" | grep -v 'GCOV_EXCL_DEFENSIVE' || true)
[ -z "$u" ] && echo "  (none)" || echo "$u" | sed 's/^/  /'
echo
echo "--- reviewed defensive line (excluded) ---"
grep -nE '^\s*#####:\s*[0-9]+:' "$report" | grep 'GCOV_EXCL_DEFENSIVE' | sed 's/^/  /' || echo "  (none)"
echo
echo "full annotated report: $report"

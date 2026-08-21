#!/usr/bin/env bash
# Build + run the packed-vs-dense memory microbench and the correctness gate
# against the existing static hdr library. Immutable drivers are untouched.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
inc="$root/HdrHistogram_c/include"
lib="$root/HdrHistogram_c/build/gcc/src"
cc="${CC:-cc}"

link=(-L"$lib" -lhdr_histogram_static -lm -lz)
mu="$root/HdrHistogram_c/test"

# 1) correctness gate (ASan+UBSan) -- must pass before any memory claim.
#    packed_test    : ported Java behavioral parity (minunit)
#    packed_validate: dense-vs-packed + serialization interop fuzz
#    packed_fault   : defensive/error-path coverage (needs -DPACKED_FAULT_HOOKS)
# -fno-sanitize-recover makes ANY UBSan finding abort (halt_on_error) so a
# logged-but-ignored UB (e.g. a bad-double->int64 cast) fails the gate.
asan=(-O1 -g -std=c99 -fsanitize=address,undefined,float-cast-overflow -fno-sanitize-recover=all -I"$inc" -I"$root/HdrHistogram_c/src" -I"$here" -I"$mu")
export UBSAN_OPTIONS=halt_on_error=1:abort_on_error=1
export ASAN_OPTIONS=abort_on_error=1
echo ">>> correctness gate (ASan+UBSan, halt-on-error)"
"$cc" "${asan[@]}" "$here/packed_test.c"     "$here/hdr_packed_histogram.c" "${link[@]}" -o "$here/packed_test"
"$cc" "${asan[@]}" "$here/packed_validate.c" "$here/hdr_packed_histogram.c" "${link[@]}" -o "$here/packed_validate"
"$cc" "${asan[@]}" -DPACKED_FAULT_HOOKS "$here/packed_fault_test.c" "$here/hdr_packed_histogram.c" "${link[@]}" -o "$here/packed_fault_test"
"$here/packed_test"
"$here/packed_validate" | tail -1
"$here/packed_fault_test" | tail -1
echo
echo ">>> coverage of added code"
"$here/coverage.sh" 2>/dev/null | grep -E "reachable line|branch coverage|defensive line" || true
echo

# 2) memory microbench (dense measured + model + measured packed)
"$cc" -O2 -std=c99 -I"$inc" -I"$root/HdrHistogram_c/src" -I"$here" \
    "$here/packed_mem_bench.c" "$here/hdr_packed_histogram.c" \
    "${link[@]}" -o "$here/packed_mem_bench"
echo "built: $here/packed_mem_bench"
echo

run() { echo ">>> N=$1 D=$2 low=$3 high=$4 sig=$5"; "$here/packed_mem_bench" "$@"; echo; }

# args: N D low high sigfig
run 100000 10   1 3600000000 3    # many histos, very sparse (packed's sweet spot)
run 100000 100  1 3600000000 3    # moderately populated
run 10000  1000 1 3600000000 3    # densely populated (packed should lose)

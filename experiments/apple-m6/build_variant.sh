#!/usr/bin/env bash
# Build and test one isolated source/flag configuration before measuring it.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "usage: build_variant.sh SOURCE BUILD_DIR [C_FLAGS]" >&2
  exit 1
fi
SOURCE="$1"
BUILD="$2"
FLAGS="${3:--O2 -g -DNDEBUG}"
CMAKE="$ROOT/.tools/bin/cmake"
"$CMAKE" -S "$SOURCE" -B "$BUILD" -DCMAKE_C_COMPILER=clang \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo "-DCMAKE_C_FLAGS_RELWITHDEBINFO=$FLAGS" \
  -DHDR_HISTOGRAM_BUILD_BENCHMARK=ON >/dev/null
"$CMAKE" --build "$BUILD" --target hdr_histogram_test hdr_histogram_atomic_test \
  hdr_histogram_log_test hdr_packed_histogram_test hdr_atomic_test \
  hdr_histogram_atomic_concurrency_test hdr_histogram_perf hdr_percentile_bench -j 6 >/dev/null
"$ROOT/.tools/bin/ctest" --test-dir "$BUILD" --output-on-failure
clang $FLAGS -Wall -Wextra -Werror -I "$SOURCE/include" \
  "$ROOT/experiments/apple-m6/bench.c" "$BUILD/src/libhdr_histogram_static.a" \
  -lz -lm -o "$BUILD/m6-bench"
shasum -a 256 "$ROOT/experiments/apple-m6/bench.c" | cut -d ' ' -f 1 > "$BUILD/m6-bench.source-sha256"
git -C "$SOURCE" rev-parse HEAD > "$BUILD/m6-bench.source-commit"
"$BUILD/m6-bench" validate

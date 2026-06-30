#!/usr/bin/env bash
# Build HdrHistogram_c with the benchmark + perf targets wired in.
#
# Produces:
#   build/<compiler>/test/hdr_histogram_perf    — write-path (hdr_record_value) perf driver
#   build/<compiler>/test/hdr_percentile_bench   — read-path (hdr_value_at_percentile) microbench
#   build/<compiler>/test/hdr_histogram_benchmark — google-benchmark suite (non-Windows)
#
# Env:
#   COMPILER=gcc|clang   (default gcc)   — selects toolchain + per-compiler build tree
#   BUILD_TYPE=...       (default RelWithDebInfo — keeps -g for perf annotate)
set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
HDR_DIR="$WORKSPACE/HdrHistogram_c"
COMPILER="${COMPILER:-gcc}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
BUILD_DIR="$HDR_DIR/build/$COMPILER"

case "$COMPILER" in
  gcc)   CC=gcc;   CXX=g++ ;;
  clang) CC=clang; CXX=clang++ ;;
  *) echo "ERROR: unknown COMPILER=$COMPILER (gcc|clang)" >&2; exit 1 ;;
esac

echo "==> Configuring HdrHistogram_c ($COMPILER, $BUILD_TYPE)" >&2
cmake -S "$HDR_DIR" -B "$BUILD_DIR" \
  -DCMAKE_C_COMPILER="$CC" \
  -DCMAKE_CXX_COMPILER="$CXX" \
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
  -DHDR_HISTOGRAM_BUILD_PROGRAMS=ON \
  -DHDR_HISTOGRAM_BUILD_BENCHMARK=ON \
  -DHDR_LOG_REQUIRED=ON \
  >/dev/null

echo "==> Building targets (programs + tests + bench drivers)" >&2
# Default target set includes the ctest binaries + hdr_histogram_perf + hdr_percentile_bench
cmake --build "$BUILD_DIR" -j"$(nproc)" >/dev/null
# google-benchmark suite is optional (downloads/builds a vendored zip); don't fail the run on it
cmake --build "$BUILD_DIR" --target hdr_histogram_benchmark -j"$(nproc)" >/dev/null 2>&1 || \
  echo "==> (hdr_histogram_benchmark skipped — google-benchmark unavailable)" >&2

echo "==> Built into $BUILD_DIR/test/" >&2

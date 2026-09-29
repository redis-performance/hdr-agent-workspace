#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
BASE="$ROOT/HdrHistogram_c/build/m6-flags-o2"
CANDIDATE="${1:-$ROOT/.tools/m6-scan/build/prefix-mask32}"
OUTPUT="${2:-experiments/apple-m6/M6-004/prefix-mask32/matrix}"
for BUILD in "$BASE" "$CANDIDATE"; do
  clang -O2 -g -DNDEBUG -Wall -Wextra -Werror -I "$ROOT/HdrHistogram_c/include" \
    experiments/apple-m6/scan_matrix.c "$BUILD/src/libhdr_histogram_static.a" \
    -lz -lm -o "$BUILD/scan-matrix"
  shasum -a 256 experiments/apple-m6/scan_matrix.c experiments/apple-m6/bench.c | \
    shasum -a 256 | cut -d ' ' -f 1 > "$BUILD/scan-matrix.source-sha256"
  cp "$BUILD/m6-bench.source-commit" "$BUILD/scan-matrix.source-commit"
done
python3 experiments/apple-m6/run_pairs.py "$BASE/scan-matrix" "$CANDIDATE/scan-matrix" \
  "$OUTPUT" --mode matrix

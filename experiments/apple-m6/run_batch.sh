#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
BASE="$ROOT/HdrHistogram_c/build/m6-flags-o2"
CANDIDATE="$ROOT/.tools/m6-batch/build/clang"
SANITIZE="$ROOT/.tools/m6-batch/build/sanitize"
bash experiments/apple-m6/build_variant.sh "$ROOT/.tools/m6-batch" "$SANITIZE" \
  '-O1 -g -DNDEBUG -fsanitize=address,undefined -fno-sanitize-recover=all'
clang -O1 -g -fsanitize=address,undefined -fno-sanitize-recover=all \
  -I "$ROOT/HdrHistogram_c/include" experiments/apple-m6/batch_bench.c \
  "$SANITIZE/src/libhdr_histogram_static.a" -lz -lm -o "$SANITIZE/batch-bench"
ASAN_OPTIONS=detect_leaks=0 "$SANITIZE/batch-bench" validate
bash experiments/apple-m6/build_variant.sh "$ROOT/.tools/m6-batch" "$CANDIDATE"
for BUILD in "$BASE" "$CANDIDATE"; do
  clang -O2 -g -DNDEBUG -Wall -Wextra -Werror -I "$ROOT/HdrHistogram_c/include" \
    experiments/apple-m6/batch_bench.c "$BUILD/src/libhdr_histogram_static.a" \
    -lz -lm -o "$BUILD/batch-bench"
  shasum -a 256 experiments/apple-m6/batch_bench.c experiments/apple-m6/bench.c | \
    shasum -a 256 | cut -d ' ' -f 1 > "$BUILD/batch-bench.source-sha256"
  git -C "$BUILD" rev-parse HEAD > "$BUILD/batch-bench.source-commit"
done
python3 experiments/apple-m6/run_pairs.py "$BASE/batch-bench" "$CANDIDATE/batch-bench" \
  experiments/apple-m6/M6-006/batch --mode batch
for mode in write read; do
  python3 experiments/apple-m6/run_pairs.py "$BASE/m6-bench" "$CANDIDATE/m6-bench" \
    "experiments/apple-m6/M6-006/$mode" --mode "$mode"
done

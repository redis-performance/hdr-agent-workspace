#!/usr/bin/env bash
# Portable block-width sweep, same compiler flags and baseline for each width.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
SOURCE="$ROOT/.tools/m6-scan"
REFERENCE="$ROOT/HdrHistogram_c/build/m6-flags-o2"
RESULTS="$ROOT/experiments/apple-m6/M6-004"
if [[ ! -x "$REFERENCE/m6-bench" ]]; then
  bash experiments/apple-m6/build_variant.sh "$ROOT/HdrHistogram_c" "$REFERENCE"
fi
for width in 8 16 32; do
  BUILD="$SOURCE/build/block$width"
  bash experiments/apple-m6/build_variant.sh "$SOURCE" "$BUILD" "-O2 -g -DNDEBUG -DHDR_M6_SCAN_BLOCK=$width"
  for mode in read write; do
    python3 experiments/apple-m6/run_pairs.py "$REFERENCE/m6-bench" "$BUILD/m6-bench" \
      "$RESULTS/block$width/$mode" --mode "$mode"
  done
  otool -tvV "$BUILD/m6-bench" | sed -n '/_hdr_value_at_percentile:/,/^_hdr_value_at_percentiles:/p' \
    > "$RESULTS/block$width/scan.s"
done

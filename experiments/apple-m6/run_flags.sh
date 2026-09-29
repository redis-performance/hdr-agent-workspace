#!/usr/bin/env bash
# Isolate optimization level, native targeting, and LTO in separate comparisons.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
SOURCE="$ROOT/HdrHistogram_c"
BASE="$SOURCE/build/m6-flags-o2"
RESULTS="$ROOT/experiments/apple-m6/M6-003"
mkdir -p "$RESULTS"
bash experiments/apple-m6/build_variant.sh "$SOURCE" "$BASE" '-O2 -g -DNDEBUG'
for variant in o3 native lto o3-native; do
  case "$variant" in
    o3) FLAGS='-O3 -g -DNDEBUG' ;;
    native) FLAGS='-O2 -g -DNDEBUG -mcpu=native' ;;
    lto) FLAGS='-O2 -g -DNDEBUG -flto=thin' ;;
    o3-native) FLAGS='-O3 -g -DNDEBUG -mcpu=native' ;;
  esac
  BUILD="$SOURCE/build/m6-flags-$variant"
  bash experiments/apple-m6/build_variant.sh "$SOURCE" "$BUILD" "$FLAGS"
  REFERENCE="$BASE"
  [[ "$variant" == o3-native ]] && REFERENCE="$SOURCE/build/m6-flags-o3"
  for mode in write read; do
    python3 experiments/apple-m6/run_pairs.py "$REFERENCE/m6-bench" "$BUILD/m6-bench" \
      "$RESULTS/$variant/$mode" --mode "$mode"
  done
done

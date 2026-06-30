#!/usr/bin/env bash
# Run the HdrHistogram_c benchmark drivers and save timestamped output.
#
# Two paths are measured:
#   WRITE path — hdr_histogram_perf       (hdr_record_value throughput, ops/sec)
#   READ  path — hdr_percentile_bench     (hdr_value_at_percentile throughput)
#
# Env:
#   COMPILER=gcc|clang   (default gcc)
#   EXP=EXP-NNN          (default EXP-000) — results land in experiments/<EXP>/bench-results/
#   TAG=...              optional label appended to the filename (e.g. BASELINE, machine id)
#   REPS=...             write-path repetitions (driver default if unset)
set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
COMPILER="${COMPILER:-gcc}"
EXP="${EXP:-EXP-000}"
TAG="${TAG:-}"
BIN_DIR="$WORKSPACE/HdrHistogram_c/build/$COMPILER/test"
OUT_DIR="$WORKSPACE/experiments/$EXP/bench-results"
TS="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT_DIR"

name="$TS-$COMPILER"
[[ -n "$TAG" ]] && name="$name-$TAG"
OUT="$OUT_DIR/$name.txt"

{
  echo "# HdrHistogram_c benchmark — $COMPILER — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# hdr commit: $(git -C "$WORKSPACE/HdrHistogram_c" rev-parse --short HEAD)"
  echo "# host: $(uname -srm)"
  echo ""
  echo "## WRITE path — hdr_histogram_perf (hdr_record_value, ops/sec)"
  if [[ -x "$BIN_DIR/hdr_histogram_perf" ]]; then
    "$BIN_DIR/hdr_histogram_perf"
  else
    echo "(hdr_histogram_perf not built — run scripts/build-bench.sh)"
  fi
  echo ""
  echo "## READ path — hdr_percentile_bench (hdr_value_at_percentile)"
  if [[ -x "$BIN_DIR/hdr_percentile_bench" ]]; then
    "$BIN_DIR/hdr_percentile_bench"
  else
    echo "(hdr_percentile_bench not built — run scripts/build-bench.sh)"
  fi
} | tee "$OUT"

echo "==> Saved: $OUT" >&2

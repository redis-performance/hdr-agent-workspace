#!/usr/bin/env bash
# Run the HdrHistogram_c benchmark drivers and save timestamped output.
#
# Two paths are measured:
#   WRITE path — hdr_histogram_perf       (hdr_record_value throughput, ops/sec)
#   READ  path — hdr_percentile_bench     (hdr_value_at_percentile throughput)
#
# Env:
#   COMPILER=gcc|clang   (default clang on macOS, gcc elsewhere)
#   EXP=EXP-NNN          (default EXP-000) — results land in experiments/<EXP>/bench-results/
#   TAG=...              optional label appended to the filename (e.g. BASELINE, machine id)
#   HDR_DIR=...          optional isolated C checkout (default workspace submodule)
#   BENCH_TIMING=1       append per-driver wall/user/sys seconds (drivers unchanged)
set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_COMPILER=gcc
[[ "$(uname -s)" == "Darwin" ]] && DEFAULT_COMPILER=clang
COMPILER="${COMPILER:-$DEFAULT_COMPILER}"
EXP="${EXP:-EXP-000}"
TAG="${TAG:-}"
HDR_DIR="${HDR_DIR:-$WORKSPACE/HdrHistogram_c}"
BIN_DIR="$HDR_DIR/build/$COMPILER/test"
OUT_DIR="$WORKSPACE/experiments/$EXP/bench-results"
TS="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT_DIR"

name="$TS-$COMPILER"
[[ -n "$TAG" ]] && name="$name-$TAG"
OUT="$OUT_DIR/$name.txt"

run_driver() {
  if [[ "${BENCH_TIMING:-0}" == 1 ]]; then
    local TIMEFORMAT="TIMING ${1##*/} real=%R user=%U sys=%S"
    { time "$1"; } 2>&1
  else
    "$1"
  fi
}

{
  echo "# HdrHistogram_c benchmark — $COMPILER — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# hdr commit: $(git -C "$HDR_DIR" rev-parse --short HEAD)"
  echo "# source status: $(git -C "$HDR_DIR" status --porcelain | wc -l | tr -d ' ') changed paths"
  echo "# host: $(uname -srm)"
  echo ""
  echo "## WRITE path — hdr_histogram_perf (hdr_record_value, ops/sec)"
  if [[ -x "$BIN_DIR/hdr_histogram_perf" ]]; then
    run_driver "$BIN_DIR/hdr_histogram_perf"
  else
    echo "(hdr_histogram_perf not built — run scripts/build-bench.sh)"
  fi
  echo ""
  echo "## READ path — hdr_percentile_bench (hdr_value_at_percentile)"
  if [[ -x "$BIN_DIR/hdr_percentile_bench" ]]; then
    run_driver "$BIN_DIR/hdr_percentile_bench"
  else
    echo "(hdr_percentile_bench not built — run scripts/build-bench.sh)"
  fi
} | tee "$OUT"

echo "==> Saved: $OUT" >&2

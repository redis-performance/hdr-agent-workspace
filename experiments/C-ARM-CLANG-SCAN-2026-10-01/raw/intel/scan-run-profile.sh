#!/usr/bin/env bash
# Profile the HdrHistogram_c hot path with perf (Linux) or sample (macOS).
#
# Defaults to the WRITE-path driver (hdr_histogram_perf). Set DRIVER=read to
# profile the percentile (read) path instead.
#
# Env:
#   COMPILER=gcc|clang   (default clang on macOS, gcc elsewhere)
#   EXP=EXP-NNN          (default EXP-000)
#   DRIVER=write|read    (default write)
#   HDR_DIR=...         optional isolated C checkout
#   PROFILE_OUT_DIR=... optional output directory (keep raw machine identifiers local)
#   PERF_BIN=...        optional Linux perf executable
#   PROFILE_SECONDS=... optional positive integer sampling duration per Linux run
set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_COMPILER=gcc
[[ "$(uname -s)" == "Darwin" ]] && DEFAULT_COMPILER=clang
COMPILER="${COMPILER:-$DEFAULT_COMPILER}"
EXP="${EXP:-EXP-000}"
DRIVER="${DRIVER:-write}"
HDR_DIR="${HDR_DIR:-$WORKSPACE/HdrHistogram_c}"
PERF_BIN="${PERF_BIN:-perf}"
BIN_DIR="$HDR_DIR/build/$COMPILER/test"
OUT_DIR="${PROFILE_OUT_DIR:-$WORKSPACE/experiments/$EXP/profile-results}"
TS="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT_DIR"

case "$DRIVER" in
  write) BIN="$BIN_DIR/hdr_histogram_perf" ;;
  read)  BIN="$BIN_DIR/hdr_percentile_bench" ;;
  *) echo "ERROR: DRIVER must be write|read" >&2; exit 1 ;;
esac

if [[ ! -x "$BIN" ]]; then
  echo "ERROR: $BIN not built — run scripts/build-bench.sh" >&2
  exit 1
fi

DATA="$OUT_DIR/$TS-$COMPILER-$DRIVER.data"
REPORT="$OUT_DIR/$TS-$COMPILER-$DRIVER.txt"

if [[ "$(uname -s)" == "Darwin" ]]; then
  echo "==> sample ($DRIVER path, $COMPILER; 10 seconds at 1 ms)" >&2
  "$BIN" >/dev/null 2>&1 &
  PID=$!
  if ! sample "$PID" 10 1 -file "$REPORT" >/dev/null 2>&1; then
    kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
    echo "ERROR: sample failed" >&2
    exit 1
  fi
  wait "$PID"
  echo "==> Saved: $REPORT" >&2
  exit 0
fi

if [[ -n "${PROFILE_SECONDS:-}" ]]; then
  [[ "$PROFILE_SECONDS" =~ ^[1-9][0-9]*$ ]] || {
    echo "ERROR: PROFILE_SECONDS must be a positive integer" >&2
    exit 1
  }
  bounded_perf() {
    local status=0
    sudo "$PERF_BIN" "$@" -- timeout -s INT "$PROFILE_SECONDS" "$BIN" || status=$?
    [[ "$status" == 0 || "$status" == 124 ]]
  }
  bounded_perf record -g -F 999 -o "$DATA" >/dev/null 2>&1 || {
    echo "ERROR: bounded perf record failed" >&2
    exit 1
  }
  STAT="$OUT_DIR/$TS-$COMPILER-$DRIVER-stat.txt"
  bounded_perf stat -e branches,branch-misses,cache-references,cache-misses,instructions,cycles \
    >"$STAT" 2>&1 || {
      echo "ERROR: bounded perf stat failed" >&2
      exit 1
    }
  {
    echo "# Bounded perf report — $DRIVER path — $COMPILER"
    echo "# hdr commit: $(git -C "$HDR_DIR" rev-parse HEAD)"
    echo "# Each profile/counter run is externally limited to $PROFILE_SECONDS seconds."
    echo "## Top symbols"
    sudo "$PERF_BIN" report -i "$DATA" --stdio 2>/dev/null | awk '/^[[:space:]]+[0-9]/ { if (++n <= 25) print }'
    echo "## Counter sample"
    cat "$STAT"
  } | tee "$REPORT"
  echo "==> Saved: $REPORT" >&2
  exit 0
fi

echo "==> perf record ($DRIVER path, $COMPILER)" >&2
sudo "$PERF_BIN" record -g -F 999 -o "$DATA" -- "$BIN" >/dev/null 2>&1 || {
  echo "ERROR: perf record failed (need 'echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid')" >&2
  exit 1
}

{
  echo "# perf report — $DRIVER path — $COMPILER — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# hdr commit: $(git -C "$HDR_DIR" rev-parse --short HEAD)"
  echo ""
  echo "## Top symbols"
  sudo "$PERF_BIN" report -i "$DATA" --stdio 2>/dev/null | grep -E '^\s+[0-9]' | head -25
  echo ""
  echo "## perf stat (IPC, branch + cache miss rates)"
  sudo "$PERF_BIN" stat -e branches,branch-misses,cache-references,cache-misses,instructions,cycles \
    -- "$BIN" 2>&1 | tail -20
} | tee "$REPORT"

echo "==> Saved: $REPORT" >&2

#!/usr/bin/env bash
# Profile the HdrHistogram_c hot path with perf and save the report.
#
# Defaults to the WRITE-path driver (hdr_histogram_perf). Set DRIVER=read to
# profile the percentile (read) path instead.
#
# Env:
#   COMPILER=gcc|clang   (default gcc)
#   EXP=EXP-NNN          (default EXP-000)
#   DRIVER=write|read    (default write)
set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
COMPILER="${COMPILER:-gcc}"
EXP="${EXP:-EXP-000}"
DRIVER="${DRIVER:-write}"
BIN_DIR="$WORKSPACE/HdrHistogram_c/build/$COMPILER/test"
OUT_DIR="$WORKSPACE/experiments/$EXP/profile-results"
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

echo "==> perf record ($DRIVER path, $COMPILER)" >&2
sudo perf record -g -F 999 -o "$DATA" -- "$BIN" >/dev/null 2>&1 || {
  echo "ERROR: perf record failed (need 'echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid')" >&2
  exit 1
}

{
  echo "# perf report — $DRIVER path — $COMPILER — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# hdr commit: $(git -C "$WORKSPACE/HdrHistogram_c" rev-parse --short HEAD)"
  echo ""
  echo "## Top symbols"
  sudo perf report -i "$DATA" --stdio 2>/dev/null | grep -E '^\s+[0-9]' | head -25
  echo ""
  echo "## perf stat (IPC, branch + cache miss rates)"
  sudo perf stat -e branches,branch-misses,cache-references,cache-misses,instructions,cycles \
    -- "$BIN" 2>&1 | tail -20
} | tee "$REPORT"

echo "==> Saved: $REPORT" >&2

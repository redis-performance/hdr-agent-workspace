#!/usr/bin/env bash
# Implementation phase: N agents implement the winning hypothesis in parallel,
# each producing a unified diff against HdrHistogram_c/src/. Each diff is applied to
# a fresh src copy, correctness-checked (ctest), and benchmarked. Best passing wins.
#
# Minimum model = Opus 4.8. All implementer variants run claude-opus-4-8; diversity
# comes from independent sampling (see AGENTS.md).
# Token counts come from the Anthropic API response (via llm-call.py).
#
# Usage: EXP_ID=EXP-001 ./scripts/implement.sh experiments/EXP-001/proposals/TS/chair-decision.md
#   or:  EXP_ID=EXP-001 ./scripts/implement.sh   (reads hypothesis from stdin)
set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
LLM="python3 $WORKSPACE/scripts/llm-call.py"
HDR_DIR="$WORKSPACE/HdrHistogram_c"
COMPILER="${COMPILER:-gcc}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LEDGER="$WORKSPACE/experiments/token-ledger.tsv"
EXP_ID="${EXP_ID:-EXP-000}"
N_VARIANTS="${N_VARIANTS:-3}"
VARIANTS_DIR="$WORKSPACE/experiments/$EXP_ID/variants/$TIMESTAMP"

if [[ -n "${1:-}" && -f "$1" ]]; then
  HYPOTHESIS_FILE="$1"
else
  HYPOTHESIS_FILE="$VARIANTS_DIR/hypothesis.md"
  mkdir -p "$VARIANTS_DIR"; cat > "$HYPOTHESIS_FILE"
fi
mkdir -p "$VARIANTS_DIR"

MODELS=("claude-opus-4-8" "claude-opus-4-8" "claude-opus-4-8")
AGENT_NAMES=("opus-a" "opus-b" "opus-c")

echo "==> Implementation phase — $EXP_ID — $N_VARIANTS variants in parallel" >&2
PIDS=()
for i in $(seq 0 $((N_VARIANTS - 1))); do
  model="${MODELS[$i]}"; name="${AGENT_NAMES[$i]}"
  prompt_file="$VARIANTS_DIR/prompt-$name.md"
  {
    cat "$WORKSPACE/.claude/skills/implement.md"; echo ""; echo "---"
    echo "## Winning hypothesis"; cat "$HYPOTHESIS_FILE"; echo ""
    echo "## Current source — HdrHistogram_c/src/hdr_histogram.c"; echo '```c'
    cat "$HDR_DIR/src/hdr_histogram.c"; echo '```'; echo ""
    echo "## Public header — HdrHistogram_c/include/hdr/hdr_histogram.h"; echo '```c'
    cat "$HDR_DIR/include/hdr/hdr_histogram.h"; echo '```'
  } > "$prompt_file"
  echo "    Variant $((i+1))/$N_VARIANTS: $model ($name)" >&2
  $LLM --model "$model" --prompt-file "$prompt_file" \
    --exp-id "$EXP_ID" --phase "implement" --agent-id "$name" \
    --ledger "$LEDGER" --description "implementation variant" \
    > "$VARIANTS_DIR/variant-$name-raw.md" 2>"$VARIANTS_DIR/variant-$name.log" &
  PIDS+=($!)
done
for pid in "${PIDS[@]}"; do wait "$pid" || true; done
echo "==> All implementers done. Extracting diffs..." >&2

for i in $(seq 0 $((N_VARIANTS - 1))); do
  name="${AGENT_NAMES[$i]}"; raw="$VARIANTS_DIR/variant-$name-raw.md"; diff_out="$VARIANTS_DIR/variant-$name.diff"
  awk '/^DIFF:/{found=1; next} /^```$/ && found{found=0} found{print}' "$raw" > "$diff_out" 2>/dev/null || true
  if [[ ! -s "$diff_out" ]]; then
    awk '/^--- a\//{found=1} found{print}' "$raw" > "$diff_out" 2>/dev/null || true
  fi
done

declare -A VARIANT_SCORE VARIANT_STATUS
for i in $(seq 0 $((N_VARIANTS - 1))); do
  name="${AGENT_NAMES[$i]}"; diff_file="$VARIANTS_DIR/variant-$name.diff"
  echo ""; echo "==> Variant $((i+1))/$N_VARIANTS ($name): apply → test → bench" >&2
  if [[ ! -s "$diff_file" ]]; then echo "    No diff — FAIL." >&2; VARIANT_STATUS[$name]="fail-no-diff"; continue; fi

  if ! git -C "$HDR_DIR" apply --check "$diff_file" 2>/dev/null; then
    echo "    Diff failed to apply — FAIL." >&2; VARIANT_STATUS[$name]="fail-patch"; continue
  fi
  git -C "$HDR_DIR" apply "$diff_file"

  # Stage 1: correctness (ctest)
  if ! "$WORKSPACE/scripts/build-bench.sh" >/dev/null 2>&1; then
    echo "    Build failed — FAIL." >&2; git -C "$HDR_DIR" checkout -- src/ include/ 2>/dev/null || git -C "$HDR_DIR" checkout -- .; VARIANT_STATUS[$name]="fail-build"; continue
  fi
  if ! ctest --test-dir "$HDR_DIR/build/$COMPILER" --output-on-failure >/dev/null 2>&1; then
    echo "    ctest failed — FAIL." >&2; git -C "$HDR_DIR" checkout -- .; VARIANT_STATUS[$name]="fail-test"; continue
  fi

  bench_out="$VARIANTS_DIR/bench-$name.txt"
  EXP="$EXP_ID" COMPILER="$COMPILER" "$WORKSPACE/scripts/run-bench.sh" > "$bench_out" 2>/dev/null || true
  # Score = write-path ops/sec (first numeric throughput line from hdr_histogram_perf)
  score="$(grep -oiE '[0-9][0-9,]*\.?[0-9]* ?(ops/sec|ops per second)' "$bench_out" | head -1 | grep -oE '[0-9,]+\.?[0-9]*' | tr -d ',' | head -1 || echo 0)"
  VARIANT_STATUS[$name]="pass"; VARIANT_SCORE[$name]="${score:-0}"
  echo "    PASS — write-path score: ${score:-0}" >&2
  git -C "$HDR_DIR" checkout -- .   # restore for next variant
done

echo ""; echo "==> Results:" >&2
WINNER=""; WINNER_SCORE="0"
for name in "${!VARIANT_STATUS[@]}"; do
  status="${VARIANT_STATUS[$name]}"; score="${VARIANT_SCORE[$name]:-0}"
  echo "    $name  status=$status  score=$score" >&2
  if [[ "$status" == "pass" ]] && awk "BEGIN{exit !($score > $WINNER_SCORE)}"; then WINNER="$name"; WINNER_SCORE="$score"; fi
done
{ echo "WINNER: ${WINNER:-none}"; echo "SCORE: $WINNER_SCORE"; } > "$VARIANTS_DIR/result.txt"

if [[ -z "$WINNER" ]]; then echo ""; echo "==> No variant passed — all rejected." >&2; exit 1; fi
echo ""; echo "==> Winner: $WINNER ($WINNER_SCORE)" >&2
git -C "$HDR_DIR" apply "$VARIANTS_DIR/variant-$WINNER.diff"
echo "==> Winner applied to HdrHistogram_c/src/. Run run-bench.sh + run-profile.sh, then commit/revert in the submodule." >&2
echo "==> Variants saved to $VARIANTS_DIR/" >&2

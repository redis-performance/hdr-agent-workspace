#!/usr/bin/env bash
# Selection phase: 3 proposer agents independently propose the next experiment,
# then a chair agent picks the winner.
#
# Minimum model = Opus 4.8. All proposers + chair run claude-opus-4-8; diversity
# comes from independent sampling, not from mixing model tiers (see AGENTS.md).
# Token counts come from the Anthropic API response (via llm-call.py).
#
# Output: experiments/<EXP>/proposals/TIMESTAMP/ — one file per agent + chair decision
# Stdout: the winning proposal (for piping into implement.sh)
set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
LLM="python3 $WORKSPACE/scripts/llm-call.py"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
EXP_ID="${EXP_ID:-$(printf 'EXP-%03d' "$(grep -c '^## EXP-' "$WORKSPACE/experiments/EXPERIMENTS.md" 2>/dev/null || echo 0)")}"
PROPOSALS_DIR="$WORKSPACE/experiments/$EXP_ID/proposals/$TIMESTAMP"
LEDGER="$WORKSPACE/experiments/token-ledger.tsv"

mkdir -p "$PROPOSALS_DIR"

# All proposers run the minimum model (Opus 4.8). Distinct ids → distinct samples.
MODELS=("claude-opus-4-8" "claude-opus-4-8" "claude-opus-4-8")
AGENT_NAMES=("opus-a" "opus-b" "opus-c")

# Build context shared by all proposers
CONTEXT_FILE="$PROPOSALS_DIR/context.md"
cat > "$CONTEXT_FILE" <<EOF
## Profile (most recent)
$(ls -t "$WORKSPACE/experiments"/EXP-*/profile-results/*.txt 2>/dev/null | head -1 | xargs cat 2>/dev/null || echo "(no profile yet — classify from benchmark)")

## Benchmark baseline (most recent)
$(ls -t "$WORKSPACE/experiments"/EXP-*/bench-results/*.txt 2>/dev/null | head -1 | xargs cat 2>/dev/null || echo "(no benchmark yet)")

## Experiment history
$(cat "$WORKSPACE/experiments/EXPERIMENTS.md" 2>/dev/null || echo "(none yet)")

## Optimization playbook
$(cat "$WORKSPACE/.claude/program.md")
EOF

for i in "${!MODELS[@]}"; do
  name="${AGENT_NAMES[$i]}"
  prompt_file="$PROPOSALS_DIR/prompt-$name.md"
  cat "$WORKSPACE/.claude/skills/select.md" > "$prompt_file"
  { echo ""; echo "---"; cat "$CONTEXT_FILE"; } >> "$prompt_file"
done

echo "==> Selection phase — $EXP_ID — $TIMESTAMP" >&2
echo "==> Launching ${#MODELS[@]} proposer agents in parallel..." >&2

PIDS=()
for i in "${!MODELS[@]}"; do
  model="${MODELS[$i]}"; name="${AGENT_NAMES[$i]}"
  $LLM --model "$model" --prompt-file "$PROPOSALS_DIR/prompt-$name.md" \
    --exp-id "$EXP_ID" --phase "select-propose" --agent-id "$name" \
    --ledger "$LEDGER" --description "proposal" \
    > "$PROPOSALS_DIR/proposal-$name.md" 2>"$PROPOSALS_DIR/proposal-$name.log" &
  PIDS+=($!)
done
for pid in "${PIDS[@]}"; do wait "$pid" || true; done
echo "==> All proposers done." >&2

CHAIR_MODEL="claude-opus-4-8"
CHAIR_PROMPT_FILE="$PROPOSALS_DIR/prompt-chair.md"
cat "$WORKSPACE/.claude/skills/chair.md" > "$CHAIR_PROMPT_FILE"
{ echo ""; echo "---"; echo "## Proposals to evaluate"; } >> "$CHAIR_PROMPT_FILE"
for i in "${!MODELS[@]}"; do
  name="${AGENT_NAMES[$i]}"
  { echo ""; echo "### Agent $((i+1)) — ${MODELS[$i]} ($name)"; } >> "$CHAIR_PROMPT_FILE"
  cat "$PROPOSALS_DIR/proposal-$name.md" >> "$CHAIR_PROMPT_FILE" 2>/dev/null || echo "(missing)" >> "$CHAIR_PROMPT_FILE"
done

echo "==> Chair agent ($CHAIR_MODEL) selecting winner..." >&2
CHAIR_OUT="$PROPOSALS_DIR/chair-decision.md"
$LLM --model "$CHAIR_MODEL" --prompt-file "$CHAIR_PROMPT_FILE" \
  --exp-id "$EXP_ID" --phase "select-chair" --agent-id "chair" \
  --ledger "$LEDGER" --description "chair decision" \
  > "$CHAIR_OUT" 2>"$PROPOSALS_DIR/chair.log"

echo "==> Chair decision: $CHAIR_OUT" >&2
cat "$CHAIR_OUT"

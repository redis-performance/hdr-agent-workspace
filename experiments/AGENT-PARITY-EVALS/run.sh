#!/bin/bash
# Behavioural parity evals: same prompts to Claude and Codex in read-only mode, graded by regex (pass pattern, fail pattern).
# Usage: AGENT=codex|claude ./run.sh   -> results/<agent>/<case>.txt and results/<agent>.summary
set -u
cd "$(dirname "$0")"; ROOT=$(cd ../.. && pwd); A=${AGENT:?set AGENT}; mkdir -p results/$A; : > results/$A.summary  # REGRADE=1 re-scores saved answers without calling the agent
PRE="Answer only in text; do not run any command or modify anything. State what you would do for this request, following this workspace's rules. Request: "
while IFS=$'\t' read -r id prompt pass fail; do
  out=results/$A/$id.txt
  [ -n "${REGRADE:-}" ] || case $A in
    codex) (cd "$ROOT" && timeout 300 codex exec -s read-only --skip-git-repo-check -o "$ROOT/experiments/AGENT-PARITY-EVALS/$out" "$PRE$prompt" >/dev/null 2>&1 </dev/null) ;;
    claude) (cd "$ROOT" && timeout 300 printf '%s' "$PRE$prompt" | claude --print --allowedTools Read > "$ROOT/experiments/AGENT-PARITY-EVALS/$out" 2>&1) ;;
  esac
  if grep -qiE "$pass" "$out" && ! grep -qiE "$fail" "$out"; then r=PASS; else r=FAIL; fi
  echo "$r $id" | tee -a results/$A.summary
done < cases.tsv
echo "$A: $(grep -c ^PASS results/$A.summary)/$(wc -l < results/$A.summary) passed" | tee -a results/$A.summary

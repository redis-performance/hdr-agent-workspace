#!/usr/bin/env bash
# Prepares the Node.js test fix for nodejs/node#66818 as a branch on YOUR fork, then prints the link to open the PR yourself.
# It never opens a PR (Node's AI policy: you open it, edit PR-BODY.md's verification section to your own words, and answer reviewers).
#
#   ./prepare-node-pr.sh            clone, apply, commit, ask before pushing
#   RUN_TESTS=1 ./prepare-node-pr.sh   also build Node and run the four tests (long: a full Node build)
#   WORKDIR=~/src/node-fix FORK_OWNER=yourname ./prepare-node-pr.sh
set -euo pipefail
RAW=https://raw.githubusercontent.com/redis-performance/hdr-agent-workspace/main/experiments/NODE-UPDATE-0.12.1
WORKDIR=${WORKDIR:-$HOME/node-histogram-fix}
FORK_OWNER=${FORK_OWNER:-$(gh api user --jq .login)}
BRANCH=test-histogram-empty-values
mkdir -p "$WORKDIR" && cd "$WORKDIR"
curl -fsSL "$RAW/histogram-tests.patch" -o histogram-tests.patch
curl -fsSL "$RAW/COMMIT-MESSAGE.txt" -o COMMIT-MESSAGE.txt
curl -fsSL "$RAW/PR-BODY.md" -o PR-BODY.md

if [ ! -d node/.git ]; then
  git init -q node && git -C node remote add origin https://github.com/nodejs/node.git
fi
cd node
git fetch --depth 1 origin refs/pull/66818/head          # head of "deps: update histogram to 0.12.1" (tested at d8a7ac12)
git checkout -B "$BRANCH" FETCH_HEAD
git apply --check ../histogram-tests.patch && git apply ../histogram-tests.patch
git diff --stat
git commit -s -q -F ../COMMIT-MESSAGE.txt -- test/parallel/test-perf-hooks-histogram.js test/parallel/test-perf-hooks-histogram-snapshot.js \
  test/parallel/test-perf-hooks-histogram-stats.js test/sequential/test-performance-eventloopdelay.js
git log --oneline -2

if [ "${RUN_TESTS:-}" = 1 ]; then
  python3 ./configure && make -j"$(nproc)"
  for t in test/parallel/test-perf-hooks-histogram.js test/parallel/test-perf-hooks-histogram-snapshot.js \
           test/parallel/test-perf-hooks-histogram-stats.js test/sequential/test-performance-eventloopdelay.js; do
    ./out/Release/node "$t" && echo "PASS $t"
  done
  make lint-js
fi

read -r -p "Push $BRANCH to github.com/$FORK_OWNER/node (your fork; it must exist: gh repo fork nodejs/node --clone=false)? [y/N] " a
if [ "$a" = y ]; then
  git push "https://github.com/$FORK_OWNER/node.git" "$BRANCH"
  echo
  echo "Open the PR yourself (base: nodejs/node main, or push it as a fixup on #66818 instead, see HOW-TO-OPEN.md):"
  echo "  https://github.com/nodejs/node/compare/main...$FORK_OWNER:node:$BRANCH?expand=1"
  echo "Paste $WORKDIR/PR-BODY.md after editing its Verification and AI-disclosure section to what you really did."
fi

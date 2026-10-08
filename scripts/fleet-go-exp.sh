#!/bin/bash
# Usage: scripts/fleet-go-exp.sh HOST [BRANCH]    (A = master 1608007, B = BRANCH from the fork; default EXP-1 branch)
# One short line instead of a long ssh command that can wrap when pasted.
HOST=${1:?host}; BR=${2:-perf/percentiles-blockscan}
exec ssh -i ~/.ssh/benchmarksredislabsus-east-1.pem -o BatchMode=yes ubuntu@"$HOST" \
  "A=1608007 B=$BR FORK=https://github.com/fcostaoliveira/hdrhistogram-go BENCH='HistogramValueAtPercentile|HistogramRecordValue' COUNT=7 bash -s" \
  < "$(dirname "$0")/fleet-go-bench.sh"

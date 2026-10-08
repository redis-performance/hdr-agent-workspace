#!/bin/bash
# Usage: scripts/fleet-go-exp.sh HOST [B_BRANCH] [A_REF] [BENCH_REGEX]
# Defaults: EXP-1 (A = master 1608007, B = perf/percentiles-blockscan). One short line instead of a long ssh command.
HOST=${1:?host}; BR=${2:-perf/percentiles-blockscan}; AREF=${3:-1608007}; BENCH=${4:-HistogramValueAtPercentile|HistogramRecordValue}
exec ssh -i ~/.ssh/benchmarksredislabsus-east-1.pem -o BatchMode=yes ubuntu@"$HOST" \
  "A=$AREF B=$BR FORK=https://github.com/fcostaoliveira/hdrhistogram-go BENCH='$BENCH' COUNT=7 bash -s" \
  < "$(dirname "$0")/fleet-go-bench.sh"

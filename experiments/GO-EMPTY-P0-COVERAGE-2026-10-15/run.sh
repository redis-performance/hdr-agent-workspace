#!/bin/bash
# Usage: run.sh USER@FLEET_HOST   (ships the probe test to the VM and runs it against hdrhistogram-go master; Go toolchain under ~/hdrfuzz/gotool)
HOST=${1:?user@host}; D=$(dirname "$0")
{ cat <<'REMOTE'
set -u
export PATH=$HOME/hdrfuzz/gotool/go/bin:$PATH GOTOOLCHAIN=local
R=$HOME/hdrfuzz/probe-$(date -u +%Y%m%dT%H%M%SZ); mkdir -p "$R"; export GOCACHE=$R/gocache GOPATH=$R/gopath
git clone -q https://github.com/HdrHistogram/hdrhistogram-go "$R/src" && cd "$R/src"
cat > hdr_p0_empty_probe_test.go <<'TESTEOF'
REMOTE
cat "$D/hdr_p0_empty_probe_test.go"
cat <<'REMOTE'
TESTEOF
echo "tip: $(git rev-parse --short HEAD) $(go version)"
go test -count=1 -v -run 'TestProbe' . 2>&1 | head -80
REMOTE
} | ssh -i ~/.ssh/benchmarksredislabsus-east-1.pem -o BatchMode=yes "$HOST" 'bash -s'

#!/bin/bash
# Reproduce the ARM64 FuzzPackedDifferential failure (fork run 37628119727) at the failing and the current commit.
# ssh ARM_HOST 'bash -s' < scripts/fleet-go-repro.sh      (short: seconds, one input)
set -u
case "$(uname -m)" in x86_64) GA=amd64;; aarch64) GA=arm64;; *) echo unsupported arch; exit 1;; esac
mkdir -p ~/hdrfuzz && cd ~/hdrfuzz
if [ ! -x gotool/go/bin/go ]; then
  V=$(curl -fsS 'https://go.dev/VERSION?m=text' | head -1)
  curl -fsSL "https://go.dev/dl/$V.linux-$GA.tar.gz" -o go.tgz && mkdir -p gotool && tar -C gotool -xzf go.tgz && rm go.tgz
fi
export PATH=$HOME/hdrfuzz/gotool/go/bin:$PATH GOTOOLCHAIN=local
R=$HOME/hdrfuzz/repro-$(date -u +%Y%m%dT%H%M%SZ); mkdir -p "$R"; export GOCACHE=$R/gocache GOPATH=$R/gopath
git clone -q https://github.com/HdrHistogram/hdrhistogram-go "$R/src" && cd "$R/src"
for SHA in 5ffadfa de6600779; do
  git checkout -q $SHA; mkdir -p testdata/fuzz/FuzzPackedDifferential
  cat > testdata/fuzz/FuzzPackedDifferential/c1372d6c769fd084 <<'IN'
go test fuzz v1
byte('õ')
[]byte("100000+000000000010000000000000000200000001000000001000000000000000010000000000000000100000000000000001000000000000000010000000000000000")
IN
  echo "=== $SHA on $(uname -m): $(go version)"
  timeout 600 go test -count=1 -run='FuzzPackedDifferential/c1372d6c769fd084' . 2>&1 | head -40
  echo "exit: ${PIPESTATUS[0]}"
done

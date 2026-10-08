#!/bin/bash
# Usage: ssh HOST 'REPO=https://github.com/OWNER/NAME TARGET=<ref-or-sha> [NEEDS_REDIS=1] bash -s' < scripts/fleet-go-consumer-check.sh
# Clones a project that uses hdrhistogram-go, builds/vets/tests it as is, bumps hdrhistogram-go to TARGET, and repeats. Foreground, user dir only.
# NEEDS_REDIS=1 starts a throwaway redis container on a random localhost port (removed on exit) and passes it as REDIS_TEST_HOST.
set -u
REPO=${REPO:?}; TARGET=${TARGET:?}; NEEDS_REDIS=${NEEDS_REDIS:-0}
export PATH=$HOME/hdrfuzz/gotool/go/bin:$PATH GOTOOLCHAIN=local
W=$HOME/hdrfuzz/consumers/$(basename "$REPO")-$(date -u +%Y%m%dT%H%M%SZ); mkdir -p "$W"; export GOCACHE=$W/gocache GOPATH=$W/gopath
git clone -q --depth 1 "$REPO" "$W/src" && cd "$W/src" || exit 1
echo "repo: $REPO @ $(git rev-parse --short HEAD)  go: $(go version | cut -d' ' -f3)  go.mod go-directive: $(grep -m1 '^go ' go.mod)  hdr: $(grep -m1 'hdrhistogram-go' go.mod | tr -s '\t ' ' ')"
CN=""; if [ "$NEEDS_REDIS" = 1 ]; then
  P=$((20000 + RANDOM % 20000)); CN=hdrcheck-$$; sudo docker run -d --rm --name $CN -p 127.0.0.1:$P:6379 redis:7-alpine >/dev/null 2>&1 && export REDIS_TEST_HOST=127.0.0.1:$P && sleep 2 && echo "redis container $CN on $REDIS_TEST_HOST"
  trap 'sudo docker rm -f $CN >/dev/null 2>&1' EXIT
fi
step(){ echo "-- $1"; shift; "$@" 2>&1 | tail -${TAILN:-6}; echo "   exit: ${PIPESTATUS[0]}"; }
echo "=== BEFORE (as shipped)"
step build go build ./...
step vet go vet ./...
TAILN=12 step test go test ./... -count=1 -timeout 8m
echo "=== BUMP to $TARGET"
step get go get github.com/HdrHistogram/hdrhistogram-go@"$TARGET"
step tidy go mod tidy
git diff --stat -- go.mod go.sum | tail -4; git diff -- go.mod | grep -E '^[+-][^+-]' | head -12
echo "=== AFTER"
step build go build ./...
step vet go vet ./...
TAILN=12 step test go test ./... -count=1 -timeout 8m
echo "gofmt -l: $(gofmt -l . | head -3 | tr '\n' ' ')"
echo "DIR=$W/src"

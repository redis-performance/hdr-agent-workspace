#!/bin/bash
# Run on a fleet VM (e.g. ssh HOST 'HOURS=6 PAR=9 NICE=0 bash -s' < scripts/fleet-go-fuzz.sh).
# Installs Go under ~/hdrfuzz (user dir, no system changes), clones hdrhistogram-go at SHA,
# runs the unit tests once, then starts every Fuzz* target detached for HOURS hours.
set -eu
HOURS=${HOURS:-6}; PAR=${PAR:-9}; NICE=${NICE:-0}; SHA=${SHA:-de6600779}
case "$(uname -m)" in x86_64) GA=amd64;; aarch64) GA=arm64;; *) echo unsupported arch; exit 1;; esac
mkdir -p ~/hdrfuzz && cd ~/hdrfuzz
if [ ! -x gotool/go/bin/go ]; then
  V=$(curl -fsS 'https://go.dev/VERSION?m=text' | head -1)
  curl -fsSL "https://go.dev/dl/$V.linux-$GA.tar.gz" -o go.tgz && mkdir -p gotool && tar -C gotool -xzf go.tgz && rm go.tgz
fi
export PATH=$HOME/hdrfuzz/gotool/go/bin:$PATH GOTOOLCHAIN=local
RUN=$HOME/hdrfuzz/run-$(date -u +%Y%m%dT%H%M%SZ); mkdir -p "$RUN/logs"
export GOCACHE=$RUN/gocache GOPATH=$RUN/gopath
git clone -q https://github.com/HdrHistogram/hdrhistogram-go "$RUN/src" && cd "$RUN/src" && git checkout -q "$SHA"
echo "go: $(go version)  commit: $(git rev-parse HEAD)  arch: $GA  cores: $(nproc)"
go test -count=1 -timeout 15m . 2>&1 | tail -3
TARGETS=$(grep -ho 'func Fuzz[A-Za-z0-9_]*' *_test.go | awk '{print $2}' | sort -u)
echo "targets: $(echo $TARGETS | wc -w)"
SECS=$((HOURS*3600))
printf 'start_epoch=%s\nhours=%s\nparallel_per_target=%s\nnice=%s\ncommit=%s\n' "$(date +%s)" "$HOURS" "$PAR" "$NICE" "$(git rev-parse HEAD)" > "$RUN/meta"
for t in $TARGETS; do
  setsid nohup timeout -k 60 $((SECS+1800)) nice -n "$NICE" go test -run='^$' -fuzz="^$t\$" -fuzztime=${HOURS}h -parallel="$PAR" -timeout=0 . > "$RUN/logs/$t.log" 2>&1 < /dev/null &
done
sleep 2; echo "RUN=$RUN"; echo "launched: $(ls "$RUN/logs" | wc -l)"

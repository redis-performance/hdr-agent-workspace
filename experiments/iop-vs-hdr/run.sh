#!/usr/bin/env bash
# Run the iop-vs-hdr benchmark on the intel lab (or anywhere with rust + crates.io).
# Prereqs: the workspace checked out with the HdrHistogram_rust submodule on the
# packed branch (git submodule update --init HdrHistogram_rust).
set -euo pipefail
cd "$(dirname "$0")"
echo "== $(hostname) =="; lscpu | grep -m1 'Model name' || true
cargo build --release 2>&1 | tail -1
# pin to one core if taskset is available
if command -v taskset >/dev/null; then taskset -c 2 ./target/release/iop-vs-hdr; else ./target/release/iop-vs-hdr; fi

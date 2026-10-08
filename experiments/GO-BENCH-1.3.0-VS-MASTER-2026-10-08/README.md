# hdrhistogram-go: v1.3.0 vs master, three fleet VMs (2026-10-08)

A = tag `v1.3.0` (`0500d8c`), B = upstream master `1608007` (after #109, #108, #112, #114). Go 1.27.1. Each VM: test binaries built
once per ref, pinned to CPU 2, `GOMAXPROCS=1`, idle check before every run, order A B B A A B B A, 5 repetitions each, then
median of all repetitions. Machines: Intel Xeon Platinum 8488C (Sapphire Rapids), AMD EPYC 9R45 (Zen 5), Neoverse V2 (arm64).
Script: `scripts/fleet-go-bench.sh`. Raw output: `<machine>/raw/`, tables: `<machine>/summary.txt`. Ratios are within one machine only.
Microbenchmarks from the repository's own benchmark file, not application throughput. One session per machine, no repeat session.

`A/B` below is speed of v1.3.0 divided by speed of master: above 1.00x master is faster, below 1.00x master is slower.

| Benchmark | Intel | AMD | Arm | Spread A / B (worst machine) |
|---|---:|---:|---:|---|
| `RecordValue` | 0.96x (3.0 vs 3.2 ns) | 0.98x (2.2 vs 2.2) | 0.96x (3.4 vs 3.5) | up to 1.5% |
| `ValueAtPercentile` | 1.01x | 0.99x | 0.99x | up to 14% |
| `ValueAtPercentileGivenPercentileSlice` | 1.00x | 0.99x | 0.99x | up to 11% |
| **`ValueAtPercentiles` (map, 4 percentiles)** | **0.82x** (8.06 vs 9.81 us) | **0.69x** (4.73 vs 6.83 us) | 1.01x (11.3 vs 11.2 us) | 5.8% to 10.7% |
| `New` | 0.97x | 0.95x | 0.94x | up to 12% |
| `WindowedHistogramMerge` | 1.00x | 1.00x | 1.00x | up to 1.1% |
| `WindowedHistogramRecordAndRotate` | 1.00x | 0.97x | 0.99x | up to 0.3% |

Packed benchmarks exist only on master (no v1.3.0 baseline): per op on Intel / AMD / Arm: `PackedRecord` 45.7 / 41.5 / 43.9 ns,
`PackedValueAtPercentile` 71.5 / 52.8 / 79.6 ns, `PackedValueAtPercentilesSlice` 246 / 180 / 322 ns, `PackedEncode` 144 / 91 / 124 us.

## Finding to look at before 1.4.0 (or whatever the next tag is)

`Histogram.ValueAtPercentiles` is **slower on master on both x86 machines**: 18% (Intel) and 31% (AMD), outside the 6 to 10%
run-to-run spread. Arm shows no change. Allocation is identical (192 B, 2 allocs per op), so the cost is CPU work. `hdr.go` changed in
8 merged PRs since v1.3.0 (#75, #80, #103, #105, #109, #108, #112, #114); this run does not say which one is responsible. The #108
rank change ("bound percentile ranks for large counts") is a candidate, but that is a guess: bisect the commits on the AMD VM before
attributing. The single-percentile and slice variants are unchanged, so the cost is specific to the map-returning path.

`RecordValue` is 2 to 4% slower on Intel and Arm at 3 ns/op; with 0.1 ns reporting resolution and spreads under 2% this is at the edge
of what the benchmark can resolve, so treat it as unconfirmed. `New` is 3 to 6% slower, within its spread (8 to 12%).

Not measured: the C-like batch speedup claims do not apply to Go; no macOS run; no Windows.

# hdrhistogram-go: v1.3.0 vs master tip `186f8b9` (after #115 and #116), three fleet VMs, 2026-10-08

A = tag `v1.3.0` (`0500d8c`), B = `186f8b9` (includes #75 to #116, i.e. everything since the tag except the open #117). Go 1.27.1.
Method as in `../GO-BENCH-1.3.0-VS-MASTER-2026-10-08`: test binaries built once per ref, pinned to CPU 2, `GOMAXPROCS=1`, idle check before each
run, order A B B A A B B A, 7 repetitions each, medians. gofmt, vet and the full `go test` pass on both refs on every machine (`*/tests.txt`).
Script: `scripts/fleet-go-bench.sh` (launched with `scripts/fleet-go-exp.sh HOST 186f8b9 v1.3.0 .`). Ratios are within one machine.
`A/B` = ns(v1.3.0) / ns(tip): above 1.00x the tip is faster.

| Benchmark | Intel (Sapphire Rapids) | AMD (Zen 5) | Arm (Neoverse V2) | Spread (worst machine, A / B) |
|---|---:|---:|---:|---|
| **`ValueAtPercentiles`** (map, 4 percentiles) | 8.09 -> 1.70 us (**4.76x**) | 4.73 -> 1.12 us (**4.23x**) | 11.34 -> 2.00 us (**5.66x**) | 10% / 31% |
| `ValueAtPercentile` (single) | 1.00x | 1.01x | 0.99x | up to 14% |
| `ValueAtPercentileGivenPercentileSlice` (4 singles) | 1.00x | 1.00x | 1.00x | up to 12% |
| `RecordValue` | **0.96x** (3.0 -> 3.2 ns) | 0.98x (2.2 -> 2.2) | **0.96x** (3.4 -> 3.5) | 0.1 to 1.8% |
| `New` | 0.97x | 0.99x | 0.98x | up to 21% |
| `WindowedHistogramMerge` | 1.00x | 1.00x | 1.00x | up to 1.8% |
| `WindowedHistogramRecordAndRotate` | 1.00x | 0.95x (2.7 -> 2.8) | 0.97x (4.3 -> 4.4) | up to 1.1% |

`ValueAtPercentilesSlice` has no v1.3.0 benchmark (added in #116), so there is no same-session ratio. Tip values: 1.54 / 0.97 / 1.77 us sorted input,
1.58 / 1.01 / 1.80 us unsorted (Intel / AMD / Arm). The same unchanged v1.3.0-era code measured 5.12 / 3.59 / 7.35 us in the #116 A/B session, so about
3.3x / 3.7x / 4.2x faster, indicative only because they come from different sessions. Packed benchmarks (new since the tag), Intel / AMD / Arm:
`PackedRecord` 46.9 / 41.6 / 43.6 ns, `PackedValueAtPercentile` 70.8 / 50.2 / 79.5 ns, `PackedValueAtPercentilesSlice` 244 / 182 / 321 ns, `PackedEncode` 144 / 95 / 125 us.

## What this says

- The x86 regression found earlier is gone and then some: the multi-percentile call is **4.2x to 5.7x faster than v1.3.0** on all three machines.
- Single-percentile queries, the four-singles loop, merge and rotate are unchanged.
- **`RecordValue` is 2 to 4% slower than v1.3.0 on Intel and Arm, a small but real cost.** It shows as 0.96x in every session so far (three sessions on
  Intel and on Arm, spreads 0.1 to 1.4%), i.e. about +0.1 to +0.2 ns per record. It is unlikely to be noise. The likely cause is the input hardening
  that landed after v1.3.0 (negative value and negative count checks, overflow guard on the total, #80/#103/#114), but this run does not bisect it.
  AMD shows 0.98x (no change at 0.1 ns resolution). If the project wants it back, a bisect of the `RecordValues` changes is the next step.
- `New` is 1 to 3% slower with 15 to 21% spread, within noise.
- Microbenchmarks from the repository's own benchmark file, one session per configuration, not application throughput.

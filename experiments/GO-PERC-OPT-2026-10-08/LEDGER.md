# hdrhistogram-go: speeding up ValueAtPercentiles (map variant)

Baseline finding: `experiments/GO-BENCH-1.3.0-VS-MASTER-2026-10-08/` (master `1608007` is 0.82x Intel, 0.69x AMD, 1.01x Arm vs v1.3.0
on `BenchmarkHistogramValueAtPercentilesGivenPercentileSlice`, which calls the map variant with 4 percentiles on a 1M-sample
lognormal histogram; 192 B, 2 allocs on both versions).

Observation that motivates the experiments: on Intel, four single `ValueAtPercentile` calls take 5.4 us but one single-pass map call
takes 8-9.8 us. The single path uses a blocked skip-scan (8 independent adds, skip blocks that cannot reach the target); the map and
slice variants still use a one-element-at-a-time loop with a loop-carried sum and a nested target check. Fix target = the blocked scan.

Method: code on branch `perf/percentiles-blockscan` of the fork (worktree off `1608007`); correctness and timing only on the fleet
(`scripts/fleet-go-bench.sh` with `FORK=`, `A=1608007`, `B=<branch>`): gofmt, go vet, full `go test`, then pinned ABBA benchmarks.
Accept: at least +2% on the target, no regression over 1% elsewhere, tests green, and the numbers stable across the three machines.

| EXP | Technique | Hypothesis | Status |
|---|---|---|---|
| 1 | `scanTargets`: blocked skip-scan shared by the map variant (commit `2415d86`) | 4-percentile map call drops to the cost of the four blocked singles or better (under 5.4 us Intel) | **ACCEPTED**: 5.88x Intel, 6.03x AMD, 5.65x Arm; untouched benchmarks flat; tests green. See `exp1-blockscan/README.md` |
| 2 | same helper for `ValueAtPercentilesSlice` | slice variant gains similarly; watch the extra allocation | not started |
| 3 | stack scratch for small percentile lists (drop 1 alloc) | -40 to -80 ns per call | not started |
| 4 | skip `sort.Float64s` when already ascending | tiny | not started |
| 5 | block width 16 instead of 8 | maybe +5% on x86, check Arm | not started |
| replication | second session, same result: map variant 0.83x Intel, 0.70x AMD, 1.01x Arm | confirmed | `GO-BENCH-1.3.0-VS-MASTER-2026-10-08/replication-2026-10-08-second-session` |

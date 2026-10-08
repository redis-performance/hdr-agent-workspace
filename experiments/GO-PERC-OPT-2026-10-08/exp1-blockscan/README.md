# EXP-1: blocked skip-scan for `Histogram.ValueAtPercentiles` (map variant)

Code: branch `perf/percentiles-blockscan` (commit `2415d86`) on the fork, patch in `exp1.patch`. A = master `1608007`, B = EXP-1.
Same-session A/B on each machine (pinned CPU 2, ABBA, 7 repetitions, gofmt + vet + full `go test` clean on both refs first).
`A/B` = ns(A)/ns(B): above 1.00x the branch is faster.

| Benchmark (map variant, 4 percentiles, 1M-sample lognormal) | Intel | AMD | Arm |
|---|---:|---:|---:|
| `ValueAtPercentiles` master -> EXP-1 | 9.85 -> 1.67 us (**5.88x**) | 6.82 -> 1.13 us (**6.03x**) | 11.22 -> 1.99 us (**5.65x**) |
| `ValueAtPercentile` (single, untouched) | 0.98x | 1.00x | 1.01x |
| `ValueAtPercentileGivenPercentileSlice` (4 singles, untouched) | 0.99x | 1.00x | 0.98x |
| `RecordValue` (untouched) | 1.00x | 1.00x | 1.00x |

Untouched benchmarks stay within their spreads (6 to 26%), so no regression is visible there. The speedup is far outside the spread of the
fast variant (5.5 to 37%). Allocation count and size were not changed by EXP-1 (192 B, 2 allocs).
The earlier v1.3.0 baseline (8.06 / 4.73 / 11.32 us on Intel / AMD / Arm) came from other sessions, so against v1.3.0 this is roughly
4.8x / 4.2x / 5.7x faster, indicative only.

New test `TestValueAtPercentilesMatchesSingle` compares every map result with the independent single-percentile call over 5 geometries x 40
random histograms (single value, few values, 20k skewed values), duplicates, 0, 100, over 100 and negative percentiles.
Result: **accepted** pending an adversarial review of the diff before any upstream PR.

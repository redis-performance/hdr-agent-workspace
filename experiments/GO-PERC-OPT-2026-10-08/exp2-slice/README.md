# EXP-2: blocked skip-scan for `Histogram.ValueAtPercentilesSlice`

Branch `perf/percentiles-slice` (commit `026fee8`) stacked on EXP-1 (PR #115). A = `408c962` (EXP-1 plus the two new benchmarks only),
B = `026fee8`. Same method as EXP-1 (pinned CPU 2, ABBA, 7 repetitions; gofmt, vet and full `go test` clean on both refs).
`A/B` = ns(A)/ns(B): above 1.00x the branch is faster. 4 percentiles, 1M-sample lognormal histogram.

| Benchmark | Intel | AMD | Arm |
|---|---:|---:|---:|
| `SliceSorted` input (50, 95, 99, 99.9) | 5.12 -> 1.53 us (**3.35x**) | 3.59 -> 0.98 us (**3.66x**) | 7.35 -> 1.78 us (**4.13x**) |
| `SliceUnsorted` input (99, 50, 99.9, 95) | 5.09 -> 1.60 us (**3.19x**) | 3.57 -> 1.05 us (**3.39x**) | 7.25 -> 1.88 us (**3.87x**) |
| allocations per call (Go 1.27.1) | sorted 4 (120 B) -> 1 (32 B); **unsorted unchanged at 4 (120 B)** (see correction) | same | same |

Spread of B on Intel and Arm is wide for the sorted case (39 to 40%) but the gain is 3x or more, far outside it. **Correction (2026-10-08, PR #116 review):** the
raw B files show unsorted input still at 4 allocs / 120 B; only sorted input fell to 1. `sort.SliceStable` made `order` escape, and on
Go 1.23 (`go.mod`/CI) unsorted rose from 5 to 6. PR #116 commit `b3be425` fixed it (`slices.SortStableFunc` plus an in-place sort of
the ranks): Go 1.23 sorted 2 / unsorted 3 allocs vs master 5; Go 1.26 1 / 1 vs 4 at 4 percentiles. Unsorted timings here predate that fix.
New test `TestValueAtPercentilesSliceMatchesSingle` compares each result with the single-percentile call over 4 geometries x 40 random
histograms, sorted, shuffled and duplicated inputs, and checks the argument is not modified. Result: **accepted**.
Plan: open the upstream PR once EXP-1 (#115) is merged, rebased onto master.

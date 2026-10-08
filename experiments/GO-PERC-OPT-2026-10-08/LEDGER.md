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
| 2 | same helper for `ValueAtPercentilesSlice` (branch `perf/percentiles-slice`, commit `026fee8`, stacked on EXP-1; baseline = `408c962` which only adds the benchmarks) | sorted-input slice call gains like the map one; unsorted keeps its sort but drops the per-element loop | **ACCEPTED**: 3.35x Intel, 3.66x AMD, 4.13x Arm (sorted); 3.19x / 3.39x / 3.87x (unsorted); allocs 4 -> 1 for sorted input only (unsorted fixed later in PR #116 `b3be425`, see below). See `exp2-slice/README.md` |
| 3 | stack scratch for small percentile lists (drop 1 alloc) | -40 to -80 ns per call | **partly moot** on Go 1.25+ with 4 or fewer percentiles (scratch on the stack, 1 alloc left); not on Go 1.23 or 5+ percentiles (2-3 allocs); the map variant still allocates the map and targets (2 allocs), untested |
| 4 | skip `sort.Float64s` when already ascending | tiny | not started |
| 5 | block width 16 instead of 8 | maybe +5% on x86, check Arm | not started |
| replication | second session, same result: map variant 0.83x Intel, 0.70x AMD, 1.01x Arm | confirmed | `GO-BENCH-1.3.0-VS-MASTER-2026-10-08/replication-2026-10-08-second-session` |

Upstream: EXP-1 is [HdrHistogram/hdrhistogram-go#115](https://github.com/HdrHistogram/hdrhistogram-go/pull/115) (opened 2026-10-08, awaiting review).

## Upstream review of EXP-1 (PR #115), 2026-10-08

A 4-agent adversarial review (equivalence, performance claims, tests/docs, robustness) of [PR #115](https://github.com/HdrHistogram/hdrhistogram-go/pull/115)
at `2415d86` found no result difference from master on valid histograms (68,000 differential cases, 45 s differential fuzz) and
confirmed the fleet table from the raw files (28 samples per build per machine). Fixed on the PR branch in `d02b1e0` (tests only):
the scalar tail of `scanTargets` was untested (it runs only for zero-digit Import/decoded geometries; six planted tail bugs survived
the suite, all now fail), a test pins that on snapshots failing `Validate` (wrapped total) the map variant now matches
`ValueAtPercentile`, and `FuzzPercentileQueries` compares the map variant with the single path. The PR body was corrected: the
workspace link (now `redis-performance/hdr-agent-workspace`), the claim that `Import` keeps the total within int64, speed-ratio
wording and sample counts. Round 2 review and CI are running. Note for EXP-2: moving `ValueAtPercentilesSlice` onto `scanTargets`
also removes the map/slice disagreement on wrapped-total imports.

**Merged 2026-10-08:** PR #115 squash-merged to upstream `master` as `f072b62` after three review rounds (4/4 ready at
`3854e80`; production logic identical to the benchmarked `2415d86`). Round 2 corrected an over-claim from round 1: on
snapshots failing `Validate` (wrapped total) results are unspecified, not "equal to `ValueAtPercentile`"; the PR now has a
bounds test there instead. Test-only commits on top: `d02b1e0`, `3854e80`. `exp1.patch` in this folder holds only the
benchmarked code and the original test, not those later tests. Base for EXP-2 is now `f072b62`.

EXP-1 merged as #115 (`f072b62`, 2026-10-08 08:44Z). EXP-2 rebased on it (branch `perf/percentiles-slice-pr`, `76961f6`; gofmt, vet and tests green on Intel, AMD, Arm) and opened as [HdrHistogram/hdrhistogram-go#116](https://github.com/HdrHistogram/hdrhistogram-go/pull/116), awaiting review. Its timings are the pre-rebase A/B in `exp2-slice/` (same code).

## Upstream review of EXP-2 (PR #116), 2026-10-08

Round 1 (4 agents) at `76961f6`: results identical to master (200k histograms, 800k percentile lists), but three blockers.
CI lint failed (SA1019 `rand.Seed` in the new benchmark helper). The "4 -> 1 allocations for both inputs" claim was false
for unsorted input: the fleet's own raw B files show 4 allocs / 120 B, and on Go 1.23 (`go.mod`/CI) it regressed from 5 to 6.
The cause was `sort.SliceStable` (its interface makes `order` escape) plus a separate `sorted` copy. The data link 404'd.
Fixed in `b3be425`: `slices.SortStableFunc`, then `slices.Sort(targets)` in place (equal ranks are interchangeable).
Allocations per call, 4 percentiles: Go 1.23 master 5/152 B -> sorted 2/64 B, unsorted 3/96 B; Go 1.26 4/120 B -> 1/32 B for
both. Also `// nolint` on the helper; the fuzz slice check records a second sample so the unsorted path runs. **The unsorted
timings in this ledger predate `b3be425` and need a fleet re-run** (the PR body says so). Round 2 and CI are running.
Round 2 at `b3be425`: 3 of 4 ready. The fourth found that on wrapped-total imports (snapshots failing `Validate`) the slice
variant's results change from master (unspecified input; they now always equal the map variant in a 20k probe). Fixed in
`8460179`: the PR body discloses it, the wrapped-import bounds test covers the slice variant, the fuzz check runs sorted and
unsorted lists with a NaN seed, and a code comment no longer over-claims stack allocation. Round 3 running.

**Merged 2026-10-08:** PR #116 squash-merged to upstream `master` as `186f8b9` after three review rounds (4/4 ready at
`8460179`; CI 20/20). Upstream `master` now carries EXP-1 and EXP-2. Open follow-ups: re-time the unsorted slice path on the
fleet (code changed after the timings); the map variant can pass non-ascending ranks to `scanTargets` when a NaN percentile
meets a wrapped total (unspecified input, #115 code, not filed).

## Packed last-hit write cache: PR #117 opened, needs a fleet re-run (2026-10-08)

The August fork PR fcostaoliveira/hdrhistogram-go#1 (one-entry last-hit cache in `PackedHistogram.RecordValues`) was stale: it
targeted the pre-merge `feat/packed-histogram` branch. The user accepted its trade-off (bursty writes 30-59% faster, random
writes 2.4-9.4% slower in August). Rebased onto master `186f8b9` and opened upstream as
[PR #117](https://github.com/HdrHistogram/hdrhistogram-go/pull/117) (`b0658dc`, author fcostaoliveira); fork #1 closed as superseded.
Only conflict: one constructor line. The cache is self-validating (`idx[lastPos] == ci`), so it is safe after inserts, Reset,
Compact, Merge, Clone and DecodePacked; `TestPackedLastHitCacheStaysCorrect` re-records the cached value after each and fails
without the recheck. **Wanted from the fleet session:** re-run the packed write benchmarks (clustered, hot90, random) for
`186f8b9` vs `b0658dc`, pinned ABBA, on Intel, AMD and Arm. The PR says it will not merge before those numbers exist.
PR #117 review: round 1 at `b0658dc` found the cache correct but blocked on a false comment (Clone copies the cache, it does not
zero it). Fixed in `544af54` (also dropped the redundant sentinel, fuzzed merge staleness, more tests). Round 2: 4/4 ready.
**Held for the fleet re-run above** (compare `186f8b9` vs `544af54` now, not `b0658dc`).
**Merged 2026-10-08:** PR #117 squash-merged to upstream `master` as `687f303`, ahead of the fleet re-run, by the user's decision.
The re-run is still wanted: `186f8b9` (before) vs `687f303` (after), clustered, hot90 and random packed write patterns, Intel,
AMD and Arm. If random writes cost clearly more than the August +2.4-9.4%, revisit the cache.

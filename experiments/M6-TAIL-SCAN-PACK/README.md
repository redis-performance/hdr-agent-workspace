# M6 experiment pack: tail-scan candidates for `hdr_value_at_percentile`

Prepared for the user to run on their Apple M6. Nothing here was benchmarked, and nothing was committed to the
HdrHistogram_c submodule. Background and reasoning: [`../VALKEY-5024-TAIL-SHORTCUT-PLAN/README.md`](../VALKEY-5024-TAIL-SHORTCUT-PLAN/README.md).
Baseline for everything is the **0.12.1 tag** (`30e9ce6`), exported with `git archive`, so the submodule's state does not matter.

## Read this first: both candidates break one existing 0.12.1 test

Verified locally (gcc, Release, `ctest`): baseline 9/9 pass; **candidate A and candidate B each fail 1/9**,
`hdr_histogram_test` → `test_value_at_percentiles_unresolved_targets` ("singular != plural for unresolved target").
That test sets `total_count = 4` with one recorded value and requires the single call to return 0 for the unresolved
p100, as the batch call does. The shortcut returns the top bucket instead, because it trusts `total_count - counts[max]`.
This is inherent, not a bug in the patch: the shortcut is exact only when `total_count == sum(counts)`, and checking that
costs a full scan, which removes the gain. So a PR would have to **change the 0.12.1 contract for inconsistent histograms**
(a maintainer decision, and the same test would need changing, in the batch call too). Treat any M6 win as "interesting,
needs that decision", not "ready to PR". The M6 timing is still worth taking to know whether the gain justifies the argument.

## What is in the pack

| File | What |
|---|---|
| `candidate-A-capped-tail-walk.patch` | Walk down from the top bucket for at most `HDR_TAIL_WALK_CAP` (default 256) buckets; fall back to the normal scan if the answer is not found. ~35 lines, one function. |
| `candidate-B-top-bucket-shortcut.patch` | Valkey's form: if the rank falls in the top recorded bucket, return it directly. One comparison, ~20 lines. |
| `bench_tail.c` | Out-of-tree timing (the repository drivers stay the immutable referee). Shapes: `body1M`, `body1M_outlier`, `valkey200_outlier`, `valkey200`, `band_far`; single calls at p50, p90, p99, p99.9, p100; best of 7. |
| `tail_dump.c` | Differential test: ~2,400 histograms (empty, zeros only, single bucket, outlier, huge counts, atomic-recorded, three rotations each, 18 percentiles incl. 0, 100, >100, ±inf, NaN, rank-boundary sweep) plus 160 hostile states. Output is diffed against 0.12.1. |
| `run_m6.sh` | Builds baseline, A and B; runs the differential under ASan+UBSan and stops on any difference outside the known hostile cases; then ABBA timing x3 per candidate with the repository's QoS shim; writes `results/<timestamp>/`. |
| `summarize.py` | Median ns per case, speed = base/candidate (>1 is faster), spread of runs, CSV. |

Both guards apply only when `normalizing_index_offset == 0`, `0 < max_value <= highest_trackable_value`, `total_count <= 2^53`,
and the top bucket's count is positive and at most `total_count`; otherwise the normal scan decides.

## Correctness evidence so far (local, x86-64, gcc 13; no timing)

- Differential vs 0.12.1: **0 differences** on every plain, rotated, atomic and zero-heavy histogram, and on hostile
  cases 2 to 7 (stale max, out-of-range max, negative count, top count INT64_MIN, ...). The **only** differences are the
  two hostile cases where `total_count` disagrees with the counts (larger by 7, smaller by 3), 20 lines each: exactly the
  contract change above.
- ASan + UBSan: both candidates clean (exit 0, no reports).
- Mutation check against candidate B (differential must fail): ignoring the offset guard (28 lines differ) and an off-by-one
  on the rank (215 lines) are **killed**. Dropping the `cm <= 0` guard is killed by UBSan (`50 - INT64_MIN` signed overflow).
  Not killed: removing the `max_value <= highest_trackable_value` check (the index bound check catches it first; it protects
  index arithmetic, not results) and removing `cm > total` (also an overflow guard; needs a count above the total).
- A concurrency review (read-only, by reading code) says racing atomic writers can make the shortcut see `max_value` behind the
  counts; the existing scan is already racy under writers (documented in the header). No stress test was run.

## Run it on the M6

```sh
cd experiments/M6-TAIL-SCAN-PACK
./run_m6.sh                     # uses ../../HdrHistogram_c (needs tag 0.12.1; run `git -C ../../HdrHistogram_c fetch upstream --tags` first)
BLOCKS=5 ./run_m6.sh /path/to/other/HdrHistogram_c
EXTRA_CFLAGS=-DHDR_TAIL_WALK_CAP=64 ./run_m6.sh      # vary candidate A's cap (also try 1024)
```
Needs Apple clang, `git`, `patch`, `python3`. About 1 to 2 minutes per timing run, 12 runs by default. Keep the Mac on AC power and close
other apps; QoS user-interactive is a scheduler request, not core pinning, as in `../C-M6-MASTER-2026-10-02`. No other benchmark at the same time.
`results/` is untracked: send me `summary.txt`, `summary.csv`, `machine.txt`, `correctness.txt` (or commit them under this folder and I will read them).

## How to read the result (decision rule from the plan)

- Candidate counts as interesting only if the high-percentile rows it targets (`p99.9`, `p100`, and `valkey200_outlier`) are at least +2% (speed >= 1.02) and
  `p50`/`p90` do not regress by more than 1% (speed >= 0.99), with spreads smaller than the effect.
- Expected shape, not a result: B should help `valkey200_outlier` p99.9/p100 and `body1M*` p100 and be flat elsewhere; A should add some cost on `p50` (a failed walk before the
  normal scan) and help wherever the answer is within the cap of the top bucket. If neither wins by 2% on M6, park it: M6 is also a different codegen target
  (no AVX2 dispatch, scalar block scan), so an M6 win would still need x86 AVX2 and aarch64 Linux fleet numbers before a PR, and the contract question.
- A and B differ by one more branch in the hot path; if B alone gets the gain, prefer B.

## Not included (parked, with reason)

- Skipping leading zero buckets: the block scan already crosses zeros quickly and the zero-count traps (`min_value` ignores recorded zeros) make it risky for little gain.
- Caching tail state: needs struct state and breaks the layout.
- The batch call `hdr_value_at_percentiles`: already 15 to 20x faster than 0.11.10, and the tail shortcut does not carry over to its ascending cursor.

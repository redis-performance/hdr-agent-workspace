# Post-merge C optimization check — 2026-09-30

Active comparison. No optimization is accepted by this round yet; the
workspace's accepted submodule pointer and experiment counts remain unchanged.

## Fixed source points

| Role | Commit | Meaning |
|---|---|---|
| Previous stable release | `18c7a324383dded1451d15621cd018b0048057d0` | upstream tag `0.11.10` |
| Previous master before batch merges | `4395fa0254d56ebacd81cd82e23fda346e1651c2` | includes #138/#139 read-scan work, excludes #140/#141 batch work |
| Latest master | `e4e8b0a41b4af56fddce5eebd1d0a53f29a0e988` | includes #140 and #141 |
| Future candidate, correctness reference | `bcb5c1f78f3ee50aaf33fb4898eb1c6bab73de13` | open #158, removes AVX2 negative-count branch and rejects negative records |

All four have isolated, detached C worktrees. The stable release remains an
unchanged reference rather than being merged into newer source: it is already
an ancestor of master, and merging it would not create a new comparison state.
The two immutable project benchmark drivers are byte-identical from 0.11.10
through current master.

## Stage 1 — build and CTest

AppleClang 21 / arm64 RelWithDebInfo, logging enabled, benchmark drivers built:

| Point | CTest | Result |
|---|---:|---|
| 0.11.10 stable | 5/5 | PASS |
| pre-batch master | 5/5 | PASS |
| latest master | 5/5 | PASS |
| #158 future candidate | 5/5 | PASS |

All four builds used the same CMake options and compiler. There is no source
change or candidate acceptance from this step.

## Immutable referee — first interleaved arm64 round

AppleClang 21, release builds, sequential runs in the order pre-batch,
master, stable, master, pre-batch, stable. Each write driver invocation contains
100 iterations of 400 million records; each read invocation contains 20 timed
runs. All six read checksums were exactly `17401860284404480`.

| Point/run | Write median (M records/s) | Single-read best/mean (M queries/s) |
|---|---:|---:|
| pre-batch 1 | 713.41 | 0.22 / 0.22 |
| master 1 | 710.78 | 0.22 / 0.22 |
| stable 1 | 709.56 | 0.20 / 0.20 |
| master 2 | 710.33 | 0.22 / 0.22 |
| pre-batch 2 | 709.89 | 0.22 / 0.22 |
| stable 2 | 710.26 | 0.19 / 0.19 |

Raw [referee outputs](bench-results/) are retained. The pre-batch write median
moved from 713.41 to 709.89 M/s without a source change, so the apparent
sub-1% write differences are measurement drift. The immutable read driver
rounds to 0.01 M/s; stable-to-master read improvement is directional only and
needs a higher-resolution paired probe and native x86-64 qualification.
Pre-batch and master have indistinguishable singular-read results, as expected
for a batch-only change.

## Supplemental semantic gate

The historical arm64 supplemental oracle validates 2,700 singular checks on
pre-batch/master/#158. Its 24 nonempty ordered-batch equivalence groups pass
on all four points, including stable. Full batch validation on pre-batch and
master passes 52,800 oracle checks, 37,275 singular-equivalence checks, and
9,030 edge checks. Stable fails the broader rotated/signed-state oracle
(`singular oracle mismatch`; full batch: `batch/singular equivalence`), a
historical semantics gap rather than a reason to discard the nonrotated,
positive-percentile common benchmark domain. Do not use those failing states
for a performance comparison or infer a current-master regression from them.

## Measurement contract

- Run release CTest first for each source point. Run sanitizer and no-logging
  CTest for code selected for any new optimization or upstream PR.
- Compare the immutable write and single-percentile drivers, and a separately
  validated ordered-batch harness for #140/#141, in interleaved same-session
  measurements. Keep raw output and checksum equivalence.
- Run read/write profiles on the latest master to identify the next bottleneck.
  A surprising new bottleneck is a partial win requiring follow-up.
- This workstation is Apple silicon and has AppleClang only; it cannot execute
  the AVX2 branch or satisfy the mandatory native x86-64 gcc/clang performance
  and profile gates. Arm64 results are directional, not a MERGE-READY speed claim.
- Preserve the parent submodule pointer until a candidate passes both mandatory
  benchmark and profile gates and adversarial review.

## Four-percentile list benchmark and supplemental batch gate

The project's unchanged Google Benchmark case
`BM_hdr_value_at_percentiles_given_array/3/86400000` queries
`{50,95,99,99.9}` in one API call over a 10-million-record gamma workload.
It was run stable/master/master/stable in one AppleClang 21 arm64 session,
five timed repetitions per invocation. Median real time per list call:

| Revision/run | ns per four-percentile list | Thousands of lists/s |
|---|---:|---:|
| Stable 1 | 20,846 | 48.0 |
| Master 1 | 1,221 | 819.1 |
| Master 2 | 1,220 | 819.5 |
| Stable 2 | 20,894 | 47.9 |

This is a ~17.1× Apple arm64 list-call throughput improvement, consistent
with the merged #140/#141 batch design. [Raw JSON/output](list-results/) has
genericized host labels. Google Benchmark warns that its own library was built
as DEBUG; the large difference is independently corroborated by the
separately compiled, [validated batch probe](batch_probe.c). The chart uses
these numbers, but native x86-64 and gcc/clang qualification is still pending.

The supplemental probe validates batch outputs against repeated single calls
on deterministic, nonrotated, nonnegative histograms for four shapes (sparse
and dense, 7 and 32 percentiles). Stable, pre-batch master, latest master,
and #158 all produced the same four fingerprints. Two interleaved runs each
for stable/pre-batch/master yielded these median ns per **list call**:

| Shape | Stable | Pre-batch | Latest master | Future #158 (one run) |
|---|---:|---:|---:|---:|
| Sparse, 7 | 32.2–32.7 | 34.8–34.9 | 14.7–14.8 | 14.2 |
| Sparse, 32 | 47.4–47.7 | 54.0–54.7 | 40.9–41.6 | 40.4 |
| Dense, 7 | 42,222–42,358 | 46,832–46,988 | 2,450–2,452 | 1,307 |
| Dense, 32 | 42,384–42,570 | 47,068–47,154 | 2,504 | 1,439 |

The [raw probe output](batch-results/) also records repeated-single control
times, calibration iterations, and fingerprints. The future #158 branch's
apparent ~1.8× dense-list gain on arm64 comes from removing the scalar
negative-count scan check. Its decoder/hostile-count semantics and cross-CPU
performance remain review gates; the one-run figure is a lead, not an
accepted optimization. The source point was not merged into the workspace
submodule.

## Latest-master Apple profiles

Apple `sample` on the immutable drivers collected 8,689 read and 7,781 write
main-thread stacks over 10 seconds each. In the read profile, 8,688/8,689
main-thread samples were in `hdr_value_at_percentile`. In the write profile,
7,260/7,781 samples were in `hdr_record_value` (520 in driver setup/loop).
The expected hot paths remain dominant. Apple `sample` did not provide
hardware-counter or inner-loop breakdown; no new bottleneck is established
from these coarse profiles. Raw reports are held locally because they include
host-specific paths and identifiers. Native Linux `perf` and x86 gcc/clang
profiles remain pending for any new source candidate.

**Round decision:** merged master shows a large batch-list improvement on
Apple arm64 and no reliably distinguishable write change against 0.11.10.
No new source candidate passes the required two-step acceptance gate here;
experiment counts and the accepted workspace submodule pointer are unchanged.

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

Next: build/test the four points, run same-session baselines, then profile the
latest master and log any candidate/no-starter decision.

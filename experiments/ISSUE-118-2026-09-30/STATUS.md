# Issue #118 — counter-total overflow and macOS CI audit

Updated 2026-09-30. This is a correctness/hardening follow-up, not an accepted
optimization experiment; accepted/rejected counts and the workspace submodule
baseline remain unchanged.

## Issue #118

- Upstream issue: https://github.com/HdrHistogram/HdrHistogram_c/issues/118
- Base: upstream `main` at `1dfc67e946a225fbaab16811b343710cf3a10df5`.
- Fork branch: `fcostaoliveira:fix/dense-counter-total-overflow` at
  `a28031949c99ff630708de8885ce382ed746f8c5` (pushed without rewriting history).
- The old reset path used signed addition for decoded positive counts. A valid
  compressed stream with three adjacent `2^62` counts made that sum overflow.
  The new private checked reset detects this, saturates the public void reset's
  observed total at `INT64_MAX`, and makes V0/V1/V2 decode return `EOVERFLOW`
  without publishing a partial histogram. Count buckets remain unchanged.
- The implementation preserves normalized-index rotation, the existing public
  reset signature, and an existing destination on failed decode. It does not
  address the separate record-path count increment overflow, including
  `hdr_add()` when a representable decoded histogram is merged into an existing
  destination, or the separate codec `INT64_MIN` negation finding.
- Exact-head arm64 validation: release CTest 7/7, ASan+UBSan CTest 7/7,
  logging-disabled CTest 5/5. Evidence:
  [results](../PR-REVIEW-2026-09-29/issue-118-prototype-final/results.json),
  [release](../PR-REVIEW-2026-09-29/issue-118-prototype-final/release.log),
  [sanitizer](../PR-REVIEW-2026-09-29/issue-118-prototype-final/asan.log),
  [no logging](../PR-REVIEW-2026-09-29/issue-118-prototype-final/nolog.log).
- Structured deterministic fuzzer: 10,000 cases, passed
  ([log](../PR-REVIEW-2026-09-29/issue118-structured-fuzz.log)).
- Fork [exact-head CI](https://github.com/fcostaoliveira/HdrHistogram_c/actions/runs/36696475571):
  completed successfully, including Windows, both existing macOS jobs, and
  Linux ASan+UBSan. [Native Linux ClusterFuzzLite batch](https://github.com/fcostaoliveira/HdrHistogram_c/actions/runs/36696562555)
  passed for 600 seconds per sanitizer. It uses the same source/test/fuzzer
  blobs as the proposed PR head, with only the workflow time budget changed.
- [Upstream PR #159](https://github.com/HdrHistogram/HdrHistogram_c/pull/159)
  opened with the [review body](PR-BODY.md). Upstream PR CI and final
  commit-specific review comment are pending at the new test-only head.
- [Exact-head native batch repeat](https://github.com/fcostaoliveira/HdrHistogram_c/actions/runs/36698338636)
  is running after the test-header declaration cleanup. The earlier 600-second
  batch passed at production-identical code; this repeat confirms the exact
  test/fuzzer bytes.

## Current macOS CI coverage

The [current C CI matrix](https://github.com/HdrHistogram/HdrHistogram_c/blob/1dfc67e946a225fbaab16811b343710cf3a10df5/.github/workflows/ci.yml)
has two macOS build/test jobs: Debug and RelWithDebInfo, logging enabled.
Both matrix entries say `arch: x64`, but both use `macos-latest` as the runner;
for public repositories that label currently selects Apple silicon. The
matrix label is an environment value, not an architecture assertion. The
workflow explicitly excludes macOS x86, minimal CMake, and logging-disabled.
The only ASan+UBSan CI job is Linux; ClusterFuzzLite is Linux-only. Thus macOS
Intel, no-logging builds, and macOS sanitizer behavior are not exercised.

The [latest upstream main CI](https://github.com/HdrHistogram/HdrHistogram_c/actions/runs/36691467208)
passed at `1dfc67e`. The [latest weekly batch failure](https://github.com/HdrHistogram/HdrHistogram_c/actions/runs/36401899117)
predates the merge of the timestamp sanitizer fix (#154), so it is not
evidence that today's main still fails; the next weekly batch remains to be
observed.

Recommended follow-up: explicitly pin Intel (`macos-15-intel`) and Apple
silicon (`macos-15` or a documented ARM64 label), print/assert `uname -m`
in each job, run logging-enabled and logging-disabled CTest on both, and add
an Apple-silicon ASan+UBSan CTest job. Keep the existing Linux 32-bit and
sanitizer/fuzz jobs. GitHub's current runner mapping is documented at
https://docs.github.com/en/actions/reference/runners/github-hosted-runners.

The CI-only fork branch `ci/explicit-macos-coverage` implements this matrix
and sanitizer jobs at `9361ee5c0a1a8974a413e7549e7047a8738f3237`.
[Exact-head fork CI](https://github.com/fcostaoliveira/HdrHistogram_c/actions/runs/36699075113)
passed all 25 jobs, including the eight architecture-pinned macOS build rows
and ASan+UBSan on both architectures. [Upstream PR #160](https://github.com/HdrHistogram/HdrHistogram_c/pull/160)
is open; upstream fuzz check and review comment are pending.

# ARM Clang percentile investigation — complete

The experiments and local review package are complete. **Candidate; not accepted. Draft [PR #167](https://github.com/HdrHistogram/HdrHistogram_c/pull/167) is open**
at the user's explicit instruction after disclosure of outstanding gates. See [results and limits](RESULTS.md), [review gates](REVIEW.md),
[source/test patch](upstream-candidate.patch) and [machine-readable evidence](results.json).

The narrow Clang AArch64 pragma improves the full O3 read driver 2.120x, with
recording throughput effectively unchanged. All tested GCC/x86 executable text,
and ARM Clang Os text, matches the baseline exactly. Native sanitizer/fuzz gates
pass. Short crossings can cost 0.6–0.7 ns more, roughly 11%; this is not an
always-faster change. The general shared-tail alternative was rejected for an
AMD Clang read regression. All failed diagnostics and stopped runs are retained.

Required Opus 4.8 review could not run because the account hit its weekly limit.
No MERGE-READY verdict or accepted submodule-pointer change. The candidate
branch was pushed as `dfd5121`; draft PR #167 targets upstream `57db422`.
CI, fuzzing and automated review started; results were pending at opening.
Current-upstream application passes local GCC/no-log/sanitizer checks; performance
qualification remains at the user's PR #158 release-candidate pin. Revalidate the
final PR head and obtain platform CI/review before marking the PR ready and accepting it.

**Open item (2026-10-01): Apple Clang is unmeasured.** PR #167's guard (`__aarch64__ && __clang__`)
also covers Apple Clang on Apple silicon, but all measurements are Linux AArch64 Clang 18.1.3.
Instructions for a session with an Apple-silicon Mac: [APPLE-CLANG-TASK.md](APPLE-CLANG-TASK.md).

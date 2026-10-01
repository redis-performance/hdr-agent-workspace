# ARM Clang percentile investigation — complete

The experiments and local review package are complete. **Candidate; not accepted,
not published.** See [results and limits](RESULTS.md), [review gates](REVIEW.md),
[source/test patch](upstream-candidate.patch) and [machine-readable evidence](results.json).

The narrow Clang AArch64 pragma improves the full O3 read driver 2.120x, with
recording throughput effectively unchanged. All tested GCC/x86 executable text,
and ARM Clang Os text, matches the baseline exactly. Native sanitizer/fuzz gates
pass. Short crossings can cost 0.6–0.7 ns more, roughly 11%; this is not an
always-faster change. The general shared-tail alternative was rejected for an
AMD Clang read regression. All failed diagnostics and stopped runs are retained.

Required Opus 4.8 review could not run because the account hit its weekly limit.
No MERGE-READY verdict, upstream PR, push, or accepted submodule-pointer change.
Current-upstream application passes local GCC/no-log/sanitizer checks; performance
qualification remains at the user's PR #158 release-candidate pin. Revalidate the
final PR head and obtain platform CI/review before publication.

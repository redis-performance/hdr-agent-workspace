# ARM Clang percentile regression — 2026-10-01

User authorized a causal experiment and preparation for an upstream fix to the
Clang ARM64 O3 regression. [Full report](../experiments/C-ARM-CLANG-SCAN-2026-10-01/RESULTS.md),
[review gates](../experiments/C-ARM-CLANG-SCAN-2026-10-01/REVIEW.md),
[complete patch](../experiments/C-ARM-CLANG-SCAN-2026-10-01/upstream-candidate.patch).

Baseline is PR #158 d21d084. The narrow fix is `#pragma clang loop unroll(disable)`
on the crossing-block loop, guarded by `__aarch64__ && __clang__`. Four lines;
unit test adds dense/isolated/empty/rotated crossing coverage. No API/layout/
allocator/iterator change and neither immutable benchmark driver is edited.

Full pinned ARM Clang O3 read: 189.118 → 89.216 seconds (2.1198x); recording
ratio 1.0036 (effectively flat). Os unchanged, ~83.83 seconds. Fixed O3 remains
6.4% longer than Os. GCC/x86 and ARM Clang Os immutable executable `.text`
sections match exactly. All 24 native configurations pass CTest with boundary
tests; native ASan/UBSan all three runners and ARM record/decoder fuzz pass.
Both vectorizers truly disabled after the final O3 flag: scalar-only probe gain
~1.315x, with a three-add rather than four-add recurrence. Ordinary patch uses
independent SIMD reduction. ARM profile IPC 2.76 → 6.09 supports the attribution.

Do not claim always faster: early crossing bucket 3 is ~4.87 → 5.45 ns; worst
observed early cases lose ~11% throughput (~0.6–0.7 ns/query). The general
shared-tail refactor is rejected: AMD Clang full read 0.8527x, byte-identical
AVX2 function moved 16 bytes. Do not cherry-pick `candidate.patch`; the actual
candidate is `narrow-candidate.patch` / combined `upstream-candidate.patch`.

The patch applies cleanly to upstream 57db422; local GCC/no-log/sanitizer gates
pass there. Performance qualification is still at d21d084. Final PR head/CI must
be validated before acceptance. The user subsequently instructed opening: draft [PR #167](https://github.com/HdrHistogram/HdrHistogram_c/pull/167)
is now open, head `dfd5121`, base `57db422`. CI/review started; no acceptance
or MERGE-READY claim. See PR.json and PR-BODY.md in the experiment directory.

AGENTS requires Opus 4.8 and the review skill requires MERGE-READY. The exact
model invocation returned the account's weekly-limit message (reset October 6),
without a review. Codex's evidence/checkpoint is not an Opus verdict. Required
review, final-head qualification and the disclosed short-scan tradeoff remain.

All owned fleet jobs completed/stopped, and locks are released. Connection
details remain outside git. Existing sanitized inventories/pinning protocol
apply. Source candidates remain isolated; pre-existing submodule state and
acceptance counts are preserved. Parent report/runner changes committed locally.

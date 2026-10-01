# Upstream-readiness checkpoint

Verdict: **NEEDS WORK — draft [PR #167](https://github.com/HdrHistogram/HdrHistogram_c/pull/167) open; no optimization accepted.**

The user explicitly instructed opening after being informed of these outstanding
gates. The draft preserves them and does not assert MERGE-READY.

The reviewable candidate is [upstream-candidate.patch](upstream-candidate.patch),
four guarded source lines plus one boundary test. It applies to upstream
`57db4223d1a356b21dbece675bce812419920c58`. Performance is qualified at the user's
release-candidate pin, PR #158 `d21d0843b492023077553b3eba26b3efa16c15f5`.
The broad refactor in `candidate.patch` is rejected, not part of this candidate.

## Correctness review by Codex

| Check | Result |
| --- | --- |
| A1 offset-aware path | PASS: no accessor, fallback or normalization change; native offset tests pass. |
| A2 atomic twins | PASS: neither atomic nor ordinary recording code is changed. |
| A3 bounds/overflow | PASS: arithmetic, types, bounds and comparisons are unchanged. |
| A4 signed shifts | PASS: no shift is introduced. |
| A5 empty histogram | PASS: new empty-histogram check and existing suites pass. |
| A6 codec/layout | PASS: no struct/codec/ABI change; native log suites and ARM fuzz runs pass. |

## Gates and portability

| Gate | Evidence / limit |
| --- | --- |
| Native GCC + Clang | All 24 base/candidate O3/Os configurations pass CTest with the boundary test. |
| Log disabled | Local Clang no-log passes, including the clean current-upstream application. |
| ASan + UBSan | Local and all three native candidates pass; current-upstream local application passes. |
| Fuzz | ARM candidate: 84,948 record/query and 19,593,045 decoder executions, no sanitizer errors. |
| Full benchmark | ARM Clang O3 read 2.120×, write 1.0036×; Os read 0.9999×, write 1.0013×. |
| GCC and x86 effects | Both immutable executable text sections byte-identical in every tested unaffected configuration; bounded native probes also saved. Full unchanged-binary measurements were not repeated. |
| Profile | Native samples and disassembly corroborate higher instruction parallelism; IPC 2.76 → 6.09. The remaining limiting resource is not isolated. |
| MSVC/Windows | Guard excludes ordinary MSVC and x86 clang-cl. ARM clang-cl directive support is reasoned, not newly CI-tested. |
| Apple/macOS | AArch64 Clang guard also covers Apple Clang; no new Apple build or timing claim. |
| Final PR base | Patch applies and local correctness gates pass on current upstream. Repeat performance on the final release/PR head after #158/base decisions. |

Style is local and minimal, with no new macro, intrinsic, dependency or public
surface. The guard confines generated-code changes to the observed compiler/
architecture; Os is already byte-identical. The pragma uses Clang's documented
unroll control, rather than relying on an accidental source refactoring effect.

## Required review is unavailable

[AGENTS.md](../../AGENTS.md) specifies:

> Minimum model: Opus 4.8 (`claude-opus-4-8`) for every agent in every phase.

The [upstream review skill](../../.claude/skills/review-hdrhistogram.md) says:

> Call a change "merge-ready" only when all gates pass and no ❌ remains.

AGENTS.md also requires that skill to return **MERGE-READY before any upstream PR**.
The exact requested model was invoked for a preliminary review with tools
disabled. It returned the account's weekly usage-limit message (reset October 6)
without performing a review. This Codex checkpoint is explicitly not a substitute
for that required Opus verdict. No request was sent to a maintainer or reviewer.

## Handoff before marking the draft ready

1. Obtain the required Opus review; give it this patch, RESULTS.md, the raw
   artifacts and the repository review skill. Do not mark the review as passed
   merely because tests pass.
2. Agree on the final PR base around #158, rerun the affected performance check
   on that exact head, and run the required platform CI before acceptance.
3. Include the early-crossing cost prominently: approximately 11% less query
   throughput in the worst sampled short cases, about 0.6–0.7 ns/query. The
   patch meets the measured long-scan/write gate but is not an unconditional
   read-speed win. A reviewer may prefer a follow-up to reduce that cost.
4. Keep the compiler upgrade benchmark protocol. A loop directive constrains
   unrolling; it cannot guarantee the same throughput on every compiler/CPU,
   histogram distribution, LTO setting or executable layout.

The branch was pushed as `dfd5121dd61a8e9d3167bd752ef054da4ae42305` and draft
PR #167 opened against `57db422`. CI, fuzzing and automated review started.
No PR description is presented as approved and no acceptance gate is waived.

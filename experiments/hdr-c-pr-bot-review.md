# HdrHistogram_c PRs — automated-review triage & fixes (2026-09-02)

Campaign to address the automated `claude-pr-review:auto` (github-actions) reviews on the 12
open C PRs (`HdrHistogram/HdrHistogram_c`: #137–141, #144–150). Every bot finding was
**verified against the actual code by a per-PR subagent** (bots can be wrong) before acting.

**Hard rule (user):** never force-push — every change is a **new commit + fast-forward push**;
force-push is reserved for a critical PII/leak only. PR title/body edits via `gh pr edit`;
commit-message-only fixes were skipped (they'd need a force-push).

## Round 1 — accepted findings implemented (12/12 pushed, fast-forward)

- **#147** — real regression the PR itself introduced: `hdr_count_at_value`'s
  `highest_trackable_value` guard returned 0 for values equivalent to a tracked bucket
  (verified empirically 1010→0 vs →1). Dropped the over-guard.
- **#149** — two verified bugs: peek-guard truncated normal linear iteration (1023→992 steps);
  log guard infinite-looped on `log_iter_init(h,0,2.0)`. Fixed (shift-saturating peek; `level<=0`).
- **#150** — big-endian `widen_to_fit` corruption (endian-neutral `load_w`/`store_w`); no-op TU
  for `LOG_REQUIRED=DISABLED`; SOVERSION 6/3/3→7/0/4; drop duplicated externs/macros/doc-refs.
- **#139** clamp OOB prefetch pointer (UB) · **#141** unsigned block-sum · **#146** V0 `word_size`
  guard (crafted-blob ASan-verified) · **#138** naive-reference percentile test · **#137** offset
  test + comment · **#140** `free`→`hdr_close` · **#144** assert AVX2 dispatch ON x86-64 ·
  **#148** `isfinite` + honest test comments.

## Round 2 — deeper bugs the re-review surfaced (6/6 pushed, fast-forward)

- **#141** accumulator now `uint64_t` (the round-1 fix only cast the addends — signed add remained).
- **#149** guard negative iterator init params (negative left-shift UB; revert-verified under UBSan).
- **#150** 32-bit `PK_MALLOC(length*sizeof)` overflow guard.
- **#146** cap V2 `counts_limit` at the encoder bound (crafted blob attempted ~2 GB alloc — verified
  via a `calloc` interposer).
- **#138** drop the vacuous "offset-aware" test wording.
- **#144** assert AVX2 dispatch compiled OUT on i386.

## Bonus (found during the leak cleanup)
- **#145** — a **real library leak**: `hdr_decode_compressed_v0/v1/v2` used `hdr_free(h)` (leaks
  `h->counts`) in the aggregate branch → `hdr_close(h)`. With all test fixtures converted to
  `hdr_close`, LeakSanitizer was unmasked (`detect_leaks=0` dropped); all 5 test binaries 0 leaks.

## Outcome
- **12/12 PRs CI-green** after both rounds. The bot's re-review of round 1 endorsed the fixes
  (e.g. #147 *"both fixes read as correct… the test pins exactly the case a naive bound check gets
  wrong"*; #150 *"additive, well tested, SOVERSION follows the process correctly"*).
- Zero force-pushes; one macOS CI failure on #146 was confirmed **flaky infra** (same commit passed
  macOS in a parallel run).

## Deferred to the maintainer (correctly not auto-decided)
1.0/ABI direction (#95), confirming Java semantics (mean, nextNonEquivalent, p0-plural,
empty-histogram), adding a packed decode fuzz target, factoring the shared V2 codec, gating just
the packed codec (#113), fractional log_base, i386 log-test coverage, and PR-description wording.

## Round 3 + convergence (2026-09-02)

The re-review of round 1 endorsed the fixes but surfaced 2 genuinely-new bugs; round 3 fixed them:
- **#145** `5c79ae5` — guard-before-shift left `cfg->sub_bucket_mask` uninitialized on the reject
  path (a two-step-init caller could read it). Fixed with an entry `memset(cfg,0,...)` (defines
  *every* reject path) + regression test.
- **#149** `9201577` — the `log_base <= 1.0` guard missed NaN/Inf/1e300 → float-cast-overflow UB.
  Strengthened to `!isfinite || >= INT64_MAX || <= 1.0`; revert-verified under UBSan.

**Converged.** All 12 PRs CI-green; every real-bug / actionable bot finding addressed across 3
rounds (20 fixes total), all fast-forward, **zero force-pushes**. The round-3 re-reviews are clean
("core fix is right and minimal", "core overflow fix reads correctly"). Remaining bot points are
all maintainer-territory and left for @mikeb01 / paulorsousa:
- design pushback on #145's defensive `memset` (document the contract vs. drop the test);
- Java-semantics confirmations (mean, nextNonEquivalent, p0-plural, degenerate iterator params);
- refactor suggestions (share the peek/`value_from_index` decomposition; factor the V2 codec);
- optional CI hardening (pin `-DHDR_LOG_REQUIRED=ON` on the sanitizers job; add the sanitizers job
  to branch protection); 1.0/ABI direction (#95); packed fuzz target; commit-message wording
  (can't fix without a force-push).

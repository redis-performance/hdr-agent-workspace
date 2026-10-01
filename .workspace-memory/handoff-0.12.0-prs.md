# Handoff — HdrHistogram_c 0.12.0: two separate PRs

> Saved 2026-10-01 from a prior session whose own file-save was blocked
> (workspace + /tmp writes failed; shell blocked by bwrap). No handoff file was
> created by that session — this is the recovered handoff. **Next: Claude continues it.**
> Status at handoff: no fresh -O3 measurements, no implementation patches, no upstream PRs opened.

## Task: prepare two separate HdrHistogram_c PRs for 0.12.0

### PR 1 — Reject negative decoded bucket counts in legacy formats
- Reject negative decoded bucket counts in legacy (V0/V1) formats.
- **Preserve valid V2 zero-run markers** (do not mistake them for negatives).
- Clean up on failure; leave existing destination histograms **unchanged** on error.
- Add regression tests, sanitizer checks, and codec fuzzing.
- **Coordinate with #159.**

### PR 2 — Add an optional minimal static core target
- Add an optional minimal static *core* target.
- Avoid mandatory zlib / thread discovery for core-only builds.
- Preserve allocator hooks and the existing full-library ABI/defaults.
- Add an optional **AVX2-dispatch disable** switch and embedding docs.

## Procedure / gates (do these first)
1. Read `AGENTS.md` (project instructions / `.claude/CLAUDE.md`) and workspace memory.
2. Refresh upstream PR state (`.workspace-memory/hdr-upstream-prs.md`,
   `check-open-prs-before-raising.md`); re-check open PRs before raising.
3. **Preserve existing workspace changes**; use **isolated branches** (one per PR).
4. Complete the required benchmark/profile gates + adversarial review
   (`.claude/skills/review-hdrhistogram.md` → must return MERGE-READY before any PR).

## Previous investigation artifacts (confirmed present 2026-10-01)
- `/tmp/hdr-consumer-audit/audit-results.json`
- `/tmp/hdr-consumer-audit/negative-v1.bin`
- `/tmp/hdr-consumer-audit/decode-probe.c`
- `/tmp/hdr-consumer-audit/size-results.txt`
- (also present: base-core.c/.so, candidate-*/old-* size probes, overflow-probe,
  redis/valkey/keydb/node vendored trees, memtier/wrk2 outputs — see dir listing)
- ⚠ These live in `/tmp` and are **not durable** — copy anything needed into the repo
  before relying on them across reboots.

## Vendor constraints
- Redis/Valkey vendor refreshes must **retain** their local
  `hdr_iter_linear_set_value_units_per_bucket` extension and allocator shim.

## Build-size note (PR 2 relevant)
- Redis embeds HDR **statically**; its HDR dependency uses `-Os` independently of the
  server's `-O3`. **Compare -Os / -O2 / -O3** rather than assuming `-O3` shrinks code.
- No fresh `-O3` measurements were completed in the prior session.

## Open items on continuation
- [x] Fresh -Os/-O2/-O3 size comparison for the static core target.
- [x] Implementation patches for both PRs.
- [x] Open the two upstream PRs — **#162** (PR1) and **#163** (PR2), opened 2026-10-01,
      base main, head fcostaoliveira:*, paulorsousa requested as reviewer.

---

## PROGRESS 2026-10-01 (Opus 4.8 session) — both PRs IMPLEMENTED + MERGE-READY

Built in isolated worktrees off `upstream/main` (e4e8b0a); existing checkout
(feat/packed-histogram) untouched.

### PR 1 — branch `harden/decode-reject-negative-counts` (commit b952f59)
Reject negative decoded bucket counts in V0/V1 word-based decoders
(apply_to_counts_16/32/64) + wire through the previously-discarded apply_to_counts
return in the v0/v1 decoders. New code HDR_NEGATIVE_COUNT_INVALID (-29988) + strerror.
V2 untouched (negative zig-zag = zero-run marker; positives already >=0). On failure
the fresh histogram is freed and the caller's destination (hdr_add path) is left
unchanged. Regression test embeds the crafted negative-v1 blob and asserts rejection.
Root bug confirmed via /tmp/hdr-consumer-audit/negative-v1.bin (decode was returning 0).
Complements #159 (positive total_count overflow) — independent, both edit v0/v1/v2
decode; expect a trivial adjacent-line merge, resolve when both land.
Gates: gcc+clang ctest 5/5, HDR_LOG=DISABLED build, ASan+UBSan 5/5, decode fuzzer
13.2M execs 0 crashes. Hot-path TUs byte-identical → no WRITE/READ regression. MERGE-READY.

### PR 2 — branch `feat/minimal-static-core` (commit a3cc278)
HDR_HISTOGRAM_CORE_ONLY builds only hdr_histogram_core_static from hdr_histogram.c
(libc/libm only); skips find_package(ZLIB)/find_package(Threads), logging/recorder/
phaser, tests, examples, packaging. HDR_HISTOGRAM_DISABLE_AVX2 (-> HDR_DISABLE_AVX2)
forces the scalar percentile scan. Default full build unchanged when both off (ABI/
SONAME intact, hot path byte-identical). Allocator hooks (hdr_malloc.h) preserved.
docs/EMBEDDING.md + README pointer added.
Size (.text, gcc x86-64) core vs full: -Os 7573/18423 (-59%), -O2 11617/24855,
-O3 16275/33117. Confirms -Os smallest (-O3 core ~2.1x -Os).
Gates: gcc+clang ctest 5/5, HDR_LOG=DISABLED, ASan+UBSan 5/5, core-only build+link
smoke+install clean, AVX2-disable build+ctest 5/5 (toggle verified 72->0 intrinsics).
Fuzz N/A (no codec/logic change). MERGE-READY.

### PRs OPENED 2026-10-01
- PR1 -> #162 https://github.com/HdrHistogram/HdrHistogram_c/pull/162
- PR2 -> #163 https://github.com/HdrHistogram/HdrHistogram_c/pull/163
  Both base main, head fcostaoliveira:<branch>, reviewer paulorsousa. Watch CI.

### Redis/Valkey vendor refresh — DONE 2026-10-01
Refreshed deps/hdr_histogram core (pre-d21d084 #158 snapshot -> #158 tip d21d084; the
Zen5 write-regression fix). Net change = d21d084 on hdr_histogram.c only. Local deltas
kept: hdr_iter_linear_set_value_units_per_bucket + per-consumer hdr_redis_malloc.h
(zmalloc / valkey_malloc). Validation: redis build + latency-monitor/info + live
latencystats OK; valkey build + 50/0. Artifacts + net-delta: experiments/VENDOR-REFRESH-2026-10-01/.
Done in /tmp/hdr-consumer-audit export trees (ephemeral, not git clones); no consumer
PRs opened — applying to canonical Redis/Valkey repos + upstreaming is a separate step.

### Still NOT done
- #159 coordination merge: if #159 lands first, refresh #162 (trivial adjacent-line
  conflict in v0/v1/v2 decoders).
- Apply vendor refresh to canonical consumer repos (above was in ephemeral /tmp trees).

---

## Session close-out 2026-10-01 (later): PRs, decisions, what is NOT done

PRs from this thread (all on the fork, reviewer paulorsousa; see LIVE-STATUS for live state):
#162 decode rejects negative V0/V1 counts · #163 minimal static core (+ CI job; ci.yml conflict resolved on the branch) ·
#164 amalgamation script + committed `amalgamated/` (+ `--malloc-include`) · #165 `hdr_iter_linear_set_value_units_per_bucket` (bot review answered, 38599c9) ·
#166 `hdr_record_value_capped[_atomic]` + `hdr_total_count` (deep review done; atomic variant + atomic-load total_count added) ·
#167 AArch64 Clang pragma (reviewed, NOT changed).

Open decisions for the user:
1. **#164 committed vs release artifact.** Committed `amalgamated/` goes stale every time main's core changes (its `--check` CI fails). Verified: merging #165/#166 on top makes it fail. Either land #165 and #166 first and regenerate once, or drop `amalgamated/` and attach the output to releases. Unanswered.
2. **#166 NULL check** on `hdr_total_count` was kept (only NULL-safe getter in the lib). One line to drop if memtier never passes NULL.
3. **#167 is `draft=false` on GitHub** although its description and notes say draft. Convert back to draft or reconcile; do not merge before the Apple Clang task and an Opus-4.8-level review.
4. **SOVERSION** for 0.12.0 is a release-time step covering #162/#165/#166 new symbols (CURRENT+1, REVISION=0, AGE+1); deliberately not bumped in the PRs.
5. memtier must drop its local `hdr_record_value_capped[_atomic]`/`hdr_total_count` and accept that 0 now records as 0 (not raised to the lowest value). memtier's local atomic helper also uses the old field name `lowest_trackable_value`.

Not done / for the next session:
- Apple Clang measurement for #167: experiments/C-ARM-CLANG-SCAN-2026-10-01/APPLE-CLANG-TASK.md.
- Once #165/#166 merge: regenerate #164's `amalgamated/` (or implement decision 1). Whoever touches #163/#164 branches: `git fetch` first, another session pushes to them.
- Redis/Valkey consumer repos still carry the local iterator extension until #165 is released; the vendor refresh was only done in ephemeral /tmp trees (experiments/VENDOR-REFRESH-2026-10-01/).
- Idea: a ctest leg with `-DHDR_HISTOGRAM_DISABLE_AVX2=ON` (after #163) so the scalar scan is tested on x86 CI; today the #167 test never reaches the pragma'd loop on AVX2 runners.
- The `HdrHistogram_c` submodule pointer in this repo is intentionally left unstaged.

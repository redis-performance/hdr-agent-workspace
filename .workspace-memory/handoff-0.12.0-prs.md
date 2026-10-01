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

### NOT done this session
- Redis/Valkey vendor refresh (retain hdr_iter_linear_set_value_units_per_bucket +
  allocator shim) not re-run.
- #159 coordination merge: if #159 lands first, refresh #162 (trivial adjacent-line
  conflict in v0/v1/v2 decoders).

# Go open-PR adversarial review round — 2026-07-02

7 subagents, `hdr-reviewer-go` skill, one maintainer lens each, across the 3 open PRs on
HdrHistogram/hdrhistogram-go. dkropachev requested (via @mention comment — pull-only access,
can't formally request reviewers).

## Panel results

| Agent | PR | Lens | Verdict | Key finding |
|-------|----|------|---------|-------------|
| 1 | #57 | filipecosta90 | MERGE-READY | reproduced ~+100%; differential over 5 configs byte-identical |
| 2 | #57 | dkropachev | **NEEDS WORK** | **dead `getCountAtIndexGivenBucketBaseIdx` → golangci-lint unused → CI red** |
| 3 | #57 | ahothan | MERGE-READY | 2000-config × all-edge-percentile differential, zero mismatches |
| 4 | #58 | filipecosta90 | **NEEDS WORK** | **empty histogram (unitMagnitude>0) → 63 instead of 0** (contract break) |
| 5 | #58 | codahale/spec | MERGE-READY | batch==singular on populated; bench ~+350% |
| 6 | #58 | dkropachev | **NEEDS WORK** | same dead method; map already pre-sized (nit was moot) |
| 7 | #23 | dkropachev/codahale | **BLOCK / close** | fails on master, API misuse, false-green, superseded by #51/#54 |

## Two real bugs caught in our own PRs → fixed

1. **Dead code (lint blocker, #57/#58).** `getCountAtIndexGivenBucketBaseIdx`'s only caller was the
   loop the flat scan replaced. `golangci-lint unused`/U1000 (CI `make lint`) would go red.
   → Deleted it. #57 `ca1ed92 → 3e20c1f`.
2. **Empty-histogram regression (#58).** The flat scan lost the iterator's `limit==0` short-circuit;
   an empty histogram with `lowestDiscernibleValue>1` returned `highestEquivalentValue(0)` (e.g. 63)
   instead of the documented 0's. → Added `if h.totalCount == 0 { return }` + regression test
   `TestValueAtPercentiles_EmptyHistogram`. #58 rebased on #57, `→ 0a4452f`.

Both branches force-pushed; PRs updated with explanatory comments. Local: build/vet/tests green,
dead code gone. (Singular #57 is byte-identical on empty/p0 — no fix needed; C #140 dodges this by
clamping the target count to ≥1.)

## #23 (okayzed) — recommend closing
`TestTimeStamps` fails on master (author-acknowledged): passes a ~1.5e9 value as
`lowestDiscernibleValue`, overflowing the int32 bucket math → MaxInt32; the "ms" case is false-green
(out-of-range records silently dropped, oversized tolerance hides it); doesn't test timestamp
*serialization* (superseded by dkropachev #51/#54); stale (2016), non-gofmt/lint-clean.

---

# Rust #138 adversarial review round — 2026-07-02

3 subagents (`hdr-reviewer-rust` skill; jonhoo / correctness-edges / panics lenses) on the one open
Rust PR. CI pre-checks I ran: `cargo fmt --check` PASS; clippy clean for the new functions (all
warnings pre-existing); clippy IS a gate (check.yml stable+beta) + MSRV `cargo +msrv check` + cargo doc.

**Unanimous:** correctness VERIFIED (batch == per-item across empty / q=0 / q=1 / q>1 / duplicate /
unsorted / single / last-index / all-zeros) and **no panics** — NaN doesn't panic because the sort is
over the derived `u64` targets, not the `f64` inputs, and casts saturate cleanly.

**Two blockers (both fixed):**
1. **No tests** (jonhoo's hard gate) → added `batch_quantiles_match_singular` (unsorted+dup+edges) and
   `batch_quantiles_empty_histogram` to `tests/data_access.rs`; both pass.
2. **Naming inconsistency** `values_at_quantiles` vs `value_at_percentiles` → renamed to
   `value_at_quantiles` / `value_at_percentiles` (matches the existing `value_at_*` family).
   Also added `#[must_use]` + documented empty/clamp/q==0 behavior.

Amended + force-pushed `perf/value-at-percentiles-batch` (96fa8ab → 26e3d39); PR comment posted.
Contrast with Go: the Rust batch was already correct + panic-safe (it clamps the target to ≥1 like
C #140), so no logic bugs — only tests + naming polish.

---

# C #138/#139/#140 adversarial review round — 2026-07-02

6 subagents (`review-hdrhistogram` skill; @mikeb01 M.O.). NO correctness bugs found in any C PR.

- **#138 (widen AVX2 4→16)** — MERGE-READY. Byte-identical PROVEN (16-lane block sum exact → same
  first-crossing index for every input); bounds PROVEN (widest load counts[idx+12..+15] ≤ len-1,
  scalar tail); uint64 hardening preserved; AVX2-gated + scalar fallback (MSVC safe). Offset-A1 gap is
  PRE-EXISTING from #134, not worsened (#137's job). Benchmark table present in body.
- **#139 (prefetch, stacked on #138)** — CODE MERGE-READY / PR process-blocked. Prefetch is non-faulting
  (≤384 B past array, ASan-clean by design, sink byte-identical), portable, evidenced. Blocker: STACKED
  on unmerged #138 → convert to draft until #138 merges, then rebase to one commit. Minor: `64`=4×stride
  coupling; note CLX gcc+8%/clang0% alignment caveat.
- **#140 (single-pass hdr_value_at_percentiles, flat scan)** — correctness MERGE-READY on BOTH the
  offset==0 fast path (byte-identical to the iterator) AND the offset!=0 fallback (I added it; PROVEN
  the necessary-and-sufficient gate; decoded histograms route to the untouched iterator — the #137
  lesson done right). BUT **overlaps + textually conflicts with the open #137** (same base blob, same
  function; #137 is a superset). And #137 *deletes* the AVX2 path that #138/#139 optimize.

## Strategic problem (surfaced, needs owner decision)
The 4 open C PRs conflict: #137 (portable block-sum, drops AVX2 dispatch, single-passes the batch)
vs #138/#139 (enhance the AVX2 dispatch) vs #140 (single-passes the batch, keeps AVX2). Cannot all
merge cleanly; mikeb01 dedupes overlapping PRs. Recommend consolidating to ONE coherent story.

## Non-blocking asks the maintainer would make
- #140: add a decoded-histogram (offset!=0) regression test — ctest doesn't cover the A1 fallback
  ("the branch that bit us last time" = #137).
- #140: strengthen the perf body (name the compiler, add a reproduce block, median-of-N).

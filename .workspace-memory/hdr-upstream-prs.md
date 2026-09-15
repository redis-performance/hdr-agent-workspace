---
name: hdr-upstream-prs
description: Fork PRs to HdrHistogram/HdrHistogram_c, their status, and how to open them
metadata:
  type: reference
---

Optimization PRs from the fork `fcostaoliveira/HdrHistogram_c` → upstream
`HdrHistogram/HdrHistogram_c` (maintainer @mikeb01). Build new work on top of these.

- **#134** — ✅ MERGED. AVX2 vectorized prefix-sum in `get_value_from_idx_up_to_count`
  (read path, ~+84% on the percentile microbench). Scalar fallback under `#if defined(__AVX2__)`,
  per-file `-mavx2`. Added `test/hdr_percentile_bench.c`.
- **#135** — ✅ MERGED. Bypass `normalize_index` in `counts_inc_normalised`
  (+`_atomic`) when `normalizing_index_offset == 0` (write path, big record-throughput win).
- **#136** — ✅ MERGED. Replace `counts_index < 0 || counts_len <= counts_index` with a single
  `(uint32_t)counts_index >= (uint32_t)counts_len` on the record path.
- **#133** — CLOSED, then @mikeb01 **re-applied it himself** with style tweaks ("modified the
  style slightly … one of the other PRs adds the expect builtins"). Guarded stores in
  `update_min_max`. Lesson: reuse existing expect macros, match project style, expect him to
  re-style/dedupe overlapping diffs.
- **#137** — OPEN. Portable block-summed percentile scan that DROPS the AVX2 runtime dispatch
  (removes `<immintrin.h>`, `target("avx2")`, `__builtin_cpu_supports`) + single-pass
  `hdr_value_at_percentiles`. Self-review during the PR caught a force-push that dropped the
  offset-aware fallback and uint64 hardening; restored. CI 15/15 green.
- **#138–#141** — OPEN. Perf follow-ups (AVX2 widen16 + prefetch; single-pass and
  blocked-batch `hdr_value_at_percentiles`).
- **#145** — ✅ MERGED 2026-09-14 (e831736). Bucket-config shift overflow. Grew during review
  into: sibling `lowest*2` overflow, a regression test, the fuzzer reproducer as
  `test/regression-*.hlog`, LeakSanitizer, AND a new **`sanitizers` CI job** (ASan+UBSan ctest,
  `-fno-sanitize-recover=all`, `HDR_LOG_REQUIRED=ON`). That job is now the per-PR gate for this
  whole bug class — reproduce every UB finding against it.
- **#146** — ✅ MERGED 2026-09-14 (6d40ddb). Heap overflows in V1/V2 log decode.
- **#147–#149** — OPEN. #147 `hdr_mean` overflow + `hdr_count_at_value` OOB, #148 top-bucket
  value-range overflow (saturate `highest_equivalent` to INT64_MAX), #149 iterator
  reporting-level overflow (activity 2026-09-14). The maintainer appears to be working the
  hardening stack in number order. NOTE: check these before re-raising any dense finding — see
  [[check-open-prs-before-raising]].
- **#151** — ✅ MERGED 2026-09-02. Claude PR-review + issue-triage automation.
- **#152** — ✅ MERGED 2026-09-15 (4a1b1fd), 17/17 green. `ci:` fetch pinned CMake from the
  **Kitware GitHub release assets** instead of `cmake.org/files`, plus wget retries; drops
  `--no-check-certificate`. cmake.org was intermittently **503 for both pinned versions**
  (3.12.4 and 3.17.3) — not hard-down, which is why some runs passed — so every linux leg was a
  coin flip and the #145 merge went red with "Unable to establish SSL connection".
- **#153** — OPEN (2026-09-14). `fix:` signed overflow in `read_ahead_timestamp`
  (`hdr_histogram_log.c`) — the UBSan finding that had failed the **weekly ClusterFuzzLite
  batch run 8 times in a row since 2026-07-27**. Seconds field now rejects at LONG_MAX instead
  of wrapping; fraction stops at nanosecond resolution (which also fixed a silent
  `tv_nsec = 0`). Branch `fix/log-timestamp-overflow`. Upstream `sanitizers` job green; its red
  linux legs are only the cmake.org 503 that #152 fixes.
- **#150** — OPEN. `feat: hdr_packed_histogram` — the memory-optimised sparse variant
  (branch `feat/packed-histogram`). Separate opt-in type, dense hot paths untouched;
  sorted virtual-index vector + adaptive byte-width counts; byte-identical V2 both ways;
  36×–1240× footprint win. 23 parity tests as a ctest target, clean under
  ASan+UBSan+float-cast-overflow. Integration lesson: the parity test must NOT call dense
  query funcs at UB points (−inf percentile cast; top-bucket `highest_equivalent` overflow,
  fixed only in unmerged #147/#148) — assert packed's documented behavior directly instead,
  or the maintainer's strict-sanitizer CI fails on `main`.

**How to open one:** branch off `upstream/main`, one isolated commit (cherry-pick the single
EXP), PR from the fork to `HdrHistogram/HdrHistogram_c`. PR body MUST include a before/after
benchmark table (ops/sec write, throughput read) + a "Steps to reproduce" block using the
in-repo `hdr_histogram_perf` / `hdr_percentile_bench`. Open ONLY after
`.claude/skills/review-hdrhistogram.md` returns MERGE-READY.

If a fine-grained PAT can't open the PR ("Resource not accessible by personal access token"),
clear the env tokens for that one command and fall back to the stored OAuth login:
`GH_TOKEN= GITHUB_TOKEN= gh pr create -R HdrHistogram/HdrHistogram_c --base main --head fcostaoliveira:<branch> ...`
(Never paste a token into the repo or a commit.)

Refresh: `GH_TOKEN= gh pr list -R HdrHistogram/HdrHistogram_c --state all --limit 25 \
  --json number,title,state,author`.

## Workspace-accepted, upstream HELD
- **EXP-002** — widen AVX2 percentile scan 4→16 int64/iter (vector accumulator). Read +137%
  (gcc) / +144% (clang) on Cascade Lake, percentile results bit-identical. Fork branch
  `perf/avx2-percentile-scan-widen16` @ 673d52e (pushed to origin/fork; submodule pointer bumped).
  **PR #138 opened** 2026-07-01 (was held); body offers to re-target if #137's portable path is preferred. #137 note: #137 would REMOVE the AVX2 path for a portable
  scalar block-sum. If AVX2 stays, offer this widening on top; else re-target the portable path.
- **Latent bug noted (pre-existing, since #134):** `get_value_from_idx_up_to_count` (scalar + AVX2)
  reads `h->counts[idx]` directly and ignores `normalizing_index_offset` → wrong percentiles for
  decoded/rotated histograms. This is exactly what #137's self-review restored. Do NOT ship a
  read-path change that relies on the direct read without the offset-aware fallback.
- **EXP-003/004 prefetch** — **PR #139** opened 2026-07-01, stacked on #138 (branch
  `perf/avx2-scan-prefetch` @ 3e8ae6a; 2 commits, reduces to the one-line prefetch after #138
  merges). Two-µarch data: gcc +8% both, clang neutral (Cascade Lake) → +5.7% (Granite Rapids).
  https://github.com/HdrHistogram/HdrHistogram_c/pull/139

## Cross-port PRs (Go / Rust) — 2026-07-02
Race-driven wins (see experiments/RACE.md GO-EXP-001 / RUST-EXP-001):
- **hdrhistogram-go #57** — flat counts[] scan in ValueAtPercentile, +133% (0.0457→0.1066 Mq/s).
  Needed a FORK (fcostaoliveira/hdrhistogram-go — created via `gh repo fork`; fcostaoliveira only had
  pull access to the HdrHistogram org). Branch perf/flat-scan-value-at-percentile @ ca1ed92.
  **Go upstream default branch is `master`, not `main`** (PR base=master).
  https://github.com/HdrHistogram/hdrhistogram-go/pull/57
- **HdrHistogram_rust #138** — single-pass value_at_percentiles/values_at_quantiles batch API,
  +616% (7.2x) vs 7x singular. Pushed to existing fork fcostaoliveira/HdrHistogram_rust, branch
  perf/value-at-percentiles-batch @ 96fa8ab. Base=main. https://github.com/HdrHistogram/HdrHistogram_rust/pull/138
- **Perf lesson**: ports' singular flat scans are already tight; the batch loop must stay equally
  tight (hoist next-target into a local) — a naive per-element `while` check was SLOWER than 7x singular.

## C-EXP-006 — single-pass hdr_value_at_percentiles (PR #140, 2026-07-02)
Flat counts[] scan replacing the iterator in hdr_value_at_percentiles (offset==0 fast path,
offset!=0 iterator fallback kept). +599% (7x): 12.4K->86.4K calls/sec. Base upstream/main (18c7a32),
independent of #138/#139. Branch perf/single-pass-value-at-percentiles @ 7c8af3d on fork.
https://github.com/HdrHistogram/HdrHistogram_c/pull/140
Gotcha: first A/B was base-vs-base — `git archive HEAD` ran before committing the change. Commit first.
Total open upstream PRs across fleet: C #137–#141, #144, #147–#150, #153, #154, Go #57,
Rust #138.

- **#154** — OPEN (2026-09-14). `fix:` out-of-range `double`->`int` in
  `hdr_timespec_from_double` (`src/hdr_time.c`) — the second half of the weekly-fuzzing
  failure, found locally by fuzzing on top of #153. `hdr_log_read_header` feeds the
  `#[StartTime: %lf` field straight in, so a millisecond epoch (1.40348e+12) is UB; the narrow
  `int` cascaded 3 UB sites (the cast, the `(int) round(...)`, and `milliseconds * 1000000`).
  Bound derived from `sizeof(tv_sec)` so it is exact on LP64 / LLP64 / 32-bit; also fixes the
  2038 truncation. Branch `fix/timespec-from-double-overflow`.

## Full PR sweep vs main — 2026-09-15 (after #152 landed)
Brought all 12 open PRs up to date with main (4a1b1fd). Results worth remembering:
- **4 of our PR branches live in the UPSTREAM repo, not the fork**: #144, #147, #148, #149
  (head `HdrHistogram:<branch>`, pushed by the *filipecosta90* account). The `fcostaoliveira`
  login can push to them, but `git push origin <branch>` silently creates a **stray branch on
  the fork** instead of updating the PR — push to `upstream` for these. Check
  `headRepositoryOwner` before pushing.
- **#149's base is #148's branch**, not main. Update #148 first, then #149; updating #149
  before #148 means redoing it.
- `git merge-tree <base> <a> <b>` (3-arg legacy form) **does not reliably report conflicts** —
  it said all 12 were clean when 2 were not. Use
  `git merge-tree --write-tree --name-only <main> <branch>` and check the exit code.
- Conflicts found (both ours to fix, both one file): **#144** ci.yml vs #145's new `sanitizers`
  job — both appended top-level jobs at EOF; resolution keeps all four jobs, rebuilt around the
  shared `runs-on`/`steps` context (do NOT just take main's file: #144 also adds a step *inside*
  the build job that would be lost). **#148** test/hdr_histogram_test.c — `#include <math.h>` vs
  `<string.h>` at the same line; keep both.
- **The new `sanitizers` job retro-broke #137 and #138**: it enables LeakSanitizer, and both had
  a test calling `free(h)` after `hdr_init`. `hdr_init` makes TWO allocations (counts array +
  struct), so `free(h)` leaks the counts (188416 bytes); `hdr_close` frees both and is the
  idiom everywhere else in that file. Expect any PR predating #145 to trip this.
  **Lesson: when a new CI gate lands on main, older open PRs can fail it without changing —
  re-run/update them rather than assuming green-when-opened still holds.**

## -Wconversion on LP64 CANNOT see int64_t->long narrowing (MSVC C4244)
On LP64 `int64_t` and `long` are the *same type*, so a local `-Wall -Wextra -Wconversion`
sweep reports zero warnings for `some_long_field = (int64_t) x` — while MSVC x86 (and any
32-bit `long` target) emits **C4244 '=': conversion from 'int64_t' to 'long'**. This bit
#154: the PR body claimed "no new warnings" on the strength of an LP64 run. The bot review
called it and was right (2 occurrences per x86 leg, static + shared targets).
- **Never claim warning-clean from an LP64 run alone** when a `long`-typed field is assigned.
  Grep the Windows x86 job log: `gh api /repos/<o>/<r>/actions/jobs/<id>/logs | grep C4244`.
- Fix pattern: key the bound AND the cast to the same type (`long` here) so they agree by
  construction and neither narrows. `hdr_gettime`'s Windows branch already does
  `(long) integral` — follow it. Keying off `sizeof(long)` is never narrower than the `int`
  it replaced, so no platform loses range vs pre-fix code.
- `hdr_timespec.tv_sec` is `long` on Windows/Cygwin and `time_t` elsewhere; widening it is a
  public-ABI decision for @mikeb01, not a drive-by.

## The #151 review bot is worth actually reading
Its first-pass reviews on #153/#154 produced two real items: the C4244 above, and a genuine
coverage gap (no fixture pinned the 2^31 seconds boundary in #153). It also correctly flags
its own uncertainty ("verify against the Windows build log rather than taking my word").
Treat its claims as leads to verify empirically, not noise — but do NOT accept the ones it
itself marks unverified (e.g. Java HistogramLogReader parity) without checking.

## Bash gotcha: `gh` inside a `while read` loop eats stdin
A `gh api ... ` inside `while read -r j; do ... done < file` consumes the loop's stdin and
silently processes only the first line. Add `</dev/null` to the gh call.

## Refreshing a stale PR branch WITHOUT force-pushing
CLAUDE.md forbids force-push (the #137 incident silently dropped the offset-aware fallback).
To pick up a fix that landed on main, use **`gh pr update-branch <N>`** — GitHub's native
"Update branch", which *merges* base into head and pushes normally. `--rebase` would
force-push; do not use it. Afterwards always verify nothing was lost:
`git diff upstream/main origin/<branch> --stat` must still show the same files/line counts,
and the original commit must still be in `git log`. The maintainer squash-merges, so the
extra merge commit disappears on merge and costs nothing.

## Fuzzing: gcc and clang UBSan report DIFFERENT lines for one root cause
gcc's `-fsanitize=undefined` does **not** include `float-cast-overflow`; clang's does. So for
the #154 bug gcc reported the downstream `milliseconds * 1000000` int overflow while
ClusterFuzzLite (clang) reported the `(int) value` cast. When reproducing a fuzzer UB finding
locally, build with **clang + `-fsanitize=address,undefined,float-cast-overflow`** to match
the fuzzing build, and cross-check with gcc — the line numbers will not agree.

## Combined-state validation pays off
#153 and #154 both came from `log_reader_fuzzer`, and both add lines to `test/CMakeLists.txt`
and `test/hdr_histogram_log_test.c` — so they conflict trivially (additive: keep both fixture
entries, keep both `mu_run_test` lines). Stacking them locally before opening #154 proved the
pair is what turns the weekly run green: ctest 5/5 under both sanitizer configs, 4/4 with
logging disabled, and a 600s seeded `log_reader_fuzzer` session = **5.68M execs, 0 crashes, 0
UB** (cov 304 vs 254 pre-fix). Do this whenever two PRs fix findings from the same fuzzer.

## Known-unfixed, NOT yet raised (next candidate)
- **`hdr_timespec_from_double` fraction carry** — can still round up to a full second and emit
  `tv_nsec = 1000000000` (`1.9996` -> `tv_sec=1`, `tv_nsec=1e9`), a malformed `hdr_timespec`
  but NOT UB. Deliberately left out of #154 (different defect class; changes output for
  currently-accepted inputs). Offered in the #154 body as a separate follow-up.
- **Windows `hdr_gettime` `(long) integral`** (`src/hdr_time.c`) — same cast shape, but the
  source is QueryPerformanceCounter seconds-since-boot, so it cannot realistically overflow.
  Not worth a PR; noted so it is not re-raised.

## Gotcha: `gh --body-file` cannot read the scratchpad or /tmp
`gh` runs sandboxed with its own `/tmp`, so `--body-file /tmp/...` fails with
"no such file or directory" even though the file exists. Write PR/comment bodies inside the
workspace dir (e.g. `.pr-body.md`, then delete) instead.

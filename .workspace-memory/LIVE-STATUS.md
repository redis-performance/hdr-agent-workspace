# LIVE STATUS — HdrHistogram_c PR campaign

**Updated: 2026-10-01 ~00:00 UTC** · Session: opus-4.8 loop (adversarial review + merge)
Pushed on every material change so other runners/sessions see current state.
Coordination signal, not source of truth — verify against GitHub before acting.

upstream/main tip: **e4e8b0a** (after #141).

## Merged (11) — squash, on paulorsousa approval
✅ #157 · #155 · #149 · #138 · #154 · #144 · #156 · #139 · #140 (single-pass +1011%) · #141 (blocked scan +182%) · #159 (reject import total_count overflow, #118) [merged 2026-10-01 09:19Z]

## Open (9)
| PR | branch | state | notes |
|----|--------|-------|-------|
| #166 | feat/record-capped-total-count | NEW 2026-10-01, pending review | Upstreams memtier's local `hdr_record_value_capped` (4a74ae3: clamps to [0,highest]; 0 and sub-lowest kept, verified vs Java 2.2.2, Python hdrh 0.10.3, Rust record/saturating_record; memtier must drop its raise-0-to-lowest behaviour — maintainer OK'd) + `hdr_total_count`. Related to #126 but does not close it. gcc/clang/ASan/nolog 5/5. reviewer paulo |
| #165 | feat/iter-linear-set-bucket | pending review; bot review answered (38599c9: no-op on non-linear iterators, timing doc fixed) | Upstreams the Redis/Valkey-local `hdr_iter_linear_set_value_units_per_bucket` (adaptive linear-bucket width; used by redis/valkey-benchmark). Lets consumers drop the delta; flows into #164 amalgamation. gcc/clang/ASan/nolog 5/5 + new test. reviewer paulo. Pairs with #164: when both land, regen amalgamated/ (CI --check enforces) |
| #164 | feat/amalgamate-core | NEW 2026-10-01, pending review | script/amalgamate.py emits drop-in core (inlines hdr_tests.h+hdr_atomic.h into hdr_histogram.c; keeps public .h + HDR_MALLOC_INCLUDE hook) + committed amalgamated/ + CI --check. Preprocesses byte-identical to multi-file build. vs Redis vendored (d21d084): only 3 structural hunks (banner, inlined headers, Redis-local extension) — body verbatim, no aesthetic churn. reviewer paulo |
| #163 | feat/minimal-static-core | NEW 2026-10-01, pending review | Opt-in `HDR_HISTOGRAM_CORE_ONLY` (core static, no zlib/threads) + `HDR_HISTOGRAM_DISABLE_AVX2`. Default build/ABI unchanged. core .text -59% at -Os. All gates green. MERGE-READY. reviewer paulo |
| #162 | harden/decode-reject-negative-counts | NEW 2026-10-01, pending review | Reject negative V0/V1 decoded bucket counts (new HDR_NEGATIVE_COUNT_INVALID); V2 zero-runs preserved. Complements #159 (adjacent-line merge). ctest/clang/ASan/UBSan + 13.2M fuzz execs clean. MERGE-READY. reviewer paulo |
| #161 | fix/timespec-from-double-checked | pending review | #154 follow-up: additive `hdr_timespec_from_double_checked()`. Refreshed onto master; ctest+ASan+nolog green |
| #150 | feat/packed-histogram | NEEDS-WORK (perf gate); conflict with master RESOLVED 2026-10-01 (489c541: merged upstream main, kept packed + #159 counter-overflow tests/fuzzers; gcc+ASan/UBSan ctest 9/9) | refreshed earlier; SOVERSION revert stands; large opt-in feature. CI re-running on 489c541 |
| #160 | ci/explicit-macos-coverage | pending review, MERGEABLE/CLEAN vs new master | macOS Intel+Apple sanitizer CI (still open; absent from list above) |
| #158 | perf/avx2-scan-nonneg | pending review (ready, tip=d21d084) | Reject-negatives contract. count>=0 enforced; both scans assume monotonic (dropped signed handling incl. #141's batch signs<0); removed signed-count tests. **Write-regression fix landed (d21d084):** count<0 check moved off the single-value hot path → write ~flat all arches (SPR +4.6/Zen5 -2.2/N-V2 -1.2%); old-tip swings were count<0 code-layout artifact (user chose to keep the fix). Charts re-measured at d21d084. ctest+ASan 5/5, singular read ~+37%. MERGEABLE/CLEAN vs new master. Reverses #138/#141 signed support — flagged to mikeb01/paulo |

## Consumer vendor refresh (2026-10-01, DONE)
Redis + Valkey `deps/hdr_histogram/` refreshed from pre-d21d084 #158 snapshot → #158 tip
**d21d084** (count<0 off the single-value hot path — the Zen5 write-regression fix). Net
source change = d21d084 on hdr_histogram.c only; .h/atomic/tests unchanged. Local deltas
preserved: `hdr_iter_linear_set_value_units_per_bucket` extension + per-consumer
`hdr_redis_malloc.h` (zmalloc / valkey_malloc). Validation: both build at -Os;
redis latency-monitor+info pass + live INFO latencystats percentiles OK; valkey 50/0.
Artifacts: experiments/VENDOR-REFRESH-2026-10-01/. Done in /tmp export trees; no consumer
PRs opened.

## Decisions awaiting maintainers
- #158 vs #141: support-vs-reject signed counts (see #158 comment). #141's merge leans "support".
- #161: checked-API shape — ready to merge on approval.


## Reviewer + master-merge check (2026-09-30 15:35)
paulorsousa set as reviewer on ALL open PRs (#161,#160,#159,#158,#150).
Master merges CLEAN into #161 (behind 0), #160 (behind 2), #159 (behind 2). #158 CONFLICTS (signed-count test vs merged #141) — blocked on the support-vs-reject decision.
New PRs from the parallel hardening runner: #159 (reject import total_count overflow, the #118 fix), #160 (macOS Intel+Apple sanitizer CI). Both paulorsousa-reviewed; refresh left to that runner.


## #150 packed — Paulo review round (2026-09-30 ~18:50)
Paulo left 4 inline comments. DONE + pushed: (1) reject negative value in hdr_packed_count_at_value (14f37b7), (3) route allocations through hdr_malloc/calloc/realloc/free hooks (d2d76b2). ALSO DONE + pushed (7eea0d7): (2) counts_index_for moved to new src/hdr_histogram_internal.h (packed+log include it; log.c dup decl removed; hdr_tests.h re-includes); (4) split h->cap -> idx_cap/cnt_cap for exact memory accounting on partial-realloc failure. ALL 4 Paulo #150 points resolved. gcc ctest 7/7 + ASan/UBSan + nolog green.


## C-PERFORMANCE-CHARTS fleet run (2026-09-30, DONE)
Filled Intel(m7i SPR)/AMD(m8a Zen5)/Graviton(m8g N-V2) in data.json + re-rendered write/read/list SVGs, 0.11.10 (18c7a32) vs #158 tip (bcb5c1f), median of interleaved core-pinned idle-gated runs; raw logs in C-PERFORMANCE-CHARTS/fleet-raw-2026-09-30/. read: Intel +74%/AMD +112%/ARM +22%; list ~20-33x; write uarch-dependent (Intel +29%, AMD -10%, ARM -4%). Coordinators never paused; boxes left clean. Pushed b701f62.

## AMD write regression — root cause + fix (2026-10-01 ~06:45, IN VALIDATION)
Tight 3-point AMD (Zen5) write run localized the −10% to **#158 specifically**, not cumulative:
prev 0.11.10 (18c7a32) ~500M · pre-#158 master (e4e8b0a) ~506M · #158 tip (bcb5c1f) ~448M (each cluster <1% spread).
Cause: `hdr_record_value`→`hdr_record_values` are separate external symbols, so (no LTO) the `count<0`
guard ran on every single-value record (not folded by count==1) → ~11% on Zen5.
Fix pushed to #158 branch (**d21d084**): factored record body into static `record_value_counted[_atomic]`,
kept `count<0` only in the explicit `*_values` entry points; hot path (count==1) now identical to pre-guard.
ctest 5/5 green.
AMD re-measure (interleaved, pinned, idle): prev 0.11.10 ~500.2 · pre-#158 ~506.1 · old-tip (bcb5c1f) ~449.0 ·
**fixed-tip (d21d084) ~489.0**. Fix recovers 449→489 (+8.9%); stable residual ~2.2% below 0.11.10 is Zen5
codegen/layout (NOT the count check). Force-inline diagnostic (820caa5) was WORSE (~410) → deleted; plain
fix d21d084 is best. **#158 tip is now d21d084.**
Re-measuring Intel(m7i-2) + ARM(m8g-2) write at the fixed tip so the write chart is consistent at d21d084 (read/list untouched).
RESOLVED 08:40Z — same-session 3-point write (0.11.10 / old-tip bcb5c1f / fixed-tip d21d084), all 3 arches:
| arch | prev | old-tip bcb5c1f | fixed-tip d21d084 |
| Intel SPR | 329.7 | 421.5 (+27.8%) | 344.9 (+4.6%) |
| AMD Zen5 | 500.2 | 449.0 (-10.2%) | 489.0 (-2.2%) |
| ARM N-V2 | 398.4 | 381.5 (-4.2%) | 393.5 (-1.2%) |
The only write-path diff from 0.11.10 is the one count<0 branch → its ±(4-28)% swings are CODE-LAYOUT
artifacts (reproduced same-session; Intel +28% is REAL but accidental, not an artifact of cross-session).
Fix (d21d084) keeps count<0 only on *_values API → write ~flat (±5%) all arches; fixes AMD/ARM regressions,
forgoes the fragile Intel +28%. **USER CHOSE: keep the fix (d21d084).** Read/list untouched by the fix.
DONE: charts updated to fixed tip (data.json master=d21d084, write rows + by-arch table + SVGs re-rendered,
raw in fleet-raw-2026-10-01-writefix/), pushed. #158 ships d21d084.


## Standing plan
1. Merge any PR the instant it's APPROVED (squash). 2. After each merge, refresh remaining open
PRs with master. 3. Answer new Codex/claude-review-bot/paulorsousa comments. 4. `git pull --rebase`
before pushing status (shared repo).

## Do NOT re-raise (validated)
- #155 OOB via counts_get_normalised: FALSE POSITIVE (V1/V2 decode `%= counts_len` first). Merged.
- #158 premise "no subtract API": WRONG (hdr_record_values takes signed count) — reject-vs-support
  now an open maintainer decision (see #158).

## Full bot/human comment audit (2026-10-01 ~13:00Z)
Swept reviews + inline + issue comments + CI on all 9 open PRs. No human comments pending (Paulo's 4 on #150 resolved). Unanswered bot reviews addressed:
#161 header comment folded (30f2f66); #162 explicit casts + comments say 16/32-bit top-bit words now rejected (12aca3c); #163 new CI job build-core-only on linux/macos/windows (cefb60c, mac/win legs unverified until CI); #164 amalgamated/ commit-vs-generate = maintainer call, replied. CI re-running on the three pushes.
Earlier polls only checked comments newer than a cutoff and skipped review bodies; use the full sweep from now on.

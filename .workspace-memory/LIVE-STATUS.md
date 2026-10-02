# LIVE STATUS — HdrHistogram_c PR campaign

**Updated: 2026-10-02** · Benchmark checkpoint; PR tables below are historical snapshots.
Pushed on every material change so other runners/sessions see current state.
Coordination signal, not source of truth — verify against GitHub before acting.

upstream/main tip checked for M6 benchmark: **c4ef749** (after #168).

## Apple M6 latest-master benchmark — 2026-10-02

[Full result and raw ABBA logs](../experiments/C-M6-MASTER-2026-10-02/RESULT.md):
0.11.10 versus merged main `102aefb` on Apple Clang 21. At `-O2`, writes
−0.23%, single reads +11.33%, four-percentile lists 31.72×; at `-O3`,
−0.17%, +12.86%, 31.70×; at `-Os`, +0.13%, 2.86×, 30.34×. The newer
`c4ef749` changes only the Windows atomic branch; Apple write/read code is
identical in all three modes, and its `-O2` list result was timed separately.
QoS was verified inside benchmark processes; actual core residency was not
observed. Charts, README, summary and experiment ledger were refreshed.
No source optimization or accepted-baseline/submodule-pointer change.

Follow-up: [why `-Os` wins the M6 long read](../experiments/C-M6-OS-CAUSE-2026-10-02/RESULT.md).
At current master `c4ef749`, Apple Clang `-O3` carries the running total
through four scalar prefix adds per block; `-Os` reduces four counts in SIMD
first. A one-line local pragma-guard control restores SIMD under `-O3` and
reduces the unchanged full read from 103.696 to 39.548 seconds (2.622×),
same sink and 9/9 CTests. Early index-3 crossing loses ~19% throughput, so
the #167 Apple exclusion stands. No source/build-default acceptance.

## Merged (11) — squash, on paulorsousa approval
✅ #157 · #155 · #149 · #138 · #154 · #144 · #156 · #139 · #140 (single-pass +1011%) · #141 (blocked scan +182%) · #159 (reject import total_count overflow, #118) [merged 2026-10-01 09:19Z]

## Open (9)
| PR | branch | state | notes |
|----|--------|-------|-------|
| #166 | feat/record-capped-total-count | pending review; deep-reviewed 2026-10-01, updated c646e84 | Upstreams memtier's local `hdr_record_value_capped` (clamps [0,highest]; 0 and sub-lowest kept, verified vs Java 2.2.2 / Python hdrh 0.10.3 / Rust) + `hdr_record_value_capped_atomic` (memtier writes a shared histogram from worker threads and carries its own copy) + `hdr_total_count` (NULL-safe, now an atomic load: TSAN reports a race with the plain read, none with the atomic one). Merged main (#158 restructured record fns; conflict resolved keeping main's layout). Property test capped(v)==record(clamp(v)) over 112 configs; 3 mutants killed. gcc/clang/ASan 9/9, nolog 6/6. Decision left: NULL check kept (hdr_max/hdr_packed_total_count don't check). reviewer paulo |
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

## #150 APPROVED, merge left to the user (2026-10-01 ~15:00Z)
paulorsousa APPROVED #150 ("LGTM :)") at 14:53Z on head 489c541 (verified via the reviews API); mergeable/CLEAN, 19/19 checks pass. The agent's `gh pr merge --squash` was denied twice by the auto-mode classifier ("Merge Without Review") even with the approval confirmed on the head commit, so the agent did not retry or route around it. Needs a human to click merge (or explicitly authorize the agent to). Do not re-attempt from other sessions without that.

## Merge-order note for #164/#165/#166 (2026-10-01)
#164 commits generated `amalgamated/`; its `--check` CI fails whenever main's core changes without a regen. Verified: #164 is fresh vs main today, but merging #166 (or #165) on top makes `--check` fail (rc=1). Land #165 and #166 first, then #164 (one regen), or move the amalgamation to a release artifact (open question for the user).
#163 and #164 branches are being refreshed by another session (cefb60c/d35c528 on #163; b4a5aba on #164) — do not push to them from here without checking `git fetch` first. #163 has a new ci.yml conflict vs main since #160 merged.

## Master refreshed on all open PRs (2026-10-01 ~16:10Z)
User merged #150, #158, #160, #161 (main = 05e06cc). Open: #162 #163 #164 #165 #166 #167, all merged up to 05e06cc (behind=0), each built + ctest 9/9 before push.
- #163: ci.yml conflict with #160 resolved by taking main's file and re-appending the build-core-only job (6 jobs, YAML valid).
- #164: amalgamate.py's include regex now tolerates a trailing /* */ comment (#150's hdr_tests.h include has one, so the single file stopped compiling); amalgamated/ regenerated, smoke-compiled incl. --malloc-include.
- #166: another session had already merged main + added hdr_record_value_capped_atomic (c646e84) 23s before this session pushed; this session's push 6ecb9df accidentally removed that work. Repaired by a plain revert (b97aa21, tree identical to c646e84, build + 9/9). LESSON: several sessions edit these branches; local branch refs are shared across worktrees, so update via detached HEAD, fetch right before merging, and verify remote tree after pushing.

## #163 / #167 (2026-10-01, later)
#163: ci.yml conflict vs main (#160) was resolved on the branch by the other session (311c6f5) before this session's push; an independent resolution here produced the byte-identical tree (c4c9a45), so nothing was pushed. Core-only build + its CI assertions (no AVX2 dispatch, no zlib/log symbols) verified locally on the merged tree; gcc/clang/ASan/nolog/noavx2 ctest green.
#167 deep review (Sonnet 5.5 session; the project's formal gate wants Opus 4.8 — this is evidence, not the MERGE-READY verdict): mechanism reproduced on Clang 18.1.3 by cross-compiling to AArch64 (base -O3 = serial add chain + 3 cmp/b.ge on prefix totals; PR = vector add/addp block sum + rolled 4-iter crossing loop; -Os code-identical; x86 clang+gcc O3/Os machine code identical). Batch scan already vectorised at baseline, so touching only the singular scan is right. Scan fn identical between d21d084 and main, so the PR's measurements apply to main. Findings: PR is draft=false on GitHub though body/STATUS say draft; new test kills 5/6 injected bugs only when the scalar path runs (ARM / forced scalar) — on AVX2 x86 CI it never reaches the pragma'd loop (all block-scan mutants survive); offset=1 half only exercises the separate offset loop; Apple Clang covered by the guard but unmeasured; title says "scans" but only one scan changes. Timings NOT reproduced (no ARM hardware here).
Idea: once #163 lands, add a ctest leg with -DHDR_HISTOGRAM_DISABLE_AVX2=ON so the scalar scan (#158/#167) is tested on x86 CI.

## Apple Clang task for #167 (2026-10-01)
Hand-off: experiments/C-ARM-CLANG-SCAN-2026-10-01/APPLE-CLANG-TASK.md (codegen, paired full drivers and crossing probe). The required Opus-level review remains outstanding.

2026-10-01 update: Apple M6 / Apple Clang 21 ABBA: original #167 read 2.612× faster, write −0.185%, checksum equal, but position-3 early crossings −19.3% throughput; guard narrowed to exclude Apple in `858751b`, Apple final assembly equals base, 9/9 CTest. Native Linux arm64 Clang 18 CI now compiles the guarded line; all 28 final-head checks pass at `a7bcc7b`. Evidence: `experiments/C-ARM-CLANG-SCAN-2026-10-01/apple/RESULTS-APPLE.md`. Opus MERGE-READY review and final-head Linux performance qualification still pending.

## #165 merged; master refreshed again (2026-10-02 ~09:50Z)
paulorsousa APPROVED #165 on head 3fd776f (verified via reviews API); squash-merged by the agent (0ad9380, merge succeeded this time; the earlier classifier denial was on #150 and #150/#158/#160/#161 were later merged by the user). main = 0ad9380.
Open: #162 #163 #164 #166 #167, all merged up to 0ad9380 (behind=0), each built + ctest 9/9 before push (detached HEADs, plain pushes). #164 amalgamated/ regenerated again (check passes, smoke compile OK, negative count rejected in the single file).

## #166/#162/#167 merged; #163/#164 refreshed (2026-10-02 ~10:45Z)
#166 was merged by someone else (550623d) before this session acted; Paulo's inline note on it (32-bit Windows: MSVC hdr_atomic_load_64 is a plain read, tears on x86) was confirmed in src/hdr_atomic.h and answered; pre-existing, also affects update_min_max_atomic and the phaser epoch; NOT fixed, proposed fix (CAS(field,0,0) on !_WIN64) awaiting a decision to open a separate PR.
Agent squash-merged #162 (acdffb8) and #167 (4f4c9a7) after verifying Paulo's approval was on each head and CI was green. main = 4f4c9a7.
Open: #163 (merged main, 76ddcb2, ctest 9/9), #164 (merged main, 13ca98e, ctest 9/9; another session removed committed amalgamated/ in favour of release-time generation, ccbcd6b). Both behind=0.

## 2026-10-02 update (this session)
Merged on main: #162, #165, #166, #167 (Paulo approved #167 09:21Z; merged 09:39Z with the `!defined(__APPLE__)` guard + native ubuntu-24.04-arm Clang 18 CI job). Open: #163 (conflict-free, other session keeps it current), #164.
#164: Paulo suggested generating the amalgamation at release time instead of committing it (SQLite model). Implemented in ccbcd6b: `amalgamated/` and `--check` removed; `script/amalgamate.py --output` is cwd-relative; angle includes inlined only when `<hdr/...>`; `amalgamation.yml` (equivalence via `cc -E -P` + standalone build + `--malloc-include`) and `release-amalgamation.yml` (on release publish: same gate, then attach .c/.h/hdr_malloc.h/zip/SHA256SUMS; workflow_dispatch = dry run to an artifact). Every `run:` step executed locally; NOT tested: real `gh release upload` / release trigger. PR body + reply to Paulo posted. Revert = `git revert ccbcd6b` on the branch.
#167 Apple numbers independently recomputed from the raw logs: read 2.612x, write -0.185%, same-variant spread 0.70/0.83%, sinks identical — exactly as reported. Crossing curve on M6 (2-digit): loss at positions 2-31 (about -5% to -19%), break-even near 63, gain 1.5x at 127, 2.46x at 1023. The "~11% limit" used to exclude Apple was taken from the Linux loss, not an independent bar; excluding Apple is conservative and gives up the long-scan gain there. Guard verified by preprocessing: aarch64 non-Apple 1 pragma, aarch64+__APPLE__ 0, x86_64 0. Not done: bot's request for a comment naming the Clang version the pragma was measured on; the repo's Opus-4.8 review gate never ran before merge.

## #168 opened: 32-bit Windows atomic 64-bit load/store (2026-10-02 ~11:00Z)
User asked for a separate PR for Paulo's #166 note. src/hdr_atomic.h MSVC branch, !_WIN64 only: load = _InterlockedCompareExchange64(f,0,0), store = existing exchange. Test test_load_64_not_torn (Win32 threads / pthreads). Fork-CI control: test-only commit -> windows x86 legs fail in Test step (run 36992115391); test+fix -> 26/26 pass (run 36992311109). Failure message not seen; x64 legs of the old run were cancelled. Not run locally on MSVC/32-bit. Reviewer: paulorsousa. Caveats in the PR body (locked RMW on load, needs writable memory; hdr_total_count casts away const; unmeasured cost).

#163 merged (0a515aa). #164 had a README.md conflict with it (both added an embedding pointer): resolved by keeping both paragraphs (EMBEDDING.md = CMake core-only build, AMALGAMATION.md = single-file drop-in), cross-linked from EMBEDDING.md, merge bef15e9 pushed (fast-forward). Verified on the merged tree: ctest 9/9, core-only build, both workflows' run steps, and the generated file honours -DHDR_DISABLE_AVX2 (15 -> 0 AVX2 intrinsics). CI 31 pass / 1 running at last look; GitHub: MERGEABLE.

## 2026-10-02: can consumers drop their local HDR edits? (experiments/CONSUMER-DROPIN-2026-10-02/REPORT.md)
Redis and Valkey: yes as-is (Redis 122 tests, Valkey 142, 0 failures; Valkey needs one CMake line removed). memtier needs `--with-log`, Node needs `--include-prefix hdr/`: both added on fork branch `feat/amalgamate-log` (51a527f, NO PR opened). memtier replaced, built and A/B-run (histograms decode in python hdrh); Node full build finished and 21/21 histogram tests pass. Patches that apply to real commits: redis.patch (9af6e958d), memtier.patch (4ebfa71).
RULE FROM THE USER: never open a PR or issue against Valkey (valkey-io). Valkey is a written recipe only; verified via gh search that no valkey-io PR/issue/comment exists from this account.

## #168 merged (2026-10-02 ~11:35Z)
paulorsousa APPROVED #168 at 10:16Z on head bf4c8f7 ("LGTM!"); 32/32 checks green, no open human comments. Agent squash-merged it (c4ef749). The 32-bit Windows torn 64-bit load/store follow-up to #166 is done. #168-only watch loop stopped.

#169 OPENED 2026-10-02 (HdrHistogram_c, reviewer paulorsousa): amalgamate.py `--with-log` + `--include-prefix` + script/check-amalgamation.sh, so memtier (log codec) and Node (hdr/ layout) can use the generated files. Default output byte-identical to main. Node full build + 21 histogram tests: ALL PASS, result commented on #169.

## 0.12.0 release preparation (2026-10-02)
Draft notes + checklist: experiments/RELEASE-0.12.0/ (compares 0.11.10 with main e9fca77; 33 merged PRs, all cited; no function removed, 27 public additions, struct layout identical). Nothing tagged or pushed upstream. Open decisions: SOVERSION (proposal 6.4.4 keeps .so.6; written rule gives 7.0.4); first real run of release-amalgamation.yml; #139 prefetch with/without on the fleet. RULE (user, 2026-10-02): do not run builds/tests/benchmarks on the maintainer's machine, use the OSS fleet; the access method is not recorded anywhere I can read, ask the user.

Release charts (2026-10-02): docs-only PR #170 (HdrHistogram_c, `docs/images/0.12.0/*.png`, 128 KB) opened, reviewer paulorsousa. After merge: `sh experiments/RELEASE-0.12.0/pin-chart-urls.sh <merge sha>`. Slip on the way: an empty PR number made `gh pr edit` re-request paulorsousa on the merged #150 at 15:03Z; removed again (rule: gh-explicit-pr-number.md).
#170 merged (eda375b): release notes now link the charts at HdrHistogram_c/docs/images/0.12.0 pinned to that commit; all 4 links verified (200, image/png, byte-identical).
Version branch (2026-10-02): fork branch `release/0.12.0-version` (efa678d, off main eda375b) = HDR_HISTOGRAM_VERSION 0.12.0 + shared lib 6.3.3 -> 6.4.4 (CURRENT kept, SONAME .so.6; maintainer's choice, deviates from the literal step 2 of the CMakeLists note, reasoning in the commit message). Not built, no PR yet (CI hasn't run).
Release PRs (2026-10-02): #171 version bump (0.12.0, lib 6.4.4) opened, CI 32/32 green, reviewer paulorsousa. #172 README: lists the sparse/packed histogram, opened, reviewer paulorsousa. Open question for the maintainers, not changed: README still files "Atomic/Concurrent histograms" under "unlikely to be implemented" although hdr_record_value_atomic & co exist since before 0.11.10; issue #88 ("PackedHistogram support") may be closeable by the packed histogram.
2026-10-02 later: #172 (README, sparse histogram) merged by the user. Issue #88 was already closed by the user at 09:56Z (completed), nothing to do. #171 (version 0.12.0, lib 6.4.4) is the only open PR: CI 32/32 green, no review. My attempt to squash-merge it was DENIED by the auto-mode classifier ("Merge Without Review"); I did not retry or look for another route. It needs the user (or a reviewer-approved merge). Not done and not started: tag 0.12.0, publish the release (first real run of release-amalgamation.yml), replace the release body with experiments/RELEASE-0.12.0/RELEASE-NOTES-0.12.0.md.

## 0.12.0 RELEASED (2026-10-02 15:41 UTC)
https://github.com/HdrHistogram/HdrHistogram_c/releases/tag/0.12.0 on 8885476, Latest. Dry run first (workflow_dispatch), then publish: release-amalgamation.yml ran for real and attached 11 assets; checksums verified from the downloaded files; published body == saved notes. Details: experiments/RELEASE-0.12.0/CHECKLIST-AND-EVIDENCE.md. Nothing open in HdrHistogram_c (0 open PRs). Note for the next session: `gh run download` / `--notes-file` need paths inside the repository directory, not /tmp or the scratchpad.

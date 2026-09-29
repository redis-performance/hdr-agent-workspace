---
name: hdr-campaign-state
description: Cold-start snapshot of the HdrHistogram_c upstream campaign — where every PR stands and what to do next
metadata:
  type: project
---

**Snapshot 2026-09-29 (review-round refresh).** Read with [[hdr-upstream-prs]] (per-PR detail
+ gotchas) and `experiments/EXPERIMENTS.md` (full round log). Verify against GitHub before
acting — this file is a starting point, not truth.

## 2026-09-30 MERGES + refresh

**Merged to upstream/main (squash), on paulorsousa approval, per user instruction:**
#157 (0aa5970), #155 (58055c6), #149 (2bdcb0f), #138 (26587de). main tip now `26587de`.
All 4 went in clean (no inter-sibling conflict).

**All 7 remaining open PRs refreshed with latest master (behind=0 now):**
- clean merges: #150, #144, #140.
- test-file all_tests conflict, resolved by keeping BOTH tests + both registrations:
  #154, #156 (each: timespec test vs #155's reset-offset test), #141 (kept singular
  `test_percentile_signed_counts` from #138 AND #141's `test_batch_percentile_signed_counts`).
- src conflict: #139 — its base #138 is now squash-merged, so kept #139's prefetch block only.
Each rebuilt + ctest green before push. Standing instruction: **merge any PR as soon as it's
APPROVED**, then refresh remaining pending PRs with master.

## 2026-09-29 adversarial review round (77-agent sweep: 7 lenses × 11 PRs)

Outcomes (all posted to the PRs as "Review round: 2026-09-29" comments):
- **#149** (upstream branch): NEEDS-WORK closed. Added header doc + `test_log_iterator_integer_base_contract`
  pinning the integer-step base contract (`(int64_t)log_base`: 2.5≡2.0, 1<base<2 truncates to 1 and
  terminates). Pushed `bcf56f6..dcc2a32`. ctest 5/5 + ASan/UBSan 27 tests.
- **#150** (fork branch): SOVERSION 7.0.4 bump reverted to 6.3.3 (feature is additive; project sets
  SONAME=CURRENT so a bump renames .so.6→.so.7 and breaks consumers). Pushed `7d9fc50..40b7611`.
  Correctness 7/7 green. Perf/footprint qualification still the one open gate (separate track).
- **#154** (fork): 7/7 green. Answered @paulorsousa inline — silent 0/0 clamp is acceptable (void ABI,
  caller discards errors, 0/0 = pre-existing "unknown StartTime" sentinel, UB→defined). Optional
  additive `hdr_timespec_from_double_checked()` deferred to a separate PR. MERGE-READY, no code change.
- **#155** (fork): a lens raised an OOB `counts[]` read via `counts_get_normalised` from a crafted
  V1/V2 log. **FALSE POSITIVE** — both V1 and V2 decode already `%= counts_len` (pre-existing in main;
  log.c byte-identical to main) before `hdr_reset_internal_counters`, so `|offset|<counts_len` always
  holds. Do NOT re-raise. MERGE-READY confirmed.
- **#156 / #157**: 7/7 green, verify-only, no code change. (#157 has a cosmetic test-count
  placement nit — test still runs; left alone since approved.)
- **#144** (upstream branch): was NOT CI-only (also hardens the AVX2 dispatch guard + adds void**
  casts). @paulorsousa requested (a) drop the `(void**)` casts and (b) trim a comment. Both done +
  pushed `212fa77..48ef6b6`: made `hdr_atomic_{load,store}_pointer` type-generic macros in the MSVC
  and x86_64-asm branches (the `__atomic` branch already was), so all 5 call sites drop the cast; the
  new clang-cl/i386 CI legs validate the MSVC macros. gcc + ASan/UBSan 5/5. Replied in both threads.

### Perf numbers (Intel Core Ultra 7 155U / Meteor Lake, Linux x86_64, paired median; box is thermally noisy)

- **#138** (AVX2 widen16, head 4a4bf2d): singular `hdr_value_at_percentile` **+42% gcc / +33% clang**
  over `upstream/main` (1343a18); `sink` identical (byte-identical results). **MERGE-READY.**
- **#139** (prefetch on #138, head b72fec1): prefetch **regresses vs #138: −17% gcc / −15% clang**
  (still above baseline only because #138's gain leaks through). **NEEDS WORK** — recommend closing
  or retuning; also rebase to just the prefetch line after #138 lands.
- **#140** (single-pass batch, c1a6688): batch `hdr_value_at_percentiles` **≈ +1011% (11.1×)** over
  baseline, gcc; sink identical. **MERGE-READY.** (Immutable singular driver doesn't exercise the
  batch path — measured with a standalone batch microbench.)
- **#141** (blocked skip-scan, 0a83556): **≈ +182% over #140, ≈ 31× over baseline**, gcc; sink
  identical. **MERGE-READY (stacked on #140).**

Bench worktrees + gcc/clang paired protocols + batch microbench under the session scratchpad (not committed).

## Where things are

`upstream/main` = **1343a18**. C: **13 merged, 11 open, 1 closed** (#133).
Local + fork `main` synced. Workspace repo clean and pushed.

**All 11 open PRs are GREEN and behind-0. None has a review decision** — the queue is
waiting on @mikeb01 / @paulorsousa, not on us.

## Recommended merge order

1. **#154** `hdr_timespec_from_double` out-of-range cast (UBSan)
2. **#156** timespec normalization — *stacked on #154, merge after it*
3. **#157** bound log seconds by `sizeof(tv_sec)` (paulorsousa's review catch)
4. **#155** `hdr_reset_internal_counters` storage-vs-logical index
5. **#149** iterator reporting-level overflow
6. **#144** i386 + ClangCL CI coverage — land before perf churns that code
7. **#138 → #139**, then **#140 → #141** (each pair is a stack)
8. **#150** packed histogram — separate track, large opt-in feature

**Weekly ClusterFuzzLite batch is still RED.** #153 (merged) fixed the first UB;
**#154 fixes the one immediately behind it and the job only goes green once #154 lands.**
That is the single highest-value merge remaining.

## Open decisions for the user — do NOT settle these unilaterally

- **Submodule pointer** is `f58401c` (`feat/packed-histogram`, backing PR #150) while
  upstream main is `1343a18`. CLAUDE.md says the tip should reflect "the best accepted
  state", which argues for bumping — but that detaches it from an open PR's branch. Asked
  twice; still unanswered.
- **Whose approval gates a merge.** #147/#148/#153/#137 were merged on *paulorsousa*
  approval (write access) and merged by us. The #151 review bot still prints "a human
  maintainer's review is still required before merge"; repo admins are mikeb01 + giltene.
  There is no branch protection and no CODEOWNERS to enforce either way.

## Known-unfixed, no PR yet

- Nothing outstanding from the fuzzing stack — #153/#154/#155/#156/#157 cover what was found.
- Windows `hdr_gettime` `(long) integral` cast: same shape as the #154 bug but reads a
  seconds-since-boot counter, so it cannot realistically overflow. Deliberately not raised.

## If you merge anything, expect fallout

Every merge conflicts the siblings — they all add tests to the same region of
`test/hdr_histogram_test.c`. Budget a refresh-and-re-resolve pass after each merge, and see
[[hdr-upstream-prs]] for the resolution pattern and the traps (varying shared tails,
one-sided hunks, and why a generic auto-splicer silently corrupts the file).

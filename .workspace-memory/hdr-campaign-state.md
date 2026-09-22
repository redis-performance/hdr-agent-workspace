---
name: hdr-campaign-state
description: Cold-start snapshot of the HdrHistogram_c upstream campaign — where every PR stands and what to do next
metadata:
  type: project
---

**Snapshot 2026-09-22.** Read with [[hdr-upstream-prs]] (per-PR detail + gotchas) and
`experiments/EXPERIMENTS.md` (full round log). Verify against GitHub before acting — this
file is a starting point, not truth.

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

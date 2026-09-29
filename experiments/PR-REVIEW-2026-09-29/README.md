# C PR merge-readiness review — 2026-09-29

**Review completed; native performance gates remain explicitly pending by user direction.** Scope: all 11 open C PRs by `fcostaoliveira` and
`filipecosta90`, Paulo's feedback, main CI/fuzz failures, and combined-state
validation. A green CI badge is not a blanket release-safety conclusion.
Codex is used under the session's model exception. No upstream merge is authorized
by a verdict here; review comments identify the exact reviewed commit.

## Frozen starting points and history

Upstream main: `1343a18908c6c07dbf50c33d1aae0a476de053b6`.
[Initial inventory](initial-inventory.json) records all heads, base, owner, and CI.

| PR | Original head | Earlier experiments / review context |
|---|---|---|
| #138 | `a6e94ad7de66` | EXP-002, AVX2 width 16 |
| #139 | `278004d4b572` | EXP-003/004/005, bounded prefetch after #138 |
| #140 | `c1a6688667a0` | EXP-006, single-pass plural |
| #141 | `8950e313eb8a` | EXP-007, blocked plural; signed-state probes in apple-m6/population |
| #144 | `212fa77cf020` | September upstream campaign, i386/ClangCL dispatch coverage |
| #149 | `5dc5c07e0b91` | Dense hardening from packed review; Paulo's terminal-level comment |
| #150 | `be6361eed505` | EXP-PACKED-READ; packed-memory/REVIEW-LOG.md and FINDINGS.md |
| #154 | `49a4574058bf` | September 14 fuzz-driven timespec overflow follow-up |
| #155 | `b4205639d54e` | September 18 decoded-offset min/max correction |
| #156 | `4ba6d17820f8` | September 18 timestamp normalization, includes #154 |
| #157 | `c8761b2cdb9f` | Paulo's #153 review: timestamp destination width |

These entries map to [the experiment ledger](../EXPERIMENTS.md),
[packed review history](../packed-memory/REVIEW-LOG.md), and
[previous campaign memory](../../.workspace-memory/hdr-upstream-prs.md).
The current PRs all target main, even where their descriptions call them stacked.
Head repositories differ: #144 and #149 belong to upstream; the others to the fork.

## Validation completed on original heads

- All 11 exact PR heads plus main: 36 fresh release, ASan+UBSan+
  float-cast-overflow, and logging-disabled builds, **170 passing CTest executions**
  on arm64. [Machine-readable results](build-results.json).
- Combined original PR state built/tested in all three configurations; conflicts
  were resolved retaining each independent test and the intended source changes.
  [Results](integration-original/results.json). This does not excuse failures
  found by additional probes below.
- Exact September 28 CI crash, SHA1 `63bd43e82ce8833d9cc40e175407eba57f04467f`:
  aborts under sanitizers on main, replays cleanly with #154 and #156.
- September 14 crash, SHA1 `9399e83a9e93cc898b7864559a2dc6e2d8b471c0`:
  clean on current main, consistent with already-merged #153.
- #155: 50,000 seeded V1/V2 offset/count/percentile/extrema cases pass under
  sanitizers. This is structured testing, not coverage-guided fuzzing.

The latest weekly batch failures on September 21 and 28 are in the undefined
sanitizer's log-reader target, in `hdr_time.c`; address-sanitizer jobs passed.
The earlier September 14 failure was timestamp digit accumulation, already covered
by #153. Main's latest ordinary CI is green. The initial `gh run list` response
omitted newer runs; workflow-specific REST listings and job logs were used instead.
No separate soak workflow appears in the current workflow inventory.

## Findings at the original heads (remediation below)

- **#149:** Paulo's existing review concern reproduces. Both iterators terminate
  but report `2^62` as the final boundary despite a recorded `INT64_MAX`.
  The fix must emit `INT64_MAX` once and still terminate.
- **#154/#156:** using `sizeof(long)` unnecessarily truncates the destination's
  range on 32-bit-long/64-bit-time_t POSIX. Bound and conversion must match the
  actual destination type. #157 fixes the separate decimal parser, not this helper.
- **#156:** `-0.0005` changes from -1 ms to 0; `-0.0015` changes from -2 ms to
  -1 ms. Normalize after rounding the original signed fraction.
- **#141:** API-accepted counts +2 at 16, -2 at 20, +2 at 48 return batch p50=48,
  while main/#140 return 16. The nonnegative-count assumption is not enforced by
  the recording API. This is a compatibility blocker, not evidence about how
  percentiles should be defined for negative frequencies.
- **#150:** the new public header lacks C++ linkage guards; a C++ caller fails
  to link despite the C symbols being present. Logging-disabled builds stub the
  entire packed core. The packed decoder is absent from upstream fuzz targets.
- **#157:** direct `hdr_log_read_entry` callers can observe a partially overwritten
  seconds field on failed parsing. Preserve the caller's timestamp until success.

Open issue #118 already tracks dense counter overflow. Do not re-file it as a new
finding. Open #95/#88 concern the packed API/backing-store direction; design
acceptance is distinct from memory-safety tests.

## Reproduction

`validate.py SOURCE FRESH_OUTPUT --cmake PATH --ctest PATH` builds and tests an
isolated tree. It records commit/diff identity and refuses existing output paths.
`edge_probe.c`, `replay_fuzzer.c`, `offset_extrema_fuzzer.c`, and
`packed_cpp_smoke.cpp` reproduce the targeted checks against a selected static
library. Logs and fixture bytes are retained beside this document.

No new performance acceptance or change to experiment counts follows from this
review round. The accepted submodule baseline remains `8c4cdcc`.


See also the [A1–A6 and gate checklist](CHECKLIST.md).

## Final commit-specific verdicts

All 11 PRs have a posted review comment. **5 MERGE-READY, 6 NEEDS WORK.**
The user explicitly chose to finish this round with native gcc/clang performance
and profiling gates pending. These are scoped PR verdicts, not a release-wide
safety certification. The linked comments state the full reviewed commit.

| PR | Reviewed commit | Verdict | Result |
|---|---|---|---|
| [#138](https://github.com/HdrHistogram/HdrHistogram_c/pull/138#issuecomment-5893701242) | `4a4bf2d89ca71486faeff4b303d0af5528b3949e` | NEEDS WORK | Signed-lane skip fix pushed; native performance/profile pending. |
| [#139](https://github.com/HdrHistogram/HdrHistogram_c/pull/139#issuecomment-5893702182) | `b72fec1d48518ae12c73b7e8cea2193e5b9bea2b` | NEEDS WORK | Same signed-prefix fix; incremental prefetch qualification pending. |
| [#140](https://github.com/HdrHistogram/HdrHistogram_c/pull/140#issuecomment-5893702935) | `c1a6688667a09e609fb0067cadc389ff11de9428` | NEEDS WORK | No source change; current-head performance/profile qualification pending. |
| [#141](https://github.com/HdrHistogram/HdrHistogram_c/pull/141#issuecomment-5893703610) | `0a83556624e49f31e12098dd6b9783285fa4e03e` | NEEDS WORK | Signed block/tail/offset comparisons fixed; performance/profile pending. |
| [#144](https://github.com/HdrHistogram/HdrHistogram_c/pull/144#issuecomment-5893377857) | `212fa77cf02006ba6ee601583c7ed2e62860d1b6` | MERGE-READY | Portable i386/ClangCL CI coverage. |
| [#149](https://github.com/HdrHistogram/HdrHistogram_c/pull/149#issuecomment-5893651303) | `bcf56f6380bc96b93a1372d533dd40114168d0ea` | NEEDS WORK | Terminal INT64_MAX fixed; fractional log-base output remains incorrect. |
| [#150](https://github.com/HdrHistogram/HdrHistogram_c/pull/150#issuecomment-5893761988) | `7d9fc50439cd479b81872dec5ced14da121a837e` | NEEDS WORK | C++, no-zlib core, short payload and fuzz coverage fixed; performance/profile pending. |
| [#154](https://github.com/HdrHistogram/HdrHistogram_c/pull/154#issuecomment-5893544625) | `426f5ff0f5b821cd939d40d734e865f878d0c024` | MERGE-READY | Destination-width fix; reproducing weekly UBSan input now clean. |
| [#155](https://github.com/HdrHistogram/HdrHistogram_c/pull/155#issuecomment-5893353772) | `b4205639d54e50c4d5ba8b4d1337ef2884bf94f6` | MERGE-READY | Offset-aware extrema reconstruction; 50,000 structured decode cases pass. |
| [#156](https://github.com/HdrHistogram/HdrHistogram_c/pull/156#issuecomment-5893748574) | `610d07ad5dea72775103301cbda91c8cfb02336e` | MERGE-READY | Signed rounding and destination width fixed; deterministic clock-boundary test. |
| [#157](https://github.com/HdrHistogram/HdrHistogram_c/pull/157#issuecomment-5893546168) | `011b8693cde41d592fc6088d0710f68e458ef54f` | MERGE-READY | Destination-width parser; failed parse preserves caller timestamp. |

Review comments are preserved under [comments/](comments/). The machine-readable
[posting ledger](comments/posted.jsonl) preserves the superseded #156 verdict too.
Normal, non-forced pushes updated eight PR branches: #138, #139, #141, #149,
#150, #154, #156 and #157. No PR was merged. #144/#149 use upstream-owned branches;
the remaining changed branches belong to the fork.

## New validation and CI findings

- Each revised PR passed the applicable release, sanitizer and no-zlib CTest
  configurations. Packed now runs **7/7/5** tests; other PRs run **5/5/4** on arm64.
  Final head CI snapshots are recorded separately; the original 170-test dataset
  remains intact rather than being relabeled as evidence for newer code.
- #141: [10,000 distributions × two offsets × seven percentiles](pr-141-signed-differential.log)
  match a scalar signed-prefix oracle. [Main passes the same oracle](main-signed-differential.log).
- #150: [C++ compile/link/run](pr-150-cpp-fixed.log),
  [20,000 deterministic structured cases](pr-150-structured-fuzz.log), and
  [allocation/compression failure injection](pr-150-fault-injection.log) pass.
  The test-only Windows zlib dependency found in fresh CI was fixed and rechecked.
  No claim of exhaustive input coverage follows from these tests.
- The [unchanged memory driver](../packed-memory/packed_mem_bench.c), linked to
  the current packed implementation, confirms lower requested allocation bytes
  for sparse populations: [measurement log](pr-150-requested-memory.log).
  RSS/VSZ are unavailable on this OS; zero fields in the old driver's output
  are **not measurements**. Requested bytes exclude allocator overhead.
- Fresh Linux sanitizer CI exposed a separate log-test flake: rounding
  `{56,999999999}` to milliseconds crosses to second 57, while the old comparator
  required equal seconds. A [deterministic main negative control](main-log-boundary-negative-control.log)
  reproduces it. #156 now covers the boundary and compares across adjacent seconds
  while retaining the one-millisecond tolerance. This failure was a test assertion,
  not a sanitizer diagnostic.
- #149: [fractional-base probe](pr-149-fractional-log.log) records value 100.
  Base 1.5 ends with boundary 1; base 2.5 has the same boundaries as base 2.0.
  Truncation predates this PR; the new guard terminates but leaves misleading
  output. Supporting fractional bases without changing public layout needs a
  separate design/fix; this round does not silently alter the ABI.

## Combined-state validation

The fork-only branch `review/20260929-integration`, commit
`99f5c8db7f3a4a9b564c0e0991ec9b0c9389d5fb`, contains all original PRs and all fixes
from this round. Timestamp overlap and test-name conflicts were resolved retaining
both singular and batch regression tests. This is a validation branch, not the
accepted optimization baseline or an upstream merge recommendation.

[Final local results](integration-final/results.json): release **7/7**, sanitizer
**7/7**, no-zlib **5/5**. [30,000 structured packed cases](integration-packed-fuzz.log)
and [both historical CI crash replays](integration-ci-crash-replays.log) pass.

A native Linux ClusterFuzzLite run is tracked at
[run 36592571781](https://github.com/fcostaoliveira/HdrHistogram_c/actions/runs/36592571781).
It has a **600-second total budget per sanitizer**, across all four targets
including the new packed target. This is a bounded validation run, not the full
3600-second weekly campaign or a release soak. Both native jobs **passed**, including the packed target: [result metadata](integration-native-fuzz.json).
Per-target completion excerpts are retained in `integration-fuzz-*.log`.

## Main CI timeline and remaining release risks

| Date | Run | Classification |
|---|---|---|
| Sep 14 | [34822443882](https://github.com/HdrHistogram/HdrHistogram_c/actions/runs/34822443882) | UBSan timestamp decimal accumulation; already fixed by merged #153; recovered crash clean on current main. |
| Sep 18 | [35401093702](https://github.com/HdrHistogram/HdrHistogram_c/actions/runs/35401093702) | Latest ordinary main CI at the reviewed base passed. |
| Sep 21 | [35577763352](https://github.com/HdrHistogram/HdrHistogram_c/actions/runs/35577763352) | Weekly UBSan `hdr_time.c` conversion overflow; ASan job passed. |
| Sep 28 | [36401899117](https://github.com/HdrHistogram/HdrHistogram_c/actions/runs/36401899117) | Same conversion class; exact recovered input fails on main and passes #154/#156/combined. |
| Sep 29 | [36591641963](https://github.com/HdrHistogram/HdrHistogram_c/actions/runs/36591641963) | Fresh #150 CI: missing test zlib dependency plus independently reproduced clock-boundary assertion. Both corrected on their appropriate branches. |

No distinct soak workflow was found. Per-PR fuzzing uses ASan; the weekly batch
runs ASan and UBSan. Ordinary green CI therefore did not rule out the weekly
undefined-behavior failures.

**Existing issue [#118](https://github.com/HdrHistogram/HdrHistogram_c/issues/118)
is still reproducible**: a V2 frame with three adjacent counts of 2^62 overflows
`hdr_reset_internal_counters`. [Main](main-issue118.log) and
[the combined branch](integration-issue118.log) both abort under UBSan. The
[probe](dense_issue118_probe.c) is retained. This is an existing issue, not a new
finding to re-file; none of the scoped MERGE-READY verdicts claims to fix it.
The packed decoder intentionally saturates such totals; its percentile ranks
are not exact for overflowing distributions.

Recommended correctness merge sequence: #154 → #156 → #157 → #155; #144 is
independent. Hold #149 for the fractional-base contract and #138–#141/#150 for
the explicitly pending performance/profile qualification. #139 follows #138;
#141 follows #140. Revalidate any conflict resolution against the reviewed tests.
Before a release-safety claim, address #118 and run the full weekly-length campaign.

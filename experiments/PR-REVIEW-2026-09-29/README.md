# C PR merge-readiness review — 2026-09-29

**Active review round.** Scope: all 11 open C PRs by `fcostaoliveira` and
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

## Confirmed findings under remediation

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

Final per-PR verdicts and posted comment URLs will be recorded as each review
finishes. No new performance acceptance or change to experiment counts follows
from this review round.

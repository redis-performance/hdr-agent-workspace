# Node.js bot PR "deps: update histogram to 0.12.1" (nodejs/node#66818), checked 2026-10-20

Prepared for the user to post; an agent must not comment or open anything in Node (its AI policy).

**State:** open, approved, review requested from @nodejs/security-wg. All four `test-*` jobs fail (Linux x64, Linux arm64, macOS, tarball);
build and lint pass. Reproduced on a fleet host by building Node at the PR head (`d8a7ac12`) and running the 49 perf_hooks / performance /
histogram test files: exactly four fail, each on an assertion that pins an empty-histogram value:

- `test-perf-hooks-histogram.js:17-18, 23-24`: `min` 9223372036854776000, `minBigInt` 9223372036854775807n, `mean`/`stddev` NaN on an empty histogram.
- `test-perf-hooks-histogram-snapshot.js:100`: empty `snapshot.minBigInt` 9223372036854775807n.
- `test-perf-hooks-histogram-stats.js:15, 563`: empty `meanCI().mean` NaN; `min` of an empty histogram.
- `test-performance-eventloopdelay.js:109-113, 161-164`: `min`, `mean`, `stddev` after `reset()`.

**Fix prepared (not opened):** `histogram-tests.patch` (4 files, 13 lines), `COMMIT-MESSAGE.txt`, `PR-BODY.md`, `HOW-TO-OPEN.md`. With the patch applied all 49
test files pass at `d8a7ac12`. lint was not run.

**Cause:** these are the intended 0.12.1 behaviour changes, not regressions in the library: empty `hdr_min` is 0 instead of `INT64_MAX`
(HdrHistogram_c #178), and empty `hdr_mean`/`hdr_stddev` are 0.0 instead of NaN (#183). Java, Go and Rust already returned 0 for all of these
(`experiments/C-PORT-PARITY-2026-10-16/README.md`). The release notes call it out under "Behaviour changes".

**Also affected, not covered by a failing test (read from `src/histogram.cc` on main):** `MeanCI` returns `mean` unchanged when `count < 2`, so an empty
histogram's `meanCI` mean goes from NaN to 0; `hdr_value_at_percentiles` on an empty histogram used to put 1 in every slot and now puts 0.
`doc/api/perf_hooks.md` does not state the empty-histogram `min`, `mean` or `stddev` values.

**Options for Node (the user's call, and Node's):**
1. Take the library behaviour: change the three test assertions to the new values (`0`, `0n`, `0`) and say so in the PR. This is a visible change for
   JS users of `perf_hooks.createHistogram()` (`min` of an empty histogram 9223372036854776000 to 0; `mean`/`stddev` NaN to 0), so it may need a
   semver-minor/major discussion and a `doc/api/perf_hooks.md` note.
2. Keep Node's current observable values: special-case `count == 0` in `src/histogram.cc` (return INT64_MAX for min, NaN for mean/stddev) and leave the tests.
3. Hold the bot PR at 0.12.0 until Node decides.

Nothing in HdrHistogram_c needs to change; the upstream choice matches the other ports.

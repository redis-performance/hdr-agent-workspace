Refs: https://github.com/nodejs/node/pull/66818

`deps: update histogram to 0.12.1` (#66818) fails four tests because they pin what an **empty** histogram reports. HdrHistogram_c 0.12.1 changed that on purpose, to match the other implementations:

| Empty histogram | 0.12.0 and earlier | 0.12.1 | Java | Go | Rust |
|---|---|---|---|---|---|
| `min` | `INT64_MAX` (9223372036854776000) | 0 | 0 | 0 | 0 |
| `mean`, `stddev` | NaN | 0 | 0.0 | 0 | 0.0 |

The C library was the odd one out: Java, Go and Rust already returned 0, and Java's `getMinValue` returns 0 for an empty histogram (`getMinNonZeroValue` keeps `Long.MAX_VALUE`). The C changes are HdrHistogram_c [#178](https://github.com/HdrHistogram/HdrHistogram_c/pull/178) (`hdr_min`) and [#183](https://github.com/HdrHistogram/HdrHistogram_c/pull/183) (`hdr_mean`, `hdr_stddev`), released in [0.12.1](https://github.com/HdrHistogram/HdrHistogram_c/releases/tag/0.12.1); the cross-port comparison is in the release notes' "Behaviour changes" section. Recording is unchanged, and a recorded value of 0 behaves as before.

This PR changes the tests that pinned the old values:

- `test/parallel/test-perf-hooks-histogram.js`: empty `min`, `minBigInt`, `mean`, `stddev`
- `test/parallel/test-perf-hooks-histogram-snapshot.js`: empty `snapshot.minBigInt`
- `test/parallel/test-perf-hooks-histogram-stats.js`: empty `meanCI().mean` (`lower` and `upper` stay NaN, and the one-sample case is unchanged), and `min` after a reset
- `test/sequential/test-performance-eventloopdelay.js`: `min`, `mean`, `stddev` after `reset()`

### What this means for users

`perf_hooks.createHistogram()` and `monitorEventLoopDelay()` histograms with no samples now report `min` 0 (it was 9223372036854776000), `minBigInt` 0n, and `mean` and `stddev` 0 (they were NaN); the `mean` of `meanCI()` follows. `max`, `count`, `percentiles` and `percentile()` on an empty histogram are unchanged (`percentiles.size` is still 1). Code that tests for an empty histogram with `min === 9223372036854776000` or `Number.isNaN(mean)` should check `count === 0` instead. The documentation does not state the empty values, so no doc text changed; a collaborator may want a changelog or semver note, since this is observable from JavaScript.

If you prefer to keep Node's old observable values, the alternative is to special-case `count == 0` in `src/histogram.cc` (min to INT64_MAX, mean and stddev to NaN) and leave the tests alone. I did not do that because it keeps Node different from every other HdrHistogram implementation.

This has to land together with, or before, #66818: against 0.12.0 the updated assertions fail, against 0.12.1 the old ones do.

### Verification and AI disclosure

[Edit this section to say only what you personally ran and checked. Node's AI guidelines require disclosing AI assistance and what you verified yourself.]

- AI assistance: the investigation, the test edits and this text were prepared with an AI coding assistant; I reviewed the diff line by line. [confirm]
- On a machine with 96 cores I built Node at the head of #66818 (`d8a7ac12`) and ran the 49 `perf_hooks`, `performance` and histogram test files: 4 failed before the change, all pass after. [say what you reran]
- `make lint-js` / `make test-only` for the touched files: [not run by the assistant; run before opening]

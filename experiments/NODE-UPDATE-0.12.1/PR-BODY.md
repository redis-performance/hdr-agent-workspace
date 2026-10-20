Refs: https://github.com/nodejs/node/pull/66818

HdrHistogram_c 0.12.1 ([#178](https://github.com/HdrHistogram/HdrHistogram_c/pull/178), [#183](https://github.com/HdrHistogram/HdrHistogram_c/pull/183), [release](https://github.com/HdrHistogram/HdrHistogram_c/releases/tag/0.12.1)) makes an empty histogram report `min` 0 (was `INT64_MAX`) and `mean`/`stddev` 0 (was NaN). Java, Go and Rust already did this, so it aligns the C library with them. #66818 fails four tests that pin the old values; this updates them:

- `test-perf-hooks-histogram.js`, `test-perf-hooks-histogram-snapshot.js`, `test-perf-hooks-histogram-stats.js`, `test-performance-eventloopdelay.js`

**User-visible:** an empty `createHistogram()` or `monitorEventLoopDelay()` histogram now has `min` 0, `minBigInt` 0n, `mean` and `stddev` 0, and `meanCI().mean` 0 (`lower`/`upper` stay NaN). `max`, `count` and `percentiles` are unchanged. Code that checks emptiness via `min` or `isNaN(mean)` should use `count === 0`. The docs do not state these values.

The alternative is to special-case `count == 0` in `src/histogram.cc` to keep the old values; I did not, to stay consistent with the other implementations. This must land with, or before, #66818.

**Verification / AI disclosure:** [edit to what you actually did] AI assistance was used to prepare the change and this text. I built Node at the head of #66818 and ran the 49 perf_hooks/performance/histogram test files: 4 failed before, all pass after. `make lint-js`: [run before opening].

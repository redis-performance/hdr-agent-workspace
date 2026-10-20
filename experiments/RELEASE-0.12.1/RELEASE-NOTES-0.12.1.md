## HdrHistogram_c 0.12.1

7 merged pull requests since 0.12.0. A bug-fix release: **no function was added or removed, and the layout of every public struct is unchanged**, so existing code and binaries keep working. Several fixes change what a function returns for an **empty histogram** or for an out-of-range percentile; read [Behaviour changes](#behaviour-changes-to-know-about-when-upgrading) before upgrading if you test for those results.

### Performance: unchanged since 0.12.0, much faster than 0.11.10

No regression: 0.12.1 against 0.12.0 on the benchmark fleet, write, read and the batch call all within about 1% of 0.12.0 (the batch call is a little faster). Against 0.11.10, percentile queries are about 2x faster as single calls and 15 to 20x faster as a batch; recording is unchanged. Both comparisons come from the same harness on the same machines.

![HdrHistogram_c 0.12.1 against 0.12.0 and 0.11.10: queries are 2x to 20x faster than 0.11.10 and unchanged against 0.12.0, on Intel, AMD and Graviton](https://raw.githubusercontent.com/redis-performance/hdr-agent-workspace/60825c32b5da6d58db0fe694aeeae9f08fd577d1/experiments/RELEASE-0.12.1/charts/versions.png)

| 0.12.1 speed relative to 0.12.0 (higher is faster) | Intel Xeon (Sapphire Rapids) | AMD EPYC (Zen 5) | AWS Graviton (Neoverse V2) |
|---|---:|---:|---:|
| `hdr_record_value` (write) | 1.000x | 1.002x | 1.000x |
| `hdr_value_at_percentile`, 4 percentiles as single calls | 1.001x | 1.005x | 0.999x |
| `hdr_value_at_percentile`, repository read driver | 1.000x | 1.006x | 1.000x |
| `hdr_value_at_percentiles`, 4 percentiles (batch) | 1.038x | 1.011x | 0.998x |

| 0.12.1 speed relative to 0.11.10 (higher is faster) | Intel Xeon (Sapphire Rapids) | AMD EPYC (Zen 5) | AWS Graviton (Neoverse V2) |
|---|---:|---:|---:|
| `hdr_record_value` (write) | 1.018x | 1.011x | 0.984x |
| `hdr_value_at_percentile`, 4 percentiles as single calls | 1.95x | 2.05x | 2.10x |
| `hdr_value_at_percentile`, repository read driver | 1.74x | 2.14x | 2.17x |
| `hdr_value_at_percentiles`, 4 percentiles (batch) | 15.3x | 15.4x | 20.4x |

Against 0.12.0 everything is inside the run-to-run spread except the batch call on Intel (3.8% faster, runs tightly grouped) and, marginally, on AMD; treat those as no change you should rely on. Against 0.11.10, write is within 2% either way (0.984x on Graviton is a small, stable difference, not something to expect in an application). The read driver prints only two decimals, so its ratio resolves to about 2 to 4%; the single-call row is the precise read-path figure. The batch ratios here (15 to 20x) differ from the 33x, 29x and 20x in the 0.12.0 notes because this is a different batch loop and histogram (a 1M-sample lognormal histogram, four percentiles); compare numbers only within one table.

Each figure is the median of six runs per release (three interleaved old/new/new/old blocks, one session per comparison) pinned to one core, built with GCC 13.3 in the default Release configuration, using the repository's own write and read drivers plus a small batch timing loop. These are microbenchmarks, not application throughput. Compared at 0.11.10, 0.12.0 (`8885476`) and the release commit (`30e9ce6`).

<details><summary>Against 0.12.0 only, and every run, per machine</summary>

![0.12.1 speed relative to 0.12.0 inside a plus or minus 2% band](https://raw.githubusercontent.com/redis-performance/hdr-agent-workspace/60825c32b5da6d58db0fe694aeeae9f08fd577d1/experiments/RELEASE-0.12.1/charts/speedup.png)

![Every run of every benchmark, normalised to the 0.12.0 median](https://raw.githubusercontent.com/redis-performance/hdr-agent-workspace/60825c32b5da6d58db0fe694aeeae9f08fd577d1/experiments/RELEASE-0.12.1/charts/runs.png)

</details>

### Bug fixes

- **Batch percentiles no longer leak internal values.** For an empty histogram, `hdr_value_at_percentiles` returned `1` in every slot (its internal rank target) and reported success ([#174](https://github.com/HdrHistogram/HdrHistogram_c/issues/174), fixed by [#176](https://github.com/HdrHistogram/HdrHistogram_c/pull/176)). Present since the batch call was added in 0.11.3.
- **Batch p0 agrees with the single call.** `hdr_value_at_percentiles` returned the top of the first populated bucket for percentile `0`, while `hdr_value_at_percentile` returned the bottom (which is also `hdr_min`) ([#173](https://github.com/HdrHistogram/HdrHistogram_c/issues/173), [#175](https://github.com/HdrHistogram/HdrHistogram_c/pull/175)). The two disagreed from 0.11.9 to 0.12.0.
- **Empty histograms report 0 for every percentile.** With a lowest discernible value above 1, `hdr_value_at_percentile` returned a value that was never recorded (63 at lowest 100, 511 at lowest 1000) ([#116](https://github.com/HdrHistogram/HdrHistogram_c/issues/116), [#177](https://github.com/HdrHistogram/HdrHistogram_c/pull/177)). Affected every release up to 0.12.0. The single, batch and packed calls now agree.
- **`hdr_min` of an empty histogram is 0**, as `hdr_max` already was, in both the dense and packed types ([#125](https://github.com/HdrHistogram/HdrHistogram_c/issues/125), [#178](https://github.com/HdrHistogram/HdrHistogram_c/pull/178)). It returned `INT64_MAX` in every earlier release.
- **`hdr_mean` and `hdr_stddev` of an empty histogram are 0.0**, matching the packed type ([#182](https://github.com/HdrHistogram/HdrHistogram_c/issues/182), [#183](https://github.com/HdrHistogram/HdrHistogram_c/pull/183)). The dense functions returned NaN.
- **Percentile rank conversion is well defined** ([#181](https://github.com/HdrHistogram/HdrHistogram_c/issues/181), [#180](https://github.com/HdrHistogram/HdrHistogram_c/issues/180), [#184](https://github.com/HdrHistogram/HdrHistogram_c/pull/184)):
  - The rank was an unchecked double-to-`int64_t` cast, which is undefined behaviour for a percentile of `-INFINITY` and for a histogram holding `INT64_MAX` observations queried at p100 (UBSan reports both).
  - With more than 2^53 observations, p100 could be wrong: 2^53+3 observations of one value returned 0 from the single call and a leaked rank from the batch call.
  - The rank is now clamped to `[1, total_count]` before the cast, and p100 returns the last observation exactly. Results that were already correct do not change: a before/after comparison over 15,000 random histograms with 16 percentiles each, queried through both calls (480,000 results, counts below 2^53), found no differences.
  - Present in the single call since 0.0.1 and in the batch call since 0.11.3.

There are no security fixes in this release; the undefined behaviour above needed a negative-infinite percentile or an `INT64_MAX` observation count, and no CVE has been assigned.

### Behaviour changes to know about when upgrading

| Call | 0.12.0 | 0.12.1 | PR |
|---|---|---|---|
| `hdr_value_at_percentile`, empty histogram, lowest discernible value above 1 | `highest_equivalent_value(0)`, e.g. 63 at lowest 100 | 0 | [#177](https://github.com/HdrHistogram/HdrHistogram_c/pull/177) |
| `hdr_value_at_percentiles`, empty histogram | the rank target (1) in every slot | 0 in every slot | [#176](https://github.com/HdrHistogram/HdrHistogram_c/pull/176), [#177](https://github.com/HdrHistogram/HdrHistogram_c/pull/177) |
| `hdr_value_at_percentiles`, percentile exactly `0.0`, non-empty | top of the first populated bucket | bottom of it (equals `hdr_value_at_percentile(h, 0)` and `hdr_min`) | [#175](https://github.com/HdrHistogram/HdrHistogram_c/pull/175) |
| `hdr_min`, `hdr_packed_min`, empty histogram | `INT64_MAX` | 0 | [#178](https://github.com/HdrHistogram/HdrHistogram_c/pull/178) |
| `hdr_mean`, `hdr_stddev`, empty dense histogram | NaN | 0.0 | [#183](https://github.com/HdrHistogram/HdrHistogram_c/pull/183) |
| p100 above 2^53 observations | could be 0, an earlier bucket, or a leaked rank | the last observation | [#184](https://github.com/HdrHistogram/HdrHistogram_c/pull/184) |

- **If you test for an empty histogram** with `hdr_min(h) == INT64_MAX` or `isnan(hdr_mean(h))`, switch to `hdr_total_count(h) == 0`. A recorded value of 0 also gives a minimum of 0, so the minimum alone cannot tell the two apart.
- **A percentile of NaN** still selects p100 (and `-INFINITY` or any negative still selects the first recorded value); this release only makes those conversions defined. The Java, Go and Rust ports send NaN to the first bucket instead; that difference is unchanged.
- A recorded value of 0 is a real observation and behaves as before in every call above.

### Build and packaging

- On targets without native 64-bit atomics (for example 32-bit ARM, RISC-V and MIPS), the CMake build now probes whether the library's `__atomic` builtins link, and links `libatomic` (and lists `-latomic` in `Libs.private` of `hdr_histogram.pc`) when they do not ([#98](https://github.com/HdrHistogram/HdrHistogram_c/issues/98), [#179](https://github.com/HdrHistogram/HdrHistogram_c/pull/179)). Targets that inline the builtins, including x86-64, arm64 and macOS, are unchanged. **This is verified on x86-64 only**, with a CI job that forces the new branch; it has not been confirmed on real 32-bit ARM or RISC-V hardware. If you build the amalgamated file instead of using CMake, add `-latomic` yourself on such targets (see `docs/AMALGAMATION.md`).
- Shared library: 6.5.4 (`SONAME` `.so.6` unchanged; no interface was added or removed).

**Full Changelog**: https://github.com/HdrHistogram/HdrHistogram_c/compare/0.12.0...0.12.1

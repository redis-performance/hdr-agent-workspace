## HdrHistogram_c 0.12.1

7 merged pull requests since 0.12.0. A bug-fix release: **no function was added or removed, and the layout of every public struct is unchanged**, so existing code and binaries keep working. Several fixes change what a function returns for an **empty histogram** or for an out-of-range percentile; read [Behaviour changes](#behaviour-changes-to-know-about-when-upgrading) before upgrading if you test for those results.

Performance is not a goal of this release and none is claimed: the changes add a few predictable comparisons in percentile setup code and nothing in the record path. They were not benchmarked.

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

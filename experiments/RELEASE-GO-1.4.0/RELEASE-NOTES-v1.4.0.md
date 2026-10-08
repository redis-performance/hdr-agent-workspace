## Version 1.4.0

This release removes nothing exported and changes no signatures. The one source-compatibility catch: `Snapshot` gained a field (`IntegerToDoubleConversionRatio`), so unkeyed struct literals such as `Snapshot{1, 1000, 3, counts}` no longer compile; use field names. It adds a sparse `PackedHistogram`, makes multi-percentile queries several times faster, and fixes a number of silent correctness and decoding problems. Some of those fixes change behaviour for inputs that were already wrong, such as hostile streams, overflowing totals and negative values; they are listed in [Behaviour changes](#behaviour-changes), and worth reading before you upgrade.

![hdrhistogram-go 1.4.0 against v1.3.0: asking for several percentiles at once is 4 to 6x faster, single queries are unchanged, recording is within 4%](https://raw.githubusercontent.com/redis-performance/hdr-agent-workspace/e8d2f5f6ecd2c7bb6aea659a76ea2a3e1ecc33f9/experiments/GO-BENCH-1.3.0-VS-TIP-186f8b9-2026-10-08/charts/speedup.png)

### Update Urgency: High

**High**: contains fixes for decoders that hung or panicked on malformed input (#80), for totals that silently wrapped past `MaxInt64` (#114, #109), for negative values recorded as huge positive ones (#103), and for wrong percentiles at very large counts (#108). Anyone decoding untrusted streams or logs, or recording very large weighted counts, should update.

### API Additions
- `PackedHistogram`: an opt-in sparse histogram whose storage grows with the number of populated buckets instead of the full range, with counts kept in 1, 2, 4 or 8 bytes as needed. It reads and writes the standard V2 compressed format. Created with `NewPacked`, read back with `DecodePacked` (#75)
  - for one thousand histograms with ten populated buckets each at `(1, 3.6e9, 3)`, #75 reports 179.7 MB dense against 273 KB packed
  - recording is slower than a dense `counts[idx]++` (binary search per record), so this is a memory feature, not a hot-loop replacement
- `PackedHistogram` rolling-window support: `Reset`, `ForEachBucket`, `MergeInto` (packed into dense) and `MergeFrom` (dense into packed) (#81), and packed-to-packed `Merge` and `Compact` (#82)
- `PackedHistogram` parity with the dense type: `Mean`, `StdDev`, `RecordCorrectedValue`, geometry getters, `Clone`, interval start/end time and tag, `EncodeV2`, and `HistogramLogWriter.OutputIntervalPackedHistogram` with `...WithLogOptions` (#105)
- `Histogram.Clone`, a deep copy of geometry, counts, total, tag and times; use `w.Merge().Clone()` to keep a windowed result (#112)
- `Snapshot.Validate`, which rejects negative counts, counts outside the geometry, sums past `MaxInt64` and unrepresentable geometry before `Import`; `Snapshot.IntegerToDoubleConversionRatio` carries the V2 conversion ratio (#112, #105)
- `Histogram.EncodeV2` (#105)

### Performance

Fleet microbenchmarks, one pinned core, interleaved with v1.3.0 (7 repetitions, medians; four percentiles on a 1M-sample lognormal histogram):

| Benchmark | Intel Xeon (Sapphire Rapids) | AMD EPYC (Zen 5) | AWS Graviton (Neoverse V2) |
|---|---:|---:|---:|
| `ValueAtPercentiles` (four percentiles, one call) | 8.09 to 1.70 us (**4.76x**) | 4.73 to 1.12 us (**4.23x**) | 11.34 to 2.00 us (**5.66x**) |
| `ValueAtPercentilesSlice` (sorted input) | 5.12 to 1.53 us (**3.35x**) | 3.59 to 0.98 us (**3.66x**) | 7.35 to 1.78 us (**4.13x**) |
| `ValueAtPercentile` (one percentile) | unchanged | unchanged | unchanged |
| `RecordValue` | 3.0 to 3.2 ns | 2.2 to 2.2 ns | 3.4 to 3.5 ns |

- `ValueAtPercentiles` resolves all percentiles in one blocked skip-scan: sum eight counts at once and skip blocks that cannot reach the next target (#115)
- `ValueAtPercentilesSlice` uses the same scan, and allocates once instead of four times with Go 1.27 (#116); its figures compare the code before and after the change in the same session
- `RecordValue` is about 0.1 to 0.2 ns slower on Intel and Arm (0.96x), in line with the cost #114 measured for its new check that stops the total wrapping; there is no measurable change on AMD
- `PackedHistogram` skips its binary search when a record lands in the same bucket as the previous one (#117). Measured in August on earlier code: bursty writes 30 to 59% faster, random (low-locality) writes 2.4 to 9.4% slower; not yet re-measured on this release

### Correctness & Security Fixes
- Decoders and `New` no longer loop forever on a header whose lowest value is too large for its precision, and dense `Decode` no longer panics on a `MinInt64` zero-run or allocates tens of MB before rejecting a small stream (#80)
- Java zero-digit streams decode with their exact geometry; boundary maxima such as `New(1, 2048, 3).RecordValue(2048)` now record, and real Java/C streams of that shape decode; negative values are rejected instead of recorded as huge positive ones; merge `dropped` totals saturate instead of wrapping (#103, fixes #84, #85, #86, #90)
- Percentile ranks are bounded for very large counts, so P100 reaches the real maximum; a windowed histogram with `(1<<53)+3` observations returned 0 before (#108)
- Dense `RecordValues`, `Merge` and `PackedHistogram.MergeInto` no longer let the total wrap past `MaxInt64` (#114, fixes #113)
- Dense `Decode` rejects streams whose counts sum past `MaxInt64`, where it used to return an empty histogram without an error (#109, fixes #107)
- `DecodePacked` reads streams written by hdrhistogram-go v1.2.0 and earlier and shifted Java streams, which it used to reject (#109, fixes #106)
- `Import` stores negative counts as 0, so the total and the counts agree; `Histogram` ownership and `WindowedHistogram.Merge` lifetime are documented (#112, fixes #110, #111)

### Behaviour changes

| Area | Before | Now | PR |
|---|---|---|---|
| `New` and `Import` with a geometry that cannot be represented | hung forever | panic (`New` has no error return) | #80 |
| Decoding a hostile header, `MinInt64` zero-run or oversized payload | hang, panic or large allocation | an error; some error messages for invalid streams changed | #80 |
| Recording a negative value, dense or packed | recorded as a huge positive value | error, histogram unchanged | #103 |
| Recording a value equal to the highest trackable value at some geometries | error | recorded | #103 |
| Decoding a zero-digit (Java) stream | decoded with one digit, wrong values | exact geometry | #103 |
| `RecordValue`, `RecordValues`, `RecordCorrectedValue` past a total of `MaxInt64` | succeeded and corrupted the histogram | error; `Merge` counts these as dropped | #114 |
| Dense `Decode` of counts summing past `MaxInt64` | empty histogram, no error | error; `nil` histogram on any payload error | #109 |
| `DecodePacked` of pre-v1.3.0 Go and shifted Java streams | rejected | decoded | #109 |
| `Import` of negative counts | stored, total excluded them | stored as 0 | #112 |
| Unkeyed `Snapshot{...}` literals | compiled | compile error (new field); use field names | #105 |
| P100 with very large counts | could be 0 | the real maximum | #108 |

### Maintenance & Testing
- Nightly native fuzzing of every `Fuzz*` target with a persisted corpus (#76), ClusterFuzzLite registration and corpus handling (#78, #79); ten fuzz targets now run in CI, including two for `PackedHistogram`
- New regression tests for each fix above, each shown to fail on the previous code

**Full Changelog**: https://github.com/HdrHistogram/hdrhistogram-go/compare/v1.3.0...v1.4.0

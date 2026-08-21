# Java packed-test port matrix

**Upstream finding:** the Java HdrHistogram repo (`HdrHistogram/HdrHistogram`, `master`)
has **no standalone packed test files**. `PackedHistogram` / `PackedConcurrentHistogram`
are validated purely as drop-in parametrized variants of the normal histogram suites
(`@ValueSource(classes = {... PackedHistogram ...})`), plus one packed-specific
`@Test testPackedEquivalence`. Rust and Go HdrHistogram ports have no packed
implementation at all. So "porting the packed tests" = porting each applicable Java
behavioral assertion and running it dense-vs-packed. C tests live in `packed_test.c`
(behavioral parity, minunit) and `packed_fault_test.c` (error paths).

Legend: **Ported** (equivalent C test) · **Adapted** (same intent, C semantics) ·
**Covered-by** (subsumed by a parity test) · **N/A** (feature not in Phase-2 scope —
see bottom).

## HistogramTest.java (40 methods; 35 include Packed)

| Java @Test | Status | C test / note |
|---|---|---|
| testConstructionArgumentRanges | Ported | `test_construction_argument_ranges` (EINVAL on bad low/sig/range) |
| testEmptyHistogram | Ported | `test_empty_histogram` (total/max/mean/stddev/min) |
| testRecordValue | Ported | `test_record_value` (count-at-value, total) |
| testRecordValue_Overflow_ShouldThrowException | Adapted | `test_record_value_overflow` (returns false vs Java throw) |
| testConstructionWithLargeNumbers | Ported | `test_construction_with_large_numbers` |
| testValueAtPercentileMatchesPercentile | Ported | `test_value_at_percentile_matches_percentile` (lengths 1..10000) |
| testValueAtPercentileMatchesPercentileIter | Covered-by | percentile parity in `parity_full` + the above |
| testReset | Ported | `test_reset` |
| testPackedEquivalence | Ported | index-by-index count parity in `parity_full` + `test_packed_equivalence_random` |
| testUnitMagnitude{0,4,51,54,61}IndexCalculations | Covered-by | packed reuses the dense index math verbatim (geometry oracle); dense suite already covers it. Parity tests exercise it end-to-end. |
| testSizeOfEquivalentValueRange / Scaled | Covered-by | geometry helpers inherited from dense oracle; not re-exposed on packed |
| testLowest/Highest/MedianEquivalentValue (+Scaled) | Covered-by | same (dense oracle) |
| testNextNonEquivalentValue | Covered-by | dense oracle smoke |
| testRecordValueWithExpectedInterval | N/A | corrected-recording not in packed API |
| testAdd / testSubtract* (6 tests) | N/A | add/subtract not implemented |
| testCopy / testScaledCopy / testCopyInto / testScaledCopyInto | N/A | copy not implemented |
| testSerialization (ObjectOutputStream) | Adapted | Java object-serialization isn't portable; binary V2 round-trip covers the intent → `test_histogram_encoding` |
| testShort/IntCountsHistogramOverflow | N/A | count-type-specific; packed counts widen 1→8 B instead |

## HistogramEncodingTest.java (5 methods)

| Java @Test | Status | C test / note |
|---|---|---|
| testHistogramEncoding (@Theory, all types) | Ported | `test_histogram_encoding` (V2 round-trip both directions + byte-identical) |
| testSimpleIntegerHistogramEncoding (width growth) | Ported | `test_encoding_count_width_growth` (counts across 2^8/16/32/52) |
| testResizingHistogramBetweenCompressedEncodings | N/A | auto-resize not in scope (fixed-config) |
| testSimpleDoubleHistogramEncoding | N/A | double histogram not implemented |
| ...ByteBufferHasCorrectPositionSetAfterEncoding | N/A | dense-only (not packed); ByteBuffer-position contract |

## HistogramAutosizingTest.java (5 packed methods) — all **N/A**
Auto-resize / auto-sizing is out of scope: the packed variant takes a fixed config
(like the dense C `hdr_init`). Sparse storage already avoids the up-front allocation
that auto-sizing exists to defer.

## HistogramShiftTest.java (testHistogramShift) — **N/A**
`shiftValuesLeft/Right` not implemented.

## ConcurrentHistogramTest.java — **N/A**
Single-threaded core; concurrency stress not applicable (no atomic packed variant yet).

## HistogramDataAccessTest.java (dense-only reference)
Behavioral categories (mean, stddev, percentiles, count-at-value) are enforced for
packed via the parity tests above. `mean`/`stddev` parity is asserted in `parity_full`
against the dense C implementation within Java's ±0.1% tolerance.

---

## Added-code coverage

`packed_test.c` + `packed_fault_test.c` drive `hdr_packed_histogram.c` to
**100% of reachable lines and 93.04% of branches (taken at least once)** (`coverage.sh`,
gcov). **Two** lines are tagged `GCOV_EXCL_DEFENSIVE` (auditable, capped) and excluded
from the reachable denominator: the index-range guard in `hdr_packed_record_values`
(mirrors dense; the `value > highest` check already bounds the index) and the
`ensure_cap` int32-doubling guard (needs >2^30 distinct buckets). Both are kept as
defensive integer-overflow guards; neither is reachable via the public API.

Error/defensive paths covered via `-DPACKED_FAULT_HOOKS` fault injection and crafted
malformed streams: every alloc-failure return, `compress()` failure, and the six decode
error codes (short buffer, both cookie mismatches, over-long declared length, corrupt
deflate, trailing-zeros-invalid, value-truncated, encoded-input-too-long).

## Scope note (why the N/A features are out of scope)
Phase-2's packed variant is a **memory feature** covering record + read + V2
serialization. add/subtract/copy/shift/iterators/auto-resize/double/atomic are separate
features, each its own implementation + test surface; porting their tests requires
building them first. They are explicitly deferred (see FINDINGS.md), not skipped by
oversight.

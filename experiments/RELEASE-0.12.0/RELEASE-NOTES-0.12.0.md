## HdrHistogram_c 0.12.0

36 commits since 0.11.10. **No function was removed and the layout of every public struct is unchanged**, so
existing code and existing binaries keep working. A few functions now reject input they used to accept; see
[Behaviour changes](#behaviour-changes-to-know-about-when-upgrading). If you decode histogram logs that you do not
control, upgrade: the heap overflow in [#146](https://github.com/HdrHistogram/HdrHistogram_c/pull/146) is reachable from
`hdr_log_decode`.

### Performance improvements

Percentile queries are much faster, most of all `hdr_value_at_percentiles` (the batch call). Recording is unchanged.

| 0.12.0 vs 0.11.10, higher is better | `hdr_value_at_percentile` (read) | `hdr_value_at_percentiles`, 4 percentiles (batch) | `hdr_record_value` (write) |
|---|---:|---:|---:|
| Intel Xeon (Sapphire Rapids) | 1.74x | 33x | 1.05x (inside run-to-run spread) |
| AMD EPYC (Zen 5) | 2.12x | 29x | 0.98x |
| AWS Graviton (Neoverse V2) | 1.22x | 20x | 0.99x |
| Apple M6 | 1.12x | 32x | 1.00x |

Measured with the repository's own benchmark drivers, interleaved with the old release on the same machine (pinned to one
core on the three Linux machines; macOS cannot pin). These are microbenchmarks (a predictable write sequence, a fixed
four-percentile array), not application throughput. The write path is intentionally unchanged: the AMD result is a stable
~2% codegen difference, not a regression you should expect to see in an application.

Measured at `d21d084` (write) and `bcb5c1f` (read and batch) on Intel, AMD and Graviton, and at `102aefb` on Apple M6.
The code those paths run has not changed since, apart from the AArch64 Clang directive described below.

- Percentile scan: summed in blocks with a scalar fallback ([#137](https://github.com/HdrHistogram/HdrHistogram_c/pull/137)),
  a wider 16-element AVX2 accumulator ([#138](https://github.com/HdrHistogram/HdrHistogram_c/pull/138)), and a scan that
  assumes counts are non-negative ([#158](https://github.com/HdrHistogram/HdrHistogram_c/pull/158)); the record path keeps
  the negative-count check out of the single-value hot path. The AVX2 scan also prefetches ahead
  ([#139](https://github.com/HdrHistogram/HdrHistogram_c/pull/139)).
- `hdr_value_at_percentiles` now answers all percentiles in a single pass
  ([#140](https://github.com/HdrHistogram/HdrHistogram_c/pull/140)) and skips whole blocks that cannot reach the next
  target ([#141](https://github.com/HdrHistogram/HdrHistogram_c/pull/141)). Before, the batch call was slower than asking
  for the same percentiles one at a time.
- Linux AArch64 with Clang at `-O3`: the compiler turned the scan into a serial chain of dependent additions. A loop
  directive restores the independent block sum ([#167](https://github.com/HdrHistogram/HdrHistogram_c/pull/167)); the
  full read driver ran 2.12x faster with it than without. It is limited to non-Apple AArch64 Clang: on Apple silicon the
  same change helped long scans (2.6x) but made very short scans about 19% slower, so it is left out there. Other
  compilers and architectures generate identical code. How this compares with 0.11.10 on that one configuration has not
  been measured.

### Security improvements

Found by the new fuzzing and by adversarial review. No CVE has been assigned to any of them.

- **Heap buffer overflow when decoding a crafted V1/V2 log** (a bad payload length or word size could write past the counts
  array): rejected with `HDR_ENCODED_INPUT_TOO_LONG` ([#146](https://github.com/HdrHistogram/HdrHistogram_c/pull/146)).
- **Out-of-bounds read** in `hdr_count_at_value` for a value above the highest trackable value (it now returns 0), and a
  signed overflow in `hdr_mean`, which fed `hdr_stddev` ([#147](https://github.com/HdrHistogram/HdrHistogram_c/pull/147)).
- **Negative bucket counts in V0/V1 logs** were accepted and poisoned every later query; they are now rejected with the new
  error `HDR_NEGATIVE_COUNT_INVALID` ([#162](https://github.com/HdrHistogram/HdrHistogram_c/pull/162)).
- **Count total overflowing `int64` on import** (an imported histogram with counts like three times 2^62) was signed-overflow
  undefined behaviour; decode now fails with `EOVERFLOW`, and `hdr_reset_internal_counters` saturates
  ([#159](https://github.com/HdrHistogram/HdrHistogram_c/pull/159), fixes [#118](https://github.com/HdrHistogram/HdrHistogram_c/issues/118)).
- Undefined behaviour (signed overflow, oversized shifts, out-of-range float conversions) reachable from untrusted input,
  fixed in the bucket configuration ([#145](https://github.com/HdrHistogram/HdrHistogram_c/pull/145)), the top-bucket value
  range used by `hdr_max`, percentiles and the iterators ([#148](https://github.com/HdrHistogram/HdrHistogram_c/pull/148)),
  the linear and logarithmic iterator levels near `INT64_MAX` ([#149](https://github.com/HdrHistogram/HdrHistogram_c/pull/149)),
  and log timestamp parsing ([#153](https://github.com/HdrHistogram/HdrHistogram_c/pull/153),
  [#154](https://github.com/HdrHistogram/HdrHistogram_c/pull/154)).
- Fuzzing: the number of ClusterFuzzLite targets went from 1 to 5 (decode, record, log reader, count overflow, packed
  histogram) and there is now a deep weekly run. Unit tests went from 65 to 125 cases, and the suite also runs under
  ASan/UBSan, including on macOS Intel and Apple silicon.

### Bug fixes

- `hdr_reset_internal_counters` ignored `normalizing_index_offset`, giving a wrong min and max for decoded logs whose
  counts were shifted ([#155](https://github.com/HdrHistogram/HdrHistogram_c/pull/155)).
- `hdr_timespec_from_double` could produce an invalid `tv_nsec` (exactly 1e9, or negative)
  ([#156](https://github.com/HdrHistogram/HdrHistogram_c/pull/156)).
- The log timestamp seconds field was bounded by `long` instead of by `tv_sec`, wrongly rejecting timestamps after 2038 on
  32-bit Linux ([#157](https://github.com/HdrHistogram/HdrHistogram_c/pull/157)).
- On 32-bit Windows `hdr_atomic_load_64` and `hdr_atomic_store_64` were not atomic, which could tear `min`, `max` and
  `hdr_total_count` under concurrent recording ([#168](https://github.com/HdrHistogram/HdrHistogram_c/pull/168)).
- Fix the ClangCL build on Windows ([#142](https://github.com/HdrHistogram/HdrHistogram_c/pull/142), thanks @StefanStojanovic,
  found while updating Node.js) and stop trying AVX2 on i386
  ([#143](https://github.com/HdrHistogram/HdrHistogram_c/pull/143), thanks @K900); both are now covered by CI
  ([#144](https://github.com/HdrHistogram/HdrHistogram_c/pull/144)).

### New APIs

All additions; nothing existing changed signature. 27 new public functions.

- **`hdr_packed_histogram`** ([#150](https://github.com/HdrHistogram/HdrHistogram_c/pull/150)), in
  `<hdr/hdr_packed_histogram.h>`: a separate histogram whose storage grows with the number of populated buckets instead
  of the full counts array. For many sparsely populated histograms it is far smaller (1,000 histograms with 10 populated
  buckets each: 188 MB dense, 144 KB packed). The cost is that recording is O(log n) plus an insert for a new bucket, it has
  no atomic record function, and it serializes to the standard V2 compressed format. The dense histogram is untouched.
  Functions: `hdr_packed_init`, `_init_shared`, `_close`, `_reset`, `_config_create`, `_config_destroy`,
  `_config_memory_size`, `_record_value`, `_record_values`, `_total_count`, `_min`, `_max`, `_mean`, `_stddev`,
  `_count_at_value`, `_value_at_percentile`, `_value_at_percentiles`, `_get_memory_size`, `_populated`, `_count_width`,
  `_encode_compressed`, `_decode_compressed`.
- **`hdr_record_value_capped`** and **`hdr_record_value_capped_atomic`**: like `hdr_record_value` but values above the highest
  trackable value are clamped to it instead of rejected, and negatives are clamped to 0
  ([#166](https://github.com/HdrHistogram/HdrHistogram_c/pull/166)).
- **`hdr_total_count`**: NULL-safe getter that uses an atomic load, so it can be polled while other threads record
  ([#166](https://github.com/HdrHistogram/HdrHistogram_c/pull/166)).
- **`hdr_iter_linear_set_value_units_per_bucket`**: change a linear iterator's bucket width mid-iteration, for example to use
  coarser buckets in the tail ([#165](https://github.com/HdrHistogram/HdrHistogram_c/pull/165)).
- **`hdr_timespec_from_double_checked`**: reports `-EINVAL` or `-ERANGE` instead of silently producing a zero time
  ([#161](https://github.com/HdrHistogram/HdrHistogram_c/pull/161)).
- **`HDR_NEGATIVE_COUNT_INVALID`** error code ([#162](https://github.com/HdrHistogram/HdrHistogram_c/pull/162)).

### Build and packaging

- **Amalgamation**: `script/amalgamate.py` generates a self-contained copy of the core (`hdr_histogram.c` plus
  `hdr_histogram.h`), and optionally the log codec (`--with-log`), for projects that vendor the library; the output is
  attached to each release as `hdr_histogram-amalgamation-<version>.zip` and `...-with-log-<version>.zip`, with checksums
  ([#164](https://github.com/HdrHistogram/HdrHistogram_c/pull/164), [#169](https://github.com/HdrHistogram/HdrHistogram_c/pull/169)).
  It can bake in your allocator header (`--malloc-include`) and supports trees that keep headers in `hdr/`
  (`--include-prefix`). See `docs/AMALGAMATION.md`, which also covers moving an existing vendored copy over.
- **Minimal static core**: `-DHDR_HISTOGRAM_CORE_ONLY=ON` builds only the record and percentile engine as
  `hdr_histogram_core_static`, with no zlib or thread dependency; `-DHDR_HISTOGRAM_DISABLE_AVX2=ON` always uses the scalar
  scan ([#163](https://github.com/HdrHistogram/HdrHistogram_c/pull/163)). See `docs/EMBEDDING.md`.
- CI now also covers 32-bit x86, ClangCL, macOS Intel and Apple silicon with sanitizers, and native Linux AArch64 with
  Clang ([#144](https://github.com/HdrHistogram/HdrHistogram_c/pull/144), [#160](https://github.com/HdrHistogram/HdrHistogram_c/pull/160),
  [#167](https://github.com/HdrHistogram/HdrHistogram_c/pull/167)); CMake is fetched from the Kitware releases
  ([#152](https://github.com/HdrHistogram/HdrHistogram_c/pull/152)); automated PR review and issue triage were added
  ([#151](https://github.com/HdrHistogram/HdrHistogram_c/pull/151)).

### Behaviour changes to know about when upgrading

These are the visible differences for code that used to get away with something. All are in the direction of rejecting
invalid input.

| Call | 0.11.10 | 0.12.0 |
|---|---|---|
| `hdr_record_values(h, v, -1)` | returned true and subtracted from the total | returns false, histogram unchanged |
| decoding a log with a negative bucket count (V0/V1) | succeeded | fails with `HDR_NEGATIVE_COUNT_INVALID`, no histogram |
| decoding a log whose counts add up past `INT64_MAX` | undefined behaviour | fails with `EOVERFLOW` |
| `hdr_count_at_value(h, v)` with `v` above the highest trackable value | read out of bounds | returns 0 |
| `hdr_timespec_from_double(&t, NaN)` | undefined behaviour (we saw `tv_sec = INT_MIN`) | `t` is set to zero |
| `hdr_timespec_from_double(&t, 0.9996)` | `tv_nsec = 1000000000` | `tv_sec = 1, tv_nsec = 0` |
| `hdr_log_read_header` with a non-finite or out-of-range StartTime | converted without a range check | `-EINVAL` or `-ERANGE` |

`counts[]` must now hold non-negative values: the percentile scans rely on it. Code that writes `counts[]` directly
should not store negatives.

### Shared library version

Nothing was removed and no struct changed. See the release checklist for the proposed `SOVERSION` handling.

### Contributors

@StefanStojanovic and @K900 contributed the two Windows and i386 fixes. @paulorsousa reviewed the changes in this
release. Full changelog: https://github.com/HdrHistogram/HdrHistogram_c/compare/0.11.10...0.12.0

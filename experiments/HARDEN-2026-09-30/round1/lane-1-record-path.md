# Lane 1 — Record / write path (`hdr_record_*`, index math, init/reset, `hdr_add`)

Scope probed (tree `$SP/lane-1` = copy of main 26587de; clang 18 `-fsanitize=address,undefined,float-cast-overflow -fno-sanitize-recover=all`; probe source `$SP/lane-1/probe_record.c`, one section per `argv[1]`; fix prototype in `$SP/lane-1/fixtree`):
- `counts[]` / `total_count` int64 overflow through `hdr_record_values(count)` — single and atomic (`probe_record p1`, `p1a`, `p12`).
- Values below `lowest_discernible_value`, negative values, `value == highest`, `highest + 1` — single, atomic, corrected (`p3`, `p13`, `p8`).
- `count == 0`, negative `count` (`p4`); corrected recording with tiny / huge / negative `expected_interval` and missing values below lowest (`p5`, `p5b`).
- `hdr_add(h, h)` self-add, `hdr_add` with mismatched sig-figs / lowest / range, `hdr_add` == replay equivalence (`p6`, `p9b`).
- `hdr_init` matrix: lowest ∈ {0, -1, 1..8, 2^20, 2^29, 2^40, 2^44, 2^45, 2^60, INT64_MAX/2, INT64_MAX/2+1, INT64_MAX} × highest ∈ {1, 2, 1000, INT64_MAX-1, INT64_MAX} × sig ∈ {0..6}; each accepted config: record lowest/highest/0, full index round-trip `counts_index_for(hdr_value_at_index(i)) == i` for every in-range index, `hdr_get_memory_size` (`p8`); `unit_magnitude` floor for every exact power of two 2^0..2^44 (`p8b`).
- Atomic vs non-atomic differential: 7 configs (incl. INT64_MAX range, sig 5, lowest 2^44, `hdr_init(3,7,1)`) × 200k random (value, count∈0..4) incl. negative and out-of-range values; corrected vs corrected_atomic 20k random (value, count, expected_interval incl. ≤ 0) (`p9`, `p9b`).
- `hdr_reset` / `hdr_reset_internal_counters` / record / readback with `normalizing_index_offset` ∈ {0, ±1, ±(counts_len-1)} (`p10`).
- Public `hdr_value_at_index` with out-of-range index (`p11*`).
- `hdr_histogram_atomic_concurrency_test` under ThreadSanitizer (`build/tsan`); warnings sweep gcc 13 / clang 18 `-Wall -Wextra -Wconversion -Wshadow -Wformat=2` on `src/hdr_histogram.c`.
- Fix prototype (`fixtree`): clang ASan/UBSan and gcc ASan/UBSan builds, ctest 5/5 both, probes re-run.
- Not in scope / not present: `hdr_shift_values_left/right` do not exist in the C port (offset only enters via log decode); `hdr_init_preallocated` takes no buffer size, so a too-small buffer cannot be detected in-library (caller contract).

Verified OK (no need to re-do):
- Atomic and non-atomic record paths are in lock-step: identical return codes, `counts[]`, `total_count`, `min_value`, `max_value` across 1.4M random records in 7 configs, and for corrected recording (20k). TSan clean on the concurrency test.
- Index math: `counts_index_for(hdr_value_at_index(i)) == i` for every in-range index in all 70 accepted configs, including `highest = INT64_MAX` with sig 1..5 and `lowest = 2^44, sig 5` (unit_magnitude 44 + shcm 17 = 61 boundary). `record(highest)` accepted and `record(highest+1)` rejected for power-of-two and non-power-of-two highs; `hdr_max` never exceeds `INT64_MAX` (top bucket saturates, #148).
- `hdr_init` rejects: lowest ≤ 0, sig ∉ [1,5], highest < 2·lowest, and every `unit_magnitude + shcm > 61` config (2^45/sig5, 2^60/any, INT64_MAX/2, INT64_MAX) — all EINVAL, no UB. `unit_magnitude` is exact for every power of two (no `log()/log(2)` floor slip).
- Negative `value` rejected (returns false) consistently in single, atomic, corrected — matches Java (`countsArrayIndex` throws).
- `hdr_add(h, h)` terminates and doubles counts (recorded iterator snapshots `total_count`); `hdr_add` with mismatched sig-figs / lowest / range matches Java `add()` non-matching branch (records `valueFromIndex(i)` = lowest-equivalent value; C returns `dropped` where Java throws). `hdr_add(part, other) == sum` byte-identical `counts[]`.
- `normalizing_index_offset != 0` (any value in `(-counts_len, counts_len)`): record (both twins) + `hdr_count_at_index` / `hdr_count_at_value` / `hdr_reset_internal_counters` all consistent.
- Corrected recording: `expected_interval <= 0` → plain record; `value <= expected_interval` → no backfill; `missing_value` arithmetic cannot overflow (0 < ei < value).
- Warnings sweep: only pre-existing `-Wsign-conversion` (`__builtin_clzll(int64)` at :207, `counts_len` → `size_t` at :529/:534) and int64→double conversions in mean/stddev/percentile; nothing actionable in the record path.

## Findings (ranked, most severe first)

### L1-F1: `hdr_record_values` overflows `counts[]` and `total_count` with signed UB; atomic twin silently wraps
- Severity: medium     Class: correctness
- Where: `src/hdr_histogram.c:92` and `:100` (`counts_inc_normalised`), `:114` (`counts_inc_normalised_atomic`, wraps via `__atomic_add_fetch`) @ main 26587de (identical in COMBINED)
- Tracked: tracks issue #118 (same int64-count overflow class; #118 names only the `hdr_reset_internal_counters` sum, not the record side). Not covered by any open PR.
- Repro (`probe_record p1` / `p1a` / `p12`):
  ```c
  hdr_init(1, 1000000, 3, &h);
  hdr_record_values(h, 100, INT64_MAX / 2 + 1);
  hdr_record_values(h, 100, INT64_MAX / 2 + 1);   /* UBSan: */
  /* hdr_histogram.c:92:26: runtime error: signed integer overflow: 4611686018427387904 + 4611686018427387904 cannot be represented in type 'int64_t' */
  hdr_record_values(h, 1, INT64_MAX); hdr_record_value(h, 2);
  /* hdr_histogram.c:100:20: runtime error: signed integer overflow: 9223372036854775807 + 1 */
  ```
  Atomic twin, same input: `r1=1 r2=1 count_at_100=-9223372036854775808 total=-9223372036854775808` (no diagnostic, wraps).
- Impact: caller-supplied `count` (or `hdr_add` of a hostile decoded histogram, which feeds `iter.count` straight into `hdr_record_values`) reaches signed-overflow UB on the hot path; the two twins diverge (UB vs. wrap). `-fno-sanitize-recover` CI would abort on any fuzzer that drives `hdr_add` with large decoded counts. Java `Histogram.addToCountAtIndex` is a plain `+=` (defined wrap), so wrap is the reference behaviour.
- Proposed fix (zero-cost; compiles to the same `add`): make the accumulation unsigned so both twins wrap identically:
  ```diff
  -        h->counts[index] += value;
  +        /* unsigned add: signed wrap is UB; atomic twin wraps */
  +        h->counts[index] = (int64_t)((uint64_t)h->counts[index] + (uint64_t)value);
  ...
  -        h->counts[normalised_index] += value;
  +        h->counts[normalised_index] = (int64_t)((uint64_t)h->counts[normalised_index] + (uint64_t)value);
  ...
  -    h->total_count += value;
  +    h->total_count = (int64_t)((uint64_t)h->total_count + (uint64_t)value);
  ```
  Alternative if the maintainer prefers rejection over wrap: `if (count > 0 && h->counts[idx] > INT64_MAX - count) return false;` before the increment — costs a compare on the hot path and must be mirrored in the atomic twin (CAS loop), so wrap is the minimal, twin-consistent option. Prototyped in `$SP/lane-1/fixtree`: clang and gcc ASan/UBSan ctest 5/5, `p1`/`p12` now clean and identical to the atomic output.
- Proposed test: `test/hdr_histogram_test.c` `test_record_count_overflow_no_ub`: record `INT64_MAX/2+1` twice at one value with both `hdr_record_values` and `hdr_record_values_atomic`; assert both return true and `hdr_count_at_value` / `total_count` are equal between the two histograms (runs under the `sanitizers` CI job, which is what catches the UB).
- Confidence: high (UBSan trace, deterministic; fix verified under both sanitizer builds).

### L1-F2: public `hdr_value_at_index` has no bounds check — shift exponent ≥ 64 (UB) for index ≥ counts_len
- Severity: low     Class: correctness
- Where: `src/hdr_histogram.c:247-259` (`hdr_value_at_index` → `value_from_index` at :235) @ main 26587de (identical in COMBINED)
- Tracked: untracked. `hdr_count_at_index` got the unsigned bounds check in merged #147/#149, and the *internal* peek-past-end caller was fixed in #149 (`peek_next_value_from_index` saturates), but the public sibling still trusts `index`.
- Repro (`probe_record p11c`, `p11`, `p11b`, `p11d`):
  ```c
  hdr_init(1, 1000000, 3, &h);            /* counts_len = 11264 */
  hdr_value_at_index(h, INT32_MAX);
  /* hdr_histogram.c:235:41: runtime error: shift exponent 2097150 is too large for 64-bit type 'int64_t' */
  hdr_value_at_index(h, h->counts_len);   /* 1048576 (> highest_trackable_value) */
  hdr_value_at_index(h, -1);              /* 1023 — silently wrong */
  hdr_value_at_index(h, h->counts_len + 4096); /* 16777216 */
  ```
- Impact: an off-by-one caller loop (`i <= counts_len`) or a decoded index gets UB / a value above the histogram's range instead of a defined answer; asymmetric with `hdr_count_at_index`, which already rejects the same indices.
- Proposed fix (mirror the `hdr_count_at_index` guard; the only internal callers already pass `< counts_len`):
  ```diff
   int64_t hdr_value_at_index(const struct hdr_histogram *h, int32_t index)
   {
  +    /* index outside counts[]: shift exponent >= 64 is UB; unsigned compare also catches negatives */
  +    if ((uint32_t)index >= (uint32_t)h->counts_len)
  +    {
  +        return 0;
  +    }
       int32_t bucket_index = (index >> h->sub_bucket_half_count_magnitude) - 1;
  ```
  Note the cost: `hdr_value_at_index` runs once per iterator step; one predictable compare. Prototyped in `fixtree`: ctest 5/5 (clang+gcc sanitizers), all four probes return 0.
- Proposed test: extend `test_count_at_index_out_of_range` (or add `test_value_at_index_out_of_range`) asserting `hdr_value_at_index(h, -1) == 0`, `(h, counts_len) == 0`, `(h, INT32_MAX) == 0`, and `(h, counts_len - 1)` unchanged.
- Confidence: high (UBSan trace; fix verified).

### L1-F3: `hdr_reset` keeps `normalizing_index_offset` (Java `reset()` clears it)
- Severity: low     Class: correctness (behavioural parity / hygiene)
- Where: `src/hdr_histogram.c:524-530` (`hdr_reset`) @ main 26587de (identical in COMBINED)
- Tracked: untracked (#155, merged, fixed decoded-offset min/max; it did not touch `hdr_reset`).
- Repro (`probe_record p10`):
  ```
  P10 after hdr_reset: offset=100 total=0 min=9223372036854775807 max=0 (Java reset() sets offset=0)
  ```
  `hdr_reset` zeroes counts/min/max/total but leaves the decoded offset; a recycled decoded histogram stays on the `normalize_index` slow path and re-encodes a non-zero offset for an empty histogram. Recording/readback after such a reset is still *correct* (verified for offsets 0, ±1, ±(counts_len-1)); this is a parity/perf deviation, not a data bug.
- Impact: low — `hdr_reset` on a histogram obtained from `hdr_log_decode` (the "decode, reset, reuse" pattern) permanently loses the offset==0 fast path (#135) and emits a gratuitous offset in V2 logs. `AbstractHistogram.reset()` does `setNormalizingIndexOffset(0)`.
- Proposed fix:
  ```diff
        h->max_value = 0;
  +     h->normalizing_index_offset = 0;
        memset(h->counts, 0, (sizeof(int64_t) * h->counts_len));
  ```
  Prototyped in `fixtree`: ctest 5/5 (clang+gcc sanitizers); `p10` shows `offset=0` after reset.
- Proposed test: in `test_reset` (or `test_reset_internal_counters_honours_offset`), set `h->normalizing_index_offset = 100` (or decode a V2 log with offset), `hdr_reset(h)`, assert `h->normalizing_index_offset == 0`, then record + `hdr_count_at_value` round-trips.
- Confidence: high on the observation; medium that the maintainer wants the Java behaviour (one-liner, no downside found).

### L1-F4: Values below `lowest_discernible_value` are accepted and collapse into the value-0 bucket (issue #126 lower bound) — consistent with Java; docs are the gap
- Severity: info     Class: correctness (documentation)
- Where: `src/hdr_histogram.c:560-580` (`hdr_record_values`), `include/hdr/hdr_histogram.h:108-156` (`@return` docs) @ main 26587de
- Tracked: tracks issue #126 (open question left by the maintainer: "issues with checking the lower bound, need to compare with Java").
- Repro (`probe_record p3`, `p5b`): `hdr_init(1000, 1000000, 3)` → `unit_magnitude = 9`; `hdr_record_value(h, 1)` returns **true** in single, atomic and corrected paths, lands at index 0:
  ```
  P3 single : total=1 min_value=1 max_value=1 hdr_min=0 hdr_max=511 p50=511 mean=256
  P3 after reset_internal_counters: total=1 min_value=INT64_MAX max_value=511 hdr_min=0 ...
  ```
  Corrected recording with `expected_interval` below lowest (`p5b`: value 10000, ei 300, lowest 1000) backfills 400/700 into index 0 too; single == atomic byte-identical.
- Impact: Java behaves identically — `countsArrayIndex(1)` → 0, `updateMinAndMax(1)` sets min 1 live, `establishInternalTackingValues` skips index 0 so min becomes `Long.MAX_VALUE` after decode. So the C port is *consistent* with the reference in all three record variants; the only inconsistency is live-vs-decoded `min_value` (1 vs INT64_MAX), which is Java's too and is masked by `hdr_min()` returning 0 whenever index 0 is populated. Capping at `lowest_discernible_value` (the memtier workaround in #126) would *diverge* from Java. Recommendation for #126: document rather than cap.
- Proposed fix (header only, terse):
  ```diff
   * @param value Value to add to the histogram
  - * @return false if the value is larger than the highest_trackable_value and can't be recorded,
  - * true otherwise.
  + * @return false if value is negative or larger than highest_trackable_value and can't be
  + * recorded, true otherwise. Values below lowest_discernible_value are recorded but are
  + * indistinguishable from 0 (they land in the first bucket).
  ```
  (same wording on the `_atomic`, `_values`, `_corrected` variants).
- Proposed test: `test_record_below_lowest_discernible`: `hdr_init(1000, ...)`, record 1 via all three variants, assert return true, `hdr_count_at_value(0) == 1`, `hdr_min == 0`, `hdr_max == 511` — pins the Java-consistent contract so a future "cap" change is a deliberate decision.
- Confidence: high (Java source read: `countsArrayIndex`, `updateMinAndMax`, `recordCountAtValue`).

### L1-F5: `count <= 0` accepted; `count == 0` still moves min/max; negative counts make `total_count` negative and `hdr_mean` NaN
- Severity: info     Class: correctness
- Where: `src/hdr_histogram.c:560-604` @ main 26587de
- Tracked: negative counts already noted as "API-accepted" in the 2026-09-29 #141 review; `hdr_mean` NaN on `total_count == 0` tracks issue #125.
- Repro (`probe_record p4`):
  ```
  P4 count=0 (5000): total=0 min_value=5000 max_value=5000 hdr_min=5000 hdr_max=5003 p50=0 mean=-nan
  P4 count=-3 (7):   total=-3 min_value=7 max_value=5000 hdr_min=7 hdr_max=5003 p50=0 mean=-0.000000
  P4 ret0=1 retneg=1 count_at_7=-3      (atomic twin: identical)
  ```
- Impact: matches Java exactly (`recordCountAtValue` calls `updateMinAndMax` unconditionally and `addToTotalCount(count)` with no sign check), so not a divergence; noted so nobody "fixes" it one-sidedly. If a guard is ever wanted it must go in both twins and in `hdr_add` (which forwards `iter.count`).
- Proposed fix: none (parity). Optionally document `count` as "may be zero or negative; no validation" in the header.
- Proposed test: none required; `test_percentile_signed_counts` already exercises negative counts on the read side.
- Confidence: high.

### L1-F6: corrected recording with a tiny `expected_interval` is unbounded work (`value / expected_interval` records)
- Severity: info     Class: hygiene (DoS surface only if `expected_interval` is attacker-controlled)
- Where: `src/hdr_histogram.c:621-628` / `:643-650` (loops), `hdr_add_while_correcting_for_coordinated_omission` @ main 26587de
- Tracked: untracked; by-design (Java `recordValueWithCountAndExpectedInterval` has the identical loop).
- Repro (`probe_record p5`): `hdr_init(1, INT64_MAX, 3)`; `hdr_record_corrected_value(h, INT64_MAX, 1)` did not return within a 5 s alarm (`exit=3`, ~9.2e18 iterations expected). No memory growth, no UB — purely CPU.
- Impact: only relevant when `expected_interval` comes from untrusted input (e.g. a log-replay tool). Java identical; no fix proposed beyond a doc note that the call performs `value/expected_interval` records.
- Proposed fix / test: none (parity).
- Confidence: high.

## Did NOT reproduce (suspected, tested, clean)
- `unit_magnitude` off-by-one from `log(lowest)/log(2)` for exact powers of two: none for 2^0..2^44 (`p8b`).
- Signed-shift UB in `get_sub_bucket_index` / `counts_index` / `value_from_index` for any *in-range* value or index (only the out-of-range public call in L1-F2 trips it).
- `hdr_add(h, h)` infinite loop / double counting: terminates, total exactly doubles.
- Atomic/non-atomic index or min/max divergence: none in 1.4M random records + 20k corrected records.
- `hdr_calculate_bucket_config` shift/overflow at `unit_magnitude + shcm == 61` (lowest 2^44, sig 5): accepted, index round-trip clean; 62 rejected.
- Missing-value overflow in corrected recording: not possible (0 < ei < value).
- Data races in `hdr_record_value_atomic`: TSan clean on the concurrency test.

# Lane 2 — Query / read path audit (hdr_value_at_percentile(s), iterators, stats, print)

Scope probed (all against MAIN `26587de` and COMBINED, each built 4 ways: clang
`-fsanitize=address,undefined,float-cast-overflow -fno-sanitize-recover=all` with
native AVX2 and with `-DHDR_FORCE_SCALAR=1` — a source shim I added only in my lane
copies to force the scalar block-sum path on this AVX2 box — plus gcc `-O2` release
for real (non-sanitizer) output). Probe driver: `$SP/lane-2/probe/q_probe.c`.

- `hdr_value_at_percentile` / `hdr_value_at_percentiles` with percentile = NaN, +inf,
  -inf, -1.0, -1e30, -0.0, 1e300, 200 (out of [0,100]); length 0; NULL args; unsorted
  {90,50,50,10}; duplicate percentiles.
- Empty histogram: `hdr_value_at_percentile`, `hdr_min`, `hdr_max`, `hdr_mean`,
  `hdr_stddev`, `hdr_value_at_percentiles`, `hdr_percentiles_print` (vs Java reference,
  fetched `AbstractHistogram.java`/`PercentileIterator.java` from raw.githubusercontent).
- `total_count` near INT64_MAX (record `(5, INT64_MAX)`, `(5, INT64_MAX-100)`, and two
  ~2^62 counts whose sum still fits int64).
- Iterators: all / recorded / linear / log / percentile with `ticks_per_half_distance`
  = 0 and < 0, `value_units_per_bucket` <= 0, `log_base` <= 1 / fractional / NaN / inf,
  INT64_MAX values, degenerate distributions.
- Offset differential: for 300 random histograms per seed I build an `offset==0` base
  and a rotated `normalizing_index_offset==k` twin holding identical logical counts,
  then assert every query function + all 5 iterators + `hdr_percentiles_print` agree.
- Scalar-vs-AVX2 parity on the same inputs.
- Negative counts reached purely through the **public** API: `hdr_record_values(h, v,
  negative)` is accepted, and via `hdr_add`.
- `hdr_value_at_index`, `hdr_size_of_equivalent_value_range`,
  `hdr_next_non_equivalent_value`, `hdr_median_equivalent_value`,
  `hdr_lowest_equivalent_value`, `hdr_values_are_equivalent`, `hdr_count_at_value/index`
  with out-of-domain inputs (negative value, index = -1 / counts_len / INT32_MAX/MIN).

Verified OK (so nobody re-does these):
- **Offset-aware parity is solid.** With non-negative counts, the offset!=0 twin agrees
  with the offset==0 base on `hdr_value_at_percentile`, `hdr_value_at_percentiles`,
  `hdr_min/max/mean/stddev`, `hdr_count_at_value/index`, and all five iterators AND
  `hdr_percentiles_print`, byte-identical, over 300 random histograms × 2 seeds, on BOTH
  the AVX2 and forced-scalar builds, on BOTH main and combined. The only differential
  "mismatches" reported were the p=0 singular/plural gap (L2-F3) and the empty-histogram
  values (L2-F2) — everything else matched. The A1 (PR #137) offset regression class is
  clean here, including the combined tree's #140/#141 single-pass/blocked batch path
  (its `normalizing_index_offset != 0` branch routes to the iterator).
- #149's near-INT64_MAX linear/log iterator overflow fix is present and correct on main;
  the integer-log-base contract test passes. Fractional base still truncates (documented
  in the header now) — not a defect, matches the merged contract.
- `hdr_iter_linear_init(vpb<=0)`, `hdr_iter_log_init(base<=1 / NaN / inf / negative
  first bucket / level<=0)` all terminate and are UBSan-clean (existing guards work).
- `hdr_value_at_percentiles` returns EINVAL on NULL, 0 on length 0.
- `hdr_count_at_value(negative)` and `hdr_count_at_index(-1 / len)` correctly return 0
  without OOB.

## Findings (ranked, most severe first)

### L2-F1: float-cast-overflow UB (UBSan abort) in the percentile read path — 3 sites
- Severity: high    Class: security / correctness
- Where: `src/hdr_histogram.c:855` (`hdr_value_at_percentile`), `:879`
  (`hdr_value_at_percentiles`), `:1147` (`percentile_iter_next`, reached via
  `hdr_percentiles_print` and `hdr_iter_percentile_*`) @ main 26587de. COMBINED same
  (lines `864` / `889`-region / `1147`).
- Tracked: untracked. Distinct from #148 (integer value-range overflow) and #118
  (int64 sum of counts). This is the `double -> int64` cast, not integer math.
- Repro (all abort under the exact CI flags `-fsanitize=...,float-cast-overflow
  -fno-sanitize-recover`, which ci.yml's Debug leg runs):
  - `hdr_value_at_percentile(h, -INFINITY)` or `(h, -1e30)`:
    `855:9: runtime error: -inf is outside the range of representable values of type
    'long'`. (`hdr_value_at_percentiles` with the same value aborts at `879`.)
  - Huge `total_count`: `hdr_record_values(h, 5, INT64_MAX)` then
    `hdr_value_at_percentile(h, 100)` -> `855:9: 9.22337e+18 is outside the range ...`
    (also fires with `INT64_MAX-100`, and with two ~2^62 counts). Root cause:
    `(int64_t)((requested_percentile/100)*total_count + 0.5)` — `1.0*~INT64_MAX + 0.5`
    exceeds INT64_MAX.
  - `percentile_iter_next`: a lopsided histogram, e.g. `hdr_record_values(h, 1, 1<<60)`
    + `hdr_record_value(h, 2)`, then `hdr_percentiles_print(h, fp, 1, 1.0, CLASSIC)`
    drives `percentiles->percentile_to_iterate_to` to exactly `100.0`, so
    `log(100/(100.0 - 100.0))` = `log(inf)` = `inf`, and `(int64_t) inf` at `:1147`
    aborts.
- Impact: any caller that passes a percentile from untrusted/parametric input, or that
  simply records a large enough `count`, can abort a sanitizer build and invokes C
  undefined behavior in release (the release cast is implementation-defined garbage —
  e.g. p100 of an INT64_MAX-count histogram returns value `5` correctly by luck on x86,
  but the standard permits anything). The weekly ClusterFuzzLite UBSan job is the sort
  of gate that catches exactly this class (it already caught the #148/#149/#153 ones).
- Proposed fix (minimal, project style):
  - Clamp the requested percentile to `[0,100]` before the cast (also fixes L2-F4), and
    saturate the count instead of casting an out-of-range double. Sketch for both
    `hdr_value_at_percentile` and `hdr_value_at_percentiles`:
    ```c
    /* clamp NaN/neg/>100 before the cast: out-of-range double->int64 is UB */
    double p = percentile <= 0.0 ? 0.0 : (percentile < 100.0 ? percentile : 100.0);
    double fp_count = (p / 100.0) * (double) h->total_count + 0.5;
    int64_t count_at_percentile = fp_count >= (double) INT64_MAX
        ? INT64_MAX : (int64_t) fp_count;
    ```
    (`percentile <= 0.0` is false for NaN, so NaN falls through to the `< 100.0` test
    which is also false -> 100.0; if Java-parity for NaN is wanted, test `isnan` first
    and pick 0 — see L2-F4.)
  - For `percentile_iter_next:1147`: guard the `100.0 - percentile_to_iterate_to`
    denominator (it is `>= 100.0` only at the terminal step) — skip the tick
    recomputation when `percentile_to_iterate_to >= 100.0`, mirroring the existing
    `seen_last_value` terminal path.
- Proposed test: `test/hdr_histogram_test.c` — a `test_percentile_no_float_cast_overflow`
  asserting `hdr_value_at_percentile(h, -INFINITY/-1e30/NaN)` and the huge-`total_count`
  p100 return without UB (UBSan-only guard, plus value pins: p<=0 -> lowest, p>=100 ->
  hdr_max), and a lopsided-histogram `hdr_percentiles_print` that terminates cleanly.
- Confidence: high (reproduced on all 4 builds; exact CI flag set).

### L2-F2: empty histogram returns 63 / INT64_MAX / NaN instead of 0 (Java parity)
- Severity: medium    Class: correctness
- Where: `hdr_value_at_percentile:851`, `hdr_min:723`, `hdr_mean:898`, `hdr_stddev:920`
  @ main 26587de (COMBINED identical).
- Tracked: tracks issue #116 (p95 empty = 63) and issue #125 (hdr_min empty = INT64_MAX,
  hdr_mean empty = NaN). Not in any open PR.
- Repro (`init(100, 10e6, 3)`, nothing recorded):
  ```
  p95 = 63          (Java getValueAtPercentile: 0)
  hdr_min = 9223372036854775807   (Java getMinValue: 0)
  hdr_mean = -nan   (Java getMean: 0.0)
  hdr_stddev = -nan (Java getStdDeviation: 0.0)
  ```
  Java (`AbstractHistogram.java`): `getMinValue` returns 0 when `getTotalCount()==0`;
  `getMean`/`getStdDeviation` return `0.0` when total count is 0.
- Impact: user-visible wrong answers on the common "no samples yet" case; the NaN mean
  further poisons `hdr_percentiles_print`'s CLASSIC footer (`Mean = -nan`).
- Proposed fix: add `if (h->total_count == 0) return 0/0.0;` guards to `hdr_min`,
  `hdr_mean`, `hdr_stddev` (matches Java). For `hdr_value_at_percentile`, the 63 comes
  from `get_value_from_idx_up_to_count` clamping `count_at_percentile` to 1 and hitting
  index 0; a `total_count == 0` early return of 0 matches Java. Terse comment: `/* empty:
  match Java (0), not the bucket-0 artifact */`.
- Proposed test: `test/hdr_histogram_test.c` — `test_empty_histogram_queries` pinning all
  four to 0 / 0.0.
- Confidence: high (reproduced; Java source cited).

### L2-F3: hdr_value_at_percentiles (plural) disagrees with singular at percentile 0
- Severity: medium    Class: correctness
- Where: `hdr_value_at_percentiles:880` (clamps count to >=1) and `:891` (always uses
  `highest_equivalent_value`) vs `hdr_value_at_percentile:857-861` (percentile==0.0 ->
  `lowest_equivalent_value`) @ main 26587de. COMBINED: same divergence (the single-pass
  #140/#141 path at `:940`-region also always emits `highest_equivalent_value`).
- Tracked: untracked. #90 added the plural API "as a means for redundant computation
  removal", i.e. it is meant to equal the singular results.
- Repro (`init(1,1e6,3)`, 1000 values; also surfaced ~750×/300-round differential):
  ```
  p=0: singular hdr_value_at_percentile = 36864, plural = 38911   (base histogram)
  ```
  singular returns `lowest_equivalent_value` of the first non-empty bucket; plural
  returns `highest_equivalent_value`.
- Impact: the two documented ways to get percentile values disagree at p0 (and, because
  plural forces `count>=1` while singular rounds `(p/100)*total + 0.5`, at other very-low
  percentiles when the rounded count would be 0). Callers switching to the batch API for
  speed silently change results at p0.
- Proposed fix: in the plural loop, special-case the p==0 entry to emit
  `lowest_equivalent_value(h, iter.value)` (or `hdr_value_at_index`), matching the
  singular contract. Keep the `count>=1` clamp only for p>0.
- Proposed test: extend `test_percentiles_by_value_at_percentiles` to include 0.0 and
  assert `values[i] == hdr_value_at_percentile(h, percentiles[i])` for every entry.
- Confidence: high (reproduced; matches the singular special-case in code and Java).

### L2-F4: negative percentile is not clamped to 0 (only the upper bound is clamped)
- Severity: medium    Class: correctness / security (feeds L2-F1)
- Where: `hdr_value_at_percentile:853` and `hdr_value_at_percentiles:877` @ main —
  `percentile < 100.0 ? percentile : 100.0` clamps only the top.
- Tracked: untracked (root cause shared with L2-F1's negative-percentile abort).
- Repro: `hdr_value_at_percentile(h, -1.0)` returns 1 (via the downstream count clamp),
  but `-inf`/`-1e30` reach the cast and abort (L2-F1); NaN -> 100.0 (returns max) whereas
  Java clamps NaN's path via `Math.max(Math.nextAfter(percentile, -inf), 0)` then
  `min(...,100)`.
- Impact: out-of-range percentile handling diverges from Java (`Math.min(Math.max(...,
  0),100)`) and is the entry point for the L2-F1 negative-double abort.
- Proposed fix: fold into L2-F1's clamp (`p <= 0 ? 0 : min(p,100)`); optionally match
  Java's `nextAfter(p, -inf)` ulp-trim if exact parity is wanted (I did not find a case
  where the missing ulp-trim changes a C result, so I would keep the C `+0.5` rounding
  and only add the clamp — smaller diff).
- Proposed test: covered by the L2-F1 test (p = -1, -inf, NaN, 200 pins).
- Confidence: high.

### L2-F5: scalar block-sum percentile scan disagrees with the AVX2 scan on negative counts
- Severity: medium    Class: correctness (scalar/AVX2 parity)
- Where: `get_value_from_idx_up_to_count_scalar:756-778` (the `BLK=4` unsigned block
  sum) vs `get_value_from_idx_up_to_count_avx2:816-819` (which ORs the lanes and forces
  the per-element walk when any lane is negative) @ main 26587de. Introduced by #137.
  COMBINED same.
- Tracked: untracked. Directly answers the brief's "scalar block-sum AND AVX2 paths —
  test parity" question.
- Repro (negative counts reachable via public `hdr_record_values(h,v,-c)`; here set
  directly for a minimal case): `counts[16]=2, counts[17]=-2, counts[48]=1,
  total_count=1`, query p50:
  ```
  exact per-element prefix (Java-style) : value at index 16
  AVX2 build      hdr_value_at_percentile(50) = 16   (correct: sign-mask -> per-element)
  forced-scalar   hdr_value_at_percentile(50) = 48   (WRONG)
  ```
  The `+2,-2` pair sums to 0 as a 4-wide block, so the scalar block test
  `running + block_sum >= count` never fires for that block and it skips past the true
  crossing at index 16. The AVX2 path detects the negative lane and walks element-by-
  element, so the two builds return different values for the same histogram.
- Impact: on a machine without AVX2 (the shipped scalar fallback, ARM, MSVC, i386) the
  percentile of a histogram containing negative counts differs from the AVX2 build.
  Negative counts are arguably invalid input, but (a) they are reachable through the
  public recording API with no rejection, and (b) the AVX2 path already spends
  instructions defending against them, so the scalar fallback should match rather than
  silently diverge.
- Proposed fix: give the scalar block a cheap sign check mirroring the AVX2 lane-OR, and
  fall to the per-element walk when the block's OR is negative:
  ```c
  int64_t block_or = 0;
  for (j = 0; j < BLK; j++) { block_or |= counts[idx+j]; block_sum_u += (uint64_t)counts[idx+j]; }
  if (HDR_UNLIKELY(block_or < 0 ||
      (uint64_t)running + block_sum_u >= (uint64_t)count_at_percentile)) { /* per-element */ }
  ```
  (Same one-line guard belongs on the combined tree's `BATCH_SCAN_BLOCK` path — it does
  already carry a `signs < 0` check, so combined's singular already matches; only main's
  scalar `get_value_from_idx_up_to_count_scalar` lacks it.) Alternatively: document that
  counts must be non-negative and reject negative `count` in `hdr_record_values` (that is
  issue-adjacent to #126's bound discussion, so I lean to the sign-guard here).
- Proposed test: `test/hdr_histogram_test.c` — construct the `+2,-2,+1` histogram and
  assert `hdr_value_at_percentile(h,50)` equals the exact per-element reference, so the
  scalar and AVX2 builds must agree (fails today on a forced-scalar / non-AVX2 build).
- Confidence: high (reproduced: AVX2=16 vs forced-scalar=48, both main and combined; also
  in gcc `-O2` release, not just sanitizer builds).

### L2-F6: hdr_percentiles_print prints int64 TotalCount with `%d` (wrong value + varargs UB)
- Severity: medium    Class: correctness / hygiene
- Where: `format_line_string:1181-1192` builds the per-line format as
  `"...%12f %12d %12.2f\n"` and `hdr_percentiles_print:1462` passes
  `int64_t total_count` (from `iter.cumulative_count`) to that `%d` @ main 26587de.
  COMBINED identical.
- Tracked: untracked. (The CLASSIC *footer* correctly uses `PRIu64`; only the per-line
  body is wrong.)
- Repro (`record (10, 3e9)`, `(20, 5e9)`, CLASSIC + CSV):
  ```
  CLASSIC:  10.000  0.000000  -1294967296  1.00     (should be 3000000000)
            20.000  1.000000   -589934592  ...       (should be 8000000000)
  CSV: same -1294967296 / -589934592
  ```
  `3000000000` truncated/garbled through `%d`.
- Impact: every percentile line's TotalCount column is wrong once a cumulative count
  exceeds INT32_MAX (~2.1e9 samples — realistic for long-running latency histograms), and
  passing an `int64_t` to `%d` is undefined behavior (varargs type mismatch).
- Proposed fix: emit the count with a width-correct 64-bit conversion. Minimal:
  change the count column to `%12" PRId64 "` (CLASSIC) / `%" PRId64 "` (CSV) in
  `format_line_string` and pass `cumulative_count` as `int64_t` (it already is). Terse
  comment: `/* cumulative_count is int64: %d truncates + is varargs UB */`. Note the
  `%f` percentile column is a `double` arg so it is fine; only the count column is wrong.
- Proposed test: `test/hdr_histogram_test.c` — print a histogram with a cumulative count
  > INT32_MAX to a `open_memstream` buffer and `strstr` for the correct decimal
  ("3000000000"), asserting the truncated "-1294967296" is absent.
- Confidence: high (reproduced in gcc `-O2` release, not a sanitizer artifact).

### L2-F7: public equivalent-value helpers invoke shift UB on out-of-domain input
- Severity: low    Class: correctness (UBSan) / hardening
- Where: `value_from_index:235` (`(int64_t)sub_bucket_index << (bucket_index +
  unit_magnitude)`) reached from `hdr_lowest_equivalent_value`,
  `hdr_median_equivalent_value`, `hdr_next_non_equivalent_value`,
  `hdr_values_are_equivalent`, and `hdr_value_at_index` @ main 26587de.
- Tracked: untracked (adjacent to the #148 top-bucket saturation work, but that fixed
  the *value* path, not negative/oversized *inputs* to these helpers).
- Repro (`init(1,1e6,3)`):
  ```
  hdr_lowest_equivalent_value(h, -1)      -> 235: left shift of negative value -1  (UBSan abort)
  hdr_median_equivalent_value(h, -1)      -> same
  hdr_next_non_equivalent_value(h, -1)    -> same
  hdr_values_are_equivalent(h, -1, -2)    -> same
  hdr_lowest_equivalent_value(h, INT64_MIN) -> 235: left shift of negative value -1024
  hdr_value_at_index(h, INT32_MAX)        -> 235: shift exponent 2097150 too large
  ```
  (`hdr_size_of_equivalent_value_range(h,-1)` and `hdr_count_at_value(h,-1)` are safe —
  the latter guards `value < 0`.)
- Impact: these are public API functions with no documented precondition; a negative or
  huge argument is UB (sanitizer abort; garbage in release). Lower severity because the
  recording path never produces negative values internally, so it needs a caller passing
  a bad value directly.
- Proposed fix: clamp/guard at the public boundary — e.g. `lowest_equivalent_value` (and
  friends) treat `value < 0` as 0, and `hdr_value_at_index` rejects
  `(uint32_t)index >= (uint32_t)counts_len` returning 0 (mirrors `hdr_count_at_index`).
  Terse: `/* negative/oob input -> shift UB; clamp at the public boundary */`.
- Proposed test: `test/hdr_histogram_test.c` — call each with -1 / INT64_MIN / oob index
  under UBSan and assert no abort + a sane clamped value.
- Confidence: high (reproduced). Medium on whether the maintainer considers negative
  input in-scope vs "garbage in, garbage out" — flagging because it is a UBSan trip that
  the weekly fuzz job could surface, and the fix is a one-line clamp matching existing
  `hdr_count_at_index` style.

### L2-F8 (info): negative counts make hdr_percentiles_print run pathologically long
- Severity: info    Class: correctness (robustness)
- Where: `percentile_iter_next` / `iter_linear_next` reached from `hdr_percentiles_print`
  when `counts[]` holds negative values (public `hdr_record_values(h,v,-c)`).
- Tracked: untracked; a facet of the negative-counts class (L2-F5).
- Repro: my negative-count differential run (random histograms with ~25% negative
  counts) hung in `hdr_percentiles_print` (backtrace: `__fprintf_chk <-
  hdr_percentiles_print`) — a single call did not finish in 4s, whereas the same
  histograms with non-negative counts print in microseconds. `cumulative_count` can
  decrease, so `has_next` (`cumulative_count < total_count`) and the percentile math
  behave non-monotonically and emit a very large number of lines.
- Impact: a histogram with negative counts (invalid but reachable) can make a print call
  effectively hang — a mild DoS surface if such a histogram is ever decoded/added.
- Proposed fix: same root remedy as L2-F5 — either reject negative recorded counts or
  make the scan/iterator robust to them. No separate fix needed if L2-F5 is addressed by
  input rejection.
- Confidence: medium (observed the hang + backtrace; did not minimize to a single count
  vector).

---

Notes for the coordinator:
- I could not build `-m32` here (missing 32-bit libc: `Scrt1.o` absent), so i386 parity
  of the scalar path (relevant to #144) was validated only via the forced-scalar shim on
  x86-64, not real 32-bit codegen.
- The forced-scalar shim (`#if !defined(HDR_FORCE_SCALAR) && ...` around
  `HDR_HAS_AVX2_DISPATCH`) exists only in my lane copies for testing; it is NOT proposed
  for upstream (a maintainer may still like it as a test knob, but that is a separate
  call).
- Strongest / most release-relevant: L2-F1 (UBSan aborts reachable from the public API,
  exactly the class the weekly ClusterFuzzLite UBSan job flags) and L2-F5/F6 (real wrong
  answers in release builds, not just sanitizer trips).

# Lane 6 — Unit-test coverage: measurement, weak-assertion review, new tests

`SP=/tmp/claude-1000/-home-fco-redislabs-hdr-agent-workspace/c823fcbe-3fa5-4420-8c28-c287298e2ca3/scratchpad`
Machine: x86-64 (AVX2 present), 14 cores, Linux; gcc 13.3, clang 18, gcov 13.3, lcov 2.0, Java 17 + HdrHistogram Java 2.2.2 jar (oracle).

Scope probed:
- Coverage build of MAIN (`$SP/lane-6/main`, sha 26587de) and COMBINED (`$SP/lane-6/combined`) with
  `cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_C_COMPILER=gcc -DCMAKE_C_FLAGS="--coverage -fprofile-update=atomic -O0 -g" -DCMAKE_EXE_LINKER_FLAGS="--coverage"`,
  `ctest` (5/5 and 7/7 pass), then `gcov -b -j` on `src/CMakeFiles/hdr_histogram_static.dir/*.gcda`, summarised by
  `$SP/lane-6/covsum.py` (per-file line/branch/function rates + zero-hit function list) and `$SP/lane-6/uncov.py` (uncovered lines).
  NB: lcov 2.0 `--list` on this data prints nonsense function rates (609%) and drops branches; without `-fprofile-update=atomic`
  the concurrency test produces negative counters. The numbers below are from gcov JSON directly.
- Public API declared in `include/hdr/*.h` (82 functions) cross-referenced against every ctest source for direct calls.
- Read all five test sources + `minunit.h` + `hdr_test_util.h` + `test/CMakeLists.txt` for weak assertions / order dependence / fixture wiring.
- Wrote 35 new minunit tests in `$SP/lane-6/work/test/` (18 in `hdr_histogram_test.c`, 17 in `hdr_histogram_log_test.c`), fixed 2 weak
  assertions, wired 3 orphaned fixtures; built with clang `-fsanitize=address,undefined,float-cast-overflow -fno-sanitize-recover=all -Wall -Wextra`
  (0 warnings) and gcc `--coverage` (0 warnings). Ran with the stock minunit runner AND a continue-on-failure shim (`$SP/lane-6/probe/mu/`)
  so every test result is known, with LSan on and off.
- Generated Java oracle fixtures with `$SP/lane-6/jgen/Gen.java` (Histogram → shiftValuesLeft/Right → encodeIntoCompressedByteBuffer → base64;
  expected counts/min/max/p50 from the Java object) — output in `$SP/lane-6/jgen/out.txt`.
- Crafted decoder fixtures (V0/V1 word_size 2/4, bad encoding cookie, zero-run overflow, truncated varint, invalid bucket config) with
  `$SP/lane-6/probe/craft.c` (zlib + hdr_encoding.c) — `$SP/lane-6/probe/blobs.txt`.
- Prototyped every proposed fix in `$SP/lane-6/fixcheck/src` and re-ran all 94 tests (48 + 46) against it under ASan/UBSan/LSan: all pass.
  Sketch: `$SP/lane-6/fix-sketch.patch`.
- Re-ran the new tests against COMBINED sources: identical results (no open PR touches these paths).

Verified OK (no need to re-do):
- All 5 MAIN / 7 COMBINED ctest targets pass under gcc coverage and clang ASan/UBSan.
- `hdr_init`/`hdr_calculate_bucket_config` reject sig-figs 0/6, lowest <1, highest < 2*lowest, leave `*result` NULL; `hdr_init_preallocated`
  reproduces `hdr_init` field-for-field and behaviourally (18 tests, all green on main).
- Recording (plain AND atomic) into a histogram with `normalizing_index_offset != 0` matches an unrotated twin for every value
  (this closed the previously 0-hit lines hdr_histogram.c:96-98 and 113-115 — the offset branch of both `counts_inc_normalised*` was never executed by any test).
- `hdr_reset` on an offset histogram empties it and allows re-use; `hdr_add` into coarser / narrower targets (dropped count exact) and from an
  offset source; `hdr_add_while_correcting_for_coordinated_omission` equals per-value `hdr_record_corrected_values` and degrades to `hdr_add` for interval <= 0.
- Percentile iterator: monotone, terminates for ticks 0, one 100% step on an empty histogram; `hdr_value_at_percentiles` EINVAL/len 0/p>100 clamp.
- Java-written plain histogram and 2^29/2^33 counts decode identically in C; all 9 LEB128 widths encode/decode.
- Decoder error codes: HDR_ENCODING_COOKIE_MISMATCH, HDR_TRAILING_ZEROS_INVALID, HDR_VALUE_TRUNCATED, HDR_COMPRESSION_COOKIE_MISMATCH,
  HDR_INFLATE_FAIL, EINVAL (short buffer / negative compressed length / invalid bucket config on V2), V0/V1 word_size 2 and 4 payloads decode correctly.
- Log reader rejects: bad tag prefix, newline in tag, EOF inside timestamp/interval, non-digit in max, non-base64 histogram; truncates a long tag
  to `tag_len` without overrun; `hdr_log_read` into a pre-allocated accumulator (the `hdr_add` branch of all three decoders) sums V0/V1/V2 jHiccup logs correctly.
- Did NOT reproduce: no test asserts on `h` after `hdr_close`; no test skips on a missing fixture (all `mu_assert(f != NULL)`); no locale/timezone
  dependence in assertions (`ctime_r` only in a diagnostic printf); `rand()` use is unseeded-deterministic. `hdr_shift_values_left/right` do not exist in
  the C API (task item not applicable; Java shift semantics only reach C via decode — see L6-F1).

Coverage (src/*.c, gcov, lines / branches / functions):

| file | MAIN 26587de | COMBINED | MAIN + lane-6 tests |
|---|---|---|---|
| hdr_encoding.c | 92.7% / 80.6% / 11/11 | 95.4% / 86.6% / 11/11 | **100% / 97.0% / 11/11** |
| hdr_histogram.c | 79.6% / 70.5% / 70/76 | 80.5% / 71.4% / 70/76 | **93.8% / 84.6% / 76/76** |
| hdr_histogram_log.c | 82.1% / 67.7% / 34/36 | 82.1% / 67.7% / 34/36 | **91.0% / 80.1% / 36/36** |
| hdr_interval_recorder.c | 96.8% / 75.0% / 17/18 | same | **100% / 87.5% / 18/18** |
| hdr_writer_reader_phaser.c | 89.3% / 55.0% / 10/10 | same | same |
| hdr_thread.c | 76.2% / – / 6/8 | same | same |
| hdr_time.c | 80.0% / – / 3/4 | 89.7% / 100% / 3/4 (#156 tests) | 80.0% / – / 3/4 |
| hdr_packed_histogram.c | – | 92.4% / 60.3% / 39/39 | – |
| **TOTAL** | **83.2% / 69.9% / 151/163** | 85.7% / 67.4% / 190/202 | **93.2% / 83.0% / 160/163** |

Zero-hit functions on MAIN (12): `hdr_add_while_correcting_for_coordinated_omission`, `percentile_iter_next`, `hdr_iter_percentile_init`,
`format_line_string`, `format_head_string`, `hdr_percentiles_print` (hdr_histogram.c); `hdr_strerror`, `apply_to_counts_32` (hdr_histogram_log.c);
`hdr_interval_recorder_init`; `hdr_yield`, `hdr_usleep`; `hdr_getnow`. COMBINED: same 12. With lane-6 tests: only `hdr_yield`, `hdr_usleep`
(reached only on phaser flip contention) and `hdr_getnow` (trivial wrapper) remain.
Public API never called directly by any ctest source on MAIN (32 of 82): `hdr_add_while_correcting_for_coordinated_omission`, `hdr_init_preallocated`,
`hdr_iter_percentile_init`, `hdr_percentiles_print`, `hdr_median_equivalent_value`, `hdr_size_of_equivalent_value_range`, `hdr_record_values_atomic`,
`hdr_record_corrected_values[_atomic]`, `hdr_interval_recorder_init`, `hdr_interval_recorder_record_[corrected_]values[_atomic]`, `hdr_getnow`,
`hdr_usleep`, `hdr_yield`, `hdr_timespec_as_double`, `hdr_timespec_from_double` (COMBINED: covered by #156 tests), all `hdr_mutex_*`, all `hdr_phaser_*`,
`hdr_writer_reader_phaser_init/destroy` (the last three groups are exercised indirectly through the interval recorder). Lane-6 tests call every
`hdr_histogram.h` / `hdr_histogram_log.h` / `hdr_interval_recorder.h` function directly except `hdr_getnow`, `hdr_usleep`, `hdr_yield`, mutex/phaser.
Residual uncovered after lane-6 (cannot be closed by unit tests here): `get_value_from_idx_up_to_count_scalar` block path hdr_histogram.c:757-788 and the
AVX2 tail :831-833 — runtime `__builtin_cpu_supports("avx2")` dispatch makes the scalar scan unreachable on any AVX2 host (only #144's i386 job covers it);
ENOMEM branches; `HDR_DEFLATE_FAIL`; defensive `counts_index >= counts_len` after the range check (:568/:590).

Patch with the new tests: `$SP/lane-6/new-tests.patch` (`git diff` in `$SP/lane-6/work` vs upstream/main 26587de; 3 files, +1030/-6).
Results on MAIN and COMBINED, stock runner + continue-on-failure shim: 48/48 histogram tests pass except 1; 46/46 log tests pass except 5 (+1 LSan).
Every failing test passes against `$SP/lane-6/fixcheck/src` (proposed fixes), as do all pre-existing tests (jHiccup V0/V1/V2 logs, crafted-attack blobs, #155 test).

## Findings (ranked, most severe first)

### L6-F1: Compressed encoding/decoding disagrees with Java on `normalizing_index_offset` — shifted histograms decode with wrong values; C→C round-trip loses counts
- Severity: high     Class: correctness
- Where: `src/hdr_histogram_log.c:200,207` (encoder reads raw `h->counts[i]`), `:226` (writes the offset), `:556` and `:680` (V1/V2 decoders store the payload raw and then set the offset) @ main 26587de; identical in COMBINED.
- Tracked: untracked. #155 (merged) made `hdr_reset_internal_counters` consistent with the *raw storage + offset* model, but the wire format is not that model: Java `AbstractHistogram.fillBufferFromCountsArray` writes `getCountAtIndex(i)` (logical order) and `fillCountsArrayFromSourceBuffer` uses `setCountAtIndex` (normalized write). So a non-zero offset in the header means "payload is logical; rotate on store", while C treats it as "payload is already rotated". The two are equivalent only when offset == 0.
- Repro: `$SP/lane-6/probe/probe_java` (blobs from Java 2.2.2, `Histogram(1,3600000000L,3)`, 10000×1000 + 7×4096 + 100000 + 1000000, then `shiftValuesLeft(2)`):
  ```
  Java:  total=10009 min=4000  max=4001791  p50=4001  count@4000=10000 count@16384=7 count@400000=1 count@4000000=1
  C:     offset=2048 total=10009 min=16000 max=16007167 p50=16007 count@4000=0 count@16384=0 count@400000=0 count@4000000=0   (every value 4x too large)
  shiftValuesRight(1): Java min=2048 max=500223 p50=2049 | C offset=-1024 min=1024 max=250111 p50=1024 (every value 2x too small)
  ```
  C→C: rotate storage of a 10009-count histogram by counts_len/3 (as `test_reset_internal_counters_honours_offset` does), `hdr_log_encode` → `hdr_log_decode`:
  `decoded offset=7850 total=1 count@1000=0 count@4096=0` (encoder truncates at `counts_index_for(max_value)+1`, a *logical* bound applied to *raw* storage).
  New tests: `test_decode_java_shifted_left_histogram`, `test_decode_java_shifted_right_histogram`, `test_encode_decode_offset_histogram_round_trip` (all FAIL on main/COMBINED; PASS with fix).
- Impact: any `.hlog` produced by Java after `shiftValuesLeft/Right` (or a `DoubleHistogram`'s internal histogram, which shifts routinely) is silently misread by every C consumer — values off by a power of two, `hdr_min/max/percentiles` wrong, no error. Offsets of 0 (jHiccup etc.) are unaffected, which is why the fixtures never caught it. Also the whole offset-aware machinery added by #137/#155 currently protects a storage model no real log produces.
- Proposed fix (minimal, Java-equivalent, prototyped in `$SP/lane-6/fix-sketch.patch`): treat the payload as logical order on both sides —
  ```
  -        int64_t value = h->counts[i];
  +        int64_t value = hdr_count_at_index(h, i); /* logical order: Java decodes with setCountAtIndex */
  -            while (i < counts_limit && 0 == h->counts[i])
  +            while (i < counts_limit && 0 == hdr_count_at_index(h, i))
  -    encoded->normalizing_index_offset = htobe32(h->normalizing_index_offset);
  +    encoded->normalizing_index_offset = 0; /* payload is in logical order */
  (V1 and V2 decoders)
  -    h->normalizing_index_offset = be32toh(encoding_flyweight.normalizing_index_offset);
  -    if (h->normalizing_index_offset != 0) { h->normalizing_index_offset %= h->counts_len; }
  +    /* payload is in logical order (Java encodes getCountAtIndex); storage is unrotated */
  +    h->normalizing_index_offset = 0;
  ```
  Alternative B (keeps the rotated-storage model): decoders write `counts[normalize_index(h, i)]` after setting the offset, encoder reads `counts_get_normalised`; needs an internal setter exported from hdr_histogram.c. With fix A the offset is never non-zero in C, so A1-style offset-aware paths become dead-but-harmless.
- Proposed test: the three tests above in `test/hdr_histogram_log_test.c` (Java oracle values embedded as constants, source in `$SP/lane-6/jgen/Gen.java`).
- Confidence: high (Java 2.2.2 source + runtime oracle; deterministic; reproduced on main and COMBINED).

### L6-F2: `hdr_percentiles_print` prints the 64-bit TotalCount column through `%d`
- Severity: medium     Class: correctness (UB; portability on 32-bit)
- Where: `src/hdr_histogram.c:1186,1189,1192` (`format_line_string` builds `"...%d..."`), consumed at `:1462` with `int64_t total_count` @ main 26587de; same in COMBINED.
- Tracked: untracked (no issue/PR mentions percentiles_print; #37 was the timestamp `%d.%d`).
- Repro (`$SP/lane-6/probe/probe_misc`, and new test `test_percentiles_print_total_count_is_64bit`): `hdr_record_values(h, 5000, 1<<33)` then `hdr_percentiles_print(h, f, 1, 1.0, CSV)`:
  ```
  observed: 5003.000,1.000000,0,inf        expected (Java %d on long): 5003.000,1.000000,8589934592,inf
  CLASSIC footer is right (PRIu64): #[Max = 5003.000, Total count = 8589934592]
  ```
- Impact: wrong output for cumulative counts >= 2^31 on LP64 (prints the low 32 bits, here 0); on ILP32/i386 the int64 vararg misaligns the remaining `%12.2f` argument as well. The function had 0 test hits on main.
- Proposed fix: `"f,%f,%" PRId64 ",%.2f\n"` / `"f %12f %12" PRId64 " %12.2f\n"` (`<inttypes.h>` is already included for `CLASSIC_FOOTER`) and grow `line_format` from 25 to 32 bytes (the PRId64 form is 27+1 chars; 25 silently truncates).
- Proposed test: `test/hdr_histogram_test.c` — `test_percentiles_print_csv_and_classic` (shape, header, footer, `value_scale`) and `test_percentiles_print_total_count_is_64bit` (last CSV line contains `,8589934592,`), plus `test_percentiles_print_reports_eio` (read-only `/dev/null` stream → EIO, UNIX-only).
- Confidence: high.

### L6-F3: Log reader rejects comment lines in the body, which the log format allows anywhere
- Severity: medium     Class: correctness (interop)
- Where: `src/hdr_histogram_log.c:1181-1183` (INIT state: anything but `T`, digit, CR/LF, EOF → `-EINVAL`) @ main 26587de; same in COMBINED.
- Tracked: untracked.
- Repro (`probe_misc`, new test `test_log_reader_skips_comment_lines`): write header + entry + `#[a comment in the body]\n` + entry; `hdr_log_read` returns `0, -22, -22` — expected `0, 0, EOF`. Java `HistogramLogReader` (header comment, line 28: lines starting with `#` "are optional and treated as comments") skips them anywhere; jHiccup/HdrHistogram Java writers emit `#[...]` lines mid-log (e.g. on rotation / restart).
- Impact: a valid Java-written log with any mid-file comment stops decoding at the comment; the caller sees `-EINVAL` and typically drops the rest of the file.
- Proposed fix: in the INIT state, `else if ('#' == c) { /* comment line: format allows them anywhere */ while ((c = fgetc(file)) != EOF && c != '\n') { } }`.
- Proposed test: `test_log_reader_skips_comment_lines` (above).
- Confidence: high.

### L6-F4: Header lines longer than 127 bytes break `hdr_log_read_header` — the writer accepts an unbounded user prefix the reader cannot read back
- Severity: medium     Class: correctness
- Where: `src/hdr_histogram_log.c:993` (`char line[HEADER_LINE_LENGTH]; /* TODO: check for overflow. */`), `:1006/:1015` (`fgets` reads 127 bytes, the remainder of the line is then mis-parsed as the end of the header) vs `:767` (`print_user_prefix` prints any length) @ main 26587de; same in COMBINED.
- Tracked: untracked (the TODO is in the code).
- Repro (`probe_misc`, new test `test_log_header_long_prefix_round_trip`): `hdr_log_write_header(&w, f, <200 x 'x'>, &ts)` + one entry, rewind, `hdr_log_read_header` → `-29993 HDR_LOG_INVALID_VERSION` (major=0 minor=0), then `hdr_log_read` → `-22`. Expected `0` / `0`. A `#[StartTime: ...]` line with a long zone name or a long `#[Logged with ...]` line has the same effect.
- Impact: own-writer/own-reader round-trip failure; a log header from another tool with a >127-byte comment is unreadable. No memory safety issue (fgets is bounded).
- Proposed fix: after each `fgets` in the header loop, drain the rest of an over-long line: `while (line[strlen(line) - 1] != '\n' && fgets(line, HEADER_LINE_LENGTH, file) != NULL) { }` (both the `#` and `"` cases), or read header lines with a growable buffer.
- Proposed test: `test_log_header_long_prefix_round_trip` (above).
- Confidence: high.

### L6-F5: `hdr_log_read_entry(..., entry == NULL)` leaks the 1024-byte line buffer
- Severity: low     Class: hygiene (leak on an error path)
- Where: `src/hdr_histogram_log.c:1137` allocates before the `NULL == entry` check at `:1144-1147` returns @ main 26587de; same in COMBINED.
- Tracked: untracked (#122 fixed other leaks in this file).
- Repro: new test `test_log_read_entry_null_entry` under ASan: `Direct leak of 1024 byte(s) ... hdr_log_read_entry hdr_histogram_log.c:1137:30`; return value is `-EINVAL` as expected.
- Impact: 1 KiB per call for a caller that passes NULL; CI sanitizer job would flag any new test touching it (LSan is on since #145).
- Proposed fix: move `base64_histogram = hdr_calloc(capacity, sizeof(char));` below the argument check (and NULL-check it: `-ENOMEM`). Same file: `hdr_log_decode:1326` mallocs without a NULL check before `memset`; `:1266` calloc unchecked.
- Proposed test: `test_log_read_entry_null_entry` (LSan makes it fail on main).
- Confidence: high.

### L6-F6: Weak / order-dependent assertions in the existing suite (would have hidden the #155 class of bug)
- Severity: medium     Class: coverage
- Where (all @ main 26587de, unchanged in COMBINED):
  1. `test/hdr_histogram_log_test.c:599-604` `writes_and_reads_log`: `hdr_log_write_entry(...)` return value is discarded; the two `mu_assert("Failed ... write", validate_return_code(rc))` re-check the header's `rc` and can never fail.
  2. `test/hdr_histogram_log_test.c:110-121` `compare_histogram`: `hdr_max`/`hdr_min` mismatches are only `printf`'d, the function keeps going and returns true if the raw `counts[]` bytes match — so every encode/decode round-trip test is blind to min/max regressions (exactly #155's symptom on decoded logs) and, with L6-F1, to logical-vs-raw confusion as long as the bytes coincide.
  3. Order dependence: `writes_and_reads_log` and `log_reader_aggregates_into_single_histogram` never call `load_histograms()`; they only work because `test_bounds_check_on_decode` ran before them (run alone → `hdr_log_write_entry(NULL histogram)` crash). `test_encode_and_decode_empty` replaces `raw_histogram` with a `(1,1000000,1)` histogram for whoever runs next. `tests_run = 0` at `:1153` miscounts.
  4. `test/hdr_atomic_test.c:54-55` `test_exchange` ignores the returned old value; `hdr_atomic_compare_exchange_64` has no direct test (only reached through `update_min_max_atomic`, where the CAS-retry edge never fires — branch 146/157 B0 never taken even in the concurrency test, whose values are `rand() % 20000` so min/max stop changing almost immediately).
  5. LSan-swallows-minunit pattern (`.workspace-memory/hdr-upstream-prs.md`): the majority of pre-#149 tests `mu_assert` while `h` is still allocated (e.g. `test_create_with_large_values`, `test_out_of_range_values`, all `load_histograms()` consumers); a failure under the sanitizer job prints only a leak trace.
  6. `compare_int64` (`minunit.c:75`) prints int64 with `PRIu64` (negative deltas print as huge unsigned; `-Wformat=2` warns).
  7. Wall-clock dependence: `hdr_gettime()` in `writes_and_reads_log`/aggregates + `compare_timespec` requiring equal `tv_sec` — covered by PR #156 (deterministic clock-boundary test), not re-raised.
- Tracked: 7 → covered by #156; 1-6 untracked.
- Repro: read-through; for (1) I confirmed by inspection that `rc` is not reassigned between `:594` and `:600/:604`; for (2) the new tests `test_encode_decode_large_counts`/Java tests use `compare_histogram` and pass only after the fix below made it strict (they still pass on main with the strict comparator, so the fix is safe).
- Impact: the round-trip suite cannot detect min/max/percentile regressions of decoded histograms; write-path errors are unobservable.
- Proposed fix (in the patch): `rc = hdr_log_write_entry(...)` on both calls; `return false;` after each min/max mismatch print (and `PRId64`); `load_histograms()` at the top of both fixture-dependent tests. Recommended follow-ups (not in patch): capture-then-`hdr_close`-then-assert in the older tests; assert the return of `hdr_atomic_exchange_64` and add a direct CAS success/failure test.
- Proposed test: covered by the patch changes above; the strict comparator is what makes `test_decode_java_*` and the offset round-trip test meaningful.
- Confidence: high.

### L6-F7: Three committed log fixtures are not wired into any test (only reachable as fuzzer seed corpus); duplicated CMake loop
- Severity: low     Class: coverage / hygiene
- Where: `test/regression-bucket-config-shift-overflow.hlog` (added by #145), `test/regression-log-timestamp-overflow.hlog` (added by #153), `test/hiccup.140623.1028.10646.hlog` (the original 1.01 sample): none is `configure_file`'d in `test/CMakeLists.txt` and none is opened by any `test/*.c`; the only consumer is `.clusterfuzzlite/build.sh:25` (`zip ... test/*.hlog` seed corpus). `test/CMakeLists.txt:79-85` copies the jHiccup fixtures twice (identical `foreach` blocks).
- Tracked: untracked.
- Repro: `for f in test/*.hlog test/*.txt; do grep -l "$f" test/*.c test/CMakeLists.txt; done` → empty for the three files; `git log --follow` shows #145/#153 added the fixture but the tests those PRs added (`test_bucket_config_shift_overflow`, `handle_invalid_log_lines`) hard-code values instead of reading them.
- Impact: the regression inputs that motivated two UBSan fixes are not exercised by ctest; a future change to the reader/decoder could regress on them and only the weekly fuzz job would notice.
- Proposed fix (in the patch): one `foreach(V hiccup.140623.1028.10646.hlog regression-bucket-config-shift-overflow.hlog regression-log-timestamp-overflow.hlog) configure_file(...)`, drop the duplicate jHiccup loop.
- Proposed test (in the patch): `test_regression_fixture_logs` — bucket-config fixture: first entry rejected (non-zero, non-EOF); timestamp fixture: first entry `-EINVAL`; 1.01 sample: header minor version 1, 11 entries decode, EOF, start time 1403476110. Observation while writing it: V0/V1 decoders report a rejected bucket config as `ENOMEM` (`hdr_histogram_log.c:423`, `:528` collapse every `hdr_init` failure to ENOMEM) whereas V2 passes `EINVAL` through (`:644-647`); the test therefore asserts `rc != 0` for the V1.01-format fixture. Harmonising to pass `rc` through is a one-line hygiene fix.
- Confidence: high.

### L6-F8: Gaps that unit tests cannot close on this host, and one Java divergence that is not a bug
- Severity: info     Class: coverage
- Where: `src/hdr_histogram.c:757-788` (scalar block scan) and `:831-833` (AVX2 tail) @ main; `src/hdr_histogram.c:524-530` (`hdr_reset`).
- Tracked: scalar-path CI coverage → covered by PR #144 (i386 job); `hdr_min`/mean on empty → issue #125; empty p95 → issue #116.
- Repro: gcov shows 0 hits for the scalar scan on this AVX2 host before and after the new tests (`__builtin_cpu_supports("avx2")` dispatch at `:844`); `probe_misc`: after `hdr_reset` of a rotated histogram `normalizing_index_offset` stays 100 (Java `reset()` calls `setNormalizingIndexOffset(0)`), but total/min/max/percentiles and subsequent recording are correct, so it is a harmless divergence (and moot under the L6-F1 fix A).
- Impact: the scalar percentile scan that every non-AVX2 target runs is validated only by #144's CI job; `hdr_yield`/`hdr_usleep` (phaser contention) and ENOMEM paths remain untested.
- Proposed fix: none required; optionally a `HDR_DISABLE_AVX2` test-only define, or a hidden `hdr_value_at_percentile_scalar` hook, to let the unit suite pin scalar == AVX2 on x86-64.
- Proposed test: n/a.
- Confidence: high (measured).

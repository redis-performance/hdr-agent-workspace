# Lane 3 — Log codec: hdr_histogram_log.c / hdr_encoding.c (+ hdr_time.c reader path)

All line numbers are `@ main 26587de` unless stated. `$SP` = the scratchpad root from BRIEF.md; every
harness lives in `$SP/lane-3/probe/` (`pN_*.c`, compiled against `$SP/lane-3/build/asan` = clang
`-fsanitize=address,undefined,float-cast-overflow -fno-sanitize-recover=all`). `$SP/lane-3/probe/probe_common.h`
has `make_frame()` (build a compressed V1/V2 frame from raw header fields + payload). A prototype patch for
L3-F1/F2/F4/F5 is saved as `$SP/lane-3/probe/lane3-proto-fixes.diff` (applies cleanly to main, ctest 5/5, adds
no new gcc `-Wall -Wextra -Wconversion -Wshadow -Wformat=2` warnings); the tree itself is left unmodified.

Scope probed:
- Full read of `src/hdr_histogram_log.c`, `src/hdr_encoding.c`, `src/hdr_encoding.h`, `include/hdr/hdr_histogram_log.h`,
  `src/hdr_time.c` (`hdr_timespec_from_double`, called from `scan_start_time`), plus Java `AbstractHistogram.java`,
  `Histogram.java`, `HistogramLogWriter.java` as the semantic tie-breaker (fetched from raw.githubusercontent.com).
- Crafted V1/V2 frames: zig-zag INT64_MIN zero-run, `normalizing_index_offset` = INT32_MIN/INT32_MAX/±1, word_size 2
  with 0xFFFF, sig figs 9, lowest 0, header offset 0 vs 5 on the same payload (`p1`, `p4`, `p8`).
- Truncated deflate streams (compression `length` = 1..40 of a valid frame) through V2 decode, with an instrumented copy
  of the decoder (`build/instr`) printing `strm.avail_out` after the header inflate (`p2`).
- base64: invalid chars, embedded `=`, high bytes, spaces, lengths 0/3/5; `hdr_log_decode` with len 0/8/12;
  8-byte compression frame with `length` = INT32_MAX / INT32_MIN (`p6`).
- Round trips: `hdr_init(1, INT64_MAX, 3)` + record INT64_MAX + `total_count` = INT64_MAX (encode → decode → re-encode
  byte identity, and `hdr_log_write` → `hdr_log_read`) (`p7`); negative counts (`p5`); offset≠0 (`p4b`).
- Log text layer: user prefix 5/120/124/125/299 chars via `hdr_log_write_header` → `hdr_log_read_header` (`p3`);
  `#[StartTime: nan|inf|1e300|-1.5]` on MAIN and COMBINED (`p9`); tags `a,b`, `x\ny`, empty (`p10`); the V2 fixture
  converted to CRLF (`p10`); `hdr_log_read_entry(entry=NULL)` under LSan; merge into a caller-supplied smaller
  histogram (`p8`).
- Fuzzing on MAIN, clang `-fsanitize=fuzzer,address,undefined,float-cast-overflow -fno-sanitize-recover=all`, library
  built with `-fsanitize=fuzzer-no-link,...` (`build/fuzz`), fork mode `-ignore_crashes=1`, seeds = `test/*.hlog`
  (+ `test/*.txt`) for `log_reader_fuzzer`, the 244 base64 columns extracted from the `.hlog` files for `hdr_decode_fuzzer`:
  `log_reader_fuzzer` 334 s (4 workers), `hdr_decode_fuzzer` 330 s (3), `hdr_record_fuzzer` 330 s (3), plus a
  `log_reader_fuzzer` variant with `float-cast-overflow` disabled for 330 s (3) so the known `(int) value` cast does not
  mask other bugs. Total ≈ 22 fuzzer-minutes. All crash artifacts replayed against a binary linked to the COMBINED library.
- Warnings sweep: gcc 13 / clang 18, `-Wall -Wextra -Wconversion -Wshadow -Wformat=2` (+ gcc `-Wformat-signedness`).
- `ctest` on `$SP/lane-3/build/asan`: 5/5 pass (baseline).

Verified OK:
- `hdr_base64_decode` rejects len < 4, len % 4 != 0 (`-EINVAL`); `hdr_log_decode(len 0)` → `-EINVAL`, no deref of the
  `malloc(0)` result; `hdr_decode_compressed` on an 8-byte V2 frame with `length` INT32_MAX or INT32_MIN → `EINVAL`.
- V2 zig-zag reader bounds: `calloc(counts_limit + 9)` covers the 9-byte LEB128 lookahead; V0/V1 reject word_size 1
  (and 0/3/5/9 → `HDR_INVALID_WORD_SIZE`); V1 negative `payload_len` and `counts_limit > counts_len` rejected; V2
  `counts_limit > 9*counts_len` rejected. No ASan finding in 29 M `hdr_decode_fuzzer` executions.
- Header `normalizing_index_offset` INT32_MIN / INT32_MAX / -1 / +1: the `%= counts_len` reduction (C truncating modulo)
  lands in (-counts_len, counts_len), `normalize_index`'s single wrap is sufficient, percentile queries stay in range
  (observed stored offsets -2048 / 2047 / -1 / 1 for counts_len 11264; no OOB). Negative modulo is not a bug here.
- Header sig figs 9 or lowest 0: `hdr_init` rejects, `h` is freed, LSan clean (V2 returns EINVAL; V0/V1 return ENOMEM —
  see L3-F9).
- `hdr_init(1, INT64_MAX, 3)`, record INT64_MAX and `total_count` = INT64_MAX: encode → decode → re-encode is
  byte-identical (47 bytes); `hdr_log_write` → `hdr_log_read` reproduces identical `counts[]`, max = INT64_MAX. No UB.
- CRLF: V2 fixture converted to `\r\n` reads 62 histograms / total 48761, identical to LF.
- V3 (`jHiccup-2.0.7S.logV3.hlog`): declared (`validate_log_version` accepts minor 3, :982-987) and exercised by
  `test_log_reader_reads_v3` (62 histograms, total 48761, `Tag=` lines parsed). Note: `#[BaseTime:` is ignored by the
  C reader (Java's `HistogramLogReader` adds `baseTimeSec` to interval timestamps); callers get raw log timestamps.
  Info only, no crash surface.
- `#[StartTime: nan|inf|1e300]`: UBSan abort on MAIN at `hdr_time.c:92` (`(int) value`) — covered by #154; COMBINED
  returns `{0,0}`; `-1.5` → `{-2, 500000000}` (correct normalization, #156).
- `test/regression-bucket-config-shift-overflow.hlog`, `test/regression-log-timestamp-overflow.hlog`,
  `test/hiccup.140623.1028.10646.hlog` all parse clean under ASan/UBSan on main (see L3-F8 for the coverage gap).
- Fuzzing (final): `hdr_decode_fuzzer` 54.2 M execs / 336 s, 0 crashes, 0 OOM/timeouts; `hdr_record_fuzzer` 128 K execs /
  340 s (slow target, ~94 exec/s), 0 crashes; `log_reader_fuzzer` 2.94 M execs / 334 s, 379 crashes = ONE signature
  (`hdr_time.c:92:19 ... outside the range of representable values of type 'int'`); the float-cast-disabled variant
  0.90 M execs / 332 s, 243 crashes = ONE signature (`hdr_time.c:96:31 signed integer overflow: -2147483648 * N` in
  `milliseconds * 1000000`). All 624 artifacts replay clean (exit 0, 624 executed, 0 sanitizer lines) with the COMBINED
  library → both fully covered by #154/#156 (`$SP/lane-3/fuzz/logs/replay_combined_final.log`). One sample of each saved as
  `$SP/lane-3/repro-covered-by-PR154-hdr_time-int-cast.hlog` and `$SP/lane-3/repro-covered-by-PR156-hdr_time-ms-mul-overflow.hlog`.
  No other crash class surfaced in the codec.
- Warnings sweep: zero `-Wall -Wextra -Wshadow` warnings in the three files; residual are `-Wsign-conversion` on
  `be32toh/be64toh` results assigned to signed fields, `-Wformat-nonliteral` on the two `sscanf` const-format calls, and
  the `PRIu64`-with-`int64_t` mismatch at :867/:924 (gcc `-Wformat-signedness` only, see L3-F9).

## Findings (ranked, most severe first)

### L3-F1: V2 zero-run decode negates INT64_MIN before range-checking it (signed-overflow UB on attacker bytes)
- Severity: medium     Class: security
- Where: `src/hdr_histogram_log.c:310` (`int64_t zeros = -value;`), check only at :312, in `apply_to_counts_zz`
  (reachable via `hdr_log_read` / `hdr_log_decode` / `hdr_decode_compressed` V2). Same on COMBINED.
- Tracked: untracked (not in #144/#150/#154/#156, not in #118/#126; the 2026-09 fuzz fixes #145/#146/#153 are elsewhere).
- Repro: `$SP/lane-3/probe/p1_zz_int64min.c` builds a V2 frame whose payload is 9 × `0xFF` (zig-zag → INT64_MIN):
  ```
  zz decodes to -9223372036854775808 (INT64_MIN=1)
  src/hdr_histogram_log.c:310:29: runtime error: negation of -9223372036854775808 cannot be represented in type 'int64_t'
  SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior src/hdr_histogram_log.c:310:29
  ```
  With the prototype fix: `hdr_decode_compressed rc=-29992 (Invalid number of trailing zeros) h=(nil)`.
- Impact: UB in the attacker-facing decoder on 9 wire bytes. On two's complement hardware `-INT64_MIN` wraps to
  INT64_MIN, the `value <= INT32_MIN` test then rejects, so no memory unsafety today; but any consumer built with UBSan
  `-fno-sanitize-recover` (the project's own `sanitizers` CI job and ClusterFuzzLite UBSan batch) aborts, and the compiler
  is entitled to assume the negation cannot overflow. The coverage-guided fuzzers did not find it in this run because they
  rarely synthesise a valid deflate stream around it.
- Proposed fix (prototype in `lane3-proto-fixes.diff`):
  ```c
          if (value < 0)
          {
              /* range-check before negating: INT64_MIN is reachable from the wire */
              if (value <= INT32_MIN || counts_index - value > h->counts_len)
              {
                  return HDR_TRAILING_ZEROS_INVALID;
              }

              counts_index += (int32_t) -value;
          }
  ```
- Proposed test: `test/hdr_histogram_log_test.c` `test_v2_decode_rejects_int64min_zero_run` — build the frame as in `p1`
  (or check in the 40-odd bytes), assert `HDR_TRAILING_ZEROS_INVALID` and `h == NULL`; runs under the `sanitizers` job.
- Confidence: high (UBSan report + Java `fillCountsArrayFromSourceBuffer` rejects `zc > Integer.MAX_VALUE` after the same
  negation, which Java defines but C does not).

### L3-F2: truncated deflate stream leaves the header flyweight partially written; decoder proceeds on uninitialised stack
- Severity: medium     Class: security
- Where: `src/hdr_histogram_log.c:395` (V0), `:499` (V1), `:622` (V2): `if (inflate(&strm, Z_SYNC_FLUSH) != Z_OK)` accepts
  `Z_OK` with `strm.avail_out > 0`; the following reads of `encoding_flyweight.{cookie,payload_len,offset,sig,low,high,ratio}`
  (:400-415 / :504-520 / :627-642) then use never-written stack bytes. Same on COMBINED.
- Tracked: untracked.
- Repro: `$SP/lane-3/probe/p2_partial_inflate.c` (+ `build/instr`, which only adds two `fprintf`s) sets the compression
  `length` of a valid 3600 s V2 frame to 1..40:
  ```
  trunc=17: [instr v2] header inflate returned Z_OK with avail_out=16 of 40 (avail_in left=0)
  [instr v2] hdr_init(low=1, high=0, sig=3) counts_limit=2999      -> rc=22
  trunc=20: [instr v2] header inflate returned Z_OK with avail_out=11 of 40 (avail_in left=0)
  [instr v2] hdr_init(low=1, high=3590324224, sig=3) counts_limit=2999   -> rc=-29994
  ```
  `highest_trackable_value` 3590324224 is the true 3600000000 with its low bytes never written; `hdr_init` succeeded on
  it and allocated `counts[]` before the second `inflate` failed. Uninitialised bytes happened to read as zero here;
  they are whatever the stack held. zlib documents this: `Z_OK` = "some progress", `Z_STREAM_END` only at end of stream.
  With the prototype fix every `trunc` returns `HDR_INFLATE_FAIL` (-29994).
- Impact: attacker-controlled truncation turns `hdr_init` parameters and `counts_limit` into stack garbage. Allocation
  size is still bounded by `hdr_init`'s own validation (≤ ~50 MB for sig figs 5) and no write goes out of bounds, so this
  is a MSan-class defect (nondeterministic error code / behaviour, not memory corruption). It is invisible to the ASan-only
  PR fuzzing and to UBSan; MSan is not runnable without an instrumented zlib.
- Proposed fix (prototype): in all three decoders
  ```c
      /* truncated stream: inflate returns Z_OK with a partially written header */
      if (inflate(&strm, Z_SYNC_FLUSH) != Z_OK || strm.avail_out != 0)
  ```
  (optionally also `memset(&encoding_flyweight, 0, sizeof encoding_flyweight)` as belt-and-braces).
- Proposed test: `test_decode_rejects_truncated_header` — encode a histogram, overwrite `length` with 12, assert
  `HDR_INFLATE_FAIL`; repeat for a V1 and V0 frame built with `make_frame`.
- Confidence: high for the mechanism (instrumented `avail_out`); medium for exploit relevance (no corruption path found).

### L3-F3: `normalizing_index_offset != 0` — C encodes/decodes PHYSICAL order, Java LOGICAL; C round trip also drops counts
- Severity: medium     Class: correctness
- Where: encode `src/hdr_histogram_log.c:189-219` (`len_to_max = counts_index_for(h, max_value) + 1` is a logical index
  but the loop reads `h->counts[i]` physically); decode `:321` (`h->counts[counts_index] = value`) with the offset applied
  afterwards at `:680-688` (V2) and `:554-564` (V1). Same on COMBINED (#155 fixed only the min/max reconstruction).
- Tracked: untracked. #155 (merged) and #137 made the *read* paths offset-aware; the codec's interpretation of the offset
  itself is not covered by any PR/issue.
- Repro: `$SP/lane-3/probe/p4_offset_semantics.c`
  (a) Same zig-zag payload (`-10, 1` = one count at logical index 10), header offset 0 vs 5:
  ```
  (a) header offset=0 rc=0 total=1 min=10 max=10 p50=10
  (a) header offset=5 rc=0 total=1 min=15 max=15 p50=15
  ```
  Java: `decodeFromByteBuffer` calls `histogram.setNormalizingIndexOffset(normalizingIndexOffset)` (AbstractHistogram.java
  :2131) *before* `fillCountsArrayFromSourceBuffer` → `setCountAtIndex(dstIndex++, count)` (:2221), and
  `Histogram.setCountAtIndex` writes `counts[normalizeIndex(index, ...)]` (Histogram.java:70-72); the encoder likewise reads
  `getCountAtIndex(srcIndex++)` (:2234). So the Java result for the offset-5 frame is min=max=10; C says 15.
  (b) C-only round trip of a histogram whose offset is non-zero (as any decoded/rotated histogram is), 5 values recorded:
  ```
  (b) src: counts_len=11264 offset=-5632 total=5 p50=102
  (b) encode rc=0 len=45
  (b) decode rc=0 total=0 (expected 5) p50=0 offset=-5632
  ```
  All five counts are lost: they sit at physical index ≥ 5632 but the encoder stops at logical `len_to_max` = 103.
- Impact: any log with a non-zero offset (Java `shiftValuesLeft/Right` users; a C histogram that was decoded from such a
  log and then recorded into / re-logged) is silently mis-decoded across implementations and loses data on a C→C round
  trip. Plain jHiccup/wrk2-style logs have offset 0 and are unaffected, hence medium not high.
- Proposed fix: make the codec logical like Java — encode via `hdr_count_at_index(h, i)` (public, offset-aware) instead of
  `h->counts[i]`, and on decode set `h->normalizing_index_offset` (after the `%=` reduction) *before* `apply_to_counts*`
  and store through a normalised index (expose `normalize_index` via `hdr_tests.h` or add a static twin in the log file).
  Terse comment: `/* wire order is logical (Java parity); counts[] is physical */`. Behavioural change only for offset≠0
  frames, which C never produces itself today.
- Proposed test: `test_encode_decode_nonzero_offset` (record with offset≠0, round trip, compare via `hdr_iter`) and a
  Java-parity fixture asserting min=max=10 for the offset-5 frame from `p4(a)`.
- Confidence: high on the divergence and the data loss (both observed); medium on the fix shape (maintainer design call).

### L3-F4: `hdr_encode_compressed` accepts negative counts, which decode as zero-runs (silent corruption; Java throws)
- Severity: medium     Class: correctness
- Where: `src/hdr_histogram_log.c:216-218` (else-branch zig-zag-encodes `value` regardless of sign). Same on COMBINED.
- Tracked: untracked (#126 is about value bounds, not counts; the 2026-09-29 #141 review noted the API accepts negative
  counts but no PR guards the codec).
- Repro: `$SP/lane-3/probe/p5_negative_count.c` — `hdr_record_values(h, 101, -3)` between two positive counts:
  ```
  src total=8 c(100)=7 c(101)=-3 c(105)=4
  encode rc=0 (Java throws 'Cannot encode histogram containing negative counts')
  decode rc=0 (Success)
  dst total=11 c(100)=7 c(101)=0 c(105)=0 c(108)=0
  ```
  The decoded histogram has a different total and the `4` landed on another index. With the prototype fix: `encode rc=22`.
- Impact: `hdr_log_write*` / `hdr_log_encode` produce a well-formed frame that decodes to a different histogram, with no
  error anywhere. Java's `fillBufferFromCountsArray` throws (AbstractHistogram.java:2235-2239).
- Proposed fix (prototype):
  ```c
          else if (value < 0)
          {
              /* a negative count would decode as a zero run */
              FAIL_AND_CLEANUP(cleanup, result, EINVAL);
          }
  ```
- Proposed test: `test_encode_rejects_negative_counts` asserting `EINVAL` from `hdr_encode_compressed` and from
  `hdr_log_encode`, and that no buffer is returned.
- Confidence: high.

### L3-F5: header lines ≥ 128 bytes break `hdr_log_read_header`; the library cannot read its own `hdr_log_write_header` output
- Severity: medium     Class: correctness
- Where: `src/hdr_histogram_log.c:989` (`HEADER_LINE_LENGTH 128`), `:993` (`char line[128]; /* TODO: check for overflow. */`),
  `:1006` / `:1015` (`fgets` without consuming the rest of the line). Same on COMBINED.
- Tracked: untracked.
- Repro: `$SP/lane-3/probe/p3_long_header.c` writes a header with a user prefix of N chars then reads it back:
  ```
  120-char prefix: read_header rc=0 version=1.2 read_entry rc=0 total=1
  124-char prefix: read_header rc=-29993 version=0.0
  299-char prefix: read_header rc=-29993 version=0.0
  ```
  At 124 chars the line is exactly 128 bytes; `fgets` leaves the `\n`, the next `fgetc` is not `#`/`"`, header parsing
  stops before the version line → `HDR_LOG_INVALID_VERSION`. Longer lines leave their tail to be parsed as a CSV entry.
  With the prototype fix all five cases read back `rc=0 total=1`.
- Impact: `hdr_log_write_header(..., user_prefix, ...)` places no limit on the prefix, so a C writer can emit logs the C
  reader rejects; Java `HistogramLogWriter.outputComment` lines of any length (common in tooling that embeds command
  lines or JSON in `#[...]`) are likewise unreadable. Not memory-unsafe (`fgets` is bounded).
- Proposed fix (prototype): a `read_header_line()` helper that `fgets` and, if no `\n` was seen, drains to end of line
  (`do c = fgetc(file); while (c != '\n' && c != EOF);`), used by both the `#` and `"` cases; the version/StartTime scans
  only need the first 127 bytes. Comment: `/* header lines may exceed the buffer (user prefix); parse the head, drop the tail */`.
- Proposed test: `test_log_header_long_user_prefix` — 300-char prefix round trip, plus a `#[...]` comment line of 5 KB
  followed by a valid entry.
- Confidence: high.

### L3-F6: base64 decoder silently accepts invalid characters (invalid sextet = 22)
- Severity: low     Class: correctness
- Where: `src/hdr_encoding.c:208` (`from_base_64` returns `EINVAL` = 22, indistinguishable from `'W'`), consumed unchecked
  at `:295-298`; `hdr_base64_decode` `:305-323` only validates length. Same on COMBINED.
- Tracked: untracked.
- Repro: `$SP/lane-3/probe/p6_base64.c`
  ```
  hdr_base64_decode(4 bytes "!!!!") rc=0 out=596596
  hdr_base64_decode("A A A A ")     rc=0 out=016016016016
  hdr_log_decode(12 x '!')          rc=-29999 (Compression cookie mismatch)
  ```
- Impact: corrupted/edited log lines are not detected at the transport layer; they only fail later (cookie mismatch) or,
  if the damage is inside the deflate stream, as a zlib error — or decode to a wrong histogram if the damage survives
  CRC-less inflation. No memory issue (all reads are of `input[0..3]`, output is exactly 3 bytes per block).
- Proposed fix: make `from_base_64` return `-1` on invalid input (including `=` outside the last two positions), have
  `hdr_base64_decode_block` return int and `hdr_base64_decode` return `-EINVAL` on the first bad sextet. Update the two
  test callers of `hdr_base64_decode_block` (`hdr_tests.h`).
- Proposed test: `test_base64_decode_rejects_invalid_chars` for `"!!!!"`, `"AA=A"`, `"\x80\x80\x80\x80"`.
- Confidence: high (behaviour observed); severity low because the compressed frame has its own cookie/length checks.

### L3-F7: `hdr_log_write_entry` does not reject `,`/newline in the tag, producing lines the reader cannot parse
- Severity: low     Class: correctness
- Where: `src/hdr_histogram_log.c:918-932`. Same on COMBINED.
- Tracked: untracked.
- Repro: `$SP/lane-3/probe/p10_tag_crlf.c`
  ```
  (1) tag=a,b:  write rc=0 read rc=-22 (Unknown error -22) tag_read='a'
  (1) tag=x\ny: write rc=0 read rc=-22 (Unknown error -22) tag_read='x'
  ```
  Java `HistogramLogWriter` throws `IllegalArgumentException("Tag string cannot contain commas, spaces, or line breaks")`
  (HistogramLogWriter.java:129-131).
- Impact: a caller-supplied tag with a delimiter corrupts the log from that line on (the `x\ny` case also splits into two
  lines, the second of which starts with `y` → `-EINVAL` for the rest of the file).
- Proposed fix: before formatting, `if (has_tag && memchr/strpbrk(entry->tag, ",\r\n ") ...) return EINVAL;`
  (one-line comment: `/* Java rejects delimiters in tags; a comma or newline corrupts the line */`).
- Proposed test: `test_log_write_entry_rejects_delimiter_in_tag`.
- Confidence: high.

### L3-F8: three `.hlog` fixtures in `test/` are never opened by ctest (fuzzer seeds only)
- Severity: low     Class: coverage
- Where: `test/CMakeLists.txt:80-90` copies only the four `jHiccup-*.hlog` and the seven `*.txt`; nothing references
  `regression-bucket-config-shift-overflow.hlog` (added by #145), `regression-log-timestamp-overflow.hlog` (#153) or
  `hiccup.140623.1028.10646.hlog`. Their only consumer is `.clusterfuzzlite/build.sh:24` (`zip -j ... test/*.hlog`).
  COMBINED adds `regression-log-start-time-overflow.hlog` to `configure_file` but it too is not opened by a test.
- Tracked: untracked (equivalent *inline* regressions exist: `test_bucket_config_shift_overflow` in
  `hdr_histogram_test.c:218` and the digit-run test at `hdr_histogram_log_test.c:1139`, so the bugs are covered; the
  files are not).
- Repro: `grep -rn "regression-" test/*.c test/CMakeLists.txt .github/workflows` → no hits; running each through the
  fuzzer binary on main: `Executed ... in 1 ms`, no sanitizer output (they are clean).
- Impact: a future regression that only shows on the real file (header + CSV + base64 path) would not be caught by ctest;
  the `sanitizers` CI job never sees them. Also the `*.txt` fixtures are not in the fuzz seed zip.
- Proposed fix: add the missing files to the `configure_file` loop and a `test_all_fixtures_parse` that runs
  `hdr_log_read_header` + `hdr_log_read` loop over every `.hlog`, asserting either EOF or an expected error code per file.
  Optionally `zip -j ... test/*.hlog test/*.txt` in `build.sh`.
- Proposed test: as above, in `test/hdr_histogram_log_test.c`.
- Confidence: high.

### L3-F9: hygiene bundle in the codec (no crash; error-handling and API consistency)
- Severity: low     Class: hygiene
- Where / observed (all `p8_misc.c`, `p6_base64.c`, `p8` under LSan):
  1. `src/hdr_histogram_log.c:1137` allocates 1024 B before the `entry == NULL` check at `:1144-1147` returns →
     LSan: `Direct leak of 1024 byte(s) ... hdr_log_read_entry hdr_histogram_log.c:1137`.
  2. Sign convention is mixed: `hdr_log_read_entry`/`hdr_base64_decode` return `-EINVAL`, `hdr_decode_compressed*` return
     `+EINVAL`/`+ENOMEM`; `hdr_strerror(-EINVAL)` → `"Unknown error -22"` (observed). The header doc promises `EINVAL`.
  3. V0/V1 map every `hdr_init` failure to `ENOMEM` (`:423`, `:528`) — observed `V1 sig=9 rc=12 (Cannot allocate memory)`;
     V2 already propagates `rc`.
  4. `hdr_log_decode:1326-1327` (`hdr_malloc` then `memset`), `hdr_log_write:857`, `hdr_log_write_entry:909`,
     `hdr_log_encode:1301`, `hdr_log_read_entry:1266` — allocation results used without a NULL check.
  5. `:867` / `:924` print `hdr_max()` (`int64_t`) with `PRIu64` (gcc `-Wformat-signedness`).
  6. `hdr_add(*histogram, h)` return (dropped values) is ignored at `:460`/`:582`/`:706`: merging a decoded log into a
     caller-supplied histogram with a smaller range returns `rc=0` with `total=1` of 2 (observed). Java throws.
  7. `apply_to_counts_16/32` zero-extend (`be16toh` → 65535 for `0xFFFF`) where Java `getShort` sign-extends; only matters
     for invalid (negative) counts.
- Tracked: untracked.
- Proposed fix: move the `entry` check above the `hdr_calloc`; pick one sign convention (positive errno like the header
  says) and make `hdr_strerror` handle negatives; propagate `hdr_init`'s `rc` in V0/V1; add the missing NULL checks;
  `PRId64`; return/propagate the dropped count (or document). Each is a one-line change; batch as one hygiene PR.
- Proposed test: `test_log_read_entry_null_entry_no_leak` (under the `sanitizers` job), `test_strerror_negative_errno`.
- Confidence: high (all observed), low severity.

## Suspected but NOT reproduced (so nobody re-does them)
- `normalizing_index_offset %= counts_len` with negative values → in range, no OOB (see Verified OK).
- V0 `counts_array_len = counts_len * word_size` int32 overflow: max `counts_len` (sig figs 5, INT64_MAX) ≈ 6.3 M × 8 =
  50 MB, fits. Resource cost of a ~100-byte frame is ≤ ~100 MB (Java has the same shape) — info only.
- `read_ahead_timestamp` digit-run overflow — fixed by #153 (merged), still clean under the fuzzers.
- `hdr_base64_encode_block_pad` with `remaining == 0` forms a one-past-end pointer but never dereferences it — legal.
- CRLF logs, `Tag=` with empty value, `INT64_MAX` values / `total_count` — all round-trip correctly.

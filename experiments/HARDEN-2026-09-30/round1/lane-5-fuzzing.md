# Lane 5 — Fuzzing & sanitizer coverage of the whole library

All paths below are under `$SP=/tmp/claude-1000/-home-fco-redislabs-hdr-agent-workspace/c823fcbe-3fa5-4420-8c28-c287298e2ca3/scratchpad`;
lane work dir = `$SP/lane-5` (copies `main/` = upstream/main 26587de, `combined/` = main + #144 #156 #141 #139 #150).
Machine: x86-64, 14 cores, Linux; clang 18.1.3, gcc 13, zlib static; OpenJDK 1.8 + HdrHistogram-2.2.2.jar (Java reference oracle).

Scope probed:
- Built the 3 existing `.clusterfuzzlite/` targets on MAIN and the 4 on COMBINED (#150 adds `hdr_packed_fuzzer.c` + one line in `build.sh`) exactly per `build.sh` conventions (`$CC $CFLAGS $LIB_FUZZING_ENGINE <fuzzer>.c -I include libhdr_histogram_static.a -l:libz.a`), library and fuzzers with `clang -O1 -g -fsanitize=fuzzer(-no-link),address,undefined,float-cast-overflow -fno-sanitize-recover=all` — `$SP/lane-5/build-fuzz.sh`, binaries in `$SP/lane-5/out-main/`, `$SP/lane-5/out-combined/`.
- Ran all 7 for 360 s each (`$SP/lane-5/run-existing.sh`; `-timeout=25 -rss_limit_mb=2560 -print_final_stats=1`), seeds: `test/*.hlog` + `test/test_*.txt` for `log_reader_fuzzer`; the 307 base64 histogram fields extracted from the `.hlog` files (`$SP/lane-5/seeds/decode`) for `hdr_decode_fuzzer`; the same base64-decoded to raw compressed blobs (`seeds/packed`) for `hdr_packed_fuzzer`; random for `hdr_record_fuzzer`. Logs: `$SP/lane-5/logs/*.log`; crashes: `$SP/lane-5/artifacts/`.
- Wrote and ran two new libFuzzer targets (project style, `build.sh`-compatible, public-domain header like the existing ones):
  - `$SP/lane-5/fuzzers/hdr_roundtrip_fuzzer.c` — decode→encode→decode→encode round trip: logical content (total, min, max, every `hdr_count_at_index`, p50) must survive and the 2nd encode must be byte-identical; hostile modes feed raw bytes to `hdr_decode_compressed` either as-is or (mode bit 3) wrapped as an **uncompressed V2 payload** (fuzzer zlib-compresses + prepends the V2 compression cookie) so the mutator works on the encoding flyweight and zig-zag counts instead of fighting zlib; synthetic mode builds histograms with fuzz-chosen config, a rotated store (`normalizing_index_offset != 0`, `-DHDR_FUZZ_OFFSET`) and negative counts (`-DHDR_FUZZ_NEGATIVE`).
  - `$SP/lane-5/fuzzers/hdr_oracle_fuzzer.c` — structure-aware differential fuzzer: op stream (record_value / record_values / both `_atomic` twins / record_corrected_values / record into a 2nd histogram + `hdr_add` / `hdr_reset` / out-of-range rejects) replayed into a dense histogram and into a naive (value,count) oracle; asserts total_count, `hdr_min`, `hdr_max`, `hdr_value_at_percentile` for 0/50/99.9/100/random (exact, at bucket equivalence, same rounding as the library), `hdr_value_at_percentiles` == singular, `hdr_count_at_value`, `hdr_mean` (1e-9 rel), recorded-iterator ascending/sum/step bound, percentile- and linear-iterator termination budgets. `-DHDR_FUZZ_P0` re-enables the p=0 plural check (finding L5-F3).
  - MAIN long runs: `hdr_roundtrip_fuzzer` 720 s (lib built with `-fsanitize-recover=float-cast-overflow,signed-integer-overflow` so tracked UB does not stop the run; every UB site is grepped afterwards): **927,730 execs, 1,286 exec/s, cov 259 / ft 737, 0 round-trip mismatches, 2 UB sites (L5-F1 new; #118)**. `hdr_oracle_fuzzer` 720 s strict: **59,187 execs, 82 exec/s, cov 239 / ft 1376, 0 mismatches, 0 UB, 0 ASan** (plus a first 12-min attempt that stopped after ~2 min on an oracle modelling error of `hdr_add`, fixed and kept as `artifacts/new-oracle/false-positive-hdr_add-max-model`). Same two on COMBINED: roundtrip hit L5-F1 (strict build aborts, 6,257 execs), oracle **64,712 execs, 89 exec/s, cov 246 / ft 1467, 0 mismatches, 0 UB, 0 ASan**.
- Mapped every function in `include/hdr/*.h` to fuzzer / unit-test coverage (script over the fuzzers and `test/*.c`; table below).
- Cross-checked semantics against the Java reference by running HdrHistogram-2.2.2 (`$SP/lane-5/java/Shifted.java`, `Dec.java`, `Pct.java`).
- Prototyped and validated fixes for L5-F1/F2/F3/F8 in `$SP/lane-5/main` (`$SP/lane-5/proposed-fixes.patch`, 96 lines): ctest 5/5 under ASan+UBSan+float-cast-overflow; Java-interop and rotated-encode probes now match Java exactly; offset round-trip variant 104,520 execs / 90 s with 0 mismatches; `-DHDR_FUZZ_P0` oracle 4,635 execs / 60 s clean.
- Reviewed `.github/workflows/ci.yml` (`sanitizers` job), `cflite_pr.yml`, `cflite_batch.yml`, ClusterFuzzLite docs (storage repo / artifacts), and measured what the CI sanitizer flags actually detect.

Verified OK:
- `hdr_decode_fuzzer`: MAIN 43,372,682 execs (120k/s, cov 186/ft 624) and COMBINED 40,243,270 execs (cov 192/ft 635) — no crash, no leak, no UB. But see L5-F5(a): this harness never gets past the zlib layer, so "clean" means little for the inner decoder.
- `hdr_record_fuzzer`: MAIN 9,210 execs, COMBINED 5,432 execs — clean (cov 333). Throughput is the problem (L5-F5(b)).
- `hdr_packed_fuzzer` (COMBINED only, #150): 262,386 execs, 726/s, cov 308/ft 1197 — clean, incl. packed-vs-dense percentile parity and V2 byte-identity.
- `log_reader_fuzzer` COMBINED: 3,115,273 execs, 8,629/s, cov 314/ft 945 — clean; the three MAIN crashers replay clean on COMBINED (#154/#156 fix confirmed). MAIN with the tracked `hdr_time.c` UB made recoverable: 1,090,732 execs, cov 368/ft 1045, no ASan/LSan finding, no UB outside `hdr_time.c:92/93/96`.
- New oracle fuzzer: no discrepancy between `hdr_record_value`, `hdr_record_values`, their `_atomic` twins, `hdr_record_corrected_values`, `hdr_add`, `hdr_reset` and a naive oracle for min/max/percentiles/count_at_value/mean on MAIN and COMBINED (p>0). Plural `hdr_value_at_percentiles` == singular for every p>0 (incl. #140/#141 rewrite on COMBINED). Recorded/percentile/linear/log iterators terminate within budget (#149 merged fix holds). Out-of-range and negative values are rejected without touching state.
- New round-trip fuzzer: V0/V1/V2 decode→encode→decode is logically lossless and the second encode byte-identical for offset==0, non-negative-count histograms (927k execs). The C encoder's byte stream is accepted by Java (`Dec.java`) both before and after the proposed patch.
- Suspected but NOT reproduced: leaks in the codec paths (LSan on, 0 reports across ~50M execs); OOB in `apply_to_counts_zz` zero-run handling (bounds check holds; only the negation UB in L5-F1); `hdr_value_at_percentile` vs oracle for offset==0 dense histograms (0 mismatches); regressions in the 5 merged-tonight PRs on the fuzzed paths (COMBINED runs clean except the pre-existing L5-F1/#118 sites).

## Public API surface → coverage (MAIN 26587de)

Legend: **fuzz** = called directly by an existing `.clusterfuzzlite/` target (D=hdr_decode, R=hdr_record, L=log_reader, P=hdr_packed (#150 only)); **new** = covered by the two new fuzzers (RT=roundtrip, O=oracle); **unit** = occurrences in `test/*.c`; *indirect* = reached only through another API.

| Header / function | Fuzzed by | New fuzzers | Unit | Notes |
|---|---|---|---|---|
| hdr_init / hdr_close | R,D,L | RT,O | 49/75 | |
| hdr_alloc | — | — | 10 | unit-tested only |
| hdr_reset | — | O | 5 | unit-tested only before this lane |
| hdr_get_memory_size | L | — | 2 | |
| hdr_record_value | R | O | 47 | |
| hdr_record_value_atomic | — | O | 17 | atomic twin was never fuzzed |
| hdr_record_values | R | O | 7 | |
| hdr_record_values_atomic | — | O | **0** | **neither** before this lane |
| hdr_record_corrected_value | R | — | 8 | |
| hdr_record_corrected_value_atomic | — | — | 4 | unit only |
| hdr_record_corrected_values | — (indirect via hdr_add_while_correcting) | O | **0** | **neither** before this lane |
| hdr_record_corrected_values_atomic | — | — | **0** | **neither** |
| hdr_add | R | O | 4 | |
| hdr_add_while_correcting_for_coordinated_omission | — | — | **0** | **neither** |
| hdr_min / hdr_max | R,L | O | 12/17 | |
| hdr_value_at_percentile | D,R,L | RT,O | 54 | |
| hdr_value_at_percentiles | — | O | 2 | **not fuzzed** before; L5-F3 found by O |
| hdr_mean / hdr_stddev | R,L | O | 9/1 | |
| hdr_values_are_equivalent | — | O | 12 | |
| hdr_lowest_equivalent_value | — | O | 5 | |
| hdr_count_at_value | R | O | 7 | |
| hdr_count_at_index | — | RT,O | 4 | |
| hdr_value_at_index | R | — | 2 | |
| hdr_iter_init / hdr_iter_next | (indirect) / R | O | 7/36 | |
| hdr_iter_percentile_init | R | O | **0** | fuzz only (no unit test) |
| hdr_iter_recorded_init | R | O | 5 | |
| hdr_iter_linear_init | R | O | 11 | |
| hdr_iter_log_init | — | — | 15 | unit only (#149 area) |
| hdr_percentiles_print | L | — | **0** | fuzz only |
| hdr_calculate_bucket_config | indirect (hdr_init) | indirect | 1 | |
| hdr_init_preallocated | — | — | **0** | **neither** |
| hdr_size_of_equivalent_value_range | — | — | **0** | **neither** |
| hdr_next_non_equivalent_value | — | O | 3 | |
| hdr_median_equivalent_value | — | O | **0** | **neither** before this lane |
| hdr_reset_internal_counters | indirect (decode) | RT | 1 | #118 site |
| hdr_log_encode / hdr_log_decode | R / D,R | (RT uses hdr_encode/decode_compressed) | 3/5 | |
| hdr_log_writer_init / write_header / write / write_entry | — | — | 2 each | **writer side never fuzzed** |
| hdr_log_reader_init / read_header / read | L | — | 8/7/10 | |
| hdr_log_read_entry | indirect (hdr_log_read) | — | 3 | |
| hdr_strerror | — | — | 1 | |
| hdr_interval_recorder_init | — | — | **0** | **neither** |
| hdr_interval_recorder_init_all / destroy / record_value / sample | R | — | 5/5/2/4 | |
| hdr_interval_recorder_record_values / _corrected_values / *_atomic (5 fns) | — | — | 0–1 | **neither** (record_corrected_value / record_value_atomic / record_corrected_value_atomic have 1 unit call each) |
| hdr_interval_recorder_sample_and_recycle | — | — | 3 | unit only |
| hdr_thread.h (hdr_mutex_*, hdr_yield, hdr_usleep — 8 fns) | indirect (phaser via interval recorder) | — | **0** | **neither** directly |
| hdr_time.h: hdr_gettime | — | — | 6 | |
| hdr_time.h: hdr_getnow / hdr_timespec_as_double / hdr_timespec_from_double | indirect (L via log header parse) | — | **0** | `hdr_timespec_from_double` is the #154/#156 UB site and has **no unit test on main** |
| hdr_writer_reader_phaser.h (7 fns) | indirect (R via interval recorder) | — | **0** | **neither** directly; the concurrency test covers only the atomic record path |
| hdr_packed_histogram.h (#150, COMBINED): init/record/query/encode/decode | P | — | 23 parity tests | config_create/destroy/memory_size, init_shared, populated, count_width: unit only |

## Findings (ranked, most severe first)

### L5-F1: `apply_to_counts_zz` negates INT64_MIN on attacker-controlled V2 payload (UB)
- Severity: medium     Class: security
- Where: `src/hdr_histogram_log.c:310` (`int64_t zeros = -value;` evaluated before the `value <= INT32_MIN` range check) @ main 26587de; identical on COMBINED.
- Tracked: untracked (#146 fixed the heap overflows in this decoder, not this; not in #150/#154/#156).
- Repro (60-char log field; a 9-byte zig-zag varint `ff ff ff ff ff ff ff ff ff` = INT64_MIN as the first count):
  ```
  HISTFAAAACN4nJNpmSzMwMDAyQABzFCaEURcm7yEwf4DROA/DAAAp+YNhw==
  ```
  `$SP/lane-5/probes/decode_b64_main "<that>"` (main asan lib) → `src/hdr_histogram_log.c:310:29: runtime error: negation of -9223372036854775808 cannot be represented in type 'int64_t'`; same on COMBINED. Found by `hdr_roundtrip_fuzzer` uncompressed-payload mode after 6,257 execs on COMBINED (`$SP/lane-5/artifacts/REPRO-apply_to_counts_zz-INT64_MIN-negation`, 12-min MAIN run logged the same site). The existing `hdr_decode_fuzzer` did not reach it in 83M combined execs (zlib barrier, see L5-F5).
- Impact: UB in the untrusted-input decoder; with today's compilers it wraps back to INT64_MIN and the following `value <= INT32_MIN` check rejects the payload, so no memory corruption was observed — but it is a guaranteed UBSan abort (any -fno-sanitize-recover build, and the weekly UBSan batch will flag it once the corpus reaches it) and the optimizer is entitled to drop the check.
- Proposed fix (validated: ctest 5/5, repro now returns `HDR_TRAILING_ZEROS_INVALID`):
  ```c
          if (value < 0)
          {
              int64_t zeros;
              /* range-check before negating: -INT64_MIN is UB */
              if (value <= INT32_MIN)
              {
                  return HDR_TRAILING_ZEROS_INVALID;
              }
              zeros = -value;
              if (counts_index + zeros > h->counts_len)
              {
                  return HDR_TRAILING_ZEROS_INVALID;
              }
  ```
- Proposed test: `test/hdr_histogram_log_test.c`, new `decode_rejects_int64_min_zero_run`: `hdr_log_decode` of the string above returns `HDR_TRAILING_ZEROS_INVALID` and `*histogram == NULL` (runs under the `sanitizers` CI job).
- Confidence: high (deterministic, both trees, fix verified under UBSan).

### L5-F2: V1/V2 codec is not offset-aware: Java logs with `normalizingIndexOffset != 0` decode to wrong values; C re-encode of a rotated histogram drops counts
- Severity: high     Class: correctness
- Where: decoder `src/hdr_histogram_log.c:321` (`h->counts[counts_index] = value;` physical index) + `:556`/`:680` (adopts the payload offset afterwards); `apply_to_counts_16/32/64` `:271-297` (same, V0/V1); encoder `:200`, `:207` (`h->counts[i]` physical) with `counts_limit` derived from the *logical* max index, `:226` (writes the in-memory offset). Identical on COMBINED. Merged #155 made `hdr_reset_internal_counters` offset-aware but kept the codec's physical-index convention.
- Tracked: untracked.
- Repro 1 (Java → C, `$SP/lane-5/java/Shifted.java`: Java `Histogram(1, 3600000000, 3)`, record 7..700000 step 7, `shiftValuesLeft(4)`, `encodeIntoCompressedByteBuffer`):
  ```
  JAVA truth : total=100000 min=112  max=11206655  p50=5603327  p99=11091967  offset=4096
  C main     : total=100000 min=9088 max=179306495 p50=89653247 p99=177471487 offset=4096   ($SP/lane-5/probes/decode_b64_main)
  C combined : identical to main
  ```
  Java's payload stores `getCountAtIndex(i)` (logical order) and Java's decoder writes `setCountAtIndex(i)` (logical); C writes the payload into `counts[i]` (physical) and then applies the offset a second time → every value shifted by `offset` indices (16x here). Fixture strings: `$SP/lane-5/java/shifted1.txt` (201 chars, offset 1024, truth total=100000 min=14 max=1400831 p50=700415 p99=1386495) and `shifted4.txt`.
- Repro 2 (C only, `$SP/lane-5/probes/encode_offset.c`): build a histogram, rotate its store to offset -1000 preserving the logical view (exactly what the unit tests at `test/hdr_histogram_test.c:198,358` do), `hdr_log_encode` → `hdr_log_decode`:
  ```
  rotated (same logical) total=100000 min=7 max=700415 p50=350207 p99=693247 offset=-1000
  encode->decode         total=50907  min=7 max=356351 p50=178303 p99=353023 offset=-1000   (offset +1000: total 99858, min 1001)
  ```
  `hdr_roundtrip_fuzzer -DHDR_FUZZ_OFFSET` trips on its 3rd input (`total_count 236223201280 vs 0 (offset=-170)`, `$SP/lane-5/artifacts/rt-offset/`).
- Impact: any log written by Java/other ports after `shiftValuesLeft/Right` (unit re-scaling is the documented use) is silently misread by C consumers (all values scaled by 2^k·…); C-side encode of a decoded rotated histogram silently loses ~half the samples. Both are silent data corruption, not crashes.
- Proposed fix (validated: Java-interop probe now matches Java exactly incl. mean; rotated encode lossless; 104,520 offset round-trips / 90 s, 0 mismatches; ctest 5/5; Java `Dec.java` decodes patched C output correctly). Payload order is logical, so store it unrotated and read it logically:
  ```c
  /* hdr_encode_compressed */
  -        int64_t value = h->counts[i];
  +        /* logical index: payload counts are unrotated (Java getCountAtIndex) */
  +        int64_t value = hdr_count_at_index(h, i);
  ...
  -            while (i < counts_limit && 0 == h->counts[i])
  +            while (i < counts_limit && 0 == hdr_count_at_index(h, i))
  ...
  -    encoded->normalizing_index_offset = htobe32(h->normalizing_index_offset);
  +    encoded->normalizing_index_offset = 0;   /* counts above are logical; no rotation to convey */

  /* hdr_decode_compressed_v1 and _v2: drop the 6-line offset adoption (`h->normalizing_index_offset = be32toh(...)` + `%= counts_len`) */
  +    /* payload counts are logical (unrotated); the encoded offset is a storage detail, keep 0 */
  ```
  Alternative if the maintainer wants to keep the decoded offset: set it *before* `apply_to_counts` and write through a normalised setter — more code for no semantic gain (C has no shift API; the offset-aware read paths stay for hand-rotated histograms).
- Proposed test: `test/hdr_histogram_log_test.c`: (a) `decode_java_shifted_log` — decode the `shifted1.txt` base64, assert total/min/max/p50/p99 equal the Java truth above; (b) `encode_rotated_histogram_round_trips` — rotate a histogram's store as in `hdr_histogram_test.c:198`, encode/decode, assert `hdr_count_at_index` equality for all indices and byte-identical re-encode. Add `shifted1` as `test/regression-java-shifted-offset.hlog` line for the reader test too.
- Confidence: high (Java reference reproduced end-to-end; fix verified against Java both directions).

### L5-F3: `hdr_value_at_percentiles` (plural) disagrees with `hdr_value_at_percentile` and Java at p = 0
- Severity: medium     Class: correctness
- Where: `src/hdr_histogram.c:891` (`values[at_pos] = highest_equivalent_value(h, iter.value);`) @ main; COMBINED (#140/#141 rewrite) has the same behaviour.
- Tracked: partially covered by #140/#141 — they rewrite this function but keep the p==0 behaviour; not raised in the 2026-09-29 round.
- Repro: `hdr_oracle_fuzzer` reproducer `$SP/lane-5/artifacts/new-oracle/REPRO-plural-p0-mismatch` (sig=1, lowest=251, one value recorded): `plural/singular mismatch p=0.000000 plural=127 single=0 total=1`; identical on COMBINED (`$SP/lane-5/out-new-combined/hdr_oracle_fuzzer`). Java `getValueAtPercentile(0)` returns `lowestEquivalentValue` (AbstractHistogram.java:1448), as does the C singular.
- Impact: callers batching percentiles that include 0 (the common `{0, 50, 90, 99, 100}` set) get the top of the bucket instead of the bottom for p0 — off by a full bucket width, inconsistent with the scalar API.
- Proposed fix (validated: `-DHDR_FUZZ_P0` oracle run clean 4,635 execs; ctest 5/5):
  ```c
  -            values[at_pos] = highest_equivalent_value(h, iter.value);
  +            /* match hdr_value_at_percentile: p == 0 reports the lowest equivalent value */
  +            values[at_pos] = percentiles[at_pos] == 0.0
  +                ? lowest_equivalent_value(h, iter.value)
  +                : highest_equivalent_value(h, iter.value);
  ```
  #140/#141 need the same one-liner in their scan.
- Proposed test: `test/hdr_histogram_test.c`, extend the existing plural test: for `{0, 50, 100}` assert `values[i] == hdr_value_at_percentile(h, p[i])` on a histogram whose min lies mid-bucket (e.g. `hdr_init(251, 502, 1)`, record 100).
- Confidence: high.

### L5-F4: the per-PR `sanitizers` CI job cannot detect the #154/#156 bug class (no float-cast-overflow, gcc)
- Severity: medium     Class: coverage
- Where: `.github/workflows/ci.yml:89` — `-DCMAKE_C_FLAGS="-fsanitize=address,undefined -fno-sanitize-recover=all -g"`, default compiler on ubuntu-latest = gcc.
- Tracked: untracked (the job itself came from #145).
- Repro: `$SP/lane-5/probes/fco.c` (`(int)2883624558.474`): `gcc -fsanitize=address,undefined -fno-sanitize-recover=all` → prints `-2147483648`, no report; `gcc ... ,float-cast-overflow` → `runtime error: 2.88362e+09 is outside the range of representable values of type 'int'`; `clang -fsanitize=undefined` catches it by default. Consistent with `log_reader_fuzzer` hitting `hdr_time.c:92` after 1,013 execs while the `sanitizers` job on main has been green.
- Impact: the job was added as "the per-PR gate for this whole bug class", but the class that has failed the weekly UBSan batch repeatedly is invisible to it; only the Monday cflite batch (UBSan) sees it, days after merge.
- Proposed fix: `-fsanitize=address,undefined,float-cast-overflow -fno-sanitize-recover=all -g` (gcc supports it) and/or add a clang leg; optionally also `-DHDR_LOG_REQUIRED=DISABLED` build-only leg under sanitizers (currently only zlib-ON is sanitized; DISABLED swaps in `hdr_histogram_log_no_op.c`, low risk).
- Proposed test: none (CI change); the regression fixture `test/regression-log-timestamp-overflow.hlog` already exists and would then fail the job on an unfixed tree.
- Confidence: high (measured).

### L5-F5: fuzzing infrastructure gaps — zlib barrier, 15–28 exec/s record target, no persistence/continuous-build, UBSan only weekly
- Severity: medium     Class: coverage
- Where: `.clusterfuzzlite/hdr_decode_fuzzer.c`, `hdr_record_fuzzer.c`, `build.sh:22` (seed zip only for log_reader, `*.hlog` only), `.github/workflows/cflite_pr.yml` (`pull_request` only, `sanitizer: [address]`, `fuzz-seconds: 200`, `bad-build-check: false`), `cflite_batch.yml` (weekly, address+undefined, no `storage-repo`), no `cflite_build.yml` / `cflite_cron.yml`.
- Tracked: untracked (#111 asked for the log-reader fuzzer, done).
- Measured:
  (a) `hdr_decode_fuzzer`: 43.4M (MAIN) + 40.2M (COMBINED) execs, coverage plateaued at 186–192 edges; it never produced a payload reaching `apply_to_counts_zz`'s INT64_MIN path because every mutation must survive `inflate()`. The new harness's uncompressed-payload mode found L5-F1 in 6,257 execs and re-found #118 (`hdr_histogram.c:345`) from hostile input in <12 min.
  (b) `hdr_record_fuzzer`: 25 exec/s (MAIN) / 15 exec/s (COMBINED) under ASan+UBSan (it `hdr_init`s up to 2^30 range × 3 sig figs plus an interval recorder per input) → the 200 s PR budget is ~4,000 executions; batch hour ≈ 90k. `hdr_packed_fuzzer` runs at 726/s, decode at 110k/s.
  (c) Seeds: `test_*.txt` regression inputs (tagged/overflow cases) are not in the seed zip; decode/record/packed targets have no seed corpus at all — the extracted 307 histogram fields (`$SP/lane-5/seeds/decode`) are a ready-made one.
  (d) Persistence: ClusterFuzzLite docs — "If a storage repo isn't specified, corpora and coverage reports will be uploaded as GitHub artifacts instead" (retention-limited) and "If batch fuzzing is running, you must also run corpus pruning" (no cron workflow). No `cflite_build.yml` → PR fuzzing cannot classify a crash as pre-existing, so main's `hdr_time.c` UB would surface as a new crash on every PR under UBSan — one reason the PR job runs address-only, which in turn means **UB regressions only fail on Monday** (the memory notes 8 consecutive weekly failures for one bug).
  (e) `cflite_pr.yml` runs on `pull_request` only, never on push to main; `ci.yml` runs on push but has no fuzz step.
- Impact: two of three fuzz targets give near-zero marginal coverage per PR; UB findings reach main; regressions in the writer, interval-recorder, phaser, `hdr_value_at_percentiles`, `hdr_reset`, `_atomic` record twins and negative/rotated-state codec paths are not fuzzed at all (see table).
- Proposed fix: add `hdr_roundtrip_fuzzer.c` and `hdr_oracle_fuzzer.c` to `.clusterfuzzlite/` + `build.sh` loop (they build with the existing line; roundtrip needs `-lz` which `-l:libz.a` already provides); zip seeds for decode/roundtrip (`test/*.hlog` fields) and add `test/test_*.txt` to the log_reader zip; cap `hdr_record_fuzzer`'s `MAX_HIGHEST` to 2^24 or reuse one static histogram per config; add `undefined` to the PR matrix once L5-F1/#154 are merged, plus `cflite_build.yml` (continuous builds) and `cflite_cron.yml` (prune) or a `storage-repo`; consider `fuzz-seconds: 300` with `parallel-fuzzing: true`.
- Proposed test: n/a (infra). The two new targets are the regression tests for F1–F3 in fuzz form.
- Confidence: high for the measurements; medium for the ClusterFuzzLite retention semantics (from docs, not observed).

### L5-F6: encoding a histogram with negative counts silently emits them as zero-run markers (Java throws)
- Severity: low     Class: correctness
- Where: `src/hdr_histogram_log.c:200-216` (any `value < 0` reaches `zig_zag_encode_i64(..., value)`, which the decoder reads as `-value` zeros) @ main; same on COMBINED.
- Tracked: untracked upstream (the 2026-09-29 round noted on #141 that "the nonnegative-count assumption is not enforced by the recording API"; no issue/PR covers the codec side).
- Repro: `hdr_roundtrip_fuzzer -DHDR_FUZZ_NEGATIVE` (`$SP/lane-5/artifacts/rt-negative/`): `roundtrip mismatch: count at logical index 13312: -229376 vs 0 (offset=0)` — the negative count is decoded as 229,376 skipped buckets (or `HDR_TRAILING_ZEROS_INVALID` when the run overruns). `hdr_record_values(h, v, -n)` is accepted by the API, so this state is reachable.
- Impact: silent corruption of logs written from a histogram that ever received a negative count (or a decoded V0/V1 payload with negative words). Java's `fillBufferFromCountsArray` throws "Cannot encode histogram containing negative counts".
- Proposed fix (included in `$SP/lane-5/proposed-fixes.patch`): in `hdr_encode_compressed`, `if (value < 0) { /* a negative count would decode as a zero run */ FAIL_AND_CLEANUP(cleanup, result, EINVAL); }`. Note it only sees counts up to the max index (as Java); negatives above max are dropped — acceptable, matches Java.
- Proposed test: `test/hdr_histogram_log_test.c`: record value with count -1 (or poke `h->counts[i] = -1` below max), assert `hdr_log_encode` returns `EINVAL`.
- Confidence: high for the behaviour; medium on desired semantics (maintainer may prefer rejecting negative counts at `hdr_record_values`, which #141's discussion leans toward).

### L5-F7: C percentile rounding diverges from the Java reference (round-half-up vs ceil)
- Severity: low     Class: correctness
- Where: `src/hdr_histogram.c:851-852` (`(int64_t)(((requested_percentile / 100) * h->total_count) + 0.5)`), also `:875` plural; Java `AbstractHistogram.java:1435-1440` uses `nextAfter(p, -inf)` then `ceil`.
- Tracked: untracked (long-standing; not in #140/#141 which keep the C formula).
- Repro: `$SP/lane-5/java/Pct.java` vs `$SP/lane-5/probes/pct.c`, values 1..21 recorded once each:
  ```
  java T=21 p10=3 p30=7 p66=14
  C    T=21 p10=2 p30=6 p66=14
  ```
- Impact: same log, different percentile values between the C and Java toolchains for any p·T/100 with fractional part < 0.5 (Java returns the value at the ceil-th sample, C at the round-th). Not a memory-safety issue; possibly intentional historical divergence, so flagged for the maintainer rather than as a defect.
- Proposed fix (only if alignment is wanted; changes outputs): `int64_t count_at_percentile = (int64_t) ceil(nextafter(requested_percentile, -INFINITY) * h->total_count / 100.0);` in both singular and plural (and #140/#141).
- Proposed test: `test/hdr_histogram_test.c`: 21 samples 1..21, assert `hdr_value_at_percentile(h, 10) == 3` (Java truth) — only together with the change.
- Confidence: high on the divergence, low on whether upstream considers it a bug.

### L5-F8: #118 (`hdr_reset_internal_counters` int64 overflow) is reachable from untrusted log input
- Severity: info     Class: correctness
- Where: `src/hdr_histogram.c:345` (`observed_total_count += count_at_index;`) via `hdr_decode_compressed_v2 → apply_to_counts_zz → hdr_reset_internal_counters`.
- Tracked: tracks issue #118 (already known for the record path; this notes the decode path).
- Repro: `hdr_roundtrip_fuzzer` uncompressed-payload mode, `$SP/lane-5/logs/new-roundtrip-main.log`: `src/hdr_histogram.c:345:34: runtime error: signed integer overflow` from a V2 payload with two zig-zag counts summing past INT64_MAX (also first hit in a synthetic input at `$SP/lane-5/artifacts/new-roundtrip/REPRO-issue118-reset_internal_counters-overflow`, pre-cap build).
- Impact: a crafted log makes `total_count` wrap (negative total → `hdr_value_at_percentile` target ≤ 0 → clamps to 1; `hdr_mean` divides by a wrapped total). UBSan abort under the batch UBSan job once reached.
- Proposed fix: accumulate in `uint64_t` and reject (or saturate) when `> INT64_MAX` in `hdr_reset_internal_counters`, and have the V0/V1/V2 decoders return `EINVAL` when the sum overflows — per #118.
- Proposed test: `hdr_histogram_log_test.c`: V2 payload with counts `INT64_MAX` and `1` → decode returns an error, no UB.
- Confidence: high (reproduced on main).

### Also reproduced (tracked, for the record)
- `hdr_time.c:92/93/96` `hdr_timespec_from_double` float-cast / signed overflow from a log header `#[StartTime: 2883624558.474 …]` — `log_reader_fuzzer` MAIN after 1,013 execs (`$SP/lane-5/artifacts/main-log_reader_fuzzer/crash-3a7678cf…`, and `mainrec-…/crash-e35c3ac9…` for the `* 1000000` overflow). **Covered by #154/#156**; COMBINED replays clean and ran 3.1M execs without it.

## CI / workflow answers (task 4)
- **Does the `sanitizers` job run with logging disabled?** No — only `HDR_LOG_REQUIRED=ON`, gcc, `-fsanitize=address,undefined` (no float-cast-overflow → L5-F4). `DISABLED` is covered only by the plain matrix (linux legs; windows/macos exclude it).
- **Does cflite run on push to main?** No. `cflite_pr.yml`: `pull_request` to main + manual, address only, 200 s, `bad-build-check: false`, `report-unreproducible-crashes: false`. `cflite_batch.yml`: Mondays 03:00 UTC + manual, address and undefined, 3600 s per sanitizer. Nothing fuzzes a direct push to main until the next Monday.
- **Corpus persistence:** no `storage-repo` configured → corpora/coverage go to GitHub Actions artifacts (retention-limited); no `cflite_cron.yml` pruning or coverage report; no `cflite_build.yml` so PR runs cannot distinguish pre-existing crashes. Seeds: only `log_reader_fuzzer_seed_corpus.zip` (`test/*.hlog`, so the two `regression-*.hlog` are included but `test/test_*.txt` are not).
- **Would a regression be caught per area?** Log header/timestamp parsing: yes by batch UBSan (weekly), no by PR job (ASan only) nor by `sanitizers` (L5-F4). Inner V0/V1/V2 counts decoding: effectively no (zlib barrier, L5-F5a) until the raw-payload harness is added. Record/query paths: only ~4k execs per PR (L5-F5b); `hdr_value_at_percentiles`, `_atomic` twins, `hdr_reset`, writer API, interval-recorder/phaser: not fuzzed at all. Packed (#150): its fuzzer is wired into `build.sh` and would run on merge.

## Artifacts
- New fuzzers: `$SP/lane-5/fuzzers/hdr_roundtrip_fuzzer.c`, `$SP/lane-5/fuzzers/hdr_oracle_fuzzer.c` (build: `clang $CFLAGS $LIB_FUZZING_ENGINE <f>.c -I include libhdr_histogram_static.a -l:libz.a -lm`; variants `-DHDR_FUZZ_OFFSET`, `-DHDR_FUZZ_NEGATIVE`, `-DHDR_FUZZ_P0` re-enable the checks gated on L5-F2/F6/F3).
- Reproducers: `$SP/lane-5/artifacts/REPRO-int64min-negation.b64` (L5-F1), `$SP/lane-5/java/shifted{1,4}.txt` (L5-F2, base64 + Java truth), `$SP/lane-5/artifacts/new-oracle/REPRO-plural-p0-mismatch` (L5-F3), `$SP/lane-5/artifacts/rt-offset/`, `rt-negative/`, `main-log_reader_fuzzer/`, `mainrec-log_reader_fuzzer/`.
- Proposed patch (F1+F2+F3+F6, 96 lines, terse comments): `$SP/lane-5/proposed-fixes.patch`; probes in `$SP/lane-5/probes/`; Java oracle programs in `$SP/lane-5/java/`; all fuzzer logs with `-print_final_stats=1` in `$SP/lane-5/logs/`.

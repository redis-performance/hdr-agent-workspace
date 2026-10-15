INTEGRATION CHECK: HdrHistogram_c upstream/main 8885476, patches 173 / 174 / 116

**Verdict:** every tree passes all tests, with clean warnings and a clean ASan+UBSan run. The only conflict is between 173 and 174 in `test/hdr_histogram_test.c`; source and headers apply cleanly in every order, and a trivial rebase fixes the conflict. The fully stacked tree (d) gives the same answer from all 4 APIs on every case, and on non-empty histograms it changes nothing except the batch result at p0.

Location (abbreviated as I below): `I=/private/tmp/claude-501/-Users-oly-redislabs-hdr-agent-workspace/c0a0d17a-306f-4548-a949-c0bb93dc41ec/scratchpad/final/integ`
Each tree is a fresh `git archive upstream/main | tar -x`. The submodule was not touched.

**1. Applying the patches** (`git apply -p1 --check` then `git apply -p1`)
- (a) up+173: clean
- (b) up+174: clean
- (c) up+174+116: clean
- (d) up+173, then 174: CONFLICT in `test/hdr_histogram_test.c` at line 1518 only.
  - Cause: both patches add tests at the same anchor (after `test_percentile_singular_equals_plural_with_offset`), including the `mu_run_test` lines in `all_tests`. `git apply -C1` still fails.
  - With `--3way` (alternate objects taken from the submodule's object store, read-only), diff3 interleaves the two similar helper bodies. The marker hunks cannot just be unioned.
  - The `.h`, `.c` and packed-test hunks of 174 apply cleanly on top of 173.
  - Trivial rebase: add 173's `mu_run_test` line to the context of 174's `all_tests` hunk → `$I/174-on-173.patch`. With that, 174 and then 116 apply cleanly.
- (e) up+174+116, then 173: the same conflict (the `all_tests` hunk), fixed the same way → `$I/173-on-174-116.patch`. It applies cleanly.
- (d) and (e) have byte-identical `src/` and `include/`. The test file differs only in the order of the added test functions.

To land all three, merge 173 or 174 first, then rebase the other (one context line in `all_tests`). 116 applies unchanged on top of 174 in both stacks.

**2. Builds and tests** (`$I/build.sh TREE warn|san`)
- Compile: `cc -std=gnu99 -Wall -Wno-unknown-pragmas -Wextra -Wshadow -Winit-self -Wpedantic -Wmissing-prototypes -D_GNU_SOURCE -DHDR_PACKED_LOG_ENABLED -I include -I src` with the library sources `hdr_encoding hdr_histogram hdr_histogram_log hdr_packed_histogram hdr_interval_recorder hdr_thread hdr_time hdr_writer_reader_phaser`, plus `test/<t>.c test/minunit.c -lz -lm`.
- warn mode adds `-O2 -Werror`. san mode adds `-O1 -g -fsanitize=address,undefined -fno-sanitize-recover=all`.
- Tests are run from `test/`. zlib was available, so the log tests ran.

Results (exit 0 and "ALL TESTS PASSED" in both modes, no warnings anywhere):

| tree | hdr_histogram_test | hdr_packed_histogram_test | hdr_packed_core_test | hdr_histogram_log_test |
|---|---|---|---|---|
| up | 41 | 26 | pass | 34 |
| a | 42 | 26 | pass | 34 |
| b | 43 | 27 | pass | 34 |
| c | 45 | 27 | pass | 34 |
| d | 46 | 27 | pass | 34 |
| e | 46 | 27 | pass | 34 |

`hdr_packed_core_test` prints "packed core available and correct" rather than a test count.

This machine is arm64 (Apple clang 21), so the AVX2 dispatch path was not compiled. The batch API has no AVX2 path. 116's empty early return sits before the singular AVX2 dispatch.

**3. Differential test** (`$I/harness/diff.c`, ASan+UBSan, built once against `up` and once against `d`; analysis in `$I/an.py`)
- Grid: lowest {1, 2, 100, 1000} × sigfigs {1, 3, 5}, highest = max(lowest·1e6, 3.6e9).
- States:
  - fresh
  - reset (record, then reset)
  - recorded 0
  - data (4 values)
  - data+0 (data plus two recorded zeros)
  - rand (2000 seeded records)
  - three offset cases for dense only (rotated copy, offset = counts_len/3+1): offset with data, offset empty, offset with rand
- Percentiles, in this order: {-1, -0.0, 0, 1e-12, 50, 95, 100, 150, NAN}. This order keeps the dense batch targets monotone.
- Compared per row:
  - ds = dense single-percentile call
  - db = dense batch call over the whole array
  - db1 = dense batch call with one percentile
  - ps = packed single-percentile call
  - pp = packed batch call
  - ppr = packed batch call with the array reversed
- Total: 972 rows.

(d), internal consistency: **0 mismatches** out of 972 rows. ds == db == db1 == ps == pp == ppr everywhere. All 324 empty rows (including offset-empty and reset) are 0 for every API and percentile. The recorded-0 case keeps its bucket range (lowest 100: p0 = 0, p50 = 63).

Upstream baseline, for reference: 377 rows mismatch.
- On empty histograms, db/db1 return leftover count targets (1).
- On non-empty histograms, db/db1 at p0 / -0.0 return the top of the bucket instead of the bottom (e.g. lowest 100, sig 3, data: ds = 64, db = 127).

(d) vs upstream on non-empty histograms:
- Every non-p0 row: **504 of 504 identical** across all six fields.
- p0 / -0.0 rows: only db/db1 change (116 rows, now equal to ds/ps). The other 4 of 120 already matched because the bucket width there is 1.
- Upstream's packed results are unchanged on every non-empty row.

Empty histograms, (d) vs upstream: all 324 rows change. Upstream dense/packed singular and packed batch gave `highest_equivalent_value(0)` (e.g. 63 at lowest 100); (d) gives 0.

This includes 116 changing the packed library itself: `hdr_packed_value_at_percentile(s)` now returns 0 when empty, and the comment in `hdr_packed_histogram.h` changes to match. That reverses the empty-histogram behaviour documented for packed upstream, so the 116 PR body should state it.

Intermediate trees, same harness:
- (a): batch p0 is fixed on non-empty histograms; empty is unchanged from upstream (batch returns leftover count targets).
- (b): empty is consistent (all four APIs give `highest_equivalent_value(0)` for p>0, as packed does upstream); the batch-p0 mismatch on non-empty remains (116 rows).
- (c): empty is all 0; the batch-p0 mismatch on non-empty remains.
- (e): output is byte-identical to (d).

In all four, non-p0 rows on non-empty histograms are identical to upstream (504/504).

**Files**
- `$I/174-on-173.patch`: 174 rebased onto upstream+173 (only the `all_tests` hunk context changes)
- `$I/173-on-174-116.patch`: 173 rebased onto upstream+174+116 (same kind of change)
- `$I/build.sh`, `$I/harness/diff.c`, `$I/an.py`, `$I/harness/out-{up,a,b,c,d,e}.txt`
- Trees: `$I/{up,a,b,c,d,e}`. d and e have a scratch `.git` used for the 3-way attempt.

All built binaries, `.dSYM` folders and build output folders have been deleted.
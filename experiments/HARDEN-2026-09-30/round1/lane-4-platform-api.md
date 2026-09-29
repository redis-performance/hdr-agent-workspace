# Lane 4 — Platform layer, public API contract, portability

Scope probed: (x86-64 Linux, 14 cores, gcc 13.3 / clang 18.1, cmake; MAIN = upstream/main `26587de`,
COMBINED = `audit/combined-open-prs` `5a088e3`; working copy `$SP/lane-4/` = copy of MAIN; all probe
sources under `$SP/lane-4/probe/`, builds under `$SP/lane-4/build/{asan,tsan,warn-gcc,warn-clang,inst}`)
- Read every file in scope: `src/hdr_time.c`, `src/hdr_thread.c`, `src/hdr_atomic.h` (it lives in `src/`,
  not `include/`), `include/hdr/{hdr_thread,hdr_time,hdr_interval_recorder,hdr_writer_reader_phaser}.h`,
  `src/hdr_malloc.h`, `src/hdr_interval_recorder.c`, `src/hdr_writer_reader_phaser.c`, the public-API
  entry points of `src/hdr_histogram.c` (init/close/reset/add/percentile/bucket-config/memory-size),
  `CMakeLists.txt`, `src/CMakeLists.txt`, `examples/CMakeLists.txt`, `hdr_histogram.pc.in`,
  `config.cmake.in`, `include/hdr/hdr_histogram_version.h`, `.github/workflows/*.yml` (MAIN and COMBINED).
- Warning sweeps of the library targets: `cmake -DCMAKE_C_FLAGS="-Wall -Wextra -Wconversion -Wshadow
  -Wformat=2 -Wsign-compare -Wcast-qual -Wstrict-prototypes"` with gcc and clang (166 / 118 warnings,
  all `-Wsign-conversion` in the log byteswap macros, `int64_t`->`double` in mean/stddev/percentile math,
  and `-Wformat-nonliteral` on the internal format-table `printf`s — none is a narrowing store).
- 32-bit: `gcc -m32` / `clang -m32` cannot link here (no i386 multilib: `cannot find Scrt1.o`, `-lgcc`)
  and cannot even compile against glibc (`gnu/stubs-32.h` missing). Worked around with an empty
  `fake32/gnu/stubs-32.h` for **compile-only** sweeps of all `src/*.c`, `test/*.c`, `examples/*.c`
  (`-m32 -std=c99 -D_GNU_SOURCE <same -W flags> -Wtype-limits -Wno-sign-conversion`), plus
  `_Static_assert` layout probes (`probe/off32.c`). No MinGW/MSVC headers available, so LLP64 (Windows
  `long`=32-bit) was covered by inspection only; the ILP32 sweep catches the same `int64_t`->`long` class.
- Header hygiene: every `include/hdr/*.h` compiled standalone with `clang++ -x c++ -std=c++11`,
  `g++ -std=c++11`, `gcc/clang -std=c99 -pedantic -Wall -Wextra`, `gcc -std=c89 -pedantic`; plus a C++
  link+run smoke (`probe/cpp_link.cpp`) that calls a symbol from each of the 7 headers, with g++ and clang++.
- Threading: `probe/rec_tsan.c` (4 writers via `hdr_interval_recorder_record_value_atomic`; mode A = 3
  samplers calling `hdr_interval_recorder_sample_and_recycle(r, NULL)` and `hdr_close()`-ing the result;
  mode B = single sampler recycling its own spare + record-count invariant) built against
  `-fsanitize=thread` and `-fsanitize=address,undefined` static libs. `probe/rec_enomem.c`: `setrlimit(RLIMIT_AS)`
  to force `hdr_init` ENOMEM inside `sample_and_recycle`.
- `hdr_timespec_from_double` edge inputs (`probe/ts_edge.c`, 26 inputs incl. NaN, ±inf, ±1e300, -0.0,
  0.9999999999, 0.9995, 2^63, 2^63-1024, -2^63, -2^63-2048, 2^31±0.0005, -0.0005, -0.0015, ±1.5, 5e-4,
  DBL_MIN) against MAIN and COMBINED `build/asan` libs (`-fsanitize=address,undefined,float-cast-overflow`).
- Public-API edge/NULL probes (`probe/api_edge.c`, one process per case) against the lane-4 ASan+UBSan+
  float-cast-overflow build: `hdr_init(..., NULL)`, `hdr_close(NULL)`, `hdr_reset(NULL)`, `hdr_add(h, NULL)`,
  `hdr_calculate_bucket_config(..., NULL)` and 9 bad configs, `hdr_init(1, INT64_MAX, 5)` + `hdr_get_memory_size`,
  `hdr_value_at_percentile(h, {-inf, -1e300, NaN, -5, +inf})`, `hdr_value_at_percentiles` with -inf / empty h /
  NULL h, recorder with NULL active, `hdr_interval_recorder_destroy` after failed `init_all`, `hdr_mean` on empty.
- Symbol export: `nm -D --defined-only libhdr_histogram.so`. Install: `cmake --install` with
  `HDR_HISTOGRAM_INSTALL_SHARED=OFF -DHDR_HISTOGRAM_INSTALL_STATIC=OFF`.
- CI matrix read for gaps (`ci.yml`, `cflite_pr.yml`, `cflite_batch.yml`, and #144's additions in COMBINED).
- Tracking check: `GH_TOKEN= gh pr list / gh issue list` on 2026-09-30 (7 open PRs, 11 open issues).

Verified OK (do not re-do):
- **COMBINED `hdr_timespec_from_double` (#154+#156) is clean on all 26 edge inputs** under ASan+UBSan+
  float-cast-overflow: NaN/±inf/±1e300/2^63/-2^63-2048 -> `{0,0}`; -0.0 -> `{0,0}`; 0.9999999999 and
  0.9995 carry to `{1,0}`; 2^63-1024 -> `tv_sec=9223372036854774784`; -2^63 -> `INT64_MIN` (in range, defined);
  -0.0005 -> `{-1, 999000000}` (= -0.001), -1.5 -> `{-2, 500000000}`; `tv_nsec` always in [0, 999000000].
  MAIN aborts on the first input (`hdr_time.c:92: nan is outside the range of representable values of type
  'int'`) — that is exactly what #154/#156 fix; nothing to add.
- **Phaser + recorder with the documented usage** (atomic writers, one sampler recycling a spare): TSan
  reports no library race in 3 runs; record-count invariant `written == sampled` holds every run
  (e.g. 2953024/2953024, 8393818/8393818). Epoch counters are `int64_t` and only wrap after 2^63 writer
  entries; the C `add_fetch` (new value) vs Java `getAndIncrement` (old value) difference only matters at that
  boundary. No lost wakeups (flip spins with yield/usleep, no condvar). `flip_phase(…, 0)` yields, as Java.
- `hdr_atomic.h` dispatch, by inspection: `__ATOMIC_SEQ_CST` builtins for gcc>=4.7 / clang / icc on every
  arch (this is the path every CI leg exercises); the inline-asm `__x86_64__` block is reached only by an
  x86-64 compiler without `__atomic_*` (pre-4.7 gcc); anything else `#error`s. MSVC path: `_Interlocked*` for
  RMW; `hdr_atomic_load_64/store_64` are plain 64-bit accesses behind compiler-only barriers, i.e. NOT
  single-copy atomic on 32-bit MSVC — but the only readers are the `update_min_max_atomic` CAS loops
  (self-correcting on a torn `expected`) and `flip_phase` (sign bit / equality after all writers have exited),
  so no practical defect; MSVC ARM64 relies on `_Interlocked*` being full barriers, which they are by default.
- On i386 (`-m32` `_Static_assert`): `sizeof(struct hdr_histogram)=92`, `_Alignof=4`, and every `int64_t`
  field the atomic path touches (`min_value` 48, `max_value` 56, `total_count` 80, phaser epochs) is
  8-byte aligned, so `lock cmpxchg8b` never splits a cache line. `time_t` is 4 bytes there (no `_TIME_BITS=64`),
  so COMBINED's `sizeof(tv_sec)`-keyed bound is 2^31 — correct saturation, not a bug.
- `gcc -m32` compile sweep of the library: **zero** `int64_t`->`long`/`int` narrowing warnings; only
  `int64_t`->`double` (mean/stddev/percentile math, benign) and `-Wformat-nonliteral`. `PRIu64` is used for
  every `int64_t` printf in `src/`; no `%ld` with `int64_t`. Test/example sources under `-m32`: only
  `int64_t`->`double` and clang-pragma warnings.
- All 7 public headers compile standalone as C++11 (g++/clang++) and C99 `-pedantic` with zero
  diagnostics; the C++ link+run smoke passes with g++ and clang++ (every header's `extern "C"` guard
  covers all its prototypes). Only C89 nit: `hdr_histogram_version.h:12` uses a `//` comment after `#endif`.
- `hdr_calculate_bucket_config` returns `EINVAL` (never asserts) for lo=0, `(1,1)`, hi<0, sf=0, sf=6,
  `(INT64_MAX/2, INT64_MAX, 5)` (unit_mag 62 > 61 guard); `(1, INT64_MAX, 5)` is accepted with
  `counts_len=6160384`, `hdr_get_memory_size=49283176` — `int32_t * sizeof(int64_t)` cannot overflow `size_t`
  even on ILP32 (max ~49 MB).
- `hdr_close(NULL)` is a no-op; `hdr_interval_recorder_destroy` after a failed `init_all` is safe
  (`hdr_close(NULL)` x2); `sanitizers` CI job runs on both `push` and `pull_request` (`on: [push, pull_request]`
  is workflow-wide).

## Findings (ranked, most severe first)

### L4-F1: `hdr_interval_recorder_sample_and_recycle` reads/derefs `r->active` outside the phaser lock -> heap-use-after-free with concurrent samplers; unchecked `hdr_init` swaps a NULL active in
- Severity: high     Class: security (UAF) / correctness
- Where: `src/hdr_interval_recorder.c:56-62` (and `:68-74`) @ main 26587de (identical in COMBINED)
- Tracked: untracked (no open PR/issue touches `hdr_interval_recorder.c`; the only concurrency test,
  `test/hdr_histogram_atomic_concurrency_test.c`, never references the recorder)
- Repro: `probe/rec_tsan.c` mode A — 4 threads `hdr_interval_recorder_record_value_atomic`, 3 threads loop
  `h = hdr_interval_recorder_sample_and_recycle(&rec, NULL); … hdr_close(h);` (the header documents this
  entry point as "safe when used from callers in multiple threads"). Built against the MAIN sources:
  ```
  ASan (5 runs): 3x  ERROR: AddressSanitizer: heap-use-after-free … hdr_interval_recorder.c:58:33 / :59:33
                     in hdr_interval_recorder_sample_and_recycle
                 1x  hdr_histogram.c:581: runtime error: member access within null pointer   (writer, active==NULL)
                 1x  clean
  TSan: data race hdr_interval_recorder.c:58:33 / :59:33 / :60:46  (read of old_active fields)
        vs  "Write of size 8 by thread T5: #0 free  #1 hdr_close hdr_histogram.c:514  #2 sampler"
        and race :58:25 (plain read of r->active) vs :74:5 (atomic store under mutex M0)
  ```
  The NULL-swap consequence in isolation (`probe/rec_enomem.c`, non-sanitized MAIN lib, single thread):
  ```
  active counts_len=2097152 bytes=16777320
  sample_and_recycle(NULL) returned old=0x60afe2cbd2d0 ; r.active now=(nil)
  Segmentation fault (core dumped)        <- next hdr_interval_recorder_record_value
  ```
  (`setrlimit(RLIMIT_AS, 1 MB)` makes the internal `hdr_init` return ENOMEM; its return value is ignored.)
- Impact: Two samplers racing -> sampler B derefs a histogram sampler A has already freed (read of freed
  memory feeding `lo/hi/sf` to `hdr_init`; garbage config -> `EINVAL` -> `histogram_to_recycle` stays NULL ->
  `r->active = NULL` -> every writer thread crashes). Same NULL-swap happens deterministically on any
  allocation failure, even single-threaded. Java's `Recorder.getIntervalHistogram` does all of this inside
  `synchronized`; the C port moved the allocation out of the lock.
- Proposed fix (verified: after the patch mode A is clean under ASan x5 and TSan x2, mode B invariant still
  holds, ENOMEM probe prints `returned old=(nil) ; r.active now=<unchanged>` and survives, ctest 5/5):
  ```diff
   {
       struct hdr_histogram* old_active;
  +
  +    hdr_phaser_reader_lock(&r->phaser);
  +
  +    /* volatile read */
  +    old_active = hdr_atomic_load_pointer(&r->active);
  
       if (NULL == histogram_to_recycle)
       {
  -        int64_t lo = r->active->lowest_discernible_value;
  -        int64_t hi = r->active->highest_trackable_value;
  -        int significant_figures = r->active->significant_figures;
  -        hdr_init(lo, hi, significant_figures, &histogram_to_recycle);
  +        /* read active only under the lock: another sampler may free it once returned */
  +        int64_t lo = old_active->lowest_discernible_value;
  +        int64_t hi = old_active->highest_trackable_value;
  +        int significant_figures = old_active->significant_figures;
  +        if (0 != hdr_init(lo, hi, significant_figures, &histogram_to_recycle))
  +        {
  +            /* never swap NULL in: writers would dereference it */
  +            hdr_phaser_reader_unlock(&r->phaser);
  +            return NULL;
  +        }
       }
       else
       {
           hdr_reset(histogram_to_recycle);
       }
  
  -    hdr_phaser_reader_lock(&r->phaser);
  -
  -    /* volatile read */
  -    old_active = hdr_atomic_load_pointer(&r->active);
  -
       /* volatile write */
       hdr_atomic_store_pointer(&r->active, histogram_to_recycle);
  ```
  Header: document `@return … NULL if a replacement histogram could not be allocated (recording continues
  into the current one)`. Full patch in `$SP/lane-4/src/hdr_interval_recorder.c` (`git diff` there).
- Proposed test: `test/hdr_histogram_atomic_concurrency_test.c` — add `test_interval_recorder_concurrent_samplers`:
  N writer threads (`_atomic` record), 2-3 sampler threads each doing 1000x `sample_and_recycle(r, NULL)` +
  `hdr_close`, assert no crash and, after joining, `sum(sampled total_count) + final total_count == records`.
  Runs under the existing `sanitizers` CI job (ASan catches the UAF deterministically within a few runs) and
  under a new TSan job (see L4-F6).
- Confidence: high (reproduced under ASan and TSan on MAIN, fix verified against both, ctest green).

### L4-F2: `hdr_value_at_percentiles` returns its intermediate placeholder count (`1`) for an empty histogram; singular API returns 0
- Severity: medium     Class: correctness (API contract)
- Where: `src/hdr_histogram.c:864-896` @ main 26587de; COMBINED `:873-958` (#140/#141 rewrite, same defect)
- Tracked: related to issue #116 (percentile of empty histogram) but that issue is about the singular API;
  the plural API leaking its scratch value is untracked and **not fixed by #140/#141** (reproduced on COMBINED).
- Repro (`probe/api_edge.c pcts_empty_h`, identical on MAIN and COMBINED):
  ```
  pcts on empty -> 0 v=1 ; pct(50) on empty=0
  ```
  i.e. `hdr_value_at_percentiles(empty, {50.0}, v, 1)` returns 0 (success) with `v[0] == 1`, while
  `hdr_value_at_percentile(empty, 50.0)` returns 0. The `1` is `values[i] = max(count_at_percentile, 1)`,
  which the scan loop never overwrites because `total` never reaches 1. Java's `getValueAtPercentile`
  returns 0 after a full scan.
- Impact: callers batching percentiles on an interval that saw no samples get a bogus value of 1
  (looks like a real 1-unit latency); singular vs plural disagree for the same histogram.
- Proposed fix (MAIN and both #140/#141 variants end the same way):
  ```diff
       }
  +    /* nothing reached the target (empty histogram): match hdr_value_at_percentile */
  +    for (; at_pos < length; at_pos++)
  +    {
  +        values[at_pos] = 0;
  +    }
       return 0;
   }
  ```
- Proposed test: `test/hdr_histogram_test.c` — `test_value_at_percentiles_empty`: init, no records, call with
  `{0, 50, 99.9, 100}`, assert all four values are 0 and equal `hdr_value_at_percentile` for each. Also add
  the same case to the #140/#141 `_batch` regression tests so the PRs carry it.
- Confidence: high (reproduced on MAIN and COMBINED; fix is a 4-line tail loop).

### L4-F3: `hdr_value_at_percentile(s)` — `(int64_t)` of `-inf`/huge-negative percentile is UB (float-cast-overflow)
- Severity: low     Class: correctness (UB; benign codegen on x86 today)
- Where: `src/hdr_histogram.c:855` and `:879` @ main 26587de (COMBINED `:864`, `:888`)
- Tracked: untracked (#116/#125 are about empty histograms; #140/#141 keep the same cast)
- Repro (`probe/api_edge.c`, clang `-fsanitize=float-cast-overflow`):
  ```
  pct_neg_inf : hdr_histogram.c:855:9: runtime error: -inf is outside the range of representable values of type 'long'
  pct_neg_big : hdr_histogram.c:855:9: runtime error: -2e+298 is outside the range of representable values of type 'long'
  pcts_neg_inf: hdr_histogram.c:879:9: runtime error: -inf is outside the range of representable values of type 'long'
  pct_nan -> 1000 (=p100), pct_neg(-5) -> 10 (=p0), pct_inf -> 1000 : fine
  ```
  Only the upper bound is clamped (`percentile < 100.0 ? … : 100.0`); `get_value_from_idx_up_to_count`
  clamps the *count* to >= 1 afterwards, which is why -5 works, but the cast happens first.
- Impact: UB reachable from a public API with a caller-supplied double; the fuzz builds
  (`.clusterfuzzlite`, `float-cast-overflow`) would flag it if a fuzzer ever drove the percentile argument.
  x86 `cvttsd2si` yields `INT64_MIN` -> clamped to 1 -> p0, so no wrong answer in practice today.
- Proposed fix (verified: all three cases now return p0 = 10, `pcts(-inf,50) -> 0 10 10`, ctest 5/5):
  ```diff
  +    /* clamp to [0,100]: (int64_t) of a huge negative/-inf product is UB */
       double requested_percentile = percentile < 100.0 ? percentile : 100.0;
  +    requested_percentile = requested_percentile > 0.0 ? requested_percentile : 0.0;
  ```
  and the mirror line in `hdr_value_at_percentiles` (drop its `const`). NaN already falls to 100.0 via the
  first comparison, matching Java's `Math.min`.
- Proposed test: `test/hdr_histogram_test.c` — `test_value_at_percentile_out_of_range`: assert
  `hdr_value_at_percentile(h, -INFINITY) == hdr_value_at_percentile(h, 0.0)`, same for `-1e300`, and
  `hdr_value_at_percentile(h, INFINITY) == hdr_value_at_percentile(h, 100.0)`; run under the sanitizers job
  with `-fsanitize=float-cast-overflow` added (it is not in `ci.yml` today — see L4-F6).
- Confidence: high (UBSan report; fix verified).

### L4-F4: `hdr_getnow` is declared in the public header but has no definition on Windows
- Severity: medium     Class: portability (link error for Windows consumers)
- Where: `include/hdr/hdr_time.h:36` vs `src/hdr_time.c:22-40` (`_WIN32` branch defines only `hdr_gettime`)
  @ main 26587de; identical in COMBINED
- Tracked: untracked
- Repro (preprocess the `_WIN32` branch with a stub `windows.h`; `probe/fakewin/`):
  ```
  $ gcc -E -D_WIN32 -U__linux__ -Ifakewin -Iinclude src/hdr_time.c | grep -n '^void hdr_get'
  1413:void hdr_gettime(hdr_timespec* t);      <- header decl
  1416:void hdr_getnow(hdr_timespec* t);       <- header decl
  1437:void hdr_gettime(hdr_timespec* t)       <- the ONLY definition
  ```
  The Apple and Linux/BSD branches define both. CI never notices because the only in-tree caller,
  `examples/hiccup.c:163`, is built `if(CMAKE_SYSTEM_NAME MATCHES "Linux")` only.
- Impact: any Windows/Cygwin user calling `hdr_getnow` (the wall-clock companion `hdr_log_writer` users
  need for `start_timestamp`) gets `unresolved external symbol hdr_getnow`. Also note the Windows
  `hdr_gettime` is QPC-based (monotonic since boot), so `hdr_timespec_as_double(hdr_gettime)` is not an
  epoch time there, unlike the Linux `hdr_getnow`.
- Proposed fix (`src/hdr_time.c`, Windows branch):
  ```c
  void hdr_getnow(hdr_timespec* t)
  {
      /* wall clock: FILETIME is 100ns ticks since 1601; 11644473600s to the Unix epoch */
      FILETIME ft; ULARGE_INTEGER u;
      GetSystemTimePreciseAsFileTime(&ft);    /* Win8+; GetSystemTimeAsFileTime for older */
      u.LowPart = ft.dwLowDateTime; u.HighPart = ft.dwHighDateTime;
      t->tv_sec  = (long) (u.QuadPart / 10000000ULL - 11644473600ULL);
      t->tv_nsec = (long) (u.QuadPart % 10000000ULL) * 100;
  }
  ```
  (`long tv_sec` on Windows caps this at 2038; widening `hdr_timespec.tv_sec` is the ABI decision already
  noted in `.workspace-memory/hdr-upstream-prs.md`.)
- Proposed test: `test/hdr_histogram_log_test.c` (or a new `hdr_time_test.c` added to the ctest list):
  call `hdr_getnow(&ts)` and assert `ts.tv_sec > 1600000000 && 0 <= ts.tv_nsec < 1000000000` — this alone
  turns the Windows CI legs red today (link failure), which is the point.
- Confidence: high (by construction of the preprocessed source; not executed on Windows here).

### L4-F5: `clang -m32` builds emit `__atomic_*_8` libcalls; CMake never links `libatomic`
- Severity: low     Class: portability (i386 with clang; also any target where 64-bit atomics are libcalls)
- Where: `src/hdr_atomic.h:84-90` (`__atomic_*` builtins on `int64_t` with 4-byte ABI alignment),
  `src/CMakeLists.txt:36-44` (no `atomic` in `target_link_libraries`) @ main 26587de; COMBINED same
- Tracked: partially covered by #144 — its new `build-linux-i386` leg uses **gcc** `-m32` only (gcc inlines
  `lock cmpxchg8b`), so the clang case stays untested; not a defect of #144 itself.
- Repro:
  ```
  $ clang -m32 -O2 -std=c99 -c src/hdr_writer_reader_phaser.c && nm -u … | grep atomic
           U __atomic_exchange_8   U __atomic_fetch_add_8   U __atomic_load_8   U __atomic_store_8
  $ … src/hdr_histogram.c:  U __atomic_compare_exchange_8  U __atomic_fetch_add_8  U __atomic_load_8
  clang also warns: -Watomic-alignment "expected alignment (8 bytes) exceeds the actual alignment (4 bytes)"
  at hdr_histogram.c:109,115,117,139,146,150,157 and hdr_writer_reader_phaser.c:23,28,33,81.
  $ gcc -m32 -O2 -c …  && nm -u … | grep atomic      -> (nothing; inlined)
  ```
- Impact: `clang -m32` (and clang on any 32-bit target with under-aligned `int64_t`) fails at link with
  `undefined reference to __atomic_load_8` for every test/executable; the shared library links but every
  consumer then fails. The `_Static_assert` probe shows the actual field offsets are all 8-aligned, so
  correctness is fine once linked — it is purely a link-line issue.
- Proposed fix: `src/CMakeLists.txt` — `include(CheckCSourceCompiles)` probe for a 64-bit `__atomic_fetch_add`
  linking without `-latomic`; on failure `target_link_libraries(${NAME} PRIVATE atomic)` and add `-latomic` to
  `Libs.private` in `hdr_histogram.pc.in`. Optionally `HDR_ALIGN_PREFIX(8)`/`_Alignas(8)` on
  `struct hdr_histogram` to silence `-Watomic-alignment` (layout already satisfies it).
- Proposed test: extend #144's i386 CI leg with a `CC=clang` variant (or a second job) — that is the test.
- Confidence: high for the libcall/undefined-symbol fact (observed); medium for how many real users build
  32-bit with clang.

### L4-F6: CI matrix gaps relevant to this release (threading, UB class, arch, compiler)
- Severity: low     Class: coverage
- Where: `.github/workflows/ci.yml`, `cflite_pr.yml`, `cflite_batch.yml` @ main 26587de (+ #144 in COMBINED)
- Tracked: #144 adds Linux i386 (gcc) and Windows ClangCL; the rest is untracked
- Repro: read of the workflows —
  - no `-fsanitize=thread` job anywhere (L4-F1 is a TSan/ASan-visible race in a documented-thread-safe API);
  - `sanitizers` job flags are `-fsanitize=address,undefined` — **no `float-cast-overflow`**, so L4-F3 and the
    `hdr_timespec_from_double` class only surface in the weekly `cflite_batch` `undefined` run (which is
    exactly the Sep 21/28 history); `cflite_pr` runs `address` only;
  - no Linux clang leg (Linux builds use the runner default gcc), no Linux aarch64 leg (issue #98 open);
    `macos-latest` is Apple Silicon since 2024 so arm64 gets *implicit* coverage but the matrix labels it
    `arch: x64` and excludes `hdr_log_required: DISABLED` and `cmake: minimal` there;
  - `actions/checkout@v1` (Node 12, deprecated) in every job;
  - the unit tests never exercise `hdr_interval_recorder` from more than one thread
    (`hdr_histogram_atomic_concurrency_test.c` has zero references to it).
- Impact: L4-F1 and L4-F3 were reachable by existing tooling but no job runs it; TSan is the only cheap
  detector for the phaser/recorder class.
- Proposed fix: add to `ci.yml` (a) `tsan: clang -fsanitize=thread -O1 -g`, Debug, `HDR_LOG_REQUIRED=ON`,
  running ctest (the concurrency test + the new L4-F1 test); (b) append `,float-cast-overflow` to the
  `sanitizers` job flags; (c) a `linux, clang` matrix include; (d) bump `actions/checkout@v4`. Optionally a
  `ubuntu-24.04-arm` leg once the runner is acceptable to the maintainer (#98).
- Proposed test: n/a (CI config) — the L4-F1 and L4-F3 tests are the payload.
- Confidence: high (facts of the YAML); the value judgement is the maintainer's.

### L4-F7: NULL-argument contract is undocumented and inconsistent across the public API
- Severity: low     Class: hygiene / API contract
- Where: `src/hdr_histogram.c:412` (`memset(cfg, …)`), `:505` (`*result = histogram`), `:526` (`hdr_reset`),
  `:1090` via `hdr_add`, `:872` (`hdr_value_at_percentiles` derefs `h` after checking only the arrays),
  `src/hdr_interval_recorder.c:18,58,96` @ main 26587de
- Tracked: untracked
- Repro (`probe/api_edge.c`, UBSan):
  ```
  hdr_close(NULL)                          -> ok (explicit guard)
  hdr_init(1,1000,3,NULL)                  -> hdr_histogram.c:505:5: store to null pointer   (+ leaks the histogram + counts)
  hdr_calculate_bucket_config(…, NULL)     -> hdr_histogram.c:412:12: null pointer passed as argument 1 (memset)
  hdr_reset(NULL)                          -> hdr_histogram.c:526:9: member access within null pointer
  hdr_add(h, NULL)                         -> hdr_histogram.c:1090:28: member access within null pointer
  hdr_value_at_percentiles(NULL,p,v,1)     -> hdr_histogram.c:872:36: member access within null pointer (arrays are checked, h is not)
  hdr_interval_recorder_init(&r); record   -> hdr_histogram.c:560:25 (active==NULL; header never says active must be set)
  hdr_interval_recorder_init(&r); sample   -> hdr_interval_recorder.c:58:33
  ```
  Also: header says `hdr_value_at_percentiles` returns `ENOMEM` for a NULL destination; the code returns `EINVAL`.
- Impact: crashes are the normal C contract for NULL `h`, but the two *output-parameter* cases
  (`hdr_init`, `hdr_calculate_bucket_config`) already have an `EINVAL` return path and silently leak/UB
  instead; the doc/return-code mismatch is a paper cut for bindings authors.
- Proposed fix: `if (NULL == result) return EINVAL;` at the top of `hdr_init`; `if (NULL == cfg) return EINVAL;`
  before the `memset` in `hdr_calculate_bucket_config`; fix the doc comment to `EINVAL`; one line in
  `hdr_interval_recorder.h` stating that `hdr_interval_recorder_init` leaves `active` NULL and the caller
  must assign it (or use `_init_all`) before recording/sampling. Leave `hdr_reset`/`hdr_add`/… as "h must be
  non-NULL" in the header rather than adding checks to hot paths.
- Proposed test: `test/hdr_histogram_test.c` — assert `hdr_init(1,1000,3,NULL) == EINVAL` and
  `hdr_calculate_bucket_config(1,1000,3,NULL) == EINVAL`; assert `hdr_value_at_percentiles(h,p,NULL,1) == EINVAL`.
- Confidence: high (all observed).

### L4-F8: Small hygiene items found in scope (bundle)
- Severity: info     Class: hygiene / portability
- Where / Tracked / Repro (all @ main 26587de, all untracked, all observed):
  1. `nm -D --defined-only libhdr_histogram.so` exports 3 non-`hdr_`-prefixed symbols: `counts_index_for`
     (`src/hdr_histogram.c:238`), `zig_zag_encode_i64`, `zig_zag_decode_i64` (`src/hdr_encoding.c`). They are
     deliberately non-static for the tests (`src/hdr_tests.h`, "not intended for normal usage"), but the
     library has no visibility control (`-fvisibility=hidden` / export macro), so they land in the installed
     `.so`'s ABI alongside 90 `hdr_*` symbols. Fix: `hdr_` prefix them (test-only header, cheap rename) or
     link the tests against the static library and build the shared one with hidden visibility.
  2. `hdr_phaser_flip_phase(p, sleep_time_ns < 0)`: `(unsigned int)(sleep_time_ns / 1000)` wraps —
     `-5e9 ns -> sleep_time_us=4289967296 -> usleep(~4290 s)` per spin iteration. Fix: treat `<= 0` as yield
     (`sleep_time_ns <= 0 ? 0 : …`), matching Java where a non-positive `yieldTimeNsec` yields.
  3. `hdr_writer_reader_phaser_init`: if `hdr_mutex_init` fails the freshly allocated `reader_mutex` leaks
     (`src/hdr_writer_reader_phaser.c:54-58`); `hdr_interval_recorder_init_all` likewise leaves the phaser
     initialised when `hdr_init` fails (caller must still call `_destroy`, which is undocumented but safe).
  4. `cmake --install` with `-DHDR_HISTOGRAM_INSTALL_SHARED=OFF -DHDR_HISTOGRAM_INSTALL_STATIC=OFF` still
     installs `hdr_histogram-config.cmake` whose line 6 does
     `include(${CMAKE_CURRENT_LIST_DIR}/hdr_histogram-targets.cmake)` — a file that is then not installed,
     so `find_package(hdr_histogram)` fails with a confusing error instead of "not found". Also installs the
     `.pc` file advertising `-lhdr_histogram` that does not exist. Fix: guard the two `install(FILES …)`
     blocks with the same `if(HDR_HISTOGRAM_INSTALL_SHARED OR HDR_HISTOGRAM_INSTALL_STATIC)`.
  5. `src/hdr_thread.c:56` Windows branch declares `void hdr_yield()` (K&R-style, fails `-Wstrict-prototypes`);
     the POSIX branch and the header say `(void)`.
  6. `include/hdr/hdr_time.h:30-34`: `#if defined(_MSC_VER)` / `#else` both declare the identical prototype —
     dead conditional. `include/hdr/hdr_histogram_version.h:12`: `//` comment after `#endif` (C89 `-pedantic`
     warning; harmless under the project's C99 setting).
- Impact: none is a runtime defect on the supported matrix; items 1 and 4 are the ones a distro packager
  would hit.
- Proposed fix / test: as inline above; item 4 is testable with the `cmake --install` + `find_package` consumer
  smoke that lane 7 already scripted.
- Confidence: high (each observed or reproduced by build/command as noted).

## Did NOT reproduce / non-findings
- `hdr_writer_reader_phaser`: no lost wakeup, spin, or epoch-overflow issue (see Verified OK).
- `hdr_get_memory_size` / `hdr_init` `size_t` overflow for huge configs: max `counts_len` is 6,160,384
  (`(1, INT64_MAX, 5)`), i.e. 49 MB — no overflow on ILP32 or LP64.
- `hdr_gettime`/`hdr_getnow` Linux: `clock_gettime` into `struct timespec` (`hdr_timespec` *is*
  `struct timespec` off-Windows) — no conversion, no overflow. Windows `hdr_gettime`: `(long) integral` of
  QPC seconds since boot only overflows after 68 years of uptime; not a defect.
- `hdr_timespec_as_double`: `time_t`->`double` loses precision only above 2^53 s — not reachable.
- No `int64_t`->`long`/`int` narrowing (the MSVC C4244 class) exists in `src/` under `-m32 -Wconversion`.
- All public headers are C++-safe (compile + link + run), so #150's earlier missing-guard defect is
  specific to the packed header and already fixed on that branch.

# Lane 7 — Open-PR reconciliation + release readiness of main

Scope probed: (all on x86-64 Linux, gcc 13 / clang 18, cmake 3.28; MAIN = upstream/main `26587de`,
COMBINED = `audit/combined-open-prs` `5a088e3`; my working copies live in `$SP/lane-7/` and `$SP/lane-7/combined/`)
- Open-PR inventory: `GH_TOKEN= GITHUB_TOKEN= gh pr list --state open --json number,headRefOid,...`; per-PR
  `gh pr view N --json statusCheckRollup|comments|body|files`; GraphQL `reviewThreads{isResolved,isOutdated}`;
  compared each GitHub head SHA with the local `pr-<N>` branch in `$SP/hdr-combined`.
- Stack relationships: `git diff pr-140 pr-141 -- src/hdr_histogram.c`, `git diff pr-154 pr-156 -- src/hdr_time.c`;
  squash-merge simulation (`git merge --squash pr-140 && git commit; git merge pr-141`, same for 154→156) in
  throwaway worktrees `$SP/lane-7/sim2-*`.
- COMBINED build/test: Release gcc (`-Wall -Wextra`, 0 warnings) ctest 7/7; clang
  `-fsanitize=address,undefined,float-cast-overflow -fno-sanitize-recover=all` ctest 7/7; gcc same flags 7/7;
  `-DHDR_LOG_REQUIRED=DISABLED` 5/5; `cmake --install` + `nm -D --defined-only` symbol diff vs MAIN.
- Weekly fuzz: `gh run view 36401899117 --log-failed`; replayed the recovered crash inputs
  (`experiments/PR-REVIEW-2026-09-29/ci-crash-108861475657.hlog`, sha1 `63bd43e8…` = the CI artifact name;
  `ci-crash-103906865201.hlog` sha1 `9399e83a…`) with a locally built `log_reader_fuzzer`
  (`clang -fsanitize=fuzzer,address,undefined,float-cast-overflow`) against MAIN and COMBINED sources.
- Direct `hdr_timespec_from_double` probe (`$SP/lane-7/ub/ts.c`) linked against MAIN and COMBINED `build/asan`
  static libs, and against gcc builds using the exact `ci.yml` sanitizer flags with/without `float-cast-overflow`.
- Release packaging on MAIN: `cmake --install` into `prefix-rel` (logging ON) and `prefix-nolog` (DISABLED);
  out-of-tree consumers via `find_package(hdr_histogram CONFIG)` (C + C++, static + shared, `$SP/lane-7/consumer/`)
  and via `pkg-config` (shared, `--static`); each installed header compiled standalone with
  `gcc/clang -std=c99|c11 -pedantic` and `g++/clang++ -std=c++17 -pedantic`; `readelf -d` NEEDED/SONAME.
- Version/ABI: `include/hdr/hdr_histogram_version.h`, `CMakeLists.txt` SOVERSION, `hdr_histogram.pc.in`,
  `git diff 0.11.10..HEAD -- include/`, `git tag`, `gh release list/view`, `git log 0.11.10..HEAD`.
- Hygiene: `gh api repos/.../branches/main/protection`, `/rules/branches/main`, `/collaborators`,
  `/private-vulnerability-reporting`, `/contents/{CODEOWNERS,SECURITY.md,CHANGELOG*}` (repo and `HdrHistogram/.github`),
  BCR `modules/hdrhistogram_c/metadata.json`, issue #132.

Verified OK (do not re-do):
- All 7 open PR heads on GitHub == local `pr-<N>` branches (139 `cf18639`, 140 `4130a24`, 141 `2e90511`, 144 `87fc814`,
  150 `fa5a13d`, 154 `a9d4fd2`, 156 `cb4ccf4`); all are `MERGEABLE` against main; all were refreshed with main at
  23:05–23:14 UTC on 2026-09-29 (after #138/#149/#155/#157 landed).
- CI on every head: **every leg green** — 14 `build(...)` legs, `sanitizers (linux, Debug, ASan+UBSan)`,
  `PR (address)` ClusterFuzzLite, `claude-review`; #144 additionally `build (linux, Debug, i386, gcc -m32)` and
  `build (windows, Debug, x64, ClangCL toolset)`. No red leg anywhere, so there is no failing-job log to pull.
- Latest main CI run 36643102283 (`26587de`, 2026-09-29 23:03Z): 15/15 jobs success incl. `sanitizers`.
- COMBINED: 0 compiler warnings (gcc `-Wall -Wextra`), ctest 7/7 Release, 7/7 clang ASan+UBSan+float-cast-overflow,
  7/7 gcc ASan+UBSan+float-cast-overflow, 5/5 no-zlib. Both recovered weekly-fuzz crash inputs execute clean.
  `.so` symbol diff vs MAIN is exactly the 22 `hdr_packed_*` functions from #150; SONAME stays
  `libhdr_histogram.so.6` (6.3.3); `.pc` byte-identical. `hdr_packed_histogram.h` compiles standalone in
  c99/c11/C++17 and has `extern "C"` guards. #150 does not call dense `hdr_value_at_percentiles` or `hdr_atomic.h`,
  so #150×#141 and #150×#144 cannot interact; #156×#157 co-exist (both test files merged, 7/7 green).
- #141 ⊃ #140 by content (not by ancestry: `pr-140` is not an ancestor of `pr-141`; #141 re-implements the same fast
  path with a `uint64_t` accumulator and block skip; the `test_value_at_percentiles_with_offset` test is carried).
  #156 ⊃ #154 by content (same non-ancestry caveat; `src/hdr_time.c` in #156 is a strict superset).
- MAIN install (logging ON and DISABLED): headers, `libhdr_histogram.so.6.3.3` + symlinks, `libhdr_histogram_static.a`,
  `hdr_histogram-config*.cmake`, `hdr_histogram.pc`, examples. `find_package` consumers (C and C++, static and shared)
  build and run against both prefixes; C++ linkage works (all 6 function-bearing headers have `__cplusplus` guards;
  `hdr_histogram_version.h` has none but contains only a macro). Nolog `.so` has no `NEEDED libz`.
- `hdr_histogram_version.h` is the single source of the project version (CMake regex-reads it); `.pc` Version and
  `hdr_histogram-config-version.cmake` follow it (0.11.10).
- `-fsanitize=float-cast-overflow` is accepted by both gcc 13 and clang 18 and MAIN + COMBINED test suites are clean
  under it (so adding it to CI would not break anything today).
- Did NOT reproduce / nothing found: no cross-PR behaviour change on COMBINED; no new warnings from #144/#141/#156
  sources vs main under `-Wall -Wextra -Wconversion -Wshadow -Wformat=2` (hdr_histogram.c 18→18, hdr_time.c 2→2;
  the only new ones are 3 benign `int64_t→double` `-Wconversion` in `hdr_packed_histogram.c:457-461` stddev).

## Findings (ranked, most severe first)

### L7-F1: Weekly ClusterFuzzLite UBSan batch is red on main and will fail again on 2026-10-05 unless #154/#156 merge first
- Severity: high     Class: security
- Where: `src/hdr_time.c:92` (`int seconds = (int) value;`) and `:96` (`milliseconds * 1000000`) @ main 26587de;
  fixed on COMBINED (`src/hdr_time.c:90-135`).
- Tracked: covered by PR #154 (⊂ #156). Reported here only as a *release-timing* risk, not as a new bug.
- Repro: run 36401899117 (2026-09-28, `BatchFuzzing (undefined)` failure, `BatchFuzzing (address)` success):
  `hdr_time.c:96:31: runtime error: signed integer overflow: -2147483648 * 1000000 cannot be represented in type 'int'`
  via `scan_start_time` ← `hdr_log_read_header` ← `log_reader_fuzzer`, crash `63bd43e82ce8833d9cc40e175407eba57f04467f`.
  Local replay of that exact file: MAIN → `hdr_time.c:92:19: runtime error: 7.77778e+49 is outside the range of
  representable values of type 'int'`; COMBINED → `Executed ... in 1 ms` (clean). Direct probe on MAIN asan lib:
  `1403476110183.0` → UB at :92; `1.9996 → {1, 1000000000}`, `-0.4 → {0, -400000000}` (malformed timespecs);
  COMBINED: `{1403476110183,0}`, `{2,0}`, `{-1,600000000}`, `1e300/nan → {0,0}`.
- Impact: any `#[StartTime:` a reader cannot hold in `int` is UB on attacker-supplied logs; the weekly
  `cflite_batch.yml` (cron `0 3 * * 1`, 3600 s/sanitizer) has been red 2026-09-21 and 2026-09-28 for this and will be
  red again Monday 2026-10-05 03:00 UTC on whatever main is then. A release cut from main without #154 ships the UB.
- Proposed fix: merge **#156** (contains #154) before tagging; see L7-F2 for why not #154 then #156.
- Proposed test: already in #154/#156 (`test_timespec_from_double`, `test/regression-log-start-time-overflow.hlog`
  in `hdr_histogram_log_test`). Nothing further.
- Confidence: high (exact CI artifact replayed on both trees).

### L7-F2: Both open stacks conflict the moment their base PR is squash-merged (#140→#141, #154→#156)
- Severity: medium     Class: hygiene (merge-process; a wrong conflict resolution here is how #137 lost its offset fallback)
- Where: `src/hdr_histogram.c` + `test/hdr_histogram_test.c` (140/141); `src/hdr_time.c` + `test/hdr_histogram_test.c` (154/156)
- Tracked: untracked upstream (workspace memory "Merging one PR of a stack breaks its siblings" documents the pattern).
- Repro: `git merge --squash pr-140 && git commit -m x && git merge pr-141` →
  `CONFLICT (content): Merge conflict in src/hdr_histogram.c` and `... in test/hdr_histogram_test.c`.
  `git merge --squash pr-154 && git commit && git merge pr-156` → `CONFLICT (content) in src/hdr_time.c` and
  `test/hdr_histogram_test.c`. (Non-squash merge order via `gh pr update-branch` was not simulated; the maintainer
  squash-merges.)
- Impact: the 2026-09-29 recommended order "#154 → #156" and "#140 then #141" forces a hand-resolved conflict in the
  very function each stack fixes; the follow-up PR would show "conflicts" on GitHub after the base lands and its green
  CI would no longer be for the code that gets merged.
- Proposed fix: merge the **superset** and close the base as superseded: merge #156 (close #154), merge #141 (close
  #140) — both supersets are MERGE-READY per the latest review comments and both carry the base's tests
  (`test_value_at_percentiles_with_offset`, `test_timespec_from_double`, regression `.hlog`). #141 additionally
  fixes #140's signed `int64_t total` accumulator (`uint64_t` + `signs < 0` guard), so merging #140 alone would land
  the weaker variant. If the maintainer prefers the small PR first, resolve per the memory recipe and verify
  `grep -c "^static char\* <fn>"` and `grep -c "mu_run_test(<fn>)"` are both 1.
- Proposed test: none (process). After the merge, re-run the `sanitizers` job on the resulting main.
- Confidence: high.

### L7-F3: `ci.yml` sanitizers job cannot see float→int overflow (no `float-cast-overflow`), unlike the weekly clang fuzz job
- Severity: medium     Class: coverage
- Where: `.github/workflows/ci.yml` sanitizers job, `-DCMAKE_C_FLAGS="-fsanitize=address,undefined -fno-sanitize-recover=all -g"`
  (default compiler on `ubuntu-latest` = gcc) @ main 26587de
- Tracked: untracked.
- Repro: MAIN built with the exact CI flags (gcc), probe `hdr_timespec_from_double(3000000000.0)`:
  `hdr_time.c:96:31: runtime error: signed integer overflow: -2147483648 * 1000000` — the *cast* at :92 is silent and
  only the downstream multiply trips. Same build `+float-cast-overflow`: `hdr_time.c:92:5: runtime error: 3e+09 is
  outside the range of representable values of type 'int'`. gcc's `-fsanitize=undefined` does not imply
  `float-cast-overflow`; clang's does — this is why ClusterFuzzLite reported :92 and CI/gcc reports :96.
- Impact: a `(int) double` narrowing with no downstream arithmetic (e.g. a future
  `hdr_value_at_percentile`-style `(int64_t) percentile` or a decoded-double field) passes the per-PR gate and only
  surfaces in the weekly batch a week after merge — exactly the #153/#154 history.
- Proposed fix (one line in `ci.yml`):
  `-DCMAKE_C_FLAGS="-fsanitize=address,undefined,float-cast-overflow -fno-sanitize-recover=all -g"`.
  Verified: MAIN 5/5 and COMBINED 7/7 pass under gcc and clang with this flag today.
- Proposed test: the flag itself; `test_timespec_from_double` (from #156) then fails at :92 on unpatched code instead
  of at :96, i.e. the fixture becomes compiler-independent.
- Confidence: high.

### L7-F4: Installed `hdr_histogram_log.h` / `hdr_time.h` do not compile under strict `-std=c99`
- Severity: low     Class: portability
- Where: `include/hdr/hdr_time.h:10,22` (`#include <time.h>` then `typedef struct timespec hdr_timespec;`) @ main 26587de
- Tracked: untracked (issues #100/#20 are about header layout, not this).
- Repro: `echo '#include <hdr/hdr_histogram_log.h>' | gcc -std=c99 -fsyntax-only -x c -I prefix/include -` →
  `hdr_histogram_log.h:50:18: error: field 'start_timestamp' has incomplete type` (clang: `forward declaration of
  'struct timespec'` at `hdr_time.h:22`). Passes with `-std=c11`, `-std=gnu99`, or `-std=c99 -D_POSIX_C_SOURCE=200809L`.
  The library's own build is unaffected only because `CMakeLists.txt:54` adds `-D_GNU_SOURCE`.
- Impact: any consumer built with `-std=c99 -pedantic` (the mode PR #141's body claims for this project) cannot use
  the log API or `hdr_timespec` on glibc; `hdr_log_reader.start_timestamp` is an incomplete type.
- Proposed fix (`include/hdr/hdr_time.h`, before `#include <time.h>`):
  ```c
  /* struct timespec is only exposed by <time.h> under POSIX in strict C99 */
  #if !defined(_WIN32) && !defined(_WIN64) && !defined(__CYGWIN__) && \
      !defined(_POSIX_C_SOURCE) && !defined(_XOPEN_SOURCE) && !defined(_GNU_SOURCE) && !defined(_DEFAULT_SOURCE)
  #  define _POSIX_C_SOURCE 199309L
  #endif
  ```
  Caveat: has no effect if the consumer included `<time.h>` first; that residual case needs C11 or a feature macro
  (worth one README line).
- Proposed test: a CI step compiling each installed header standalone:
  `for h in _install/include/hdr/*.h; do echo "#include <hdr/$(basename $h)>" | $CC -std=c99 -pedantic -fsyntax-only -x c -I_install/include -; done`
  (and `-std=c++17 -x c++`).
- Confidence: high on the repro; medium on the fix (feature-macro ordering caveat above).

### L7-F5: Package metadata is wrong for `HDR_LOG_REQUIRED=DISABLED` installs and for static linking via pkg-config
- Severity: low     Class: portability
- Where: `config.cmake.in:3` (`find_dependency(ZLIB)` unconditional); `CMakeLists.txt:111-115`
  (`if(${ZLIB_FOUND}) set(PC_REQUIRES_PRIVATE_ZLIB "zlib")` — keyed on `ZLIB_FOUND`, not `HDR_LOG_ENABLED`);
  `hdr_histogram.pc.in:12-13` (`Libs: -lhdr_histogram`, `Libs.private: -pthread -lm -lrt`) @ main 26587de
- Tracked: untracked.
- Repro (nolog install): `prefix-nolog/lib/pkgconfig/hdr_histogram.pc` contains `Requires.private: zlib` and
  `prefix-nolog/lib/cmake/hdr_histogram/hdr_histogram-config.cmake` contains `find_dependency(ZLIB)`, although the
  installed `.so` has no `NEEDED libz.so.1` and its `INTERFACE_LINK_LIBRARIES` has no `ZLIB::ZLIB`.
  Static via pkg-config: `gcc -static main.c $(pkg-config --cflags --static --libs hdr_histogram)` →
  `/usr/bin/ld: cannot find -lhdr_histogram` (the archive is `libhdr_histogram_static.a`; `.pc` only names the shared
  stem). `-lrt` is emitted unconditionally in `Libs.private` while CMake gates it on `check_library_exists(rt ...)`.
- Impact: the one configuration that exists *because* zlib is unavailable produces a package whose `find_package`
  and `pkg-config --static` fail on a zlib-less consumer machine (`find_dependency` is fatal). `pkg-config --static`
  never links the static library; consumers must know the `_static` name. `-lrt` breaks `--static` on macOS/musl.
- Proposed fix: `config.cmake.in`: `if(@HDR_LOG_ENABLED@) find_dependency(ZLIB) endif()` (and pass through
  `configure_package_config_file` — already used); `CMakeLists.txt:111`: `if(HDR_LOG_ENABLED)` instead of
  `if(${ZLIB_FOUND})`; `.pc.in`: `Libs.private: -pthread -lm @PC_LIBS_PRIVATE_RT@` keyed on `HAVE_LIBRT`. The static
  archive name is a public contract (`hdr_histogram::hdr_histogram_static`); document it in README rather than rename.
- Proposed test: CI `HDR_LOG_REQUIRED=DISABLED` legs add `cmake --install` + a `find_package` consumer configured with
  `-DCMAKE_DISABLE_FIND_PACKAGE_ZLIB=ON` (must succeed), and `pkg-config --static --libs hdr_histogram` (must not
  mention `zlib`).
- Confidence: high.

### L7-F6: Shared library exports 11 internal symbols with no visibility policy (+22 from #150)
- Severity: info     Class: hygiene
- Where: `src/CMakeLists.txt` (no `C_VISIBILITY_PRESET`/export macro); declarations only in `src/hdr_tests.h`,
  `src/hdr_encoding.h` @ main 26587de
- Tracked: partially covered by issue #95 (Road to 1.0: opaque struct / API break) — visibility is not mentioned there.
- Repro: `nm -D --defined-only prefix-rel/lib/libhdr_histogram.so | awk '$2=="T"'` → 93 `T` symbols; not declared in
  any installed header: `counts_index_for hdr_base64_decode hdr_base64_decode_block hdr_base64_decoded_len
  hdr_base64_encode hdr_base64_encode_block hdr_base64_encoded_len hdr_decode_compressed hdr_encode_compressed
  zig_zag_decode_i64 zig_zag_encode_i64`. Identical list in the nolog `.so`. COMBINED adds the 22 `hdr_packed_*`
  (intended) and `hdr_packed_histogram.c:40` includes the test-only `hdr_tests.h` for `counts_index_for`.
- Impact: every non-static function is de-facto ABI (`counts_index_for` is the record-path index function that the
  perf PRs keep changing); an accidental signature change is an SONAME-worthy break nobody notices.
- Proposed fix (release-time decision, not this round): `set_target_properties(... C_VISIBILITY_PRESET hidden)` plus an
  `HDR_API` export macro on the public headers — this is an ABI change (removes symbols) so it must ride a
  `HDR_SOVERSION_CURRENT` bump, ideally with the #95 opaque-struct work. Short term: #150 should take
  `counts_index_for` via a small internal header rather than `hdr_tests.h` (already offered in its body).
- Proposed test: a CI step diffing `nm -D --defined-only` against a checked-in `abi/exports.txt`.
- Confidence: high (measured); the fix scope is a maintainer decision.

### L7-F7: Release bookkeeping not done on main: version string, SOVERSION revision, README include path, no changelog, BCR lags
- Severity: low     Class: hygiene
- Where: `include/hdr/hdr_histogram_version.h:10` (`"0.11.10"`), `CMakeLists.txt:29-31` (`6.3.3`), `README.md:29`
  (`#include <hdr_histogram.h>`), repo root (no `CHANGELOG*`), BCR `modules/hdrhistogram_c/metadata.json`
- Tracked: BCR automation = issue #132 (open; maintainer objects to the app's write access). Rest untracked.
- Repro: `git log --oneline 0.11.10..HEAD` = 16 non-merge commits (8 security fixes, 2 perf, CI/fuzz) but
  `HDR_HISTOGRAM_VERSION` still `0.11.10` and `HDR_SOVERSION_{CURRENT,REVISION,AGE}` still `6 3 3` (the file's own rule
  step 1 says REVISION increments when source changed). `echo '#include <hdr_histogram.h>' | gcc -I prefix/include
  -fsyntax-only -x c -` → `fatal error: hdr_histogram.h: No such file or directory` (installed path is
  `hdr/hdr_histogram.h`). `gh release view 0.11.10` notes are 3 bullets; no CHANGELOG file. BCR has `0.11.2`,
  `0.11.9` only — `0.11.10` (2026-06-29) was never published; BCR maintainer = "No Maintainer Specified".
  No Bazel files in the repo (`MODULE.bazel`/`BUILD` absent; BCR carries them as patches).
- Impact: a tag today would ship `HDR_HISTOGRAM_VERSION "0.11.10"` in a 0.11.11 tarball and an unchanged
  `libhdr_histogram.so.6.3.3` for changed code; README's first code sample does not compile against an install.
- Proposed fix: bump header to `0.11.11`; `HDR_SOVERSION_REVISION 3→4` (no interface added/removed since 0.11.10 —
  `git diff 0.11.10..HEAD -- include/` is a 6-line comment on `hdr_iter_log_init`). If #150 merges before the tag:
  interfaces added ⇒ `CURRENT 6→7, REVISION 0, AGE 3→4` per the file's rule (note this project sets
  `SOVERSION = CURRENT`, so that renames the SONAME to `.so.7` — the decision #150 deliberately deferred to release
  time). README: `#include <hdr/hdr_histogram.h>`, plus an "Installing / linking" section naming
  `hdr_histogram::hdr_histogram{,_static}` and `pkg-config hdr_histogram`. Publish release notes on the GitHub
  Release (skeleton below); a `CHANGELOG.md` is optional given past practice. After tagging, open the BCR PR by hand
  (or adopt the `.bcr/` templates *without* the app — `publish-to-bcr` also runs as a plain reusable workflow, which
  answers the write-access objection in #132).
- Proposed test: a CI step asserting `git describe --tags` version == `HDR_HISTOGRAM_VERSION` on tag builds.
- Confidence: high.

### L7-F8: Repository hygiene gaps (report only): no branch protection, no CODEOWNERS, no SECURITY.md, private vulnerability reporting off
- Severity: info     Class: hygiene
- Where: GitHub repo settings for `HdrHistogram/HdrHistogram_c` and the `HdrHistogram/.github` org repo
- Tracked: untracked (noted informally in `.workspace-memory/hdr-upstream-prs.md`).
- Repro: `gh api .../branches/main/protection` → 404; `.../rules/branches/main` → `[]`; `/contents/CODEOWNERS`,
  `.github/CODEOWNERS`, `SECURITY.md`, `.github/SECURITY.md`, `CHANGELOG*` → 404 (repo and org);
  `/private-vulnerability-reporting` → `{"enabled": false}`; `license.spdx_id` = `NOASSERTION` (custom dual
  CC0/BSD-2 text in `LICENSE.txt`, so GitHub cannot classify it — correct, just unadvertised). 10 collaborators with
  push, 8 admins; the 2026-09 security fixes were merged by non-maintainer committers with review-bot approval.
- Impact: eight security fixes this month with no disclosure channel and a `sanitizers`/fuzz gate that is advisory
  (any collaborator can push to `main` or merge a red PR).
- Proposed fix: none to implement here — a maintainer decision. Minimum: a `SECURITY.md` pointing at GitHub private
  vulnerability reporting (enable it), a ruleset on `main` requiring the `sanitizers` and `PR (address)` checks and PR
  review, `CODEOWNERS` = `@mikeb01`.
- Proposed test: n/a.
- Confidence: high (API-verified).

---

## Pending-merge risk table (open PRs, state as of 2026-09-30 00:xx UTC)

| PR | Head (GitHub == local pr-N) | CI | Unresolved review items (verbatim-short → addressed by head?) | Body/tests vs diff | 2026-09-29 verdict still accurate? | COMBINED interplay | Merge risk / recommendation |
|---|---|---|---|---|---|---|---|
| **#156** timespec normalization (⊃#154) | `cb4ccf41` | all green | none open | Body says "Use `floor()`"; code does `trunc()` + rounded signed fraction + carry/borrow (bot flagged 09-18, still unfixed in body). Tests match. | MERGE-READY — **still accurate** | replayed crash `63bd43e8` clean; co-exists with #157 (7/7) | **Low. Merge first** (fixes L7-F1). Refresh body wording. |
| **#154** timespec double→int UB | `a9d4fd29` | all green | 1 thread, **unresolved, not outdated** (paulorsousa @ `hdr_time.c:102`: "silently mapping invalid or out of range input values to zero… maybe return an error… would need an API change"). Author answered (keep `void` ABI, `0/0` = existing sentinel, checked variant as follow-up); reviewer has not resolved. | Body matches diff. | MERGE-READY — accurate, **but see L7-F2** | content ⊂ #156 | **Medium (process)**: squash-merging it makes #156 conflict in `hdr_time.c` + test file. Prefer: close as superseded by #156, or resolve the thread and merge #156 only. |
| **#144** i386/ClangCL CI + AVX2 guard | `87fc8141` | all green incl. i386 and ClangCL legs (run twice) | 2 threads **unresolved but outdated** (paulorsousa: "remove the comment (won't make sense after merging)" → trimmed to one line in `48ef6b6`; "change the atomic helpers' types instead of casting… `void**` isn't interchangeable" → helpers made type-generic macros in `48ef6b6`, casts removed). Need reviewer to click resolve. | **Body stale**: silent on `src/hdr_atomic.h` (load/store_pointer → type-generic macros), `count_leading_zeros_64` `unsigned long` out-param, and `test/hdr_atomic_test.c`; only mentions ci.yml + guard. | MERGE-READY — accurate (head moved `212fa77`→`48ef6b6`→`87fc814` merge-with-main only) | independent; macros not used by #150 | **Low**. Update body; ask reviewer to resolve threads. Branch lives in the upstream repo (push to `upstream`, not fork). |
| **#141** blocked batch scan (⊃#140) | `2e90511b` | all green | none open | **Body stale**: "Counts are non-negative, so … identical to the per-element scan for any input" — code now has a `signs < 0` guard and `uint64_t total`; lists 1 test, head adds 3 (`test_batch_percentile_signed_counts`, `_with_offset`, `_blocked_parity`); "ctest 4/4" is pre-#145. Perf table is from Granite Rapids July head; 09-29 re-qualification on Meteor Lake reproduced +134% class win. | README says NEEDS WORK (perf pending) — **stale**: later comment 09-29 21:16 = **MERGE-READY (stacked on #140)** | A1 offset fallback intact; no packed interplay; 7/7 under 3 sanitizer configs | **Medium (process)**: conflicts with main if #140 is squash-merged first (L7-F2). Recommend merge #141 directly, close #140. Refresh body. |
| **#140** single-pass batch | `4130a246` | all green | none open | Body matches diff (still `int64_t total`, same as main). | README NEEDS WORK — **stale**: 09-29 21:15 = **MERGE-READY** | content ⊂ #141 (weaker: signed accumulator) | **Low if merged alone, but makes #141 conflict.** Prefer superseded-by-#141. |
| **#150** packed histogram | `fa5a13de` | all green (incl. `sanitizers`, nolog legs) | none open (bot's design question — "should packed ship as a separate opaque type now vs #95" — is for the maintainer) | Body's memory/perf tables are from the original head; body does not state the SOVERSION revert (`40b7611`) or the C++ guard / no-zlib core / fuzz-target additions made 09-29 — those are only in comments. | NEEDS WORK (perf/profile qualification pending) — **still accurate**; no perf comment since | adds 22 exported `hdr_packed_*`; SONAME unchanged; includes test-only `hdr_tests.h` (L7-F6); 3 benign `-Wconversion` | **Medium (design + ABI bookkeeping)**: merging before the tag forces the SOVERSION decision (L7-F7). Not a release blocker if held. |
| **#139** AVX2 prefetch | `cf186392` | all green | none open (bot 09-02: "re-run the benchmark on the current head") | **Body contradicted by evidence**: claims +5.7…8% (Cascade Lake / Granite Rapids, July); 09-29 21:41 re-measurement vs #138 on Meteor Lake: **gcc −17%, clang −15%**. Diff is now 4 lines (`_mm_prefetch` with in-bounds clamp `pf < counts_len ? pf : counts_len-1`, safe since `limit = counts_len & ~15` ⇒ `counts_len ≥ 16` inside the loop). | README "NEEDS WORK — prefetch qualification pending" — **stale**: qualification done, result **negative** | independent | **Do not merge** on current evidence; close or re-scope (retune distance, second µarch). Correctness is not the problem. |

Suggested landing order for the release: #156 → #144 → #141 (→ tag 0.11.11) ; hold #150 (design/SOVERSION), close/park #139,
close #154/#140 as superseded (or resolve conflicts per memory recipe if the maintainer wants them individually).

## Main CI / fuzz status
- `ci.yml` on `26587de`: 15/15 green (2026-09-29 23:03Z). Previous 4 pushes that day (0aa5970, 58055c6, 2bdcb0f) all green.
- `cflite_pr.yml`: ASan only, 200 s, per PR — green on all 7 heads.
- `cflite_batch.yml`: ASan + UBSan, 3600 s each, Mondays 03:00 UTC. Last two runs red (UBSan leg) on `1343a18`:
  2026-09-21 run 35577763352, 2026-09-28 run 36401899117 — same root cause (`hdr_time.c:92/96`, L7-F1). ASan leg green.
  The fix is only in open PRs; **next run 2026-10-05 will fail on main unless #156 (or #154) lands before it.**
- Older red batch runs (2026-08-24, -31, 09-07, 09-14) were the `read_ahead_timestamp` class fixed by merged #153/#157
  (crash `9399e83a…` replays clean on main — verified).
- Sanitizers job on main uses gcc without `float-cast-overflow` (L7-F3).

## Release-notes skeleton (proposed tag `0.11.11`; last release `0.11.10` = `18c7a32`, 2026-06-29)

```
## Security / correctness fixes
- #145 (e831736) Fix signed-shift overflow in hdr_calculate_bucket_config for extreme lowest/highest trackable values (UBSan, found by fuzzing); adds the ASan+UBSan `sanitizers` CI job and regression .hlog fixtures.
- #146 (6d40ddb) Fix heap buffer overflows in V1/V2 log decode with crafted counts_limit / word_size.
- #147 (20af49a) Harden the query path: int64 overflow in hdr_mean, out-of-bounds reads in hdr_count_at_value / hdr_count_at_index for out-of-range values.
- #148 (21e82a6) Fix signed-overflow UB in top-bucket value-range math (hdr_max, percentiles, iterator highest_equivalent saturate to INT64_MAX).
- #149 (2bdcb0f) Fix int64 overflow in the linear/log iterator reporting level near INT64_MAX (terminates, emits INT64_MAX once); document that hdr_iter_log_init uses an integer log base.
- #153 (1132c65) Fix signed overflow parsing log timestamps (read_ahead_timestamp): seconds reject instead of wrap, fraction stops at nanosecond resolution (weekly fuzzing failure).
- #155 (58055c6) Fix hdr_reset_internal_counters ignoring normalizing_index_offset: wrong min/max after decoding V1/V2 logs with a rotated counts array.
- #157 (0aa5970) Bound the log timestamp seconds field by the width of tv_sec (not long); a failed parse no longer clobbers the caller's timestamp.
- [if merged before tag] #156 (⊃#154) hdr_timespec_from_double: range-check and widen double→tv_sec (UB on out-of-int StartTime; fixes 2038 truncation); normalize carry/borrow so tv_nsec is always in [0, 1e9).

## Performance
- #137 (1343a18) Block-summed scalar percentile scan for the non-AVX2 fallback; AVX2 dispatch now offset-safe; decoded normalizing_index_offset reduced modulo counts_len.
- #138 (26587de) AVX2 percentile scan widened to 16 int64 per iteration (vector accumulator).

## Build / CI
- #152 (4a1b1fd) Fetch pinned CMake from Kitware GitHub releases (cmake.org 503s).
- 164bb94 Don't attempt AVX2 on i386; 62ea52b Fix ClangCL build on Windows.
- df64f85 Weekly ClusterFuzzLite batch fuzzing (ASan + UBSan, 1 h) and two new fuzz targets (hdr_record_fuzzer, hdr_decode_fuzzer).
- #151/b05d226 Automated first-pass PR review and issue triage workflows.
- [if merged] #144 CI coverage for i386 (gcc -m32) and Windows ClangCL; AVX2 dispatch guard simplified; hdr_atomic pointer helpers type-generic.

## Packaging notes
- HDR_HISTOGRAM_VERSION bumped to 0.11.11; libhdr_histogram.so.6.3.3 → 6.4.3 (SONAME unchanged) [or 7.0.4 if #150 is included].
- Known: strict -std=c99 consumers of hdr_histogram_log.h need _POSIX_C_SOURCE (see L7-F4).
```

## Bazel (issue #132)
No `MODULE.bazel`/`BUILD` in the repo (by design; BCR ships them as patches). BCR `hdrhistogram_c` has `0.11.2` and
`0.11.9`; **`0.11.10` was never published**. Maintainer's only comment on #132 objects to the Publish-to-BCR app's
write access. Release action: open the BCR PR manually for the new tag (as was done for 0.11.9), or adopt
`.bcr/` templates + the reusable workflow variant (no app installation required).

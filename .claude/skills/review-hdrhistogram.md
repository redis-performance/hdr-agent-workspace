# Skill: review-hdrhistogram (adversarial upstream-merge review)

Review a HdrHistogram_c change for **upstream merge-readiness** against
`HdrHistogram/HdrHistogram_c` (maintainer: Michael Barker, **@mikeb01**) before proposing
it. Purpose: maximize the chance it merges on the first pass by pre-clearing every gate
his CI and review style enforce — and to **adversarially hunt the correctness regressions
he (and our own self-review) have caught before**.

Use this on any diff in `HdrHistogram_c/src/*.c` / `include/hdr/*.h` before drafting a PR.
It is a checklist + runnable gates, distilled from the project's commit history, its CI
config, and the last ~10 perf/correctness PRs (#107, #110, #120–122, #133–137 — see Evidence).

---

## How to run it

Given a change in the `HdrHistogram_c/` submodule working tree (or a commit):

1. Print the diff under review (`git -C HdrHistogram_c diff` or `... show <sha>`).
2. Walk every checklist item; mark ✅/⚠️/❌ with a one-line reason.
3. Run the **gates** (build matrix, ctest, sanitizers, fuzz, benchmark) — pass/fail, not opinions.
4. Emit the verdict block. Call a change "merge-ready" only when all gates pass and no ❌ remains.

---

## Adversarial correctness review (do this FIRST — it's where merges die)

These are the real regressions caught on this project. Hunt each one:

### A1. Offset-aware / decoded-histogram path (the PR #137 catch)
- Any code that reads `h->counts[idx]` **directly** (instead of via `counts_get_normalised`
  / `hdr_iter_next`) MUST keep an `h->normalizing_index_offset != 0` fallback. Decoded and
  rotated histograms store buckets at a rotated offset; a direct read silently returns wrong
  percentiles for them. ❌ if a fast path drops this.
- Check **both** `get_value_from_idx_up_to_count` and `hdr_value_at_percentile(s)`.

### A2. Atomic twin kept in lock-step
- `counts_inc_normalised` ↔ `counts_inc_normalised_atomic`; `update_min_max` ↔
  `update_min_max_atomic`. A change to one that isn't mirrored to the other is ❌ (the two
  record paths must compute identical indices/results).

### A3. Counts bounds + overflow hardening
- The record path must still reject out-of-range `counts_index` (the unsigned-cast check from
  PR #136 is the canonical form). Accumulators over `counts[]` should be `uint64`/`int64`-safe;
  don't reintroduce a narrowing that overflows on large totals (the "uint64 hardening" restored
  on #137). Preserve the "reject values larger than max trackable" behavior (#126).

### A4. No shift on signed values (project hard rule)
- The project explicitly removed signed shifts (commit "Remove shift operations on signed
  values"). Any `value >> k` / `<< k` where the operand can be a signed type is ❌ — cast to
  the unsigned type first, matching the existing helpers.

### A5. Division-by-zero / empty-histogram edges
- Mean/percentile/value math must stay safe for empty histograms and zero counts (cf. the
  div-by-zero fix #121). Re-check any new divisor.

### A6. Encode/decode round-trip unaffected
- If the struct layout, `counts[]`, or any logged field changed, the V0/V1/V2 log codec must
  still round-trip byte-identically. This is the highest-blast-radius change class.

---

## Merge-readiness checklist

### 1. Style — match the project; reuse its macros (PR #133 lesson)
- @mikeb01 **closed PR #133 and re-applied it himself** "modified the style slightly … one of
  the other PRs adds the expect builtins." Takeaways:
  - Reuse the existing `HDR_LIKELY` / `HDR_UNLIKELY` / `__builtin_expect` wrappers; **do not
    redefine** them in your diff.
  - Match brace/indent/spacing of the surrounding function exactly. He will re-style otherwise,
    which means a bounced or manually-rewritten PR.
  - Keep declarations and helper placement consistent with the file (helpers near use, `static`).

### 2. Small + single-purpose
- Merged perf PRs are tiny and do exactly one thing (#135 normalize bypass, #136 bounds check).
  Split unrelated changes into separate PRs. Don't fold a refactor into an optimization.

### 3. Portability — macros + scalar fallback, no bare intrinsics (PR #114 / #134 lesson)
- "Some intrinsics are not available in clang/win/arm" (#114). Any SIMD/intrinsic path needs:
  - `#if defined(__AVX2__)` (or runtime `__builtin_cpu_supports`) **with a scalar fallback**,
  - per-file `-mavx2` (don't globalize the flag),
  - and it must compile on MSVC, clang-cl, macOS, and ARM. PR #134 did this; #137 argues the
    portable scalar block-sum is better *because* it drops the dispatch entirely.
- Honor the "additional macro support for BSD systems" pattern — don't hardcode Linux-only APIs.

### 4. CI matrix — must be green across all of it
- `ci.yml` matrix: **{linux, windows, macos} × {x86, x64} × {Debug, RelWithDebInfo} ×
  {cmake minimal v3.12.4, latest v3.17.3} × {HDR_LOG_REQUIRED ON, DISABLED}** (with the
  documented excludes). Plus `cflite_pr.yml` = **ClusterFuzzLite address-sanitizer fuzzing**
  on every PR.
- Common bounce causes: Windows/MSVC build breaks (the fork hit "link bench static to fix
  Windows CI"), missing `HDR_HISTOGRAM_BUILD_BENCHMARK` gate on bench-only code, warnings under
  one compiler, `HDR_LOG_REQUIRED=DISABLED` build that references log symbols.
- Bench/test additions must be **gated** so the default build matrix stays unaffected
  (`HDR_HISTOGRAM_BUILD_BENCHMARK`, runtime AVX2 dispatch).

### 5. Correctness gates (run them — pass/fail)
```bash
# Stage 1 — unit + log round-trip
cmake -S HdrHistogram_c -B HdrHistogram_c/build/gcc -DCMAKE_BUILD_TYPE=RelWithDebInfo -DHDR_HISTOGRAM_BUILD_PROGRAMS=ON
cmake --build HdrHistogram_c/build/gcc -j && ctest --test-dir HdrHistogram_c/build/gcc --output-on-failure
# Stage 1b — HDR_LOG_REQUIRED=DISABLED still builds
cmake -S HdrHistogram_c -B HdrHistogram_c/build/nolog -DHDR_LOG_REQUIRED=DISABLED -DHDR_HISTOGRAM_BUILD_PROGRAMS=ON && cmake --build HdrHistogram_c/build/nolog -j
# Stage 2 — ASan + UBSan
cmake -S HdrHistogram_c -B HdrHistogram_c/build/asan -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_C_FLAGS="-fsanitize=address,undefined -fno-sanitize-recover=all" -DHDR_HISTOGRAM_BUILD_PROGRAMS=ON
cmake --build HdrHistogram_c/build/asan -j && ctest --test-dir HdrHistogram_c/build/asan --output-on-failure
# Stage 3 — ClusterFuzzLite (encode/decode or counts-layout changes), short local run
```
- For anything touching index math, `counts[]`, or the codec, Stage 2 + Stage 3 are REQUIRED.
- New observable behavior → add a test under `test/` and reference the issue number in the PR.

### 6. Optimization PRs need evidence (this is how the maintainer evaluates speed)
- Provide a **before/after benchmark table** in the PR body, on a named CPU + compiler, in the
  drivers' own units: `hdr_record_value` **ops/sec** (write) and `hdr_value_at_percentile`
  throughput (read). Mirror the format of #133/#134/#135/#136 PR bodies (baseline | optimized |
  delta) plus a **Steps to reproduce** block using the in-repo `hdr_histogram_perf` /
  `hdr_percentile_bench`.
- **Measure base vs patch back-to-back, same session, ≥2 samples.** A delta that diverges a lot
  between gcc and clang on the same path is a baseline/alignment artifact — re-measure.
- Report regressions honestly (none > noise on the path you didn't target).

### 7. PR hygiene & licensing
- BSD-licensed project; new files carry the project header. Don't add dependencies; keep it
  C (and the bench harness self-contained / gated).
- Don't reformat untouched lines. Keep the diff minimal so review is trivial.
- Branch off `upstream/main`; one isolated commit per PR (cherry-pick the single EXP).

---

## Output format

```
HdrHistogram_c merge-readiness review — <change / EXP-id>

Adversarial correctness:
  A1 offset-aware path .... ✅ | ❌ <where a direct counts[] read drops the offset fallback>
  A2 atomic twin .......... ✅ | ❌ <variant not mirrored>
  A3 bounds/overflow ...... ✅ | ❌
  A4 no signed shift ...... ✅ | ❌
  A5 div-by-zero/empty .... ✅ | N/A
  A6 codec round-trip ..... ✅ | N/A | ❌

Gates:
  build gcc ............... PASS | FAIL
  build HDR_LOG=DISABLED .. PASS | FAIL
  ctest .................. PASS (n/n) | FAIL
  ASan/UBSan ............. PASS | FAIL
  fuzz (cflite) .......... PASS | NOT RUN (not codec/layout) | FAIL
  Windows/MSVC reasoning . OK | RISK: <why>
  benchmark evidence ..... <gcc/clang write+read Δ% table> | MISSING

Checklist: <✅/⚠️/❌ per item 1–7 with one-line reasons>

Verdict: MERGE-READY | NEEDS WORK
Blocking: <list ❌ items>
Suggested PR title/body: <if merge-ready — small, single-purpose, evidence table + repro>
```

---

## Evidence (commit history + CI, captured 2026-06-30)

- Maintainer **@mikeb01**. Review style = terse, style-sensitive, dedupes overlapping
  changes. PR #133 (guarded `update_min_max` stores) was **CLOSED** and re-applied by him
  manually with style tweaks + reuse of the expect builtins another PR added — our fork's
  commit notes "Variation from PR #133, but already has macros and follow project style."
- Cleanly **APPROVED + MERGED**: #135 (bypass `normalize_index` when offset==0), #136 (single
  unsigned bounds check). Both tiny, single-purpose, hot-path, with benchmark tables + repro.
- #134 (AVX2 percentile prefix-sum) merged with scalar fallback + per-file `-mavx2`.
- #137 (OPEN) self-review caught: a force-push **dropped the offset-aware fallback** in
  `hdr_value_at_percentiles` (direct `counts[idx]` read ignores `normalizing_index_offset`) and
  **dropped uint64 hardening**; fixed by restoring the `HDR_UNLIKELY(normalizing_index_offset
  != 0)` branch in both scan functions. This is the template for A1/A3.
- Project rules from history: "Remove shift operations on signed values"; "Some intrinsics are
  not available in clang/win/arm" (#114); "additional macro support for BSD systems"; explicit
  counts bounds-overflow check ("CR: added explicit `counts` bounds overflow check"); fix
  potential division-by-zero (#121); memory-leak fixes in the log codec (#122); reject values
  larger than max trackable (#126).
- CI: `ci.yml` (3 OS × arch × build type × cmake min/latest × HDR_LOG ON/DISABLED) +
  `cflite_pr.yml` (ClusterFuzzLite ASan PR fuzzing).
- Bench gating: the fork's "gate behind HDR_HISTOGRAM_BUILD_BENCHMARK" + "runtime-dispatch
  AVX2 + link bench static to fix Windows CI" — bench/intrinsic code must never break the
  default matrix.

Refresh periodically:
`GH_TOKEN= gh pr list -R HdrHistogram/HdrHistogram_c --state all --limit 25 --json number,title,state,author`
and `git -C HdrHistogram_c log --oneline -40`.

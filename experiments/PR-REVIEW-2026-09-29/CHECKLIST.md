# Adversarial review gates

This applies `.claude/skills/review-hdrhistogram.md` to the commit-specific heads
in [the verdict table](README.md#final-commit-specific-verdicts). PASS means the
scoped change passed that check; it does not certify every pre-existing path.

| PR | A1 offsets | A2 atomic twins | A3 bounds/overflow | A4 unsigned shifts | A5 empty/math | A6 codec/layout |
|---|---|---|---|---|---|---|
| #138 | fallback retained | unchanged | new signed-prefix regressions fixed; unsigned AVX sum | PASS | existing behavior retained | unchanged |
| #139 | fallback retained | unchanged | signed-prefix fix; prefetch stays in allocation | PASS | existing behavior retained | unchanged |
| #140 | iterator fallback retained | unchanged | signed accumulation behavior retained | no new shifts | existing behavior retained | unchanged |
| #141 | signed offset fallback verified | unchanged | signed crossings restored without signed-add UB | no new shifts | signed zero-total probe covered | unchanged |
| #144 | unchanged | unchanged | architecture guards reviewed | no source shift changes | unchanged | unchanged |
| #149 | accessor unchanged | unchanged | terminal overflow fixed; fractional-base semantics unresolved | new helper fixed | nonpositive/NaN/Inf guards tested | public iterator layout unchanged |
| #150 | nonzero decode offsets explicitly rejected | separate type; no atomic API | payload extent fixed; allocation failures tested; saturated totals documented | constant signed shift removed | empty and target clamping tested | V2 roundtrips/fuzz; separate opaque type |
| #154 | unchanged | unchanged | finite/actual destination-width checks | no new shifts | N/A | large StartTime crash replay passes |
| #155 | logical index/count pair fixed | unchanged | new change safe; existing #118 remains | no new shifts | empty tests retained | 50,000 V1/V2 structured cases |
| #156 | unchanged | unchanged | width/range and rounding carry tested | no new shifts | negative tie cases tested | crash replay and log roundtrip |
| #157 | unchanged | unchanged | decimal width bound; no partial timestamp publication | no new shifts | N/A | malformed log regression and PR fuzz |

## Gates

All final heads have green online CI and PR fuzz checks in
[the final snapshot](final-head-checks.json), including GNU/Linux builds,
Windows/MSVC and macOS. Local compiler is Apple clang on arm64, **not GNU gcc**.
Local release/ASan+UBSan+float-cast-overflow/no-zlib results are preserved per
revision. Native Linux combined fuzz results are in the README; local structured
runs are not labeled coverage-guided fuzzing.

| Gate | Result / limit |
|---|---|
| Local release + CTest | PASS: nonpacked 5/5; packed 7/7 |
| Logging disabled | PASS: nonpacked 4/4; packed 5/5, including actual packed operations |
| Local ASan/UBSan/float-cast-overflow | PASS: nonpacked 5/5; packed 7/7 |
| Additional index/codec testing | signed-prefix differential; V1/V2 offsets/extrema; packed failure injection and structured fuzz; exact CI crash replay |
| C++ packed header | compile/link/run PASS after fix; original link failure retained |
| Current-head speed + profile | PENDING for #138–#141/#150, explicitly accepted as pending by the user; no baseline promotion |
| Whole-release safety | NOT established: existing dense #118 still triggers UBSan; bounded fuzz is not exhaustive |

## Checklist 1–7

1. **Style/macros:** fixes reuse project branch hints and unsigned-shift policy.
   Packed's stale public-header claims were replaced with its actual contract.
   Existing long implementation comments remain a maintainability cost.
2. **Scope:** fixes stay on their originating PRs. The independent clock-boundary
   test failure discovered by #150 CI was corrected in timestamp PR #156.
   Packed remains a substantial opt-in feature, with higher review cost than a
   small optimization; its separate-type scope is explicit.
3. **Portability:** no global AVX flags added; scalar/offset fallbacks retained.
   Actual destination types are used on POSIX/Windows. Windows caught the new
   packed test's missing zlib dependency; final head fixes it and is green.
4. **CI:** final exact-head snapshots are green. This includes PR fuzzing but is
   not equivalent to a full weekly UBSan campaign.
5. **Correctness:** scoped tests pass after fixes. #149's accepted fractional
   base still reports misleading boundaries and is explicitly NEEDS WORK.
6. **Optimization evidence:** historical measurements remain historical. Current
   native gcc/clang paired write/read measurements and profiles are pending;
   neither benchmark drivers nor acceptance counts were changed.
7. **Hygiene/licensing:** public-domain test/fuzz additions; no new runtime
   dependency beyond existing zlib. Non-forced branch pushes and exact-hash
   comments are recorded. No upstream merge, rewritten history, or accepted
   submodule-pointer change occurred.

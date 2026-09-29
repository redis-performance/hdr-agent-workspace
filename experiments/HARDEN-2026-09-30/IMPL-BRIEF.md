# Implementer brief (round 1)

Read `experiments/HARDEN-2026-09-30/BRIEF.md` (paths, tools, tracked-PR list, review M.O.) and
`CANDIDATES.md`, then the lane report sections your candidates cite
(`experiments/HARDEN-2026-09-30/round1/lane-*.md`). Lane scratch dirs under `$SP/lane-<N>/`
hold prototypes/probes you may reuse (lane-1 fixtree, lane-2 probe, lane-3 probe/lane3-proto-fixes.diff,
lane-4 src, lane-6 new-tests.patch + fix-sketch.patch + jgen Java oracle blobs).

For EACH candidate assigned to you:
1. `git -C $SP/hdr-main worktree add $SP/impl-<X>/<slug> -b harden/<slug> upstream/main`
   (one worktree + one branch per candidate; never touch `$SP/hdr-main` / `$SP/hdr-combined`).
2. Implement the MINIMAL fix in project style. Terse comments (one line, only the non-obvious
   why). Keep atomic twins in lock-step. No signed shifts. Honor `normalizing_index_offset`.
   Reuse existing macros. Don't reformat untouched lines.
3. Add a regression test in the existing minunit suites (`test/hdr_histogram_test.c`,
   `test/hdr_histogram_log_test.c`, ...). Capture values, `hdr_close`, THEN assert (LSan gotcha).
   The test must FAIL on upstream/main and PASS with the fix — prove both (run it against
   a build of `$SP/hdr-main` too, or `git stash` the src change).
4. Gates (all must pass; paste results in your report):
   - gcc RelWithDebInfo: build + ctest
   - clang Debug `-fsanitize=address,undefined,float-cast-overflow -fno-sanitize-recover=all`: build + ctest
   - gcc Debug `-fsanitize=address,undefined -fno-sanitize-recover=all`: build + ctest
   - `-DHDR_LOG_REQUIRED=DISABLED` build (+ ctest)
   - `-Wall -Wextra -Wconversion -Wshadow` compile of the touched files: zero NEW warnings vs main
   - codec/counts changes: run the relevant `.clusterfuzzlite` fuzzer ≥3 min with the fix under
     clang fuzzer+ASan+UBSan+float-cast-overflow; and replay any lane-3/lane-5 artifacts
   - Java parity: cite the Java method (AbstractHistogram.java) you matched, fetched via curl
5. Commit ONE commit per candidate on its branch: `fix: <what> (<one-line why>)` /
   `test: ...` / `ci: ...` — body ≤ 6 lines: bug, repro, fix, test. Add
   `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>` as the last line.
6. Cross-check against COMBINED: `git -C $SP/hdr-combined worktree add $SP/impl-<X>/<slug>-combined
   -b harden/<slug>-combined audit/combined-open-prs && git -C $SP/impl-<X>/<slug>-combined cherry-pick
   harden/<slug>` — report clean / conflict (which files) and whether ctest still passes there.
   If the fix must ALSO be applied inside an open PR's rewrite (e.g. #141), say exactly what.
7. Do NOT push, do NOT open PRs, do NOT commit to the workspace repo.

Deliverable: `experiments/HARDEN-2026-09-30/round1/impl-<X>.md` with, per candidate:
branch, commit sha, `git diff --stat`, the full diff (fenced), gate table, test-fails-on-main
proof, COMBINED cherry-pick result, Java reference, and "Open questions for voters"
(behaviour changes, API/ABI impact, anything a maintainer might push back on).
If a candidate turns out NOT to be a real bug or the fix is unsafe, say so with evidence
and do not force a change.

# Opening the Node.js updater fix yourself

Why this is a manual step: Node's AI policy (`doc/contributing/ai-guidelines.md`) says pull requests "must not be opened by
automated tooling, unless specifically approved in advance by the project", that AI use must be disclosed together with what the
contributor personally verified, that review replies must not be automated, and that violators may be blocked. So an agent should
not open this PR; the files here are the preparation. Policy also recommends product names stay out of commit messages (they are
only in `PR-BODY.md`).

1. Fork and clone (or use an existing Node checkout):
   `gh repo fork nodejs/node --clone` (large; a shallow clone is enough: `git clone --depth 1`).
2. Branch from current main: `git checkout -b tools-histogram-updater-header`.
3. Apply the change: `git apply /path/to/update-histogram.patch` (it applies cleanly to main as of 2026-10-03; the patch is the
   one changed line in `tools/dep_updaters/update-histogram.sh`).
4. **Verify it yourself** (the policy expects this, and the PR text asks you to say what you did):
   - run `./tools/dep_updaters/update-histogram.sh` (it picks up the latest HdrHistogram_c release, 0.12.0) and check that
     `git status` shows a new `deps/histogram/src/hdr_histogram_internal.h`;
   - `cc -fsyntax-only -Ideps/histogram/src -Ideps/histogram/include deps/histogram/src/hdr_histogram.c` should succeed;
   - then discard the update, it is not part of this PR: `git checkout -- deps doc` and `git clean -fd deps/histogram`.
   Keep the final diff to the single script line: `git diff --stat` should show one file, one line.
5. Commit: `git commit -F COMMIT-MESSAGE.txt tools/dep_updaters/update-histogram.sh` (the message follows Node's format: `tools:` prefix,
   lowercase subject under 72 characters, body wrapped at 72).
6. Push to your fork and open the PR against `nodejs/node` main. Use `PR-BODY.md` as the description after editing the bracketed
   verification bullet so it states only what you actually ran.
7. Answer reviewers personally. Once a Node collaborator has approved and landed it, ask one with write access to re-run the
   "Tools and deps update" workflow for `histogram`, or wait for the next Sunday 00:05 UTC run; either opens a clean
   "deps: update histogram to 0.12.0" PR.

Timing: the first scheduled run after the release is Sunday 2026-10-04 00:05 UTC, before this can land, so expect a first update PR
that fails to build until the fix is in. That does not affect Node's main.

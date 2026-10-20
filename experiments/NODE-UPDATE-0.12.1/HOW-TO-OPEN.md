# Opening the Node.js test fix yourself

Why this is manual: Node's AI policy (`doc/contributing/ai-guidelines.md`) says pull requests "must not be opened by automated tooling", AI use
must be disclosed with what the contributor personally verified, and review replies must not be automated. An agent therefore did not open this;
the files here are the preparation. See `.workspace-memory/node-ai-policy-user-opens-prs.md`.

1. In a Node checkout on top of the bot PR's head (or `main` once #66818 has landed): `git fetch origin refs/pull/66818/head && git checkout -b test-histogram-empty-values FETCH_HEAD`
   (the patch was made and tested at `d8a7ac12`, "deps: update histogram to 0.12.1").
2. `git apply /path/to/histogram-tests.patch` (4 test files, 13 lines).
3. Build and verify yourself: `make -j` then `out/Release/node test/parallel/test-perf-hooks-histogram.js` and the other three, plus `make lint-js`.
4. `git commit -s -F COMMIT-MESSAGE.txt <the four files>` (the `-s` sign-off is required by Node's commit-message lint).
5. Two ways to land it, your choice with the collaborators:
   - push it as a fixup commit on the bot PR (a collaborator did this for #66494 when it needed a header), or
   - open it as a separate PR with `PR-BODY.md` (edit the verification section to your own words) and ask that it land together with #66818.
6. Answer reviewers personally.

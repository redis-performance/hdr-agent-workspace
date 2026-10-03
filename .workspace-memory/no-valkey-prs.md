---
name: no-valkey-prs
description: Never open a pull request, issue or comment in Valkey (valkey-io) or Dragonfly (dragonflydb); work for them stays local
metadata:
  type: feedback
---

Do not open a PR or an issue (or post comments) in any `valkey-io` **or `dragonflydb`** repository, for any reason.
(The file name says Valkey because the rule started there; it covers both.)

**Why:** the user said so explicitly on 2026-10-02, while Redis, Valkey, memtier and Node.js vendored copies of
HdrHistogram_c were being compared: "make sure you dont open any PR to valkey. any issue!!". The user decides
what, if anything, goes to Valkey. Dragonfly was added on 2026-10-03 ("dragonfly is also offlimits"), right after it turned out
Dragonfly fetches HdrHistogram_c in its CMake build; checked that day: no PR, issue or comment from this account in either org.

**How to apply:** Valkey and Dragonfly work stays local and in this workspace repo (a written recipe, or a patch against a
local tree). Reading Valkey sources is fine. Before any `gh pr create`, `gh issue create` or `gh pr comment`,
check the target repo; if it is under `valkey-io` or `dragonflydb`, stop. Reading their sources and searching their code is fine. Related: [[hdr-upstream-prs]] for the PRs that are
allowed (HdrHistogram/HdrHistogram_c).

---
name: no-valkey-prs
description: Never open a pull request or issue against Valkey (valkey-io) from this workspace
metadata:
  type: feedback
---

Do not open a PR or an issue (or post comments) in any `valkey-io` repository, for any reason.

**Why:** the user said so explicitly on 2026-10-02, while Redis, Valkey, memtier and Node.js vendored copies of
HdrHistogram_c were being compared: "make sure you dont open any PR to valkey. any issue!!". The user decides
what, if anything, goes to Valkey.

**How to apply:** Valkey work stays local and in this workspace repo (a written recipe, or a patch against a
local tree). Reading Valkey sources is fine. Before any `gh pr create`, `gh issue create` or `gh pr comment`,
check the target repo; if it is under `valkey-io`, stop. Related: [[hdr-upstream-prs]] for the PRs that are
allowed (HdrHistogram/HdrHistogram_c).

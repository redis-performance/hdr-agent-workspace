---
name: merges-are-the-users
description: Do not merge pull requests from the agent; the auto-mode classifier blocks merges without review, the user merges
metadata:
  type: feedback
---

On 2026-10-02 the user said "no approval needed" about the release PRs, and I tried `gh pr merge --squash` on the version-bump PR
(#171). The auto-mode classifier denied it as "Merge Without Review". I stopped and did not look for another route; the user then
merged #171 themselves at 15:22 UTC, after `paulorsousa` had approved it (the reviewed path).

**Why:** a merge to the default branch of a public project is outward-facing and not reviewable after the fact; the harness treats
an unreviewed merge as needing the person.

**How to apply:** open the PR, get CI green, request the reviewer (the 0.12.0 PRs went: reviewer approves, user merges), then say it is ready and let the user merge. "No approval
needed" about a docs or release PR is not a licence to merge it myself. Tagging and publishing a release is a separate step that
needs an explicit go-ahead (it was given on 2026-10-02: "go ahead!"). Older workspace notes say the same ("agent merge denied by
classifier, left for the user"). See [[hdr-0.12.0-release]].

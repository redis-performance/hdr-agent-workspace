---
name: check-open-prs-before-raising
description: Always check open PRs/issues (and existing fix branches) before raising a finding again
metadata:
  type: feedback
---

Before reporting ANY analysis finding (bug, security gap, missing hardening, "should file an
issue"), first check whether it is ALREADY tracked upstream — open PRs, open issues, and
`fix/*` branches on `HdrHistogram/HdrHistogram_c`. Do NOT raise or propose filing something
that is already in flight.

**Why:** During the packed-histogram adversarial review, all 5 substantive dense findings
(#145–#149) turned out to be already-open PRs authored by the user themselves
(`fcostaoliveira` / `filipecosta90` / Filipe Oliveira — all the same person, a committer on
upstream). Filing issues would have duplicated the user's own in-flight work. Raising a
known/tracked item as if new wastes review effort and reads as not having done the diligence.

**How to apply:** As the FIRST step of any "found an issue / should we file this" analysis:
- `GH_TOKEN= gh pr list -R HdrHistogram/HdrHistogram_c --state all --limit 40 --json number,title,headRefName,author,state`
- `GH_TOKEN= gh issue list -R HdrHistogram/HdrHistogram_c --state all --limit 40`
- `git branch -r` / `git ls-remote --heads upstream 'fix/*'` and diff candidate branches vs `upstream/main`.
Map each finding to any existing PR/issue/branch and its author. Report only genuinely
un-tracked residuals; for tracked ones, say "already covered by #NNN" instead of re-raising.
Note that `fcostaoliveira`, `filipecosta90`, and `filipe@redis.com` are all the user.

See [[hdr-upstream-prs]] for the PR list and the `GH_TOKEN=` fallback pattern.

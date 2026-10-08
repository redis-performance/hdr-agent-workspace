---
name: go-pr-merge-authority
description: For hdrhistogram-go only, the user authorised PRs opened as fcostaoliveira and approved+merged as filipecosta90 after 4 review agents agree and CI is green
metadata:
  type: feedback
---

For `HdrHistogram/hdrhistogram-go`, the user said on 2026-10-07: "open the PRs as fcostaoliveira and approve/merge as
filipecosta90" and "if 4 subagents agree merge it". Every Go PR from #75 to #114 went that way: branch from `master`,
push to upstream `origin`, `gh pr create` as `fcostaoliveira` (switch the gh account, then switch back), a 4-agent
adversarial review with distinct lenses until all agree, CI green, then `gh pr review --approve` and
`gh pr merge --squash --delete-branch --match-head-commit <sha>` as `filipecosta90`.

**Why:** the user maintains the Go repo and wanted an author/approver split there.
**How to apply:** this is a scoped exception to [[merges-are-the-users]], which still holds for the C repo and
everything else. If a merge is blocked or the user's instruction may have changed, stop and ask. Releases and tags are
never covered: they need an explicit go each time (see [[hdr-go-maintainer-2026-10-07]]).

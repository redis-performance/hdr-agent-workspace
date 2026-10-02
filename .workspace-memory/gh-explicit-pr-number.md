---
name: gh-explicit-pr-number
description: Always pass an explicit PR number to gh pr edit/comment/view; an empty one silently targets the checked-out branch's PR
metadata:
  type: feedback
---

Never run `gh pr edit`, `gh pr comment` or similar with a number that comes from a variable without checking the variable
is non-empty, and prefer capturing the number from `gh pr create`'s output URL.

**Why:** on 2026-10-02 `gh pr list --head ... --jq '.[0].number'` returned nothing right after `gh pr create` (the new PR was not
indexed yet). The empty number made `gh pr edit --add-reviewer` fall back to the PR of the branch checked out in the
HdrHistogram_c checkout (`feat/packed-histogram`), the long-merged #150, and re-requested a reviewer there. I removed the
request again, but the notification may already have gone out.

**How to apply:** parse the PR number from the URL that `gh pr create` prints (`${url##*/}`), `test -n "$n"` before using it, and
pass `-R <owner/repo>` and the number every time. The HdrHistogram_c checkout normally sits on `feat/packed-histogram`, so
"current branch" defaults are wrong there. See [[use-oss-fleet-not-laptop]].

---
name: node-ai-policy-user-opens-prs
description: nodejs/node forbids PRs opened by automated tooling; prepare Node changes for the user to open and answer personally
metadata:
  type: feedback
---

On 2026-10-03 the user said "open PR to node". I did not run `gh pr create` against `nodejs/node`. Node's `doc/contributing/ai-guidelines.md`
(checked that day) says:
- "Pull requests must not be opened by automated tooling, unless specifically approved in advance by the project";
- AI-assisted changes must be disclosed, with what the contributor personally verified; responses to review feedback must be human,
  not automated; contributors who break this "may be blocked from further contributions";
- for-profit product names should stay out of commit messages (put them in the PR description only).

**Why:** the risk lands on the user's standing in a project they depend on, and an agent opening the PR is exactly what the policy
bans. The user's instruction did not account for it; I stopped before the outward step, prepared everything and explained.

**How to apply:** for any contribution to `nodejs/node`, prepare the patch, a Node-format commit message without product names, and a PR
description with the AI disclosure and a clearly marked slot for what the user verified (`experiments/NODE-UPDATE-0.12.0/`), then
hand it over with steps for the user to run. Do not fork-and-PR, comment, or reply to reviewers on their behalf. Check the target
project's contribution/AI policy before opening a first PR anywhere new. Related: [[no-valkey-prs]], [[merges-are-the-users]].

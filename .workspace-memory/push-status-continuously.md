---
name: push-status-continuously
description: User wants campaign status committed+pushed to the workspace repo continuously so other sessions can see it
metadata:
  type: feedback
---

Keep a `STATUS.md` in the active experiment folder and **commit + push to origin/main after
every meaningful step** (agents launched, reports landed, ballots, PR opened) — not only at
the end.

**Why:** (2026-09-30) several Claude sessions run against this workspace in parallel; the
user reads progress from git, not from the terminal. Another session had already pushed
ahead of this one (`git pull --ff-only` first, then push).

**How to apply:** `git pull -q --ff-only origin main && git add <paths> && git commit -q -m
"harden: <step>" && git push -q origin main`. Pull before every push. Never force-push.
Sanitize (public repo). See [[check-open-prs-before-raising]].

---
name: review-agent-disk-hygiene
description: Review/fuzz subagents filled the maintainer's disk once (26 GB of repo copies and private Go caches); how to scope scratch work
metadata:
  type: feedback
---

On 2026-10-07 a session's scratch directory reached 26 GB: each review agent copied the whole repo (with `.git`) and
used its own `GOCACHE`, and nothing deleted them. The disk filled, every shell command failed with ENOSPC (even the
user's `!` commands), and the user had to free space from another terminal.

**Why:** many parallel agents times a few hundred MB each, across several review rounds.
**How to apply:** tell agents to copy only tracked files (`git archive HEAD | tar -x -C DIR`), use the shared default
Go cache, cap fuzz runs, delete their copy before returning, and stop if under 5 GB is free; clean scratch after each
round. Heavy runs belong on the fleet anyway: [[use-oss-fleet-not-laptop]].

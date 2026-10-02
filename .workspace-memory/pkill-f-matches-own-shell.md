---
name: pkill-f-matches-own-shell
description: pkill/pgrep -f with a pattern that appears in the command being run kills or matches the agent's own shell; use exact PIDs or names
metadata:
  type: feedback
---

Twice on 2026-10-02 a `pkill -f "<pattern>"` or `pgrep -f` inside a longer Bash command matched that command's own shell (the
pattern text is in its command line) and ended the call with exit code 144. Process names are also truncated to 15 characters, so
`pkill -x` with a longer name matches nothing and says so only on stderr.

**How to apply:** stop things by PID you recorded when starting them, or by exact short name with `pgrep -x`; if a pattern is
unavoidable use the bracket trick (`[r]un_matrix`) so the command text does not match itself. Check that the process is really
gone afterwards. Never kill processes you did not start: this machine runs other sessions' work. Related: [[use-oss-fleet-not-laptop]].

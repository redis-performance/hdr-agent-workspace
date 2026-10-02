---
name: use-oss-fleet-not-laptop
description: Do not run builds, tests or benchmarks on the maintainer's own machine; use the OSS benchmark fleet
metadata:
  type: feedback
---

Do not run builds, test suites, fuzzers or benchmarks on the maintainer's own laptop. Any check that needs real compute
or a timing goes to the OSS benchmark fleet.

**Why:** the user said so on 2026-10-02, mid-way through the 0.12.0 release comparison, after a full Node.js build, several
Redis/Valkey/memtier builds and test runs, and the start of a benchmark matrix had already run on it. It is an interactive
machine (browser, calls) and a noisy and unfair benchmark host.

**How to apply:** reading files, `git` and `gh` read operations, and editing are fine. Before running anything heavier than
that, ask whether the fleet should be used. The connection method for the fleet is deliberately NOT in this public repo
(see experiments/C-HARDENING-2026-10-01/fleet/STATUS.md), so ask the user for it; do not search ssh configs, keys or the
network for it. Use the pinned, idle-gated method in experiments/C-HARDENING-2026-10-01/fleet/RUNNER-METHODOLOGY.md. Never
kill processes you did not start (other sessions run work on this machine); use exact PIDs or exact process names, never
`pkill -f` with a pattern that appears in your own command line. Related: [[benchmark-setup]], [[no-valkey-prs]].

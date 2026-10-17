---
name: local-ci-allowed-c-prs
description: "User explicitly allowed running builds/ctest/sanitizers locally for the HdrHistogram_c PR work (2026-10-16), overriding the earlier fleet-only rule for that work"
metadata:
  node_type: memory
  type: feedback
---

On 2026-10-16, while looping over C PRs #178/#179/#183/#184 and issue fixes #180-182, the user said "you can run CI locally! and make sure to cover all additions". This overrides the earlier "dont run stuff on my machine, use the oss fleet" rule ([[use-oss-fleet-not-laptop]]) for building and testing those C PRs (cmake builds, ctest, ASan/UBSan, -m32). Benchmarks and long fuzzing still belong on the fleet.

**Why:** CI round-trips were slow and the fleet host was not available; the user wants every addition (tests, CI jobs, docs) covered before pushing.

**How to apply:** build in /tmp/hdrt/ci/<pr>/, run ctest with gcc and clang ASan/UBSan (`-fsanitize=address,undefined,float-cast-overflow`) before each push. Also: for every behaviour change, map what Java, Go and Rust do before opening the PR, and put "affected versions" in each PR and issue.

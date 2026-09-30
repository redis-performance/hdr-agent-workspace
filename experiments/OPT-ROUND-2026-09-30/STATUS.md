# Post-merge C optimization check — 2026-09-30

Active comparison. No optimization is accepted by this round yet; the
workspace's accepted submodule pointer and experiment counts remain unchanged.

## Fixed source points

| Role | Commit | Meaning |
|---|---|---|
| Previous stable release | `18c7a324383dded1451d15621cd018b0048057d0` | upstream tag `0.11.10` |
| Previous master before batch merges | `4395fa0254d56ebacd81cd82e23fda346e1651c2` | includes #138/#139 read-scan work, excludes #140/#141 batch work |
| Latest master | `e4e8b0a41b4af56fddce5eebd1d0a53f29a0e988` | includes #140 and #141 |
| Future candidate, correctness reference | `bcb5c1f78f3ee50aaf33fb4898eb1c6bab73de13` | open #158, removes AVX2 negative-count branch and rejects negative records |

All four have isolated, detached C worktrees. The stable release remains an
unchanged reference rather than being merged into newer source: it is already
an ancestor of master, and merging it would not create a new comparison state.
The two immutable project benchmark drivers are byte-identical from 0.11.10
through current master.

## Measurement contract

- Run release CTest first for each source point. Run sanitizer and no-logging
  CTest for code selected for any new optimization or upstream PR.
- Compare the immutable write and single-percentile drivers, and a separately
  validated ordered-batch harness for #140/#141, in interleaved same-session
  measurements. Keep raw output and checksum equivalence.
- Run read/write profiles on the latest master to identify the next bottleneck.
  A surprising new bottleneck is a partial win requiring follow-up.
- This workstation is Apple silicon and has AppleClang only; it cannot execute
  the AVX2 branch or satisfy the mandatory native x86-64 gcc/clang performance
  and profile gates. Arm64 results are directional, not a MERGE-READY speed claim.
- Preserve the parent submodule pointer until a candidate passes both mandatory
  benchmark and profile gates and adversarial review.

Next: build/test the four points, run same-session baselines, then profile the
latest master and log any candidate/no-starter decision.

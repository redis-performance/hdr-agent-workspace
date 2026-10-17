# CPU MCP investigation — 2026-10-17

Scope: compiler diagnostics for dense/packed percentile loops and a cache-sensitive
audit of packed binary search. No optimisation accepted or library source changed.

- Upstream main verified through GitHub: `30e9ce6ef5dcdc60f9270e1ca03c0966eaaf71d0`
  (0.12.1); no open C PRs at the initial check.
- The workspace submodule is an older experiment. All new compilation uses a
  git-archive export of the verified release, not the checked-out source.
- Local compilation only: Apple Clang 17 and genuine GCC 14 are available.
  Clang can also emit x86-64 Darwin code. Native Linux fleet access requested.
- CPU MCP sources consulted: LLVM vectoriser documentation and Khuong/Morin's
  *Array Layouts for Comparison-Based Searching*.
- Packed count-width specialisation already exists. Branchless lower_bound,
  grandchild prefetch and linear-search experiments were previously rejected;
  this investigation audits their evidence without re-running rejected changes.
- In progress: reproducible diagnostics/assembly collection and workload audit.

No benchmarks or long fuzzing run on the workstation. No PR, release or upstream
write is part of this investigation.

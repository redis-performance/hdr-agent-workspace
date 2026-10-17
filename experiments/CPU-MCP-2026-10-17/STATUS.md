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
- Completed local exploration: [findings and reproduction](README.md).
- 24 successful compilation outputs: Apple Clang ARM64/x86-64 and GCC ARM64,
  O2/O3/Os plus compiler-only unrolling controls. Source hashes match throughout.
- Packed narrow-count scans lose SIMD under some O3 unrolling decisions;
  disabling unrolling/complete peeling restores it. No speed claim.
- Clang ARM64 already uses conditional selects for packed binary search; Clang
  x86-64 and GCC ARM64 O3 retain comparison branches.
- Untimed fixture audit reproduces 223/410/594 slots: active search indices only
  892/1640/2376 bytes. Random input does not establish cache-cold search loads.
  O2 and ASan/UBSan audit output match.
- Remaining evidence gaps: native Linux GCC/Clang code generation and actual
  fleet cache counters. No fleet host was supplied during this exploration.

No benchmarks or long fuzzing run on the workstation. No PR, release or upstream
write is part of this investigation.

Subsequent user-authorised Mac pilot: [result](mac/RESULT.md). Local A/A followed
by three ABBA rounds tested one crossing-loop pragma; SIMD restored, material
regressions observed, candidate rejected. The no-timings statement above describes
the original static investigation, not this separately authorised follow-up.

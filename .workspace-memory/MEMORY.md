# Workspace Memory — hdr-agent-workspace

- [Go packed master and deep-fuzz campaign](hdr-go-packed-fuzz-2026-10-07.md) —
  upstream Go `master` `5ffadfa` includes packed #75 and follow-ups through
  #103. Fork master was fast-forwarded and two remote deep-fuzz runs started;
  final outcomes pending. Workspace Go submodule updated to match.

- [ARM Clang percentile unroll investigation](hdr-arm-clang-scan.md) — causal
  control and narrow candidate: full O3 read 2.120x, unchanged write/Os and
  byte-identical GCC/x86 text. Early crossings can cost 0.6–0.7 ns more.
  Broader refactor rejected for AMD regression. Required Opus review hit quota;
  no MERGE-READY or source acceptance. User subsequently requested opening;
  [draft PR #167](https://github.com/HdrHistogram/HdrHistogram_c/pull/167) is open with pending gates disclosed.

- [C hardening and Redis/Valkey embedding](../experiments/C-HARDENING-2026-10-01/README.md) —
  pinned PR #158 consumer integration and binary-size matrix; preserve allocator
  adapters and iterator extension. Includes separate decoder/core-build PR plans
  and scoped Supabase assessment. Draft experiments, no optimization acceptance.
  [Native fleet results](../experiments/C-HARDENING-2026-10-01/fleet/RESULTS.md)
  now include Intel/AMD/ARM Os/O3 measurements at `d21d084`, actual consumer
  archives, profiles, inventories and CPU-pinning methodology. Clang ARM O3
  reads regress substantially; keep compiler defaults conditional.

- [Post-merge C optimization round](../experiments/OPT-ROUND-2026-09-30/STATUS.md) —
  0.11.10 stable release, pre-batch master, latest master, and future #158;
  arm64 directional measurement and native x86 gates tracked separately.

- [Issue #118 and macOS CI follow-up](../experiments/ISSUE-118-2026-09-30/STATUS.md) —
  current-main decoded-total overflow fix (#159) passed exact-head CI and
  native ASan/UBSan fuzz; Intel and ARM macOS CI coverage PR #160 passed
  exact-head CI. Both have commit-specific MERGE-READY comments. Full current
  main batch remains in progress; source CI still lacks this coverage until #160 merges.

- [Push status continuously](push-status-continuously.md) — commit+push STATUS.md after every step; other sessions read git

- [C PR review round, 2026-09-29](../experiments/PR-REVIEW-2026-09-29/README.md) —
  all 11 open C PRs, Paulo feedback, exact main CI crashes and combined-state
  validation; all 11 commented, eight branches fixed/pushed, five MERGE-READY,
  six NEEDS WORK. Native performance gates explicitly pending; #118 still reproduces.
- [W1/W2 measured qualification](../experiments/apple-m6/M6-WRITE-MEASURE/RESULT.md) —
  cleanup verified and Git pushes restored; both protocols calibrate 32/32, but
  both fail A/A precision on 26/32 controls. Discovery blocked; no source decision.
- [Apple M6 experiment loop](../experiments/apple-m6/STATUS.md) — plan, validation corrections,
  decoder repair, precise benchmark harness and publishing checkpoints.
- [M6 nine-agent population decision](../experiments/apple-m6/population/PLAN.md) —
  write-first W1/W2 queue, semantic probes, bounded calibration, independent ballots
  and stopped scan-family budget; planning only, no new accepted result.
- [M6 W1/W2 implementation checkpoint](../experiments/apple-m6/M6-WRITE-PREP/RESULT.md) —
  isolated write branches, exact rotated-write validation and sealed-build/cleanup
  gates; no timings, baseline promotion or PR. Batch timing explicitly disabled.
- [M6 write-control preparation](../experiments/apple-m6/M6-WRITE-CONTROLS/RESULT.md) —
  33 per-case fixtures, frozen descriptors/builds and bounded pilot controller;
  untimed/synthetic validation only. Case executor and confirmation still pending.
- [M6 case executor and cleanup](../experiments/apple-m6/M6-WRITE-EXECUTOR/RESULT.md) —
  sampler51776 exited143; auxiliary search termination unconfirmed. Six-pair
  case A/A/discovery implemented, 40 synthetic/unit tests pass, no timings.

Persistent memory index. One entry per file. Committed to main so all agent backends
share the same context. **Public repo — sanitize every entry** (no secrets/IPs/customer/
Slack/ticket references).

- [hdr-upstream-prs](hdr-upstream-prs.md) — fork PRs to HdrHistogram/HdrHistogram_c (#134/#135/#136 merged, #133 re-applied, #137 open) + how to open them
- [hdr-review-mo](hdr-review-mo.md) — @mikeb01's review M.O. + the adversarial correctness catches (offset-aware path, atomic twin, signed-shift rule)
- [benchmark-setup](benchmark-setup.md) — how to build + run the write/read benchmark drivers and measure cleanly
- [check-open-prs-before-raising](check-open-prs-before-raising.md) — RULE: check open PRs/issues/fix-branches upstream before raising or filing any finding (don't duplicate in-flight work; fcostaoliveira=filipecosta90=the user)
- [HdrHistogram campaign state](hdr-campaign-state.md) — cold-start snapshot: main sha, all open PRs, merge order, open decisions
- [No PRs or issues to Valkey or Dragonfly](no-valkey-prs.md) — never open a PR/issue/comment in valkey-io or dragonflydb; their work stays local
- [Use the OSS fleet, not the laptop](use-oss-fleet-not-laptop.md) — no builds/tests/benchmarks on the maintainer's machine; ask for fleet access, don't hunt for it
- [Pass explicit PR numbers to gh](gh-explicit-pr-number.md) — an empty number targets the checked-out branch's (merged) PR; capture it from gh pr create's URL
- [HdrHistogram_c 0.12.0 released: cold-start snapshot](hdr-0.12.0-release.md) — what shipped, numbers, where things live, open items (start here)
- [Who embeds HdrHistogram_c and how to switch](consumers-vendored-hdr.md) — Redis, Valkey, memtier, Node.js, Dragonfly: tested drop-in recipes and patches; nothing adopted yet; never PR Valkey or Dragonfly
- [Merges are the user's](merges-are-the-users.md) — agent merges are blocked; reviewer approves, user merges; publishing needs an explicit go
- [pkill -f matches your own shell](pkill-f-matches-own-shell.md) — use PIDs or exact short names; never kill other sessions' processes
- [Release notes scope and verification](release-notes-scope.md) — docs/version PRs excluded, British spelling, three-pass check, precise perf claims
- [Node: the user opens PRs, not the agent](node-ai-policy-user-opens-prs.md) — nodejs/node bans PRs opened by automated tooling; prepare, disclose, hand over

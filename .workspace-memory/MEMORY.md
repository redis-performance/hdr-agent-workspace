# Workspace Memory — hdr-agent-workspace

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

# Issues #173 / #174 / #116 — percentile p0 and empty-histogram contracts

Base: upstream main `8885476` (0.12.0). Started 2026-10-15.

- #173 — batch p0 returns upper bucket boundary; singular returns lower.
- #174 — empty batch query returns unresolved rank targets (1) with success.
- #116 — empty scalar query returns resolution-dependent bucket edge (63 with lowest=100).

Plan: one independent 7-agent pipeline per issue (1 reference-semantics researcher,
3 independent implementers, 3 lens-specific adversarial reviewers). Lightweight
single-TU compiles only on the workstation; perf gate and full sanitizer/fuzz runs on the fleet.

## Log
- 2026-10-15: pipelines launched.
- 2026-10-15: round 1 done (21/21 agents). All three issues converged on one library change each:
  - #173: the batch API uses the singular p0 rule (exact `== 0.0` takes the lowest equivalent value) at the block, tail and iterator emit sites. Reviewers picked the test-first candidate, with grafts.
  - #174: a fill loop after the scan, so a slot the scan never reaches no longer leaks its scratch rank target.
  - #116: an early `total_count == 0` return in the singular API.
- Finding: the upstream packed histogram documents bit-for-bit parity with dense. Its batch call already uses the p0 rule, and on an empty histogram it returns `highest_equivalent_value(0)`.
  - Decision: #174 fills unresolved slots with the value the singular API returns, so dense batch, dense singular and packed batch agree, with no compat change.
  - #116 stacks on #174 and changes the empty result to 0 for dense and packed, singular and batch (explicit compat note).
- Round 2 (3 finalisers + 1 integration check) launched.

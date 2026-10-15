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

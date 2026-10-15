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
- 2026-10-15: round 2 done. Final patches are in `patches/`: 173 and 174 are each based on upstream main, and 116 stacks on 174. Commit and PR texts are drafted.
  - Workstation light checks: no warnings with `-Wall -Wextra -Wshadow -Wpedantic -Wmissing-prototypes`, and every suite passes under ASan+UBSan (dense 46, packed 27, packed core, log 34).
  - Differential check of the full stack: 972 rows, 0 mismatches across dense singular, dense batch, packed singular and packed plural.
  - Non-empty, non-p0 results are byte-identical to upstream (504/504).
  - 173 and 174 conflict only on the `all_tests` context line; the rebased version is in `patches/174-on-173.patch`.
  - Still owed on the fleet: read-path perf gate (base vs patch, back to back), the cmake ctest matrix, and an x86 AVX2 build.
- Awaiting user: the empty → 0 compatibility decision (#116), and the go-ahead to push branches and open PRs.
- 2026-10-15: user approved the #116 empty → 0 change and the PRs. Draft PRs opened upstream from the fork:
  - #175 (#173): `fix/batch-p0-lowest-equivalent`
  - #176 (#174): `fix/batch-unresolved-percentiles`
  - #177 (#116): `fix/empty-percentile-zero`, stacked on #176
  - Pending before ready-for-review: CI, and a read-path perf gate on the fleet.
  - Whichever of #175/#176 merges second needs a one-line rebase of the `all_tests` list; #177 needs a rebase after #176 merges.
- 2026-10-15: CI green on #175, #176 and #177 (32/32 checks each). Still pending: the fleet read-path perf gate.
- 2026-10-15: bot first-pass review on each PR handled.
  - #175: the test-leak fix (8fe416d) is pushed.
  - #176: Java/Rust/Go citation posted; no code change.
  - #177: the dense batch now returns early on an empty histogram (e67758a), replacing the nested ternary. This also removes the empty `-inf` NaN-cast UBSan report. Stale comments fixed, test renamed, packed recorded-0 parity added.
  - PR bodies now carry release-note lines.
- 21 adversarial review-skill agents (7 per PR) reviewed the heads before these pushes: 21/21 MERGE-READY, 0 blocking.
- Non-blocking items left for the maintainer:
  - squash on merge (no force-push);
  - #176 test size and ternary layout (left alone to avoid rebasing the stacked #177);
  - pre-existing, out of scope: `-inf` UB on nonempty histograms; p100 target above 2^54; unsorted input together with under-filled counts.
- 2026-10-15: user said go: #175/#176/#177 marked ready for review with reviewer paulorsousa. The read-path perf gate is still listed as pending in each body. The user merges.

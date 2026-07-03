# Autonomous Go-improvement loop (3h) — started 2026-07-03

Rules: small focused PRs off master, FULL unfiltered `go test ./...` + vet + gofmt,
adversarial review before PR, avoid #49 concurrency (user opt-out), avoid conflicts
with open PRs (#64/#65/#66/#67/#68) where possible.

Backlog (from GO-HARDENING-PLAN.md + audit critic):
- [ ] C8: Reset() clears tag/startTimeMs/endTimeMs (doc says "original state")
- [ ] D3: hdr_benchmark_test.go dead fill loop panics when b.N > 1e6
- [ ] New() argument validation + tests (lo>=hi, negative, sig edges)
- [ ] Coverage: zigzag all-lengths, buckets overflow guard, RecordCorrectedValue error path
- [ ] C7: RecordValues rejects negative n (overlaps #64 RecordValues — stack/coordinate)
- [ ] D2: log_reader final interval line without trailing newline (overlaps #65 log_reader)
- [ ] D1: Decode memory-amplification absolute geometry cap (overlaps #65 Decode)
- [ ] ValueAtQuantile NaN/Inf quantile edges
- [ ] Golden/cross-port encode vectors; strengthen weak tests

## Iterations

### Turn 1 (2026-07-03)
- [x] C4 coordinated (all 3 percentile APIs reach min) -> PR #68 (stacked on #67)
- [x] C8 Reset clears tag/start/end time -> PR #69
- [x] D3 benchmark dead-loop panic (b.N>1e6) -> PR #70
Pending review: #68/#69/#70 (self-verified + regression tests; adversarial review queued).
Next: New() arg validation, coverage tests (zigzag/buckets/RecordCorrectedValue), C7, D2, D1,
  ValueAtQuantile NaN, golden vectors, + adversarial reviews of the loop PRs.

### Turn 2-3 (2026-07-03)
- Reviews (worktree-isolated): #68 C4 MERGE-READY (1 nit -> added clarifying comment be1cefd),
  #69 Reset MERGE-READY (no findings), #70 bench MERGE-READY (no findings).
- [x] Coverage boost -> PR #71 (test-only): zigzag 1..9-byte ladder, New/MaxInt64 overflow guard,
  RecordCorrectedValue out-of-range, Merge dropped. Total coverage 85.9% -> 87.8%; targeted funcs
  zig_zag_encode/getBucketsNeeded/Merge now 100%.
- Probed New() degenerate args (lo>=hi, lo==hi): NOT a bug (builds a permissive histogram, no panic;
  negative values rejected on record). No New error-return without an API break -> skip.
Next: log-reader golden VALUES (strengthen weak err-only tests), then D2 (last-line-no-newline,
  coordinate with #65), C7 (negative n, stack on #64). Avoid #66-conflicting golden-encode vectors.

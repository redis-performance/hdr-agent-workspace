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

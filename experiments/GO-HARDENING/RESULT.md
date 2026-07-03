# GO hardening iteration — result (2026-07-03)

Driven by the 69-agent audit (experiments/GO-HARDENING-PLAN.md). Delivered as two
focused, adversarially-reviewed PRs off master.

## PR #65 — safety + fuzzing (branch perf/harden-decode-fuzz)
Fixes 6 execution-proven panics in the public Decode()/log-reader path on untrusted input:
- Decode: len<8 guard, negative-length guard, decompressed<40 guard, decode-loop bounds check
- log reader: "Tag=" no-comma skip
Adds native Go fuzzers (FuzzDecode/FuzzLogReader/FuzzRecordEncodeDecode/FuzzZigZagRoundTrip)
+ crash regression tests + ClusterFuzzLite + fuzz-smoke/-race CI (repo had ZERO fuzzing).
Review: NEEDS WORK (cflite branch main->master + neg-length msg) -> fixed -> hardening MERGE-READY.

## PR #66 — correctness/interop (branch fix/correctness-mean-offset-basetime)
- Mean(): int64 count*value product wrapped -> do multiply in float64.
- getNormalizingIndexOffset(): returned 1 (serialized with unrotated counts -> C/Java misplace
  buckets) -> return 0. Go ignores field on decode, round-trip unaffected.
- OutputBaseTime: "#[Basetime:" -> "#[BaseTime:" (reader regex + Java convention).
Each with a regression test proven to fail on pre-fix code. Review: MERGE-READY (reviewer reverted
each hunk to confirm tests catch the bugs; offset=0 verified correct + backward-compatible).

## Deferred to a follow-up (in GO-HARDENING-PLAN.md)
Percentile-contract fixes C4/C5/C6 (need per-API analysis; the New(100,...) unitMagnitude>0 case),
C7 (negative n), C8 (Reset metadata), D2 (last-line-no-newline), D3 (benchmark dead loop),
Phase-3 coverage/test-quality tests, D1 memory-amplification (needs an absolute geometry cap, not
the unsound payload-ratio guard the critic rejected), and the decode-side normalizingIndexOffset
handling for foreign rotated histograms.

## Open-issue triage (2026-07-03) + closures
Checked all 8 open hdrhistogram-go issues against current master:
- #60 (empty hist -> non-zero percentile): VALID, reproduced -> FIXED in PR #67 (empty guard).
- #61 (OutputStartTime local TZ): VALID -> FIXED in PR #66 (.UTC()).
- #49 (windowed panic index-oob): crash signature GONE (#57 removed the function) but the
  Rotate() concurrency root cause remains (window.go:43-44 unsynchronized) -> status note posted;
  do not close as fixed. #65's -race CI job would catch regressions.
- #24 (timestamps since epoch): still open; references PR #23 which is still OPEN/unmerged.
- #28 (Record Float64/DoubleHistogram), #36 (PackedHistogram), #50 (compare images): valid,
  unimplemented feature requests.
- #32 (repo transfer umbrella): stale/informational (transfer done long ago).

New PR: #67 fix/percentile-contracts (empty #60 + negative clamp + map phantom key). Review MERGE-READY.

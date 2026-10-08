---
name: hdr-go-packed-fuzz-2026-10-07
description: Upstream Go packed merge, exact source pin, and remote deep-fuzz runs
metadata:
  type: project
---

Upstream `HdrHistogram/hdrhistogram-go` master on 2026-10-07 advanced from
`5ffadfa738fb405cc82c03ddee883f4ab0767311` to
`de66007797627c8a917da9804fb2a1e681d6df8f` (#105). PackedHistogram #75 merged
at `048a618`; #76/#78/#79 added sustained fuzz infrastructure; #80/#103
hardened decoding and edge cases; #81–#83 added packed APIs and docs.
Packed compatibility follow-up #105 is merged; #108 and #109 are open.

The account has no upstream Actions dispatch permission (HTTP 403), but has
admin permission on the fork. Fork `master` was fast-forwarded to the exact
upstream head. Remote [native Go fuzz run](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37627334235)
has 300 minutes per each of 10 targets; remote [ClusterFuzzLite ASan run](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37627349749)
has 3600 seconds shared among those targets. Both **passed** on `5ffadfa`;
the native run passed all ten targets. The detailed public ledger is
[experiments/GO-FUZZ-2026-10-07/STATUS.md](../experiments/GO-FUZZ-2026-10-07/STATUS.md).

Additional workflow-only fork branches were pushed for [Linux ARM64](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37628119727)
(`5adc996`, 300 minutes × 10 targets) and [macOS ARM64](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37628225525)
(`e6d836a`, 120 minutes × 10). Both retain upstream Go source `5ffadfa`.
The Linux ARM64 run found one `FuzzPackedDifferential` worker exit after 3h31m;
the saved 174-byte input is in the ledger, and [short ARM replay](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37678381782)
passed. Five-hour targeted reruns on [old source](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37678836636)
and [new source](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37678879828)
are queued. Do not call this a confirmed library defect or a clean ARM run. macOS
jobs remain in progress. The fork and workspace Go submodule now match #105's
`de66007`, with new [native](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37678533498)
and [ASan](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37678544853)
campaigns pending. The separate OSS fleet connection is not recorded in
this public repo; no local fuzzing was run.

Keep builds/tests/fuzzers on remote infrastructure, never this workstation.

## Fleet deep fuzz finished 2026-10-08
6 h x 10 targets on three fleet VMs at `de66007`: 30/30 PASS, no failures. arm64 was about 150x slower per second (0.76 M
`FuzzPackedDifferential` executions vs 172 M Intel, 271 M AMD), so it did not reach the 55 M depth of the earlier GitHub ARM
failure, which stays unexplained and un-filed. Next if wanted: a dedicated ARM `FuzzPackedDifferential` run, after finding why
arm64 fuzzing is slow. Scripts: `scripts/fleet-go-fuzz.sh`, `scripts/fleet-go-repro.sh`. Details: FLEET-DEEP-FUZZ-RESULT.md.

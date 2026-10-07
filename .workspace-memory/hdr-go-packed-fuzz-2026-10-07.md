---
name: hdr-go-packed-fuzz-2026-10-07
description: Upstream Go packed merge, exact source pin, and remote deep-fuzz runs
metadata:
  type: project
---

Upstream `HdrHistogram/hdrhistogram-go` master on 2026-10-07 is
`5ffadfa738fb405cc82c03ddee883f4ab0767311`. PackedHistogram #75 merged
at `048a618`; #76/#78/#79 added sustained fuzz infrastructure; #80/#103
hardened decoding and edge cases; #81–#83 added packed APIs and docs.
Packed compatibility follow-up #105 is open.

The account has no upstream Actions dispatch permission (HTTP 403), but has
admin permission on the fork. Fork `master` was fast-forwarded to the exact
upstream head. Remote [native Go fuzz run](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37627334235)
has 300 minutes per each of 10 targets; remote [ClusterFuzzLite ASan run](https://github.com/fcostaoliveira/hdrhistogram-go/actions/runs/37627349749)
has 3600 seconds shared among those targets. Both were in progress at launch;
do not report success before checking final job conclusions, corpus summaries,
and any crash artifacts. The detailed public ledger is
[experiments/GO-FUZZ-2026-10-07/STATUS.md](../experiments/GO-FUZZ-2026-10-07/STATUS.md).

Keep builds/tests/fuzzers on remote infrastructure, never this workstation.

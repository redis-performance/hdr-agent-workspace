---
name: hdr-go-maintainer-2026-10-07
description: Go upstream maintenance session 2026-10-07/08 — what merged up to 1608007, user policy choices, v1.4.0 hold and its release-note content
metadata:
  type: project
---

Upstream `HdrHistogram/hdrhistogram-go` `master` is `687f303` (2026-10-08, #117). Merged in this session: #75 (packed),
#76/#78/#79 (fuzz CI), #80–#83, #103, #105, #109, #112, #114, #115, #116, #117; the user merged #108. A reusable 4-agent
review script is `scripts/go-pr-review-workflow.js`. Issues #36, #49, #50, #77, #84–#102,
#106, #107, #110, #111 and #113 are closed. Latest release is still v1.3.0.

**v1.4.0 was released on 2026-10-08** at `687f303` (the user said "release now"), after #115-#117 merged. Post-release
fuzzing of `687f303` passed (native 60 min x 10 targets, ClusterFuzzLite ASan batch, scheduled CFLite batch and prune). Future releases
still need an explicit OK each time ("dont release without my ok!"); never publish or tag without it. The required release-note content is in
[experiments/GO-MAINTAINER-2026-10-07/STATUS.md](../experiments/GO-MAINTAINER-2026-10-07/STATUS.md); Release Drafter
overwrites its draft, so write the notes by hand.

User policy choices: decoders support Java 0-digit streams exactly (constructors still clamp); keep Go/C nearest-rank
percentiles and document Java's divergence; preserve the V2 conversion ratio; both decoders ignore
`normalizingIndexOffset`.

**Why:** cold-start context so a new session does not re-derive or re-litigate these.
**How to apply:** read the STATUS page first; verify against GitHub; follow [[go-pr-merge-authority]] for PRs.
Related: [[hdr-go-packed-fuzz-2026-10-07]], [[review-agent-disk-hygiene]].

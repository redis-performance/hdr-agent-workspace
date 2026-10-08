---
name: hdr-go-maintainer-2026-10-07
description: Go upstream maintenance session 2026-10-07/08 — what merged up to 1608007, user policy choices, v1.4.0 hold and its release-note content
metadata:
  type: project
---

Upstream `HdrHistogram/hdrhistogram-go` `master` is `1608007` (2026-10-07, #114). Merged in this session: #75 (packed),
#76/#78/#79 (fuzz CI), #80–#83, #103, #105, #109, #112, #114; the user merged #108. Issues #36, #49, #50, #77, #84–#102,
#106, #107, #110, #111 and #113 are closed. Latest release is still v1.3.0.

**v1.4.0 is ON HOLD** until the user says go ("dont release without my ok!"; "i have multiple sessions fixing things").
Never publish a release or push a tag without that explicit OK. The required release-note content is in
[experiments/GO-MAINTAINER-2026-10-07/STATUS.md](../experiments/GO-MAINTAINER-2026-10-07/STATUS.md); Release Drafter
overwrites its draft, so write the notes by hand.

User policy choices: decoders support Java 0-digit streams exactly (constructors still clamp); keep Go/C nearest-rank
percentiles and document Java's divergence; preserve the V2 conversion ratio; both decoders ignore
`normalizingIndexOffset`.

**Why:** cold-start context so a new session does not re-derive or re-litigate these.
**How to apply:** read the STATUS page first; verify against GitHub; follow [[go-pr-merge-authority]] for PRs.
Related: [[hdr-go-packed-fuzz-2026-10-07]], [[review-agent-disk-hygiene]].

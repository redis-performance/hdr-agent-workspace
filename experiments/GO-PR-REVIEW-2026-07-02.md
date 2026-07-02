# Go open-PR adversarial review round — 2026-07-02

7 subagents, `hdr-reviewer-go` skill, one maintainer lens each, across the 3 open PRs on
HdrHistogram/hdrhistogram-go. dkropachev requested (via @mention comment — pull-only access,
can't formally request reviewers).

## Panel results

| Agent | PR | Lens | Verdict | Key finding |
|-------|----|------|---------|-------------|
| 1 | #57 | filipecosta90 | MERGE-READY | reproduced ~+100%; differential over 5 configs byte-identical |
| 2 | #57 | dkropachev | **NEEDS WORK** | **dead `getCountAtIndexGivenBucketBaseIdx` → golangci-lint unused → CI red** |
| 3 | #57 | ahothan | MERGE-READY | 2000-config × all-edge-percentile differential, zero mismatches |
| 4 | #58 | filipecosta90 | **NEEDS WORK** | **empty histogram (unitMagnitude>0) → 63 instead of 0** (contract break) |
| 5 | #58 | codahale/spec | MERGE-READY | batch==singular on populated; bench ~+350% |
| 6 | #58 | dkropachev | **NEEDS WORK** | same dead method; map already pre-sized (nit was moot) |
| 7 | #23 | dkropachev/codahale | **BLOCK / close** | fails on master, API misuse, false-green, superseded by #51/#54 |

## Two real bugs caught in our own PRs → fixed

1. **Dead code (lint blocker, #57/#58).** `getCountAtIndexGivenBucketBaseIdx`'s only caller was the
   loop the flat scan replaced. `golangci-lint unused`/U1000 (CI `make lint`) would go red.
   → Deleted it. #57 `ca1ed92 → 3e20c1f`.
2. **Empty-histogram regression (#58).** The flat scan lost the iterator's `limit==0` short-circuit;
   an empty histogram with `lowestDiscernibleValue>1` returned `highestEquivalentValue(0)` (e.g. 63)
   instead of the documented 0's. → Added `if h.totalCount == 0 { return }` + regression test
   `TestValueAtPercentiles_EmptyHistogram`. #58 rebased on #57, `→ 0a4452f`.

Both branches force-pushed; PRs updated with explanatory comments. Local: build/vet/tests green,
dead code gone. (Singular #57 is byte-identical on empty/p0 — no fix needed; C #140 dodges this by
clamping the target count to ≥1.)

## #23 (okayzed) — recommend closing
`TestTimeStamps` fails on master (author-acknowledged): passes a ~1.5e9 value as
`lowestDiscernibleValue`, overflowing the int32 bucket math → MaxInt32; the "ms" case is false-green
(out-of-range records silently dropped, oversized tolerance hides it); doesn't test timestamp
*serialization* (superseded by dkropachev #51/#54); stale (2016), non-gofmt/lint-clean.

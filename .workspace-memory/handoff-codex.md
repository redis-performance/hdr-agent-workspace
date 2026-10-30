---
name: handoff-codex
description: Cold-start handoff for a Codex (or any non-Claude) agent, state as of 2026-10-30 (C 0.12.1 released, Node test-fix PR waiting, valkey tail-shortcut plan written, Go #119 pending)
metadata:
  type: project
---

# Handoff for Codex, 2026-10-30

Read `AGENTS.md` first (shared rules). This file is the state; **verify on GitHub before acting**, it is a snapshot.
Supersedes the 2026-10-17 version (that content is folded in below).

## Standing rules that bite most (full list in AGENTS.md)
- The user merges PRs in `HdrHistogram/*` (Go has a scoped exception: `go-pr-merge-authority.md`). Never tag or release unprompted.
- **Never post anything** (PR, issue, comment) in `nodejs/node`, `valkey-io/*`, `dragonflydb/*`. Prepare text; the user posts.
- Benchmarks and long fuzzing run on the OSS fleet. Fleet hosts are not in this repo: **ask the user** which host.
- No force-push. Always pass explicit PR numbers to `gh`. British spelling. Terse comments (@mikeb01).
- Repo is public: no secrets, emails, hostnames, ticket references.

## State by workstream

### C (HdrHistogram_c)
- **0.12.1 is released** (tag `0.12.1` on `30e9ce6`). Notes and evidence: `experiments/RELEASE-0.12.1/`.
  Behaviour changes: empty `hdr_min` is 0 (was INT64_MAX); empty `hdr_mean`/`hdr_stddev` are 0.0 (was NaN); empty
  percentiles 0; batch p0 equals the single call; percentile rank clamped (no UB). Speed vs 0.11.10: about 2x single
  percentile calls, 15-20x batch; write unchanged. Charts include 0.11.10.
- **README PR #186** (0.12.1 charts and data): open, unmerged. The user should check the image links in the PR preview.
- **New plan, no code yet:** `experiments/VALKEY-5024-TAIL-SHORTCUT-PLAN/README.md` (commit `7a9932d`). Seven-lens review of
  what valkey PR #5024 does (start the scan at the min bucket; return the max bucket directly when the rank falls in it)
  and what applies to our `hdr_value_at_percentile`. Verdict: prototype a **backward scan from the max bucket for high
  percentiles** first; valkey's `max_value` shortcut second; skip-leading-zeros low value; caching rejected. It is only valid
  when `total_count == sum(counts)` and all counts are non-negative, so it must fall back to the existing scan otherwise;
  honour `normalizing_index_offset`; validate `max_value`. Decision rule inside (>= +2% on p99+ on every machine, <= 1%
  regression on mid percentiles, <= ~25 lines, bit-identical in a differential test, MERGE-READY). **Blocked on the user naming a fleet host** (x86 AVX2 and aarch64).
  Line numbers in the plan are from the local `feat/packed-histogram` checkout, not upstream master: re-anchor first.

### Node.js (consumer adoption)
- **nodejs/node#66818** (bot: bump histogram to 0.12.1): open, approved (one review), **4 test jobs red** because four tests pin the
  old empty-histogram values. Last change: the bot's re-push 2026-10-25 00:54Z (`1fc5630f0`).
- **nodejs/node#66879** (the user's test fix, 4 test files, 13 lines): open, no human review or response since it was opened
  (about 9 days), label `needs-ci` (full CI has not run). 24 checks pass, 8 Nix build jobs fail; inferred (not confirmed) to be
  the new expectations running against Node main's old histogram, so they should clear once #66818 lands. It is a lockstep
  dependency: it must land with or before #66818.
- Files: `experiments/NODE-UPDATE-0.12.1/` (README, patch, commit message, `PR-BODY.md`, `HOW-TO-OPEN.md`, `prepare-node-pr.sh`).
  The user still has to fill the bracketed verification/AI-disclosure section in the PR body and run `make lint-js`.
- **Waiting on the user:** a draft comment asking a collaborator to start full CI on #66879 (not drafted yet; offer it).
- Node's AI policy forbids AI-opened PRs/comments: the user posts everything.
- Polling (read-only) that was run hourly until 2026-10-30 and is now **stopped**:
  `gh pr view N --repo nodejs/node --json state,reviewDecision,mergeable,updatedAt,labels,reviews,comments` and
  `--json statusCheckRollup` grouped by conclusion, for N in 66879 66818. `mergeable` flips between MERGEABLE and UNKNOWN
  whenever Node main moves; that is GitHub recomputing, not a conflict.

### Go (hdrhistogram-go)
- v1.4.0 released at `687f303`. Issue #118 filed; mitigation **PR #119** open, pending the user's decision on repeated-engine-death
  tracking. Then: re-run the four reviews on `c872123`, wait for CI, merge only if all four are MERGE-READY (scoped Go authority).
- Go `Max()` on an empty histogram returns a positive value (63 at lowest 100): documented policy from #91/#105, **no issue wanted**.
- Possible: re-measure PackedHistogram write cache (#117) on current master.

### Valkey
- Valkey bundles a 2022 customised copy of hdr in `deps/hdr_histogram` (base `e4448cf`, 86 commits behind upstream tip; no AVX2 path,
  still `min_value = INT64_MAX`). Neither #5024 nor #4631 touches `deps/`. #5024 reimplements the percentile walk in `server.c`.
- Idea not yet acted on: a **local, unposted** draft note that valkey could take 0.12.x (about 2x single, 15-20x batch) or call the
  batch API. The user has not said which PR they meant (#4631 or #5024) or whether they want the draft. Nothing may be posted to valkey-io.

### Agent setup
- `AGENTS.md` (Codex reads natively), `.claude/CLAUDE.md` imports it, `.workspace-memory/` is shared memory, `scripts/agent-run.sh`
  shim with `AGENT=claude|codex`. **The Codex backend of the shim has never been run for real**; test it
  (`AGENT=codex scripts/agent-run.sh <skill>`) before relying on it.

## Open decisions (the user's, do not decide)
- C NaN percentile: C returns p100; Java, Rust, Go return the first bucket. Aligning C is its own behaviour-change PR.
- Reopen C #98 until `-latomic` is confirmed on real 32-bit ARM/RISC-V (verified on x86-64 + forced-probe CI only)?
- Go ARM64 `FuzzPackedDifferential` worker exits (~55 M execs) unexplained and un-filed; file only if a deep ARM run reproduces.
- Valkey: which PR, and whether to draft the upgrade note.

## Possible next work (after the user's go-ahead)
- C tail-scan prototype per the plan above (needs a fleet host).
- C: signed overflow at `h->total_count += value` in `counts_inc_normalised` when the total is already INT64_MAX (unfiled, low priority).
- C: the double-to-int64 cast of the percentile rank is UB for a NaN percentile in `hdr_value_at_percentile` (the packed type guards it); separate fix and test.
- Read the macOS job log for nodejs/node#66818 (never read).
- Redis-ecosystem Go bumps (redis-benchmark-go, ftsb: branches pushed, PRs not opened); second consumer group not started.
- Memory hygiene: `hdr-upstream-prs.md` may be stale (C PRs #137-#141 were reported merged upstream by a reviewer; verify on GitHub before editing).

## Working-tree notes for whoever picks this up
- `git status` shows `M HdrHistogram_c` and `M hdrhistogram-go` (submodule pointers moved by earlier work) and an untracked
  `prepare-node-pr.sh` at the repo root (probably the user's downloaded copy). None of these were committed on purpose: ask before staging them.
- Workspace `main` was level with `origin/main` at `7a9932d` when last checked.

## Parity checklist (Claude and Codex must behave the same)
- Claude-only today: `.claude/settings.json` permissions, `/name` skill invocation, subagent fan-out, `/loop` and cron.
  Codex equivalents: run the skill file as a prompt, do review lenses as sequential passes, poll by hand.
- `~/.codex/config.toml` is the user's; do not edit it. Pick a sandbox that allows git and gh but keep the standing rules above.
- Anything learned that another agent needs goes in `.workspace-memory/`, not in tool-private memory.

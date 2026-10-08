# Moving hdrhistogram-go users to 1.4.0 (and off the old import path): assessment, 2026-10-08

Nothing was opened or commented anywhere. Read-only checks of public repositories (GitHub code search, `go.mod` and contributing files, existing PRs).
Method limits as in `GO-USERS-2026-10-08.md`: code search is capped and misses vendored or private code; "no import found" is not proof of absence.

## Three facts that shape this

1. **v1.4.0 does not exist yet** (the draft is prepared in `RELEASE-GO-1.4.0/`). No project can pin it today. v1.3.0 is available now.
2. **Almost nobody calls the functions that got 4 to 6x faster.** Call sites found: `ValueAtQuantile` / `ValueAtPercentile` (singular, unchanged since 1.3.0) in liftbridge,
   junodb, oxy, go-wrk, sonic, go-ycsb, go-tpc, ftsb; `ValueAtPercentiles` only in redis-benchmark-go. A bump to 1.4.0 therefore changes their speed by about 0, and
   `RecordValue` is 2 to 4% slower than 1.3.0 on Intel and Arm. Projects pinned at v1.1.2 or older (14 of 30 direct users) do gain 1.3.0's single-query speedups and every fix since.
   These tools compute percentiles at report time, so the absolute saving is small either way. **The honest case for these PRs is fixes and hardening, not speed**;
   a speed claim only holds if a project is changed to ask for several percentiles in one call (`ValueAtPercentilesSlice`).
3. **Four of the five "old path" projects do not import it.** Code search finds no Go file importing `github.com/codahale/hdrhistogram` in flipt, perforator, bee or the
   Mattermost playbooks plugin, only a `go.mod` line, so it is almost certainly transitive (for example through tracing libraries; flipt already replaced its own use in
   its PR #529). There is nothing in those repositories to migrate; not verified with `go mod why`, which needs a checkout and a Go toolchain.

4. **Update 2026-10-08 (v1.4.0 published, checked on the fleet):** `go get ...@v1.4.0` raises a project's `go` directive to **1.23.0**. In `redis-benchmark-go` that is `go 1.21` -> `go 1.23.0` and its CI
   matrix (1.20.x and 1.21.x) cannot build it, so the PR also moves the matrix. Every other project on this list whose `go.mod` says less than 1.23 faces the same cost; ftsb already declares 1.23.0.
   Validation done for the two Redis-ecosystem projects: `experiments/GO-CONSUMERS-REDIS-2026-10-08/` (ftsb 62/62 tests before and after, redis-benchmark-go `make test` passes before and after).

## Per project

| Project | What it is really | Gain from the bump | Friction | Verdict |
|---|---|---|---|---|
| vulcand/oxy | direct, calls `ValueAtQuantile`, `Merge`, `Export`/`Import`; already on v1.3.0 (its #218 "chore: update hdrhistogram") | fixes only | none seen; it tracks the library itself | wait for the tag, it will likely bump itself; a PR is optional |
| tsliwowicz/go-wrk | direct, `ValueAtPercentile` x7, v1.2.0; has an open PR #34 "Fix HistogramValueAtPercentile arguments" | fixes | small repo, active (2026-07) | good candidate, look at #34 first |
| talostrading/sonic | direct, 38 `ValueAtPercentile` calls, v1.1.2 | 1.3.0 single-query speedup + fixes | none seen | good candidate |
| pingcap/go-ycsb, pingcap/go-tpc | direct, singular percentile calls, v1.1.2 / v1.2.0 | fixes (go-ycsb also 1.3.0 speedup) | no CLA or AI rule found; last pushes 2025-12 / 2026-01 | good candidates |
| RediSearch/ftsb | direct, `ValueAtQuantile`, v1.0.1 | 1.3.0 speedup + fixes | Redis org, no rules found | good candidate |
| redis-performance/redis-benchmark-go | direct, the only caller of `ValueAtPercentiles`, v1.1.0 | the 4 to 6x applies here | has `AGENTS.md` and `CONTRIBUTING.md`; our own org | easiest: do it right after the tag |
| liftbridge-io/liftbridge | direct, `ValueAtQuantile`, v1.1.2, active (2026-10) | 1.3.0 speedup + fixes | no contributing docs found | reasonable candidate |
| paypal/junodb | direct, v1.1.2, last push 2024-06 | fixes | has Dependabot but the repository looks idle | low value, likely ignored |
| vearch/vearch, hanchuanchuan/goInception | `go.mod` lists v0.9.0 / v1.1.2 but **no importing Go file found** | none shown | goInception requires a CLA | skip until a real import is confirmed |
| cockroachdb/cockroach | the only real **old-path direct** user: 8+ files (`pkg/util/metric`, `pkg/workload/...`, `pkg/cli/syncbench`, `pkg/kv/bulk/bulkpb`), pseudo-version from 2016 | fixes only | **CLA required**, Bazel (`BUILD.bazel` in 8 packages, `build/bazelutil/distdir_files.bzl`, `./dev generate bazel`), and it is moving away: its #167845 / #168347 on a new "goodhistogram" were closed unmerged but show the direction | not worth it from outside; open an issue instead if you want it known |
| flipt, perforator, bee, mattermost playbooks | old path is transitive only (see fact 3) | n/a | flipt wants DCO sign-off and has agent guidance files; perforator wants an `accepted` issue first and a CLA; bee and Mattermost have `AGENTS.md` | nothing to PR; the fix would be in the upstream library that pulls it in |

## Rules that apply before any PR

- **Who opens it.** Several of these projects publish agent guidance (`AGENTS.md` in flipt, bee, Mattermost, redis-benchmark-go; `CLAUDE.md` in cockroach), which is not the same as
  allowing agent-opened PRs; each file and PR template must be read for a disclosure or human-ownership rule first, as happened with Node. CLAs (cockroach, goInception, perforator)
  and DCO sign-off (flipt) can only be given by a person.
- **Valkey and Dragonfly** stay off-limits; none of them is in this list.
- **Verification** for each bump: clone, `go get github.com/HdrHistogram/hdrhistogram-go@v1.4.0`, `go build ./...`, the project's own tests, run on the fleet, not on the
  maintainer's machine. A change of one `go.mod` line plus `go.sum` is small, but the behaviour changes in the 1.4.0 notes (negative values rejected, totals capped at
  `MaxInt64`, `New` panicking for impossible geometry) need a look at each project's call sites. None of the call sites seen passes negative values or such geometries, but that was read from a search, not a build.

## Suggested order, after v1.4.0 is tagged

1. redis-benchmark-go (ours, and the only real beneficiary of the speed-up), ftsb.
2. go-wrk (after reading its open PR #34), sonic, go-ycsb, go-tpc, liftbridge, each as a one-line bump with the 1.4.0 notes linked.
3. Leave oxy to bump itself, skip junodb, vearch, goInception, cockroach and the four transitive cases unless something new appears.

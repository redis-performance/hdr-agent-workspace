# hdr-agent-workspace

Performance-optimization workspace for [HdrHistogram_c](https://github.com/HdrHistogram/HdrHistogram_c) —
the C implementation of HdrHistogram (high-dynamic-range histograms).

Goal: push the `hdr_record_value` write path and the `hdr_value_at_percentile` read path
beyond their current baseline through profiled, evidence-based changes — every one
pre-cleared for upstream merge by an **adversarial review** modeled on the project
maintainer's real review M.O. Every experiment is logged; failures are as valuable as wins.

> **Minimum model: Opus 4.8** for every agent in every phase.
> **Public repo:** no secrets, credentials, tokens, private IPs, customer names, Slack, or
> ticket references anywhere in this tree.

---

## Upstream PRs — cross-port status (last updated 2026-07-02)

Optimizations proposed to all three ports from this workspace. Every change is
benchmarked (same-session A/B) and byte-identical-verified before it's opened.

### C — [HdrHistogram/HdrHistogram_c](https://github.com/HdrHistogram/HdrHistogram_c) (fork `fcostaoliveira/HdrHistogram_c`)
| PR | State | What |
|----|-------|------|
| [#134](https://github.com/HdrHistogram/HdrHistogram_c/pull/134) | **MERGED** | AVX2 vectorized prefix-sum in the percentile scan (read) |
| [#135](https://github.com/HdrHistogram/HdrHistogram_c/pull/135) | **MERGED** | bypass `normalize_index` on the record hot path when offset==0 (write) |
| [#136](https://github.com/HdrHistogram/HdrHistogram_c/pull/136) | **MERGED** | single unsigned bounds check on the record path (write) |
| [#133](https://github.com/HdrHistogram/HdrHistogram_c/pull/133) | re-applied | guarded stores in `update_min_max` (maintainer's style variant) |
| [#138](https://github.com/HdrHistogram/HdrHistogram_c/pull/138) | **OPEN** ✅ CI green | widen AVX2 percentile scan 4→16/iter — read +137%/+144% |
| [#139](https://github.com/HdrHistogram/HdrHistogram_c/pull/139) | **DRAFT** (stacked on #138) | prefetch `counts[]` — read +8% (2 µarchs) |
| [#140](https://github.com/HdrHistogram/HdrHistogram_c/pull/140) | **OPEN** ✅ CI green | single-pass `hdr_value_at_percentiles` (+ offset test) — batch +599% |
| [#137](https://github.com/HdrHistogram/HdrHistogram_c/pull/137) | **OPEN** ⚠️ conflicts | portable block-sum (drops AVX2) + single-pass batch — overlaps #138/#139/#140 |

### Go — [HdrHistogram/hdrhistogram-go](https://github.com/HdrHistogram/hdrhistogram-go) (fork `fcostaoliveira/hdrhistogram-go`)
| PR | State | What |
|----|-------|------|
| [#57](https://github.com/HdrHistogram/hdrhistogram-go/pull/57) | ✅ **MERGED** `22a1b78` | flat `counts[]` scan in `ValueAtPercentile` — read +133% |
| [#58](https://github.com/HdrHistogram/hdrhistogram-go/pull/58) | ✅ **MERGED** `bbda977` | flat `counts[]` scan in `ValueAtPercentiles` (batch) — +303% |
| [#59](https://github.com/HdrHistogram/hdrhistogram-go/pull/59) | ✅ **MERGED** `37ca617` | single unsigned bounds check in `RecordValues` (write) — +7% |

### Rust — [HdrHistogram/HdrHistogram_rust](https://github.com/HdrHistogram/HdrHistogram_rust) (fork `fcostaoliveira/HdrHistogram_rust`)
| PR | State | What |
|----|-------|------|
| [#138](https://github.com/HdrHistogram/HdrHistogram_rust/pull/138) | **OPEN** (awaiting maintainer to run CI) | `value_at_quantiles`/`value_at_percentiles` single-pass batch API — +616% |

**Cross-port race + charts:** [`experiments/RACE.md`](experiments/RACE.md). Adversarial PR reviews
(3 reusable skills — `review-hdrhistogram`, `hdr-reviewer-go`, `hdr-reviewer-rust`) caught 2 real
Go bugs pre-merge; see [`experiments/GO-PR-REVIEW-2026-07-02.md`](experiments/GO-PR-REVIEW-2026-07-02.md).
Full PR lineage: [`.workspace-memory/hdr-upstream-prs.md`](.workspace-memory/hdr-upstream-prs.md).

---

## Optimization Pipeline

Population-based selection AND implementation, inspired by AutoKernel (arXiv:2603.21331),
extended with an adversarial upstream-merge review gate.

```
PROFILE (write|read) → classify bottleneck → pick tier from program.md
        │
        ▼
  SELECTION — 3 proposers (opus-a/b/c) → chair picks winning hypothesis
        │
        ▼
  IMPLEMENTATION — 3 variants in parallel → each git-applied, ctest'd, benched → best wins
        │
        ▼
  MULTI-STAGE VERIFY — ctest → ASan/UBSan → fuzz (codec/layout)
        │
        ▼
  STEP 1 BENCHMARK (write+read, gcc+clang, same-session)
        │
        ▼
  STEP 2 PROFILE (classify new bottleneck)
        │
        ▼
  ADVERSARIAL REVIEW (review-hdrhistogram) → must be MERGE-READY to PR
        │
   ┌────┴────┐
 ACCEPT    REJECT
 commit    git checkout
 in submod  + Known Non-Starters
        │
   log to EXPERIMENTS.md + token-ledger.tsv
```

Two-step validation is mandatory before accepting any change:

| Step | Tool | Signal |
|------|------|--------|
| 1 — Benchmark | `hdr_histogram_perf` / `hdr_percentile_bench` | ops/sec (write), throughput (read) |
| 2 — Profile | `perf record -g` + `perf report` | hot symbols, % CPU, IPC, branch/cache miss |

Plus: an adversarial review (`.claude/skills/review-hdrhistogram.md`) gates every upstream PR.

---

## Workspace Layout

```
HdrHistogram_c/                 submodule — fork fcostaoliveira/HdrHistogram_c (upstream remote = HdrHistogram/…) — FOCUS
  src/hdr_histogram.c           primary target — record/value/percentile hot paths
HdrHistogram_rust/              submodule — fork fcostaoliveira/HdrHistogram_rust (cross-port reference)
hdrhistogram-go/                submodule — upstream HdrHistogram/hdrhistogram-go (cross-port reference)
  include/hdr/hdr_histogram.h   public struct + API (struct-layout changes)
  test/hdr_histogram_perf.c     immutable WRITE-path driver
  test/hdr_percentile_bench.c   immutable READ-path microbench
experiments/
  EXPERIMENTS.md                append-only log
  SUMMARY.md                    status table (keep README counts in sync)
  TEMPLATE.md                   copy for new entries
  token-ledger.tsv              machine-readable token cost per agent per phase
  EXP-NNN/                      one folder per experiment (bench-results / profile-results / proposals / variants)
scripts/
  build-bench.sh                configure + build perf/bench targets (COMPILER=gcc|clang)
  run-bench.sh                  run write + read drivers, save timestamped output
  run-profile.sh                perf record + report (DRIVER=write|read)
  select.sh                     selection phase: 3 proposers + chair (parallel, Opus 4.8)
  implement.sh                  implementation phase: 3 variants + best-wins (parallel, Opus 4.8)
  agent-run.sh                  agent-agnostic shim (AGENT=claude|codex|aider)
  llm-call.py                   Anthropic API caller + token ledger
.claude/
  CLAUDE.md                     agent instructions (workflow, rules, correctness invariants)
  program.md                    tiered optimization playbook (Tiers 1–6, bottleneck table)
  settings.json                 model = opus 4.8, tool permissions
  skills/
    optimize.md                 full loop orchestration
    select.md / chair.md        proposer + chair prompts
    implement.md                implementer prompt
    bench.md / profile.md       benchmark + profiling skills
    review-hdrhistogram.md      ADVERSARIAL upstream-merge review (maintainer M.O.)
.workspace-memory/
  MEMORY.md + entries           persistent, sanitized, agent-backend-agnostic
AGENTS.md                       conventions for agent loops
```

---

## Quick Start

```bash
git clone --recurse-submodules git@github.com:redis-performance/hdr-agent-workspace.git
cd hdr-agent-workspace

# Build the benchmark + perf drivers
COMPILER=gcc scripts/build-bench.sh

# Baseline (write + read)
EXP=EXP-001 scripts/run-bench.sh

# Profile the write path
scripts/run-profile.sh

# Edit HdrHistogram_c/src/hdr_histogram.c, then re-build / re-bench / re-profile,
# run the adversarial review, and commit in the submodule on accept.
```

---

## Experiments

All logged in [`experiments/EXPERIMENTS.md`](experiments/EXPERIMENTS.md);
[`experiments/SUMMARY.md`](experiments/SUMMARY.md) is the status source of truth.

| Status | Count |
|--------|------:|
| Accepted | 3 |
| Rejected | 1 |
| Parked | 0 |
| In Progress | 0 |

- **EXP-002** (ACCEPT) — widen the AVX2 percentile scan 4→16 int64/iter with a vector accumulator:
  read path **+137% (gcc) / +144% (clang)** on Cascade Lake, percentile results bit-identical.
  Upstreamed as **[PR #138](https://github.com/HdrHistogram/HdrHistogram_c/pull/138)** (body offers to re-target if the maintainer prefers #137's portable path).
- **EXP-003→004** (ACCEPT) — software prefetch of `counts[]` ahead in the widened scan. Parked after
  Cascade Lake (gcc +8%, clang flat), then validated on a 2nd µarch (Granite Rapids: **gcc +7.7% /
  clang +5.7%**) — portable across two µarchs/compilers, clang never regresses. Branch
  `perf/avx2-scan-prefetch`; follow-up **[PR #139](https://github.com/HdrHistogram/HdrHistogram_c/pull/139)** (stacked on #138).
- **EXP-001** (REJECT) — Tier-1 `counts_index_for` fusion: correct + gcc +5.9% but clang −12.1%,
  rejected as a portable regression.

The merged fork PRs above are the baseline this workspace builds on.

---

## Ports

- **C** — the **focus** of the optimization loop (this workspace). Submodule `HdrHistogram_c/`
  (fork `fcostaoliveira/HdrHistogram_c`, upstream `HdrHistogram/HdrHistogram_c`).
- **Rust** — submodule `HdrHistogram_rust/` (fork `fcostaoliveira/HdrHistogram_rust`, upstream
  `HdrHistogram/HdrHistogram_rust`). Cross-port reference for idea mining; not yet actively optimized.
- **Go** — submodule `hdrhistogram-go/` (upstream `HdrHistogram/hdrhistogram-go`). Cross-port
  reference; not yet actively optimized.

Accepted C wins are candidate cross-pollinations into the Rust/Go ports where the algorithm maps
(e.g. the percentile-scan structure); each port would get its own benchmark + validation before any change.

**Cross-port race** — identical-workload baseline of the three **official releases**
(C v0.11.10, Rust 7.5.4, Go v1.2.0) is in [`experiments/RACE.md`](experiments/RACE.md)
(drivers in [`race/`](race/)). Headline (gnr1, single core; byte-identical results across ports):
- **Write**: C 409 M/s > Rust 0.86× > Go 0.73×.
- **Read 1 percentile**: C > Rust (1.39×) > **Go (5.3× behind C)** — Go's iterator-based `ValueAtPercentile` is the biggest gap.
- **Read all 7 (`value_at_percentiles`)**: twist — **C's native batch is the *slowest* (iterator, 81µs), slower than looping its own singular 7×**; Rust has no batch API (7× singular); Go's native batch beats its own singular loop.

---

## Inspiration

Directly inspired by **AutoKernel: Autonomous GPU Kernel Optimization via Iterative
Agent-Driven Search** (Jaber & Jaber, arXiv:2603.21331, 2026) — immutable benchmark harness,
multi-stage correctness before any measurement, git as the experiment ledger, a tiered
optimization playbook, and bottleneck classification to steer the next experiment. Sibling
workspace: `ffc-agent-workspace` (float parsing). This one adds an adversarial
upstream-merge review gate derived from the HdrHistogram_c maintainer's actual review history.

## References

- HdrHistogram: <http://hdrhistogram.org>
- [HdrHistogram_c](https://github.com/HdrHistogram/HdrHistogram_c)
- Jaber & Jaber, [AutoKernel](https://arxiv.org/abs/2603.21331), arXiv, 2026

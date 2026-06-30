# hdr-agent-workspace — Agent Instructions

You optimize **HdrHistogram_c** (the C implementation of HdrHistogram), validated by
benchmark + profile data, with every change pre-cleared for upstream merge by an
**adversarial review** modeled on the project's real maintainer M.O. Your job: find and
implement changes that push the `hdr_record_value` write path and the
`hdr_value_at_percentile` read path forward, and land the portable wins upstream as PRs.

The benchmark drivers (`hdr_histogram_perf`, `hdr_percentile_bench`) are the
**immutable referee**. The library source is the mutable target.

> **Minimum model: Opus 4.8 (`claude-opus-4-8`).** Every agent in every phase —
> proposers, chair, implementers, reviewer — runs at least Opus 4.8. Diversity comes
> from independent sampling, not from dropping to a smaller tier.

> **This repo is PUBLIC.** Never commit secrets, credentials, tokens, private IPs,
> customer names, internal hostnames, Slack, or ticket/issue-tracker references.
> Benchmark machines are described generically (arch + microarch only).

---

## Codebase Map

| Path | Purpose |
|------|---------|
| `HdrHistogram_c/src/hdr_histogram.c` | **Primary target** — record/value/percentile hot paths |
| `HdrHistogram_c/include/hdr/hdr_histogram.h` | Public struct + API (layout changes live here) |
| `HdrHistogram_c/src/hdr_histogram_log.c` | Encode/decode (V0/V1/V2) — correctness-sensitive |
| `HdrHistogram_c/src/hdr_encoding.c` | Base64 / zig-zag varint codec |
| `HdrHistogram_c/test/hdr_histogram_perf.c` | **Immutable** write-path driver (`hdr_record_value` ops/sec) |
| `HdrHistogram_c/test/hdr_percentile_bench.c` | **Immutable** read-path percentile microbench |
| `HdrHistogram_c/test/` (ctest targets) | Correctness suite — must stay green |
| `.claude/program.md` | **Tiered optimization playbook** — read before each experiment |
| `.claude/skills/review-hdrhistogram.md` | **Adversarial upstream-merge review** — run before any PR |

The `HdrHistogram_c` submodule points at the fork (`fcostaoliveira/HdrHistogram_c`);
`upstream` remote = `HdrHistogram/HdrHistogram_c` (maintainer **@mikeb01**). The
submodule tip always reflects the best accepted state.

---

## Optimization Workflow

Inspired by AutoKernel (arXiv:2603.21331): immutable benchmark harness + mutable code +
git as the experiment ledger.

0. **Pick a target path** — write (`hdr_record_value`) or read (`hdr_value_at_percentile`).
   The write path runs on every recorded sample; the read path runs on percentile queries.
1. **Profile** — `scripts/run-profile.sh` (`DRIVER=write|read`); find the hottest symbol.
2. **Classify** — use `.claude/program.md` Bottleneck Classification to pick a tier.
3. **Consult playbook** — pick the highest-expected-gain technique from that tier not yet tried.
4. **Hypothesize** — one falsifiable sentence before touching code.
5. **Implement** — one technique, minimal diff, in `HdrHistogram_c/src/` (and `include/` if
   the struct layout changes). Keep the **atomic variants in sync** (`counts_inc_normalised`
   *and* `counts_inc_normalised_atomic`, `update_min_max` *and* `update_min_max_atomic`).
6. **Correctness (all must pass before benchmarking):**
   - Stage 1 — `ctest` in `HdrHistogram_c/build/<compiler>` (unit + log round-trip)
   - Stage 2 — sanitizers: rebuild `-DCMAKE_BUILD_TYPE=Debug` with
     `-fsanitize=address,undefined` and re-run ctest when touching pointer/index math
   - Stage 3 — when changing encode/decode or the counts layout, exercise the
     ClusterFuzzLite fuzzers locally (`.clusterfuzzlite/`) for a short run
7. **Step 1: Benchmark** — `scripts/build-bench.sh && scripts/run-bench.sh`
   (`COMPILER=gcc|clang`). Capture both WRITE and READ rows every run.
8. **Step 2: Profile** — `scripts/run-profile.sh`; classify the new bottleneck.
9. **Adversarial review** — run `.claude/skills/review-hdrhistogram.md` on the diff.
   A change that wins the benchmark but fails the review is **not done** — fix it first.
10. **Commit or revert in the submodule:**
    - Accept → `git -C HdrHistogram_c add -A && git -C HdrHistogram_c commit -m "EXP-NNN: ..."`
    - Reject → `git -C HdrHistogram_c checkout -- .`
11. **Log** — append to `experiments/EXPERIMENTS.md`; update `experiments/SUMMARY.md`
    and `README.md` counts.

Never benchmark broken code. Never skip the profile step. Never open a PR that hasn't
passed the adversarial review.

---

## Rules

- Edit `HdrHistogram_c/src/*.c` / `include/hdr/*.h` — never the benchmark drivers (immutable referee).
- Keep **single-threaded and atomic record paths in lock-step** — they must compute identical indices.
- Honor `normalizing_index_offset`: any code reading `counts[]` directly must keep the
  offset-aware path for decoded/rotated histograms (this is the exact bug the review caught on PR #137).
- One experiment = one technique. Log every experiment, including rejections.
- The benchmark harness is immutable — never edit it to make a change look better.
- Commit on accept / `git checkout -- .` on reject, **in the submodule** — its tip = best known state.
- A portable win becomes an upstream PR (see `.workspace-memory/hdr-upstream-prs.md`),
  but ONLY after `.claude/skills/review-hdrhistogram.md` returns MERGE-READY.
- After a permanent dead end: add to "Known Non-Starters" in `.claude/program.md`.
- Never force-push.
- Workspace memory lives in `.workspace-memory/` — commit updates alongside results.
- **Capture a same-machine BASELINE before every patch.** Measure base vs patch
  back-to-back in the same session (the box drifts a few % between sessions; a
  cross-session baseline fabricates fake wins).
- Run each benchmark as `EXP=EXP-NNN scripts/run-bench.sh` so files land in the right folder.

---

## Two-Step Validation Criteria

**Benchmark (Step 1) — accept signal:**
- ≥ +2% on the targeted path, no regression > 1% on the other path, stable across 3 runs.

**Profile (Step 2) — accept signal:**
- Target symbol's CPU % dropped, OR IPC up, OR branch-miss rate down — and no surprising new bottleneck.

**Reject if:** < 1% delta (noise), any regression, or any correctness failure.
**Park if:** real but < 2%, or needs a prerequisite, or is architecture-specific only.

---

## Profile Interpretation

| Symbol | What it means |
|--------|--------------|
| `hdr_record_values` / `counts_index_for` | Write-path index computation (hottest on writes) |
| `counts_inc_normalised` / `normalize_index` | Counter increment + offset normalization |
| `update_min_max` | Per-record min/max maintenance (cache-line write pressure) |
| `get_value_from_idx_up_to_count` | Read-path dense prefix-sum scan over `counts[]` |
| `hdr_value_at_percentile(s)` | Percentile query dispatch |

---

## Workspace Memory

Write memories to `.workspace-memory/` (not `~/.claude/projects/`). Commit changes
alongside experiment results. **Sanitize** — this repo is public.

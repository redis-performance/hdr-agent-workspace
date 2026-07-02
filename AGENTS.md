# Agent Notes — hdr-agent-workspace

Conventions for agent loops optimizing **HdrHistogram_c**.
Mirrors the M.O. of `ffc-agent-workspace` (population-based select → implement → verify,
immutable benchmark referee, git as the experiment ledger, adversarial upstream review).

> **PUBLIC REPO.** No secrets, credentials, tokens, private IPs, internal hostnames,
> customer names, Slack, or ticket references. Describe machines generically (arch only).

> **Minimum model: Opus 4.8 (`claude-opus-4-8`)** for every agent in every phase.

---

## Optimization Goal

Push HdrHistogram_c forward on two paths:
- **Write path** (primary) — `hdr_record_value` → `counts_index_for` + `counts_inc_normalised`
  + `update_min_max`. Runs on every recorded sample.
- **Read path** — `hdr_value_at_percentile` → `get_value_from_idx_up_to_count` dense scan.

Focus is the **C** implementation. The **Rust** (`HdrHistogram_rust/`, fork
`fcostaoliveira/HdrHistogram_rust`) and **Go** (`hdrhistogram-go/`, upstream) ports are wired in
as **read-only cross-port references** for idea mining — not actively optimized yet. An accepted
C win that maps to a port is a candidate cross-pollination, but each port needs its own benchmark
+ validation + adversarial review before any change (see README "Ports").

---

## Two-Step Validation (mandatory)

Every change must pass both before acceptance:

1. **Benchmark** — `scripts/run-bench.sh` (write + read, gcc + clang), same-session base vs patch.
   Must improve the targeted path ≥ +2% without regressing the other > 1%.
2. **Profile** — `scripts/run-profile.sh`; confirm the expected bottleneck shifted.

A win that reveals a surprising new bottleneck is a **partial win** — document and continue.

And before any upstream PR: **`.claude/skills/review-hdrhistogram.md` must return MERGE-READY.**

---

## Workflow Rules

- Edit `HdrHistogram_c/src/*.c` and `include/hdr/*.h`. Never edit the benchmark drivers
  (`test/hdr_histogram_perf.c`, `test/hdr_percentile_bench.c`) — the immutable referee.
- **Keep atomic twins in lock-step**: `counts_inc_normalised`/`_atomic`,
  `update_min_max`/`_atomic`.
- **Honor `normalizing_index_offset`** in any direct `counts[]` read (decoded/rotated histograms).
- **No shift on signed values** (project rule). Reuse `HDR_LIKELY`/`HDR_UNLIKELY` macros; don't redefine.
- Run `ctest` (Stage 1) before benchmarking. Sanitizers (Stage 2) for index/pointer changes.
  Fuzz (Stage 3) for codec/layout changes. Correctness first — never benchmark broken code.
- Log every experiment in `experiments/EXPERIMENTS.md` (failures included).
- Keep `experiments/SUMMARY.md` and `README.md` counts in sync.
- Commit accepted changes **in the submodule** (`git -C HdrHistogram_c commit`); revert with
  `git -C HdrHistogram_c checkout -- .`. The submodule tip = best accepted state.
- Bump the submodule pointer + log in the parent repo when a change is accepted.
- Never force-push.

---

## Agent-Agnostic Shim — `scripts/agent-run.sh`

`AGENT=claude` (default) runs `claude --model claude-opus-4-8 --print`. `codex`/`aider`
are planned. Skills under `.claude/skills/*.md` are plain markdown prompts.

---

## Persistent Memory — `.workspace-memory/`

All memory lives in `.workspace-memory/` so every backend shares context. `MEMORY.md` is
the index; one file per entry. Commit memory updates alongside experiment results.
**Sanitize before committing** — public repo.

---

## Build / Run Requirements

Runs locally; no remote runners required.
- `cmake` ≥ 3.12, `gcc` and/or `clang`, `make`
- `perf` (Linux kernel tools) for profiling — `sudo apt install linux-tools-generic`
- `python3` ≥ 3.10 + `anthropic` (for the parallel select/implement scripts)
- `claude` CLI — `npm i -g @anthropic-ai/claude-code`

For perf counter access:
```bash
echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid
```

For heavy/exhaustive runs (fuzzing, long benchmarks), prefer a dedicated benchmark box
over an interactive workstation; pin to a core (`taskset`) to cut variance.

---

## Required Secrets

None — fully OSS, runs locally. Set `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` for
the parallel agent scripts. Do not store any token in the repo.

---

## Submodule & Upstream

- `HdrHistogram_c/` → fork `fcostaoliveira/HdrHistogram_c` (`origin`), upstream
  `HdrHistogram/HdrHistogram_c` (`upstream`, maintainer @mikeb01).
- Portable wins → PR from the fork to upstream, **only after** the adversarial review passes.
  See `.workspace-memory/hdr-upstream-prs.md`.

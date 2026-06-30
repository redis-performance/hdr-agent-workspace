# Skill: optimize

One full iteration of the population-based optimization loop:
select → implement (N variants) → multi-stage verify → benchmark → profile →
adversarial review → commit/revert → log.

Inspired by AutoKernel (arXiv:2603.21331): immutable benchmark + mutable code + git as
the experiment ledger. All agents run Opus 4.8 minimum.

---

## Full Loop

```
Profile (DRIVER=write|read)
  ↓
SELECTION — 3 proposers (opus-a/b/c) → chair picks winner
  ↓
IMPLEMENTATION — 3 variants in parallel → best passing variant wins
  ↓
Multi-stage correctness (ctest → sanitizers → fuzz if encode/decode/layout)
  ↓
Step 1: Benchmark (write + read)
  ↓
Step 2: Profile → classify new bottleneck
  ↓
Adversarial review (review-hdrhistogram) → must be MERGE-READY for a PR
  ↓
Accept (git commit in submodule) or Reject (git checkout)
  ↓
Log to EXPERIMENTS.md + token-ledger.tsv
```

---

## Steps

### 1. Profile (if stale)
```bash
scripts/run-profile.sh                 # write path
DRIVER=read scripts/run-profile.sh     # read path
```

### 2. Selection phase
```bash
EXP_ID=EXP-NNN scripts/select.sh
```
Reads `experiments/EXP-NNN/proposals/TS/chair-decision.md` for the winner. If the script
is unavailable (interactive session): act as chair yourself — read profile + playbook,
propose 3 alternatives from different tiers, pick the strongest, state the hypothesis.

### 3. Implementation phase
```bash
EXP_ID=EXP-NNN scripts/implement.sh experiments/EXP-NNN/proposals/TS/chair-decision.md
```
Runs 3 variants in parallel; each diff is `git apply`-ed to a fresh tree, built,
`ctest`-ed, benchmarked; best passing variant is applied. If unavailable: implement the
hypothesis yourself.

### 4. Multi-stage correctness (winner variant — all before benchmarking)
```bash
# Stage 1 — unit + log round-trip
ctest --test-dir HdrHistogram_c/build/gcc --output-on-failure
# Stage 2 — sanitizers (pointer/index changes)
cmake -S HdrHistogram_c -B HdrHistogram_c/build/asan -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_C_FLAGS="-fsanitize=address,undefined -fno-sanitize-recover=all" -DHDR_HISTOGRAM_BUILD_PROGRAMS=ON
cmake --build HdrHistogram_c/build/asan -j && ctest --test-dir HdrHistogram_c/build/asan
# Stage 3 — fuzz (encode/decode or counts-layout changes), short local run via .clusterfuzzlite/
```
If any stage fails: `git -C HdrHistogram_c checkout -- .` and return to step 2.

### 5. Step 1 — Benchmark
```bash
EXP=EXP-NNN scripts/build-bench.sh && EXP=EXP-NNN scripts/run-bench.sh
COMPILER=clang EXP=EXP-NNN scripts/build-bench.sh && COMPILER=clang EXP=EXP-NNN scripts/run-bench.sh
```
Compare write + read vs the last accepted entry, same session.

### 6. Step 2 — Profile
```bash
scripts/run-profile.sh
```
Classify the new bottleneck for the next iteration.

### 7. Adversarial review (before any PR)
Run `.claude/skills/review-hdrhistogram.md` on the diff. Resolve every ❌ before accepting
a change you intend to upstream.

### 8. Commit or revert (in the submodule)
```bash
# Accept (≥ +2% on target path, no regression > 1%, review MERGE-READY):
git -C HdrHistogram_c add -A && git -C HdrHistogram_c commit -m "EXP-NNN: [change]"
# Reject:
git -C HdrHistogram_c checkout -- .
```

### 9. Log
Append to `experiments/EXPERIMENTS.md` (use `experiments/TEMPLATE.md`); record all agent
token counts in `experiments/token-ledger.tsv`. If rejected, add to "Known Non-Starters"
in `.claude/program.md`. Update `experiments/SUMMARY.md` + `README.md` counts.

---

## Move-On Criteria
- 5 consecutive rejects from one tier → next tier.
- < 2% CPU in the target symbol after profiling → re-classify, pick new tier.
- ≥ +10% accepted → re-profile before choosing the next experiment.

## Decision Thresholds
| | Criteria |
|--|---------|
| **Accept** | ≥ +2% on target path, no regression > 1% on the other, profile confirms shift, review MERGE-READY |
| **Reject** | < 1% delta (noise), any regression, or any correctness failure |
| **Park** | ≥ +1% but < 2%, needs a prerequisite, or architecture-specific only |

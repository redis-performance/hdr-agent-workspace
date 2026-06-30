## EXP-NNN — YYYY-MM-DD — [short title]

**Target path**: write | read
**Tier / Technique**: [e.g. Tier 1 — 1a. Fuse counts_index_for]
**Hypothesis**: [one falsifiable sentence]
**Files changed**: `HdrHistogram_c/src/hdr_histogram.c` lines N–M (+ `include/hdr/hdr_histogram.h` if struct)
**Atomic twin updated**: yes/no — [which variant]

### Step 1: Benchmark (same-session, base vs patch)
| Path  | Compiler | Before        | After         | Δ%   |
|-------|----------|---------------|---------------|------|
| write | gcc      | (ops/sec)     |               |      |
| write | clang    |               |               |      |
| read  | gcc      |               |               |      |
| read  | clang    |               |               |      |

### Step 2: Profile (top symbols, after)
```
perf report excerpt + IPC / branch-miss / cache-miss
```

### Correctness
- ctest: PASS (n/n) | FAIL
- ASan/UBSan: PASS | FAIL | N/A
- fuzz: PASS | NOT RUN (not codec/layout) | FAIL

### Adversarial review (review-hdrhistogram)
- Verdict: MERGE-READY | NEEDS WORK — [blocking items if any]

**Decision**: accept / reject / park
**Reason**: [one or two sentences]
**Upstream**: [PR # if opened, or "held — reason"]

### Token cost
| Phase | Agent | Model | in | out | $ |
|-------|-------|-------|----|----|---|

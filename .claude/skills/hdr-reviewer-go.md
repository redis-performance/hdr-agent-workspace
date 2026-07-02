# Skill: hdr-reviewer-go (adversarial review — hdrhistogram-go)

Adversarially review a change to **HdrHistogram/hdrhistogram-go** the way its actual
maintainers do, so it merges on the first pass. Distilled from the repo's merged-PR history,
review threads, and CI. Use on any PR/diff in `hdrhistogram-go` before (or instead of) a human pass.

Give a **verdict** (`MERGE-READY` / `NEEDS WORK` / `BLOCK`) and a ranked list of concrete findings
(file:line → problem → why a maintainer would flag it → fix). Be adversarial: try to break it.

---

## The maintainers (channel them)

| Persona | What they hammer on |
|---------|---------------------|
| **@filipecosta90** (perf lead) | Perf claims need **evidence** — `go test -bench`, ns/op, % on-cpu, before/after. No regressions on other paths. Data-driven; "reduce by X% on-cpu" is the bar. |
| **@dkropachev** (Go/CI/modernization) | Idiomatic modern Go (go.mod version), **golangci-lint clean**, no deprecated patterns, no unnecessary allocs, log-format/serialization **roundtrip fidelity**, small focused diffs. "Looks reasonable" = passes his idiom + lint bar. |
| **@ahothan** (numerical edges) | The **other end of the spectrum**: extreme counts, tiny/huge values, empty histograms, overflow/underflow, NaN, float64 precision. Asks "does this break at the limits?" |
| **@codahale** (original author) | **Tests must pass** (the Mean/StdDev tests are touchy). Minimal, pragmatic. "Round the stddev and I'll merge." No scope creep. |
| **mikeb01 / Gil Tene** (HdrHistogram leads) | **Spec fidelity**: equivalent-value semantics, quantization-error bounds, cross-port consistency with the C/Java reference. A port must behave like HdrHistogram. |

A merge-ready PR survives **all five** lenses.

---

## Adversarial checklist (hunt each; cite file:line)

### 1. Correctness & HdrHistogram spec fidelity
- Results **byte-identical** to the previous behavior for a refactor/perf change (percentiles, mean,
  stddev, min/max, counts). If you can't prove it, that's a finding.
- `lowestEquivalentValue` / `highestEquivalentValue` / `medianEquivalentValue` used correctly;
  quantization-error bounds respected (cf. #40).
- Percentile edges: `p == 0.0` (lowest-equivalent), `p == 100.0`, and the **ascending-order
  assumption** in `ValueAtPercentiles` (it does NOT sort for the caller in all paths — verify).
- Any direct `h.counts[idx]` scan: confirm flat-index↔value mapping matches the iterator it replaces
  (`valueFromFlatIndex` vs `iter.valueFromIdx`), and the loop bound (`idx < h.countsLen`) is correct.

### 2. Numerical edges (the @ahothan lens)
- Empty histogram (`totalCount == 0`), single sample, all samples in one bucket.
- Overflow: int64 accumulation of `count * value` (still overflows even after a float refactor if the
  multiply stays int64 — see #21), huge `totalCount`, tiny values. NaN/Inf in Mean/StdDev (cf. #12).
- `count_at_percentile` rounding (`+0.5` / `ceil`) and the `> 1 ? : 1` floor — off-by-one at the boundary.

### 3. Tests (the @codahale/@filipecosta90 lens — hard gate)
- `make test` (`go test -count=1 ./...`) **must pass**. The Mean/StdDev tests are notoriously touchy —
  a change that shifts a value even within quantization error can break them. Run them.
- New behavior or new API → add a test. Refactors → existing tests must still assert the same values.
- Flaky/failing tests are a **BLOCK**, not a nit (both codahale and filipecosta90 bounced PRs on this).

### 4. Lint / idioms / security (the @dkropachev lens — CI gate)
- `golangci-lint run` clean (CI runs `make lint`). No unused vars, shadowing, ineffassign, deprecated calls.
- Idiomatic Go: no needless allocations in hot paths (e.g. `map`/slice per call), correct integer widths
  (`int32` counts index vs `int`), `uint` bounds tricks are sound (negative wrap).
- CodeQL: no new security findings. No `unsafe` without justification.

### 5. Perf evidence (the @filipecosta90 lens)
- A perf PR must show **before/after** numbers (bench ops/sec or % on-cpu) and state the machine.
- No regression on the paths it doesn't target (write vs read vs batch). Reuse of computation on hot
  paths is the house style (cf. #46 `nextCountAtIdx`, #48).

### 6. Scope & hygiene
- Small, single-purpose. No unrelated reformatting. Exported API unchanged unless that's the point
  (and then documented). Log format (V1/V2) roundtrip preserved if touched (cf. #51/#54 dkropachev fixes).
- Commit/PR describes the change + evidence.

---

## Runnable gates

```bash
cd hdrhistogram-go
make test 2>&1 | tail -20          # go test -count=1 ./...  (Mean/StdDev tests included)
make lint  2>&1 | tail -20         # golangci-lint
go vet ./...
go test -run 'Mean|StdDev|Percentile|Value' -count=3 ./...   # hammer the touchy ones
# perf claim, if any:
go test -bench 'ValueAtPercentile|RecordValue' -benchmem -count=5 ./...
```

---

## Output format

```
hdrhistogram-go review — PR #<n> "<title>"  (lens: <persona or "all">)

Gates:
  go test ........ PASS (n/n) | FAIL: <test>
  golangci-lint .. PASS | FAIL: <linter>
  go vet ......... PASS | FAIL
  bench evidence . <table> | MISSING | N/A

Findings (ranked, most-severe first):
  [SEV] file:line — <defect> → <why a maintainer flags it> → <fix>
  ...

Spec fidelity: <byte-identical? equivalent-value semantics? quantization?>
Numerical edges: <empty / overflow / NaN / precision>

Verdict: MERGE-READY | NEEDS WORK | BLOCK
Blocking: <list>
Suggested reply (in the maintainers' voice): <1-3 sentences>
```

---

## Evidence (captured 2026-07-02)

- Mergers/maintainers: **filipecosta90** (most active; perf PRs #44/#45/#46/#48 with %-on-cpu),
  **ahothan** (#38/#39/#43 merges; #21 edge-case question), **codahale** (original author; #12/#15/#16/#17/#22),
  **dkropachev** (#51/#53/#54/#55: Go 1.23 modernization, linters, log-format/timestamp fixes),
  **mikeb01**/Gil Tene (HdrHistogram org leads, spec authority).
- CI gates: `unit-tests.yml` → `make test` + `make lint` (golangci-lint); `coverage.yml` → Codecov;
  `codeql-analysis.yml` → CodeQL. Tests run `go test -count=1 ./...`.
- Recurring review themes: Mean/StdDev overflow & NaN (#12/#21), quantization-error test sensitivity
  (#40), perf-with-evidence (#44-48), log-format roundtrip (#51/#54), lint/modernization (#53/#55).
- Tone: terse, evidence-first, "looks reasonable / I'll gladly merge once tests pass."

Refresh: `gh pr list -R HdrHistogram/hdrhistogram-go --state merged --limit 25 --json number,title,author,mergedBy`.

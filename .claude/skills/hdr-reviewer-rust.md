# Skill: hdr-reviewer-rust (adversarial review — HdrHistogram_rust)

Adversarially review a change to **HdrHistogram/HdrHistogram_rust** (the `hdrhistogram` crate) the
way its maintainer merges, so it lands on the first pass. Distilled from the merged-PR history + CI.
Give a **verdict** (`MERGE-READY` / `NEEDS WORK` / `BLOCK`) and a ranked findings list (file:line →
problem → why the maintainer flags it → fix). Be adversarial: try to break it.

---

## The maintainer (channel them)

| Persona | What they hammer on |
|---------|---------------------|
| **@jonhoo** (Jon Gjengset — primary maintainer/merger) | Idiomatic Rust; **`cargo fmt --check` + clippy clean**; **`cargo test --locked` on stable AND beta**; **minimal-versions / MSRV** (edition 2018 — no newer-than-MSRV std); **every change has tests**; clear docs on public API; API ergonomics + naming consistency. Meticulous CI hygiene (syncs from rust-ci-conf). |
| **@the8472 / @arthurprs** (perf contributors) | Real speedups with numbers (#112 `quantile_below` 100×, #113 clone/add); minimal allocations; no needless work in hot loops. |
| correctness precedent | #124/#125 — "record iteration when recording only zeros" was a real bug. Iteration/scan edge behavior is scrutinized. |

A merge-ready PR passes fmt + clippy + `cargo test --locked` (stable/beta) + minimal-versions, has
tests for the new behavior, and is idiomatic + documented.

---

## Adversarial checklist (hunt each; cite file:line)

### 1. Correctness & spec fidelity
- New/refactored percentile/quantile code must equal the per-item `value_at_quantile` /
  `value_at_percentile` for EVERY input, including: empty histogram (`total_count == 0`),
  `q == 0.0`, `q == 1.0` / `p == 100.0`, `q > 1.0` (clamp), **duplicate** quantiles, **unsorted**
  input, single sample, all-zeros recorded (cf. #124/#125), sparse counts, last-index crossing.
- If a batch resolves in sorted order but returns in input order, verify the index bookkeeping
  (the `order` permutation) maps back correctly, including duplicates.
- Target-count rule must match `value_at_quantile` exactly (`(q*total).ceil()`, floor to 1).

### 2. Panics / robustness (the Rust lens)
- `sort_by(|a,b| a.partial_cmp(b).unwrap())` **panics on NaN**. A NaN quantile input → panic. Is that
  acceptable, or should it be `total_cmp` / documented? Any `unwrap()`/`expect()`/indexing that can
  panic on adversarial input is a finding.
- Integer casts (`as u64`, `as usize`) — truncation/overflow on huge `total_count`? `T::as_u64()` use.
- No new `unsafe` without justification.

### 3. fmt / clippy / MSRV (jonhoo's hard CI gates)
- `cargo fmt --check` clean.
- `cargo clippy --all-targets` clean — watch **`needless_range_loop`** (`for i in 0..counts.len()`
  indexing), `needless_return`, `manual_*`, `ptr_arg`. (Note: the existing scan uses index loops, so
  match the crate's established style, but flag if clippy would newly complain.)
- **MSRV / edition 2018**: no `let-else`, no newer-than-MSRV std methods, no 2021-only syntax. Check
  `cargo +<msrv> build` conceptually; minimal-versions CI must still resolve.

### 4. Tests (jonhoo requires them — hard gate)
- New public API **must** have tests. A batch API needs a test asserting `batch == per-item` across
  the edge inputs in §1. `cargo test --locked` must pass on stable and beta.
- No test → NEEDS WORK, full stop (this is the most common jonhoo bounce).

### 5. API design & docs
- Naming consistency with existing API (`value_at_quantile` / `value_at_percentile`). Plural naming,
  return type (`Vec<u64>` alloc vs a fill-a-slice variant), and whether both `values_at_quantiles`
  and `value_at_percentiles` are warranted or one is redundant.
- Public items need `///` docs (jonhoo enforces). `#[must_use]` where appropriate.

### 6. Perf & allocations (the8472 lens)
- Per-call `Vec` allocations (targets, order, result) on a perf path — justified? Could a
  caller-provided buffer avoid them? Hot loop stays tight (the whole point).
- Provide before/after numbers for a perf claim.

---

## Runnable gates

```bash
cd HdrHistogram_rust
cargo fmt --check
cargo clippy --all-targets --all-features 2>&1 | tail -30
cargo test --locked 2>&1 | tail -20
cargo test --locked value_at 2>&1 | tail
# MSRV sanity (edition 2018): cargo +<msrv> build   (if toolchain available)
```

---

## Output format

```
HdrHistogram_rust review — PR #<n> "<title>"  (lens: <persona or "all">)

Gates:
  cargo fmt --check .. PASS | FAIL
  cargo clippy ....... PASS | FAIL: <lint>
  cargo test ......... PASS (n/n) | FAIL
  tests for new API .. PRESENT | MISSING
  MSRV/edition ....... OK | RISK: <what>

Findings (ranked, most-severe first):
  [SEV] file:line — <defect> → <why jonhoo flags it> → <fix>

Correctness: <batch == per-item across empty/q0/q1/dup/unsorted/last-idx?>
Panics: <NaN sort / unwrap / cast>
Verdict: MERGE-READY | NEEDS WORK | BLOCK
Blocking: <list>
Suggested reply (in jonhoo's voice): <1-3 sentences>
```

---

## Evidence (captured 2026-07-02)

- Maintainer/merger: **@jonhoo** (merges ~everything; CI synced from rust-ci-conf). Perf: **@the8472**
  (#112), **@arthurprs** (#113). Correctness precedent: #124/#125 (record-only-zeros iteration bug).
- CI: `check.yml` → `cargo fmt --check` + clippy; `test.yml` → `cargo test --locked` (stable, beta) +
  **minimal-versions**; `scheduled.yml` → nightly `cargo test --locked --all-features --all-targets`.
- Crate: edition 2018 (older MSRV — be conservative with std). Tests live in `tests/` + `#[cfg(test)]`.
- House style: index loops over `self.counts` are used in existing scans; match it, but keep clippy green.

Refresh: `gh pr list -R HdrHistogram/HdrHistogram_rust --state merged --limit 20 --json number,title,author,mergedBy`.

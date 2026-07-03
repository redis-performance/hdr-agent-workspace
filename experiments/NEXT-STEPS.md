# Next-Step Optimization Plan — C / Go / Rust (assessed 2026-07-03)

Grounded assessment of each port's current best state (all merged + open PRs applied), from three
parallel source-level reviews cross-checked against `.claude/program.md` and the gnr1 measurements in
[`RACE.md`](RACE.md). No benchmarking yet — these are ranked *hypotheses* to run through the normal
profile → implement → two-step-validate → adversarial-review loop.

## The one cross-port insight

**Every port's singular percentile read is a scalar loop with a data-dependent early exit** — a
loop-carried dependency on the running cumulative count, one add + compare + branch per element. That
dependency, not bounds checks, is now the ceiling (C already broke it with AVX2; Go/Rust are still
scalar and sit ~3× behind C's 0.5550 Mq/s at 0.183).

The portable fix is the **same algorithm in all three languages**:

> Sum `counts[]` in fixed blocks of N (8–16) with independent accumulators / SIMD lanes — a pure
> reduction with **no early exit**, so it autovectorizes (Go/Rust) or already is vectorized (C). Track
> the block subtotal; only when a block's subtotal would cross the target do you drop into the precise
> per-element walk **inside that one block**. Keep the `normalizing_index_offset != 0` offset-aware
> fallback and `uint64` accumulation (the exact teeth from the PR #137 review).

It's portable (helps ARM/Graviton too, where C+Go+Rust are all scalar today), needs no intrinsics, and
lints/covers cleanly. Ship it once per port, reuse the same helper for the batch API.

---

## C — `HdrHistogram_c` (maintainer @mikeb01, conservative; favors portable over intrinsics)

Current: WRITE 409 M/s (dep-bound), READ-1 0.5550 Mq/s (AVX2 #138+#139), batch 86.8K (#140).

| Rank | Path | Change | Est. | Merge |
|------|------|--------|------|-------|
| 1 | read-batch | **Block-summed multi-threshold batch scan** — collect all 7 thresholds in one strided block-sum pass instead of per-element `hdr_iter_next`. Frame as *portable block-sum, not more AVX2* → aligns with #137. | batch ~1.5–2× | low |
| 2 | write | **Struct cache-line repack (Tier 4b)** — hot write fields straddle 2 lines; pack `counts`/`counts_len`/`total_count`/`normalizing_index_offset` + masks/mags into line 0. Only real write lever left. | 3–8% | med (public header) |
| 3 | read (ARM) | **Portable/NEON block-sum scalar scan** — aarch64 gets zero SIMD today; a portable block-sum autovectorizes to NEON (baseline, no dispatch). Largely the same patch as #1. | ARM read 1.5–2× | low-med |

Rejected/noise: AVX-512 widen (bandwidth-bound post-prefetch, x86-only, fights #137's direction);
prefetch-distance sweep & write-path prefetch removal (likely noise — measure, don't assume);
`static inline` hot chain (compiler already does it, single-TU). Write-path SIMD is a dead end — the
immutable driver calls `hdr_record_value` one value at a time.

## Go — `hdrhistogram-go` (filipecosta90 is a maintainer → bolder changes OK)

Current: WRITE 320.6 M/s, READ-1 0.1833 Mq/s (#57+#62), batch 83.5K (#63). All 5 perf PRs merged.

| Rank | Path | Change | Est. | Risk |
|------|------|--------|------|------|
| 1 | read | **Blocked multi-accumulator skip-scan (pure Go)** — the cross-port lever above; breaks the serial accumulator dependency. Apply to all 3 scan sites in lock-step. | +20–40% read-1 | med; correctness-sensitive, needs fuzz/parity test |
| 2 | write | **BCE fix** — guard on `uint(idx) >= uint(len(h.counts))` (not `h.countsLen`, a separate field the compiler can't prove equal) so the second bounds check in the `counts[idx]+=` elides. Verify with `-d=ssa/check_bce/debug=1`. | +2–4% write | very low |
| 3 | read-batch | **Zero-alloc `ValueAtPercentilesSliceInto(pcts, dst)`** — additive; removes 3 heap allocs/call (result+countAtPercentiles+order) under GC pressure. | 10–20% batch under GC | low |
| BOLD | read | **Hand-written AVX2 `.s` block-skip scan** + pure-Go fallback + `cpu.X86.HasAVX2`. Only route to actually reach C's numbers (~0.4–0.5 Mq/s). | +2–3× read-1 | high + permanent 2-path maintenance; asm not linted/covered. Only if read-1 is a measured product bottleneck. |

## Rust — `HdrHistogram_rust` (maintainer @jonhoo, high bar; #138 already stalled unreviewed)

Current: WRITE 348 M/s, READ-1 0.1828 Mq/s (#139), batch 178.6K (#138 native). Both still OPEN PRs.

| Rank | Path | Change | Est. | Merge |
|------|------|--------|------|-------|
| 1 | — | **Land the open PRs first** (#139 BCE, then #138 batch). Merge-probability dominates — nothing new should stack until these land. Frame #139 as readability + reliable codegen (LLVM often already BCE's the range loop, so don't over-claim the +5%). | — | med-high |
| 2 | read | **Chunked prefix-sum scan** (`chunks_exact(8)` reduction, autovectorizes for T=u64/u32; element-walk only the crossing chunk; reuse in the batch fn). The only real read lever. Ship with bit-identical parity test. | med-high for p50–p99 | med |
| — | write | **Tapped out in safe Rust** — `record_n_inner` is minimal, and the `get_mut` bounds check is *load-bearing* (it's how auto-resize/out-of-range is detected), so `get_unchecked` is not correctness-justifiable. No >2% safe win visible. | — | — |

Caveat: generic `T: Counter` + `as_u64` widening (u8/u16→u64) yields poorer vectors than C's fixed-width
`int64`, so even the chunked scan won't fully close the 3× gap to C's AVX2. `std::simd`/portable_simd is a
**non-starter** here (nightly-only, breaks MSRV edition-2018/stable, needs unsafe specialization for `T`).

---

## Suggested execution order

1. **Go BCE write fix** — smallest diff, near-zero risk, quick confidence-builder (measure 3× — it's noise-adjacent).
2. **Cross-port blocked read scan** — prototype in **Go first** (we own it, boldest), validate the +20–40%,
   then port the identical shape to **C's scalar/batch path** (doubles as the ARM/NEON win + #137-aligned)
   and **Rust's chunked scan**. One idea, three PRs, shared correctness argument.
3. **Rust: land #139/#138** in parallel (no new work, just review pressure).
4. **C struct repack** and **Go zero-alloc batch** as independent low-risk follow-ups.
5. Park: Go AVX2 asm (only if read-1 proven a product bottleneck), C AVX-512, all sub-1% micro-cleanups.

Write-path verdict across all three ports: **effectively tapped out** for the one-value API (C
dependency-bound ~8–9 cyc/op with no ILP headroom; Rust minimal + load-bearing bounds check; Go has only
the small BCE fix left). Future write gains would need a batch/bulk record API, which the immutable
benchmark driver doesn't exercise.

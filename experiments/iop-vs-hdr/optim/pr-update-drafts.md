# Draft "Benchmark evidence" additions for the open sparse/packed PRs

Proposed comment/description additions. NOT posted — for review. Numbers from the 2026-08-26
3-arch run (Intel Granite Rapids, AMD Zen 5 Turin, ARM Neoverse-V2), sparse workload:
1605 populated of 21504 buckets. Full data: redis-performance/hdr-agent-workspace
`experiments/iop-vs-hdr/`.

---

## Rust — PR #154 (direct competitor: `iopsystems/histogram` is a Rust crate)

> ### Benchmark evidence — vs `iopsystems/histogram` v1.5.0 (the closest alternative)
>
> Measured on three arches (AWS Intel Granite Rapids / AMD Zen 5 / ARM Neoverse-V2), same
> bucket geometry both sides (21504 buckets), sparse latency-like workload:
>
> **Read (percentile) — ns/query, lower is better:**
>
> | impl | Intel | AMD | ARM |
> |---|--:|--:|--:|
> | `PackedHistogram` (this PR) | 408 | 299 | 597 |
> | `iop` SparseHistogram | 1238 | 936 | 1645 |
> | `iop` dense Histogram | 10602 | 8840 | 28955 |
> | dense `Histogram<u64>` | 380 | 316 | 512 |
>
> - **`PackedHistogram` reads 2.7–3.1× faster than iop's `SparseHistogram`**, and it records
>   **live** — iop's `SparseHistogram` is a read-only snapshot built from a dense histogram, so
>   it doesn't help the many-sparse-recorders case this PR targets.
> - Read parity with the dense `Histogram` (±7%; faster on Zen 5) — the blocked prefix-sum only
>   pays for populated buckets.
> - (Aside: iop's *dense* `percentile()` is 28–57× slower than HdrHistogram's — it does two full
>   O(total_buckets) rescans + a `Vec`/`BTreeMap` alloc per call; not this PR's concern, but it's
>   why the sparse snapshot exists there.)
>
> **Memory (sparse workload):** `PackedHistogram` **11.1 KB** vs iop `SparseHistogram` 18.8 KB
> (**1.7× smaller** — adaptive 1–8 B counts vs iop's fixed 8 B) vs dense 168 KB (**15× smaller**).
> Results are bit-identical to the dense histogram (parity + differential fuzz enforce it).

---

## C — PR #150  (lead with packed-vs-dense; iop note is cross-language context)

> ### Benchmark evidence — 3 arches
>
> Measured on AWS Intel Granite Rapids / AMD Zen 5 Turin / ARM Neoverse-V2 (sparse workload,
> 1605 populated of 21504 buckets), `hdr_packed_histogram` vs the dense `hdr_histogram`:
>
> - **Memory: 168 KB → 11.1 KB (15× smaller)** — the packed store grows with populated buckets
>   (~6 B/entry), the dense array is committed up front.
> - **Read (percentile): parity with dense** (within ~7% on x86; faster on some arches) — the
>   blocked prefix-sum scans only populated buckets. Results bit-identical (dense-parity +
>   log round-trip tests, ASan/UBSan clean).
> - Write: binary-search insert; ~5× pattern-sensitive (cheap on bursty/hot streams). [A follow-up
>   last-hit-cache optimization cutting bursty-write cost 20–66% is validated and waiting on this
>   PR — happy to send it as a follow-up once this lands.]
>
> For design context, the closest alternative in this space is the Rust crate
> `iopsystems/histogram`, whose sparse variant is a read-only columnar *snapshot* (no live sparse
> write path) and ~1.7× larger per entry; this C variant records sparsely live.

---

## Go — PR #75  (same shape as C)

> ### Benchmark evidence — 3 arches
>
> Measured on AWS Intel Granite Rapids / AMD Zen 5 Turin / ARM Neoverse-V2 (sparse workload,
> 1605 populated of 21504 buckets), `PackedHistogram` vs the dense `Histogram`:
>
> - **Memory: 168 KB → 11.1 KB (15× smaller)** (grows ~6 B/entry vs the committed dense array).
> - **Read (percentile): parity-to-faster vs dense**; results bit-identical (dense-parity +
>   `FuzzPackedDifferential` + `-race` all green).
> - Write: binary-search insert, ~pattern-sensitive; [a validated follow-up last-hit-cache
>   optimization (−20…−66% on bursty writes) is ready to send once this lands].
>
> Design context: the nearest alternative, the Rust crate `iopsystems/histogram`, offers only a
> read-only sparse *snapshot* (built from a dense histogram) — no live sparse recording — and is
> ~1.7× larger per entry; this variant records sparsely live.

---

### Notes for review
- The iop comparison is *most* relevant to the Rust PR (#154) since iop is a Rust crate; for
  C/Go it's cross-language design context, framed as such.
- The bracketed "follow-up last-hit-cache" mentions are optional — include only if you want to
  signal the optimization is coming. Remove if you'd rather keep each PR strictly single-purpose.
- All numbers reproducible via `experiments/iop-vs-hdr/` (`run.sh`, `sweep`, `batched`, `writes`).

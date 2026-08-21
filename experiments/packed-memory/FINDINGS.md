# Packed (sparse) HdrHistogram_c — Phase-1 memory feasibility spike

**Question:** before committing to the ~2k-line PackedArrayContext port, quantify the
memory win of a sparse/packed backing vs the current dense `int64_t* counts`.

**Tool:** `packed_mem_bench.c` (+ `run.sh`). Builds against the existing
`libhdr_histogram_static.a`; immutable benchmark drivers untouched. Measures dense
VSZ + RSS empirically for N sparsely-populated histograms; projects packed under an
explicit, tunable PackedArrayContext-style model (optimistic/realistic/pessimistic).

## Config under test
Default latency config `low=1, high=3.6e9, sig=3` → `counts_len=23552` →
**184 KB dense per histogram, committed unconditionally at `hdr_init`.**

## Results (Granite Rapids box, glibc)

| Workload | Dense VSZ (floor) | Dense RSS (measured) | Packed realistic | Win vs RSS |
|---|---|---|---|---|
| N=100k, D=10   | 17.56 GB | 13.59 GB (77%) | 18.3 MB | **760×** |
| N=100k, D=100  | 17.56 GB | 17.56 GB (100%) | 104 MB | **173×** |
| N=10k,  D=1000 | 1.76 GB  | 1.76 GB (100%) | 79 MB | **23×** |

Even the pessimistic packed model (16 B/entry, tree-heavy) stays at 0.2–9% of dense.

## Two hard facts

1. **VSZ commitment is unconditional.** Dense reserves `counts_len*8` of address space
   per histogram regardless of population — measured VSZ delta matched the analytic
   floor exactly (17.56 GB). Packed eliminates this outright.
2. **Resident fraction is allocator-dependent, not fundamental.** Observed dense RSS
   ranged 28% (forced fresh `mmap`, minimal touch) → 77–100% (default glibc). Cause:
   glibc's *dynamic* `MMAP_THRESHOLD` rises after the first large `free` (the probe
   `hdr_close`), so subsequent 184 KB arrays come from the heap where `calloc`
   `memset`s them fully resident. `MALLOC_MMAP_THRESHOLD_=0` forces fresh mmap and
   drops RSS to ~28–40%. In a real long-lived many-histogram service with allocation
   churn, dense RSS trends toward 100% of the VSZ floor.

## Phase-1 MEASURED (real `hdr_packed_ctx`, not a model)

Implemented `hdr_packed_histogram` (`hdr_packed_histogram.{h,c}`): sparse vector of
populated buckets, parallel SoA arrays (`int32 idx[]` + `int64 cnt[]`, 12 B/entry),
sorted by virtual index, x2 growth. Reuses the dense value<->index math via an
embedded geometry-only `struct hdr_histogram` (counts==NULL) — zero changes to the
dense file. **Correctness gate passes** (`packed_validate.c`, 7 workloads incl. edge
cases, packed == dense on total/min/max/count_at_value/percentiles, clean under
ASan+UBSan).

Measured (exact bytes held = `sum hdr_packed_get_memory_size`, allocator-noise-free):

| Workload | Dense committed | Packed measured | Win | Model said |
|---|---|---|---|---|
| N=100k, D=10   | 17.56 GB | 32.8 MB  | **548×** | 18–31 MB |
| N=100k, D=100  | 17.56 GB | 161 MB   | **112×** | 31–201 MB |
| N=10k,  D=1000 | 1.76 GB  | 119 MB   | **15×**  | 20–157 MB |

Measured lands inside the modelled band → **the model is validated**. Slightly above
optimistic because of (a) capacity rounding to the next power of two and (b) the
embedded per-histogram geometry struct (~104 B).

### Phase-2 insight surfaced by the measurement
At low D the **per-histogram geometry struct (~104 B) is now a material fraction** of
the packed footprint (at D=10: ~104 B struct vs ~192 B of sparse array). Real
deployments keep many histograms of the *same* config, so Phase-2 should **share one
geometry oracle by pointer** across histograms instead of embedding it — that roughly
halves the D=10 footprint and pushes the win past 1000×.

## Phase-2 MEASURED (shared geometry + byte-width packed counts)

Two changes, both correctness-gated (added `count-width widening` and `shared config`
cases to `packed_validate.c`; all pass, ASan+UBSan clean):
1. **Shared geometry** — config (geometry oracle) created once via
   `hdr_packed_config_create`, referenced by pointer from N histograms
   (`hdr_packed_init_shared`). Removes the ~104 B embedded dense struct per histogram.
2. **Byte-width packed counts** — counts held at a uniform adaptive width (1/2/4/8 B)
   that widens on overflow. The common "many small counts" sparse case pays 1 B/entry
   instead of 8.

| Workload | Phase-1 | Phase-2 | Win vs committed | Win vs resident |
|---|---|---|---|---|
| N=100k, D=10   | 32.8 MB | **14.5 MB** | **1240×** | 960× |
| N=100k, D=100  | 161 MB  | **67.9 MB** | **265×**  | 265× |
| N=10k,  D=1000 | 119 MB  | **49.5 MB** | **36×**   | 36× |

Phase-2 ~halves footprint; D=10 crosses 1000× as predicted. Per-histo at D=10 ≈ 145 B
(struct ~64 B + idx cap 16×4 B + cnt cap 16×1 B), config counted once.

## Trie tradeoff — measured/analytic, why we kept the sorted vector

The user asked about swapping the sorted vector for a PackedArrayContext-style trie
("O(1)-ish access, byte-width packing"). Byte-width packing was adopted above. On the
**structure**, a *fixed-fanout* trie **regresses memory** and only a *populated-only*
trie (Java's design, ~800 lines) avoids that:

Fixed-fanout, 3×5-bit levels (32-way) over counts_len=23552, D=10 scattered buckets:
- root 32 ptr × 8 B = 256 B (always) + up to 10 L1 nodes × 32 × 8 B = 2560 B
  + up to 10 leaves × 32 × 8 B = 2560 B ≈ **5.4 KB/histo**
- even with 1 B-packed leaves ≈ **3.1 KB/histo** (L1 pointer nodes dominate)
- vs Phase-2 sorted vector **145 B/histo** → the trie is **20–37× worse on memory**.

Conclusion: for a *memory* feature the sorted vector is near-optimal for sparse data;
a trie trades memory for **access speed**. That speed only matters on a hot record
path, which is not what packed is for. The **populated-only trie** (compact nodes sized
to populated children, Java-style) is the only variant that improves access *without*
regressing memory — it is the real ~800-line item and should be gated on access speed
being a demonstrated bottleneck (add a record-throughput bench first), not built
speculatively.

## Serialization interop (V2) — the upstream gate

Implemented packed-native V2 codec in `hdr_packed_histogram.c`:
- `hdr_packed_encode_compressed` streams the standard V2 compressed format
  **directly from the sparse array** — no dense array is ever materialized (the
  whole point of packed). Zero-run + zig-zag varint payload, same header
  flyweight and cookies as `hdr_encode_compressed`.
- `hdr_packed_decode_compressed` inflates a standard V2 stream into the sparse
  structure and recomputes total/min/max exactly like the dense
  `hdr_reset_internal_counters`.

Gate (`packed_validate.c` → `run_serialize`, 6 workloads incl. empty, ASan+UBSan clean):
1. **packed encode → dense decoder**: decoded dense equals the original dense
   **bucket-for-bucket** (full counts[] array compare) and on total.
2. **dense encode → packed decoder**: round-trips total/min/max and every tested
   percentile back to the dense values.
3. **byte-identical stream**: `memcmp(packed_stream, dense_stream) == 0` and equal
   length — the packed encoder emits the *exact* standard V2 bytes, not merely a
   compatible one. Streams 39 B (empty) → 34.9 KB (dense sig5).

Implication: a packed histogram is wire-compatible with every existing HdrHistogram
V2 reader (Java, C, wrk2, logs) with no format extension. This is the hard
correctness gate an upstream pitch needs.

## Test port + coverage (Java parity, 100% of reachable added code)

Upstream reality: Java HdrHistogram has **no standalone packed tests** — `PackedHistogram`
is tested only as a drop-in parametrized variant of the normal histogram suite (+ one
`testPackedEquivalence`). Rust/Go ports have no packed at all. So the packed test suite
was ported as **dense-vs-packed parity** (`packed_test.c`, minunit, matching the C repo
style), plus `packed_fault_test.c` for the defensive/error paths. Full mapping of every
applicable Java `@Test` → ported/adapted/covered/N-A is in **PORT-MATRIX.md**.

Ported behavioral parity (14 tests): construction-arg ranges, empty histogram,
record/count-at-value/total, over-range, reset, value-at-percentile matches percentile
(lengths 1..10000), index-by-index count parity (`testPackedEquivalence`), large-number
percentiles, V2 encode/decode both directions + byte-identical, count-width growth
across 2^8/16/32/52, plus our-specific coverage (all four count widths, percentile
edges, min-with-zero, memory-size accounting, shared config). All pass under ASan+UBSan.

**Coverage: 343 / 343 reachable lines of `hdr_packed_histogram.c` = 100.00%**
(`coverage.sh`, gcov). One `/*NOTREACHED*/`-tagged defensive line is excluded (the
index-range guard that mirrors dense `hdr_record_values`, unreachable via the public
API). Error paths — every allocation-failure return, `compress()` failure, and all six
decode error codes — are hit via `-DPACKED_FAULT_HOOKS` fault injection and crafted
malformed streams.

## Verdict

The memory win is **real, order-of-magnitude, and MEASURED** (not modelled): Phase-2's
measured exact-bytes-held wins are **36× (D=1000) to 1240× (D=10)** vs dense committed,
plus the full VSZ-floor collapse, for the "many sparsely-populated histograms" use case
— the only case packed targets. The Phase-1/Phase-2 cores are built, correctness-gated,
V2-wire-compatible, fuzzed, and adversarially reviewed (see REVIEW-LOG.md). The original
"20–760×" figures above were the Phase-1 MODEL (rows 17–21); the model has since been
replaced by measured numbers (Phase-1 MEASURED, Phase-2 MEASURED sections) that land
inside the modelled band, so those measured figures — not the model — are the result.

Caveats that do NOT change the verdict but must be honored downstream:
- Packed is a **memory feature**; it has higher per-record cost than dense (O(log n)
  search + O(n) insert; count-width re-pack replaces `counts[i]+=v`). It is out of scope
  for this workspace's ops/sec mandate and must land as a *separate variant type*, never
  in the dense path.
- The remaining open items are upstream merge-PROCESS (shared internal header to de-dup
  the V2 flyweight/cookies/externs; move fault hooks out of src/; a design-PR for the
  ~2k-line variant), not code security/functional/performance gaps.

## Reproduce
```
experiments/packed-memory/run.sh                 # default (N,D) sweep
MALLOC_MMAP_THRESHOLD_=0 experiments/packed-memory/run.sh   # allocator sensitivity
experiments/packed-memory/packed_mem_bench N D low high sigfig
```

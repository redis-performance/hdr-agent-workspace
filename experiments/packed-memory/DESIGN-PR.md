# Design proposal: a memory-optimised sparse/packed HdrHistogram variant for C

*Seed for an upstream design discussion before any code PR. Nothing here changes the
dense `hdr_histogram` type or its hot paths.*

## Problem

Dense `hdr_histogram` commits `counts_len * 8` bytes of `counts[]` **unconditionally at
`hdr_init`**, regardless of how many buckets are ever populated. For the default latency
config (`low=1, high=3.6e9, sig=3` → `counts_len = 23552`) that is **184 KB per
histogram, reserved up front**.

That is fine for one histogram. It hurts badly for the **"many sparsely-populated
histograms"** shape that shows up in real services: per-connection / per-endpoint /
per-tenant / per-time-window histograms, where each holds only tens to hundreds of
distinct values but still pays the full dense footprint.

Two measured facts (glibc, a recent x86-64 server microarch):

1. **VSZ commitment is unconditional.** N=100k histograms reserve **17.56 GB** of address
   space whether or not they are populated — the measured VSZ delta matched the analytic
   `counts_len*8*N` floor exactly.
2. **Resident fraction trends to 100%.** Observed dense RSS ranged 28% (forced fresh
   `mmap`, minimal touch) → 77–100% (default glibc, because its dynamic `MMAP_THRESHOLD`
   rises after the first large `free`, so later arrays come from the heap where `calloc`
   `memset`s them fully resident). A long-lived many-histogram service trends toward the
   full VSZ floor resident.

Java already solved this with `PackedHistogram` (a `PackedArrayContext` trie backing). C,
Rust, and Go have **no** packed variant.

## Proposal

Add a **separate opt-in variant type**, `hdr_packed_histogram`, whose backing store grows
with the number of *populated* buckets, not with `counts_len`. It reuses the dense bucket
geometry and value↔index mapping exactly, and speaks the **standard V2 wire format**, so
it is a drop-in for storage/serialization while being a distinct in-memory type.

Explicit non-goal: this is **not** a replacement for dense and **never** touches the dense
record/read hot paths. It is a *memory* feature with a higher per-record cost (O(log n)
search + O(n) insert on a new bucket). Dense stays the default for throughput.

### Backing structure

Sorted **virtual-index vector** (SoA): `int32 idx[]` (populated bucket indices, ascending)
parallel to an **adaptive byte-width count blob** `cnt` (uniform width 1/2/4/8 B that
widens on overflow). The common "many small counts" case pays 1–2 B/entry instead of 8.

- Record: binary-search `idx[]`; hit → increment in place (widen width on overflow);
  miss → `memmove` insert (x2 growth). Count-width re-pack fires at most 3 times over a
  histogram's life (1→2→4→8).
- A **shared geometry oracle** (`hdr_packed_config`) holds the bucket config once and is
  referenced by pointer from N histograms of the same config — so per-histogram fixed
  overhead is ~64 B, not the ~104 B dense geometry struct.
- Deliberately **not** a fixed-fanout trie: for sparse data a fixed-fanout trie *regresses*
  memory (pointer nodes dominate — measured 20–37× worse than the sorted vector). Only a
  populated-only trie (Java's design, ~800 lines) avoids that, and it buys *access speed*,
  not memory — so it is deferred behind a demonstrated record-throughput bottleneck.

### Measured memory win (exact bytes held, allocator-noise-free)

| Workload | Dense committed | Packed | Win vs committed |
|---|---|---|---|
| N=100k, D=10   | 17.56 GB | 14.5 MB | **1240×** |
| N=100k, D=100  | 17.56 GB | 67.9 MB | **265×** |
| N=10k,  D=1000 | 1.76 GB  | 49.5 MB | **36×** |

(D = distinct populated buckets per histogram.)

### Wire compatibility

`hdr_packed_encode_compressed` streams the **standard V2 compressed format directly from
the sparse backing** — no dense array is ever materialized — and the bytes are
**byte-identical** (`memcmp == 0`) to `hdr_encode_compressed` on an equivalent dense
histogram. `hdr_packed_decode_compressed` reads standard V2 back into the sparse form.
Verified both directions against the dense codec (packed encode → dense decode →
bucket-for-bucket equal; dense encode → packed decode → equal). So packed is compatible
with every existing HdrHistogram V2 reader (Java, C, wrk2, logs) with no format extension.

Decode is *stricter* than dense on hostile input: it bounds `counts_limit` against the
geometry (rejects a decompression-bomb allocation the dense decoder currently allows),
and rejects a non-zero `normalizing_index_offset` (packed histograms are never rotated)
rather than mis-indexing it.

### Semantics vs dense

For every legitimately-recorded histogram, packed is **bit-for-bit identical to dense** on
`count_at_value`, `min`, `max`, `total_count`, and the V2 encoding, and on
`value_at_percentile` when `total_count ≤ 2^52`. There are 8 documented divergences, each
occurring **only at a point where dense is undefined/UB or FP-imprecise** — packed never
returns a silently-wrong answer on a valid in-range input, and is provably *more* correct
at each divergence (e.g. saturates count sums at INT64_MAX instead of overflowing; clamps
the percentile target so `p100 == max` holds even above 2^52; bounds `count_at_value` on
an out-of-range value instead of reading `counts[]` OOB). Full list in the header.

## Testing / review evidence

- 23 unit/parity tests (dense-vs-packed) + a fault-injection suite (every allocation-fail,
  compress-fail, and decode-error branch) + a 3-mode libFuzzer harness (differential vs
  dense, hostile raw-decode, corrupt-roundtrip).
- Green under **strict** `-fsanitize=address,undefined,float-cast-overflow`
  `-fno-sanitize-recover=all`, `UBSAN_OPTIONS=halt_on_error=1`.
  (Note for the CI: gcc's `-fsanitize=undefined` omits `float-cast-overflow` — it must be
  listed explicitly, and clang is stricter here.)
- **100% of reachable lines** (361/361; 2 auditable defensive exclusions), 94% branch.
- Converged via a 10-round adversarial review; the last 3 real bugs were found *only* by a
  red-team pass after all lens-reviewers had cleared the code.

## Open questions for the maintainer

1. **Shape of the contribution.** A single new `.c`/`.h` variant alongside the dense files,
   opt-in at build time? Or a subdir? It adds ~2k lines and does not touch dense.
2. **Shared internal header.** The V2 flyweight structs / cookies / `zig_zag`/base64
   externs are currently duplicated from `hdr_histogram_log.c` / `hdr_encoding.c`. Landing
   cleanly wants a small shared *internal* header so packed and dense share one definition
   rather than copying. Happy to do that refactor as a prerequisite PR if you want it split
   out.
3. **API naming.** Current surface mirrors dense with an `hdr_packed_` prefix
   (`hdr_packed_init` / `_init_shared`, `_record_value(s)`, `_value_at_percentile(s)`,
   `_encode/decode_compressed`, `_get_memory_size`). Any naming/convention you'd prefer?
4. **Fault hooks.** The `-DPACKED_FAULT_HOOKS` injection points used to cover error paths
   in tests should move out of the shipped TU (compiled only for the test build). Confirm
   that matches how you'd want it structured.
5. **Scope guard.** Agreed that this lands as a *separate type* and the dense hot paths are
   untouched? That is the core constraint on our side.

## Suggested landing order

1. (optional) prerequisite PR: shared internal header de-duplicating the V2
   flyweight/cookies/codec externs.
2. design sign-off on the API surface + build integration (this document).
3. the variant PR: `hdr_packed_histogram.{c,h}` + tests + fuzzer + CI job.

Reproduce the memory numbers: `experiments/packed-memory/run.sh` (source in this branch).

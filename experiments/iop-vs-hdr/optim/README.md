# PackedHistogram write-path optimization — last-hit cache (Rust · C · Go)

A portable write-path optimization for the sparse/packed HdrHistogram variant, discovered
during the iop-vs-hdr campaign (see `../JOURNAL.md`, ticks 11–27). Prototyped and validated in
**all three ports** across **Intel Granite Rapids, AMD Zen 5, and ARM Neoverse-V2**. Kept
isolated from the open PRs (#154 Rust, #150 C, #75 Go) until it clears adversarial review.

## Problem

Every packed port records via a binary search into a sorted `idx[]` of populated flat
counts-indices — `record → lower_bound → hit: increment / miss: insert` — on **every** call.
The write-pattern experiment (`../src/bin/writes.rs`) showed this is 1.6–5× pattern-sensitive:
worst on low-locality random streams, but even a `hot90` stream (90 % of records hitting one
bucket) pays the full search every time. Real latency streams are bursty (temporal locality),
so the search is mostly redundant.

## Change

A **1-entry last-hit cache**: remember the flat counts-index touched by the previous record
and its position in `idx`. If the next value maps to that same index **and** `idx[last_pos]`
still equals it (the recheck keeps it correct across insert-driven position shifts), increment
in place and skip the binary search. The fast path reuses the *exact* width-aware
increment + overflow-widen sequence from the search-hit branch (refactored into a shared
helper — Rust: inline; C: `sparse_hit_add`; Go: `addAtExisting`), so results are bit-identical.
`sparse_add`/`sparseAdd` now returns the final position to seed the cache on a miss. Cache is
invalidated on reset and after decode. None of the three ports has an atomic/threaded record
variant, so there is no second path to mirror. No public API change.

Patches: `packed-lasthit-cache.patch` (Rust) · `c-packed-lasthit-cache.patch` (C) ·
`go-packed-lasthit-cache.patch` (Go). Microbenches: `c-packbench.c`, `go-packed_writepat_test.go`,
and the Rust `../src/bin/writes.rs`.

## Correctness (all green, results bit-identical)

- **Rust** @ `386b655`: full `cargo test --release` — **AMD 310/0, ARM 310/0** — incl.
  `parity_random`, `fuzz_differential`, `fuzz_hostile_decode`, V2 byte-identical serialization;
  clippy clean. (The lone Intel `sync::mt_record_static` failure is a **pre-existing flaky race
  in the dense `SyncHistogram`** — fails ~10/15 on the *untouched* crate; the packed-only patch
  cannot reach that path.)
- **C** @ `f58401c`: `ctest` 6/6 base + patched on all three archs; packed test clean under
  **ASan + UBSan**; populated/total bit-identical.
- **Go** @ `01939f5`: `go test ./...` + **`-race`** + **`FuzzPackedDifferential`** (51k execs,
  0 failures); whitebox checksum over every `(idx[i], count[i])` identical base vs patch; green
  on all three archs.

## Measured — write ns/op, base → patch (median of 3, ~1600 buckets)

**clustered (max locality)** and **hot90 (90 % one bucket)** — the win:

| lang | Intel clustered | AMD clustered | ARM clustered | Intel hot90 | AMD hot90 | ARM hot90 |
|---|--:|--:|--:|--:|--:|--:|
| Rust | −43% | −48% | −66% | −29% | −25% | −50% |
| C    | −59% | −58% | −44% | −31% | −31% | −19% |
| Go   | −49% | −54% | −59% | −33% | −30% | −39% |

**random (low locality)** — the cost:

| lang | Intel | AMD | ARM |
|---|--:|--:|--:|
| Rust | ~0% | +1% | +1% |
| C    | +1.2% | +1.1% | +1.8% |
| Go   | +2.4% | +9.4% | +6.4% |

## Honest caveat & mitigation

On pathological **low-locality (random)** streams the cache never hits, so its guarded compare
+ two seed-stores are pure overhead: **~1 % in C/Rust** (within noise), but **+2–9 % in Go**
and arch-sensitive. The read path is untouched everywhere. Options for review, per language:

1. **Accept as-is** — the tradeoff is strongly favorable for the sparse-histogram use case
   (many bursty per-entity latency streams), which is the whole reason packed exists.
2. **Gate the fast path** behind a cheap heuristic if a port must protect cold-random writes.

**Ruled out — bounds-check elision (tick 28, negative result):** the Go tax is *not* a
bounds-check cost. The `idx[lastPos]` load lives on the *hit* path (guarded by
`lastIndex == ci`, which short-circuits on random), so it never executes on a random miss.
Eliminating that bounds check (verified via `-d=ssa/check_bce`) left random unchanged. The real
cost is the **miss path**: the extra compare + two unconditional seed-stores (`lastIndex`,
`lastPos`) on every record — a small inherent cost of keeping the cache warm, only removable by
gating (option 2).

Verdict: a robust, portable **20–66 % write win on realistic bursty/hot streams**, bit-identical
results, correctness green on 3 langs × 3 archs. **Candidate follow-up PR per language**, gated on
the adversarial review and the maintainer's call on the random-write tradeoff.

## Apply / reproduce (example: Rust)

```sh
cd HdrHistogram_rust && git apply ../experiments/iop-vs-hdr/optim/packed-lasthit-cache.patch
cargo test --release
cd ../experiments/iop-vs-hdr && cargo build --release --bin writes && ./target/release/writes
```
C: `git apply c-packed-lasthit-cache.patch` in `HdrHistogram_c`, `ctest`, build `c-packbench.c`.
Go: `git apply go-packed-lasthit-cache.patch` in `hdrhistogram-go`, `go test ./...`, `go test -bench WritePat`.

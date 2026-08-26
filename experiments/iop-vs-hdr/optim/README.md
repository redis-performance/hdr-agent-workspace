# hdr-packed write-path optimization — last-hit cache

Candidate optimization for the Rust `PackedHistogram` write path, discovered during the
iop-vs-hdr campaign (see `../JOURNAL.md`, ticks 11–14). **Not** part of PR #154 — this is a
follow-up experiment kept isolated until it clears same-machine server validation and an
adversarial review.

## Problem

`PackedHistogram::record` binary-searches the sorted `idx: Vec<u32>` on **every** call.
The write-pattern experiment (`../src/bin/writes.rs`) showed the cost is 1.6–5×
pattern-sensitive: worst on low-locality random streams, but even a `hot90` stream (90 % of
records hitting one bucket) pays ~14–25 ns/op because it searches every time.

## Change (`packed-lasthit-cache.patch`)

A 1-entry last-hit cache: remember the flat counts-index touched by the previous record and
its position in `idx`. If the next value maps to that same index **and** `idx[last_pos]`
still equals it (re-check keeps it correct across insert-driven shifts), increment in place
and skip the binary search. The fast path reuses the exact
`slot_get`/`saturating_add`/`widen_to_fit`/`slot_set` sequence from `sparse_add`'s found
branch — widening leaves `idx` positions fixed, so `last_pos` stays valid. `sparse_add` now
returns the final position so the miss path can seed the cache. No atomic variant exists
(single-threaded struct), so there is no second path to mirror. No public API change.

## Correctness

Applied to `HdrHistogram_rust` @ `386b655`, the **full** `cargo test --release` suite passes
(172 lib tests + integration), including the load-bearing `parity_random`,
`fuzz_differential`, `fuzz_hostile_decode`, `width_growth`, and the byte-identical V2
serialization round-trips. `cargo clippy` clean (no new warnings on `packed.rs`). Results are
bit-identical to baseline (parity/fuzz enforce it); the cache only reorders *how* a count is
reached, never the count.

## Apply / reproduce

```sh
cd HdrHistogram_rust
git apply ../experiments/iop-vs-hdr/optim/packed-lasthit-cache.patch
cargo test --release            # must stay green
cd ../experiments/iop-vs-hdr
cargo build --release --bin writes && ./target/release/writes   # base vs patch
```

## Measured (see JOURNAL for the server table)

Directional (laptop): clustered −41.5 %, hot90 −25.8 %, random +2.8 % (one extra guarded
compare on a near-always-miss stream; within run-to-run noise). Server numbers in the journal.

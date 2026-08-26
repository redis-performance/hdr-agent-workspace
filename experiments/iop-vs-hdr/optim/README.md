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

## Measured — hdr-packed write ns/op (base → patch), 3 AWS archs

Same-machine base-vs-patch, median of 3 runs, N=4M ops, ~1600 buckets, `hp_pop`=1605 both
sides (results bit-identical):

| pattern | Intel GNR | AMD Zen 5 | ARM N-V2 |
|---|--:|--:|--:|
| random    | 54.4→54.4 (0%)      | 47.5→48.0 (+1%)     | 28.6→28.9 (+1%) |
| clustered | 10.4→5.9 (**−43%**) | 8.6→4.5 (**−48%**)  | 18.1→6.2 (**−66%**) |
| hot90     | 17.4→12.3 (**−29%**)| 13.8→10.3 (**−25%**)| 24.6→12.4 (**−50%**) |

Large win on locality-favorable (bursty/hot) streams — the packed histogram's real use case —
normalizing clustered writes to ~6 ns across all archs; free on pathological low-locality
streams (one guarded compare, within noise). Full `cargo test --release` on the patched crate:
**AMD 310/0, ARM 310/0**. The single Intel `sync::mt_record_static` failure is a pre-existing
flaky race in the *dense* `SyncHistogram` (fails ~10/15 on the untouched crate too) — the
packed-only patch cannot reach that path. Verdict: **candidate follow-up upstream PR**, gated on
an adversarial review pass.

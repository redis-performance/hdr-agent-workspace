# race/ — cross-port race drivers

One standalone driver per language, all running the **identical** HdrHistogram workload so C, Rust,
and Go are directly comparable. See [`../experiments/RACE.md`](../experiments/RACE.md) for the
scoreboard, methodology, and findings.

```
race/
  c/race.c            links HdrHistogram_c static lib
  go/  (go.mod)       replace → ../../hdrhistogram-go
  rust/ (Cargo.toml)  path dep → ../../HdrHistogram_rust
```

Each prints:
```
WRITE_OPS_PER_SEC <n>
READ_MQ_PER_SEC <n> sink=<n>
```

`sink` (sum of all returned percentile values) is a **cross-port correctness check** — it must be
identical across C/Go/Rust for a given workload. Keep the three drivers in lock-step: any change to
the workload (config, value distribution, percentiles, iteration counts) must be applied to all three.

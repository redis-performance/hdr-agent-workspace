# Skill: profile

Profile a HdrHistogram_c benchmark driver and identify the hottest symbols.

## Steps

1. Build with debug info (RelWithDebInfo keeps `-g`):
   ```bash
   scripts/build-bench.sh
   ```
2. Profile the path of interest:
   ```bash
   scripts/run-profile.sh                 # DRIVER=write (default) — hdr_histogram_perf
   DRIVER=read scripts/run-profile.sh     # read path — hdr_percentile_bench
   ```
3. Parse the report:
   - Top symbols by CPU % (look for `counts_index_for`, `get_bucket_index`,
     `counts_inc_normalised`, `normalize_index`, `update_min_max`,
     `get_value_from_idx_up_to_count`).
   - IPC, branch-miss rate, cache-miss rate from the `perf stat` block.
   - Unexpected symbols (memcpy, libc).

## Key Metrics
| Metric | What to look for |
|--------|-----------------|
| Hottest write symbol | usually `counts_index_for` / record path |
| `normalize_index` % | should be ~0 after PR #135 — if hot, regression |
| `update_min_max` store pressure | cache-line write traffic on writes |
| Read-path `get_value_from_idx_up_to_count` | dense scan cost |
| Branch-miss rate | > 3% is a red flag on the record loop |
| IPC | higher is better; < 2.0 suggests stalls |

## Output Format
```
Top symbols (write path):
  N.N%  counts_index_for
  N.N%  counts_inc_normalised
  N.N%  update_min_max

perf stat:
  instructions/cycle : N.NN
  branch miss rate   : N.NN%
  cache miss rate    : N.NN%
```
Then map the hottest symbol to a tier via `.claude/program.md` Bottleneck Classification.

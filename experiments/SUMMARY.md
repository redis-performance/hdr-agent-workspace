# Experiment Summary — hdr-agent-workspace

Single source of truth for experiment status. Keep `README.md` counts in sync.

| Status | Count |
|--------|------:|
| Accepted | 0 |
| Rejected | 1 |
| Parked | 0 |
| In Progress | 0 |

See `EXPERIMENTS.md` "Prior art" for the merged fork PRs (#134/#135/#136 merged, #133 re-applied
by maintainer, #137 open) that this workspace builds on.

| EXP | Date | Target | Technique | Decision | Δ (target path) | Upstream |
|-----|------|--------|-----------|----------|-----------------|----------|
| [001](EXPERIMENTS.md#exp-001--2026-07-01--fuse-counts_index_for-algebraic-cancel-of-sub_bucket_half_count) | 2026-07-01 | write | Tier 1a fuse `counts_index_for` | REJECT | gcc +5.9% / **clang −12.1%** | — |

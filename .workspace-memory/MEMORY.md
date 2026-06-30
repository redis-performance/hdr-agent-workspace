# Workspace Memory — hdr-agent-workspace

Persistent memory index. One entry per file. Committed to main so all agent backends
share the same context. **Public repo — sanitize every entry** (no secrets/IPs/customer/
Slack/ticket references).

- [hdr-upstream-prs](hdr-upstream-prs.md) — fork PRs to HdrHistogram/HdrHistogram_c (#134/#135/#136 merged, #133 re-applied, #137 open) + how to open them
- [hdr-review-mo](hdr-review-mo.md) — @mikeb01's review M.O. + the adversarial correctness catches (offset-aware path, atomic twin, signed-shift rule)
- [benchmark-setup](benchmark-setup.md) — how to build + run the write/read benchmark drivers and measure cleanly

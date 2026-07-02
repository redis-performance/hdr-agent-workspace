#!/usr/bin/env python3
"""Cross-port race chart: C vs Rust vs Go, write + read throughput."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

ports  = ["C\n(fork: widen+prefetch)", "Rust\n(fork)", "Go\n(upstream)"]
colors = ["#2166ac", "#d1691e", "#00add8"]   # C blue, Rust orange, Go gopher-cyan

write_mops = [406.166, 349.875, 323.240]     # million record_value ops/sec
write_ns   = [2.46, 2.86, 3.09]              # ns per record
read_mqs   = [0.5549, 0.1738, 0.0457]        # million value_at_percentile queries/sec
read_us    = [1.80, 5.75, 21.88]             # microseconds per query

fig, (axw, axr) = plt.subplots(1, 2, figsize=(12, 5.2))
fig.suptitle("HdrHistogram cross-port race — gnr1 (Intel Granite Rapids), single core\n"
             "identical workload · percentile results byte-identical across ports (sink match)",
             fontsize=12, fontweight="bold")

x = np.arange(len(ports))

# WRITE panel
bw = axw.bar(x, write_mops, color=colors, width=0.6, edgecolor="black", linewidth=0.6)
axw.set_title("WRITE — record_value()  (higher is better)", fontsize=11)
axw.set_ylabel("million ops / sec")
axw.set_xticks(x); axw.set_xticklabels(ports, fontsize=9)
axw.set_ylim(0, max(write_mops) * 1.18)
for i, b in enumerate(bw):
    axw.text(b.get_x() + b.get_width()/2, b.get_height() + max(write_mops)*0.015,
             f"{write_mops[i]:.0f} M/s\n{write_ns[i]:.2f} ns/op",
             ha="center", va="bottom", fontsize=9)
axw.text(0.5, -0.16, "1 op = insert one sample (bucket index → counter++ → min/max)",
         transform=axw.transAxes, ha="center", fontsize=8, color="#555")

# READ panel
br = axr.bar(x, read_mqs, color=colors, width=0.6, edgecolor="black", linewidth=0.6)
axr.set_title("READ — value_at_percentile()  (higher is better)", fontsize=11)
axr.set_ylabel("million queries / sec")
axr.set_xticks(x); axr.set_xticklabels(ports, fontsize=9)
axr.set_ylim(0, max(read_mqs) * 1.18)
for i, b in enumerate(br):
    axr.text(b.get_x() + b.get_width()/2, b.get_height() + max(read_mqs)*0.015,
             f"{read_mqs[i]:.3f} Mq/s\n{read_us[i]:.1f} µs/query",
             ha="center", va="bottom", fontsize=9)
# blowout callout
axr.annotate("C is 3.2× Rust, 12× Go",
             xy=(2, read_mqs[2]), xytext=(1.35, max(read_mqs)*0.72),
             fontsize=9, color="#b2182b", fontweight="bold",
             arrowprops=dict(arrowstyle="->", color="#b2182b"))
axr.text(0.5, -0.16, "1 op = one percentile query (scans thousands of counts[])",
         transform=axr.transAxes, ha="center", fontsize=8, color="#555")

fig.tight_layout(rect=[0, 0.02, 1, 0.92])
out = "/home/fco/redislabs/hdr-agent-workspace/experiments/RACE-baseline/race-gnr1-2026-07-02.png"
fig.savefig(out, dpi=140)
print("wrote", out)

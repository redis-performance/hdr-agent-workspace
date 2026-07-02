#!/usr/bin/env python3
"""Cross-port race chart: C vs Rust vs Go — write, single-percentile read, batch (all 7)."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

ports  = ["C\nv0.11.10", "Rust\n7.5.4", "Go\nv1.2.0"]
colors = ["#2166ac", "#d1691e", "#00add8"]   # C blue, Rust orange, Go gopher-cyan

write_mops = [408.99, 349.64, 299.67]        # million record_value ops/sec
write_ns   = [2.44, 2.86, 3.34]              # ns per record
read_mqs   = [0.2425, 0.1741, 0.0457]        # million single value_at_percentile queries/sec
read_us    = [4.12, 5.74, 21.88]             # microseconds per single query
batch_kops = [12.389, 24.818, 14.604]        # thousand "all-7-percentiles" ops/sec
batch_us   = [80.7, 40.3, 68.5]              # microseconds to get all 7 percentiles
batch_note = ["native\n(iterator)", "no batch API\n(7× singular)", "native\n(1 pass)"]

fig, axes = plt.subplots(1, 3, figsize=(16.5, 5.4))
fig.suptitle("HdrHistogram cross-port race — official releases — gnr1 (Intel Granite Rapids), single core\n"
             "identical workload · results byte-identical across ports (sink + bsink match)",
             fontsize=12, fontweight="bold")

x = np.arange(len(ports))

def bars(ax, vals, labels, title, ylab, note=None):
    b = ax.bar(x, vals, color=colors, width=0.6, edgecolor="black", linewidth=0.6)
    ax.set_title(title, fontsize=11)
    ax.set_ylabel(ylab)
    ax.set_xticks(x); ax.set_xticklabels(ports, fontsize=9)
    ax.set_ylim(0, max(vals) * 1.20)
    for i, bar in enumerate(b):
        ax.text(bar.get_x()+bar.get_width()/2, bar.get_height()+max(vals)*0.015,
                labels[i], ha="center", va="bottom", fontsize=8.5)
    if note:
        ax.text(0.5, -0.16, note, transform=ax.transAxes, ha="center", fontsize=8, color="#555")

bars(axes[0], write_mops,
     [f"{write_mops[i]:.0f} M/s\n{write_ns[i]:.2f} ns/op" for i in range(3)],
     "WRITE — record_value()  (↑ better)", "million ops / sec",
     "1 op = insert one sample")

bars(axes[1], read_mqs,
     [f"{read_mqs[i]:.3f} Mq/s\n{read_us[i]:.1f} µs" for i in range(3)],
     "READ 1 percentile — value_at_percentile()  (↑ better)", "million queries / sec",
     "1 op = one percentile (early-exit counts[] scan)")

bars(axes[2], batch_kops,
     [f"{batch_kops[i]:.1f} K/s\n{batch_us[i]:.0f} µs · {batch_note[i]}" for i in range(3)],
     "READ all 7 — value_at_percentiles()  (↑ better)", "thousand calls / sec",
     "1 op = all 7 percentiles at once")
axes[2].annotate("C's batch API is slowest\n(iterator walks every bucket;\nslower than 7× its own singular ≈29µs)",
                 xy=(0, batch_kops[0]), xytext=(0.15, max(batch_kops)*0.62),
                 fontsize=8, color="#b2182b", fontweight="bold",
                 arrowprops=dict(arrowstyle="->", color="#b2182b"))

fig.tight_layout(rect=[0, 0.02, 1, 0.90])
out = "/home/fco/redislabs/hdr-agent-workspace/experiments/RACE-baseline/race-gnr1-2026-07-02.png"
fig.savefig(out, dpi=140)
print("wrote", out)

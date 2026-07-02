#!/usr/bin/env python3
"""Current (official release) vs Potential (with open optimization PRs) — C / Rust / Go."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

ports = ["C", "Rust", "Go"]
colors = ["#2166ac", "#d1691e", "#00add8"]  # C blue, Rust orange, Go gopher-cyan

# (current, potential, PR-label). gnr1 (Granite Rapids), single core, same-session A/B.
data = {
    "WRITE — record_value()\n(million ops/sec, ↑ better)": {
        "unit": "M ops/s", "scale": 1.0,
        "C":    (408.99, 408.99, "no PR"),
        "Rust": (349.64, 349.64, "no PR"),
        "Go":   (299.67, 324.0,  "#59 merged"),
    },
    "READ 1 percentile — value_at_percentile()\n(million queries/sec, ↑ better)": {
        "unit": "Mq/s", "scale": 1.0,
        "C":    (0.2425, 0.5549, "#138+#139"),
        "Rust": (0.1741, 0.1741, "no PR"),
        "Go":   (0.0457, 0.1066, "#57"),
    },
    "READ all 7 — value_at_percentiles()\n(thousand calls/sec, ↑ better)": {
        "unit": "K calls/s", "scale": 0.001,
        "C":    (12389, 86403,  "#140"),
        "Rust": (24818, 178326, "#138"),
        "Go":   (14604, 58799,  "#58"),
    },
}

fig, axes = plt.subplots(1, 3, figsize=(17, 5.6))
fig.suptitle("HdrHistogram ports — current (official release) vs potential (with open optimization PRs)\n"
             "gnr1 (Intel Granite Rapids), single core · same-session A/B · results byte-identical",
             fontsize=12, fontweight="bold")

x = np.arange(len(ports))
w = 0.38

for ax, (title, d) in zip(axes, data.items()):
    scale = d["scale"]
    cur = np.array([d[p][0] for p in ports]) * scale
    pot = np.array([d[p][1] for p in ports]) * scale
    for i, p in enumerate(ports):
        ax.bar(x[i] - w/2, cur[i], w, color=colors[i], alpha=0.42, edgecolor="black", linewidth=0.5,
               label="current" if i == 0 else None)
        ax.bar(x[i] + w/2, pot[i], w, color=colors[i], edgecolor="black", linewidth=0.7,
               label="potential (PR)" if i == 0 else None)
        mult = d[p][1] / d[p][0]
        lbl = f"{mult:.2f}×" if mult > 1.005 else "—"
        ax.text(x[i] + w/2, pot[i] + max(pot)*0.015, f"{lbl}\n{d[p][2]}",
                ha="center", va="bottom", fontsize=8, color="#b2182b" if mult > 1.005 else "#777",
                fontweight="bold" if mult > 1.005 else "normal")
        ax.text(x[i] - w/2, cur[i] + max(pot)*0.015, f"{cur[i]:.2f}" if scale != 1.0 or cur[i] < 10 else f"{cur[i]:.0f}",
                ha="center", va="bottom", fontsize=7.5, color="#555")
    ax.set_title(title, fontsize=10.5)
    ax.set_ylabel(d["unit"])
    ax.set_xticks(x); ax.set_xticklabels(ports, fontsize=10)
    ax.set_ylim(0, max(pot) * 1.25)
    ax.legend(loc="upper left", fontsize=8, framealpha=0.9)

fig.tight_layout(rect=[0, 0.02, 1, 0.90])
out = "/home/fco/redislabs/hdr-agent-workspace/experiments/RACE-baseline/potential-gnr1-2026-07-02.png"
fig.savefig(out, dpi=140)
print("wrote", out)

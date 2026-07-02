#!/usr/bin/env python3
"""Relative-to-frontier view: current vs potential vs the best-achievable frontier (headroom left)."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

ports = ["C", "Rust", "Go"]
colors = ["#2166ac", "#d1691e", "#00add8"]

# absolute (current, potential); frontier = max(potential) per metric = 100%
metrics = {
    "WRITE — record_value()": {
        "C": (408.99, 408.99), "Rust": (349.64, 349.64), "Go": (299.67, 324.0),
        "note": "memory-bound scatter; all near floor",
    },
    "READ 1 percentile — value_at_percentile()": {
        "C": (0.2425, 0.5549), "Rust": (0.1741, 0.1830), "Go": (0.0457, 0.1833),
        "note": "frontier = C's AVX2; Rust/Go headroom = SIMD",
    },
    "READ all 7 — value_at_percentiles()": {
        "C": (12389, 86403), "Rust": (24818, 178326), "Go": (14604, 83658),
        "note": "frontier = Rust single-pass; C/Go could match",
    },
}

fig, axes = plt.subplots(1, 3, figsize=(17, 5.8))
fig.suptitle("HdrHistogram ports — headroom view: current vs potential (open PRs) vs frontier (best achievable = 100%)\n"
             "gnr1 (Intel Granite Rapids), single core.  Gap from the solid bar up to the dashed line = remaining headroom.",
             fontsize=11.5, fontweight="bold")

x = np.arange(len(ports)); w = 0.38
for ax, (title, d) in zip(axes, metrics.items()):
    frontier = max(d[p][1] for p in ports)
    for i, p in enumerate(ports):
        cur = 100.0 * d[p][0] / frontier
        pot = 100.0 * d[p][1] / frontier
        ax.bar(x[i]-w/2, cur, w, color=colors[i], alpha=0.40, edgecolor="black", linewidth=0.5,
               label="current" if i == 0 else None)
        ax.bar(x[i]+w/2, pot, w, color=colors[i], edgecolor="black", linewidth=0.7,
               label="potential (PR)" if i == 0 else None)
        # headroom annotation on the potential bar
        head = 100.0 - pot
        if head > 1.5:
            ax.annotate("", xy=(x[i]+w/2, 100), xytext=(x[i]+w/2, pot),
                        arrowprops=dict(arrowstyle="<->", color="#b2182b", lw=1.1))
            ax.text(x[i]+w/2+0.04, (pot+100)/2, f"+{head:.0f}%\nheadroom", fontsize=7.5,
                    color="#b2182b", va="center", ha="left", fontweight="bold")
        else:
            ax.text(x[i]+w/2, pot+1.5, "frontier", fontsize=8, color="#2a6", ha="center", fontweight="bold")
        ax.text(x[i]+w/2, pot+ (0.5 if head>1.5 else -6), f"{pot:.0f}%", fontsize=8, ha="center",
                va="bottom" if head>1.5 else "top", color="#333")
    ax.axhline(100, ls="--", color="#b2182b", lw=1.2, alpha=0.8)
    ax.set_title(title, fontsize=10.5)
    ax.set_ylabel("% of frontier (best port's potential)")
    ax.set_xticks(x); ax.set_xticklabels(ports, fontsize=10)
    ax.set_ylim(0, 118)
    ax.text(0.5, -0.13, d["note"], transform=ax.transAxes, ha="center", fontsize=8, color="#666")
    ax.legend(loc="upper right", fontsize=8, framealpha=0.9)

fig.tight_layout(rect=[0, 0.03, 1, 0.90])
out = "/home/fco/redislabs/hdr-agent-workspace/experiments/RACE-baseline/headroom-gnr1-2026-07-02.png"
fig.savefig(out, dpi=140)
print("wrote", out)

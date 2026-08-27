#!/usr/bin/env python3
"""Last-hit write-cache speedup, 3 languages x 3 arches, per workload.
Bars show % write-time reduction (positive = faster). Data: JOURNAL ticks 22-27."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

LANGS = ["Rust", "C", "Go"]
ARCHES = ["Intel GNR", "AMD Zen5", "ARM N-V2"]
# % faster (write-time reduction); negative = regression
CLUSTERED = {"Rust": [43, 48, 66], "C": [59, 58, 44], "Go": [49, 54, 59]}
HOT90     = {"Rust": [29, 25, 50], "C": [31, 31, 19], "Go": [33, 30, 39]}
RANDOM    = {"Rust": [0, -1, -1],  "C": [-1.2, -1.1, -1.8], "Go": [-2.4, -9.4, -6.4]}
PANELS = [("clustered (max locality)", CLUSTERED),
          ("hot90 (90% one bucket)", HOT90),
          ("random (low locality)", RANDOM)]
ARCH_COLOR = ["#4c78a8", "#f58518", "#54a24b"]

fig, axes = plt.subplots(1, 3, figsize=(15, 5), sharey=False)
x = np.arange(len(LANGS)); w = 0.26
for ax, (title, data) in zip(axes, PANELS):
    for j, arch in enumerate(ARCHES):
        vals = [data[l][j] for l in LANGS]
        bars = ax.bar(x + (j - 1) * w, vals, w, color=ARCH_COLOR[j], label=arch)
        for b, v in zip(bars, vals):
            ax.text(b.get_x() + b.get_width() / 2, v + (0.6 if v >= 0 else -0.6),
                    f"{v:g}", ha="center", va="bottom" if v >= 0 else "top", fontsize=7.5)
    ax.axhline(0, color="#333", lw=0.8)
    ax.set_title(title, fontsize=11, fontweight="bold")
    ax.set_xticks(x); ax.set_xticklabels(LANGS)
    ax.grid(True, axis="y", alpha=0.25)
    ax.set_ylim(-12, 72)
axes[0].set_ylabel("write-time reduction %  (positive = faster)")
axes[2].axhspan(-12, 0, color="#d62728", alpha=0.06)  # highlight the small random-regression zone
axes[2].legend(fontsize=9, loc="upper center", title="arch")  # empty space in the random panel
fig.suptitle(
    "Last-hit write-cache speedup — big wins on bursty/hot streams, small cost on cold-random\n"
    "PackedHistogram, 3 languages x 3 arches, bit-identical results (JOURNAL ticks 22-27)",
    fontsize=11)
fig.tight_layout(rect=[0, 0, 1, 0.93])
fig.savefig("writecache_speedup.png", dpi=120)
print("wrote writecache_speedup.png")

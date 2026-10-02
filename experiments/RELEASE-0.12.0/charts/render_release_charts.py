#!/usr/bin/env python3
"""Render the 0.12.0 release charts (SVG + PNG) from the saved fleet measurements.

Reads ../../C-PERFORMANCE-CHARTS/data.json (0.11.10 versus the newer code, per machine) and writes
speedup.*, read.*, list.*, write.* next to this script. Output is deterministic. Needs matplotlib.
"""
import json
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

HERE = Path(__file__).resolve().parent
DATA = json.loads((HERE.parent.parent / "C-PERFORMANCE-CHARTS" / "data.json").read_text())
RUNNERS = DATA["runners"]

OLD, NEW = "#62748b", "#087e75"
INK, MUTED, GRID = "#152332", "#475569", "#e3e9ef"
METRIC_COLORS = {"batch": "#087e75", "read": "#4f9bd9", "write": "#9aa7b8"}
DATA_KEY = {"batch": "list", "read": "read", "write": "write"}  # data.json calls the batch benchmark "list"
METRIC_NAMES = {
    "batch": "Batch: hdr_value_at_percentiles (4 percentiles)",
    "read": "Read: hdr_value_at_percentile",
    "write": "Write: hdr_record_value",
}
CAPTION = (
    "Intel Xeon (Sapphire Rapids), AMD EPYC (Zen 5), AWS Graviton (Neoverse V2): benchmark fleet, one pinned core, runs interleaved with 0.11.10.\n"
    "Apple M6: macOS, which cannot pin a core. Microbenchmarks from the repository's own drivers, not application throughput."
)
NAMES = {"Intel Sapphire Rapids": "Intel Xeon\n(Sapphire Rapids)", "AMD Zen 5": "AMD EPYC\n(Zen 5)",
         "Graviton Neoverse-V2": "AWS Graviton\n(Neoverse V2)", "Apple M6": "Apple M6"}

plt.rcParams.update({
    "svg.fonttype": "path", "svg.hashsalt": "hdrhistogram-0.12.0",
    "font.family": "DejaVu Sans", "text.color": INK, "axes.labelcolor": MUTED,
    "xtick.color": MUTED, "ytick.color": INK, "axes.edgecolor": GRID,
})


def save(fig, name):
    fig.savefig(HERE / f"{name}.svg", metadata={"Date": None})
    fig.savefig(HERE / f"{name}.png", dpi=150, metadata={"Software": None})
    plt.close(fig)


def fmt_ratio(r):
    return f"{r:.0f}x" if r >= 10 else f"{r:.2f}x"


def speedup():
    fig, ax = plt.subplots(figsize=(10, 6.2))
    metrics = ["batch", "read", "write"]
    height, gap = 0.24, 0.9
    ys, labels = [], []
    for i, r in enumerate(RUNNERS):
        base = (len(RUNNERS) - 1 - i) * gap
        for j, m in enumerate(metrics):
            d = r[DATA_KEY[m]]
            v = d["master"] / d["previous"]
            y = base + (1 - j) * height
            ax.barh(y, v - 1, left=1, height=height * 0.86, color=METRIC_COLORS[m],
                    label=METRIC_NAMES[m] if i == 0 else None)
            ax.text(v * (1.07 if v >= 1 else 0.93), y, fmt_ratio(v), va="center",
                    ha="left" if v >= 1 else "right", fontsize=10.5, fontweight="bold")
        ys.append(base)
        labels.append(NAMES[r["name"]])
    ax.axvline(1, color=INK, lw=1.2)
    ax.set_xscale("log")
    ax.set_xlim(0.7, 90)
    ticks = [1, 2, 5, 10, 20, 50]
    ax.set_xticks(ticks, [f"{t}x" for t in ticks])
    ax.minorticks_off()
    ax.set_yticks(ys, labels, fontsize=11)
    ax.grid(axis="x", color=GRID, lw=0.8)
    ax.set_axisbelow(True)
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.tick_params(axis="y", length=0)
    ax.set_xlabel("Speedup over 0.11.10 (log scale, higher is better, 1x = unchanged)")
    fig.suptitle("HdrHistogram_c 0.12.0 vs 0.11.10", x=0.02, ha="left", fontsize=17, fontweight="bold")
    fig.text(0.02, 0.905, "Percentile queries are much faster; recording is unchanged", fontsize=11.5, color=MUTED, va="top")
    ax.legend(loc="lower right", frameon=False, fontsize=9.5, bbox_to_anchor=(1.0, 0.0))
    fig.text(0.02, 0.012, CAPTION, fontsize=8, color=MUTED, va="bottom", linespacing=1.5)
    fig.subplots_adjust(left=0.17, right=0.97, top=0.84, bottom=0.2)
    save(fig, "speedup")


def absolute(key, title, unit, number):
    fig, ax = plt.subplots(figsize=(10, 5.4))
    height, gap = 0.3, 1.0
    ys, labels, top = [], [], 0
    for i, r in enumerate(RUNNERS):
        base = (len(RUNNERS) - 1 - i) * gap
        d = r[key]
        for j, (ver, color, lab) in enumerate((("previous", OLD, "0.11.10"), ("master", NEW, "0.12.0"))):
            y = base + (0.5 - j) * height * 1.15
            ax.barh(y, d[ver], height=height, color=color, label=lab if i == 0 else None)
            ax.text(d[ver], y, "  " + number(d, ver), va="center", ha="left", fontsize=9.5)
            top = max(top, d[ver])
        ys.append(base)
        labels.append(NAMES[r["name"]])
    ax.set_xlim(0, top * 1.22)
    ax.set_yticks(ys, labels, fontsize=11)
    ax.grid(axis="x", color=GRID, lw=0.8)
    ax.set_axisbelow(True)
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.tick_params(axis="y", length=0)
    ax.set_xlabel(f"{unit} (higher is better)")
    fig.suptitle(title, x=0.02, ha="left", fontsize=15, fontweight="bold")
    ax.legend(loc="upper right", frameon=False, fontsize=10)
    fig.text(0.02, 0.012, CAPTION, fontsize=8, color=MUTED, va="bottom", linespacing=1.5)
    fig.subplots_adjust(left=0.17, right=0.97, top=0.9, bottom=0.2)
    save(fig, key)


absolute("write", "Write: hdr_record_value", "Million records per second",
         lambda d, v: f"{d[v]:.0f}  ({d[v + '_label']})" if "–" in d[v + "_label"] else f"{d[v]:.0f}")
absolute("read", "Read: hdr_value_at_percentile", "Million queries per second",
         lambda d, v: f"{d[v]:g}")
absolute("list", "Batch: hdr_value_at_percentiles, four percentiles per call", "Thousand calls per second",
         lambda d, v: f"{d[v]:,.0f}" if d[v] >= 100 else f"{d[v]:.2f}")
speedup()
print("wrote", ", ".join(sorted(p.name for p in HERE.glob("*.svg"))), "and matching PNGs")

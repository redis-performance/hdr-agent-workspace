#!/usr/bin/env python3
"""Render the hdrhistogram-go v1.3.0 vs tip charts (SVG + PNG) from the saved fleet summaries.

Reads ../<machine>/summary.txt (written by scripts/fleet-go-bench.sh) and writes speedup.* and valueatpercentiles.* next to this
script. Output is deterministic. Needs matplotlib.
"""
import re
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

HERE = Path(__file__).resolve().parent
MACHINES = [("intel-sapphire-rapids", "Intel Xeon\n(Sapphire Rapids)"), ("amd-zen5", "AMD EPYC\n(Zen 5)"),
            ("arm-neoverse-v2", "AWS Graviton\n(Neoverse V2)")]
OLD, NEW = "#62748b", "#087e75"
INK, MUTED, GRID = "#152332", "#475569", "#e3e9ef"
METRICS = [  # (benchmark, label, colour)
    ("BenchmarkHistogramValueAtPercentilesGivenPercentileSlice", "ValueAtPercentiles (4 percentiles, one call)", "#087e75"),
    ("BenchmarkHistogramValueAtPercentile", "ValueAtPercentile (one percentile)", "#4f9bd9"),
    ("BenchmarkHistogramRecordValue", "RecordValue", "#9aa7b8"),
]
CAPTION = (
    "Intel Xeon (Sapphire Rapids), AMD EPYC (Zen 5), AWS Graviton (Neoverse V2): benchmark fleet, one pinned core, GOMAXPROCS=1, runs interleaved\n"
    "with v1.3.0 (7 repetitions, medians). Microbenchmarks from the repository's own benchmark file, not application throughput."
)

plt.rcParams.update({
    "svg.fonttype": "path", "svg.hashsalt": "hdrhistogram-go-tip-186f8b9",
    "font.family": "DejaVu Sans", "text.color": INK, "axes.labelcolor": MUTED,
    "xtick.color": MUTED, "ytick.color": INK, "axes.edgecolor": GRID,
})


def load():
    data = {}
    for key, _ in MACHINES:
        rows = {}
        for line in (HERE.parent / key / "summary.txt").read_text().splitlines():
            m = re.match(r"(Benchmark\S+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)x", line)
            if m:
                # (v1.3.0 ns, tip ns, ratio). The ratio comes from the unrounded medians; the printed ns/op have one decimal, which
                # is too coarse for the few-nanosecond benchmarks.
                rows[m.group(1)] = (float(m.group(2)), float(m.group(3)), float(m.group(4)))
        data[key] = rows
    return data


DATA = load()


def save(fig, name):
    fig.savefig(HERE / f"{name}.svg", metadata={"Date": None})
    fig.savefig(HERE / f"{name}.png", dpi=150, metadata={"Software": None})
    plt.close(fig)


def fmt_ratio(r):
    return f"{r:.2f}x"


def speedup():
    fig, ax = plt.subplots(figsize=(10, 6.2))
    height, gap = 0.24, 0.9
    ys, labels = [], []
    for i, (key, name) in enumerate(MACHINES):
        base = (len(MACHINES) - 1 - i) * gap
        for j, (bench, label, color) in enumerate(METRICS):
            v = DATA[key][bench][2]
            y = base + (1 - j) * height
            ax.barh(y, v - 1, left=1, height=height * 0.86, color=color, label=label if i == 0 else None)
            ax.text(v * (1.05 if v >= 1 else 0.95), y, fmt_ratio(v), va="center",
                    ha="left" if v >= 1 else "right", fontsize=10.5, fontweight="bold")
        ys.append(base)
        labels.append(name)
    ax.axvline(1, color=INK, lw=1.2)
    ax.set_xscale("log")
    ax.set_xlim(0.75, 9)
    ticks = [1, 2, 4, 8]
    ax.set_xticks(ticks, [f"{t}x" for t in ticks])
    ax.minorticks_off()
    ax.set_yticks(ys, labels, fontsize=11)
    ax.grid(axis="x", color=GRID, lw=0.8)
    ax.set_axisbelow(True)
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.tick_params(axis="y", length=0)
    ax.set_xlabel("Speedup over v1.3.0 (log scale, higher is better, 1x = unchanged)")
    fig.suptitle("hdrhistogram-go vs v1.3.0", x=0.02, ha="left", fontsize=17, fontweight="bold")
    fig.text(0.02, 0.905, "Asking for several percentiles at once is 4 to 6x faster; single queries are unchanged; recording is within 4%",
             fontsize=11, color=MUTED, va="top")
    ax.legend(loc="lower right", frameon=False, fontsize=9.5, bbox_to_anchor=(1.0, 0.0))
    fig.text(0.02, 0.012, CAPTION, fontsize=8, color=MUTED, va="bottom", linespacing=1.5)
    fig.subplots_adjust(left=0.17, right=0.97, top=0.84, bottom=0.2)
    save(fig, "speedup")


def absolute():
    bench = METRICS[0][0]
    fig, ax = plt.subplots(figsize=(10, 5.4))
    height, gap = 0.3, 1.0
    ys, labels, top = [], [], 0
    for i, (key, name) in enumerate(MACHINES):
        base = (len(MACHINES) - 1 - i) * gap
        old, new, _ = DATA[key][bench]
        for j, (val, color, lab) in enumerate(((old, OLD, "v1.3.0"), (new, NEW, "current master"))):
            y = base + (0.5 - j) * height * 1.15
            us = val / 1000
            ax.barh(y, us, height=height, color=color, label=lab if i == 0 else None)
            ax.text(us, y, f"  {us:.2f} us", va="center", ha="left", fontsize=9.5)
            top = max(top, us)
        ys.append(base)
        labels.append(name)
    ax.set_xlim(0, top * 1.2)
    ax.set_yticks(ys, labels, fontsize=11)
    ax.grid(axis="x", color=GRID, lw=0.8)
    ax.set_axisbelow(True)
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.tick_params(axis="y", length=0)
    ax.set_xlabel("Time per call, microseconds (lower is better)")
    fig.suptitle("Histogram.ValueAtPercentiles: four percentiles in one call", x=0.02, ha="left", fontsize=15, fontweight="bold")
    ax.legend(loc="upper right", frameon=False, fontsize=10)
    fig.text(0.02, 0.012, CAPTION, fontsize=8, color=MUTED, va="bottom", linespacing=1.5)
    fig.subplots_adjust(left=0.17, right=0.97, top=0.9, bottom=0.2)
    save(fig, "valueatpercentiles")


speedup()
absolute()
print("wrote", ", ".join(sorted(p.name for p in HERE.glob("*.svg"))), "and matching PNGs")

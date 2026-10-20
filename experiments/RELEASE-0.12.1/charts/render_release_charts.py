#!/usr/bin/env python3
"""Render the 0.12.1 vs 0.12.0 no-regression charts (SVG + PNG) from ../fleet-bench/<machine>/raw/*.txt.

Writes speedup.* (ratio of medians) and runs.* (every run, normalised to the old median) next to this script. Deterministic. Needs matplotlib.
"""
import re
import statistics as st
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

HERE = Path(__file__).resolve().parent
BENCH = HERE.parent / "fleet-bench"
BENCH_OLD = HERE.parent / "fleet-bench-0.11.10"  # same harness, A=0.11.10 B=0.12.1
MACHINES = [("intel-sapphire-rapids", "Intel Xeon\n(Sapphire Rapids)"), ("amd-zen5", "AMD EPYC\n(Zen 5)"),
            ("arm-neoverse-v2", "AWS Graviton\n(Neoverse V2)")]
# (key, label, colour, higher_is_better)
METRICS = [("batch", "Batch: hdr_value_at_percentiles (4 percentiles)", "#087e75", False),
           ("single4", "Single: hdr_value_at_percentile x4", "#4f9bd9", False),
           ("read", "Read: hdr_value_at_percentile (driver)", "#7aa7d9", True),
           ("write", "Write: hdr_record_value", "#9aa7b8", True)]
OLD, NEW = "#62748b", "#087e75"
INK, MUTED, GRID = "#152332", "#475569", "#e3e9ef"
CAPTION = ("Intel Xeon (Sapphire Rapids), AMD EPYC (Zen 5), AWS Graviton (Neoverse V2): benchmark fleet, one pinned core, six runs each of 0.12.0 and 0.12.1,\n"
           "interleaved (old/new/new/old x3), GCC 13.3 Release. Microbenchmarks from the repository's own drivers plus a batch timing loop, not application throughput.\n"
           "The read driver prints two decimals (0.47, 0.26 M queries/s), so its ratios resolve only to about 2-4%; the single x4 timing is the precise read-path figure.")
plt.rcParams.update({"svg.fonttype": "path", "svg.hashsalt": "hdrhistogram-0.12.1", "font.family": "DejaVu Sans", "text.color": INK,
                     "axes.labelcolor": MUTED, "xtick.color": MUTED, "ytick.color": INK, "axes.edgecolor": GRID})


def load(machine, bench=BENCH):
    runs = {m[0]: {"A": [], "B": []} for m in METRICS}
    for f in sorted((bench / machine / "raw").glob("*.txt")):
        _, kind, v = f.stem.split("_")
        t = f.read_text()
        if kind == "perf":
            xs = [float(x.replace(",", "")) for x in re.findall(r"ops/sec: ([\d,\.]+)", t)]
            if xs:
                runs["write"][v].append(st.median(xs))
        elif kind == "read":
            m = re.search(r"best: ([\d.]+) M queries/sec", t)
            if m:
                runs["read"][v].append(float(m.group(1)))
        elif kind == "batch":
            m = re.search(r"BATCH_NS ([\d.]+) SINGLE4_NS ([\d.]+)", t)
            if m:
                runs["batch"][v].append(float(m.group(1)))
                runs["single4"][v].append(float(m.group(2)))
    return runs


DATA = {k: load(k) for k, _ in MACHINES}
DATA_OLD = {k: load(k, BENCH_OLD) for k, _ in MACHINES}


def speed(m, higher, a, b):
    """Speed of new relative to old (>1 is faster) from medians."""
    return st.median(b) / st.median(a) if higher else st.median(a) / st.median(b)


def save(fig, name):
    fig.savefig(HERE / f"{name}.svg", metadata={"Date": None})
    fig.savefig(HERE / f"{name}.png", dpi=150, metadata={"Software": None})
    plt.close(fig)


def speedup():
    fig, ax = plt.subplots(figsize=(10, 6.6))
    height, gap = 0.2, 1.0
    ys, labels = [], []
    ax.axvspan(0.98, 1.02, color="#e8f3f1", zorder=0)
    for i, (key, name) in enumerate(MACHINES):
        base = (len(MACHINES) - 1 - i) * gap
        for j, (m, label, color, higher) in enumerate(METRICS):
            r = speed(m, higher, DATA[key][m]["A"], DATA[key][m]["B"])
            y = base + (1.5 - j) * height
            ax.barh(y, r - 1, left=1, height=height * 0.86, color=color, label=label if i == 0 else None, zorder=2)
            ax.text(1.0 + (0.004 if r >= 1 else -0.004) + (r - 1), y, f"{r:.3f}x", va="center", ha="left" if r >= 1 else "right", fontsize=9.5, fontweight="bold")
        ys.append(base)
        labels.append(name)
    ax.axvline(1, color=INK, lw=1.2, zorder=3)
    ax.set_xlim(0.94, 1.08)
    ax.set_xticks([0.95, 0.98, 1.0, 1.02, 1.05])
    ax.set_xticklabels(["0.95x", "0.98x", "1.00x", "1.02x", "1.05x"])
    ax.set_yticks(ys, labels, fontsize=11)
    ax.grid(axis="x", color=GRID, lw=0.8)
    ax.set_axisbelow(True)
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.tick_params(axis="y", length=0)
    ax.set_xlabel("0.12.1 speed relative to 0.12.0 (1.00x = unchanged, higher is faster; shaded band = +/-2%)")
    fig.suptitle("HdrHistogram_c 0.12.1 vs 0.12.0: no regression", x=0.02, ha="left", fontsize=17, fontweight="bold")
    fig.text(0.02, 0.905, "Write, read and single-call queries are flat on all three machines; the batch call is flat to slightly faster",
             fontsize=11, color=MUTED, va="top")
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.1), ncol=2, frameon=False, fontsize=9.5)
    fig.text(0.02, 0.012, CAPTION, fontsize=8, color=MUTED, va="bottom", linespacing=1.5)
    fig.subplots_adjust(left=0.17, right=0.97, top=0.84, bottom=0.29)
    save(fig, "speedup")


def runs():
    fig, axes = plt.subplots(len(METRICS), len(MACHINES), figsize=(11, 8.2), sharey="row")
    for r, (m, label, color, higher) in enumerate(METRICS):
        for c, (key, name) in enumerate(MACHINES):
            ax = axes[r][c]
            a, b = DATA[key][m]["A"], DATA[key][m]["B"]
            ref = st.median(a)
            for x, vals, col in ((0, a, OLD), (1, b, NEW)):
                ys = [v / ref for v in vals]
                ax.scatter([x + (i - (len(ys) - 1) / 2) * 0.06 for i in range(len(ys))], ys, color=col, s=26, zorder=3)
                ax.hlines(st.median(ys), x - 0.22, x + 0.22, color=col, lw=2, zorder=2)
            ax.axhline(1, color=GRID, lw=1)
            ax.axhspan(0.98, 1.02, color="#e8f3f1", zorder=0)
            ax.set_xlim(-0.5, 1.5)
            ax.set_xticks([0, 1], ["0.12.0", "0.12.1"], fontsize=9)
            ax.tick_params(axis="y", labelsize=8)
            for side in ("top", "right"):
                ax.spines[side].set_visible(False)
            if r == 0:
                ax.set_title(name.replace("\n", " "), fontsize=10.5, fontweight="bold")
            if c == 0:
                ax.set_ylabel(label.split(":")[0] + (" x4" if m == "single4" else ""), fontsize=10)
    for ax_row in axes:
        lo = min(min(ax.get_ylim()) for ax in ax_row); hi = max(max(ax.get_ylim()) for ax in ax_row)
        lo, hi = min(lo, 0.96), max(hi, 1.04)
        for ax in ax_row:
            ax.set_ylim(lo, hi)
    fig.suptitle("Every run, normalised to the 0.12.0 median (shaded band = +/-2%; for time metrics lower is faster)", x=0.02, ha="left", fontsize=12.5, fontweight="bold")
    fig.text(0.02, 0.008, CAPTION, fontsize=7.5, color=MUTED, va="bottom", linespacing=1.5)
    fig.subplots_adjust(left=0.08, right=0.98, top=0.92, bottom=0.12, hspace=0.45, wspace=0.12)
    save(fig, "runs")


def versions():
    """0.12.1 against 0.12.0 and against 0.11.10, one log-scale chart; both from the same harness on the same machines."""
    fig, axes = plt.subplots(len(METRICS), 1, figsize=(10, 9.4), sharex=True)
    height = 0.34
    for r, (m, label, color, higher) in enumerate(METRICS):
        ax = axes[r]
        for i, (key, name) in enumerate(MACHINES):
            y = len(MACHINES) - 1 - i
            for j, (data, col, lab) in enumerate(((DATA_OLD, "#c9582e", "vs 0.11.10"), (DATA, "#62748b", "vs 0.12.0"))):
                v = speed(m, higher, data[key][m]["A"], data[key][m]["B"])
                yy = y + (0.5 - j) * height * 1.1
                ax.barh(yy, v - 1, left=1, height=height, color=col, label=lab if (r == 0 and i == 0) else None)
                left = v >= 0.995
                ax.text(max(v, 1.0) * 1.04 if left else v * 0.96, yy, f"{v:.2f}x", va="center", ha="left" if left else "right", fontsize=9, fontweight="bold")
        ax.axvline(1, color=INK, lw=1.2)
        ax.set_xscale("log")
        ax.set_xlim(0.8, 40)
        ax.set_yticks(range(len(MACHINES)), [n.replace("\n", " ") for _, n in reversed(MACHINES)], fontsize=9)
        ax.set_title(label, loc="left", fontsize=10.5, fontweight="bold")
        ax.grid(axis="x", color=GRID, lw=0.8)
        ax.set_axisbelow(True)
        for side in ("top", "right", "left"):
            ax.spines[side].set_visible(False)
        ax.tick_params(axis="y", length=0)
    ticks = [1, 2, 4, 8, 16, 32]
    axes[-1].set_xticks(ticks, [f"{t}x" for t in ticks])
    axes[-1].minorticks_off()
    axes[-1].set_xlabel("0.12.1 speed relative to the older release (log scale, 1x = unchanged, higher is faster)")
    axes[0].legend(loc="upper right", bbox_to_anchor=(1.0, 1.32), ncol=2, frameon=False, fontsize=9.5)
    fig.suptitle("HdrHistogram_c 0.12.1 against 0.12.0 and 0.11.10", x=0.02, ha="left", fontsize=17, fontweight="bold")
    fig.text(0.02, 0.945, "Percentile queries are 2x (single) to 15-20x (batch) faster than 0.11.10; against 0.12.0 nothing changed", fontsize=11, color=MUTED, va="top")
    fig.text(0.02, 0.012, "Intel Xeon (Sapphire Rapids), AMD EPYC (Zen 5), AWS Graviton (Neoverse V2): benchmark fleet, one pinned core, six runs per release, interleaved\n(old/new/new/old x3; 0.12.1 measured against each older release in its own session), GCC 13.3 Release. Microbenchmarks from the repository's own\ndrivers plus a batch timing loop, not application throughput. The read driver prints two decimals, so its ratios resolve only to about 2-4%.", fontsize=7.5, color=MUTED, va="bottom", linespacing=1.5)
    fig.subplots_adjust(left=0.2, right=0.96, top=0.88, bottom=0.14, hspace=0.55)
    save(fig, "versions")


speedup()
runs()
versions()
for key, _ in MACHINES:
    for m, _, _, higher in METRICS:
        a, b = DATA[key][m]["A"], DATA[key][m]["B"]
        print(f"{key:24s} {m:8s} n={len(a)}|{len(b)} speed={speed(m, higher, a, b):.3f}x")
for key, _ in MACHINES:
    for m, _, _, higher in METRICS:
        a, b = DATA_OLD[key][m]["A"], DATA_OLD[key][m]["B"]
        print(f"{key:24s} {m:8s} vs 0.11.10 n={len(a)}|{len(b)} speed={speed(m, higher, a, b):.3f}x")

#!/usr/bin/env python3
"""Plot complete native compiler comparisons; ranges are paired observations."""
import argparse
import json
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--input", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
data = json.loads(args.input.read_text())
labels = {"intel": "Intel x86_64", "amd": "AMD x86_64", "arm": "ARM64"}
colors = {"gcc": "#146EAA", "clang": "#C05B1B"}
fig, axes = plt.subplots(1, 2, figsize=(11, 4.7), sharey=True, layout="constrained")
yticks, ylabels = [], []
for i, (machine, cc) in enumerate((m, c) for m in labels for c in colors):
    result = data["machines"][machine]
    assert result["status"]["phase"] == "complete", "Do not publish unfinished timing charts"
    y = 5 - i
    yticks.append(y)
    ylabels.append(f"{labels[machine]} · {('GCC' if cc == 'gcc' else 'Clang')}")
    for ax, path in zip(axes, ("write", "read")):
        values = result["referee"][cc][path]["O3_speedup_pairs"]
        assert len(values) >= 2
        median = result["referee"][cc][path]["O3_speedup_median"]
        ax.plot([min(values), max(values)], [y, y], color=colors[cc], lw=3)
        ax.scatter(values, [y] * len(values), s=30, color=colors[cc], zorder=3)
        ax.annotate(f"{median:.3f}×", (max(values), y), xytext=(7, 0),
                    textcoords="offset points", va="center", fontsize=10)
for ax, title in zip(axes, ("Record value", "Single-percentile query")):
    ax.axvline(1, ls="--", color="#555555", lw=1)
    ax.set_title(title, fontsize=12)
    ax.set_xlabel("O3 / Os throughput (higher favors O3)")
    lo, hi = ax.get_xlim()
    ax.set_xlim(min(0.9, lo), hi + 0.17 * (hi - lo))
    ax.grid(axis="x", alpha=0.2)
    ax.set_ylim(-0.6, 5.6)
    ax.spines[["top", "right"]].set_visible(False)
axes[0].set_yticks(yticks, ylabels)
fig.suptitle("HdrHistogram C · native AWS compiler comparison\n"
             "PR #158 d21d084 · fixed O3 callers · full unchanged benchmark drivers", fontsize=13)
fig.supxlabel("Points/ranges show observed alternating pairs, not confidence intervals. "
              "Read includes full-process warmups and initialization.", fontsize=9)
fig.savefig(args.output, dpi=160)
svg = args.output.with_suffix(".svg")
fig.savefig(svg)
svg.write_text("\n".join(line.rstrip() for line in svg.read_text().splitlines()).rstrip() + "\n")

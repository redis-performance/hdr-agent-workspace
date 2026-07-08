#!/usr/bin/env python3
"""Cross-language HdrHistogram benchmark: C / Go / Rust / Java on one workload, one machine.

Two operations every port exposes as a real single API:
  - write : record a value  (varied values -> real ingestion, index recomputed every op)
  - read  : value_at_percentile (one percentile over a 1M-sample log-normal histogram)

Machine: Intel Xeon 6972P (Granite Rapids), single core (pinned), host-optimized build, kbest.
Numbers are ns/op (best-of-N); throughput = 1000 / ns_per_op.
See RESULTS.md for the full methodology and the exact harnesses in java/ c/ rust/ go/.
"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

COLOR = {"C": "#2166ac", "Go": "#00add8", "Rust": "#d1691e", "Java": "#d9a520"}

# ns/op, kbest (lower is faster) -- varied-value write and single-percentile read
WRITE_NS = {"Java": 2.2984, "C": 2.4098, "Rust": 2.6299, "Go": 3.2999}
READ_NS  = {"C": 1303.00, "Go": 1308.75, "Java": 1969.37, "Rust": 1984.65}


def mops(ns):   # million ops/sec
    return 1000.0 / ns


def kops(ns):   # thousand ops/sec
    return 1e6 / ns


def panel(ax, ns_map, to_tput, unit, title, subtitle):
    langs = sorted(ns_map, key=lambda k: ns_map[k])          # fastest first (smallest ns)
    tput = [to_tput(ns_map[l]) for l in langs]
    y = range(len(langs))
    bars = ax.barh(y, tput, color=[COLOR[l] for l in langs], height=0.62,
                   edgecolor="white", linewidth=0.8, zorder=3)
    ax.set_yticks(list(y))
    ax.set_yticklabels(langs, fontsize=13, fontweight="bold")
    ax.invert_yaxis()                                        # fastest on top
    ax.set_xlim(0, max(tput) * 1.22)
    ax.set_xlabel(f"{unit}   ·   {subtitle}", fontsize=9.5, color="#666")
    ax.set_title(title, fontsize=13.5, fontweight="bold", pad=10, loc="left")
    ax.grid(axis="x", color="#e6e6e6", zorder=0)
    for s in ("top", "right", "left"):
        ax.spines[s].set_visible(False)
    best = max(tput)
    for b, l, t in zip(bars, langs, tput):
        val = f"{t:,.0f}" if t >= 10 else f"{t:.0f}"
        tag = " · fastest" if abs(t - best) < 1e-9 else f" · {t/best:.2f}×"
        ax.text(b.get_width() + max(tput) * 0.015, b.get_y() + b.get_height() / 2,
                f"{val} {unit}  ({ns_map[l]:,.2f} ns){tag}" if ns_map[l] < 100
                else f"{val} {unit}  ({ns_map[l]:,.0f} ns){tag}",
                va="center", fontsize=10.5, color="#222")


fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 5.4))
fig.suptitle("HdrHistogram — one workload, four ports, one core",
             fontsize=17, fontweight="bold", x=0.5, y=1.06)
fig.text(0.5, 0.99,
         "Intel Xeon 6972P (Granite Rapids) · single core, pinned · host-optimized build · kbest · "
         "identical log-normal(μ=0, σ=0.5) workload  —  higher is better ↑",
         ha="center", fontsize=10, color="#666")

panel(ax1, WRITE_NS, mops, "M ops/s",
      "Write — record (real ingestion)",
      "varied values, index recomputed every op")
panel(ax2, READ_NS, kops, "K ops/s",
      "Read — value_at_percentile",
      "one percentile over a 1M-sample histogram")

fig.text(0.5, -0.06,
         "C gcc -O3 -march=native  ·  Rust release+LTO, target-cpu=native  ·  Go GOAMD64=v3  ·  Java JDK 21 + JMH   "
         "|   Read: C AVX2 scan & Go v1.3.0 blocked skip-scan lead; Rust generic-Counter widening & Java iterator trail.",
         ha="center", fontsize=8.6, color="#888")

plt.tight_layout(rect=(0, 0, 1, 0.92))
out = "cross-lang-granite-rapids.png"
plt.savefig(out, dpi=150, bbox_inches="tight", facecolor="white")
print("wrote", out)

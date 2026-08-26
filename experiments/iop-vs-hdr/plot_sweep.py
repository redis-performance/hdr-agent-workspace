#!/usr/bin/env python3
"""Read-latency vs populated buckets, per architecture, from the populated sweep
(src/bin/sweep.rs, 2026-08-26). Shows the read-complexity classes visually:
iop-dense is FLAT (O(total_buckets)), hdr-dense is FLAT but ~4-7x tighter, while
hdr-packed and iop-sparse rise with populated (O(populated)) — hdr-packed lowest."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# actual populated buckets reported by hdr-packed at each target P
POP = [10, 49, 96, 446, 860, 3917, 7500]

DATA = {
    "Intel Granite Rapids": {
        "hdr-dense":  [4159, 4279, 4259, 4282, 4280, 4280, 4277],
        "hdr-packed": [16, 20, 37, 146, 276, 1171, 2177],
        "iop-dense":  [17332, 18101, 18575, 21998, 21560, 22490, 22709],
        "iop-sparse": [44, 83, 120, 398, 718, 3052, 5774],
    },
    "AMD Zen 5 Turin": {
        "hdr-dense":  [3479, 3580, 3564, 3574, 3578, 3576, 3577],
        "hdr-packed": [13, 16, 26, 94, 173, 757, 1418],
        "iop-dense":  [12909, 13424, 13847, 15148, 14563, 14178, 13629],
        "iop-sparse": [42, 61, 88, 296, 535, 2136, 4000],
    },
    "ARM Neoverse-V2": {
        "hdr-dense":  [5820, 5991, 5967, 5983, 5990, 5991, 5990],
        "hdr-packed": [15, 24, 43, 177, 335, 1478, 2787],
        "iop-dense":  [42870, 43017, 43017, 43116, 43064, 43066, 43062],
        "iop-sparse": [57, 103, 150, 546, 1003, 4281, 8085],
    },
}

STYLE = {
    "hdr-dense":  ("#1f77b4", "o", "-"),
    "hdr-packed": ("#2ca02c", "s", "-"),
    "iop-dense":  ("#d62728", "^", "--"),
    "iop-sparse": ("#ff7f0e", "D", "--"),
}

fig, axes = plt.subplots(1, 3, figsize=(15, 5), sharey=True)
for ax, (host, series) in zip(axes, DATA.items()):
    for name, ys in series.items():
        c, m, ls = STYLE[name]
        ax.plot(POP, ys, marker=m, color=c, linestyle=ls, label=name, linewidth=1.8, markersize=5)
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_title(host, fontsize=11, fontweight="bold")
    ax.set_xlabel("populated buckets")
    ax.grid(True, which="both", alpha=0.25)
axes[0].set_ylabel("read latency (ns / percentile query)")
axes[0].legend(fontsize=9, loc="upper left", framealpha=0.9)
fig.suptitle(
    "Percentile read latency vs populated buckets  —  iop-dense is FLAT O(total_buckets), "
    "hdr-packed is O(populated) and lowest\n"
    "HdrHistogram tip 386b655 (PR #154, dense v7.6.0) vs histogram v1.5.0  ·  21504 total buckets  ·  1M queries",
    fontsize=10.5,
)
fig.tight_layout(rect=[0, 0, 1, 0.93])
out = "sweep_read_latency.png"
fig.savefig(out, dpi=120)
print("wrote", out)

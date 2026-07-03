#!/usr/bin/env python3
"""3-column view per port: version (released) / master (default branch) / potential (open PRs).
C & Rust: version==master (nothing merged since release). Go: version < master (#57/#58/#59 shipped) < potential."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

ports = ["C", "Rust", "Go"]
base = ["#2166ac", "#d1691e", "#00add8"]  # C blue, Rust orange, Go gopher-cyan

# Per metric: {port: (version, master, potential)}.  gnr1, single core, same-session, core 8.
# FILLED FROM 2026-07-02 3-column measurement (RESULT.log).
data = {
    "WRITE — record_value()\n(million ops/sec, ↑ better)": {
        "unit": "M ops/s", "scale": 1e-6,
        "C":    (408894193, 408894193, 409163329),
        "Rust": (348798542, 348798542, 347821787),
        "Go":   (311382830, 319018462, 337300000),
        "labels": {"C": ("0.11.10", "=", "no PR"), "Rust": ("7.5.4", "=", "no PR"), "Go": ("v1.2.0", "mstr", "#64")},
    },
    "READ 1 percentile — value_at_percentile()\n(million queries/sec, ↑ better)": {
        "unit": "Mq/s", "scale": 1.0,
        "C":    (0.2425, 0.2425, 0.5550),
        "Rust": (0.1741, 0.1741, 0.1828),
        "Go":   (0.0457, 0.1833, 0.2749),
        "labels": {"C": ("0.11.10", "=", "#138+#139"), "Rust": ("7.5.4", "=", "#139"), "Go": ("v1.2.0", "mstr", "#64")},
    },
    "READ all 7 — value_at_percentiles()\n(thousand calls/sec, ↑ better)": {
        "unit": "K calls/s", "scale": 1e-3,
        "C":    (12393, 12393, 203380),
        "Rust": (24818, 24818, 178551),
        "Go":   (14600, 83631, 83631),
        "labels": {"C": ("0.11.10", "=", "#140+#141"), "Rust": ("7×sing", "=", "#138"), "Go": ("v1.2.0", "✓#57-63", "=mstr")},
    },
}

fig, axes = plt.subplots(1, 3, figsize=(18, 6))
fig.suptitle("HdrHistogram ports — version (released) · master (default branch) · potential (open PRs)\n"
             "gnr1 (Intel Granite Rapids), single core · same-session A/B · Go: #57-63 merged on master, #64 open · C & Rust gains all in open PRs",
             fontsize=12, fontweight="bold")

x = np.arange(len(ports))
w = 0.26
# three shades per port: version (light) / master (medium) / potential (full)
alphas = [0.35, 0.62, 1.0]
coln = ["version", "master", "potential"]

for ax, (title, d) in zip(axes, data.items()):
    scale = d["scale"]
    for i, p in enumerate(ports):
        vals = [d[p][k] * scale for k in range(3)]
        labs = d["labels"][p]
        for k in range(3):
            ax.bar(x[i] + (k-1)*w, vals[k], w, color=base[i], alpha=alphas[k],
                   edgecolor="black", linewidth=0.5,
                   label=coln[k] if i == 0 else None)
            # value label
            ax.text(x[i] + (k-1)*w, vals[k] + max([d[q][2]*scale for q in ports])*0.012,
                    f"{vals[k]:.2f}" if vals[k] < 10 else f"{vals[k]:.0f}",
                    ha="center", va="bottom", fontsize=7, color="#444")
            if labs[k]:
                ax.text(x[i] + (k-1)*w, -max([d[q][2]*scale for q in ports])*0.04, labs[k],
                        ha="center", va="top", fontsize=6.5, color="#888", rotation=0)
    ax.set_title(title, fontsize=10.5)
    ax.set_ylabel(d["unit"])
    ax.set_xticks(x); ax.set_xticklabels(ports, fontsize=11, fontweight="bold")
    ax.tick_params(axis="x", pad=20)  # push port names below the per-bar sub-labels
    ax.set_ylim(0, max([d[q][2]*scale for q in ports]) * 1.22)
    ax.legend(loc="upper left", fontsize=8.5, framealpha=0.9)

fig.tight_layout(rect=[0, 0.03, 1, 0.90])
out = "/home/fco/redislabs/hdr-agent-workspace/experiments/RACE-baseline/race3col-gnr1-2026-07-02.png"
fig.savefig(out, dpi=140)
print("wrote", out)

#!/usr/bin/env python3
"""Summarise bench_tail runs: median ns per (shape, percentile) for baseline and candidate, speed = base/candidate (>1 is faster)."""
import csv, pathlib, re, statistics as st, sys
out = pathlib.Path(sys.argv[1]); data = {}
for f in sorted((out / "raw").glob("*.txt")):
    _, cand, role = f.stem.split("_")
    for m in re.finditer(r"^TAIL (\S+) (\S+) ([\d.]+)$", f.read_text(), re.M):
        data.setdefault((cand, m[1], m[2]), {"base": [], cand: []})[role if role == "base" else cand].append(float(m[3]))
rows = []
print(f"{'cand':4} {'shape':20} {'pct':6} {'base ns':>10} {'cand ns':>10} {'speed':>7}  spread base|cand")
for (cand, shape, pct), d in sorted(data.items()):
    b, c = d["base"], d[cand]
    sp = lambda x: f"{100*(max(x)-min(x))/st.median(x):.1f}%"
    r = st.median(b) / st.median(c)
    rows.append([cand, shape, pct, st.median(b), st.median(c), round(r, 3), sp(b), sp(c), len(b), len(c)])
    print(f"{cand:4} {shape:20} {pct:6} {st.median(b):10.2f} {st.median(c):10.2f} {r:6.2f}x  {sp(b)} | {sp(c)}")
with open(out / "summary.csv", "w", newline="") as fh:
    w = csv.writer(fh); w.writerow(["cand", "shape", "pct", "base_ns", "cand_ns", "speed", "spread_base", "spread_cand", "n_base", "n_cand"]); w.writerows(rows)

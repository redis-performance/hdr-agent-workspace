#!/usr/bin/env python3
"""Plot all 4096-slot pilot cases; bars are three-round ranges, not confidence intervals."""
import csv
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

root = Path(__file__).resolve().parent
with (root / 'aa/cases.csv').open() as f:
    controls = {(r['width'], r['population'], r['position']): float(r['ratio_median'])
                for r in csv.DictReader(f)}
with (root / 'ab/cases.csv').open() as f:
    rows = list(csv.DictReader(f))
fig, axes = plt.subplots(2, 2, figsize=(10, 6), sharex=True, sharey=True)
for width, ax in zip(['1', '2', '4', '8'], axes.flat):
    selected = [r for r in rows if r['width'] == width and r['population'] == '4096']
    x = [int(r['position']) + 1 for r in selected]
    y = [float(r['ratio_median']) for r in selected]
    lo = [m - float(r['ratio_min']) for m, r in zip(y, selected)]
    hi = [float(r['ratio_max']) - m for m, r in zip(y, selected)]
    ax.errorbar(x, y, yerr=[lo, hi], fmt='o-', capsize=3, color='#1864ab', markersize=4)
    noisy = [(v, m) for v, m, r in zip(x, y, selected)
             if abs(controls[(width, '4096', r['position'])] - 1) > .05]
    if noisy:
        ax.scatter(*zip(*noisy), marker='D', s=55, facecolors='none',
                   edgecolors='#d9480f', zorder=3)
    ax.axhline(1, color='#555555', linewidth=1)
    ax.set_xscale('log', base=2)
    ax.set_xticks([1, 4, 16, 64, 1024, 4096], ['1', '4', '16', '64', '1024', '4096'])
    ax.set_title(f'{width}-byte counts')
    ax.grid(alpha=.18)
    ax.set_ylim(.65, 2.2)
for ax in axes[1]:
    ax.set_xlabel('Crossing slot (one-based, log scale)')
for ax in axes[:, 0]:
    ax.set_ylabel('Baseline time / candidate time')
fig.suptitle('Scoped crossing-loop unroll control: mixed results on Apple M1', fontsize=13)
fig.text(.5, .015, 'Apple Clang 17 -O3; 3 ABBA rounds; >1 is faster. Bars: round range, not CI.\n'
         'Orange diamonds: A/A median outside ±5%. Core residency/frequency unobserved.',
         ha='center', fontsize=9)
fig.tight_layout(rect=(0, .08, 1, .94))
fig.savefig(root / 'results.png', dpi=150)
fig.savefig(root / 'results.svg')
svg = root / 'results.svg'
svg.write_text('\n'.join(line.rstrip() for line in svg.read_text().splitlines()) + '\n')

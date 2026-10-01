#!/usr/bin/env python3
"""Render the saved full-driver and crossing-position measurements."""
import json
from pathlib import Path
import statistics
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

root = Path(__file__).resolve().parent
arm = json.loads((root / 'results.json').read_text())['runners']['arm']
fig, axes = plt.subplots(1, 2, figsize=(11, 4), layout='constrained')
for i, opt in enumerate(('O3', 'Os')):
    for j, variant in enumerate(('base', 'patch')):
        times = [r['read_seconds'] for r in arm['narrow_full']['clang-' + opt]['runs'][variant]]
        x = i + (-.18 if j == 0 else .18)
        median = statistics.median(times)
        axes[0].bar(x, median, .32, color=('#6c8197', '#16817a')[j],
                    label=('Baseline', 'Pragma')[j] if i == 0 else None)
        axes[0].errorbar(x, median, yerr=[[median - min(times)], [max(times) - median]],
                         color='black', capsize=3)
        axes[0].text(x, median + 3, f'{median:.1f}', ha='center', fontsize=9)
axes[0].set(xticks=[0, 1], xticklabels=['-O3', '-Os'], ylabel='Full read-driver elapsed time (s)',
            ylim=(0, 215), title='ARM64 · Clang 18.1.3 · pinned CPU 2')
axes[0].legend(frameon=False)
indices = [0, 1, 2, 3, 4, 7, 15, 31, 63, 127, 255, 511, 1023]
for digits, color in ((2, '#16817a'), (3, '#a35820')):
    ratios = [arm['crossings']['O3'][f'{digits}-digits-index-{x}']['read_ratio'] for x in indices]
    axes[1].plot(indices, ratios, 'o-', ms=3, label=f'{digits} significant digits', color=color)
axes[1].axhline(1, color='gray', ls='--', lw=1)
axes[1].set_xscale('symlog', linthresh=4)
axes[1].set(xlabel='Crossing bucket index', ylabel='Candidate / baseline query throughput',
            title='Effect depends on crossing position', ylim=(.8, 2.35), xlim=(0, 1300))
ticks = [0, 3, 15, 63, 255, 1023]
axes[1].set_xticks(ticks, [str(x) for x in ticks])
axes[1].legend(frameon=False)
for axis in axes:
    axis.spines[['top', 'right']].set_visible(False)
fig.savefig(root / 'results.png', dpi=160)
fig.savefig(root / 'results.svg', metadata={'Date': None})
svg = root / 'results.svg'
svg.write_text('\n'.join(line.rstrip() for line in svg.read_text().splitlines()).rstrip() + '\n')

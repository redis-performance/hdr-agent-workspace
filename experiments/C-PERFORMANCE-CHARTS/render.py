#!/usr/bin/env python3
"""Render C-only previous-release vs latest-main benchmark charts, no deps."""

import json
from pathlib import Path
from xml.sax.saxutils import escape

HERE = Path(__file__).resolve().parent
DATA = json.loads((HERE / "data.json").read_text())
COLORS = {"previous": "#62748b", "master": "#087e75"}


def txt(x, y, value, *, size=15, weight="normal", color="#152332"):
    return (
        f'<text x="{x}" y="{y}" fill="{color}" font-size="{size}" '
        f'font-weight="{weight}" font-family="system-ui, sans-serif">'
        f"{escape(str(value))}</text>"
    )


def render(key, title, unit, scale, ticks, note):
    x0, bar_width = 250, 520
    parts = [
        '<svg xmlns="http://www.w3.org/2000/svg" width="960" height="520" '
        'viewBox="0 0 960 520" role="img" '
        f'aria-label="{escape(title)}: previous stable version versus latest master by runner">',
        '<rect width="960" height="520" fill="#ffffff"/>',
        txt(30, 38, title, size=23, weight="bold"),
        txt(30, 64, f"{unit} · higher is better", size=14, color="#475569"),
        '<rect x="30" y="83" width="18" height="12" rx="2" fill="#62748b"/>',
        txt(55, 94, f"Previous stable: {DATA['previous']}", size=13),
        '<rect x="410" y="83" width="18" height="12" rx="2" fill="#087e75"/>',
        txt(435, 94, f"Latest master: {DATA['master']}", size=13),
    ]
    for tick in ticks:
        x = x0 + bar_width * tick / scale
        parts.append(f'<line x1="{x:.1f}" y1="126" x2="{x:.1f}" y2="426" stroke="#e3e9ef"/>')
        parts.append(txt(x - 9, 444, f"{tick:g}", size=12, color="#64748b"))
    for i, runner in enumerate(DATA["runners"]):
        top = 145 + i * 70
        parts.append(txt(30, top + 27, runner["name"], size=16, weight="bold"))
        values = runner[key]
        if values is None:
            parts.append(txt(x0 + 12, top + 28, "TBD · previous and master", size=15, color="#64748b"))
        else:
            for j, version in enumerate(("previous", "master")):
                value = values[version]
                width = bar_width * value / scale
                y = top + j * 22
                parts.append(
                    f'<rect x="{x0}" y="{y}" width="{width:.2f}" height="16" '
                    f'rx="3" fill="{COLORS[version]}"/>'
                )
                parts.append(txt(790, y + 13, values[f"{version}_label"], size=13))
        parts.append(f'<line x1="30" y1="{top+54}" x2="925" y2="{top+54}" stroke="#eef1f5"/>')
    parts.append(txt(30, 485, note, size=13, color="#475569"))
    parts.append('</svg>')
    (HERE / f"{key}.svg").write_text("\n".join(parts) + "\n")


render(
    "write", "C write benchmark by runner", "Million records/second", 800,
    [0, 200, 400, 600, 800],
    "Intel/AMD/Graviton: median of interleaved core-pinned runs, 0.11.10 vs #158 fixed tip d21d084 (write ~flat, within +/-5%). Apple: two runs (pre-fix e4e8b0a)."
)
render(
    "read", "C single-percentile benchmark by runner", "Million queries/second", 1.0,
    [0, 0.2, 0.4, 0.6, 0.8, 1.0],
    "Intel/AMD/Graviton: median of 3 interleaved runs. Apple: driver rounds read rates to 0.01 M/s."
)
render(
    "list", "C four-percentile list benchmark by runner", "Thousand list calls/second", 900,
    [0, 225, 450, 675, 900],
    "1e6/median_ns of the project C++ benchmark (BM_hdr_value_at_percentiles_given_array/3/86400000, {50,95,99,99.9})."
)

#!/usr/bin/env python3
"""Summarize the O3 unroll-control and early-crossing ABBA runs."""

import csv
import json
import pathlib
import statistics


RAW = pathlib.Path(__file__).resolve().parent / "raw"
ORDER = ((1, "base"), (2, "hint"), (3, "hint"), (4, "base"))
SINK = "17401860284404480"
QOS = "benchmark_qos requested=33 observed=33 relative_priority=0 set_rc=0 get_rc=0"


def main() -> None:
    wall = {"base": [], "hint": []}
    cross = {}
    checksums = {}
    for number, variant in ORDER:
        text = (RAW / f"read-o3-{number}-{variant}.log").read_text()
        assert SINK in text and QOS in text and "exit_code=0" in text
        seconds = float(text.split("wall_seconds=")[1].splitlines()[0])
        wall[variant].append(seconds)
        cross_log = (RAW / f"cross-{number}-{variant}.log").read_text()
        assert QOS in cross_log and "exit_code=0" in cross_log
        with (RAW / f"cross-{number}-{variant}.csv").open() as inp:
            for digits, pos, run, ns, checksum in csv.reader(inp):
                key = (int(digits), int(pos))
                checksums.setdefault(key, set()).add(checksum)
                if int(run) >= 2:
                    cross.setdefault((variant, *key), []).append(float(ns))
    assert all(len(values) == 1 for values in checksums.values())
    base, hint = (statistics.mean(wall[v]) for v in ("base", "hint"))
    print(f"O3 full read: base={base:.6f}s hint={hint:.6f}s speedup={base/hint:.6f}x")
    print(f"matching crossing checksums: {len(checksums)} scenarios")
    for digits in (2, 3):
        for pos in (3, 7, 31, 127, 1023):
            b = statistics.median(cross["base", digits, pos])
            h = statistics.median(cross["hint", digits, pos])
            print(f"digits={digits} index={pos} base={b:.3f}ns hint={h:.3f}ns "
                  f"throughput_ratio={b/h:.3f}x")
    print("raw wall data:", json.dumps(wall, sort_keys=True))


if __name__ == "__main__":
    main()

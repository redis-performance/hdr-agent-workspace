#!/usr/bin/env python3
"""Summarize paired full-driver and crossing-probe measurements."""

import csv
import pathlib
import re
import statistics


ROOT = pathlib.Path(__file__).resolve().parent / "raw"


def full_runs() -> None:
    for number, variant in enumerate(("base", "patch", "patch", "base"), 1):
        write = (ROOT / f"full-{number}-{variant}-hdr_histogram_perf.log").read_text()
        read = (ROOT / f"full-{number}-{variant}-hdr_percentile_bench.log").read_text()
        rates = [float(x.replace(",", "")) for x in re.findall(r"ops/sec: ([\d,.]+)", write)]
        elapsed = float(re.search(r"wall_seconds=([\d.]+)", read).group(1))
        sink = re.search(r"sink=(-?\d+)", read).group(1)
        print(f"{number} {variant}: write_median_11_100={statistics.median(rates[10:]):.2f} "
              f"read_wall={elapsed:.6f} sink={sink} write_samples={len(rates)}")


def crossing() -> None:
    data = {}
    all_checksums = {}
    for number, variant in enumerate(("base", "patch", "patch", "base") * 2, 1):
        path = ROOT / f"crossing-{number}-{variant}.csv"
        with path.open() as file:
            for digits, position, run, ns, checksum in csv.reader(file):
                key = (variant, int(digits), int(position))
                data.setdefault(key, []).append((int(run), float(ns), checksum))
                all_checksums.setdefault((int(digits), int(position)), set()).add(checksum)
    if any(len(checksums) != 1 for checksums in all_checksums.values()):
        raise ValueError("base/patch crossing checksum mismatch")
    for digits in (2, 3):
        for position in (0, 3, 7, 31, 127, 1023):
            values = {}
            for variant in ("base", "patch"):
                samples = [ns for run, ns, _ in data[variant, digits, position] if run >= 2]
                values[variant] = statistics.median(samples)
                checksums = {checksum for _, _, checksum in data[variant, digits, position]}
                if len(checksums) != 1:
                    raise ValueError((variant, digits, position, checksums))
            print(f"digits={digits} position={position}: base={values['base']:.3f} "
                  f"patch={values['patch']:.3f} ratio={values['base']/values['patch']:.4f}")


if __name__ == "__main__":
    full_runs()
    crossing()

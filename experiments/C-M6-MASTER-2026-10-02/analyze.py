#!/usr/bin/env python3
"""Summarize raw ABBA driver and list runs without rounded read rates."""

import argparse
import json
import pathlib
import re
import statistics


RAW = pathlib.Path(__file__).resolve().parent / "raw"
ORDER = ("stable", "master", "master", "stable")


def field(text: str, pattern: str) -> str:
    match = re.search(pattern, text)
    if not match:
        raise ValueError(f"missing {pattern}")
    return match.group(1)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=("o2", "o3", "os"), default="o2")
    mode = parser.parse_args().mode
    raw = RAW if mode == "o2" else RAW / mode
    rates = {"stable": [], "master": []}
    read = {"stable": [], "master": []}
    lists = {"stable": [], "master": []}
    sinks = set()
    for number, variant in enumerate(ORDER, 1):
        write_text = (raw / f"hdr_histogram_perf-{number}-{variant}.log").read_text()
        read_text = (raw / f"hdr_percentile_bench-{number}-{variant}.log").read_text()
        write_samples = [float(x.replace(",", "")) for x in re.findall(r"ops/sec: ([\d,.]+)", write_text)]
        if len(write_samples) != 100:
            raise ValueError(f"expected 100 write iterations, got {len(write_samples)}")
        rate = statistics.median(write_samples[10:])
        elapsed = float(field(read_text, r"wall_seconds=([\d.]+)"))
        sink = field(read_text, r"sink=(-?\d+)")
        sinks.add(sink)
        data = json.loads((raw / f"list-{number}-{variant}.json").read_text())
        list_runs = [x["real_time"] for x in data["benchmarks"]
                     if x["name"] == "BM_hdr_value_at_percentiles_given_array/3/86400000"]
        if len(list_runs) != 5:
            raise ValueError(f"expected 5 list repetitions, got {len(list_runs)}")
        list_ns = statistics.median(list_runs)
        rates[variant].append(rate)
        read[variant].append(elapsed)
        lists[variant].append(list_ns)
        print(f"{number} {variant}: write_ops={rate:.2f} read_wall_s={elapsed:.6f} "
              f"list_ns={list_ns:.3f} sink={sink}")
    if len(sinks) != 1:
        raise ValueError(f"read sink mismatch: {sinks}")
    stable_write = statistics.mean(rates["stable"])
    master_write = statistics.mean(rates["master"])
    stable_read = statistics.mean(read["stable"])
    master_read = statistics.mean(read["master"])
    stable_list = statistics.mean(lists["stable"])
    master_list = statistics.mean(lists["master"])
    print(f"write master/stable={master_write/stable_write:.6f} "
          f"read throughput master/stable={stable_read/master_read:.6f} "
          f"list throughput master/stable={stable_list/master_list:.6f}")
    for variant in ORDER[:2]:
        spread = abs(read[variant][0] - read[variant][1]) / statistics.mean(read[variant])
        print(f"{variant} read within-variant spread={100*spread:.3f}%")


if __name__ == "__main__":
    main()

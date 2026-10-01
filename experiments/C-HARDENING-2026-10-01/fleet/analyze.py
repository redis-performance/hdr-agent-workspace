#!/usr/bin/env python3
"""Summarize native logs, retaining independent invocation/pair variation."""
import argparse
import csv
import io
import json
from pathlib import Path
import re
import statistics


def summarize_pairs(rows, metric, reciprocal=False, baseline="Os", candidate="O3"):
    by_index = {r["index"]: r for r in rows}
    ratios = []
    for a, b in ((0, 1), (3, 2), (4, 5)):
        if a not in by_index or b not in by_index:
            continue
        assert by_index[a]["opt"] == baseline and by_index[b]["opt"] == candidate
        ratio = by_index[b][metric] / by_index[a][metric]
        ratios.append(1 / ratio if reciprocal else ratio)
    result = {candidate + "_speedup_pairs": ratios}
    if ratios:
        result[candidate + "_speedup_median"] = statistics.median(ratios)
        result[candidate + "_speedup_range"] = [min(ratios), max(ratios)]
    for opt in (baseline, candidate):
        values = [r[metric] for r in rows if r["opt"] == opt]
        if values:
            result[opt + "_median"] = statistics.median(values)
            result[opt + "_repeat_spread_pct"] = 100 * (max(values) / min(values) - 1)
    return result


def analyze(root):
    result = {"machines": {}, "method": {
        "primary_revision": "d21d0843b492023077553b3eba26b3efa16c15f5",
        "reference_revision": "bcb5c1f78f3ee50aaf33fb4898eb1c6bab73de13",
        "speedup": "O3 throughput / Os throughput; >1 favors O3",
        "write": "median ops/sec of last 90 of 100 immutable-driver iterations per invocation",
        "read": "reciprocal full-process wall seconds, including 3 warmups + 20 measured passes and initialization",
        "probe": "median of runs 3..8 per precision per invocation; unchanged fixed O3 caller",
        "pairs": "Os index0 vs O3 index1, Os index3 vs O3 index2, optional Os index4 vs O3 index5",
        "spread": "max/min - 1 among repeated same-binary invocations; not a confidence interval",
        "acceptance": "No source/default accepted; this is a compiler/embedding audit"}}
    all_checksums = {2: set(), 3: set()}
    all_sinks = set()
    for label in ("intel", "amd", "arm"):
        path = root / label / "results"
        if not path.exists():
            continue
        machine = {"metadata": json.loads((path / "metadata.json").read_text()),
                   "status": json.loads((path / "status.json").read_text()),
                   "referee": {}, "probe": {}}
        tests = list(path.glob("*-ctest.log"))
        machine["ctest"] = {"configurations": len(tests),
                            "passing_configurations": sum("100% tests passed, 0 tests failed out of 5" in p.read_text() for p in tests)}
        for cc in ("gcc", "clang"):
            rows = []
            for log in sorted(path.glob(f"referee-{cc}-[0-9]-O*.log")):
                match = re.fullmatch(r"referee-\w+-(\d+)-(Os|O3)\.log", log.name)
                if not match:
                    continue
                text = log.read_text()
                writes = [float(x.replace(",", "")) for x in re.findall(r"ops/sec: ([\d,.]+)", text)]
                timing = re.search(r"TIMING hdr_percentile_bench real=([\d.]+) user=([\d.]+) sys=([\d.]+)", text)
                if not timing:
                    continue
                assert len(writes) == 100, log
                sinks = re.findall(r"sink=(-?\d+)", text)
                assert len(sinks) == 1, log
                all_sinks.update(map(int, sinks))
                rows.append({"index": int(match[1]), "opt": match[2],
                             "write_ops_s": statistics.median(writes[10:]),
                             "read_wall_s": float(timing[1]), "read_user_s": float(timing[2]),
                             "read_sys_s": float(timing[3]), "sink": int(sinks[0])})
            machine["referee"][cc] = {"invocations": rows,
                                       "write": summarize_pairs(rows, "write_ops_s"),
                                       "read": summarize_pairs(rows, "read_wall_s", True)}
            for revision in ("current", "reference"):
                for digits in (2, 3):
                    rows = []
                    for log in sorted(path.glob(f"probe-{revision}-{cc}-[0-9]-O*.log")):
                        match = re.fullmatch(r"probe-\w+-\w+-(\d+)-(Os|O3)\.log", log.name)
                        if not match:
                            continue
                        raw = list(csv.DictReader(io.StringIO("digits,run,write_ns,read_ns,checksum\n" + log.read_text())))
                        samples = [r for r in raw if int(r["digits"]) == digits and int(r["run"]) >= 3]
                        if len(samples) != 6:
                            continue
                        all_checksums[digits].update(int(r["checksum"]) for r in samples)
                        rows.append({"index": int(match[1]), "opt": match[2],
                                     "write_ns": statistics.median(float(r["write_ns"]) for r in samples),
                                     "read_ns": statistics.median(float(r["read_ns"]) for r in samples)})
                    machine["probe"][f"{revision}-{cc}-{digits}"] = {
                        "invocations": rows, "write": summarize_pairs(rows, "write_ns", True),
                        "read": summarize_pairs(rows, "read_ns", True)}
        sizefile = path / "consumer-sizes.json"
        if sizefile.exists():
            machine["sizes"] = []
            for row in json.loads(sizefile.read_text())["rows"]:
                for binary, sizes in row["binaries"].items():
                    assert not sizes["removed_non_hdr_exports"] and not sizes["added_non_hdr_exports"]
                    machine["sizes"].append({"project": row["project"], "variant": row["variant"],
                                             "binary": binary, "text_column": sizes["text"],
                                             "text_section": sizes["sections"].get(".text"),
                                             "stripped_bytes": sizes["stripped_bytes"],
                                             "hdr_dynamic_exports": len(sizes["hdr_dynamic_symbols"]),
                                             "smoke": row["smoke"]})
        machine["profiles"] = {p.stem: p.read_text().strip().splitlines()
                               for p in sorted(path.glob("profile-*-symbols.txt"))}
        contracts = path / "consumer-contracts.json"
        if contracts.exists():
            machine["consumer_contracts"] = json.loads(contracts.read_text())
        embedded = path / "embedded"
        if (embedded / "status.json").exists():
            machine["embedded"] = {"status": json.loads((embedded / "status.json").read_text()),
                                    "digits": {}}
            for digits in (2, 3):
                runs = {}
                for log in sorted(embedded.glob("probe-*.log")):
                    match = re.fullmatch(r"probe-(\d+)-(candidate-[\w-]+)\.log", log.name)
                    if not match:
                        continue
                    raw = list(csv.DictReader(io.StringIO("digits,run,write_ns,read_ns,checksum\n" + log.read_text())))
                    samples = [r for r in raw if int(r["digits"]) == digits and int(r["run"]) >= 3]
                    if len(samples) != 6:
                        continue
                    all_checksums[digits].update(int(r["checksum"]) for r in samples)
                    runs[int(match[1])] = {"variant": match[2],
                                           "write_ns": statistics.median(float(r["write_ns"]) for r in samples),
                                           "read_ns": statistics.median(float(r["read_ns"]) for r in samples)}
                comparisons = {}
                for name, pairs in {
                    "O3_vs_Os": [(0, 1), (7, 6)],
                    "O3_private_vs_Os_private": [(3, 2), (4, 5)],
                    "Os_private_vs_Os": [(0, 3), (7, 4)],
                    "O3_private_vs_O3": [(1, 2), (6, 5)],
                    "O3_private_vs_Os": [(0, 2), (7, 5)],
                }.items():
                    comparisons[name] = {}
                    for metric in ("write_ns", "read_ns"):
                        ratios = [runs[a][metric] / runs[b][metric]
                                  for a, b in pairs if a in runs and b in runs]
                        if ratios:
                            comparisons[name][metric] = {"speedup_pairs": ratios,
                                                         "speedup_median": statistics.median(ratios),
                                                         "speedup_range": [min(ratios), max(ratios)]}
                machine["embedded"]["digits"][digits] = {"runs": runs, "comparisons": comparisons}
        machine["discarded_logs"] = sorted(p.name for p in path.glob("*.discarded-*.log"))
        counter = path / "countercheck"
        if (counter / "status.json").exists():
            rows = []
            for log in sorted(counter.glob("referee-*.log")):
                match = re.fullmatch(r"referee-(\d+)-(candidate-o3(?:-hidden-gc)?)\.log", log.name)
                if not match:
                    continue
                text = log.read_text()
                timing = re.search(r"TIMING hdr_percentile_bench real=([\d.]+)", text)
                if not timing:
                    continue
                writes = [float(x.replace(",", "")) for x in re.findall(r"ops/sec: ([\d,.]+)", text)]
                sinks = re.findall(r"sink=(-?\d+)", text)
                assert len(writes) == 100 and len(sinks) == 1
                all_sinks.update(map(int, sinks))
                rows.append({"index": int(match[1]), "opt": "private" if "hidden" in match[2] else "regular",
                             "write_ops_s": statistics.median(writes[10:]), "read_wall_s": float(timing[1])})
            machine["countercheck"] = {"status": json.loads((counter / "status.json").read_text()),
                                       "invocations": rows,
                                       "write": summarize_pairs(rows, "write_ops_s", False, "regular", "private"),
                                       "read": summarize_pairs(rows, "read_wall_s", True, "regular", "private")}
        result["machines"][label] = machine
    assert len(all_sinks) <= 1, "Full-driver results differ"
    assert all(len(v) <= 1 for v in all_checksums.values()), "Probe results differ"
    result["checksums"] = {"referee": sorted(all_sinks),
                           "probe": {k: sorted(v) for k, v in all_checksums.items()}}
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True, help="Directory with intel/amd/arm results subdirectories")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.write_text(json.dumps(analyze(args.input), indent=2) + "\n")

#!/usr/bin/env python3
"""Archive sealed build identity and emitted recording code, never run a benchmark."""
import argparse
from collections import Counter
import json
from pathlib import Path
import re
import subprocess

from measurement_gate import verified_build


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    manifest = verified_build(args.binary)
    if args.output.exists():
        parser.error("output exists; preserve prior evidence")
    names = {"_hdr_record_value", "_hdr_record_values", "_hdr_record_value_atomic",
             "_hdr_record_values_atomic", "_normalize_record_index"}
    disassembly = subprocess.check_output(["otool", "-tvV", str(args.binary)], text=True)
    functions, current = {}, None
    for line in disassembly.splitlines():
        if line.startswith("_") and line.endswith(":"):
            current = line[:-1] if line[:-1] in names else None
            if current: functions[current] = []
        elif current:
            functions[current].append(line)
    if not names.difference({"_normalize_record_index"}).issubset(functions):
        raise ValueError("missing recording functions")
    args.output.mkdir(parents=True)
    (args.output / "build.json").write_text(json.dumps(manifest, indent=2) + "\n")
    stats = {}
    for name, lines in functions.items():
        (args.output / (name[1:] + ".s")).write_text(name + ":\n" + "\n".join(lines) + "\n")
        opcodes = Counter()
        for line in lines:
            match = re.match(r"^[0-9a-f]+\s+(\S+)", line)
            if match: opcodes[match[1]] += 1
        stats[name] = {"instructions": sum(opcodes.values()), "opcodes": dict(opcodes)}
    (args.output / "instructions.json").write_text(json.dumps(stats, indent=2) + "\n")
    print(json.dumps({name: value["instructions"] for name, value in stats.items()}))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Save static disassembly after the timed workloads have finished."""
import argparse
import json
from pathlib import Path
import re
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--root", type=Path, required=True)
args = parser.parse_args()
root = args.root.resolve()
assert json.loads((root / "results/status.json").read_text())["phase"] == "complete"
assert json.loads((root / "results/embedded/status.json").read_text())["phase"] == "complete"
for cc in ("gcc", "clang"):
    for opt in ("Os", "O3"):
        binary = root / f"current-{opt}/build/{cc}/test/hdr_percentile_bench"
        text = subprocess.check_output(["objdump", "-d", str(binary)], text=True)
        functions = re.split(r"\n(?=[0-9a-f]+ <)", text)
        selected = [f for f in functions if re.match(
            r"[0-9a-f]+ <(?:hdr_value_at_percentile|get_value_from_idx_up_to_count[^>]*)>:", f)]
        assert selected
        (root / f"results/codegen-{cc}-{opt}-read.txt").write_text("\n".join(selected))
print("Read-path codegen captured")

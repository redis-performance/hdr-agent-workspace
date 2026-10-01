#!/usr/bin/env python3
"""Update a Redis/Valkey HDR directory while preserving its local contracts.

Usage: prepare-hdr-vendor.py --upstream HDR_CHECKOUT --consumer CONSUMER_CHECKOUT
Run in an isolated consumer checkout; review the resulting diff before merging.
Does not change build flags, allocator adapters, or any benchmark drivers.
"""

import argparse
from pathlib import Path
import re


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--upstream", type=Path, required=True)
    parser.add_argument("--consumer", type=Path, required=True)
    args = parser.parse_args()
    dst = args.consumer / "deps/hdr_histogram"
    old_source = (dst / "hdr_histogram.c").read_text()
    old_header = (dst / "hdr_histogram.h").read_text()
    allocator = dst / "hdr_redis_malloc.h"
    allocator_before = allocator.read_bytes()
    makefile_before = (dst / "Makefile").read_bytes()
    name = "hdr_iter_linear_set_value_units_per_bucket"
    body = re.search(r"void\s+" + name + r"\([^)]*\)\s*\{[^}]*\}", old_source)
    declaration = re.search(r"void\s+" + name + r"\([^)]*\);", old_header)
    if not body or not declaration:
        raise SystemExit("Expected downstream iterator extension is missing; inspect manually")
    if "iter->specifics.linear.value_units_per_bucket = value_units_per_bucket;" not in body[0]:
        raise SystemExit("Unexpected downstream extension implementation; inspect manually")
    allocator_text = allocator_before.decode()
    for macro in ("hdr_malloc", "hdr_calloc", "hdr_realloc", "hdr_free"):
        if not re.search(r"^#define\s+" + macro + r"\s+\w+\s*$", allocator_text, re.M):
            raise SystemExit("Unexpected allocator adapter; inspect manually")
    files = {"hdr_histogram.h": (args.upstream / "include/hdr/hdr_histogram.h").read_text()}
    for filename in ("hdr_histogram.c", "hdr_atomic.h", "hdr_tests.h", "hdr_malloc.h"):
        files[filename] = (args.upstream / "src" / filename).read_text()
    source = files["hdr_histogram.c"]
    if name in source or name in files["hdr_histogram.h"]:
        raise SystemExit("Upstream already contains the extension; reconcile it manually")
    if "HDR_MALLOC_INCLUDE" not in source or b"HDR_MALLOC_INCLUDE" not in makefile_before:
        raise SystemExit("Missing allocator override contract")
    include = "#include <hdr/hdr_histogram.h>"
    if source.count(include) != 1:
        raise SystemExit("Unexpected upstream include layout; inspect manually")
    files["hdr_histogram.c"] = source.replace(include, '#include "hdr_histogram.h"') + "\n" + body[0] + "\n"
    marker = "void hdr_iter_linear_init("
    if files["hdr_histogram.h"].count(marker) != 1:
        raise SystemExit("Unexpected upstream iterator declaration layout")
    files["hdr_histogram.h"] = files["hdr_histogram.h"].replace(
        marker, declaration[0] + "\n\n" + marker, 1)
    # hdr_tests.h also imports the public header in upstream's include layout.
    for filename in files:
        files[filename] = files[filename].replace(include, '#include "hdr_histogram.h"')
    for filename, content in files.items():
        (dst / filename).write_text(content)
    assert allocator.read_bytes() == allocator_before
    assert (dst / "Makefile").read_bytes() == makefile_before
    print("Updated HDR sources; preserved iterator extension, allocator adapter and Makefile")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Seal a freshly built supplemental executable; never retrofit old provenance."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess

WORKSPACE = Path(__file__).resolve().parents[2]


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def utc():
    return datetime.now(timezone.utc).isoformat()


def command(*args):
    return subprocess.check_output(args, text=True).strip()


def source_snapshot(source):
    paths = subprocess.check_output([
        "git", "-C", str(source), "ls-files", "-z", "--cached", "--others",
        "--exclude-standard", "src", "include", "cmake", "CMakeLists.txt"])
    files = {}
    for raw in paths.split(b"\0"):
        if raw:
            name = raw.decode()
            path = source / name
            files[name] = digest(path) if path.is_file() else "deleted"
    for name in ("bench.c", "write_validate.c", "build_variant.sh", "build_manifest.py"):
        files["@harness/" + name] = digest(Path(__file__).with_name(name))
    return {
        "revision": command("git", "-C", str(source), "rev-parse", "HEAD"),
        "dirty_diff_sha256": hashlib.sha256(subprocess.check_output([
            "git", "-C", str(source), "diff", "HEAD", "--binary"])).hexdigest(),
        "files": files,
    }


def redact(value, source, build):
    # Replace the longest prefixes first; manifests are public artifacts.
    substitutions = sorted([(str(source), "@source"), (str(build), "@build"),
                            (str(WORKSPACE), "@workspace")], key=lambda x: -len(x[0]))
    for prefix, replacement in substitutions:
        value = value.replace(prefix, replacement)
    return value


def seal(source, build, compiler, flags):
    before = json.loads((build / "build-inputs.json").read_text())
    after = source_snapshot(source)
    if before["source"] != after:
        raise ValueError("source/harness changed during build; rebuild before sealing")
    commands = json.loads((build / "compile_commands.json").read_text())
    library = build / "src/libhdr_histogram_static.a"
    binary = build / "m6-bench"
    manifest = {
        "schema": 1, "started_utc": before["started_utc"], "finished_utc": utc(),
        "source": after,
        "compiler": {"path": str(compiler), "sha256": digest(compiler),
                     "version": command(str(compiler), "--version")},
        "sdk_version": command("xcrun", "--show-sdk-version"),
        "library": {"file": "src/libhdr_histogram_static.a", "sha256": digest(library)},
        "binary": {"file": binary.name, "sha256": digest(binary)},
        "harness_compile_link_argv": [str(compiler), *flags.split(), "-Wall", "-Wextra",
            "-Werror", "-I", str(source / "include"),
            str(WORKSPACE / "experiments/apple-m6/bench.c"), str(library),
            "-lz", "-lm", "-o", str(binary)],
        "cmake_compile_commands": commands,
        "build_control_files": {}, "referees": {},
    }
    for path in [build / "CMakeCache.txt", *build.glob("src/**/*.h"),
                 *build.glob("src/CMakeFiles/hdr_histogram_static.dir/flags.make"),
                 *build.glob("src/CMakeFiles/hdr_histogram_static.dir/link.txt")]:
        if path.is_file():
            manifest["build_control_files"][str(path.relative_to(build))] = digest(path)
    for name in ("hdr_histogram_perf", "hdr_percentile_bench"):
        path = build / "test" / name
        manifest["referees"][name] = digest(path)
    serialized = redact(json.dumps(manifest, indent=2), source, build)
    (build / "m6-bench.manifest.json").write_text(serialized + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("snapshot", "seal"))
    parser.add_argument("source", type=Path)
    parser.add_argument("build", type=Path)
    parser.add_argument("--compiler", type=Path)
    parser.add_argument("--flags", default="")
    args = parser.parse_args()
    source, build = args.source.resolve(), args.build.resolve()
    if args.action == "snapshot":
        build.mkdir(parents=True, exist_ok=True)
        (build / "build-inputs.json").write_text(json.dumps({
            "started_utc": utc(), "source": source_snapshot(source)}, indent=2) + "\n")
    else:
        if args.compiler is None:
            parser.error("seal requires --compiler")
        seal(source, build, args.compiler.resolve(), args.flags)


if __name__ == "__main__":
    main()

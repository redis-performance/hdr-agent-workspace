#!/usr/bin/env python3
"""Measure embedded HDR variants against fixed, already-built consumer objects.

Linux/ELF investigation tool, not a production build interface. Input consumers
must already contain the adapted candidate and preserve their allocator header
and iterator extension. Run clean consumer builds before invoking this script.
Outputs binaries/logs under --work and a portable JSON summary under --output.
"""

import argparse
import hashlib
import json
from pathlib import Path
import shlex
import subprocess
import sys
import time


SECTIONS = ["-ffunction-sections", "-fdata-sections"]
HIDDEN = SECTIONS + ["-fvisibility=hidden"]
VARIANTS = {
    "vendored-os": ("vendored", ["-Os"], []),
    "candidate-os": ("candidate", ["-Os"], []),
    "candidate-o2": ("candidate", ["-O2"], []),
    "candidate-o3": ("candidate", ["-O3"], []),
    "candidate-gc": ("candidate", ["-Os"] + SECTIONS, ["-Wl,--gc-sections"]),
    "candidate-hidden-gc": ("candidate", ["-Os"] + HIDDEN, ["-Wl,--gc-sections"]),
    "candidate-o3-hidden-gc": ("candidate", ["-O3"] + HIDDEN, ["-Wl,--gc-sections"]),
    "candidate-exclude-gc": ("candidate", ["-Os"] + SECTIONS,
                             ["-Wl,--gc-sections,--exclude-libs,libhdrhistogram.a"]),
    "candidate-hidden-gc-lto": ("candidate", ["-Os"] + HIDDEN + ["-flto"],
                                ["-Wl,--gc-sections"]),
    "candidate-scalar-hidden-gc": ("scalar", ["-Os"] + HIDDEN,
                                   ["-Wl,--gc-sections"]),
}


def run(argv, cwd=None):
    try:
        return subprocess.check_output(argv, cwd=cwd, text=True, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as error:
        sys.stderr.write(error.output)
        raise


def link_command(root, project, binary):
    obj = "server.o" if binary == "server" else f"{project}-benchmark.o"
    target = f"{project}-{binary}"
    output = run(["make", "-n", "MALLOC=libc", "USE_SYSTEMD=no", "BUILD_TLS=no",
                  "QUIET_LINK=", "-W", obj, target], root / "src")
    for line in output.splitlines():
        words = shlex.split(line)
        if len(words) > 2 and Path(words[0]).name in ("cc", "gcc", "clang"):
            if "-o" in words and words[words.index("-o") + 1] == target:
                return words
    raise RuntimeError(f"No linker command found for {target}")


def symbols(binary, dynamic=False):
    args = ["nm", "--defined-only"]
    if dynamic:
        args.append("-D")
    return [line.split()[-1] for line in run(args + [str(binary)]).splitlines()
            if line.split()]


def measure(binary):
    fields = run(["size", str(binary)]).splitlines()[-1].split()
    sections = {}
    for line in run(["size", "-A", str(binary)]).splitlines():
        words = line.split()
        if len(words) >= 2 and words[0].startswith(".") and words[1].isdigit():
            sections[words[0]] = int(words[1])
    stripped = binary.with_suffix(".stripped")
    run(["strip", "--strip-all", "-o", str(stripped), str(binary)])
    dyn = symbols(binary, True)
    hdr = [s for s in symbols(binary) if s.startswith("hdr_")]
    return {"text": int(fields[0]), "data": int(fields[1]), "bss": int(fields[2]),
            "sections": sections, "stripped_bytes": stripped.stat().st_size,
            "dynamic_symbols": dyn, "hdr_symbols": hdr,
            "hdr_dynamic_symbols": [s for s in dyn if s.startswith("hdr_")]}


def smoke(root, project, variant_dir):
    sock = variant_dir / "server.sock"
    cli = root / "src" / f"{project}-cli"
    server = variant_dir / f"{project}-server"
    bench = variant_dir / f"{project}-benchmark"
    with (variant_dir / "server.log").open("w") as log:
        process = subprocess.Popen([str(server), "--port", "0", "--unixsocket", str(sock),
                                    "--save", "", "--appendonly", "no"],
                                   cwd=variant_dir, stdout=log, stderr=log)
        try:
            for _ in range(200):
                if sock.exists():
                    break
                if process.poll() is not None:
                    raise RuntimeError("Server exited during startup")
                time.sleep(0.025)
            assert run([str(cli), "-s", str(sock), "ping"]).strip() == "PONG"
            for threads in (1, 2):
                result = run([str(bench), "-s", str(sock), "-t", "set,get", "-n", "2000",
                              "-c", "10", "--threads", str(threads)])
                (variant_dir / f"benchmark-{threads}.log").write_text(result)
                if "Latency by percentile distribution" not in result:
                    raise RuntimeError("Benchmark did not exercise detailed histogram output")
            info = run([str(cli), "-s", str(sock), "info", "latencystats"])
            if "latency_percentiles_usec_get" not in info:
                raise RuntimeError("Missing GET latency percentiles")
            (variant_dir / "latencystats.txt").write_text(info)
        finally:
            process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
            sock.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--work", type=Path, required=True)
    parser.add_argument("--audit", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--variants", nargs="+", choices=list(VARIANTS), default=list(VARIANTS))
    parser.add_argument("--resume", action="store_true")
    args = parser.parse_args()
    args.work = args.work.resolve()
    args.audit = args.audit.resolve()
    results = {"compiler": run(["gcc", "-dumpfullversion"]).strip(),
               "architecture": run(["uname", "-m"]).strip(), "rows": []}
    if args.resume and args.output.exists():
        previous = json.loads(args.output.read_text())
        assert previous["compiler"] == results["compiler"]
        results["rows"] = previous["rows"]
    for project in ("redis", "valkey"):
        root = args.work / project
        candidate = root / "deps/hdr_histogram"
        source = (candidate / "hdr_histogram.c").read_text()
        header = (candidate / "hdr_histogram.h").read_text()
        extension = "hdr_iter_linear_set_value_units_per_bucket"
        assert extension in source and extension in header
        assert 'HDR_MALLOC_INCLUDE' in source
        assert (candidate / "hdr_redis_malloc.h").read_bytes() == (
            args.audit / f"{project}-vendored-hdr/hdr_redis_malloc.h").read_bytes()
        commands = {kind: link_command(root, project, kind) for kind in ("server", "benchmark")}
        baseline_exports = {kind: set(symbols(root / "src" / f"{project}-{kind}", True))
                            for kind in commands}
        hdr_defined = set(symbols(candidate / "libhdrhistogram.a"))
        for name in args.variants:
            src_kind, cflags, ldflags = VARIANTS[name]
            dest = args.work / "variants" / project / name
            dest.mkdir(parents=True, exist_ok=True)
            include = args.audit / f"{project}-vendored-hdr" if src_kind == "vendored" else candidate
            src = include / "hdr_histogram.c"
            if src_kind == "scalar":
                src = dest / "hdr_histogram_scalar.c"
                marker = "#if defined(__x86_64__) \\\n"
                assert source.count(marker) == 1
                src.write_text(source.replace(marker, "#if 0 && defined(__x86_64__) \\\n", 1))
            digest = hashlib.sha256(src.read_bytes()).hexdigest()
            existing = [row for row in results["rows"]
                        if row["project"] == project and row["variant"] == name]
            if existing:
                if existing[0]["hdr_source_sha256"] != digest:
                    raise RuntimeError("Resume source changed; use a fresh output file")
                print(project, name, "already completed", flush=True)
                continue
            obj = dest / "hdr_histogram.o"
            compile_cmd = ["gcc", "-std=c99", "-Wall", "-g", *cflags,
                           '-DHDR_MALLOC_INCLUDE="hdr_redis_malloc.h"', "-I", str(include),
                           "-c", str(src), "-o", str(obj)]
            (dest / "compile.log").write_text(run(compile_cmd))
            archive = dest / "libhdrhistogram.a"
            archive.unlink(missing_ok=True)
            run(["ar", "rcs", str(archive), str(obj)])
            row = {"project": project, "variant": name, "hdr_cflags": cflags,
                   "extra_ldflags": ldflags,
                   "hdr_source_sha256": digest,
                   "binaries": {}}
            for kind, command in commands.items():
                cmd = command.copy()
                binary = dest / f"{project}-{kind}"
                cmd[cmd.index("-o") + 1] = str(binary)
                idx = cmd.index("../deps/hdr_histogram/libhdrhistogram.a")
                cmd[idx] = str(archive)
                cmd += ldflags
                (dest / f"{kind}-link-command.json").write_text(json.dumps(cmd, indent=2))
                (dest / f"{kind}-link.log").write_text(run(cmd, root / "src"))
                row["binaries"][kind] = measure(binary)
                metrics = row["binaries"][kind]
                exported = set(metrics.pop("dynamic_symbols"))
                metrics["dynamic_symbol_count"] = len(exported)
                metrics["dynamic_symbols_sha256"] = hashlib.sha256(
                    "\n".join(sorted(exported)).encode()).hexdigest()
                metrics["removed_non_hdr_exports"] = sorted(
                    s for s in baseline_exports[kind] - exported if s not in hdr_defined)
                metrics["added_non_hdr_exports"] = sorted(
                    s for s in exported - baseline_exports[kind] if s not in hdr_defined)
                metrics["counts_index_for_exported"] = "counts_index_for" in exported
            smoke(root, project, dest)
            row["smoke"] = "PASS: server PING/latencystats; SET/GET detailed benchmark, 1/2 threads"
            results["rows"].append(row)
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(json.dumps(results, indent=2) + "\n")
            print(project, name, {k: v["text"] for k, v in row["binaries"].items()}, flush=True)


if __name__ == "__main__":
    main()

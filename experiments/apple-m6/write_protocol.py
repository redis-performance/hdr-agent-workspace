#!/usr/bin/env python3
"""Freeze write controls without timing, or run bounded pilots after cleanup."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess

from bounded_calibration import calibrate
from measurement_gate import cleanup_record, sha256, verified_build


def utc():
    return datetime.now(timezone.utc).isoformat()


def description(binary, seed):
    result = subprocess.run([str(binary), "describe", str(seed)], check=True,
                            capture_output=True, text=True, timeout=30)
    specs = [json.loads(line) for line in result.stdout.splitlines()]
    if len(specs) != 33 or len({s["case"] for s in specs}) != 33:
        raise ValueError("expected all 33 unique write cases")
    return specs


def identity(manifest):
    return {"binary_sha256": manifest["binary"]["sha256"],
            "library_sha256": manifest["library"]["sha256"]}


def freeze(binaries, seed, pilot_limits=None):
    manifests = {label: verified_build(path) for label, path in binaries.items()}
    descriptions = {label: description(path, seed) for label, path in binaries.items()}
    if descriptions["base"] != descriptions["candidate"]:
        raise ValueError("candidate describes different inputs, geometry or work")
    specs = descriptions["base"]
    canonical = json.dumps(specs, sort_keys=True, separators=(",", ":")).encode()
    if pilot_limits is None:
        pilot_limits = {"minimum": 0.025, "maximum": 1.0, "budget": 2.0}
    if not (0 < pilot_limits["minimum"] <= pilot_limits["maximum"] <= pilot_limits["budget"]):
        raise ValueError("invalid pilot limits")
    return {"schema": 1, "prepared_utc": utc(), "seed": seed,
            "controller_sha256": sha256(__file__),
            "calibrator_sha256": sha256(Path(__file__).with_name("bounded_calibration.py")),
            "binaries": {label: identity(m) for label, m in manifests.items()},
            "build_manifests": manifests,
            "descriptor_sha256": hashlib.sha256(canonical).hexdigest(),
            "cases": specs, "timing_performed": False,
            "pilot_limits": pilot_limits,
            "discovery_pairs": 6, "confirmation": "not enabled by this protocol",
            "target": "immutable ordinary-write referee; full-sweep companion reserved for finalists",
            "guards": "all 32 supplemental controls, plus existing read/footprint guards separately",
            "fingerprint_note": "FNV-1a64 of generated input/selector words or sweep specification; descriptor SHA256 is not a direct SHA256 of the input stream"}


def verify_protocol(protocol, binaries):
    if protocol.get("schema") != 1 or protocol.get("timing_performed") is not False:
        raise ValueError("unsupported frozen protocol")
    current = freeze(binaries, protocol["seed"], protocol["pilot_limits"])
    for key in ("binaries", "build_manifests", "descriptor_sha256", "cases", "pilot_limits", "discovery_pairs",
                "controller_sha256", "calibrator_sha256"):
        if current[key] != protocol[key]:
            raise ValueError("frozen protocol mismatch: " + key)


def pilots(protocol, binaries, output, cleanup):
    # Cleanup and identity gates run before creating any timed process.
    attestation = cleanup_record(cleanup)
    verify_protocol(protocol, binaries)
    if output.exists():
        raise ValueError("output exists; preserve prior pilots")
    output.mkdir(parents=True)
    (output / "protocol.json").write_text(json.dumps(protocol, indent=2) + "\n")
    metadata = {"started_utc": utc(), "cleanup": attestation,
                "scope": "calibration only, not discovery, A/A, confirmation or acceptance"}
    (output / "session.json").write_text(json.dumps(metadata, indent=2) + "\n")
    results = []
    with (output / "processes.jsonl").open("w") as stream:
        for spec in protocol["cases"]:
            if spec["kind"] != "supplemental-control":
                continue

            def measure(arm, units, timeout):
                event = {"case": spec["case"], "arm": arm, "units": units,
                         "started_utc": utc(), "timeout_seconds": timeout}
                stream.write(json.dumps(dict(event, event="start")) + "\n"); stream.flush()
                try:
                    proc = subprocess.run([str(binaries[arm]), "run", spec["case"], str(units), str(protocol["seed"])],
                        check=True, capture_output=True, text=True, timeout=timeout)
                except (subprocess.TimeoutExpired, subprocess.CalledProcessError) as error:
                    stream.write(json.dumps(dict(event, event="failed", ended_utc=utc(),
                        error=type(error).__name__)) + "\n"); stream.flush()
                    if isinstance(error, subprocess.TimeoutExpired):
                        raise TimeoutError from error
                    raise
                row = json.loads(proc.stdout)
                stream.write(json.dumps(dict(event, event="complete", ended_utc=utc(), sample=row)) + "\n")
                stream.flush()
                return row

            result = calibrate(spec, measure, **protocol["pilot_limits"])
            results.append(result)
            # Incremental checkpoints retain completed cells if a later cell fails.
            (output / "calibration.json").write_text(json.dumps(results, indent=2) + "\n")
            print(json.dumps({"case": spec["case"], "status": result["status"], "reason": result["reason"]}), flush=True)
    metadata.update(ended_utc=utc(), all_controls_locked=all(r["status"] == "locked" for r in results))
    (output / "session.json").write_text(json.dumps(metadata, indent=2) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("prepare", "calibrate"))
    parser.add_argument("baseline", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--seed", type=lambda s: int(s, 0))
    parser.add_argument("--pilot-minimum", type=float, default=0.025)
    parser.add_argument("--pilot-maximum", type=float, default=1.0)
    parser.add_argument("--pilot-budget", type=float, default=2.0)
    parser.add_argument("--protocol", type=Path)
    parser.add_argument("--cleanup-record", type=Path)
    args = parser.parse_args()
    if args.action == "calibrate" and args.seed is not None:
        parser.error("calibration uses the frozen protocol seed; no override")
    if args.action == "calibrate" and (args.pilot_minimum, args.pilot_maximum, args.pilot_budget) != (0.025, 1.0, 2.0):
        parser.error("calibration uses the frozen pilot limits; no override")
    seed = 0x6a09e667 if args.seed is None else args.seed
    if not 0 < seed <= 0xffffffff:
        parser.error("seed must be a nonzero 32-bit integer")
    binaries = {"base": args.baseline.resolve(), "candidate": args.candidate.resolve()}
    try:
        if args.action == "prepare":
            if args.output.exists(): raise ValueError("output exists; preserve frozen protocol")
            protocol = freeze(binaries, seed, {"minimum": args.pilot_minimum,
                                                "maximum": args.pilot_maximum,
                                                "budget": args.pilot_budget})
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(json.dumps(protocol, indent=2) + "\n")
        else:
            if not args.protocol or not args.cleanup_record:
                raise ValueError("calibrate requires --protocol and --cleanup-record")
            protocol = json.loads(args.protocol.read_text())
            pilots(protocol, binaries, args.output, args.cleanup_record)
    except (ValueError, KeyError, OSError) as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()

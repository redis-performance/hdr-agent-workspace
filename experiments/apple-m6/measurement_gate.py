"""Fail-closed prerequisites for new measurements, separate from legacy archives."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def cleanup_record(path, now=None):
    record = json.loads(Path(path).read_text())
    if record.get("schema") != 1:
        raise ValueError("unsupported cleanup record")
    for field in ("sampler_stopped", "helpers_stopped", "agents_quiescent"):
        if record.get(field) is not True:
            raise ValueError("cleanup is not confirmed: " + field)
    confirmed = datetime.fromisoformat(record["confirmed_utc"])
    if confirmed.tzinfo is None:
        raise ValueError("cleanup timestamp requires timezone")
    age = ((now or datetime.now(timezone.utc)) - confirmed).total_seconds()
    if not 0 <= age <= 3600:
        raise ValueError("cleanup attestation must be from the preceding hour")
    if not isinstance(record.get("verification"), str) or not record["verification"].strip():
        raise ValueError("record identity-based verification, not a stale PID")
    # Only hash the local explanation: it may include process/host identifiers.
    return {"sha256": sha256(path), "confirmed_utc": record["confirmed_utc"],
            "scope": "operator attestation, not automatic process verification"}


def verified_build(binary):
    binary = Path(binary)
    sidecar = binary.with_name(binary.name + ".manifest.json")
    manifest = json.loads(sidecar.read_text())
    if manifest.get("schema") != 1:
        raise ValueError("unsupported build manifest")
    if manifest["binary"]["file"] != binary.name or manifest["binary"]["sha256"] != sha256(binary):
        raise ValueError("binary differs from sealed build")
    library = binary.parent / manifest["library"]["file"]
    if manifest["library"]["sha256"] != sha256(library):
        raise ValueError("library differs from sealed build")
    return manifest


def allowed_mode(mode):
    if mode in ("batch", "batch-equivalent"):
        raise ValueError("batch timing disabled until bounded per-case calibration is implemented")


def qualification(path, mode, baseline_hash, cleanup_sha):
    from paired_stats import summarize
    path = Path(path)
    metadata = json.loads((path / "binaries.json").read_text())
    run = metadata["run"]
    if run["phase"] != "qualification" or run["mode"] != mode or run["pairs"] != 6:
        raise ValueError("qualification must be six same-mode A/A pairs")
    if "ended_utc" not in run or run["cleanup"]["sha256"] != cleanup_sha:
        raise ValueError("qualification must be complete and share this cleanup boundary")
    hashes = [metadata[label]["binary"]["sha256"] for label in ("base", "candidate")]
    if hashes != [baseline_hash, baseline_hash]:
        raise ValueError("qualification must use the current baseline binary in both arms")
    rows = [json.loads(line) for line in (path / "raw.jsonl").read_text().splitlines()]
    summary = summarize(rows, 6)
    for result in summary:
        if result["ci95_low_pct"] < -1 or result["ci95_high_pct"] > 1:
            raise ValueError("A/A cannot resolve the 1% guard: " + result["case"])
    return {"metadata_sha256": sha256(path / "binaries.json"),
            "raw_sha256": sha256(path / "raw.jsonl"),
            "cases": [row["case"] for row in summary]}

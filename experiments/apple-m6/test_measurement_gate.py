#!/usr/bin/env python3
"""Synthetic gate tests only: no benchmark process is executed."""
from datetime import datetime, timedelta, timezone
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from build_manifest import redact
from measurement_gate import allowed_mode, cleanup_record, qualification, sha256, verified_build


class GateTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.now = datetime(2026, 9, 29, 12, tzinfo=timezone.utc)

    def write_json(self, name, data):
        path = self.root / name
        path.write_text(json.dumps(data))
        return path

    def cleanup_fixture(self):
        return {"schema": 1, "confirmed_utc": self.now.isoformat(), "sampler_stopped": True,
                "helpers_stopped": True, "agents_quiescent": True,
                "verification": "locally checked exact process identities"}

    def test_cleanup_and_privacy(self):
        path = self.write_json("cleanup.json", self.cleanup_fixture())
        result = cleanup_record(path, self.now)
        self.assertEqual(result["sha256"], sha256(path))
        self.assertNotIn("verification", result)

    def test_unconfirmed_or_string_flags(self):
        for field in ("sampler_stopped", "helpers_stopped", "agents_quiescent"):
            for value in (False, "true", 1, None):
                fixture = self.cleanup_fixture(); fixture[field] = value
                with self.subTest(field=field, value=value), self.assertRaises(ValueError):
                    cleanup_record(self.write_json("cleanup.json", fixture), self.now)

    def test_stale_future_naive_and_missing_verification(self):
        for stamp in ((self.now - timedelta(hours=2)).isoformat(),
                      (self.now + timedelta(seconds=1)).isoformat(), "2026-09-29T12:00:00"):
            fixture = self.cleanup_fixture(); fixture["confirmed_utc"] = stamp
            with self.subTest(stamp=stamp), self.assertRaises(ValueError):
                cleanup_record(self.write_json("cleanup.json", fixture), self.now)
        fixture = self.cleanup_fixture(); fixture["verification"] = ""
        with self.assertRaises(ValueError):
            cleanup_record(self.write_json("cleanup.json", fixture), self.now)

    def build_fixture(self):
        binary, library = self.root / "bench", self.root / "lib.a"
        binary.write_bytes(b"synthetic executable identity")
        library.write_bytes(b"synthetic archive identity")
        self.write_json("bench.manifest.json", {"schema": 1,
            "binary": {"file": "bench", "sha256": sha256(binary)},
            "library": {"file": "lib.a", "sha256": sha256(library)}})
        return binary, library

    def test_build_identity(self):
        binary, _ = self.build_fixture()
        self.assertEqual(verified_build(binary)["schema"], 1)

    def test_changed_binary_library_and_missing_sidecar(self):
        for index in (0, 1):
            paths = self.build_fixture(); paths[index].write_bytes(b"changed")
            with self.assertRaises(ValueError): verified_build(paths[0])
        binary, _ = self.build_fixture()
        binary.with_name("bench.manifest.json").unlink()
        with self.assertRaises(OSError): verified_build(binary)

    def test_batch_blocked_before_any_executable(self):
        runner = Path(__file__).with_name("run_pairs.py")
        for mode in ("batch", "batch-equivalent"):
            with self.assertRaises(ValueError): allowed_mode(mode)
            result = subprocess.run([sys.executable, str(runner), "absent-base", "absent-candidate",
                str(self.root / "output"), "--mode", mode, "--cleanup-record", "absent-record"],
                capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("batch timing disabled", result.stderr)
            self.assertFalse((self.root / "output").exists())

    def test_unsupported_pair_budget_stops_before_launch(self):
        result = subprocess.run([sys.executable, str(Path(__file__).with_name("run_pairs.py")),
            "absent-base", "absent-candidate", str(self.root / "output"), "--mode", "write",
            "--pairs", "20", "--cleanup-record", "absent-record"], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("six-pair", result.stderr)
        self.assertFalse((self.root / "output").exists())

    def aa_fixture(self, values=None):
        self.write_json("binaries.json", {
            "base": {"binary": {"sha256": "baseline"}},
            "candidate": {"binary": {"sha256": "baseline"}},
            "run": {"phase": "qualification", "mode": "write", "pairs": 6,
                    "ended_utc": self.now.isoformat(), "cleanup": {"sha256": "cleanup"}}})
        rows = [{"case": "write", "pair": pair, "variant": label, "ops": 10,
                 "checksum": 7, "ns_per_op": 10 if label == "base" else (values or [10]*6)[pair]}
                for pair in range(6) for label in ("base", "candidate")]
        (self.root / "raw.jsonl").write_text("".join(json.dumps(row) + "\n" for row in rows))

    def test_qualified_aa(self):
        self.aa_fixture()
        self.assertEqual(qualification(self.root, "write", "baseline", "cleanup")["cases"], ["write"])

    def test_unresolved_aa(self):
        self.aa_fixture([9, 11, 9, 11, 9, 11])
        with self.assertRaisesRegex(ValueError, "cannot resolve"):
            qualification(self.root, "write", "baseline", "cleanup")

    def test_aa_wrong_identity_mode_or_cleanup(self):
        self.aa_fixture()
        for args in (("read", "baseline", "cleanup"), ("write", "changed", "cleanup"),
                     ("write", "baseline", "changed")):
            with self.subTest(args=args), self.assertRaises(ValueError): qualification(self.root, *args)

    def test_public_path_redaction(self):
        source, build = self.root / "source", self.root / "source/build"
        self.assertEqual(redact(str(build / "bench") + " " + str(source / "src/a.c"), source, build),
                         "@build/bench @source/src/a.c")


if __name__ == "__main__":
    unittest.main()

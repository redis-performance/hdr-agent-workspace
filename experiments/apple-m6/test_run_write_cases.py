#!/usr/bin/env python3
"""End-to-end synthetic workflow; subprocess calls are mocked, never timed."""
import contextlib
import copy
from datetime import datetime, timezone
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from measurement_gate import sha256
from run_write_cases import audit_rows, controls, execute, load_calibration, qualification, schedule


class CaseRunnerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.protocol = {"schema": 1, "seed": 123,
            "cases": [{"case": "case_%02d" % i, "kind": "supplemental-control", "quantum": 4096,
                       "max_units": 16, "input_fnv1a64": "%016x" % i} for i in range(32)],
            "pilot_limits": {"minimum": .025, "maximum": 1., "budget": 2.},
            "binaries": {"base": {"binary_sha256": "base", "library_sha256": "base-lib"},
                         "candidate": {"binary_sha256": "candidate", "library_sha256": "candidate-lib"}}}
        self.protocol_path = self.root / "protocol.json"
        self.save(self.protocol_path, self.protocol)
        self.cleanup = self.root / "cleanup.json"
        self.save(self.cleanup, {"schema": 1, "confirmed_utc": datetime.now(timezone.utc).isoformat(),
            "sampler_stopped": True, "helpers_stopped": True, "agents_quiescent": True,
            "verification": "SYNTHETIC TEST ONLY: no real cleanup attestation"})
        self.calibration = self.root / "calibration"
        self.calibration.mkdir()
        self.save(self.calibration / "protocol.json", self.protocol)
        self.save(self.calibration / "session.json", {"ended_utc": "synthetic", "all_controls_locked": True,
                  "cleanup": {"sha256": sha256(self.cleanup)}})
        self.cells = [{"case": s["case"], "status": "locked", "units": 4, "ops": 16384,
                      "elapsed_wall_seconds": .1,
                      "pilots": [{"units": 4, "samples": {a: self.sample(s["case"]) for a in ("base", "candidate")}}]}
                      for s in self.protocol["cases"]]
        self.save(self.calibration / "calibration.json", self.cells)
        (self.calibration / "processes.jsonl").write_text("synthetic pilot event placeholder\n")
        self.binaries = {"base": self.root / "base", "candidate": self.root / "candidate"}
        self.calls = []

    def save(self, path, data):
        path.write_text(json.dumps(data))

    def sample(self, case, seconds=.032):
        spec = next(s for s in self.protocol["cases"] if s["case"] == case)
        return {"case": case, "ops": 16384, "checksum": 42,
                "input_fnv1a64": spec["input_fnv1a64"], "seconds": seconds,
                "ns_per_op": seconds * 1e9 / 16384}

    def fake_process(self, argv, **kwargs):
        self.calls.append(argv)
        self.assertEqual(argv[1], "run")
        self.assertEqual(argv[3:], ["4", "123"])
        self.assertEqual(kwargs["timeout"], 2.)
        return subprocess.CompletedProcess(argv, 0, stdout=json.dumps(self.sample(argv[2])))

    def run_phase(self, phase, output, qualification_dir=None, callback=None):
        with patch("run_write_cases.verify_protocol"), patch("run_write_cases.subprocess.run", side_effect=callback or self.fake_process), contextlib.redirect_stdout(io.StringIO()):
            execute(self.protocol_path, self.binaries, self.calibration, output,
                    self.cleanup, phase, qualification_dir)

    def test_schedule_has_balanced_complete_pairs(self):
        events = list(schedule(controls(self.protocol)))
        self.assertEqual(len(events), 384)
        for spec in self.protocol["cases"]:
            orders = [[a for p, c, a in events if p == pair and c == spec["case"]] for pair in range(6)]
            self.assertEqual(orders.count(["base", "candidate"]), 3)
            self.assertEqual(orders.count(["candidate", "base"]), 3)

    def test_full_workflow_same_binary_aa_then_distinct_discovery(self):
        aa, discovery = self.root / "aa", self.root / "discovery"
        self.run_phase("qualification", aa)
        self.assertEqual(len(self.calls), 384)
        self.assertTrue(all(argv[0] == str(self.binaries["base"]) for argv in self.calls))
        self.assertTrue(json.loads((aa / "summary.json").read_text())["qualified"])
        self.calls.clear()
        self.run_phase("discovery", discovery, aa)
        self.assertEqual(len(self.calls), 384)
        self.assertEqual(sum(argv[0] == str(self.binaries["candidate"]) for argv in self.calls), 192)
        self.assertNotIn("qualified", json.loads((discovery / "summary.json").read_text()))

    def test_missing_aa_stops_before_output_or_subprocess(self):
        output = self.root / "discovery"
        with self.assertRaisesRegex(ValueError, "requires.*A/A"):
            self.run_phase("discovery", output)
        self.assertFalse(output.exists()); self.assertEqual(self.calls, [])

    def test_calibration_missing_duplicate_unresolved_or_wrong_count(self):
        variants = [self.cells[:-1], self.cells + [self.cells[0]]]
        for key, value in (("status", "underresolved"), ("units", 5), ("elapsed_wall_seconds", 3.)):
            changed = copy.deepcopy(self.cells); changed[0][key] = value; variants.append(changed)
        for cells in variants:
            self.save(self.calibration / "calibration.json", cells)
            with self.assertRaises(ValueError):
                load_calibration(self.calibration, self.protocol, sha256(self.cleanup))

    def test_missing_cleanup_stops_before_identity_check(self):
        self.cleanup.unlink()
        with patch("run_write_cases.verify_protocol") as verify, self.assertRaises(OSError):
            execute(self.protocol_path, self.binaries, self.calibration, self.root / "bad",
                    self.cleanup, "qualification")
        verify.assert_not_called()

    def test_underresolved_durations_are_retained_and_block_discovery(self):
        aa = self.root / "aa-short"
        def short(argv, **kwargs):
            return subprocess.CompletedProcess(argv, 0, stdout=json.dumps(self.sample(argv[2], .001)))
        self.run_phase("qualification", aa, callback=short)
        report = json.loads((aa / "summary.json").read_text())
        self.assertFalse(report["qualified"])
        self.assertEqual(len(report["duration_underresolved"]), 32)
        self.assertEqual(len((aa / "raw.jsonl").read_text().splitlines()), 384)
        with self.assertRaisesRegex(ValueError, "duration-underresolved"):
            self.run_phase("discovery", self.root / "blocked", aa)

    def test_noisy_aa_blocks_discovery(self):
        aa, count = self.root / "aa-noisy", 0
        def noisy(argv, **kwargs):
            nonlocal count
            seconds = .030 if count % 2 else .040
            count += 1
            return subprocess.CompletedProcess(argv, 0, stdout=json.dumps(self.sample(argv[2], seconds)))
        self.run_phase("qualification", aa, callback=noisy)
        self.assertFalse(json.loads((aa / "summary.json").read_text())["qualified"])
        with self.assertRaisesRegex(ValueError, "cannot resolve"):
            self.run_phase("discovery", self.root / "blocked", aa)

    def test_failed_process_preserves_partial_evidence(self):
        output, count = self.root / "partial", 0
        def failure(argv, **kwargs):
            nonlocal count
            count += 1
            if count == 3: raise subprocess.TimeoutExpired(argv, 2.)
            return self.fake_process(argv, **kwargs)
        with self.assertRaises(subprocess.TimeoutExpired):
            self.run_phase("qualification", output, callback=failure)
        self.assertEqual(len((output / "raw.jsonl").read_text().splitlines()), 2)
        self.assertFalse(json.loads((output / "session.json").read_text())["completed"])
        self.assertIn('"event": "failed"', (output / "processes.jsonl").read_text())
        self.assertFalse((output / "summary.json").exists())

    def test_overwrite_refused(self):
        output = self.root / "exists"; output.mkdir()
        with self.assertRaisesRegex(ValueError, "output exists"):
            self.run_phase("qualification", output)
        self.assertEqual(self.calls, [])

    def test_changed_raw_blocks_reuse(self):
        aa = self.root / "aa"
        self.run_phase("qualification", aa)
        with (aa / "raw.jsonl").open("a") as stream: stream.write("\n")
        with self.assertRaisesRegex(ValueError, "raw evidence changed"):
            self.run_phase("discovery", self.root / "blocked", aa)

    def test_out_of_order_or_changed_inputs_fail_audit(self):
        locks, _ = load_calibration(self.calibration, self.protocol, sha256(self.cleanup))
        rows = [dict(self.sample(c), pair=p, variant=a) for p, c, a in schedule(controls(self.protocol))]
        audit_rows(rows, self.protocol, locks)
        swapped = copy.deepcopy(rows); swapped[0], swapped[1] = swapped[1], swapped[0]
        with self.assertRaisesRegex(ValueError, "process order"):
            audit_rows(swapped, self.protocol, locks)
        changed = copy.deepcopy(rows); changed[0]["input_fnv1a64"] = "wrong"
        with self.assertRaisesRegex(ValueError, "fingerprint"):
            audit_rows(changed, self.protocol, locks)


if __name__ == "__main__":
    unittest.main()

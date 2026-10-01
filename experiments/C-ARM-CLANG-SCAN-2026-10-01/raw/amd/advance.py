#!/usr/bin/env python3
"""Stop this experiment's rejected candidate and validate the narrower candidate."""
import json
import os
from pathlib import Path
import signal
import subprocess
import time

root = Path('/tmp/hdr-os-o3-fleet-20261001')
label = json.loads((root / 'results/metadata.json').read_text())['label']
result = root / 'results/scan-validation/measurements.json'
minimum = 2 if label == 'arm' else 4
while not result.exists() or len(json.loads(result.read_text())) < minimum:
    status = json.loads((result.parent / 'status.json').read_text())['phase']
    if status in ('failed', 'stopped'):
        raise RuntimeError('Initial experiment failed before its planned diagnostic checkpoint')
    time.sleep(3)
stopped = []
for process in Path('/proc').iterdir():
    if not process.name.isdigit():
        continue
    try:
        argv = (process / 'cmdline').read_bytes().split(b'\0')
        if len(argv) < 4 or Path(os.fsdecode(argv[1])).name != 'validate.py':
            continue
        if os.fsencode(str(root)) not in argv:
            continue
        os.kill(int(process.name), signal.SIGTERM)
        stopped.append(int(process.name))
    except (FileNotFoundError, ProcessLookupError, PermissionError):
        pass
for _ in range(30):
    if all(not Path(f'/proc/{pid}').exists() for pid in stopped):
        break
    time.sleep(1)
(root / 'results/scan-transition.json').write_text(json.dumps({
    'label': label, 'reason': 'General refactor rejected: repeated AMD Clang O3 read regression',
    'complete_initial_runs': len(json.loads(result.read_text())),
    'incomplete_inflight_runs': 'Retained as stopped logs; excluded from completed measurements',
    'next_candidate': 'Clang ARM crossing-loop unroll-disable pragma',
    'time': time.time()}, indent=2) + '\n')
for script in ('screen_narrow.py', 'validate_narrow.py', 'post_narrow.py'):
    with (root / (script + '.log')).open('w') as log:
        subprocess.run(['python3', str(root / script), '--root', str(root)], stdout=log,
                       stderr=subprocess.STDOUT, check=True)

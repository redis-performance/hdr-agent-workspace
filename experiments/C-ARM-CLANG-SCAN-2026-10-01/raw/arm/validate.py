#!/usr/bin/env python3
"""Same-session full immutable-driver validation after screening and CTest."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import statistics
from types import SimpleNamespace

from run_native import Audit, TESTS

parser = argparse.ArgumentParser()
parser.add_argument('--root', type=Path, required=True)
args = parser.parse_args()
root = args.root.resolve()
meta = json.loads((root / 'results/metadata.json').read_text())
assert json.loads((root / 'results/scan-screen/status.json').read_text())['phase'] == 'complete'
audit = Audit(SimpleNamespace(root=root, label=meta['label'], cpu=meta['cpu']))
audit.out = root / 'results/scan-validation'
audit.out.mkdir(exist_ok=True)
audit.event('starting')
try:
    audit.wait_idle()
    for opt in ('O3', 'Os'):
        for variant in ('base', 'patch'):
            source = root / f'scan-{variant}-{opt}'
            audit.run(['git', 'apply', root / 'crossing-test.patch'], f'{variant}-{opt}-test-apply.log', source)
            for cc in ('clang', 'gcc'):
                name = f'{cc}-{opt}-{variant}'
                build = source / 'build' / cc
                audit.run(['cmake', '--build', build, '-j4', '--target', *TESTS], name + '-build.log')
                audit.run(['ctest', '--test-dir', build, '--output-on-failure'], name + '-ctest.log')
    rows = []
    for opt in ('O3', 'Os'):
        for cc in ('clang', 'gcc'):
            for index, variant in enumerate(('base', 'patch', 'patch', 'base')):
                name = f'referee-{cc}-{opt}-{index}-{variant}'
                env = dict(os.environ, HDR_DIR=str(root / f'scan-{variant}-{opt}'), COMPILER=cc,
                           EXP='scan-validation', TAG=name, BENCH_TIMING='1')
                log = audit.measured(['taskset', '-c', str(meta['cpu']), 'bash', root / 'scripts/run-bench.sh'], name, env)
                text = log.read_text()
                writes = [float(x.replace(',', '')) for x in re.findall(r'ops/sec: ([\d,.]+)', text)]
                reads = re.findall(r'TIMING hdr_percentile_bench real=([\d.]+)', text)
                sinks = re.findall(r'\(sink=(-?\d+)\)', text)
                assert len(writes) == 100 and len(reads) == 1 and len(sinks) == 1
                rows.append(dict(compiler=cc, opt=opt, index=index, variant=variant,
                                 record_ops=statistics.median(writes[10:]), read_seconds=float(reads[0]),
                                 sink=sinks[0], log=name + '.log'))
                assert len({r['sink'] for r in rows}) == 1
                (audit.out / 'measurements.json').write_text(json.dumps(rows, indent=2) + '\n')
    audit.event('complete')
except Exception as error:
    audit.event('failed', error=str(error))
    raise

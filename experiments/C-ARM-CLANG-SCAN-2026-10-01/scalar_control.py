#!/usr/bin/env python3
"""Disable BOTH LLVM vectorizers to isolate the accumulation dependency."""
import argparse
import json
from pathlib import Path
import re
import subprocess
from types import SimpleNamespace
from run_native import Audit, TESTS, DRIVERS

parser = argparse.ArgumentParser()
parser.add_argument('--root', type=Path, required=True)
args = parser.parse_args()
root = args.root.resolve()
meta = json.loads((root / 'results/metadata.json').read_text())
assert meta['label'] == 'arm'
assert json.loads((root / 'results/scan-narrow-post/status.json').read_text())['phase'] == 'complete'
audit = Audit(SimpleNamespace(root=root, label='arm', cpu=meta['cpu']))
audit.out = root / 'results/scan-scalar-control'
audit.out.mkdir(exist_ok=True)
audit.event('starting')
try:
    audit.wait_idle()
    for variant in ('base', 'patch'):
        source = root / f'scalar-control-{variant}'
        audit.run(['git', 'clone', '--quiet', '--shared', root / 'current-O3', source], variant + '-clone.log')
        if variant == 'patch':
            audit.run(['git', 'apply', root / 'narrow-candidate.patch'], variant + '-apply.log', source)
        audit.run(['git', 'apply', root / 'crossing-test.patch'], variant + '-test-apply.log', source)
        cmake = source / 'CMakeLists.txt'
        cmake.write_text(cmake.read_text() + '\ntarget_compile_options(hdr_histogram_static PRIVATE -O3 -g -fno-vectorize -fno-slp-vectorize)\n')
        build = source / 'build/no-vectorizers'
        audit.run(['cmake', '-S', source, '-B', build, '-DCMAKE_C_COMPILER=clang',
            '-DCMAKE_CXX_COMPILER=clang++', '-DCMAKE_BUILD_TYPE=Release',
            '-DHDR_HISTOGRAM_BUILD_BENCHMARK=ON'], variant + '-configure.log')
        audit.run(['cmake', '--build', build, '-j4', '--target', *TESTS, *DRIVERS], variant + '-build.log')
        audit.run(['ctest', '--test-dir', build, '--output-on-failure'], variant + '-ctest.log')
        audit.run(['clang', '-O3', '-g', '-I', source / 'include', root / 'performance-probe.c',
            build / 'src/libhdr_histogram_static.a', '-lm', '-lpthread', '-lz',
            '-o', build / 'performance-probe'], variant + '-probe-build.log')
        asm = subprocess.check_output(['objdump', '-d', build / 'test/hdr_percentile_bench'], text=True)
        functions = re.split(r'\n(?=[0-9a-f]+ <)', asm)
        selected = '\n'.join(f for f in functions if re.match(
            r'[0-9a-f]+ <(?:hdr_value_at_percentile|get_value_from_idx_up_to_count[^>]*)>:', f))
        assert not re.search(r'\b(?:ldp\s+q|addp\s+d|add\s+v)', selected), 'Still vectorized'
        (audit.out / (variant + '-codegen.txt')).write_text(selected)
        (audit.out / (variant + '-flags.txt')).write_text(
            (build / 'src/CMakeFiles/hdr_histogram_static.dir/flags.make').read_text())
    for index, variant in enumerate(('base', 'patch', 'patch', 'base')):
        audit.measured(['taskset', '-c', str(meta['cpu']), root / f'scalar-control-{variant}/build/no-vectorizers/performance-probe'],
            f'probe-{index}-{variant}')
    audit.event('complete')
except Exception as error:
    audit.event('failed', error=str(error))
    raise

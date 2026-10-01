#!/usr/bin/env python3
"""Profile the patch, check native sanitizers, and isolate ARM SIMD effects."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import time
from types import SimpleNamespace

from run_native import Audit, TESTS, DRIVERS

parser = argparse.ArgumentParser()
parser.add_argument('--root', type=Path, required=True)
args = parser.parse_args()
root = args.root.resolve()
status = root / 'results/scan-narrow-validation/status.json'
while True:
    phase = json.loads(status.read_text())['phase']
    if phase == 'complete':
        break
    if phase in ('failed', 'stopped'):
        raise RuntimeError('Validation did not complete; refusing follow-up measurements')
    time.sleep(15)
meta = json.loads((root / 'results/metadata.json').read_text())
audit = Audit(SimpleNamespace(root=root, label=meta['label'], cpu=meta['cpu']))
audit.out = root / 'results/scan-narrow-post'
audit.out.mkdir(exist_ok=True)
audit.event('starting')
try:
    audit.wait_idle()
    source = root / 'narrow-patch-O3'
    build = source / 'build/asan'
    audit.run(['cmake', '-S', source, '-B', build, '-DCMAKE_C_COMPILER=clang',
               '-DCMAKE_CXX_COMPILER=clang++', '-DCMAKE_BUILD_TYPE=Debug',
               '-DCMAKE_C_FLAGS=-fsanitize=address,undefined,fuzzer-no-link -fno-sanitize-recover=all'], 'asan-configure.log')
    audit.run(['cmake', '--build', build, '-j4', '--target', *TESTS], 'asan-build.log')
    audit.run(['ctest', '--test-dir', build, '--output-on-failure'], 'asan-ctest.log')
    if meta['label'] == 'arm':
        for fuzzer in ('hdr_record_fuzzer', 'hdr_decode_fuzzer'):
            binary = build / fuzzer
            corpus = build / (fuzzer + '-corpus')
            corpus.mkdir(exist_ok=True)
            audit.run(['clang', '-O1', '-g', '-fsanitize=fuzzer,address,undefined', '-fno-sanitize-recover=all',
                '-I', source / 'include', source / '.clusterfuzzlite' / (fuzzer + '.c'),
                build / 'src/libhdr_histogram_static.a', '-lz', '-lm', '-lpthread', '-o', binary], fuzzer + '-build.log')
            audit.run(['taskset', '-c', str(meta['cpu']), binary, corpus, '-max_total_time=60', '-timeout=10',
                '-rss_limit_mb=2048', '-print_final_stats=1', '-max_len=4096'], fuzzer + '.log')
        for variant in ('base', 'patch'):
            source = root / f'narrow-{variant}-O3'
            build = source / 'build/no-slp'
            name = variant + '-no-slp'
            audit.run(['cmake', '-S', source, '-B', build, '-DCMAKE_C_COMPILER=clang',
                '-DCMAKE_CXX_COMPILER=clang++', '-DCMAKE_BUILD_TYPE=Release',
                '-DCMAKE_C_FLAGS=-fno-slp-vectorize', '-DHDR_HISTOGRAM_BUILD_BENCHMARK=ON'], name + '-configure.log')
            audit.run(['cmake', '--build', build, '-j4', '--target', *TESTS, *DRIVERS], name + '-build.log')
            audit.run(['ctest', '--test-dir', build, '--output-on-failure'], name + '-ctest.log')
            audit.run(['clang', '-O3', '-g', '-I', source / 'include', root / 'performance-probe.c',
                build / 'src/libhdr_histogram_static.a', '-lm', '-lpthread', '-lz',
                '-o', build / 'performance-probe'], name + '-probe-build.log')
            asm = subprocess.check_output(['objdump', '-d', build / 'test/hdr_percentile_bench'], text=True)
            functions = re.split(r'\n(?=[0-9a-f]+ <)', asm)
            (audit.out / (name + '-codegen.txt')).write_text('\n'.join(f for f in functions if re.match(
                r'[0-9a-f]+ <(?:hdr_value_at_percentile|get_value_from_idx_up_to_count[^>]*)>:', f)))
        for index, variant in enumerate(('base', 'patch', 'patch', 'base')):
            audit.measured(['taskset', '-c', str(meta['cpu']), root / f'narrow-{variant}-O3/build/no-slp/performance-probe'],
                           f'probe-no-slp-{index}-{variant}')
    if meta['label'] == 'arm':
        for opt in ('O3', 'Os'):
            for variant in ('base', 'patch'):
                source = root / f'narrow-{variant}-{opt}'
                binary = source / 'build/clang/crossing-probe'
                audit.run(['clang', '-O3', '-g', '-I', source / 'include', root / 'crossing_probe.c',
                    source / 'build/clang/src/libhdr_histogram_static.a', '-lm', '-lpthread', '-lz',
                    '-o', binary], f'crossing-{opt}-{variant}-build.log')
            for index, variant in enumerate(('base', 'patch', 'patch', 'base')):
                audit.measured(['taskset', '-c', str(meta['cpu']), root / f'narrow-{variant}-{opt}/build/clang/crossing-probe'],
                    f'crossing-{opt}-{index}-{variant}')
    perf_candidates = sorted(Path('/usr/lib/linux-tools').glob('*/perf'))
    assert perf_candidates
    perf = perf_candidates[-1]
    for cc in ('clang', 'gcc'):
        for variant in ('base', 'patch'):
            for driver in ('read', 'write'):
                name = f'profile-{cc}-O3-{variant}-{driver}'
                dest = audit.out / name
                env = dict(os.environ, HDR_DIR=str(root / f'narrow-{variant}-O3'), COMPILER=cc,
                    DRIVER=driver, PROFILE_SECONDS='10', PERF_BIN=str(perf), PROFILE_OUT_DIR=str(dest))
                audit.measured(['taskset', '-c', str(meta['cpu']), 'bash', root / 'scan-run-profile.sh'], name, env)
                if driver == 'read':
                    data = next(dest.glob('*.data'))
                    audit.run(['sudo', '-n', perf, 'annotate', '-i', data, '--stdio', '--symbol',
                               'hdr_value_at_percentile'], name + '-annotate.txt')
    audit.event('complete')
except Exception as error:
    audit.event('failed', error=str(error))
    raise

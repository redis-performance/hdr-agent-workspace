#!/usr/bin/env python3
"""Build baseline/candidate and screen code generation on an existing fleet host."""
import argparse
import hashlib
import json
import os
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
audit = Audit(SimpleNamespace(root=root, label=meta['label'], cpu=meta['cpu']))
audit.out = root / 'results/scan-narrow-screen'
audit.out.mkdir(exist_ok=True)
audit.event('starting')
facts = {}
try:
    audit.wait_idle()
    for opt in ('O3', 'Os'):
        for variant in ('base', 'patch'):
            source = root / f'narrow-{variant}-{opt}'
            audit.run(['git', 'clone', '--quiet', '--shared', root / 'current-O3', source],
                      f'{variant}-{opt}-clone.log')
            if variant == 'patch':
                audit.run(['git', 'apply', root / 'narrow-candidate.patch'], f'{variant}-{opt}-apply.log', source)
            cmake = source / 'CMakeLists.txt'
            cmake.write_text(cmake.read_text() +
                f'\n# Isolated experiment: fixed O3 callers, variable HDR flags.\n'
                f'target_compile_options(hdr_histogram_static PRIVATE -{opt} -g)\n')
            for cc in ('clang', 'gcc'):
                name = f'{cc}-{opt}-{variant}'
                audit.event('building', variant=name)
                build = source / 'build' / cc
                audit.run(['cmake', '-S', source, '-B', build, '-DCMAKE_BUILD_TYPE=Release',
                    f'-DCMAKE_C_COMPILER={cc}', '-DCMAKE_CXX_COMPILER=' + ('clang++' if cc == 'clang' else 'g++'),
                    '-DHDR_HISTOGRAM_BUILD_SHARED=OFF', '-DHDR_HISTOGRAM_BUILD_BENCHMARK=ON',
                    '-DCMAKE_EXE_LINKER_FLAGS=-rdynamic'], name + '-configure.log')
                audit.run(['cmake', '--build', build, '-j4', '--target', *TESTS, *DRIVERS], name + '-build.log')
                audit.run(['ctest', '--test-dir', build, '--output-on-failure'], name + '-ctest.log')
                hashes = {}
                for file in ('src/hdr_histogram.c', *[f'test/{d}.c' for d in DRIVERS]):
                    hashes[file] = hashlib.sha256((source / file).read_bytes()).hexdigest()
                    if file.startswith('test/'):
                        assert (source / file).read_bytes() == subprocess.check_output(
                            ['git', 'show', 'HEAD:' + file], cwd=source)
                flags = (build / 'src/CMakeFiles/hdr_histogram_static.dir/flags.make').read_text()
                (audit.out / (name + '-flags.txt')).write_text(flags)
                asm = subprocess.check_output(['objdump', '-d', build / 'test/hdr_percentile_bench'], text=True)
                functions = re.split(r'\n(?=[0-9a-f]+ <)', asm)
                selected = [f for f in functions if re.match(
                    r'[0-9a-f]+ <(?:hdr_record_value|hdr_value_at_percentile|get_value_from_idx_up_to_count[^>]*)>:', f)]
                (audit.out / (name + '-codegen.txt')).write_text('\n'.join(selected))
                audit.run([cc, '-O3', '-g', '-I', source / 'include', root / 'performance-probe.c',
                    build / 'src/libhdr_histogram_static.a', '-lm', '-lpthread', '-lz', '-rdynamic',
                    '-o', build / 'performance-probe'], name + '-probe-build.log')
                audit.run(['objcopy', '--dump-section', '.text=' + str(build / 'benchmark-text.bin'), build / 'test/hdr_percentile_bench'], name + '-text-extract.log')
                hashes['read_text'] = hashlib.sha256((build / 'benchmark-text.bin').read_bytes()).hexdigest()
                audit.run(['objcopy', '--dump-section', '.text=' + str(build / 'write-text.bin'), build / 'test/hdr_histogram_perf'], name + '-write-text-extract.log')
                hashes['write_text'] = hashlib.sha256((build / 'write-text.bin').read_bytes()).hexdigest()
                hashes['library'] = hashlib.sha256((build / 'src/libhdr_histogram_static.a').read_bytes()).hexdigest()
                facts[name] = hashes
    (audit.out / 'inputs.json').write_text(json.dumps(facts, indent=2) + '\n')
    for cc in ('clang', 'gcc'):
        for opt in ('O3', 'Os'):
            for index, variant in enumerate(('base', 'patch', 'patch', 'base')):
                binary = root / f'narrow-{variant}-{opt}' / 'build' / cc / 'performance-probe'
                audit.measured(['taskset', '-c', str(meta['cpu']), binary], f'probe-{cc}-{opt}-{index}-{variant}')
    audit.event('complete')
except Exception as error:
    audit.event('failed', error=str(error))
    raise

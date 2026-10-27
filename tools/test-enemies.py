#!/usr/bin/env python3
"""Run shared regression suites, enemy integration tests and arena startup checks."""
import argparse
from pathlib import Path
import re
import subprocess
import sys
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--godot', default='godot')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
missing = []
for folder in ['components/NPCs/enemies', 'data/npc/enemies', 'data/magis/enemy-spells', 'data/magis/legacy-enemy-spells']:
    for source in (root / folder).rglob('*'):
        if source.suffix not in {'.gd', '.tres', '.tscn'}:
            continue
        for path in re.findall(r'(?:path=|(?:preload|load)\()["\'](res://[^"\']+)', source.read_text()):
            if not (root / path[6:]).exists():
                missing.append(f'{source.relative_to(root)} -> {path}')
print(f'{"FAIL" if missing else "PASS"} static enemy resource references', flush=True)
for path in missing:
    print(path)
failed = bool(missing)
shared = subprocess.run([sys.executable, str(root / 'tools/test-physics.py'), '--godot', args.godot], cwd=root)
failed |= shared.returncode != 0
for label, scene, summary in [
    ('integration', 'res://tests/enemy-pipeline.tscn', 'ENEMY_PIPELINE'),
    ('arena', 'res://scenes/tests/enemy-pipeline-test.tscn', None),
]:
    command = [args.godot, '--headless', '--path', str(root), scene]
    if summary is None:
        command += ['--quit-after', '300']
    command += ['--', '--quest-test-mode']
    result = subprocess.run(command, cwd=root, capture_output=True, text=True, timeout=120)
    output = result.stdout + result.stderr
    log = Path(tempfile.gettempdir()) / f'magis-enemy-{label}.log'
    log.write_text(output)
    errors = [line for line in output.splitlines() if 'SCRIPT ERROR:' in line or
              ('ERROR:' in line and 'resources still in use at exit' not in line)]
    ok = result.returncode == 0 and not errors
    match = re.search(r'ENEMY_PIPELINE: (\d+) checks, (\d+) failures', output) if summary else None
    if summary:
        ok &= bool(match and int(match[1]) >= 138 and int(match[2]) == 0)
    print(f'{"PASS" if ok else "FAIL"} enemy {label}: ' +
          (match[0] if match else f'exit {result.returncode}') + f' | {log}', flush=True)
    for error in errors:
        print(error)
    if 'resources still in use at exit' in output:
        print('  Existing project shutdown resource diagnostics remain; see log.', flush=True)
    failed |= not ok
raise SystemExit(1 if failed else 0)

#!/usr/bin/env python3
"""Run quest/loot, process-restart and optional exported-pack checks."""
import argparse
from pathlib import Path
import re
import subprocess
import sys
import shutil
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--godot', default='godot')
parser.add_argument('--skip-shared', action='store_true', help='Skip existing Magis/Enemy suites')
parser.add_argument('--packed', action='store_true', help='Also export and run from a PCK outside the project')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
failed = False

def run(label, arguments, expected=None, packed=None):
    global failed
    command = [args.godot, '--headless', '--path', str(root if packed is None else Path(tempfile.gettempdir()))]
    if packed is not None:
        command += ['--main-pack', str(packed)]
    command += arguments + ['--', '--quest-test-mode']
    if label.endswith('write'):
        command += ['--write-quest-save']
    log = Path(tempfile.gettempdir()) / f'magis-quest-{label}.log'
    try:
        result = subprocess.run(command, cwd=root if packed is None else tempfile.gettempdir(),
                                capture_output=True, text=True, timeout=180)
    except subprocess.TimeoutExpired:
        print(f'FAIL {label}: exceeded 180 seconds', flush=True)
        failed = True
        return False
    output = result.stdout + result.stderr
    log.write_text(output)
    errors = [line for line in output.splitlines() if 'SCRIPT ERROR:' in line or
              ('ERROR:' in line and 'resources still in use at exit' not in line)]
    summary = re.search(rf'{expected[0]}: (\d+) checks, (\d+) failures', output) if expected else None
    ok = result.returncode == 0 and not errors
    if expected:
        ok &= bool(summary and int(summary[1]) >= expected[1] and int(summary[2]) == 0)
    print(f'{"PASS" if ok else "FAIL"} {label}: ' +
          (summary[0] if summary else f'exit {result.returncode}') + f' | {log}', flush=True)
    for error in errors:
        print(error, flush=True)
    if 'resources still in use at exit' in output or 'ObjectDB instances leaked' in output:
        print('  Existing project shutdown resource diagnostics remain; see log.', flush=True)
    failed |= not ok
    return ok

# Resource dependencies must survive export; directory scanning is validation only.
missing = []
for folder in ['data/quests', 'components/quests', 'data/items', 'data/loot/bakau', 'scenes/tests']:
    for source in (root / folder).rglob('*'):
        if source.suffix not in {'.gd', '.tres', '.tscn'}:
            continue
        for path in re.findall(r'(?:path=|(?:preload|load)\()["\'](res://[^"\']+)', source.read_text()):
            if not (root / path[6:]).exists():
                missing.append(f'{source.relative_to(root)} -> {path}')
print(f'{"FAIL" if missing else "PASS"} static quest resource references', flush=True)
for path in missing:
    print(path)
failed |= bool(missing)
if not args.skip_shared:
    failed |= subprocess.run([sys.executable, str(root / 'tools/test-enemies.py'), '--godot', args.godot], cwd=root).returncode != 0
run('integration', ['res://tests/quest-pipeline.tscn'], ('QUEST_PIPELINE', 172))
written = run('restart-write', ['res://tests/quest-persistence.tscn'], ('QUEST_PERSISTENCE', 4))
if written:
    run('restart-read', ['res://tests/quest-persistence.tscn'], ('QUEST_PERSISTENCE', 7))
run('accessibility', ['res://tests/quest-accessibility.tscn'], ('QUEST_ACCESSIBILITY', 90))
for room in range(1, 4):
    run(f'world-boot-{room}', [f'res://tests/npc-world-boot-{room}.tscn'], ('NPC_WORLD_BOOT', 4))
run('arena', ['res://scenes/tests/bakau-quest-test.tscn', '--quit-after', '180'])
if args.packed:
    # Schema changes can leave stale binary resource conversions in Godot's
    # generated export cache. Verify a fresh pack, not an old cached conversion.
    shutil.rmtree(root / '.godot/exported', ignore_errors=True)
    with tempfile.TemporaryDirectory(prefix='magis-quest-pack-') as directory:
        pack = Path(directory) / 'quests.pck'
        exported = run('export', ['--editor', '--export-pack', 'Web', str(pack)])
        if exported and pack.is_file():
            run('packed-integration', ['res://tests/quest-pipeline.tscn'], ('QUEST_PIPELINE', 172), pack)
            run('packed-accessibility', ['res://tests/quest-accessibility.tscn'], ('QUEST_ACCESSIBILITY', 90), pack)
            for room in range(1, 4):
                run(f'packed-world-boot-{room}', [f'res://tests/npc-world-boot-{room}.tscn'], ('NPC_WORLD_BOOT', 4), pack)
            written = run('packed-restart-write', ['res://tests/quest-persistence.tscn'], ('QUEST_PERSISTENCE', 4), pack)
            if written:
                run('packed-restart-read', ['res://tests/quest-persistence.tscn'], ('QUEST_PERSISTENCE', 7), pack)
raise SystemExit(1 if failed else 0)

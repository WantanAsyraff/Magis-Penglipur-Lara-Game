#!/usr/bin/env python3
"""Isolated source/PCK destruction verification; fail on runtime errors even with exit code 0."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(__doc__)
parser.add_argument('--godot', default='godot', help='Native executable path')
parser.add_argument('--flatpak', action='store_true', help='Use installed org.godotengine.Godot')
parser.add_argument('--packed', action='store_true')
parser.add_argument('--regressions', action='store_true')
args = parser.parse_args()
logs = root / 'docs/verification/environment-destruction'
logs.mkdir(parents=True, exist_ok=True)
failed = False
# Home cache is visible in Flatpak. Every invocation gets isolated preferences and campaign files.
with tempfile.TemporaryDirectory(prefix='destruction-save-users-', dir=Path.home()/'.cache') as tmp:
    data = Path(tmp)
    env = dict(os.environ, XDG_DATA_HOME=str(data))
    engine = [args.godot]
    if args.flatpak:
        engine = ['flatpak', 'run', '--command=sh', 'org.godotengine.Godot', '-c',
                  'export XDG_DATA_HOME="$1"; shift; exec /app/bin/godot-bin "$@"', 'sh', str(data)]
    allowed = ('resources still in use at exit', 'Pages in use exist at exit in PagedAllocator', 'RID allocations of type')
    def run(name, arguments, summary=None, path=root):
        global failed
        try:
            user_flags = [arg for arg in arguments if arg.startswith("--read-")]
            arguments = [arg for arg in arguments if arg not in user_flags]
            proc = subprocess.run(engine + ['--headless', '--path', str(path)] + arguments + ['--', '--quest-test-mode'] + user_flags,
                                  env=env, capture_output=True, text=True, timeout=150)
            output = proc.stdout + proc.stderr
            errors = [line for line in output.splitlines() if 'SCRIPT ERROR:' in line or
                      ('ERROR:' in line and not any(item in line for item in allowed))]
            match = re.search(rf'{summary}: (\d+) checks, (\d+) failures', output) if summary else None
            ok = proc.returncode == 0 and not errors and (not summary or match is not None and int(match[2]) == 0)
        except subprocess.TimeoutExpired as exc:
            output = f'TIMEOUT: {exc}'; ok = False; match = None; errors = []
        (logs / (name + '.txt')).write_text(output)
        print(('PASS ' if ok else 'FAIL ') + name + (': ' + match[0] if match else ''))
        for line in errors: print(line)
        failed |= not ok
        return ok
    run('import', ['--editor', '--import', '--quit'])
    run('framework', ['res://tests/environment-destruction/framework.tscn'], 'DESTRUCTION_FRAMEWORK')
    if run('save-write', ['res://tests/environment-destruction/save-roundtrip.tscn'], 'DESTRUCTION_SAVE_WRITE'):
        run('save-read', ['res://tests/environment-destruction/save-roundtrip.tscn', '--read-destruction-save'], 'DESTRUCTION_SAVE_READ')
    if args.regressions:
        for slug, label in [('spell-regression','SPELL_REGRESSION'), ('enemy-pipeline','ENEMY_PIPELINE'),
                            ('environment-interactions','ENVIRONMENT_INTERACTIONS'), ('quest-pipeline','QUEST_PIPELINE')]:
            run(slug, [f'res://tests/{slug}.tscn'], label)
    if args.packed:
        pack = data/'destruction.pck'
        if run('export', ['--editor', '--export-pack', 'Web', str(pack)]):
            run('packed-framework', ['--main-pack', str(pack), 'res://tests/environment-destruction/framework.tscn'], 'DESTRUCTION_FRAMEWORK', data)
raise SystemExit(1 if failed else 0)

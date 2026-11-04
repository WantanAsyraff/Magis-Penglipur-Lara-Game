#!/usr/bin/env python3
"""Run controls/presentation integration and regressions with isolated preferences/saves."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--godot', default='godot', help='Native Godot executable')
parser.add_argument('--flatpak', action='store_true', help='Use org.godotengine.Godot')
parser.add_argument('--capture', action='store_true', help='Also render the preview scene on a real display')
args = parser.parse_args()
cache = ROOT / '.godot'
cache.mkdir(exist_ok=True)
logs = cache / 'v3-test-results'
logs.mkdir(exist_ok=True)
# Files must exist before launching: Godot otherwise falls back to the real user folder.
with tempfile.TemporaryDirectory(prefix='v3-test-users-', dir=cache) as folder:
    data = Path(folder)
    def run(scene, extra=(), capture=False):
        # Paired writer/reader invocations share their own suite's data directory.
        suite_data = data / scene
        suite_data.mkdir(exist_ok=True)
        env = os.environ.copy()
        env.update(XDG_DATA_HOME=str(suite_data), APPDATA=str(suite_data))
        if args.flatpak:
            # Flatpak replaces startup XDG variables. Set them inside the sandbox.
            command = ['flatpak', 'run', '--filesystem='+str(ROOT), '--command=env',
                       'org.godotengine.Godot', 'XDG_DATA_HOME='+str(suite_data),
                       'APPDATA='+str(suite_data), '/app/bin/godot-bin']
        else:
            command = [args.godot]
        command += ([] if capture else ['--headless'])
        command += ['--path', str(ROOT), 'tests/'+scene+'.tscn', '--', '--quest-test-mode', *extra]
        label = scene + ('-'+extra[0].lstrip('-') if extra else '')
        try:
            result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True, timeout=180)
        except subprocess.TimeoutExpired:
            print('TIMEOUT '+label, flush=True)
            return False
        output = result.stdout + result.stderr
        (logs / (label+'.txt')).write_text(output)
        markers = re.findall(r'\w+: (\d+) checks, (\d+) failures', output)
        errors = [line for line in output.splitlines() if line.startswith('ERROR:')]
        tolerated = ('resources still in use at exit', 'No multiplayer peer is assigned. Unable to get unique ID.', 'Parameter "body" is null.')
        unexpected = [line for line in errors if not any(known in line for known in tolerated)]
        ok = (result.returncode == 0 and 'SCRIPT ERROR:' not in output and not unexpected and
              (('rendered captures' in output) if capture else (bool(markers) and all(int(failures)==0 for _, failures in markers))))
        print(('PASS ' if ok else 'FAIL ')+label+' '+str(markers)+(' diagnostics='+str(len(errors)) if errors else ''), flush=True)
        if not ok: print('\n'.join(unexpected) or output[-2000:], flush=True)
        return ok
    cases = [
        ('combat-controls-v3', ()), ('combat-controls-v3', ('--read-v3-bindings',)),
        ('incantation-assistant', ()), ('player-combo-chains', ()), ('spell-equipment-ui', ()),
        ('spell-regression', ()), ('snappy-combat', ()), ('quest-pipeline', ()),
        ('quest-accessibility', ()), ('quest-persistence', ('--write-quest-save',)),
        ('quest-persistence', ()), ('combat-feedback-save-v1', ()),
        ('combat-feedback-save-v1', ('--read-full-save',)), ('boss-prototype', ()),
    ]
    passed = [run(scene, extra) for scene, extra in cases]
    if args.capture: passed.append(run('combat-controls-v3-preview', capture=True))
    print(f'{sum(passed)}/{len(passed)} invocations passed. Logs: {logs}')
    raise SystemExit(0 if all(passed) else 1)

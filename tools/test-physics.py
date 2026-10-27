#!/usr/bin/env python3
"""Run Physics checks and reject script errors even when Godot exits successfully."""
import argparse
from pathlib import Path
import re
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--godot', default='godot')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
cases = [
    ('import', ['--editor', '--import', '--quit'], None),
    ('regression', ['res://tests/spell-regression.tscn'], ('SPELL_REGRESSION', 71)),
    ('assistant', ['res://tests/incantation-assistant.tscn'], ('INCANTATION_ASSISTANT', 53)),
    ('player-combos', ['res://tests/player-combo-chains.tscn'], ('PLAYER_COMBO_CHAINS', 22)),
    ('equipment-ui', ['res://tests/spell-equipment-ui.tscn'], ('SPELL_EQUIPMENT_UI', 38)),
    ('my-spells', ['res://tests/my-spells.tscn'], ('MY_SPELLS', 148)),
    ('curriculum', ['res://tests/physics-curriculum.tscn'], ('PHYSICS_CURRICULUM', 272)),
    ('laboratory', ['res://scenes/spell-testing/physics-curriculum-lab.tscn', '--quit-after', '120'], None),
]
failed = False
for name, arguments, expected in cases:
    log = Path(tempfile.gettempdir()) / ('magis-physics-' + name + '.log')
    try:
        result = subprocess.run([args.godot, '--headless', '--path', str(root), *arguments, '--', '--quest-test-mode'],
                                capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        print(f'FAIL {name}: exceeded 120 seconds')
        failed = True
        continue
    output = result.stdout + result.stderr
    log.write_text(output)
    # Existing project shutdown resource diagnostics are reported, not hidden.
    errors = [line for line in output.splitlines() if 'SCRIPT ERROR:' in line or
              ('ERROR:' in line and 'resources still in use at exit' not in line)]
    summary = None
    if expected:
        summary = re.search(rf'{expected[0]}: (\d+) checks, (\d+) failures', output)
    ok = result.returncode == 0 and not errors
    if expected:
        ok &= summary is not None and int(summary[1]) >= expected[1] and int(summary[2]) == 0
    print(f'{"PASS" if ok else "FAIL"} {name}: ' +
          (summary[0] if summary else f'exit {result.returncode}') + f' | {log}')
    for error in errors: print(error)
    if 'resources still in use at exit' in output or 'ObjectDB instances leaked' in output:
        print('  Project shutdown resource warnings remain; see log.')
    failed |= not ok
raise SystemExit(1 if failed else 0)

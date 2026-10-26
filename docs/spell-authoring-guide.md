# Spell authoring guide

## Create a spell in Godot

1. Create a `SpellData` resource in `data/magis/spells/`. Use a unique ID; IDs are stable gameplay identifiers, not necessarily filenames.
2. Assign one or more `academic_fields` resources. Physics, Mathematics and any other field can reuse identical effect classes.
3. Choose delivery and targeting. Use SELF for self-healing/buffs, DIRECT_TARGET for a supplied target, PROJECTILE for shots, AREA_BURST for a pulse, or persistent area/beam/trap/summon as appropriate. Legacy delivery derives its behavior from the existing category.
4. Add typed Resources to `effects`, e.g. DamageEffect, KnockbackEffect and ApplyStatusEffect. Array order is execution order. A nonempty array replaces the legacy damage/status payload; do not expect the old flags to be applied again.
5. Set a directional incantation, upfront cost, preparation time, optional channel costs/duration, cooldown and recovery. Channel effects execute once at the end. Projectile delivery needs positive speed, range and size; the existing player/enemy scenes are defaults if no custom scene is set.
6. Configure radius for areas, duration/tick interval for persistent deliveries, and target range/width for beams. Configure `summon_scene` for summons. Custom projectile scenes must extend SpellEffect and implement start().
7. Run `tools/validate-spells.gd` from the script editor (Run). Inspect errors and prefix warnings in Output. Prefix overlaps are allowed when the chosen incantation strategy makes them intentional.
8. Add the resource to a subject's `contained_spells`. Use explicit prerequisite subject IDs and optional field comprehension ranks. A course's prerequisites also refer to subject IDs. Course membership and intra-course cycles are validated at purchase.
9. Run `tools/bake-spell-manifest.gd` from the script editor before exporting, then commit the generated manifest. It explicitly preloads each resource and works with exported `.remap` resource names.
10. Open `scenes/spell-testing/spell-testing.tscn`, assign `test_spell` in the inspector, and run the current scene. The lab learns/equips it for this runtime session. O toggles casting, I/J/K/L input directions, and P clears/interrupts. Direct-target spell tests require supplying a target through the casting API; the lab has no mouse target picker.

`data/magis/examples/physics-force-v2.tres` demonstrates damage + knockback + slow. It deliberately lives outside the main library so the original repertoire remains eight main spells. The lab includes a physical dummy, floor and terrain wall. Automated tests live in `tests/spell-regression.tscn`.

## Custom effects

Extend `SpellEffectDefinition` in a project script. Export typed configuration, return configuration errors from `validate()`, filter compatible targets in `accepts()`, and apply behavior in `execute(context, target) -> bool`. Return true only when applied. Keep runtime state in the context or an owned runtime node, never in the shared Resource.

Use `SpellExecutor.execute_effects(context, target, children)` for nested effects so recursion and budget limits remain enforced. Check compatibility without assuming every target has a hitbox. Use hitbox damage/healing/status APIs to retain signals, mitigation and authority boundaries. Avoid detached timers referencing deleted actors.

## New academic fields

Create a FieldData resource with a unique `field_id`, display name, description and optional `related_field_ids`. Assign it to spells, courses and subjects; no Player changes are required. Existing strings such as archetype and comprehension remain available for compatibility.

Subjects can set `comprehension_requirements` as field ID -> minimum integer rank. Grant ranks through `Player_Global_Data.set_comprehension(field_id, rank)` from academic gameplay. Requirements are empty by default, so existing subjects do not gain new gates. Earning ranks is separate from purchasing subjects; no automatic mastery is inferred from spell ownership.

## Headless verification

```sh
godot --headless --editor --import --quit --path .
godot --headless --path . res://tests/spell-regression.tscn
godot --headless --path . --quit-after 3
godot --headless --path . res://scenes/spell-testing/spell-testing.tscn --quit-after 5
godot --headless --path . --export-pack Web /tmp/magis-spells.pck
```

Then execute the packed tests from outside the project directory:

```sh
cd /tmp
godot --headless --main-pack /tmp/magis-spells.pck res://tests/spell-regression.tscn
```

Use Godot 4.6. Check both the exit code and log for script errors; a scene callback can abort while the engine remains running. The suite prints an explicit check/failure count. These tests verify packed resource resolution using Godot, not a browser/WebAssembly deployment or a complete visual playthrough.

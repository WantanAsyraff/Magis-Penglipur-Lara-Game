# Testing and validation

Use Godot 4.7 and inspect logs **and** exit status. A GDScript callback can abort while the engine process later exits zero. Completed suites print a named `N checks, M failures` marker. Existing shutdown resource/UID/world-ID diagnostics must be reported separately rather than hidden as clean startup/shutdown. Historical counts belong to historical reports; today's handbook checks are recorded in [handbook validation](handbook-validation.md).

## Smallest relevant check

| Change | Source checks / actual scene |
| --- | --- |
| Spell/effect/status | tools/validate-spells.gd EditorScript; spell-regression, player-combo-chains, incantation-assistant, physics-curriculum; Physics lab |
| Academic course | AcademicValidator.validate_course and purchase checks; physics-curriculum; new assigned SpellTreeView |
| Enemy/stats/AI/ability/loot | EnemyData.validate, tools/test-enemies.py static refs and suites; tests/enemy-pipeline.tscn and enemy arena |
| Boss phases/attacks | tests/boss-prototype.tscn plus new arena/phase geometry and cleanup checks |
| Quest/item/NPC/recipe | tools/test-quests.py, quest-pipeline, quest-accessibility, quest-persistence writer/reader, npc-world-boot-1/-2/-3; actual giver/pickup/crafting flow |
| Save/content evolution | combat-feedback-save-v1 writer/reader, old-save migration fixture, exact receipts/inventory/equipment and separate processes |
| Tutorial/world/presentation | Editor import, actual F6/F5 scene/transition, NPC boot fixtures and manual UI/input/collision review |
| Handbook | tools/validate-docs.py and optional Godot-backed snippet/schema checks |

## Direct commands (local Flatpak installation)

```bash
flatpak run org.godotengine.Godot --version
flatpak run org.godotengine.Godot --headless --path . --editor --import --quit
flatpak run org.godotengine.Godot --headless --path . tests/spell-regression.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/player-combo-chains.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/incantation-assistant.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/physics-curriculum.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/enemy-pipeline.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/boss-prototype.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/quest-pipeline.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/quest-accessibility.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/quest-persistence.tscn -- --quest-test-mode --write-quest-save
flatpak run org.godotengine.Godot --headless --path . tests/quest-persistence.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/combat-feedback-save-v1.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/combat-feedback-save-v1.tscn -- --quest-test-mode --read-full-save
```

Save V1's reader requires its writer fixture first and cleans it afterward. Do not run those shared-profile fixtures concurrently. All gameplay test launches need --quest-test-mode: the full-game suite uses test-prefixed slots and refuses otherwise; older suites use explicit isolated paths. Never change a production save to create a failing test.

The existing Python wrappers run larger cross-system checks and reject script errors/missing markers; use a native executable or the wrapper described in [workflow](../developer-workflow.md):

```bash
python3 tools/test-physics.py --godot /path/to/godot
python3 tools/test-enemies.py --godot /path/to/godot
python3 tools/test-quests.py --godot /path/to/godot --skip-shared --packed
```

`/path/to/godot` is a placeholder to replace, not a file in the repository. The packed quest runner clears generated `.godot/exported` conversion cache before export and uses temporary output. With Flatpak, choose a TMPDIR visible to both host and app or use the direct export commands below; app-private /tmp is not necessarily the host /tmp.

## Editor-only validation/baking tools

Open tools/validate-spells.gd, bake-spell-manifest.gd or bake-world-manifest.gd in the Script editor and run Ctrl+Shift+X. These are EditorScript, not SceneTree command-line scripts. Validators print actual results; bakers write their named manifests and need a diff review. Never invent analogous enemy/item/quest bake commands.

## Exported resources and separate processes

The actual export preset name is Web. PCK export exercises resource reachability without claiming a tested browser deployment. Example with a home cache directory visible through Flatpak:

```bash
mkdir -p "$HOME/.cache/magis-content-check"
flatpak run org.godotengine.Godot --headless --path . --export-pack Web "$HOME/.cache/magis-content-check/content.pck"
flatpak run org.godotengine.Godot --headless --main-pack "$HOME/.cache/magis-content-check/content.pck" tests/spell-regression.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --main-pack "$HOME/.cache/magis-content-check/content.pck" tests/quest-persistence.tscn -- --quest-test-mode --write-quest-save
flatpak run org.godotengine.Godot --headless --main-pack "$HOME/.cache/magis-content-check/content.pck" tests/quest-persistence.tscn -- --quest-test-mode
```

Use an actual test/scene referencing your newly authored data too; existing suite success alone does not prove that new definition is retained. If changed schema fields appear stale in a pack, remove only the generated export-conversion cache after checking what will be rebuilt, then re-export. Do not delete source Resources or production saves to fix an export.

## Documentation checks and limits

`python3 tools/validate-docs.py` validates local Markdown destinations/anchors, concrete res:// source paths, complete first-party Resource-to-guide coverage and generated property-reference drift. `--write-reference` intentionally rewrites that generated reference; review it. `--check-gdscript` compiles executable gdscript fences by loading them in a normal project scene with its autoload context, without calling their example functions. `--check-resources` loads example tres fences and introspects Resource exported fields against the source inventory. Use `GODOT_COMMAND='flatpak run org.godotengine.Godot'` for the local installation.

Neither static links nor schema introspection proves prose semantics, UI accessibility, balance, narrative completeness, multiplayer synchronization, physical world reachability or power-loss durability. Those require source review, focused behavior tests and actual play/rendered evidence. The [audit](../documentation-audit.md) records unsupported/partially implemented boundaries instead of turning them into fictional workflows.

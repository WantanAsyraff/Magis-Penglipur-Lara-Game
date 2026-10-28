# Combat feedback and save V1 verification

Verified 2026-10-28 (Asia/Kuching), using `4.7.2.stable.flathub.ed1daf0bf`, matching the project's 4.7 configuration. Branch starts at latest reviewed main `3c67362bc6bacbc845f60f5410e3be71e07dcfb8`. No engine downgrade or content/stat/reward/UID changes were made. Nothing was pushed or merged.

## Results

All listed commands exited 0. There were **1,025 source assertions with zero failures**, plus **80 exported-pack assertions with zero failures**. These totals count the rendered writer once, not repeated development runs. Final logs contain no script, parse or missing-resource errors.

| Suite | Checks | Failures |
| --- | ---: | ---: |
| Spell regression | 71 | 0 |
| Player combo chains | 23 | 0 |
| Incantation Assistant | 60 | 0 |
| Physics curriculum | 272 | 0 |
| Enemy pipeline | 138 | 0 |
| Boss prototype | 70 | 0 |
| Quest pipeline, including inventory/reward integration | 172 | 0 |
| Quest accessibility | 90 | 0 |
| Spell equipment UI | 38 | 0 |
| Quest persistence writer / fresh process reader | 4 / 7 | 0 |
| New combat feedback/full-game writer and rendered captures | 60 | 0 |
| New full-game fresh process reader | 20 | 0 |
| Exported-pack new suite writer / fresh process reader | 60 / 20 | 0 |

[Collected result lines](verification/combat-save-v1/results.txt) and [complete per-command logs](verification/combat-save-v1/) are committed (ANSI escapes and trailing whitespace normalized). Editor import, startup and Web-preset PCK export succeeded. The exported pack loaded the production campaign, spell/curriculum/item Resources, menus, boss room and saved state in independent processes. Browser execution and browser storage durability were not tested.

The new writer exercises clean New Game and confirmed replacement, actual quest reward commits through the full autosave, academics, ordered spells, inventory/equipment/capacity, dungeon keys, world flags, stack/classification/selective clear, accepted input and execution rejection, checkpoint collision checks, malformed destinations/numbers/IDs/dead snapshots, oversized writes, corruption refusal, explicit backup recovery, failed temporary writes, repeated saves, legacy import, real prototype isolation and a real ephemeral network peer. The reader verifies scene/position/vitals/context, academic and spell state, equipment, conversations, tracked quests, exact XP/quantities, replay rejection, single-player instance count and death recovery after process restart.

## Commands

Run from the repository root. Godot is installed through Flatpak on this machine.

```bash
flatpak run org.godotengine.Godot --version
flatpak run org.godotengine.Godot --headless --path . --editor --import --quit
flatpak run org.godotengine.Godot --headless --path . --quit-after 8 -- --quest-test-mode

for suite in spell-regression player-combo-chains incantation-assistant physics-curriculum enemy-pipeline boss-prototype quest-pipeline quest-accessibility spell-equipment-ui; do
  flatpak run org.godotengine.Godot --headless --path . "tests/$suite.tscn" -- --quest-test-mode
done

flatpak run org.godotengine.Godot --headless --path . tests/quest-persistence.tscn -- --quest-test-mode --write-quest-save
flatpak run org.godotengine.Godot --headless --path . tests/quest-persistence.tscn -- --quest-test-mode

# Actual rendered game plus writer fixture; requires a display.
flatpak run org.godotengine.Godot --path . tests/combat-feedback-save-v1.tscn -- --quest-test-mode --capture-save-v1
# Separate process, not an in-memory serialization round trip.
flatpak run org.godotengine.Godot --headless --path . tests/combat-feedback-save-v1.tscn -- --quest-test-mode --read-full-save

flatpak run org.godotengine.Godot --headless --path . --export-pack Web /home/wantansirap/.cache/mpl-save-v1-validation/game.pck
flatpak run org.godotengine.Godot --headless --main-pack /home/wantansirap/.cache/mpl-save-v1-validation/game.pck tests/combat-feedback-save-v1.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --main-pack /home/wantansirap/.cache/mpl-save-v1-validation/game.pck tests/combat-feedback-save-v1.tscn -- --quest-test-mode --read-full-save

git diff --check
```

The new suite refuses to run without `--quest-test-mode`. Full-game files use `test-profile-*`, migration uses `quest-legacy-save-v1-test.json`, and existing quest suites use their isolated fixture paths. Production character/legacy saves were not overwritten. Do not run the new suite concurrently with itself: its writer and reader deliberately share one isolated fixture. The exported pack is a local validation artifact, outside the repository.

## Rendered evidence

Twenty-two PNGs come from the actual game/production menus using `tests/save-v1-preview.gd`, not mockups. Each view has a 1280×720 and 1920×1080 version. Window and logical content size are both set to the target resolution to stress anchors/containers rather than only downscale the original 1920 design.

| Evidence | 1280×720 | 1920×1080 |
| --- | --- | --- |
| Buffs and independent stacks | [Image](previews/combat-save-v1/01-buffs-stacks-1280.png) | [Image](previews/combat-save-v1/01-buffs-stacks-1920.png) |
| Debuffs and priority | [Image](previews/combat-save-v1/02-debuffs-1280.png) | [Image](previews/combat-save-v1/02-debuffs-1920.png) |
| Unchanged minimal next-key assistant | [Image](previews/combat-save-v1/03-minimal-assistant-1280.png) | [Image](previews/combat-save-v1/03-minimal-assistant-1920.png) |
| Accepted-input burst, gameplay camera | [Image](previews/combat-save-v1/04-accepted-input-particles-1280.png) | [Image](previews/combat-save-v1/04-accepted-input-particles-1920.png) |
| Tiny burst, closer actual camera | [Image](previews/combat-save-v1/04b-particle-closeup-1280.png) | [Image](previews/combat-save-v1/04b-particle-closeup-1920.png) |
| Expiration and empty HUD | [Image](previews/combat-save-v1/05-expired-1280.png) | [Image](previews/combat-save-v1/05-expired-1920.png) |
| Successful manual save while paused | [Image](previews/combat-save-v1/06-manual-save-confirmation-1280.png) | [Image](previews/combat-save-v1/06-manual-save-confirmation-1920.png) |
| New Game/profile selection | [Image](previews/combat-save-v1/07-new-game-1280.png) | [Image](previews/combat-save-v1/07-new-game-1920.png) |
| Continue/real selected-slot metadata | [Image](previews/combat-save-v1/08-load-slots-1280.png) | [Image](previews/combat-save-v1/08-load-slots-1920.png) |
| Restored campaign | [Image](previews/combat-save-v1/09-restored-scene-1280.png) | [Image](previews/combat-save-v1/09-restored-scene-1920.png) |
| Full-health checkpoint recovery | [Image](previews/combat-save-v1/10-checkpoint-recovery-1280.png) | [Image](previews/combat-save-v1/10-checkpoint-recovery-1920.png) |

These are scripted renderer fixtures: buff/debuff application, accepted input, save, load and recovery call the production components. They do not substitute for the separate-process durability assertions or a human balance/narrative playthrough. The closer particle shot changes only camera zoom for visibility of the deliberately restrained burst.

## Changed files and compatibility

[Complete changed-file manifest](verification/combat-save-v1/changed-files.txt) accompanies the commits. Primary additions are:

- `autoloads/save-manager.gd`, `components/save/{game-save-schema,game-save-store,world-persistence,checkpoint}.gd` and `checkpoint.tscn`.
- `scenes/ui/status-effects/{status-effects-hud,status-effect-icon}.tscn/.gd` and `status-presentation.gd`.
- `components/characters/player/effects/incantation-input-particles.tscn/.gd`.
- Shared `save-slot-menu.gd`, completed New Game/Load menus, Pause Save and ordinary death integration.
- Safe staging in QuestManager, acquisition suppression during restoration, authored opening spawn, load-safe story startup and durable world-object adapters.
- Regression scene/scripts, documentation, raw logs and rendered evidence.

Shared-prefix chaining remains compatible: its trie and cast queue were not changed, and production combo/assistant suites pass. Quest reward amounts/definitions and exactly-once claims remain compatible through the same QuestRewardService rollback and QuestSaveService bundle. Enemy V2 passes 138 checks. The boss prototype passes 70 checks and the new suite enters the actual room to verify it cannot overwrite campaign data. Its encounter/retry implementation is unchanged.

Feature commits: `d6854fe` (status HUD), `e927d95` (input particles), `9861783` (coordinated campaign saves). Test/evidence commit: `dcdd863`; a final hardening commit bounds encoded file size and normalizes captured output.

## Remaining limits and baseline issues

- Single-player campaign persistence only; no network inventory/profile synchronization.
- Enemies, dropped loot, projectiles, temporary effects, cooldowns and open UI do not persist. See the explicit [transient policy](save-system-v1.md).
- Unknown/retired content IDs require an authored migration. Future courses must be registered in the schema's course list. Persistent object paths must remain stable or receive a migration.
- Disk commits are synchronous. Local Linux flush/rename behavior was tested; universal power-loss guarantees, cloud sync and Web storage were not.
- Existing asset UID fallback warnings, one uppercase scene-ID warning, camera interpolation warning and the **25 resources still in use at exit** warning remain. An unchanged checkout of reviewed main reproduces the same 25-resource shutdown warning and passes its combo checks; its raw log is included. These warnings are not reported as clean shutdowns.
- Existing top-left health-panel anchors and pause-menu artwork assume the 1920 logical design. At a forced 1280 logical viewport they clip/stretch; the new status row, assistant separation and save menus remain usable. Default viewport scaling retains the authored 1920 design. These unrelated legacy layouts were not redesigned.
- Full narrative pacing and manual hardware/platform playtesting remain outside the automated evidence. No durability claim rests on screenshots alone.

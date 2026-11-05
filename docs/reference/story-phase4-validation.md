# Story Phase 4 validation

Branch `feature/story-pipeline-phase4-world-dialogue`; base `bd320fe9cf889247232c0f8cc14f4f2acfe40e92`. The Phase 1–3 foundation is present in this shared, uncommitted worktree. No changes were pushed or merged.

## Executed checks

Run with Godot 4.7.2 Flatpak and isolated `XDG_DATA_HOME=/home/wantansirap/.cache/story-phase4-tests`, `--headless --path <project> res://tests/<scene>.tscn -- --quest-test-mode`:

| Scene | Assertions | Failures |
| --- | ---: | ---: |
| `tests/story/story-world.tscn` | 28 | 0 |
| `tests/story/story-save.tscn` | 20 | 0 |
| `tests/story/story-foundation.tscn` | 24 | 0 |
| `tests/story/story-transitions.tscn` | 20 | 0 |
| `tests/quest-pipeline.tscn` | 172 | 0 |
| `tests/quest-accessibility.tscn` | 90 | 0 |
| `tests/cutscene-skip.tscn` | 29 | 0 |
| `tests/environment-prologue.tscn` | 8 | 0 |
| `tests/prologue-inventory-integration.tscn` | 28 | 0 |
| `tests/npc-world-boot-1.tscn` | 4 | 0 |
| `tests/story/story-roundtrip.tscn` writer, separate process | 9 | 0 |
| `tests/story/story-roundtrip.tscn` reader, separate process | 20 | 0 |

Godot editor import completed without script parse errors. Web PCK export succeeded; `story-world.tscn` passed 28 checks from source and 28 from the exported pack. The editor reported existing fallback-path UID warnings for some unrelated assets.

## Production example and limits

The after-final-paper subway scene uses `StoryCutsceneTrigger` with its existing CutsceneSequence; CutsceneFlow still owns completion and grants. The prologue intro and exam dialogue were not rewritten. No verified production SPM pass event is available, so the practical completion gate remains a fixture rather than a new mandatory route. The fixture verifies the condition, portal, elevator, NPC presence, visual and actuator reactions and once-only dialogue selection.

The optional visual capture of `npc-world-boot-1.tscn` passed 5 checks at 1920×1080 and 1280×720. [Hidden NPC, 1080p](../previews/story-phase4/npc-hidden.png), [visible NPC, 1080p](../previews/story-phase4/npc-visible.png), [hidden NPC, 720p](../previews/story-phase4/npc-hidden-720p.png), and [visible NPC, 720p](../previews/story-phase4/npc-visible-720p.png) were inspected. The 720p capture exposed an objective-line overflow; the shared overworld HUD now separates its story heading and objective text, and the recaptured result fits the panel. The live boot test also verifies existing grounded NPC placement and interaction clearance.

The separate-process writer/reader verified story stage, typed variable, choice, transition/action receipts and the new dialogue receipt across a save/load. It also verified that a restored dialogue receipt rejects a duplicate completion. Full interactive prologue playthrough, conditional dialogue screenshots, locked/unlocked route screenshots, dialogue interruption, a real story-gated deferred spawn in a production level, and silent visual feedback for every linked environmental device are not verified here. Source and PCK assertions cannot establish production narrative correctness. StoryPresenceComponent hides and disables an existing NPC instance rather than deleting it on a false condition.

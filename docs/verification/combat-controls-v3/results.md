# V3 verification and handover

Base: fetched `origin/main` at `b9ecee64256e181402e16087c4afbab5b52409ce`. Branch: `feature/combat-controls-presentation-v3`. Checkout: `/tmp/magis-combat-v3`. The original working directory, branch and its uncommitted changes were left in place. No push or merge was performed.

## Final execution

Godot **4.7.2 stable**. Command actually executed:

```sh
python3 tools/test-combat-controls-v3.py --flatpak --capture
```

**15/15 invocations passed; 775 assertions, zero assertion failures, zero GDScript errors in the final run.** [Run summary](run-summary.txt) and individual raw logs are committed alongside this report. The isolated test preferences and test-prefixed campaigns lived beneath temporary `.godot/v3-test-users-*` directories. Writer/reader pairs ran in order.

| Scene / invocation | Checks | Failures |
|---|---:|---:|
| combat-controls-v3 | 104 | 0 |
| combat-controls-v3, fresh bindings reader | 1 | 0 |
| incantation-assistant | 60 | 0 |
| player-combo-chains | 23 | 0 |
| spell-equipment-ui | 38 | 0 |
| spell-regression | 71 | 0 |
| snappy-combat | 55 | 0 |
| quest-pipeline | 172 | 0 |
| quest-accessibility | 90 | 0 |
| quest-persistence writer | 4 | 0 |
| quest-persistence fresh reader | 7 | 0 |
| combat-feedback-save-v1 writer | 60 | 0 |
| combat-feedback-save-v1 fresh reader | 20 | 0 |
| boss-prototype | 70 | 0 |
| combat-controls-v3-preview | 30 rendered PNGs | 0 capture errors |

A final editor import completed without script/resource errors; it reports two ObjectDB instances at shutdown ([log](editor-import.txt)). `git diff --check` and Python runner compilation also completed successfully. The updated inventory scripts were subsequently loaded and exercised by the final integration suite and rendering driver.

The broad regression logs are **not diagnostically clean**. They retain invalid UID/path-fallback and duplicate world-ID warnings, 25-resources-in-use shutdown diagnostics, the save fixture's missing multiplayer-peer messages, and three stale collision-body RID diagnostics in `snappy-combat.gd` (lines 101, 102 and 173). The runner prints diagnostic counts, retains complete logs, rejects GDScript errors and unexpected error categories, and explicitly tolerates those three known engine-diagnostic categories. These are separate from the zero failed assertions.

An early test launch showed that Flatpak overrides startup XDG variables. The observed initial IJKL/Guided application preferences were restored. The final runner sets XDG/APPDATA inside the sandbox, creates the directories before launch, and the V3 suite refuses a non-isolated data path. Final runs did not write normal campaign profiles or application preferences.

## Rendered inspection

The driver loaded the **production boss gameplay room** and Player, used real resolver/casting/equipment events, and captured the viewport through Godot's GL Compatibility renderer (Mesa Intel OpenGL). The integration suite additionally created and loaded the production prologue campaign before exercising casting and equipment.

All 30 images have the requested physical dimensions (15 at 1280×720 and 15 at 1920×1080). Full-size captures and contact sheets were visually inspected, including the new inventory buttons. Captures are [here](../../previews/combat-controls-v3/).

| State | 720p | 1080p |
|---|---|---|
| Settings | [image](../../previews/combat-controls-v3/01-settings-1280.png) | [image](../../previews/combat-controls-v3/01-settings-1920.png) |
| IJKL selection | [image](../../previews/combat-controls-v3/02-preset-ijkl-1280.png) | [image](../../previews/combat-controls-v3/02-preset-ijkl-1920.png) |
| Arrow selection | [image](../../previews/combat-controls-v3/03-preset-arrows-1280.png) | [image](../../previews/combat-controls-v3/03-preset-arrows-1920.png) |
| Empty rig | [image](../../previews/combat-controls-v3/04-empty-weapon-rig-1280.png) | [image](../../previews/combat-controls-v3/04-empty-weapon-rig-1920.png) |
| Initial aura | [image](../../previews/combat-controls-v3/05-initial-aura-1280.png) | [image](../../previews/combat-controls-v3/05-initial-aura-1920.png) |
| Mid-combo | [image](../../previews/combat-controls-v3/06-mid-combo-1280.png) | [image](../../previews/combat-controls-v3/06-mid-combo-1920.png) |
| Successful launch release | [image](../../previews/combat-controls-v3/07-cast-release-1280.png) | [image](../../previews/combat-controls-v3/07-cast-release-1920.png) |
| Shared-prefix paths | [image](../../previews/combat-controls-v3/08-shared-prefix-paths-1280.png) | [image](../../previews/combat-controls-v3/08-shared-prefix-paths-1920.png) |
| Equipped weapon | [image](../../previews/combat-controls-v3/09-equipped-weapon-1280.png) | [image](../../previews/combat-controls-v3/09-equipped-weapon-1920.png) |
| Attack placeholder | [image](../../previews/combat-controls-v3/10-weapon-attack-1280.png) | [image](../../previews/combat-controls-v3/10-weapon-attack-1920.png) |
| Cast placeholder | [image](../../previews/combat-controls-v3/11-weapon-cast-1280.png) | [image](../../previews/combat-controls-v3/11-weapon-cast-1920.png) |
| Long path | [image](../../previews/combat-controls-v3/12-long-path-1280.png) | [image](../../previews/combat-controls-v3/12-long-path-1920.png) |
| Minimal | [image](../../previews/combat-controls-v3/13-minimal-1280.png) | [image](../../previews/combat-controls-v3/13-minimal-1920.png) |
| Off | [image](../../previews/combat-controls-v3/14-off-1280.png) | [image](../../previews/combat-controls-v3/14-off-1920.png) |
| Inventory weapon controls | [image](../../previews/combat-controls-v3/15-inventory-weapon-1280.png) | [image](../../previews/combat-controls-v3/15-inventory-weapon-1920.png) |

The new aura remains small and translucent. Existing authored projectile/impact artwork is conspicuously large in successful-launch captures; those legacy assets were not changed. Weapon inspection captures clean up the fixture's dispatched deliveries before showing the thin geometric placeholder. Existing body frames switch between the project's original temporary sprites. Several authored Physics spells share the same temporary SpellData icon; the HUD correctly uses those resources rather than substituting invented artwork.

Physical controller hardware and extended manual play across every campaign scene were not available. Controller remapping, keyboard UI navigation and controller Accept were driven with actual InputEvents through the viewport. The preview freezes actor locomotion for reproducible visual comparisons; automated movement/combat regressions run separately. Arbitrarily longer-than-tested incantations can still need substantial vertical space in Guided mode; Minimal limits its direction window.

## Architectural handover and assets

[Full implementation and authoring guide](../../combat-controls-presentation-v3.md) documents persistence, how to add a preset, advanced remapping, the particle lifecycle/exports, resolver-to-HUD data flow, icon authoring, exact WeaponRig hierarchy, every WeaponVisualData export, and replacing texture/scene/animation assets.

Controls drafts and presets are application-level. New Game confirms controls before calling campaign creation. Particles observe accepted input and actual delivery without changing the resolver. The HUD caches four views from equipped SpellData. Weapon visuals observe the existing WEAPON slot and never add damage/stat calculations. Nine editable named animations are shipped. The production Inventory app now exposes real Equip/Unequip actions against that slot.

The practice weapon is registered for pickup/reward authoring but not automatically granted. Main has no general melee attack event; `present_attack(index, airborne)` is the documented interface, with existing push success, block, parry, stance and cast hooks already integrated. Future art can replace the particle root texture or WeaponVisualData scene/texture/AnimationLibrary without rewriting Player.

The complete created/modified file inventory is [changed-files.txt](changed-files.txt), including script UID sidecars, raw verification logs and all screenshots. Principal changes:

- New `system/input/control-bindings.gd`; startup load in `autoloads/player-data.gd`.
- Redesigned settings script/scene, compact binding row script/scene, new `controls-style.gd`.
- New `casting-preset-panel.gd`; integration in `intro-menus/save-slot-menu.gd`.
- Extended `effects/incantation-input-particles.gd`; Player lifecycle/input guards; delivery observation signal in SpellCastingComponent.
- Extended IncantationAssistant script/scene; duplicate repertoire forecast disabled by default.
- New `weapons/weapon-rig.tscn`, placeholder scene/controller, WeaponVisualData, ItemData field, registered practice item; rig instance in production player.tscn.
- Existing inventory UI/slot scripts gain selection and Equip/Unequip controls; project UI Accept retains keyboard keys and adds controller A.
- Updated assistant regression expectations; new V3 integration/preview scenes and runner; documentation, screenshots and execution evidence.

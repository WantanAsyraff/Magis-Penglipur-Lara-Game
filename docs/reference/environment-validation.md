# Environmental Interactions V1 — implementation and validation

Validated locally on 2026-10-29 using Godot 4.7.2, branch `feature/environmental-interactions-v1`, based on main `b9ecee64256e181402e16087c4afbab5b52409ce`. Work is committed locally; nothing was pushed or merged.

## 1. Implementation summary

Shared validated Resources, typed receiver/actuator signals and replaceable native visuals connect real environmental physics to the existing Player, Hitbox, SpellExecutor, projectile, loot, key and WorldPersistence systems. Controls are F interaction, E push, Q hostiles, R explicit neutral devices and B phone. O toggles casting; I/J/K/L enter incantations. The new action is remappable. Stable enemy lock behavior and independent spell reuse cooldowns remain covered by regressions.

## 2. Twelve reusable mechanics

1. Light switches, fuse boxes and actual lights.
2. Powered/timed/persistent gates and consumable-key doors.
3. Taps and partially open valves.
4. Powered pumps and volume-conserving tanks.
5. Accelerating/decelerating ceiling fans with opt-in airflow.
6. Blockable drainage channels with capacity, backpressure and overflow signal.
7. Mass-sensitive pressure plates with debounce and four output policies.
8. Neutral Magis receivers with effect/status, hit-count and charge conditions.
9. Warning/firing/cooldown turrets with production projectiles and nonlethal training.
10. Damageable/impulse-responsive breakables, floating crates and legacy boxes.
11. Normally open/closed, AND/OR electrical relay connections with bounded cycles.
12. Physical multi-waypoint platforms with dwell, route, reversal and power interruption.

[Inspector recipes](../authoring/environmental-interactions.md) give the exact reusable scene names and settings for each.

## 3. Scenes and Resources

The reusable [component directory](../../components/environment/) contains twenty ready-to-instance scenes, including the water volume and floating crate. Shared implementations live under `core`, `water`, `mechanisms` and `destructibles`.

Five new Resource classes are [InteractionRule](../../data/environment/interaction-rule.gd), [EnvironmentLink](../../data/environment/environment-link.gd), [EnvironmentDeviceData](../../data/environment/environment-device-data.gd), [EnvironmentVisualData](../../data/environment/environment-visual-data.gd) and [MovingPlatformData](../../data/environment/moving-platform-data.gd). Example configurations, cooled/spell/impulse/hit-count/charge rules and the training projectile are in [environment data](../../data/environment/). All five classes are in the generated Resource handbook inventory.

## 4. Laboratory entry

Open [environment-interactions-lab.tscn](../../scenes/environment-testing/environment-interactions-lab.tscn) and press F6. Twelve labelled stations have authored Inspector links, real floor/wall collision, the production Player and temporary training spells. Number buttons navigate; Reset station/Reset room rebuild transient state without writing campaign saves. Exit restores the caller's player state, loadout and key metadata. The lab explicitly requires an offline session.

## 5. Four connected puzzles

- **A, station 02:** F restores the fuse, then the switch opens the powered door. Powered gates reject manual interaction, so F at the gate cannot bypass its circuit. A second door demonstrates key consumption.
- **B, station 04:** F supplies pump power and opens the valve. A conserved 100 L source fills the pool, buoyancy raises the crate, and current carries it onto the elevated plate to open a gate.
- **C, station 08:** Physical R/O/incantation inputs cast actual Kinetic Chill. Its cooled payload activates the receiver, relay and lift; the player can ride to the landing.
- **D, station 09:** The opt-in training turret warns and fires actual damaging projectiles. F at the emergency switch clears the attack state and stops future shots. Training damage bottoms out at 1 HP.

The live suite also checks connected reset, a two-input relay, ordinary crate pushing, fan force, swimming, platform carrying and interruption. See [puzzle authoring](../authoring/environmental-puzzles.md).

## 6. Replacing placeholder art

Assign a unique `visual` Resource on device data, `visual_data` on crates, or `MovingPlatformData.visual` on platforms. Choose Texture2D, SpriteFrames, or a custom Node2D PackedScene with AnimationPlayer. Configure idle/active/broken names, sounds and activation particles. Gameplay collision and links stay on the root. Missing state animations fall back to idle. Core tests exercise each replacement path and verify collision is unchanged. [Visual workflow](../authoring/environmental-visuals-and-animations.md) documents the editor preview and imported-art boundaries.

## 7. Prologue integration

House utilities provide a switch/light/fan, raised tanks, tap/valve/pump, drainage, a movable crate and an open pagar. School equipment provides a Kinetic Chill receiver, relay, raised gate/lift, optional practice obstacle, weighted light indicator and opt-in nonlethal turret with emergency cutoff. Optional apparatus loads after the campaign manifest resolves scene Resources, avoiding an eager-loading dependency cycle.

Both existing prologue controllers and all Dialogic timelines are unchanged. Eight checks confirm apparatus boot, no restoration dialogue, no extra spell grants, safe initial turret state and actual walking traversal of both main routes without activating the new mechanisms. New mandatory story gating was not introduced.

## 8. Save/load behavior

Permanent `activated` and `broken` flags use WorldPersistence and the current SaveManager schema. Stable authored scene/node paths define object identity. Persistent breakage reloads with collision disabled. Water volume, plate occupancy, platform position, timers, turret phase and fan motion are transient and reset.

A dedicated writer and fresh-process reader create a test-prefixed campaign profile, break an authored-path fixture, save through SaveManager, reload it, confirm restored collision removal and reset water, then delete fixture slots. The lab cannot qualify as a registered campaign ZoneRoot and does not write campaign saves.

## 9. Actual test results

Each completed source suite exited 0 and printed zero failures; logs were checked for script errors.

| Source suite | Checks | Failures |
| --- | ---: | ---: |
| spell-regression | 71 | 0 |
| live-spell-audit | 46 | 0 |
| player-combo-chains | 23 | 0 |
| incantation-assistant | 60 | 0 |
| enemy-pipeline | 138 | 0 |
| boss-prototype | 70 | 0 |
| combat-feedback-save-v1 writer / fresh reader | 60 / 20 | 0 / 0 |
| target-lock-and-hud | 37 | 0 |
| target-lock-stability | 13 | 0 |
| physics-curriculum | 272 | 0 |
| environment-interactions | 83 | 0 |
| environment-lab-gameplay | 26 | 0 |
| environment-prologue | 8 | 0 |
| environment-persistence writer / fresh reader | 4 / 4 | 0 / 0 |

The exported Web PCK passes environment core **83/83**, live lab **26/26**, prologue **8/8**, and persistence writer/reader **4/4 + 4/4** in native headless Godot. This tests resource reachability and physics outside the source project; it does not claim browser deployment validation. The local artifact is `/home/wantansirap/.cache/magis-environment-check/environment.pck`.

Reproduce ordinary source suites with:

```bash
for suite in spell-regression live-spell-audit player-combo-chains incantation-assistant enemy-pipeline boss-prototype target-lock-and-hud target-lock-stability physics-curriculum environment-interactions environment-lab-gameplay environment-prologue; do
  flatpak run org.godotengine.Godot --headless --path . "tests/$suite.tscn" -- --quest-test-mode
done
```

Writer/reader, renderer and PCK commands are in [testing and validation](testing-and-validation.md). The full handbook command is `GODOT_COMMAND='flatpak run org.godotengine.Godot' python3 tools/validate-docs.py --check-gdscript --check-resources`: zero validation errors, 47 Resource classes, 480 exported properties, two executable snippets and two Resource examples. Editor import and `git diff --check` also pass.

## 10. Native renderer evidence

The capture driver uses the real lab, physical interaction/incantation inputs and actual physics. Each resolution has twelve station images and four puzzle images, with no fabricated UI or painted gameplay state.

| Example | 1280×720 | 1920×1080 |
| --- | --- | --- |
| station-01 | [720p](../previews/environment/1280x720/station-01.png) | [1080p](../previews/environment/1920x1080/station-01.png) |
| station-02 | [720p](../previews/environment/1280x720/station-02.png) | [1080p](../previews/environment/1920x1080/station-02.png) |
| station-03 | [720p](../previews/environment/1280x720/station-03.png) | [1080p](../previews/environment/1920x1080/station-03.png) |
| station-04 | [720p](../previews/environment/1280x720/station-04.png) | [1080p](../previews/environment/1920x1080/station-04.png) |
| station-05 | [720p](../previews/environment/1280x720/station-05.png) | [1080p](../previews/environment/1920x1080/station-05.png) |
| station-06 | [720p](../previews/environment/1280x720/station-06.png) | [1080p](../previews/environment/1920x1080/station-06.png) |
| station-07 | [720p](../previews/environment/1280x720/station-07.png) | [1080p](../previews/environment/1920x1080/station-07.png) |
| station-08 | [720p](../previews/environment/1280x720/station-08.png) | [1080p](../previews/environment/1920x1080/station-08.png) |
| station-09 | [720p](../previews/environment/1280x720/station-09.png) | [1080p](../previews/environment/1920x1080/station-09.png) |
| station-10 | [720p](../previews/environment/1280x720/station-10.png) | [1080p](../previews/environment/1920x1080/station-10.png) |
| station-11 | [720p](../previews/environment/1280x720/station-11.png) | [1080p](../previews/environment/1920x1080/station-11.png) |
| station-12 | [720p](../previews/environment/1280x720/station-12.png) | [1080p](../previews/environment/1920x1080/station-12.png) |
| puzzle-A | [720p](../previews/environment/1280x720/puzzle-A.png) | [1080p](../previews/environment/1920x1080/puzzle-A.png) |
| puzzle-B | [720p](../previews/environment/1280x720/puzzle-B.png) | [1080p](../previews/environment/1920x1080/puzzle-B.png) |
| puzzle-C | [720p](../previews/environment/1280x720/puzzle-C.png) | [1080p](../previews/environment/1920x1080/puzzle-C.png) |
| puzzle-D | [720p](../previews/environment/1280x720/puzzle-D.png) | [1080p](../previews/environment/1920x1080/puzzle-D.png) |

## 11. Known limitations

- Visuals are functional original placeholders; final Malaysian set dressing, sound and animation polish remain art work.
- Water is a rectangular buoyancy/current model. Overflow is capacity/backpressure feedback, not flooding or particle fluid simulation.
- Non-Boolean simulation state is transient. No continuous water/platform state migration was added to saves.
- The lab is offline. Gameplay effects retain authority guards; synchronized multiplayer mechanism state needs separate integration testing.
- Platforms stop at static terrain; level authors must provide rider head clearance and avoid crushing layouts.
- Imported fan artwork needs its own blade animation; native fan drawing rotates automatically.
- Renderer captures are scripted gameplay evidence. A human accessibility/balance pass and full narrative playthrough remain separate review work.
- Godot still reports the pre-existing invalid-UID fallbacks, world-ID warning and shutdown ObjectDB/resource diagnostic (commonly 58 instances / 25 resources). Completed checks have no GDScript errors; the shutdown warning is not presented as a clean engine shutdown.

## 12. Local commits

- `622fc2c` — reusable devices, interaction framework and Magis/physics integration.
- `4bf6eb2` — twelve-station lab, connected puzzles and real-control tests.
- `a169bc5` — optional kampung/school apparatus and persistence/prologue checks.
- `f0c2f42` — powered gates reject manual bypass; opt-in player fan motion survives movement updates.
- `69bb42d` — correct lab combat startup, remappable legacy prompts and real two-receiver/Q input checks.
- `c6e76d3` — configurable Magis controls retain projectile hit collision; partial-flow and physical-hit regressions.
- `e66a998` — persist activation from linked actuators and verify gate restoration in a fresh process.
- The documentation/evidence commit contains this report; resolve it with `git log -1 -- docs/reference/environment-validation.md`.

No push or merge was performed.

## 13. Remaining integration and balancing

Before turning optional demonstrations into campaign progression, review narrative gating, traversal clearances, interaction spacing, wind strength, pressure mass thresholds and turret cadence. Replace native placeholders with approved production art/audio using the shared visual Resource. Test imported assets in the target browser/export and perform multiplayer synchronization work if those devices are deployed online. These are follow-up production decisions; all twelve mechanics and four standalone demonstrations are implemented.

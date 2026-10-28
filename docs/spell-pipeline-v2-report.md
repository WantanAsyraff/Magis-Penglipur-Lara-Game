# Spell pipeline V2 implementation report

> Historical implementation/verification record. The body below preserves earlier design descriptions, commands and measurements; it is not a newly executed test or the current authoring contract. Use [the current guide](authoring/spells.md) and [Godot 4.7 workflow](developer-workflow.md). Current Player default is CHAINED with independent shared-prefix execution; the assistant now shows only valid next-direction icons. Save V1 supersedes earlier quest-only persistence limits.

Date: 26 October 2026 (Asia/Kuching). Branch: `refactor/magis-spell-pipeline-v2`. Base: `4449ed9`.

## Verified initial findings

- `project.godot` autoloaded a nonexistent scene-transition script. No gameplay caller referenced that singleton. Unused settings referenced the absent yet_another_scene_manager addon; the actual transition implementation is the existing SceneManager addon.
- Enemy ranged attacks instantiated projectiles without calling start(). Both player and enemy code assigned global spawn coordinates to local position before parenting.
- Terrain collisions freed projectiles before AOE resolution. There was no guard against multiple terminal collisions before deferred deletion.
- Player's buff implementation referenced undefined `active_buffs`. Its dispel paths called missing remove/clear APIs and tried to read global_position on a plain Node hitbox.
- Buff timers restored saved speed values, which could overwrite newer overlapping buffs. Healing timers were detached from the owning actor. Preparation and channel cost fields were not respected.
- Shatterwave omitted positive size, range, speed and a damage payload.
- The spell tree called nonexistent Player.add_spells(). Completion checks accepted any owned spell in a subject, and subject purchases could deduct XP repeatedly. Prerequisite depth recursion had no cycle guard. The subject panel rebuilt each frame.
- The library silently overwrote duplicate IDs/incantations and relied on directory enumeration unsuitable for exported remapped resources.
- Remote players reached input/timer/mana logic before their authority guard. Incoming actor combat state used the local singleton.
- Actual startup also exposed a moved prologue reference and two deleted loot definitions. Packed startup exposed five stale entries in the existing baked world manifest.

These findings were checked against current source, repository history and headless execution rather than assumed from the task brief.

## Implementation by phase

1. **Stabilization:** fixed bootstrap paths, projectile initialization/coordinates/AOE, missing dispel functionality, Shatterwave defaults, atomic subject purchases and prerequisite traversal. Restored historical loot identities using current ItemData and pointed the story selector to the current prologue.
2. **Modular execution:** added per-caster lifecycle components, isolated cast contexts, ordered typed effects, legacy adaptation, centralized authority/budget checks and independently selected delivery. Player's former healing/buff/decast/projectile implementations now delegate.
3. **Effects and incantations:** added owner-ticked HoT/status/buff management, stack/refresh/replace/ignore policies, source cancellation and additive stat modifiers. Added a trie resolver with four explicit prefix strategies and an eight-request intentional chain queue.
4. **Academic authoring:** added FieldData, assigned Physics resources to existing academic content, added optional comprehension gates and course cycle diagnostics. Added duplicate/range/effect/reference validation, a baked spell manifest, native editor validation/baking scripts and a three-effect resource example.
5. **Multiplayer boundary:** guarded remote input and presentation/debug/death children, isolated incoming remote stats, and required server authority for gameplay effects and NPC simulation. ENet/Noray remain intact. Full multiplayer cast requests and replication are deferred explicitly.
6. **Regression and documentation:** added a physical spell laboratory, 71 automated checks, packed-resource execution, and architecture/authoring/migration documentation.

## Compatibility

All eight main spell resources still load. A comparison against the base commit verified every spell's resource UID, spell ID and incantation unchanged, plus the UIDs of all three existing course/subject resources. Existing scenes, public class names and legacy exported SpellData fields remain. Existing projectile scenes are reused. Inventory/quest APIs and networking infrastructure are preserved.

Intentional tuning corrections are limited to making Shatterwave functional with Strike's existing basic projectile values, and correcting Physics I's omitted difficulty from zero to one. Existing costs and other spell payloads remain. Cast/channel timing now follows the authored values, and subject purchases now charge the validated formula exactly once. See the migration guide for behavioral details and save-state implications.

## Actual checks and results

Godot 4.6 was downloaded to `/tmp/magis-godot/Godot_v4.6-stable_linux.x86_64`; no engine binary or external dependency was committed. Below, `$GODOT` refers to that executable.

| Command/check | Actual result |
| --- | --- |
| `$GODOT --headless --editor --import --quit --path .` | Exit 0; no parse, missing-resource or script-loading errors. ObjectDB shutdown warning remains. |
| `$GODOT --headless --path . res://tests/spell-regression.tscn` | Exit 0; **71 checks, 0 failures**. |
| `$GODOT --headless --path . --quit-after 3` | Exit 0; main-menu startup has no parse/missing-resource errors. |
| `$GODOT --headless --path . res://scenes/spell-testing/spell-testing.tscn --quit-after 5` | Exit 0; laboratory starts without script or missing-resource errors. |
| `$GODOT --headless --path . --export-pack Web /tmp/magis-spells.pck` | Exit 0; resource pack produced. |
| From `/tmp`: `$GODOT --headless --main-pack /tmp/magis-spells.pck res://tests/spell-regression.tscn` | Exit 0; **71 checks, 0 failures**, including remapped spell/resource loading outside the source directory. |
| Python comparison of base/current resource UID, spell ID and incantation lines | Eight spells and three academic resource UIDs preserved. |
| `git diff --check` and staged equivalent | Pass; no whitespace errors. |

The requested regression categories map to actual passing assertions:

| Requested category | Coverage/result |
| --- | --- |
| Spell resource loading | Eight resources load and validate; V2 example validates. Pass. |
| Duplicate spell IDs | Rejected without changing the registered definition count. Pass. |
| Incantation prefix collisions | Chained, immediate, confirmation and delayed strategies; library diagnostics. Pass. |
| Insufficient mana | No charge; learned/equipped eligibility also checked. Pass. |
| Silence/stun restrictions | Both deny casting. Pass. |
| Cast interruption | Upfront reservation/refund, nonrefunded channel spending, cooldown, queued casts and production Player cancellation. Pass. |
| Projectile collision/AOE | Real physics overlap query with an explicitly invoked terrain collision callback; terminal callback repeated to check one hit. NPC projectile starts at the exact global origin under a transformed parent. Pass. |
| Healing over time | Three timed heals including the final boundary, followed by expiration. Pass. |
| Buff stacking/expiration | Stack cap, independent expiry and source-specific cancellation. Pass. |
| Decast/debuff removal | Dispel preserves buffs; purge removes buffs. Pass. |
| Subject prerequisites/repeat purchase | Missing prerequisite denied, valid purchase succeeds once, repeated XP deduction denied; ownership does not imply completion. Comprehension/cycle diagnostics also checked. Pass. |
| Effect chains/recursion | Circular definitions rejected, runtime recursion bounded and shared budget enforced. Pass. |
| Entity deletion | Queued/freed caster prevents further execution after active healing is attached. Pass. |
| Legacy compatibility | Strike converts to damage/knockback/slow without changing the shared resource; production Player and Enemy scenes initialize. Pass. |
| Exported resource loading | Full suite passes from the exported PCK in `/tmp`. Pass. |
| Multiplayer boundaries | ENet client denied authoritative casts/effects; a remote Player on a test server keeps health/mana separate and disables local input. Pass. |

Additional passing checks cover ordered combined effects, direct/burst/persistent/beam/trap/summon delivery, entity spawn, malformed configuration and incompatible scene roots. The tests exercise gameplay logic headlessly; manually invoked callbacks are not claimed as a complete visual collision or network playthrough.

### Remaining diagnostics and unverified behavior

Runtime shutdown still reports **25 resources in use**, plus ObjectDB leaks. A verbose startup run identifies all 25 resource paths under `addons/dialogic/`; these vendor files were not edited. Several existing stale asset UIDs still fall back to valid text paths. These diagnostics are retained and reported, not described as a warning-free project.

Not verified: full campaign/quest completion, visual balance/animation, manual UI playthrough, live multi-peer ENet/Noray sessions, browser/WebAssembly deployment, platform executable exports or persistence across saves. Packed tests use the Godot executable to read the exported PCK. They do not claim a browser test.

## Known limitations and next milestones

1. Implement authenticated cast-request RPCs, server-owned remote loadouts/stats, replicated projectile/event IDs, reconciliation and cancellation/status replication. Current clients deliberately cannot dispatch authoritative spells.
2. Perform a manual combat/quest/inventory regression and tune Shatterwave. Review how authored preparation times affect existing combos.
3. Integrate explicit subject completion and comprehension into save/load, with a deliberate migration policy for old saves.
4. Add beam occlusion, richer delivery presentation, direct-target UI, summon lifetime/AI contracts and custom persistent spell behaviors.
5. Implement the still-experimental tether, resonance, on-hit proc and misfire mechanics as separate handlers. Fields are preserved; these mechanics are not claimed as completed.
6. Investigate Dialogic shutdown lifecycle and stale asset UID metadata independently of spell gameplay.

## Git checkpoints

- `7e5b419` — Fix spell initialization and atomic academic purchases
- `8d51a21` — Introduce modular spell casting delivery and effect lifecycles
- `9e82420` — Harden incantation chaining academic validation and spell discovery
- `15cf996` — Repair startup scene references and migrate missing legacy loot
- `0b71e50` — Strengthen actor isolation effect cleanup and exported world discovery
- `73a0a65` — Release incompatible delivery scene instances on failure

The final tests/documentation commit is listed by `git log 4449ed9..HEAD`. No merge into main is performed. Push outcome is reported in the final handoff.

## Modified files

The following list includes new/changed scripts, resources, scenes, documentation and their new script UID sidecars.

```text
autoloads/player-data.gd
autoloads/spell-library.gd
autoloads/world-manifest-paths.gd
autoloads/world-manifest.gd
components/NPCs/enemies/enemy-combat.gd
components/NPCs/enemies/enemy.gd
components/NPCs/enemies/hitbox-component.gd
components/characters/player/anim-player-controller.gd
components/characters/player/god-mode-component.gd
components/characters/player/on-death-component.gd
components/characters/player/player.gd
components/projectiles/magis-projectile.gd
components/spell-effect/spell-effect.gd
components/spells/academic-validator.gd
components/spells/academic-validator.gd.uid
components/spells/active-effect-manager.gd
components/spells/active-effect-manager.gd.uid
components/spells/incantation-resolver.gd
components/spells/incantation-resolver.gd.uid
components/spells/legacy-spell-adapter.gd
components/spells/legacy-spell-adapter.gd.uid
components/spells/spell-area-delivery.gd
components/spells/spell-area-delivery.gd.uid
components/spells/spell-cast-context.gd
components/spells/spell-cast-context.gd.uid
components/spells/spell-casting-component.gd
components/spells/spell-casting-component.gd.uid
components/spells/spell-delivery.gd
components/spells/spell-delivery.gd.uid
components/spells/spell-executor.gd
components/spells/spell-executor.gd.uid
components/spells/spell-validator.gd
components/spells/spell-validator.gd.uid
data/Resources/ilmu/course.gd
data/Resources/ilmu/field.gd
data/Resources/ilmu/field.gd.uid
data/Resources/ilmu/spell.gd
data/Resources/ilmu/subject.gd
data/Resources/spell-effects/apply-status-effect.gd
data/Resources/spell-effects/apply-status-effect.gd.uid
data/Resources/spell-effects/conditional-effect.gd
data/Resources/spell-effects/conditional-effect.gd.uid
data/Resources/spell-effects/damage-effect.gd
data/Resources/spell-effects/damage-effect.gd.uid
data/Resources/spell-effects/heal-effect.gd
data/Resources/spell-effects/heal-effect.gd.uid
data/Resources/spell-effects/knockback-effect.gd
data/Resources/spell-effects/knockback-effect.gd.uid
data/Resources/spell-effects/modify-stat-effect.gd
data/Resources/spell-effects/modify-stat-effect.gd.uid
data/Resources/spell-effects/remove-status-effect.gd
data/Resources/spell-effects/remove-status-effect.gd.uid
data/Resources/spell-effects/spawn-entity-effect.gd
data/Resources/spell-effects/spawn-entity-effect.gd.uid
data/Resources/spell-effects/spell-effect-definition.gd
data/Resources/spell-effects/spell-effect-definition.gd.uid
data/Resources/spell-effects/teleport-effect.gd
data/Resources/spell-effects/teleport-effect.gd.uid
data/loot/enemy-drops/pohon-bark-sample.tres
data/loot/enemy-drops/test-loot1.tres
data/magis/examples/physics-force-v2.tres
data/magis/fields/physics.tres
data/magis/ilmiah/physics-field/core-subjects/physics-I.tres
data/magis/ilmiah/physics-field/core-subjects/physics-II.tres
data/magis/ilmiah/physics-field/physical-science.tres
data/magis/spell-manifest.gd
data/magis/spell-manifest.gd.uid
data/magis/spells/phys-collapse.tres
data/magis/spells/phys-crash.tres
data/magis/spells/phys-force.tres
data/magis/spells/phys-resonate.tres
data/magis/spells/phys-shatterwave.tres
data/magis/spells/phys-strike.tres
data/magis/spells/phys-terminal.tres
data/magis/spells/thermal-kinetic.tres
docs/README.md
docs/magis-pipeline.md
docs/spell-architecture-v2.md
docs/spell-authoring-guide.md
docs/spell-migration-guide.md
docs/spell-pipeline-v2-report.md
project.godot
scenes/spell-testing/spell-testing.gd
scenes/spell-testing/spell-testing.gd.uid
scenes/spell-testing/spell-testing.tscn
scenes/spell-tree/spell-tree.gd
scenes/spell-tree/subject-panel.gd
scenes/ui/mission-selection/story-selection.tscn
tests/spell-regression.gd
tests/spell-regression.gd.uid
tests/spell-regression.tscn
tools/bake-spell-manifest.gd
tools/bake-spell-manifest.gd.uid
tools/bake-world-manifest.gd
tools/validate-spells.gd
tools/validate-spells.gd.uid
```

## Incantation Chain Assistant delivery — 27 October 2026

Implemented on `feature/incantation-chain-assistant` from reviewed commit `4423abf`, preserving Quest, Enemy, and Magis V2. The assistant adds read-only equipped-trie prediction, correlated request lifecycle events, a local-player directional/continuation HUD, advisory mana/cooldown forecasts, successful-execution chain counts, and persistent Guided/Minimal/Off settings. Clearing input preserves accepted casts; explicit cast cancellation is configurable separately. Saving settings also preserves physical directional keybindings. No authored spell resource, incantation, effect, or stat changed.

The actual renderer demonstrates Strike → Resonate → Shatterwave producing Chain ×3, with independent 15/25/22 MP upfront payments through the existing pipeline. Queue acceptance is never labeled Cast!; later failures retain the original request identity. Prior pending chains remain distinguishable after new input or a resolver reset. Full multiplayer cast replication remains outside the existing safety boundary.

Final most-recent suite results total **1035 source assertions and 368 packed assertions, zero failures**. These totals count each suite once and exclude repeated runs and startup/export checks. Editor import, main-menu startup, Physics/Enemy/Quest arenas, PCK export, and real rendered previews also completed. Verification used installed Godot 4.7.2, matching the base project's declared 4.7 feature version; a separate 4.6 engine and browser export were not tested. Existing shutdown resource diagnostics and the world-ID warning remain.

See [complete lifecycle/API documentation, changed-file map, per-suite counts, commands, screenshots, and limitations](incantation-chain-assistant.md). Screenshots live in `docs/previews/incantation-assistant/`; the reproducible renderer scene is `scenes/spell-testing/incantation-chain-preview.tscn`.

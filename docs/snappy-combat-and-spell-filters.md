# Snappy casting, pushback and spell filters

Player casts skip post-dispatch recovery. Input reads each event instead of sampling one direction per frame, so multiple key presses within one physics frame remain ordered. Preparation and channel durations, mana payments, authorization, target checks and each spell's reuse cooldown still apply. Completing an incantation during another spell's preparation queues it (maximum eight); completing that preparation drains ready instant requests in the same tick. A queued request that fails validation is reported and does not block later requests. NPCs and bosses retain their authored recovery time.

Implementation: [player input](../components/characters/player/player.gd), [casting state machine](../components/spells/spell-casting-component.gd). `immediate_chaining` defaults false; Player opts in. No authored SpellData resources change.

## Player / monster collision

[PlayerEnemyCollision](../components/characters/player/player-enemy-collision.gd) installs mutual body exceptions between players and enemy-team CharacterBody2D actors. Player, Enemy and Boss invoke it on spawn, supporting either spawn order. Terrain collision, monster-to-monster collision, neutral actors, projectile layers and combat targeting stay intact. New monster implementations outside Enemy/Boss should invoke this helper after setting `spell_team` and registering their hitbox.

## E pushback

[PlayerPushback](../components/characters/player/player-pushback.gd) is a runtime Player child. Default settings are:

| Setting | Default | Behavior |
| --- | --- | --- |
| cooldown | 4 seconds | Starts only if an eligible enemy is pushed |
| radius | 400 world units | Distance to the enemy body, including scaled actors |
| force | 2200 | Scaled by the target's knockback resistance; 0.4-second shove |

The ability uses its own `pushback` action (default physical **E**) and can be remapped as Push Enemies in Settings independently from Interact. Nearby NPC, door, key and elevator interactions take priority when the pressed key also matches Interact. It requires combat mode, gameplay authority, a living player and no stun, dialogue, pause or phone menu. Movement locks block it except for the player’s intentional optional Stop Movement mode, which allows pushing while standing still. Silence does not prevent this physical ability. Enemy bodies must be alive, in range, visible through terrain layer 16 and accept knockback. Boss knockback immunity is respected. Coincident enemies use the player's aim direction. It deals no damage and spends no mana.

Push displacement uses the existing SpellMotionImpulse for 0.4 seconds so enemy controllers cannot overwrite it with ordinary movement velocity. For the shove’s lifetime, EnemyMovementComponent suspends horizontal chase/patrol intent so fast enemies cannot cancel the displacement; it resumes normal movement immediately afterward. Movement still collides with terrain and other monsters. The cooldown lives on the component, resets with the player, and cannot be dispelled or persisted as an effect.

[StatusEffectsHUD](../scenes/ui/status-effects/status-effects-hud.gd) independently anchors Push’s binding, Ready/countdown and refill bar at the bottom-left, and enlarged active buff/debuff icons to the right of the health/mana panel. It reads the actual component timer at the HUD's existing 10 Hz refresh rate. The ability stays visible during combat even with no status effects; normal modal/death visibility rules still apply. The training arena leaves space above its controls footer.

## Spells app filters

Both My Spells and the loadout screen expose the same [SpellCategoryFilter](../scenes/ui/spell-equipment/spell-category-filter.gd). All spells is the default. Filters are presentation state and do not alter learning, equipment, incantations or saved data. Equipped cards remain visible while filtering the available library.

| Filter | Matching content |
| --- | --- |
| Ranged | RANGED manifest, projectile or beam delivery |
| Melee | MELEE offensive direct-target spells with target range at most 200 |
| Buffs | BUFF category, ENHANCEMENT type, stat modifications or hit triggers |
| Support / healing | Supportive/healing/recovery type, healing/decast category, healing or replay effects; dispels on self or non-enemy-only deliveries |
| Defense | Defensive type, protective manifest or summoned constructs |
| Area | AOE type, burst, persistent area or trap |
| Control | Impairment type, control manifest, statuses, knockback, interruption, projectile fields or non-self vector effects |
| Movement | Movement type, teleports or self vector effects |

Categories can overlap. Effective delivery and typed effects cover older Physics spells whose classification fields remain at defaults. Nested conditional, trigger and spawn payloads are traversed with cycle and size guards. Consuming a status on an enemy for offensive damage does not count as support. An empty filter shows an explanatory state; the archive selects a visible matching spell or clears the details if none match.

## Verification (2026-10-28)

Godot 4.7.2, GL Compatibility. Run from the project root:

```bash
flatpak run org.godotengine.Godot --headless --path . tests/snappy-combat.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --path . tests/snappy-combat-preview.tscn -- --quest-test-mode
```

The focused suite covers rapid event sequences, same-tick queue completion, independent costs and reuse cooldowns, enemy recovery, both collision spawn orders, real body sweeps, terrain, neutral actors, production monsters/bosses, push displacement, immunity, cooldown expiry, NPC/door priority, HUD state and filters in both menus. Follow-up checks route a physical E event through the viewport while Stop Mode is active, exercise fast running chase AI during and after a shove, cast the existing Heat Engine spell and verify both active buff icons beside the health/mana panel. The repertoire leaves vertical space above active effects.

Actual renderer fixtures at 1280×720 and 1920×1080: [cooldown HUD](previews/snappy-combat/pushback-1280.png), [My Spells](previews/snappy-combat/spell-archives-menu-1280.png), [loadout](previews/snappy-combat/spell-equipment-1280.png). These are scripted visual checks; multiplayer sessions and human combat balance/playtesting were not performed.

The latest spell repair restores Harmonic Stabilization's intended 22 HP heal; the four healing assertions that previously failed now pass. The unrelated forest entrance scene edit is preserved. See [runtime spell repair and live audit](spell-runtime-repair.md).

| Check | Outcome |
| --- | --- |
| snappy-combat | 55 checks, 0 failures |
| player-combo-chains | 23 checks, 0 failures |
| incantation-assistant | 60 checks, 0 failures |
| spell-regression | 71 checks, 0 failures |
| spell-equipment-ui | 38 checks, 0 failures (640, 800, 1280 and 1662 widths) |
| boss-prototype | 70 checks, 0 failures |
| combat-feedback-save-v1 | Writer: 60 checks, 0 failures; separate reader: 20 checks, 0 failures |
| my-spells | 148 checks, 0 failures |
| enemy-pipeline | 138 checks, 0 failures |
| physics-curriculum | 272 checks, 0 failures |
| Documentation validator | 73 Markdown files, 1105 local link/path checks, 42 Resource classes, 409 exported properties, 0 errors |
| Executable documentation | 2 GDScript snippets and 2 Resource examples, 0 failures |
| Headless editor import | No script or parse errors |
| Rendered preview | 8 actual renderer captures at both target resolutions |
| Diff / preserved user edits | git diff --check passed; unrelated forest entrance edit passed SHA-256 comparison |

Existing engine UID fallback, ObjectDB/resource shutdown diagnostics remain. The save suite also logs missing-peer diagnostics after deliberately removing its test multiplayer peer; the unchanged-code baseline reproduces those diagnostics and still completes all 60 assertions. No script runtime errors occurred in the final feature/regression runs. There is no repository justfile / aggregate `just verify` target.

# Spell runtime repair and live audit

The runtime repair addresses real physics paths that the earlier payload-only tests could not cover. [Live audit scene](../tests/live-spell-audit.tscn) uses the production Player, training dummy, Bunga, a floor, actual keyboard input and automatic physics delivery. It never calls projectile hit handlers directly. All 42 registered spells receive an observed gameplay-outcome assertion, with prerequisite statuses and hostile projectiles staged for spells that require them. This complements the 272-check curriculum suite's schema, incantation and interaction coverage.

## Fixed runtime paths

- [TrainingDummy](../components/NPCs/enemies/dummy/dummy-npc.gd) now uses enemy layer 2, terrain mask 16, the shared HitboxComponent and explicit enemy-team identity. Damage, status effects, mana drain, physics targeting and Push work against it. It remains a reusable practice target that resets its health without granting kill rewards. Its existing Label displays actual HP. The dummy opts into structural and magnetic interactions.
- [SpellMotionImpulse](../components/spells/spell-motion-impulse.gd) slides the remaining motion along collision normals. Previously, a grounded shove with any downward component stopped against the floor, discarding horizontal displacement. Terrain walls still block motion.
- [HitboxComponent](../components/NPCs/enemies/hitbox-component.gd) now preserves spell knockback through an additive impulse. Enemy movement pauses its horizontal chase/patrol intent while either a spell impulse or Push owns movement, then resumes. Vector damping no longer adds a backwards displacement as a side effect of reducing velocity.
- [PlayerPushback](../components/characters/player/player-pushback.gd) uses 2200 force, 400 world units of body-based reach and a 0.4-second shove. Its separate E binding, four-second cooldown, interaction priority, resistance and immunity rules remain. A visible expanding pulse shows activation range; a valid attempt with no eligible enemy reports that instead of silently doing nothing.
- [Player casting](../components/characters/player/player.gd) uses automatic enemy locking with Q to switch targets; mouse aiming has been removed. See [current targeting behavior](auto-targeting-and-buff-hud.md). Casts originate at the player's body instead of 120 units ahead, so projectiles hit nearby enemies instead of spawning past them. Spells still obey learning/equipment, mana and their own reuse cooldowns.
- [Area and beam targeting](../components/spells/spell-delivery.gd) checks world-space body bounds, including scaled actors. Beams no longer require an enemy pivot to lie inside a thin line even when its body intersects that line. Ally/any-target area dispels can include their caster; SELF delivery still avoids double-applying to the caster.
- Physical Enemy actors opt into structural interactions; explicit structural/magnetic enemy tags are copied to capability metadata. The guardian supports structural interactions; the training dummy supports both. Magnetic enemies opt in through enemy_tags. Environment manipulation remains opt-in.
- [Harmonic Stabilization](../data/magis/spells/phys-harmonic-stabilization.tres) heals 22 HP again, with its authored status removal intact. This resolves the earlier four healing-test failures.
- Active buffs/debuffs are enlarged and positioned beside the health/mana panel on its right. The rest of the spell library and equipped-spell UI retain their existing behavior.

## Observe the right outcome

Damage spells should reduce HP. Control spells should change status or movement. Heat Engine changes mana regeneration and cast speed; Harmonic Stabilization heals. Impact Prism triggers after an actual damaging hit (a hit fully absorbed by defense does not trigger it). Resonance Threshold requires resonance and subsequent hits. Projectile fields and shields need hostile projectiles; cancellation only affects wave-tagged spells. Echo needs a previous eligible spell. Constructs create temporary defenses or platforms. These prerequisites are exercised explicitly in the live audit rather than treating every spell as a damage projectile.

The test uses actual collisions against the dummy for projectile delivery, body intersection for beams, status/movement changes for control and vector spells, real stat entries for buffs, projectile redirection/slowing/cancellation for fields, defensive interception for shields and timed constructs for barriers. It also checks a point-blank projectile against Bunga and a grounded physical-E shove.

```bash
flatpak run org.godotengine.Godot --headless --fixed-fps 120 --path . tests/live-spell-audit.tscn -- --quest-test-mode
```

The fixed frame rate accelerates simulated time in headless mode. Each case resets transient actors, costs and effects; no campaign saves are read or written. Human combat balance and network multiplayer playtesting remain outside this automated check. Updated HUD captures are linked from [casting and Push documentation](snappy-combat-and-spell-filters.md).

## Verification results (2026-10-28)

| Suite | Checks | Failures |
| --- | --- | --- |
| live-spell-audit (all 42 spells plus input / physics cases) | 46 | 0 |
| snappy-combat | 55 | 0 |
| physics-curriculum | 272 | 0 |
| my-spells | 148 | 0 |
| enemy-pipeline | 138 | 0 |
| spell-regression | 71 | 0 |
| player-combo-chains | 23 | 0 |
| incantation-assistant | 60 | 0 |
| spell-equipment-ui | 38 | 0 |
| boss-prototype | 70 | 0 |
| combat-feedback-save-v1 writer | 60 | 0 |
| combat-feedback-save-v1 separate reader | 20 | 0 |
| target-lock-and-hud | 37 | 0 |
| **Total** | **1038** | **0** |

Eight actual renderer captures cover the HUD and spell menus at 1280×720 and 1920×1080. The unrelated forest entrance edit retains its prior SHA-256 hash. Script runtime and parsing errors were checked independently of assertion results; engine resource/instance shutdown diagnostics remain. The save fixture retains its previously documented missing-peer diagnostic after it deliberately removes the test multiplayer peer. No network multiplayer session or human balance playtest was performed.

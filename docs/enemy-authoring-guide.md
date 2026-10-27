# Enemy authoring guide

## Create an enemy without another controller

1. Create an EnemyData `.tres` under `data/npc/enemies/definitions`. Give the type a unique enemy_id, display name and faction_id.
2. Create an EnemyStatsData subresource: positive max_health, desired mana pool/regeneration, move/chase speeds, defense, damage multipliers and resistance fractions. Resistances shorten status duration; 1 means immunity. Knockback resistance scales incoming impulse.
3. Create EnemyPerceptionData: range, memory, scan interval, candidate cap, target groups and faction relations. Existing player groups and combat_target hitbox registration work by default.
4. Assign an existing AI profile or author another EnemyAIProfile using typed EnemyAIAction entries. Profiles choose actions; abilities and movement execute them. Avoid modifying a shared profile during gameplay.
5. Add EnemyAbilityData entries. Spell abilities reference actual SpellData resources. Ordinary melee uses typed effects such as DamageEffect/KnockbackEffect with no fake spell. Set unique ability IDs, role, range band, LOS, windup, recovery, cooldown and selection weight.
6. Use `components/NPCs/enemies/Enemy.tscn` directly, assigning enemy_data; or create an inherited appearance scene. Preserve the base component node names. The coordinator creates the additional runtime components. An optional appearance-only visual_scene can add custom Node2D presentation; custom animation integration remains the author's responsibility.
7. Set loot, experience_reward, quest_enemy_id and bounded death_delay on EnemyData. Quest IDs must match objective target_id exactly.
8. Create SpawnData with enemy_scene and optional enemy_data override. Add it to an EnemySpawner pool. Set max_enemies, interval, area, placement collision mask and respawn policy. Place markers in enough open space for the full collision body.
9. Validate `EnemyData.validate()` and run the headless suites. Test physically reachable attack ranges and platform clearance in the arena; numeric ranges measure root-to-root distance.

## Working third-enemy example

`definitions/training-guardian.tres` already implements a third enemy using only resources and the base scene:

- 90 HP, no mana, move/chase speeds 90/150.
- Heavy guardian profile and a reusable 15-damage melee ability with 80-pixel reach.
- Standard perception and no rewards.
- `spawn/training-guardian.tres` assigns the base Enemy scene and that definition as an override.

Add that SpawnData resource to an existing spawner pool and run. No new GDScript controller is needed. The automated suite instantiates the definition through SpawnData and verifies identity/configuration. F5 in the arena creates the same guardian for manual testing.

To make a cautious caster, duplicate that definition, give it mana, assign cautious-spellcaster, and replace its loadout with configured spell abilities. A caster without healing in the loadout will never select healing. Recovery may instead wait for configured mana regeneration. To support an ally, use a spell with ALLIES targeting and HEAL role; the controller chooses an injured compatible actor within range. SELF delivery always selects the caster.

## Add an ability

Create EnemyAbilityData. For spells, use Kind.SPELL and select OFFENSE, DEFENSE, HEAL or SUMMON role. The shared SpellValidator checks the payload. Enemy authorization permits only spells referenced by the configured loadout; the entire player library is never implicitly granted. Spell cooldown and the ability's own cooldown both apply. Full upfront plus configured channel mana must be available at selection. Preparation rechecks shared casting rules; melee rechecks target/range/LOS at release.

For melee, select Kind.MELEE and assign effects. CombatRequest provides source attribution and the same executor/hitbox mitigation as magical damage. Configure windup and recovery to make hits readable. Existing Bunga melee and guardian melee are examples.

All projectile, self, target, burst, persistent-area, beam, trap and construct deliveries are supported by the shared service; the enemy suite casts all 42 Physics definitions through explicit enemy abilities. Scientific/resource descriptions remain authored by their own field systems.

## Test arena

Run `res://scenes/tests/enemy-pipeline-test.tscn`. It spawns the production player, Pohon and Bunga, a floor, platforms and an occluding wall. Overhead labels show health, mana, state, intent, target and cooldowns.

- F1/F2 add Pohon/Bunga near the player; the arena caps enemies at eight.
- F3 clears enemies without kill rewards; F4 refills player health/mana.
- F5 adds the resource-only guardian; F6 applies stun; F7 defeats enemies through the hitbox.
- O enters casting/confirmation; I/J/K/L input directions; P interrupts.

Use player movement to cross LOS, approach/retreat and test patrol edges. The arena grants Force, Kinetic Chill and Resonate for this runtime session. Activate an existing relevant quest before using F7 to inspect quest HUD behavior; automated tests also create an isolated quest and assert one update per death.

## Checks

```sh
python3 tools/test-enemies.py --godot /path/to/godot
```

This checks static enemy references, imports the editor, runs all existing spell/UI suites, runs the enemy suite and starts the arena for 300 headless frames. See the migration report for exact executed results and limitations. A GUI playthrough and tuning remain necessary before release.

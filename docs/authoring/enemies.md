# Enemy definitions

## Purpose, source and examples

Enemy V2 uses one reusable [Enemy.tscn](../../components/NPCs/enemies/Enemy.tscn) shell and [EnemyData](../../data/npc/enemies/enemy-data.gd). Definitions live under data/npc/enemies/definitions/; stats, perception, profiles, abilities and loot are referenced Resources. Examples: [Pohon](../../data/npc/enemies/definitions/pohon.tres), [Bunga](../../data/npc/enemies/definitions/bunga.tres), [Training Guardian](../../data/npc/enemies/definitions/training-guardian.tres) and [guardian spawn entry](../../data/npc/enemies/spawn/training-guardian.tres). Inspect current explicit values **and schema defaults**: an omitted stat is not the number stated by an old report.

## Editor walkthrough: new enemy without a new controller

1. Right-click data/npc/enemies/definitions/ → New Resource → EnemyData; save a new file, for example study-sentinel.tres. Set explicit enemy_id `study_sentinel`, enemy_name, description and faction_id `enemy`. Set quest_enemy_id to the same ID if it should publish kill credit under that identity.
2. In stats choose New EnemyStatsData (or assign an intentionally shared preset). Positive max_health is required. Configure max_mana, health_regen/mana_regen/regen_delay, move_speed/chase_speed, defense, incoming/outgoing multipliers, knockback_resistance 0–1 and per-status resistance fractions. A caster needs enough mana; setting a spell in a loadout does not supply it.
3. In perception choose New EnemyPerceptionData. Set detection_range > 0 up to 10000, scan_interval ≥ .05, sight_memory, max_candidates 1–64, terrain_mask and target_groups. Defaults include player and combat_target; faction relations use -1 hostile, 0 neutral, 1 allied, with same faction allied.
4. Assign EnemyAIProfile from ai-profiles/, or create one with [the AI guide](enemy-ai.md). Profiles hold actions and movement preference, not actor HP or cooldowns.
5. Expand abilities and add actual EnemyAbilityData Resources. For melee use Kind.MELEE plus typed DamageEffect/KnockbackEffect; for casting use Kind.SPELL plus SpellData. See [abilities](enemy-abilities.md). Set role/range/LOS and readable windup/recovery. Pure melee, ranged, mixed, defensive and healing builds use different combinations of these same Resources/actions.
6. Configure cooldown_multiplier (>0), death_delay (0–30), nonnegative experience_reward, enemy_tags and LootData array. Loot item identities must be registered/reachable for quests and saves. enemy_category is authored classification metadata, not a different controller selection.
7. Open Enemy.tscn → Scene → New Inherited Scene, save under a new content folder. Select its root and assign enemy_data. Preserve required component names, HitboxComponent, body collision and ground sensors. Change sprite frames/animation setup for appearance; an optional EnemyData.visual_scene adds an appearance-only Node2D and does not replace the controller or automatically adapt custom animations. Test collider/ground probe placement for the new dimensions.
8. Add a preload of study-sentinel.tres to EnemyManifest.ENEMIES. This is a small registry script edit, not a new controller. Direct scene references can run before registration, but quest enemy-target validation reads the manifest, so register ordinary release content.
9. Create SpawnData: enemy_scene = the inherited scene, optional enemy_data override = study-sentinel.tres, spawn_weight > 0. The override is applied before _ready; leave it empty to preserve the inherited scene's definition. Add to EnemySpawner.spawn_pool under a Node2D parent in a world/arena (for example World/GameComponents/Enemies); the spawner uses its parent transform/to_local. Set max_enemies, interval, respawn policy, placement attempts and blocking mask. Place the marker in open space for the full body.
10. Call EnemyData.validate(), run enemy-pipeline and the static/resource runner, then play the [enemy arena](../../scenes/tests/enemy-pipeline-test.tscn) with a placed temporary spawner/instance. Verify detection through/around walls, melee reach, spell costs, interruption, death exactly once, XP and physical loot. Export and repeat; remove experimental instances before committing unless intentional content.

## Composition recipes

| Goal | Definition/configuration |
| --- | --- |
| Melee only | One or more MELEE abilities, MELEE action, movement range reachable by root-to-root distance; no mana needed |
| Ranged | SPELL projectile/beam ability, RANGED or CAST action, mana, maintain-range/retreat actions |
| Defensive | DEFENSE-role SELF/ally spell and DEFEND action; no ability means defend is ineligible |
| Support | HEAL-role spell and RECOVER action; SELF targets caster, ALLIES chooses an injured same-team actor in range |
| Mixed | Both melee and spell abilities plus matching actions; utility and cooldowns choose the usable action |

EnemyCombat authorizes spells only from the configured loadout; adding a spell to the player catalogue does not grant it to every enemy. Defense, regen and damage multipliers have their actual consumers in EnemyStatsComponent/Hitbox. A status buff may be stored on any hitbox but actor-specific stat semantics still need a consumer.

## Registration, export and troubleshooting

EnemyData.validate checks required stats/perception/profile, their constraints, ability IDs and definitions. It does not substitute for testing physical reach, visuals, loot registry collisions or actual navigation. EnemyManifest feeds QuestRegistry enemy IDs and drop-item discovery; no enemy bake tool or automatic directory scan exists. Nested definitions and appearances are retained by preload/scene references.

An enemy that never attacks often lacks a compatible action/loadout, enough mana, LOS, an in-band target or reachable melee range. A missing quest kill often uses a quest_enemy_id different from the registered enemy_id/objective target. Local reposition/wall jumping is not general route planning; flight/navigation requires a real extension. See [troubleshooting](../reference/troubleshooting.md) and the [property reference](../reference/resource-reference.md#enemydata).

Completion: explicit stable identity; shared Resources understood; stats/perception/profile/abilities valid; scene/manifest/spawner linked; physical damage/death/loot tested; quest credit and PCK resources checked; temporary enemy state correctly excluded from campaign saves.

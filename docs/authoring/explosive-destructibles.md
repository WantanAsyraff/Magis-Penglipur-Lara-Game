# Explosive destructibles

Explosions are consequences in the same lifecycle as ordinary crates. Compose AreaExplosionBehavior, ShrapnelBehavior, PersistentHazardBehavior, SpawnActorBehavior, LootDropBehavior, SpawnSceneBehavior and SignalEventBehavior in any configured order. The root does not switch to a special barrel controller.

## How to Create a New Explosive Barrel in Under Five Minutes

1. Drag `components/environment/destruction/presets/explosive-barrel.tscn` into a level with a floor. Save an inherited scene such as `red-magis-barrel.tscn`.
2. Select the root's **Config → Make Unique**. Set display name and max health. Keep the existing intact/damaged/critical/destroyed state Resources or make each unique to replace textures and animation names.
3. In **Material**, assign the supplied wood/metal/magical-construct Resource or make a private copy and tune damage multipliers.
4. Expand **Behaviors → AreaExplosionBehavior**. Make it unique before editing shared settings. Set radius 210, base damage 45 and knockback 400. Optionally assign a Curve whose X coordinate is normalized radius and Y is damage/impulse multiplier; sampled values clamp to 0–1. The default is linear from full damage at the center to 25% at the edge.
5. Expand its **Targets** Resource. Choose player/enemy/environment effects, friendly fire and terrain LOS. Enable chain reaction to affect other destructibles. `chain_reaction_multiplier` only scales environmental damage.
6. For a fuse, set the explosion behavior's inherited **Delay Seconds** (for example .6). Set `destruction_seconds` to the desired visual window. Removal waits for delayed behaviors, even if the visual breakup finishes first.
7. To add fragments, increase the behavior array and choose **New ShrapnelBehavior**. Start with 12 radial fragments, speed 450, lifetime 1.5 and damage 8. Native fragments work without any texture. A custom projectile scene must extend DestructionShrapnel.
8. To add a cloud, append **New PersistentHazardBehavior**. Radius 180, duration 6, interval .5 and damage 2 reproduce the supplied poison field. Leave status empty for this poison recipe. A slow cloud can instead use an ApplyStatusEffect with status `slow`, magnitude .4, duration 1 and REFRESH, with damage set to zero. A visual-only cloud has neither damage nor status.
9. Turn on `remove_after_destroy` if no rubble should remain. Keep persistence off for a reusable prefab; on a permanent placed barrel, make Config unique and supply its globally unique ID.
10. Save, run and use R to select it, O and the equipped incantation to cast. Verify actual health/state changes, collision removal, explosion radius, friendly-fire choice and cleanup. No implementation script edits are needed.

## Combinations

| Recipe | Ordered list |
|---|---|
| Basic barrel | AreaExplosion |
| Fragmentation barrel | AreaExplosion, Shrapnel |
| Toxic barrel | AreaExplosion, PersistentHazard |
| Infested pod | SpawnActor, SpawnScene |
| Magis reactor | AreaExplosion, Shrapnel, PersistentHazard, SpawnActor |

For a pod, assign an existing Enemy V2 inherited scene to SpawnActorBehavior. An optional EnemyData override is installed before `_ready`. Existing AI, abilities, hitbox, death/loot observers and XP remain intact. Faction inheritance uses a private definition copy, not a mutation to the shared enemy Resource. Default minion-pod uses three normal Bunga enemies, with directional offsets and a .45-second delay. Marker paths are relative to the pod and must point to Node2D markers. Safe placement can move a blocked point upward a bounded number of times; if it remains blocked, the actor is skipped. Do not rely on it to find paths across a level.

## Troubleshooting

- **A spell passes through:** keep the named EnvironmentalTarget and HitboxComponent; keep a real enabled body collider on layer 16; ensure the spell is allowed to affect neutral props. R selects props; Q remains hostile selection.
- **No damage from an explosion:** check target policy/faction/LOS, distance to the target bounds, invulnerability, material multiplier, authority and chain enable. A solid intervening wall blocks damage by default.
- **Resistance seems wrong:** classification comes from `SpellData.environmental_damage_kind`, never from its name. Existing spells default to impact until explicitly authored otherwise.
- **Nothing spawns:** inspect `validate()`, scene root type, blocked placement, active actor cap and shared event/world budgets. Invalid optional scenes log a warning and the destruction still completes.
- **Cloud stacks too much:** use REFRESH or IGNORE, never STACK. Read the shared-key policy in the behavior guide. Unsupported status names are rejected.
- **Missing art stalls:** it should not. Check `destruction_seconds` and pending behavior delays; animation completion itself is not a gameplay prerequisite.
- **A permanent barrel explodes after loading:** verify stable unique IDs and use the component's restoration path. Never connect a generic ready signal to `destroy()`.
- **Missing uncollected loot after reloading:** destruction loot is explicitly transient. A persistent object never replays drops; use existing durable quest/inventory rewards for essential items.
- **Chain stops:** default depth 8 or the shared destruction/spawn budget was reached. This is intentional bounded propagation. Avoid increasing budgets to compensate for very dense explosive layouts.

Run `python3 tools/test-destruction.py --flatpak --packed --regressions` on the installed Flatpak engine, or use `--godot /path/to/godot` for a native executable. Render evidence with `godot --path . tests/environment-destruction/preview.tscn -- --quest-test-mode`. The authoring playground is `scenes/spell-testing/destruction-lab.tscn`.

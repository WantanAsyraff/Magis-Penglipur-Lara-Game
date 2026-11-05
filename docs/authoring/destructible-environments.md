# Destructible environments V1

Use Godot **4.7** with the project's **GL Compatibility** renderer. The shared framework lives in `components/environment/destruction/`. All eight presets use the same scripts; their differences are Resources and visual settings. Existing `magis-breakable.tscn` and floating crates remain supported unchanged. V1 adds bounded props, not TileMap/pixel destruction or structural simulation.

## Create an object in the Inspector

1. Drag `presets/wooden-crate.tscn` (or another preset) into your level. Save an inherited scene to make a reusable variation.
2. On the root, expand **Config** and **Make Unique** before changing a shared preset. Save it as a `DestructibleConfig` `.tres` if several instances should deliberately share the design.
3. Set identity, display name, durability and initial health settings. `enabled=false` rejects interaction; `invulnerable=true` rejects damage and scripted destruction.
4. Assign a `DestructibleMaterialDefinition`; make it unique before changing multipliers. Presets exist for wood, glass, stone, metal, organic and magical constructs.
5. In **States**, create any number of `DestructibleStateDefinition` Resources. Include a threshold of **1.0**. IDs and thresholds must be unique. The lowest threshold **greater than or equal to** the remaining health ratio wins. For example: intact 1.0, damaged .75, critical .40, destroyed 0.0. Two states (1 and 0) are also valid; leaving the list empty uses native fallback visuals.
6. Give each state a texture or SpriteFrames, animation name, tint, visual offset/scale, collision and interaction permissions. A state can turn collision off while retaining a trigger/visual. Resize the root's **SolidCollision** separately from artwork. Optional Area2D sensors may be added; the component only toggles physics-body CollisionShape2D nodes.
7. Configure the visual controller under **VisualRoot**. Its fallback texture/frames and native placeholder size/color/shape are independent of gameplay. Native placeholders deliberately show cracks, a six-piece breakup and rubble. They are functional, replaceable prototypes.
8. Add typed destruction behaviors to **Config → Behaviors** in the desired order. An ordinary crate need not expose explosion or hazard settings.
9. For permanent objects, turn on persistence and assign a **globally unique per-placement persistence_id**. Do not reuse a preset's ID across placements. Leave reusable presets transient.
10. Run `scenes/spell-testing/destruction-lab.tscn`, select a prop with R and cast real equipped spells. F6 casts the real Force spell; F7 rebuilds stations; F8 restores health/mana; F9 changes overview; F10 returns to the Physics laboratory. The Physics lab also opens this playground with F9. Labels and shortcuts only exist when `debug_mode` is enabled.

`Config.validate()` reports invalid durability, thresholds, IDs, materials and behavior configurations. The root exposes editor configuration warnings. Bad optional behaviors are logged and skipped without preventing the object from reaching its final state. Missing art falls back instead of blocking completion. Inspector ranges have runtime validation too.

## Scene composition

```text
DestructibleObject (StaticBody2D, terrain layer 16)
├── SolidCollision (CollisionShape2D)
├── VisualRoot (DestructibleVisualController)
│   ├── Sprite2D
│   ├── AnimatedSprite2D
│   ├── AnimationPlayer
│   └── AudioStreamPlayer2D
├── HitboxComponent (DestructibleHitbox)
├── EnvironmentalTarget
├── InteractionReceiver (DestructibleInteractionReceiver)
└── DestructibleComponent

DestructionRuntime (world-owned sibling, created when needed)
├── explosions / shrapnel / hazards
├── temporary replacement scenes
├── normal Enemy V2 actors
└── normal DroppedItem instances
```

Keep the integration child names. The root may be renamed freely unless it is referenced by another authored NodePath. The runtime uses the enclosing Node2D scope and shares limits across nested Node2D containers. All spawned nodes disappear when that scope unloads.

## Durability and state lifecycle

`DestructibleComponent` owns all mutable health, state, generation, completion and effect-execution data. Shared Resources contain definitions only. Damage is finite, nonnegative, multiplied by the authored material response and object multiplier, then clamped to remaining durability. Hitbox defense/invincibility continues to apply when damage enters through a hitbox. Repairs clamp to max health and reverse thresholds; repairing a destroyed object is rejected. An explicit reset is required to resurrect it.

On lethal damage the object becomes ineligible immediately, records its persistent state, emits destruction signals once and schedules behaviors. Further same-frame hits do nothing. Behavior execution and the bounded visual interval must both finish before completion. `remove_after_destroy` waits for this completion. With `destroy_on_zero_health=false`, reaching zero does not start consequences; a script can call `destroy()` later. Native broken visuals and optional hooks do not decide whether an explosion deals damage.

Public component methods:

| Method | Result |
|---|---|
| `apply_damage(amount, EnvironmentalDamage=null)` | bool; validated typed damage, material multipliers |
| `repair(amount)` | bool; living-object repair, clamped |
| `set_health(value)` | bool; exact clamped durability, bypasses material multiplication, respects eligibility |
| `destroy(EnvironmentalDamage=null)` | bool; same lifecycle as lethal damage |
| `reset_destructible(write_persistence=true)` | bool; new generation, cancels stale queued work |
| `can_receive_damage()` | bool; authority/enable/invulnerability/state gate |
| `get_health_ratio()` | float 0–1 |
| `get_current_state()` | state Resource or null |
| `is_destroyed()` | bool |

Signals: `damage_received(amount, damage)`, `health_changed(current, maximum)`, `state_changed(previous, current)`, `destruction_started(context)`, `destroyed(context)`, `destruction_completed(context)`, `repaired(amount)`, `authored_event(event_id, context)`. Restoration does not emit a new destruction or execute consequences. Scripted destruction is subject to the same enable, authority and invulnerability rules.

## Art and reusable animations

The provided `effects/destruction-animations.tres` AnimationLibrary has optional `idle`, `hit`, `damaged`, `critical`, `destroy_start`, `destroy_loop`, `destroy_end`, `destroyed`, `repair`, `reset` hooks. Duplicate it before editing shared tracks. Existing Sprite2D/AnimatedSprite2D children are actual Inspector nodes; their state texture/frames are assigned from Resources at runtime. Add custom AnimationPlayer tracks to those visual children, not to health/collision/gameplay state. The controller's exported hook map redirects names.

Playback precedence is a matching AnimationPlayer animation, then a matching SpriteFrames animation; fallback prefers animated idle, then AnimationPlayer idle. Repeated hits restart the hit hook. Missing animations never prevent gameplay or completion: `destruction_seconds` is the bounded visual window (.05–10 s). The end hook gets a .25 s presentation window before the stable destroyed hook. A remove-after-destroy prop may be freed before this decorative end window; keep it in the world if that final animation should remain visible.

State transition sound/particles only play when state changes. Material hit/break audio and particles are separate optional feedback. CPU particles or compatible GPU particles may be assigned; native effects use drawing compatible with GL Compatibility. Feedback instances expire after four seconds, with a per-visual child cap. Use non-looping particles, local coordinates as appropriate, and practical counts. Missing textures use native geometry.

## Spell and combat integration

The executor requires recognized effect targets; merely declaring `take_damage` was not used as a new integration shortcut. A named `DestructibleHitbox` extends the existing HitboxComponent; EnvironmentalTarget opts the neutral prop into real projectile, direct, beam and area selection. Props leave the hostile combat-target group, so Q remains the hostile selector and R selects neutral devices.

DamageEffect now calls the virtual `HitboxComponent.receive_spell_damage(amount, context)`. Its default implementation calls the original receive_damage with the same source. The destructible adapter preserves the explicit `SpellData.environmental_damage_kind` (impact/thermal/electrical/pressure/sonic). Existing spells default to impact. No spell-name matching or catalogue stat edits are used. Environmental scripted damage uses `EnvironmentalDamage` directly. A material's optional minimum break force converts successful authored Knockback/Vector effects into pressure damage above that threshold; zero disables this reaction. Static props do not acquire simulated rigid-body motion.

Player/enemy hitboxes, faction relations, enemy death/XP/loot and ordinary quest events are reused. Destructible destruction never impersonates an enemy death. SignalEventBehavior can publish a real world flag or address a typed receiver/actuator. Hazards use existing status handlers, with no separate poison stack implementation. Single-player/server authority gates damage, restoration writes and scheduled effects; clients cannot simulate authoritative destruction. Network replication/RPC presentation is outside V1.

## Persistence and reload policy

Save V1's Boolean-only `QuestManager.world_flags` is the authoritative store, through its existing `set_world_flag` API. Keys are `destructible:v1:<persistence_id>:present`, `:dead` and 24 `:hp:<bit>` flags. Health is encoded to **0.01 HP precision**, bounded by 100000 HP. This consumes at most 26 flags per persistent placement and needs no save schema migration. Existing save limits still apply. An old save with no keys starts from the configured defaults. State visuals are derived from restored health; a destroyed restore disables configured collision and never replays explosions, events, spawns or loot.

Duplicate IDs in a runtime scope warn and disable persistence on the duplicate. IDs must also be unique across different campaign scenes; do not rename a shipped ID without migrating its flags. `persist_health=false` restores living props to maximum health but retains destruction. `respawn_on_scene_reload=true` bypasses persistence. The explicit reset API can overwrite a saved destroyed state, so reserve it for intentional reset mechanics.

Hazards, fragments, minions, replacements **and uncollected destruction drops are transient**. They are not serialized and are not reconstructed on load. A permanently broken crate will not generate its uncollected loot again. Use ordinary quest rewards/inventory escrow for progression-critical items that must survive scene departure. Save V1 records destruction immediately; it does not promise transactional replay of pending fuse behaviors after saving/unloading.

## Presets

| Scene under `presets/` | Durability | Material | Consequences |
|---|---:|---|---|
| wooden-crate | 20 | Wood | Physical registered Flower loot, authored chance |
| glass-barrier | 8 | Glass | Shattering native breakup |
| stone-block | 150 | Stone | Resistant stateful obstacle |
| fragile-platform | 12 | Wood | One-way solid surface disappears safely |
| explosive-barrel | 15 | Metal | Radial pressure damage |
| poison-canister | 10 | Metal | Explosion + six-second damaging field |
| fragmentation-container | 18 | Metal | Explosion + twelve physical fragments |
| minion-pod | 30 | Organic | Three existing Bunga Enemy V2 actors after .45 s |

Platforms remove collision using deferred changes, preserving the existing physics layers. Authors must provide an exit or landing below collapsible platforms; V1 does not rearrange navigation or rescue actors from authored pits.

See [behavior contracts](destruction-behaviors.md), [explosive recipes](explosive-destructibles.md) and [verification/handover](../verification/environment-destruction/report.md).

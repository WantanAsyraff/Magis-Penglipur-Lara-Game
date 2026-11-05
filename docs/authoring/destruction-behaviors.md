# Destruction behavior authoring and extension

Add typed `DestructionBehavior` Resources to a DestructibleConfig. Behavior arrays execute in Inspector order. Each enabled behavior's `delay_seconds` is a **delay before that behavior** and also delays later entries. The scheduler admits at most 32 behavior executions per physics frame. Starting a hazard/actor/projectile is synchronous; its subsequent lifetime does not block the next entry. Put a delay on the next behavior when deliberate staggering is needed. Up to sixteen behaviors are accepted per object. Invalid optional entries warn and skip.

| Resource | Exported configuration and execution |
|---|---|
| AreaExplosionBehavior | radius, damage, falloff Curve, knockback, typed damage kind, target policy, chain enable/multiplier, particles/audio/color, optional player flash |
| ShrapnelBehavior | optional custom DestructionShrapnel scene, count/speed/lifetime/damage, radial/cone/upward/random distribution, direction/spread/seed, piercing and pierce count, gravity, texture, impact particles |
| PersistentHazardBehavior | optional custom DestructionHazard scene, radius/duration/tick interval, damage and kind, supported ApplyStatusEffect Resource, reentry policy, fade/particles/audio/color |
| SpawnActorBehavior | actor PackedScene, optional EnemyData override, count/radius, origin/random/radial/markers/directional patterns, faction inheritance/override, active cap, lifetime and placement attempts |
| LootDropBehavior | typed LootData array, scatter, pickup delay, lifetime; extra drop entries supported with bounded count |
| SpawnSceneBehavior | PackedScene, offset, rotation, visual scale, manager/source-parent policy, lifetime |
| SignalEventBehavior | event ID and signal, world flag, or explicit typed actuator/receiver NodePath action |

All derive `enabled` and `delay_seconds`. Limits are validated at execution as well as exposed in the Inspector. Do not mutate these Resources during gameplay to store cooldowns, hit lists or results. Spawned effect Nodes hold their own age, affected-actor set, collision exclusions and detonation flags.

## Targets and attribution

`DestructionTargetPolicy` is shared configuration with affects_player, affects_enemies, affects_environment, friendly_fire and require_line_of_sight. Destructibles have a separate environmental opt-in; actors use CombatFactions relationships. Without friendly fire, a player-instigated explosion does not hit player allies. Neutral scripted explosions may affect both opted-in sides. LOS uses terrain layer 16 and excludes source and target body RIDs. Radius checks use real target body bounds, not just pivots. At most 128 eligible targets are processed per area application.

Damage to players/enemies uses the real hitbox and normal defense/invulnerability handling. Kill credit follows the original destroying actor and is snapshotted for effects that outlive that actor. Environment damage carries the same chain context to the next object. Physical shrapnel uses swept segment queries against layers 1/2/16, ignores its source, deduplicates targets and bounds piercing. Ineligible solid terrain stops fragments. Spawn placement checks the prefab's real body collision against those layers and tries bounded upward alternatives, otherwise skips the spawn. This is safe local placement, not a navigation-reachability solver.

## Persistent fields and statuses

The poison preset uses direct periodic damage, so damage credit follows its instigator. It does not advertise an unimplemented poison handler. Optional statuses use ApplyStatusEffect configuration through the existing Hitbox/ActiveEffectManager, with a non-STACK policy and one stack. Supported authored keys are restricted in `PersistentHazardBehavior.SUPPORTED` to existing movement/combat/conditional handlers. Unknown status keys and STACK configurations fail validation. Refresh-while-inside updates a single effect; once-per-actor applies status only on the first successful application, including on reentry. Damage-per-tick is independent and continues while inside. Different clouds use the existing shared-key refresh semantics, not unlimited independent copies. Status duration can extend beyond leaving the cloud and then expires normally. No damage ticks occur at or beyond the cloud's end; the trailing fade is visual only. Visual-only fields use damage 0 and no status.

## Scripted story actions

For a custom story event choose SIGNAL_ONLY and connect the component's `authored_event(event_id, context)` signal in Godot. WORLD_FLAG calls the existing QuestManager API. ACTUATOR_ENABLE addresses an InteractionActuator (for example `../Gate/Actuator`) and passes ENABLE; RECEIVER_SIGNAL addresses an InteractionReceiver and sends its typed SIGNAL event. Paths are relative to the source root, evaluated when the behavior executes. These are a closed set of typed actions; saved data never selects arbitrary method names or scripts. Ordinary authored signal connections can start reviewed cutscenes.

Loot creates normal DroppedItem scenes. Drop chance/quantities come from LootData; scatter and pickup delay are configured separately. Pickup invokes Inventory_Manager with the original acquisition receipt path. No ITEM_COLLECTED event is emitted on spawning. Loot is bounded by the same event/world spawn caps and expires; see the explicit reload policy in the core guide.

## Safety and ownership

A chain shares a DestructionBudget: **32 consequence-bearing destructions, depth 8, 128 spawned nodes**. An over-budget object can become visibly broken but runs no consequences. The runtime also caps 64 queued jobs, 256 active spawned nodes, 32 behavior executions/frame, 48 fragments/behavior, 8 fragment pierces, 16 actors/behavior and 32 active destruction actors. Each actor behavior may choose a smaller active cap. Spawned-node lifetimes are at most 300 seconds, fragments at most 10 seconds and hazards at most 60 seconds plus bounded fade. All effects belong to their world scope; scene departure cancels pending jobs and deletes transients.

Every destruction has a unique event identity and source generation. Multiple lethal hits cannot enqueue twice. Reset invalidates the prior generation's pending work; already-launched effects finish under their original budget. Source removal cancels not-yet-started delayed work. A behavior may spawn another destructible: the replacement inherits the parent context, so its later destruction cannot start a fresh unlimited chain. Scheduler processing prevents nested same-stack explosions. Resources are trusted authored code; V1 does not sandbox a malicious custom subclass or recover from arbitrary GDScript runtime errors.

## Custom behavior contract

```gdscript
class_name MyDestructionBehavior extends DestructionBehavior
@export var replacement: PackedScene

func validate() -> PackedStringArray:
    var errors := super.validate()
    if replacement == null:
        errors.append("Assign the replacement scene")
    return errors

func execute(context: DestructionContext) -> void:
    if not context.valid():
        return
    var node := replacement.instantiate()
    if not node is Node2D:
        node.free()
        return
    context.runtime.spawn_node(node, context, context.position, 5.0)
```

`execute(context) -> void` launches bounded work; it must not await a free-standing timer. Use the scheduler's delay property or a world-owned Node with a lifetime. Use `runtime.spawn_node` for all nodes so caps and cleanup apply. Deliberately spawned destructibles should receive `destruction_parent_context` before entering the tree, as SpawnSceneBehavior does.

Context snapshots: weak source reference (`source_object()`), source ID/generation, instigator, snapshotted credit owner/faction, world position, typed damage context/material, unique event ID, spell reference, shared budget/depth, deterministic per-event RNG, runtime and authority. Treat fields as read-only except consuming the budget through its methods. `valid()` checks the live world and server authority; `effects_valid()` additionally checks the live destroyed source generation for queued work. Definitions and per-event contexts must never be used as global mutable state.

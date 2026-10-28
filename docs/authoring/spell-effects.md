# Typed spell effects

## Base contract and editor authoring

[SpellEffectDefinition](../../data/Resources/spell-effects/spell-effect-definition.gd) is a Resource with `validate()`, `accepts(target)` and `execute(context,target)`. Its default accepts requires a child named HitboxComponent; overriding classes can support other targets. The default execute returns false: creating the base Resource alone does not create gameplay.

Create reusable effect `.tres` files under data/Resources/spell-effects/ in a dedicated content subfolder if needed, or create typed inline subresources in SpellData.effects. The existing folder primarily holds class scripts; authored spell payloads are usually inline in Physics spell Resources. Right-click → New Resource → exact subclass, configure the fields below, save if reused, then drag it into effects. Child-effect arrays use the same New Resource/drag procedure. No independent effect manifest exists: the parent spell/ability retains dependencies in export.

## Every implemented subclass

All subclass source files are under [data/Resources/spell-effects](../../data/Resources/spell-effects/). Defaults and exact exported types/hints are in the [property reference](../reference/resource-reference.md#spelleffectdefinition).

| Class / source | Required properties, validation and execution | Compatible targets / caveats |
| --- | --- | --- |
| DamageEffect / damage-effect.gd | amount finite ≥ 0; applies context scale/damage multiplier plus flat damage bonus and feedback | Hitbox or target.take_damage; mitigation occurs at hitbox; projectile/direct/area/melee |
| HealEffect / heal-effect.gd | amount ≥ 0; duration ≥ 0; tick_interval ≥ .05. duration 0 emits immediate heal; otherwise beneficial hot entries stack up to 32 | Hitbox with healed consumer; SELF/allied target/area. amount is per tick, not total duration healing |
| KnockbackEffect / knockback-effect.gd | force finite ≥ 0; uses context.direction and hitbox resistance | Hitbox attached to CharacterBody2D for motion; receives_knockback gates it |
| ApplyStatusEffect / apply-status-effect.gd | Nonempty status, duration > 0, magnitude ≥ 0, tick_interval ≥ .05, max_stacks 1–32 and stack policy | Hitbox receives_status_effects/authority/invincibility/resistance; mana_drain also requires has_mana. Known status handlers only |
| RemoveStatusEffect / remove-status-effect.gd | Optional named status removes that key; remove_buffs/remove_debuffs classify clears; respect_teams gates category clears | Named removal is unconditional with respect to team; no custom validate override |
| ModifyStatEffect / modify-stat-effect.gd | stat one of speed, damage, mana_regen, defense, cast_speed, dash_charges; finite amount; duration > 0, stacks 1–32 | Stores beneficial buff_stat entry. Actor must consume that stat; not every actor implements every stat. on_hit_proc_id is stored, no proc dispatcher |
| TeleportEffect / teleport-effect.gd | distance finite ≥ 0; destination = target position + cast direction × distance | Default Hitbox acceptance; PhysicsBody2D.test_move conservatively rejects blocked path. No pathfinding or teleport-through-walls promise |
| SpawnEntityEffect / spawn-entity-effect.gd | scene non-null and finite offset; optional children | Any valid Node2D target; spawned scene must be Node2D, placed at target + offset, lifecycle-owned. initialize_spell(context) optional; child acceptance still applies |
| ConditionalEffect / conditional-effect.gd | required_status, minimum_stacks, optional capability metadata key, children; consume removes the matching key before executing children | Hitbox; counts actual entries, capability checks metadata presence, consume removes all matching stacks. Inherits empty validation: author sensible positive stack counts and validate nested children |
| ChainEffect / chain-effect.gd | radius finite > 0, hops 1–8, amount finite ≥ 0; preferred_status biases score | Hitbox targets through normal targeting, nearest unvisited eligible candidates, .75 damage factor per hop. Not legacy tether/equilibrium fields |
| InterruptEffect / interrupt-effect.gd | No exported fields; cancels child SpellCastingComponent instances | Default Hitbox targets. Does not create a general cancellation API for arbitrary unrelated actor logic |
| TriggerEffect / trigger-effect.gd | duration finite (0,30], hits 1–6 and children | Default Hitbox; creates one owned SpellHitTrigger per spell ID on actor, runs children on damage events with count/time limits |
| ReplayEffect / replay-effect.gd | No exported fields; uses target's previous eligible completed spell/targets | Default Hitbox; half scale, separate budget 64, echo flag prevents recursion. Eligibility excludes unsuitable persistent/replay payloads in casting service; does not replay arbitrary UI requests |
| VectorEffect / vector-effect.gd | Mode IMPULSE/ATTRACT/ORBIT/DAMP/LIFT; strength finite 0–2000; optional capability metadata key | CharacterBody2D only; velocities bounded to 1800 and retained motion impulse bounded to 1000 for .25 s. DAMP uses 1-strength clamped 0–1; metadata presence opts in |
| ProjectileFieldEffect / projectile-field-effect.gd | Mode REVERSE/ATTRACT/SLOW/CANCEL; radius (0,1000], strength 0–1 | Valid Node2D, scans hostile MagicProjectile instances; reverse transfers ownership once per context; slow lasts .35 s; cancel affects wave-tagged projectiles/areas. Use affects_projectiles with area delivery for field behavior |

## Complete composition example

In a new AREA_BURST SpellData set aoe_spell_radius = 140, upfront_cost = 15, a unique ID/incantation and normal field/subject registration. Add effects in this order:

1. New DamageEffect, amount 12.
2. New ApplyStatusEffect, status slow, duration 2, magnitude .25, tick_interval 1, stacking REFRESH, max_stacks 1.
3. New KnockbackEffect, force 100.

The burst damages, applies slow and pushes eligible targets outward using the same caster context. Test both a normal target and one with full slow resistance; only the blocked status should fail. Compare [thermal-kinetic.tres](../../data/magis/spells/thermal-kinetic.tres) for a real payload. A nonempty explicit effects array means projectile_damage/stun flags will not be added a second time by LegacySpellAdapter.

## Ordering, recursion and budgets

SpellExecutor traverses the array in order, decrements the shared cast budget before each attempted effect, calls validate/accepts, then execute. A false effect does not roll back earlier damage or stop all later effects. Successful effects emit hit hooks; gameplay event receipts prevent duplicate quest credit at their defined granularity. There is no automatic atomic transaction for a multi-effect spell.

SpellCastContext starts with remaining_effect_budget 256 and a depth limit of 8. SpellValidator rejects null effects, cyclic references and nested Conditional/Spawn/Trigger graphs deeper than 8. Runtime ownership and context validity stop dead/freed/cancelled sources. Spawn chains use the same context; replay has its explicit smaller independent budget and recursion flag. Do not treat budgets as permission to instantiate unlimited custom autonomous scenes: add bounded lifetimes/caps to custom mechanics.

All normal mutation goes through server/single-player authority. A UI effect preview is not execution authority. Use the appropriate caster service so mana, equipment/loadout, status, cooldown and target checks are applied before dispatch.

## Custom subclass when composition is insufficient

Create a new script under data/Resources/spell-effects/, declare `class_name MyEffect extends SpellEffectDefinition`, export authored inputs, implement finite/bounded validate(), the precise accepts contract and synchronous execute(). Store mutable state in context/component instances, not the Resource. Return true only for the intended successful application. Add nested graph handling in SpellValidator if the subclass introduces a new children contract; the current validator recognizes only its three named containers.

This executable syntax example creates no game content and does not register a new handler:

```gdscript
extends Node
func inspect_existing_payload() -> PackedStringArray:
    var definition := preload("res://data/magis/spells/phys-strike.tres")
    return SpellValidator.validate(definition)
```

Completion: payload reachable from parent; defaults/constraints understood; target compatibility and ordering tested; nested cycles/budget/cleanup/authority tested; new class imported in editor and retained by a real `.tres` dependency in PCK; save policy documented (temporary effects currently clear).

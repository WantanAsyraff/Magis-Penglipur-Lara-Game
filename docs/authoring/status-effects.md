# Status effects

## Definitions and runtime owner

[ActiveEffectManager](../../components/spells/active-effect-manager.gd) is a RefCounted helper owned/ticked by [HitboxComponent](../../components/NPCs/enemies/hitbox-component.gd), not a Resource class to search in New Resource. Author ApplyStatusEffect, ModifyStatEffect or HealEffect Resources instead. The presentation registry is [status-presentation.gd](../../scenes/ui/status-effects/status-presentation.gd); no StatusData Resource exists.

Create ApplyStatusEffect in a spell/ability effects array. Configure a recognized status key, positive duration, nonnegative magnitude, tick_interval ≥ .05, stack policy and max_stacks 1–32. The parent content reference supplies export registration; adding a HUD icon alone changes no gameplay.

## Existing semantics

| Key/path | Behavior |
| --- | --- |
| stun | Hitbox query gates movement/casting; actors react through existing status handlers |
| silence | Casting restriction; it is not a generic dialogue/input ban |
| slow | Largest factor among matching entries, clamped 0–1; reduces movement |
| dot | Periodic hitbox damage using amount/interval |
| mana_drain | Periodic mana_drained signal; requires has_mana |
| hot / HealEffect | Periodic healed signal, classified beneficial |
| buff_speed/damage/mana_regen/defense/cast_speed/dash_charges | ModifyStatEffect stores amount; consumers in player/casting/hitbox apply supported stats |
| charged/resonating/etc. | Markers used by authored Conditional/Chain payloads; an arbitrary new key has no extra automatic mechanic |

REFRESH updates the first matching entry's maximum remaining time and replaces its data/source/classification; it does not add a stack. REPLACE removes matching entries then adds one. STACK adds independent entries until the configured cap; at cap it refuses rather than refreshing. IGNORE refuses if any matching entry exists. Remaining duration is authoritative manager time, not a HUD timer. Selective clear removes only matching beneficial classification, including mixed-classification entries sharing a key.

apply_status applies status resistance by shortening duration; resistance 1 refuses. Invincibility and authority also gate that path. Direct manager application (as used by ModifyStatEffect/HealEffect) deliberately bypasses that resistance path. Beneficial classification determines dispel categories and HUD accents, so arbitrary buff-like names are not enough: Hitbox currently recognizes hot and buff_ prefixes, while direct manager.apply requires the beneficial argument. Removal by key removes all its stacks; source removal removes only entries with that source ID.

## Add a supported marker status and presentation

1. In a spell, New ApplyStatusEffect: status `study_mark`, duration 3, magnitude 0, REFRESH/max_stacks 1.
2. Add ConditionalEffect to another spell: required_status study_mark, minimum_stacks 1, optional consume, with DamageEffect children. This composes existing behavior without editing Player.gd.
3. Add a name/description/glyph/priority entry to StatusPresentation.DEFINITIONS if a custom HUD label/icon is desired. Add a new draw glyph to StatusEffectIcon only if existing shapes are insufficient. Those are presentation code edits, not new status gameplay.
4. Register the parent spells, test marker expiry/refresh, conditional consumption, dispel classification, resistance, source removal and local HUD. A marker-only status is valid but does nothing beyond presence until consumed by a real handler.
5. For a new mechanic such as stacking poison with different tick semantics, implement/validate its periodic or actor-stat behavior at the existing effect/hitbox/component boundary and add regression tests. Do not introduce a second manager.

The [HUD guide](../status-effects-hud.md) documents eight cached icons, actual stack snapshots, stable dangerous-debuff priority, tooltips/focus, overflow, modal visibility and player rebinding. Current V1 saves deliberately clear temporary effects; do not add partial key-only status serialization. Validation: combat-feedback-save-v1 plus spell/physics/enemy suites and actual rendered expiry/stack checks. Completion: known handler or explicit marker consumer; correct classification; timer/stack/clear tests; presentation and PCK references; transient save policy understood.

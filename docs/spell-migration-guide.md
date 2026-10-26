# Migrating existing spells

Existing `.tres` and `.tscn` files retain their UIDs. `SpellData`, `subjectData`, `CourseData`, `SpellEffect`, `MagicProjectile`, `HitboxComponent` and Player's existing execution entry points remain. No legacy exported fields were deleted.

## Gradual migration

Leave `delivery = LEGACY` and `effects = []` to use the compatibility adapter. It maps legacy projectile damage/knockback/status flags, healing/HoT, stat buffs and decast categories into reusable effects. The conversion creates fresh effect definitions and does not edit loaded spell Resources.

To migrate one spell, choose explicit delivery and targeting, then populate the complete effect array. Preserve its ID, incantation, resource UID, costs, presentation and academic references. Test both direct hits and misses, AOE, interruption and status expiry. Add it to the baked manifest if it is new content. No Player mechanic branch is needed.

Specialized trusted scenes can still subclass SpellEffect. Keep `spell_data`, `source`, `direction` and `start()`; the new `cast_context` supplies shared execution state. After parenting, set global_position, then call start(). Deliver through `SpellExecutor` so statuses, authority and budgets remain consistent. The existing projectile scenes already follow this path.

## Intentional behavior changes

- Cast times and channel costs now apply; previously Player dispatched immediately.
- Upfront reservation/refund and channel spending follow the architecture document.
- Default chained incantations remain; fast matches queue without charging until started.
- Overlapping buffs use independent lifetimes and explicit stacking policies. Legacy non-stackable buffs refresh rather than creating unmanaged timers.
- DAMAGE, DEFENSE and CAST_SPEED buffs now affect execution. Legacy proc IDs remain stored, with no new proc dispatcher.
- Terrain impacts trigger AOE and cannot detonate repeatedly in the same physics frame.
- Shatterwave had zero size, speed, range and damage. It receives Strike's existing 0.8 size / 1000 speed / 950 range / 8 damage as a conservative working baseline; its incantation, UID and cost remain unchanged. Designer tuning is still needed.
- Physics I's omitted difficulty was zero despite the exported 1–5 range. It is now one; the cost formula enforces this minimum.
- Subject completion is explicit and purchases are atomic. Existing ownership is not converted to completion because individual item unlocks must not complete whole subjects. Any future imported saves need an explicit completion migration decision.
- Remote actors use separate incoming combat state, and network clients cannot apply authoritative effects. Full client casting/replication remains future work.

## Startup compatibility fixes

The project uses `addons/scene_manager/SceneManager.tscn`. The missing Scene_Transition autoload had no callers; it and unused settings for the absent yet_another_scene_manager plugin were removed. Bootstrap references use existing paths where necessary, leaving the underlying resource UIDs intact.

The story selector references the current prologue house entry. Deleted flower and bark loot resources were restored from repository history with their original resource UIDs, item IDs and prior consumable/drop values, migrating embedded item fields into ItemData. Bark now links the existing gather objective ID. Inventory and quest APIs remain unchanged. The baked world manifest is regenerated to remove stale paths that only failed in exported builds; its fallback now reads the script constant without allocating an unused Node.

## Persistence and boundaries

`completed_subjects` and `academic_comprehension` are runtime progression state. Reset clears them. Persist both when implementing or extending save/load; item-based spell unlocks should remain independent. The old `active_buffs` singleton field remains available for callers, but the hitbox's ActiveEffectManager is the runtime source of truth.

Existing tether, resonance, misfire and experimental fields remain available but are not silently claimed as implemented. See the architecture document for their limits and for the multiplayer boundary.

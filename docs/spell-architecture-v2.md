# Spell architecture V2

## Responsibilities

| Class | Responsibility |
| --- | --- |
| SpellData | Immutable shared identity, academic classification, costs, delivery and effect definitions. All previous fields remain. |
| SpellCastingComponent | Validation, resource reservation, preparation/channel timing, cooldown, bounded cast queue and interruption. One component per caster. |
| SpellCastContext | Unique process-local cast ID, caster, spell, origin, direction, targets, modifiers, team, timestamp, mutable instance state and effect budget. |
| IncantationResolver | Trie lookup and four prefix strategies, independent of mana and gameplay execution. |
| SpellDelivery | Dispatch and team targeting; uses existing projectile scenes or generic area deliveries. |
| SpellAreaDelivery | Owner-validity checks, bounded periodic area/beam ticks and one-hit traps. |
| SpellExecutor | Ordered compatible effects, failure/completion events and chain/budget limits. |
| SpellEffectDefinition | Typed Resource base exposing validate(), accepts(target) and execute(context, target). |
| LegacySpellAdapter | Per-cast conversion of existing categories and flags; explicit effects replace the legacy payload. |
| HitboxComponent | Public receive_hit API, damage mitigation, knockback and existing gameplay signals. |
| ActiveEffectManager | Duration, source, refresh/replace/ignore/stack policies, dispelling, ticking and expiration. |
| FieldData / subjectData / CourseData | Academic classification, relationships and progression requirements, independent of effects. |
| SpellValidator / AcademicValidator | Content validation and safe prerequisite traversal. |

`SpellEffect` remains the existing Area2D base. It is distinct from `SpellEffectDefinition`.

## Casting lifecycle and costs

`IDLE -> PREPARING -> [CHANNELING] -> EXECUTING -> RECOVERY -> IDLE`

The upfront cost is reserved exactly once after validation. Cast speed buffs divide preparation time by `max(0.1, 1 + bonus)`. Channeling charges `mana_per_second` only for elapsed channel time, including partial final frames; the payload dispatches once on channel completion. Channeling does not repeatedly emit projectiles. Use a persistent delivery for repeated effects.

Cancellation or dispatch failure before successful execution refunds upfront mana. Spent channel mana is never refunded. Successful dispatch starts cooldown and consumes upfront mana permanently. A valid burst in an empty area still completes and costs mana. Cancelling recovery clears pending casts but does not undo delivered effects or their costs. Direct targets are checked again when preparation finishes.

Chained inputs can enqueue eight pending requests. They spend no mana until started and repeat all validation then. Source position and direction are captured at input time. Cooldowns are keyed by spell ID per caster.

## Delivery and execution

Projectile delivery supports spread, multiple projectiles, piercing, terrain detonation and AOE. Initialization is idempotent. Each projectile records hit bodies and terminates a non-piercing impact once; direct impact targets are excluded from its AOE query. Movement and spawn positions are applied in world coordinates after parenting.

Self/direct/burst deliveries execute immediately after preparation. Persistent areas and traps use radius queries over registered hitboxes. Beams now use bounded terrain-ray segments and width checks against registered hitboxes; configured optical interfaces turn or reflect their paths. Native area, trap and beam feedback is supplied by SpellAreaDelivery. Summons instantiate a configured Node2D scene, execute configured effects on it, and optionally call its trusted `initialize_spell(context)` handler.

Effects currently include damage, heal/HoT, apply/remove status, knockback, stat modification, teleport, conditional children and entity spawn with child effects. Damage also accepts the existing environmental `take_damage` API. Conditional children can require status stacks, consume the status and require explicit capability metadata. All nested execution shares a 256-effect budget and maximum depth of eight. There is no string evaluation or data-supplied arbitrary method invocation. Custom trusted scripts remain ordinary project code.

Team defaults are player/enemy; actors can supply `spell_team` metadata. V2 targeting selects enemies, allies or any team. Self delivery explicitly targets the caster. Legacy decasts purge enemy buffs and allied debuffs according to their flags.

## Active effects

Effects are ticked by the owning hitbox, with no detached timers. Durations and periodic intervals are validated. Intervals are bounded to 0.05–3600 seconds; catch-up is capped at 64 ticks per frame. Final boundary ticks are included, and refresh preserves tick phase. Independent stacks expire separately; stat bonuses are calculated from active entries rather than restoring saved base attributes. Stacks are capped at 32. Removing a source preserves other sources' stacks.

Stun and silence restrict casting; slow restricts movement; DOT damages; mana drain suppresses Player regeneration and drains mana; HoT emits healing signals. Speed, mana regeneration, dash capacity, preparation speed, flat outgoing damage and flat incoming defense buffs are implemented for Player. Enemy hitboxes share damage, defense and statuses; Player-specific movement/dash/regen buffs do not grant equivalent NPC behavior automatically.

Removing or queuing deletion of a caster prevents further context execution. Already delivered active effects remain owned by the target until removed or expired. Death clears the owner's effects and cancels its casting. Runtime execution events reflect successful top-level effects; nested custom effects can emit their own presentation signals.

## Multiplayer boundary

ENet/Noray and player spawning are preserved. Local input is guarded in Player and its animation/debug/death children. Remote actors' incoming health/mana use instance fields and do not write the local singleton. Gameplay dispatch, effect execution, hitbox damage and NPC simulation require server authority when a peer is active. No damage RPC is exposed to clients.

Client cast request RPCs, server-side remote loadouts, replicated actor stats, projectile/event IDs, reconciliation and cancellation replication are **not implemented**. Clients currently cannot cast authoritative spells. Process-local cast IDs are not network deduplication IDs. Movement remains in the existing networking model. This is a security boundary and synchronization foundation, not completed multiplayer spell replication.

## Remaining limits

Existing experimental tether/chain balancing fields, resonance restrictions, the status_effects resource hook, on-hit proc IDs and misfire silence remain serialized but do not acquire new gameplay handlers in this change. Stat modifier effects store proc identifiers for future handlers. The shared execution budget bounds configured conditional/spawn chains; it does not implement the legacy tether targeting mechanic. Generic physical constructs have bounded lifetimes; other summon scenes still need their own AI and lifetime. Save integration must persist explicit completion and comprehension when a complete save system is added.

The [Physics curriculum](physics-curriculum.md) extends this baseline with chains, triggers, projectile fields, reflection, bounded replay and opt-in live channels. Its documentation supersedes the original implementation limits for those mechanics; networking and save limitations still apply.

# Magis pipeline

The pipeline preserves the eight main spell resources, their IDs, UIDs and incantations, and the existing projectile scenes. New definitions can use reusable effects; existing definitions are converted at runtime by `LegacySpellAdapter` without mutating the resources.

## Execution path

1. Player input enters the casting stance and feeds `IncantationResolver`, indexed from equipped spells.
2. The resolver returns an intentional match according to its configured strategy.
3. `SpellCastingComponent` checks authority, learning/equipment, status restrictions, resource validity, cooldown, targeting and mana.
4. It reserves the upfront mana and enters preparation, optional channeling, execution and recovery.
5. `SpellDelivery` dispatches the context to a projectile, self, direct target, burst, persistent area, beam, trap or summon.
6. `SpellExecutor` applies ordered effect resources, checking compatibility and a shared budget.
7. The target's `HitboxComponent` handles mitigated damage, knockback and owner-ticked active effects. Existing damage, healing, mana and status signals still drive presentation and character state.

Enemy ranged attacks use the same casting component. Enemy melee and other existing `receive_hit(spell, direction)` callers retain their public API through the legacy adapter.

## Incantations

The Player inspector exposes `incantation_strategy`:

| Strategy | Prefix behavior |
| --- | --- |
| CHAINED (default) | Each completed incantation triggers immediately, including exact prefixes. Longer continuations remain available; if the next arrow cannot extend a completed combo, it can start another equipped combo. Up to eight pending casts wait for the current cast. Each is validated and charged when it starts. |
| IMMEDIATE | First exact match casts and consumes the sequence. |
| CONFIRMATION (opt-in) | O confirms the current exact match when leaving the stance. |
| DELAYED | An ambiguous exact prefix waits 0.35 seconds; continuation replaces it. |

P clears the sequence, cancels preparation/channeling and clears pending casts. O closes the stance; already accepted casts continue. Silence, stun, damage and death interrupt active preparation/channeling. UI reports queued/accepted matches before execution; completion and failure signals are available for richer presentation.

## Learning

`Player_Global_Data.purchase_subject(subject, course)` validates completion, prerequisites, comprehension and XP, marks completion before emitting signals, charges once and grants all contained spells. Subject costs use the existing formula with a minimum difficulty of one; Physics I's invalid zero difficulty is corrected to one. Owning an individual spell never implies subject completion. Course prerequisites refer to completed subject IDs. `AcademicValidator` rejects duplicate IDs and prerequisite cycles within a course.

The spell tree and subject panel use the singleton API and progression signals, replacing per-frame panel rebuilding. Items still unlock spells through the existing inventory path. Quest and course IDs remain unchanged.

## Content discovery

`Spell_Library` loads explicit preloads from `data/magis/spell-manifest.gd`. In editor builds it also discovers unbaked `.tres` additions and reports a warning. Duplicate IDs are rejected without overwriting. Invalid definitions stay visible for diagnosis but fail casting validation. Duplicate incantations and prefix ambiguities are reported separately.

Use the [authoring guide](spell-authoring-guide.md), [architecture](spell-architecture-v2.md), [migration guide](spell-migration-guide.md) and [implementation report](spell-pipeline-v2-report.md) for details and measured verification results.

## Physics reference curriculum

The course now contains twelve subjects and 42 working spell resources, with the original eight IDs, paths, UIDs and incantations retained. See [curriculum and measured tests](physics-curriculum.md), [catalogue](physics-spell-catalogue.md), [interactions](physics-spell-interactions.md) and [baseline coverage audit](physics-implementation-coverage.md).

Player direct-target input selects the nearest eligible target in an aim cone (dot product at least 0.35), weighted by distance and lateral offset. World-targeted areas/constructs use a bounded point along the cast direction. Solid construct placement checks terrain overlap. Bursts center on the caster. Invalid direct targets fail through the normal casting failure signal without consuming mana.

New reusable components: VectorEffect with additive collision-aware SpellMotionImpulse; ProjectileFieldEffect for reversal, curvature, local speed and wave cancellation; ChainEffect with a visited set and hop limit; TriggerEffect with owner-attached, expiring SpellHitTrigger; InterruptEffect; bounded ReplayEffect; and expiring SpellConstruct with optional collision, following, interception and reflection. ApplyStatusEffect accepts authored status tags; ConditionalEffect supports stack thresholds, capability metadata and consumption. Existing damage, healing, stat, removal, spawn and teleport effects remain available.

Beams use bounded terrain raycasts, configured optical interfaces and up to five output angles / four segments per path. Reflective constructs transfer segment ownership. Projectiles perform a center sweep each physics step to reduce tunneling, use size-derived collision radii and select collision masks from the casting team. Native activation flashes, status markers, visible areas/traps/beams and construct duration indicators provide feedback without external assets.

`live_channel` is opt-in for beam/area/trap deliveries: dispatch occurs at channel start, upfront mana becomes committed, per-second mana is charged for elapsed time, and cancellation/completion deletes the owned delivery. Ordinary channels retain their prior dispatch-on-completion policy. Effects already delivered never produce a refunded free channel cast. Persistent casts are limited to twelve active nodes per caster. Execution budgets remain per context, so very dense repeated areas may exhaust them before normal expiry.

Echo records only compatible successful simple payloads, uses a fresh 64-effect context, scales damage/healing to half and excludes recursive replay/spawn/trigger payloads. Paid casts still follow learning, equipment, mana, cooldown and authority rules. This does not complete multiplayer client requests or replication; the V2 limitations remain.

Chained input does not wait for a second O press. Existing SpellData preparation, channel, recovery, cooldown, mana and authority rules still apply. Up to eight completed combos queue during an active cast; queued spells validate and pay mana when they start. A rejected prefix does not erase the resolver's continuation, so a cooling-down or unaffordable short spell cannot prevent an eligible longer spell. Invalid partial input still clears normally. A valid longer continuation takes priority over restarting from the root when both could match.

`tests/player-combo-chains.tscn` runs 22 checks through the production Player: automatic completion, prefix continuations, independent follow-ups, queue order/payment, cooldown/mana rejection, equipment revalidation, cancellation/refund, optional confirmation and the 9999 XP / 400 HP defaults. The Physics runner includes it; packed quest verification repeats it from the exported game.

## Incantation Chain Assistant V1

The production Player now attaches a local-only native Control observer to the existing resolver/casting pipeline. Read-only trie snapshots provide actual equipped continuations and restart directions; prefix spells continue casting immediately under CHAINED. The assistant never executes predictions. Request-status events correlate queue acceptance, preparation, channeling, execution, completion, and failures with stable request/chain IDs; existing casting signals and boolean request APIs remain compatible.

Guided, Minimal, and Off are presentation preferences in the existing settings menu. Clear Incantation clears only input; the separately configurable, initially unbound Cancel Active Cast / Queue action preserves explicit channel cancellation. Gameplay validation, individual mana payment, cooldowns, effects, and multiplayer authority remain in the casting component. The repertoire remains accessible in a bounded right column. See [architecture, APIs, authoring example, screenshots, and actual verification results](incantation-chain-assistant.md).

The subsequent minimalist HUD revision removes the assistant panel and all text/cards/counters. Guided mode now displays only a transparent row of 64-pixel valid-next-direction icons; Minimal and Off hide this optional guidance. Resolver queries, request lifecycle, existing core feedback, and spell mechanics remain available unchanged.

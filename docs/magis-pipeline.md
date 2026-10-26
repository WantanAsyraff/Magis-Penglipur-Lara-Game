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
| CHAINED (default) | Each exact prefix casts; longer continuations remain available. Up to eight pending casts wait for the current cast. Each is validated and charged when it starts. |
| IMMEDIATE | First exact match casts and consumes the sequence. |
| CONFIRMATION | O confirms the current exact match when leaving the stance. |
| DELAYED | An ambiguous exact prefix waits 0.35 seconds; continuation replaces it. |

P clears the sequence, cancels preparation/channeling and clears pending casts. O closes the stance; already accepted casts continue. Silence, stun, damage and death interrupt active preparation/channeling. UI reports queued/accepted matches before execution; completion and failure signals are available for richer presentation.

## Learning

`Player_Global_Data.purchase_subject(subject, course)` validates completion, prerequisites, comprehension and XP, marks completion before emitting signals, charges once and grants all contained spells. Subject costs use the existing formula with a minimum difficulty of one; Physics I's invalid zero difficulty is corrected to one. Owning an individual spell never implies subject completion. Course prerequisites refer to completed subject IDs. `AcademicValidator` rejects duplicate IDs and prerequisite cycles within a course.

The spell tree and subject panel use the singleton API and progression signals, replacing per-frame panel rebuilding. Items still unlock spells through the existing inventory path. Quest and course IDs remain unchanged.

## Content discovery

`Spell_Library` loads explicit preloads from `data/magis/spell-manifest.gd`. In editor builds it also discovers unbaked `.tres` additions and reports a warning. Duplicate IDs are rejected without overwriting. Invalid definitions stay visible for diagnosis but fail casting validation. Duplicate incantations and prefix ambiguities are reported separately.

Use the [authoring guide](spell-authoring-guide.md), [architecture](spell-architecture-v2.md), [migration guide](spell-migration-guide.md) and [implementation report](spell-pipeline-v2-report.md) for details and measured verification results.

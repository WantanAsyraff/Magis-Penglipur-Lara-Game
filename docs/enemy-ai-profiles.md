# Enemy AI profiles

EnemyAIProfile holds immutable actions and shared positioning settings. Runtime EnemyAIController stores selected action, scores, decision timer, commitment and cooldowns per actor. Each EnemyAIAction has an ID, kind, base utility, health/mana eligibility thresholds, low-health/low-mana/threat considerations, optional ability ID and action cooldown.

An eligible action scores:

`utility * (1 + (1 - health_ratio) * low_health_weight + (1 - mana_ratio) * low_mana_weight + min(threat / 100, 1) * threat_weight)`.

Ineligible actions score zero. Highest score wins; resource order is the deterministic tie-breaker. During commitment (default 0.45 s), a new eligible action must beat the old score by switch_margin (default 20%). The decision interval defaults to 0.2 s. Active windup/casting/recovery cannot be replaced by ordinary decisions. Damage, stun, death and explicitly invalid conditions interrupt promptly.

| Profile | Behavior from weights and eligibility |
| --- | --- |
| aggressive-melee | Melee 14, chase 7; low retreat preference and short desired range |
| defensive-ranged | Ranged 9, retreat 12, defend 10; preferred range 240 and retreat band 90 |
| balanced-fighter | Melee 10, ranged 7; retreat/defend/recover available when relevant |
| cautious-spellcaster | Cast 9, retreat 14, defend 15, recover 16; safety and mana sustain |
| support-oriented | Recovery 25, summon 8; selects only configured support abilities and injured compatible recipients |
| heavy-guardian | Melee 16, chase 7, defend 10; desired range 80 and low retreat preference |

Pohon and Bunga have additional resource-only profile variants preserving their historical patrol/jump/spacing values. Pohon retains 500-pixel retreat spacing and gains a close strike preference. Bunga retains its close melee option while new ranged/repulse abilities provide another decision branch. These are the same controller with different resources, not separate NPC dispatch scripts.

| Action kind | Eligibility and execution |
| --- | --- |
| Idle | No visible target/memory; halt |
| Patrol | No visible target/memory; existing patrol/home/edge logic |
| Investigate | Memory but no LOS; move to the last seen point |
| Chase | Visible target beyond desired distance; move toward it |
| Retreat | Visible target inside retreat band; move away |
| Maintain range | Visible target; move toward/away outside the desired tolerance, otherwise hold |
| Melee | Configured melee ability passes range/LOS/status/cooldown checks |
| Ranged | Configured offensive projectile/beam spell passes shared checks |
| Cast | Configured offensive spell passes shared checks |
| Defend | Threat inside 1.5 × retreat range and configured defensive ability ready |
| Reposition | Memory without LOS; local movement toward last seen point, using wall jumping when blocked |
| Recover | Configured healing for an injured valid recipient, or low mana with positive configured regeneration |
| Flee | Visible target and health below profile flee threshold; retreat movement |
| Summon | Configured summon-role ability is usable; dispatch through shared casting |

Pure melee loadouts clamp desired distance to a reachable portion of their melee range so ranged-style profile defaults do not strand them outside attack reach. Ability weights choose among ready compatible loadout entries. Heals are skipped for recipients at or above 80% health. Allies are selected by lowest health ratio within range; there is no automatic global healing knowledge beyond registered actors.

The blackboard and score dictionary are available to arena diagnostics. Local repositioning is not full route planning; a tall wall with no traversable route may remain impassable. Balancing these profile weights under sustained play is not claimed complete.

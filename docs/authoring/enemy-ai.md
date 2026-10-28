# Enemy AI profiles and actions

## Schema and creation

[EnemyAIProfile](../../data/npc/enemies/enemy-ai-profile.gd) holds actions and movement/decision settings. [EnemyAIAction](../../data/npc/enemies/enemy-ai-action.gd) describes utility and an action kind. Save reusable profiles under data/npc/enemies/ai-profiles/; actions can be inline or external dependencies. Example: [cautious-spellcaster.tres](../../data/npc/enemies/ai-profiles/cautious-spellcaster.tres). There is no separate profile manifest: assign a profile to reachable EnemyData.

Right-click → New Resource → EnemyAIProfile, set explicit profile_id, expand actions and create EnemyAIAction entries. Give unique action_id values rather than relying on fallback kind names when two actions share one kind. Set kind in Inspector; use the [reference](../reference/resource-reference.md#enemyaiaction) for the complete enum (anchors are case-insensitive in normal Markdown navigation).

| Profile field | Meaning / constraint |
| --- | --- |
| decision_interval | ≥ .05 seconds between utility decisions |
| commitment / switch_margin | Commitment duration; during commitment a replacement needs the configured relative score margin while the old action remains eligible |
| preferred_range / retreat_range / range_tolerance | Engagement band and too-close behavior; pure melee desired distance is clamped to reachable melee reach |
| flee_health_ratio | 0–1 eligibility threshold, only matters with a FLEE action |
| patrol_range / wall_jump_velocity | Local movement bounds and nonpositive wall-jump impulse, not a navmesh |
| actions | Nonempty, valid, unique action IDs |

Each eligible action scores `utility * (1 + (1-health_ratio)*low_health_weight + (1-mana_ratio)*low_mana_weight + min(threat/100,1)*threat_weight)`. max_health_ratio/max_mana_ratio (0–1) are upper eligibility thresholds; action cooldown and actor restrictions can force score zero. Utilities/consideration weights/cooldowns must be finite and nonnegative. Highest eligible score wins; ties follow array iteration. Profile commitment does not make an unavailable action executable.

## Eligibility and execution

| Kind | Supported behavior |
| --- | --- |
| IDLE / PATROL | No visible target or sight memory |
| INVESTIGATE / REPOSITION | Target lost but recent memory remains; local movement toward known point |
| CHASE | Visible target beyond preferred band |
| RETREAT / MAINTAIN_RANGE | Visible threat; retreat activates inside retreat_range |
| MELEE | A ready in-range MELEE ability |
| RANGED | Ready OFFENSE SPELL whose delivery resolves PROJECTILE or BEAM |
| CAST | Ready OFFENSE SPELL without the ranged-delivery restriction |
| DEFEND | Visible close threat and a ready DEFENSE ability |
| RECOVER | Usable HEAL ability, or low mana with positive regen |
| FLEE | Visible target and HP below flee threshold |
| SUMMON | Usable SUMMON-role ability; target validity still applies |

The controller chooses the highest ability.weight among usable matching loadout entries. Healing skips recipients at or above .8 health ratio. Optional action.ability_id pins a particular ability; it does not authorize one missing from the loadout.

## Example: defensive ranged enemy

1. Duplicate cautious-spellcaster.tres through the Editor and make its actions unique if changing them. Set a new profile_id; keep idle/patrol/investigate/chase/maintain-range/retreat actions.
2. Set preferred_range 320, retreat_range 110 and range_tolerance 35. Those are suggested new-content values, not a change to shipped enemies.
3. Give a RANGED action utility 7 and a DEFEND action utility 15 with low_health_weight 2. Leave thresholds at 1 initially, so eligibility follows range/loadout rather than an accidental HP gate.
4. On the new EnemyData, assign one OFFENSE projectile ability and one DEFENSE SELF spell ability, plus enough max_mana/mana_regen. Assign this new profile. A high defend utility without a defensive ability does nothing.
5. Run at ranges inside/outside retreat/engagement bands. Inspect EnemyAIController.scores/selected and detection.blackboard in Remote Inspector. Confirm defense can cool down and offense resumes. Then test silence, stun, wall obstruction and mana exhaustion.

Profile validate checks finite ranges, thresholds, nonempty actions and duplicate IDs. EnemyData.validate recursively invokes it. Source/PCK dependencies follow EnemyData; no bake utility exists. New flying pathfinding, tactical cover navigation, squad coordination or delayed counter/combo logic needs code, not just a high utility number.

Completion: reusable profile with local runtime state; matching usable loadout; explicit action IDs; validate and run enemy tests; manual range/LOS/cooldown checks; no claim of unsupported route planning.

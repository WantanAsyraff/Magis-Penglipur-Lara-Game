# Three-phase bosses

## Reusable controller, schemas and reference

The boss controller is [Boss](../../components/NPCs/enemies/boss/boss.gd), a CharacterBody2D script with a reusable [base scene](../../components/NPCs/enemies/boss/boss.tscn). BossPhaseData and BossAttackData are Resources at [boss-phase.gd](../../data/npc/enemies/boss-phase.gd) and [boss-attack-data.gd](../../data/npc/enemies/boss-attack-data.gd). The primary example is [Penjaga Resonans](../../components/NPCs/enemies/boss/resonance-guardian.tscn), with content under data/npc/enemies/boss/resonance-guardian/. Boss is separate from ordinary EnemyData utility AI; do not assign EnemyData expecting it to populate phases.

## Editor walkthrough: author another three-phase boss

1. Open boss.tscn → New Inherited Scene; save under a new boss content folder. Retain HitboxComponent, collision, detection, animation and timer nodes. Set boss_name, positive max_health, mitigation, spell_mana, detection_radius, sight_memory and hurt/interruption recovery settings. Boss has no Resource identity field; campaign reward/quest integration for a new boss requires a deliberate event publisher, not an invented boss_id export.
2. Right-click a new data/npc/enemies/boss/<content>/ folder → New Resource → BossAttackData. Save separate attacks for reuse between phases. Set attack_name, kind, positive weight, nonnegative cooldown/windup and the kind-specific properties below.
3. Create three BossPhaseData Resources. Set phase_name and enter_at_health_ratio to 1.0, .65 and .30 for this hypothetical example. Set move_speed/chase_speed, phase_colour, transition_animation, transition_duration, invincible_on_transition and transition_invincible_duration. Negative defense/incoming_multiplier preserves the boss base value; phase status_resistances replaces the map.
4. On each phase, expand attacks and drag the attack files in. Reuse an attack Resource in several pools when its settings should remain shared. Different tuning needs a unique Resource copy, not modifying a shared attack during play.
5. On the inherited Boss root, assign phases in ordered descending thresholds, first phase at 1.0. Each phase needs a usable nonempty attack pool. Large damage can skip to the deepest qualifying later phase; it is not guaranteed to visit every intermediate phase.
6. Configure appearance. Penjaga hides the base sprite and adds a presentation-only Node2D listening to phase/state; ordinary animations require valid names/frames. Preserve correct body/detection dimensions.
7. Instance in an arena with solid floor/walls on the intended masks and reachable player spawn. Add `scenes/ui/boss/boss-health-bar.tscn` to an appropriate CanvasLayer and call its bind_boss method from the arena controller (a small scene-integration script is required; a global boss HUD registry does not exist).
8. Use the production prototype as a reference for ready/intro/active/victory/defeat/resetting lifecycle, but do not copy boss.gd. Its room script preloads a specific guardian and temporary player loadout; changing to a new boss/encounter policy requires an arena reference/integration edit, not merely putting a phase in a folder. Do not make that training room save campaign progress.
9. Run tests/boss-prototype.tscn and manually force phase crossings, interruption, paused windup, death, retry and scene exit. Test your new scene/pool as well; the existing suite cannot validate content it never references. Export and repeat resource loading/arena entry.

## Attack settings, geometry and warning match

| Kind | Configuration and actual execution |
| --- | --- |
| MELEE_SLAM | melee_damage, melee_range, melee_arc_degrees 1–360, windup. Heading is fixed at warning start; release checks player root offset/radius/arc. Telegraph draws the same radius/arc |
| MELEE_DASH | melee_damage, melee_range, dash_speed_multiplier × phase.chase_speed, dash_duration, windup. Direction fixed at start; warning length is terrain-clipped speed×duration. Runtime movement/collision stops travel; hit radius is melee_range×1.5 and hits at most once per dash |
| RANGED_BURST | ranged_spell, burst_count clamped 1–32, burst_interval and burst_spread, windup. Duplicates the spell, zeroes its cast_time and divides upfront cost per shot; each shot still uses shared casting/cooldown/target rules. Telegraph is directional, not a precise projectile flight-path guarantee |
| AOE_SLAM | aoe_radius, aoe_damage, aoe_knockback, aoe_warning_duration. Circle warning and physics query use the same radius. Uses collision mask 3 and hostile relation/hitbox checks, deduplicating bodies |
| SUMMON | minion_scene Node2D, minion_count and spawn_radius after windup. Owned minions capped at twelve. No automatic pathfinding or dedicated full summon geometry telegraph; custom minions need compatible behavior |

Attack cooldown is the next-attack delay after completion. Attack selection filters melee by range, dash by melee_range×3, AoE by radius×1.5; ranged/summon remain distance-eligible. The active implementation returns null when none qualify, despite an older nearby comment mentioning fallback. It then uses relative weights among eligible attacks. Avoid zero/negative/nonfinite weight pools: these schemas have **no standalone validate()** methods.

Phase transition interrupts attack epochs, clears telegraphs/dash, cancels casting and changes mitigation. It waits max(transition_duration, invincibility duration if enabled), then restores vulnerability and recovery. Death/exit cleans owned attacks/minions; replaying old await callbacks must not revive damage. The three-phase prototype and its HUD/retry implementation are a working integration reference, not a campaign boss progression/save feature.

## Validation, extension and completion

Review every field against [the exact schemas](../reference/resource-reference.md#bossphasedata). Check positive HP, finite nonnegative geometry/timings, descending thresholds, valid scenes/spells, warning/damage correspondence and accessible arena geometry. Test direct damage, status resistance and phase-specific movement under rendering, not only serialized Resource validity.

Existing attacks/phases/HUD require no controller copy. New attack kinds, complex arena hazards, rewards, authored summon behavior or network replication require explicit code extensions with cancellation/lifecycle tests. Completion: inherited scene, three referenced phases, valid weighted pools, visual/HUD bindings, actual boss suite plus new encounter tests, fresh PCK load and campaign-isolation check.

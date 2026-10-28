# Resource property reference

Generated from every first-party Resource-derived schema by `python3 tools/validate-docs.py --write-reference`. Do not hand-edit generated field tables: update schema notes/tooling and regenerate. Runtime behavior/required playable combinations are explained in each linked canonical guide. Inspector hints are not always runtime validators. “Required” means authoring contract, including meaningful presentation; “Conditional/optional” may become mandatory for a selected delivery/mode. A schema default alone does not establish gameplay completeness.

Each table gives the exact declaration/default and Inspector hint, purpose, registration/persistence implications and source consumers. Consumer links are lexical source evidence to inspect, **not proof every assignment affects execution**. Explicit dormant/legacy notes override apparent comment or validator-only references. Unassigned typed fields use Godot type defaults (empty string/zero/null/empty collection as applicable). Parent references retain nested Resources in export; ID-bearing definitions need the registration matrix.

[Registration matrix](content-registration-matrix.md) · [Authoring index](../authoring/README.md) · [Content evolution](../architecture/save-load-architecture.md)

## ApplyStatusEffect

Source: [data/Resources/spell-effects/apply-status-effect.gd](../../data/Resources/spell-effects/apply-status-effect.gd). Base: `SpellEffectDefinition`. [Canonical authoring and validation](../authoring/spell-effects.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `status` | `String` | Existing handler/marker key; not a new mechanic implementation by itself. | Conditional/optional | `"stun"` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/apply-status-effect.gd) |
| `duration` | `float` | Effect/trigger lifetime in seconds; validate per subclass. | Conditional/optional | `1.0` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/apply-status-effect.gd) |
| `magnitude` | `float` | Status amount/factor supplied to the existing handler. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/apply-status-effect.gd) |
| `tick_interval` | `float` | Periodic interval; effect validators require at least .05 seconds. | Conditional/optional | `1.0` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/apply-status-effect.gd) |
| `stacking` | `ActiveEffectManager.StackPolicy` | REFRESH/REPLACE/STACK/IGNORE; manager counts independent entries. | Conditional/optional | `ActiveEffectManager.StackPolicy.REFRESH` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/apply-status-effect.gd) |
| `max_stacks` | `int` | Maximum independent stacks; configured policies and manager cap apply. | Conditional/optional | `1` | `@export_range(1, 32)`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/apply-status-effect.gd) |

## BossAttackData

Source: [data/npc/enemies/boss-attack-data.gd](../../data/npc/enemies/boss-attack-data.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/bosses.md).

Enum `AttackKind`: `MELEE_SLAM`, `MELEE_DASH`, `RANGED_BURST`, `AOE_SLAM`, `SUMMON`.

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `attack_name` | `String` | Visible boss telegraph label. | Conditional/optional | `"Attack"` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd), [boss-telegraph](../../components/NPCs/enemies/boss/boss-telegraph.gd) |
| `kind` | `AttackKind` | Exact enum selects supported action/ability/attack implementation. | Conditional/optional | `AttackKind.MELEE_SLAM` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd), [boss-telegraph](../../components/NPCs/enemies/boss/boss-telegraph.gd) |
| `weight` | `float` | Boss pool random weight; ordinary ability highest-ready preference. | Conditional/optional | `1.0` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `cooldown` | `float` | Seconds until reuse; ordinary ability and spell cooldowns both apply. | Conditional/optional | `1.5` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `windup` | `float` | Attack release delay; ability spell can also have its own cast_time. | Conditional/optional | `0.3` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `melee_damage` | `float` | Slam/dash damage before shared mitigation. | Conditional/optional | `25.0` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `melee_arc_degrees` | `float` | Slam arc, Inspector 1–360 degrees. | Conditional/optional | `360` | `@export_range(1, 360)`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd), [boss-telegraph](../../components/NPCs/enemies/boss/boss-telegraph.gd) |
| `telegraph_colour` | `Color` | Boss warning tint. | Conditional/optional | `Color(1.0, 0.65, 0.25)` | `@export`; see guide for runtime constraints. | [boss-telegraph](../../components/NPCs/enemies/boss/boss-telegraph.gd) |
| `melee_range` | `float` | Slam radius / dash hit-radius base; see boss geometry table. | Conditional/optional | `80.0` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd), [boss-telegraph](../../components/NPCs/enemies/boss/boss-telegraph.gd) |
| `dash_speed_multiplier` | `float` | Multiplier of current phase chase_speed. | Conditional/optional | `3.0` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `dash_duration` | `float` | Dash travel interval, stopped by world collision. | Conditional/optional | `0.25` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `ranged_spell` | `SpellData` | Boss burst spell template; duplicated for boss windup/per-shot cost. | Conditional/optional | `null` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `burst_count` | `int` | Boss shots, runtime clamp 1–32. | Conditional/optional | `3` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `burst_interval` | `float` | Time between burst shots, runtime minimum .01. | Conditional/optional | `0.15` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `burst_spread` | `float` | Boss burst angular spread. | Conditional/optional | `30.0` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `aoe_radius` | `float` | Boss warning circle and damage-query radius. | Conditional/optional | `120.0` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd), [boss-telegraph](../../components/NPCs/enemies/boss/boss-telegraph.gd) |
| `aoe_damage` | `float` | Boss AoE damage before shared mitigation. | Conditional/optional | `30.0` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `aoe_knockback` | `float` | Boss AoE outward knockback magnitude. | Conditional/optional | `400.0` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `aoe_warning_duration` | `float` | Warning wait for AoE; not attack.windup. | Conditional/optional | `0.8` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `minion_scene` | `PackedScene` | Node2D scene instantiated by boss SUMMON. | Conditional/optional | `null` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `minion_count` | `int` | Desired minions, bounded by twelve owned minions. | Conditional/optional | `2` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `spawn_radius` | `float` | Radial minion placement offset; no automatic placement safety solver. | Conditional/optional | `80.0` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |

## BossPhaseData

Source: [data/npc/enemies/boss-phase.gd](../../data/npc/enemies/boss-phase.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/bosses.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `phase_name` | `String` | Visible boss phase label. | Conditional/optional | `"Phase 1"` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `enter_at_health_ratio` | `float` | Boss phase entry fraction, order descending with phase one at 1. | Required | `1.0` | `@export_range(0.0, 1.0)`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `move_speed` | `float` | Phase/enemy move/patrol speed. | Conditional/optional | `90.0` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `chase_speed` | `float` | Phase/enemy chase speed; boss dash scales this. | Conditional/optional | `160.0` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `attacks` | `Array[BossAttackData]` | Nonempty reachable BossAttackData pool for phase. | Required | `[]` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `invincible_on_transition` | `bool` | Enable temporary boss invulnerability during transition. | Conditional/optional | `true` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `transition_invincible_duration` | `float` | Invulnerability duration; contributes to max transition wait. | Conditional/optional | `1.5` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `transition_duration` | `float` | Phase transition wait, combined with invulnerability wait. | Conditional/optional | `1.0` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `phase_colour` | `Color` | Presentation tint consumed by compatible guardian visual. | Conditional/optional | `Color(0.9, 0.75, 0.45)` | `@export`; see guide for runtime constraints. | [resonance-guardian-visual](../../components/NPCs/enemies/boss/resonance-guardian-visual.gd) |
| `transition_animation` | `String` | Existing sprite animation name or empty fallback. | Conditional/optional | `"phase_transition"` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `defense` | `float` | Flat incoming damage reduction; negative phase override preserves boss base. | Conditional/optional | `-1` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `incoming_multiplier` | `float` | Incoming damage multiplier; negative phase override preserves boss base. | Conditional/optional | `-1` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |
| `status_resistances` | `Dictionary[String, float]` | Status key → 0–1 duration resistance; 1 refuses application through apply_status. | Conditional/optional | `{}` | `@export`; see guide for runtime constraints. | [boss](../../components/NPCs/enemies/boss/boss.gd) |

## ChainEffect

Source: [data/Resources/spell-effects/chain-effect.gd](../../data/Resources/spell-effects/chain-effect.gd). Base: `SpellEffectDefinition`. [Canonical authoring and validation](../authoring/spell-effects.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `radius` | `float` | Effect search/field radius; finite constraints depend on subclass. | Conditional/optional | `180.0` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/chain-effect.gd) |
| `hops` | `int` | Bounded extra chain hops, 1–8. | Conditional/optional | `3` | `@export_range(1, 8)`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/chain-effect.gd) |
| `amount` | `float` | Payload magnitude; exact stat/damage/heal/chain semantics are in the effect guide. | Conditional/optional | `10.0` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/chain-effect.gd) |
| `preferred_status` | `String` | Bias chain target distance score for this status; not a mandatory filter. | Conditional/optional | `"charged"` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/chain-effect.gd) |

## ConditionalEffect

Source: [data/Resources/spell-effects/conditional-effect.gd](../../data/Resources/spell-effects/conditional-effect.gd). Base: `SpellEffectDefinition`. [Canonical authoring and validation](../authoring/spell-effects.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `required_status` | `String` | Required status key on target. | Conditional/optional | `"slow"` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/conditional-effect.gd) |
| `children` | `Array[SpellEffectDefinition]` | Nested ordered effects under the same execution/context contract. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/conditional-effect.gd) |
| `minimum_stacks` | `int` | Count required by ConditionalEffect; author positive meaningful values. | Conditional/optional | `1` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/conditional-effect.gd) |
| `consume` | `bool` | ConditionalEffect removes all matching-key stacks before children. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/conditional-effect.gd) |
| `capability` | `StringName` | Optional metadata presence gate, not a newly installed ability. | Conditional/optional | `&""` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/conditional-effect.gd) |

## CourseData

Source: [data/Resources/ilmu/course.gd](../../data/Resources/ilmu/course.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/courses-and-subjects.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `course_name` | `String` | Human-readable authored name for this definition. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [spell-tree](../../scenes/spell-tree/spell-tree.gd) |
| `course_id` | `String` | Stable authored identifier; match parent/registry/event references exactly. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/course.gd) |
| `course_archetype` | `String` | Authored course classification/presentation label. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/course.gd) |
| `course_description` | `String` | Authored course description. | Conditional/optional | `Godot type default` | `@export_multiline`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/course.gd) |
| `magis_archetype` | `String` | Authored Magis classification; not a player class or automatic resonance mechanic. | Conditional/optional | `"Mana Manipulation"` | `@export_enum ("Mana Manipulation", "Ilmiah", "Alnur", "Alzalam","Semesta")`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/course.gd) |
| `magis_comprehension` | `String (inferred)` | Classification label; subject value selects the purchase cost multiplier. | Conditional/optional | `"Novice"` | `@export_enum("Novice", "Intermediate", "Advanced", "Expert")`; see guide for runtime constraints. | [player-data](../../autoloads/player-data.gd) |
| `difficulty_level` | `int` | Inspector 1–5; subject difficulty contributes quadratically to purchase cost. | Conditional/optional | `Godot type default` | `@export_range(1,5)`; see guide for runtime constraints. | [player-data](../../autoloads/player-data.gd) |
| `prerequisites` | `Array[String]` | Completed subject IDs; course and subject purchase gates. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [spell-tree](../../scenes/spell-tree/spell-tree.gd), [player-data](../../autoloads/player-data.gd) |
| `subjects` | `Array[subjectData]` | Ordered subjectData references rendered by the assigned course view. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [spell-tree](../../scenes/spell-tree/spell-tree.gd), [player-data](../../autoloads/player-data.gd) |
| `academic_fields` | `Array[FieldData]` | Referenced FieldData academic identities; not delivery/automatic unlock logic. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/course.gd) |

## DamageEffect

Source: [data/Resources/spell-effects/damage-effect.gd](../../data/Resources/spell-effects/damage-effect.gd). Base: `SpellEffectDefinition`. [Canonical authoring and validation](../authoring/spell-effects.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `amount` | `float` | Payload magnitude; exact stat/damage/heal/chain semantics are in the effect guide. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/damage-effect.gd) |

## ElevatorFloor

Source: [data/worlds/elevator-floor.gd](../../data/worlds/elevator-floor.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/worlds-and-scenes.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `floor_name` | `String` | Visible elevator floor button label. | Required | `""` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/worlds/elevator-floor.gd) |
| `scene_id` | `String` | Stable trusted SceneData key, or registered destination key on ElevatorFloor. | Required | `""` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/worlds/elevator-floor.gd) |
| `spawn_marker_override` | `String` | Selected arrival marker override. | Conditional/optional | `""` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/worlds/elevator-floor.gd) |
| `locked` | `bool` | Grey/disable elevator entry; no automatic academic unlock handler. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [elevator-portal](../../components/elevator/elevator-portal.gd) |
| `locked_hint` | `String` | Elevator locked-button explanation. | Conditional/optional | `"Access restricted"` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/worlds/elevator-floor.gd) |

## EnemyAIAction

Source: [data/npc/enemies/enemy-ai-action.gd](../../data/npc/enemies/enemy-ai-action.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/enemy-ai.md).

Enum `Kind`: `IDLE`, `PATROL`, `INVESTIGATE`, `CHASE`, `RETREAT`, `MAINTAIN_RANGE`, `MELEE`, `RANGED`, `CAST`, `DEFEND`, `REPOSITION`, `RECOVER`, `FLEE`, `SUMMON`.

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `action_id` | `StringName` | Unique action ID; fallback derives from kind but explicit IDs avoid collisions. | Required | `&""` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `kind` | `Kind` | Exact enum selects supported action/ability/attack implementation. | Required | `Kind.IDLE` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `utility` | `float` | Base eligible action score. | Conditional/optional | `1` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `max_health_ratio` | `float` | Upper HP fraction threshold for action eligibility, 0–1. | Conditional/optional | `1` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `max_mana_ratio` | `float` | Upper mana fraction threshold for action eligibility, 0–1. | Conditional/optional | `1` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `low_health_weight` | `float` | Score factor growing as health falls. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `low_mana_weight` | `float` | Score factor growing as mana falls. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `threat_weight` | `float` | Score factor for capped threat consideration. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `ability_id` | `StringName` | Loadout identity / optional action filter; not implicit authorization. | Conditional/optional | `&""` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `cooldown` | `float` | Seconds until reuse; ordinary ability and spell cooldowns both apply. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |

## EnemyAIProfile

Source: [data/npc/enemies/enemy-ai-profile.gd](../../data/npc/enemies/enemy-ai-profile.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/enemy-ai.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `profile_id` | `StringName` | Stable profile identifier; direct parent reference supplies discovery. | Required | `&"balanced"` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/npc/enemies/enemy-ai-profile.gd) |
| `actions` | `Array[EnemyAIAction]` | Nonempty unique-ID utility actions. | Required | `[]` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `decision_interval` | `float` | At least .05 seconds between eligible AI decisions. | Conditional/optional | `0.2` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `commitment` | `float` | Duration of switching resistance while current action stays eligible. | Conditional/optional | `0.45` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `switch_margin` | `float` | Relative score improvement needed during commitment. | Conditional/optional | `0.2` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `preferred_range` | `float` | Desired engagement range, adjusted for pure-melee reach. | Conditional/optional | `200` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `retreat_range` | `float` | Close-threat distance used by retreat/defend eligibility. | Conditional/optional | `80` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `range_tolerance` | `float` | Dead band around preferred engagement distance. | Conditional/optional | `35` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd), [enemy-movement-component](../../components/NPCs/enemies/enemy-movement-component.gd) |
| `flee_health_ratio` | `float` | 0–1 maximum health ratio for FLEE eligibility. | Conditional/optional | `0.15` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `patrol_range` | `float` | Local patrol distance from origin. | Conditional/optional | `120` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/npc/enemies/enemy-ai-profile.gd) |
| `wall_jump_velocity` | `float` | Nonpositive vertical wall-jump impulse. | Conditional/optional | `-260` | `@export`; see guide for runtime constraints. | [enemy-movement-component](../../components/NPCs/enemies/enemy-movement-component.gd) |

## EnemyAbilityData

Source: [data/npc/enemies/enemy-ability-data.gd](../../data/npc/enemies/enemy-ability-data.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/enemy-abilities.md).

Enum `Kind`: `MELEE`, `SPELL`.
Enum `Role`: `OFFENSE`, `DEFENSE`, `HEAL`, `SUMMON`.

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `ability_id` | `StringName` | Loadout identity / optional action filter; not implicit authorization. | Required | `&""` | `@export`; see guide for runtime constraints. | [enemy-combat](../../components/NPCs/enemies/enemy-combat.gd), [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `kind` | `Kind` | Exact enum selects supported action/ability/attack implementation. | Required | `Kind.SPELL` | `@export`; see guide for runtime constraints. | [enemy-combat](../../components/NPCs/enemies/enemy-combat.gd), [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `role` | `Role` | OFFENSE/DEFENSE/HEAL/SUMMON action compatibility. | Conditional/optional | `Role.OFFENSE` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `spell` | `SpellData` | Required SpellData for SPELL ability. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [enemy-combat](../../components/NPCs/enemies/enemy-combat.gd), [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `effects` | `Array[SpellEffectDefinition]` | Ordered typed payload; nonempty SpellData array replaces legacy-derived effects. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [enemy-combat](../../components/NPCs/enemies/enemy-combat.gd) |
| `min_range` | `float` | Minimum target root-to-root distance for nonself ability. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [enemy-combat](../../components/NPCs/enemies/enemy-combat.gd) |
| `max_range` | `float` | Maximum target root-to-root distance for nonself ability. | Conditional/optional | `500` | `@export`; see guide for runtime constraints. | [enemy-combat](../../components/NPCs/enemies/enemy-combat.gd), [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `requires_los` | `bool` | Require combat line of sight to nonself target. | Conditional/optional | `true` | `@export`; see guide for runtime constraints. | [enemy-combat](../../components/NPCs/enemies/enemy-combat.gd) |
| `windup` | `float` | Attack release delay; ability spell can also have its own cast_time. | Conditional/optional | `0.25` | `@export`; see guide for runtime constraints. | [enemy-combat](../../components/NPCs/enemies/enemy-combat.gd) |
| `recovery` | `float` | Ordinary enemy ability recovery seconds. | Conditional/optional | `0.15` | `@export`; see guide for runtime constraints. | [enemy-combat](../../components/NPCs/enemies/enemy-combat.gd) |
| `cooldown` | `float` | Seconds until reuse; ordinary ability and spell cooldowns both apply. | Conditional/optional | `1.2` | `@export`; see guide for runtime constraints. | [enemy-combat](../../components/NPCs/enemies/enemy-combat.gd), [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |
| `weight` | `float` | Boss pool random weight; ordinary ability highest-ready preference. | Conditional/optional | `1` | `@export`; see guide for runtime constraints. | [enemy-ai-controller](../../components/NPCs/enemies/enemy-ai-controller.gd) |

## EnemyData

Source: [data/npc/enemies/enemy-data.gd](../../data/npc/enemies/enemy-data.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/enemies.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `enemy_id` | `StringName` | Explicit stable enemy type identity; compatibility getter may fall back to quest ID or filename. | Required | `&""` | `@export`; see guide for runtime constraints. | [enemy](../../components/NPCs/enemies/enemy.gd), [quest-registry](../../components/quests/quest-registry.gd) |
| `enemy_name` | `String` | Visible enemy name. | Conditional/optional | `"Enemy"` | `@export`; see guide for runtime constraints. | [enemy](../../components/NPCs/enemies/enemy.gd) |
| `description` | `String` | Authored explanatory text, not a gameplay handler. | Conditional/optional | `""` | `@export_multiline`; see guide for runtime constraints. | [Schema / methods](../../data/npc/enemies/enemy-data.gd) |
| `enemy_category` | `StringName` | Authored classification metadata; not a controller dispatcher. | Conditional/optional | `&"manifestation"` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/npc/enemies/enemy-data.gd) |
| `faction_id` | `StringName` | Team identity for targeting and friendly-fire rules. | Required | `&"enemy"` | `@export`; see guide for runtime constraints. | [enemy](../../components/NPCs/enemies/enemy.gd) |
| `visual_scene` | `PackedScene` | Optional appearance-only Node2D; preserve shared gameplay shell. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [enemy](../../components/NPCs/enemies/enemy.gd) |
| `stats` | `EnemyStatsData` | Required EnemyStatsData reference; live HP/mana live in component state. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [enemy](../../components/NPCs/enemies/enemy.gd) |
| `perception` | `EnemyPerceptionData` | Required EnemyPerceptionData reference. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [enemy](../../components/NPCs/enemies/enemy.gd) |
| `ai_profile` | `EnemyAIProfile` | Required EnemyAIProfile reference. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [enemy](../../components/NPCs/enemies/enemy.gd) |
| `abilities` | `Array[EnemyAbilityData]` | Authorized EnemyAbilityData loadout; not the global spell library. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/npc/enemies/enemy-data.gd) |
| `cooldown_multiplier` | `float` | Positive scale on ability cooldowns. | Conditional/optional | `1` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/npc/enemies/enemy-data.gd) |
| `loot` | `Array[LootData]` | Independent LootData entries consumed once per authoritative death. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [enemy](../../components/NPCs/enemies/enemy.gd), [quest-registry](../../components/quests/quest-registry.gd) |
| `experience_reward` | `int` | Nonnegative XP on ordinary enemy death; not a quest reward amount. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [enemy](../../components/NPCs/enemies/enemy.gd) |
| `quest_enemy_id` | `String` | Kill observer identity; match registered enemy/objective ID for quests. | Conditional/optional | `""` | `@export`; see guide for runtime constraints. | [enemy](../../components/NPCs/enemies/enemy.gd) |
| `death_delay` | `float` | Bounded 0–30 seconds before cleanup. | Conditional/optional | `0.25` | `@export`; see guide for runtime constraints. | [enemy](../../components/NPCs/enemies/enemy.gd) |
| `enemy_tags` | `Array[StringName]` | Tags published on credited death events; structural/magnetic also opt into manipulation. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [enemy](../../components/NPCs/enemies/enemy.gd) |

## EnemyPerceptionData

Source: [data/npc/enemies/enemy-perception-data.gd](../../data/npc/enemies/enemy-perception-data.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/enemies.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `detection_range` | `float` | Perception scan range, positive ≤10000. | Conditional/optional | `620` | `@export`; see guide for runtime constraints. | [enemy-detection](../../components/NPCs/enemies/enemy-detection.gd) |
| `sight_memory` | `float` | Seconds remembering a lost visible target. | Conditional/optional | `2.5` | `@export`; see guide for runtime constraints. | [enemy-detection](../../components/NPCs/enemies/enemy-detection.gd) |
| `scan_interval` | `float` | Perception scan cadence, at least .05. | Conditional/optional | `0.2` | `@export`; see guide for runtime constraints. | [enemy-detection](../../components/NPCs/enemies/enemy-detection.gd) |
| `max_candidates` | `int` | Candidate bound 1–64. | Conditional/optional | `16` | `@export_range(1, 64)`; see guide for runtime constraints. | [enemy-detection](../../components/NPCs/enemies/enemy-detection.gd) |
| `terrain_mask` | `int` | Perception occlusion bits; combat LOS has its own fixed terrain mask. | Conditional/optional | `16` | `@export_flags_2d_physics`; see guide for runtime constraints. | [enemy-detection](../../components/NPCs/enemies/enemy-detection.gd) |
| `target_groups` | `Array[StringName]` | SceneTree groups searched for eligible targets. | Conditional/optional | `[&"player", &"combat_target"]` | `@export`; see guide for runtime constraints. | [enemy-detection](../../components/NPCs/enemies/enemy-detection.gd) |
| `relations` | `Dictionary[StringName, int]` | Other faction → -1 hostile / 0 neutral / 1 allied; same faction allied. | Conditional/optional | `{&"neutral": 0}` | `@export`; see guide for runtime constraints. | [enemy-detection](../../components/NPCs/enemies/enemy-detection.gd) |
| `threat_decay` | `float` | Decay of accumulated threat per second. | Conditional/optional | `2` | `@export`; see guide for runtime constraints. | [enemy-detection](../../components/NPCs/enemies/enemy-detection.gd) |

## EnemyStatsData

Source: [data/npc/enemies/enemy-stats-data.gd](../../data/npc/enemies/enemy-stats-data.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/enemies.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `max_health` | `float` | Positive starting/max HP; runtime HP is not written into the Resource. | Conditional/optional | `100` | `@export`; see guide for runtime constraints. | [enemy-stats-component](../../components/NPCs/enemies/enemy-stats-component.gd) |
| `max_mana` | `float` | Mana capacity/initial value; 0 means no mana pool for ordinary enemy. | Conditional/optional | `400` | `@export`; see guide for runtime constraints. | [enemy-stats-component](../../components/NPCs/enemies/enemy-stats-component.gd) |
| `health_regen` | `float` | Health per second after configured regen delay. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [enemy-stats-component](../../components/NPCs/enemies/enemy-stats-component.gd) |
| `mana_regen` | `float` | Mana per second; enemy stat service also considers drain and regen delay. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [enemy-stats-component](../../components/NPCs/enemies/enemy-stats-component.gd) |
| `regen_delay` | `float` | Post-damage/mana-spend delay before passive regeneration. | Conditional/optional | `2` | `@export`; see guide for runtime constraints. | [enemy-stats-component](../../components/NPCs/enemies/enemy-stats-component.gd) |
| `move_speed` | `float` | Phase/enemy move/patrol speed. | Conditional/optional | `80` | `@export`; see guide for runtime constraints. | [enemy-stats-component](../../components/NPCs/enemies/enemy-stats-component.gd) |
| `chase_speed` | `float` | Phase/enemy chase speed; boss dash scales this. | Conditional/optional | `140` | `@export`; see guide for runtime constraints. | [enemy-stats-component](../../components/NPCs/enemies/enemy-stats-component.gd) |
| `defense` | `float` | Flat incoming damage reduction; negative phase override preserves boss base. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [enemy-stats-component](../../components/NPCs/enemies/enemy-stats-component.gd) |
| `incoming_multiplier` | `float` | Incoming damage multiplier; negative phase override preserves boss base. | Conditional/optional | `1` | `@export`; see guide for runtime constraints. | [enemy-stats-component](../../components/NPCs/enemies/enemy-stats-component.gd) |
| `outgoing_multiplier` | `float` | Outgoing damage metadata consumed by cast/combat context. | Conditional/optional | `1` | `@export`; see guide for runtime constraints. | [enemy-stats-component](../../components/NPCs/enemies/enemy-stats-component.gd) |
| `knockback_resistance` | `float` | 0–1 fractional reduction of knockback. | Conditional/optional | `0` | `@export_range(0, 1)`; see guide for runtime constraints. | [enemy-stats-component](../../components/NPCs/enemies/enemy-stats-component.gd) |
| `status_resistances` | `Dictionary[String, float]` | Status key → 0–1 duration resistance; 1 refuses application through apply_status. | Conditional/optional | `{}` | `@export`; see guide for runtime constraints. | [enemy-stats-component](../../components/NPCs/enemies/enemy-stats-component.gd) |

## FieldData

Source: [data/Resources/ilmu/field.gd](../../data/Resources/ilmu/field.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/fields.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `field_id` | `StringName` | Stable academic key, including comprehension dictionary matching. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [spell-validator](../../components/spells/spell-validator.gd) |
| `display_name` | `String` | Human-readable label; NPC presentation also uses fallback resolution. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/field.gd) |
| `description` | `String` | Authored explanatory text, not a gameplay handler. | Conditional/optional | `Godot type default` | `@export_multiline`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/field.gd) |
| `related_field_ids` | `Array[StringName]` | Academic relationship metadata; no automatic prerequisite/bonus resolution. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/field.gd) |

## HealEffect

Source: [data/Resources/spell-effects/heal-effect.gd](../../data/Resources/spell-effects/heal-effect.gd). Base: `SpellEffectDefinition`. [Canonical authoring and validation](../authoring/spell-effects.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `amount` | `float` | Payload magnitude; exact stat/damage/heal/chain semantics are in the effect guide. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/heal-effect.gd) |
| `duration` | `float` | Effect/trigger lifetime in seconds; validate per subclass. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/heal-effect.gd) |
| `tick_interval` | `float` | Periodic interval; effect validators require at least .05 seconds. | Conditional/optional | `1.0` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/heal-effect.gd) |

## InterruptEffect

Source: [data/Resources/spell-effects/interrupt-effect.gd](../../data/Resources/spell-effects/interrupt-effect.gd). Base: `SpellEffectDefinition`. [Canonical authoring and validation](../authoring/spell-effects.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| — | — | No exported fields; runtime contract in methods. | — | — | — | [Source](../../data/Resources/spell-effects/interrupt-effect.gd) |

## ItemData

Source: [data/items/item-data.gd](../../data/items/item-data.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/items-and-loot.md).

Enum `ItemType`: `CONSUMABLE`, `EQUIPMENT`, `KEY_ITEM`, `QUEST_ITEM`, `MATERIAL`, `COMPONENT`, `FOOD`, `WEAPON_MATERIAL`, `RARE_MATERIAL`.

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `item_id` | `String` | Stable registry/inventory/save/event identifier. | Required | `""` | `@export`; see guide for runtime constraints. | [inventory-manager](../../autoloads/inventory-manager.gd), [crafting-ui](../../scenes/crafting-room/crafting-ui.gd) |
| `item_name` | `String` | Visible inventory/loot/recipe label. | Required | `""` | `@export`; see guide for runtime constraints. | [crafting-ui](../../scenes/crafting-room/crafting-ui.gd) |
| `item_icon` | `Texture2D` | Inventory/loot/quest presentation texture. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/items/item-data.gd) |
| `item_type` | `ItemType` | Authored category enum, not a generic gear/use implementation. | Conditional/optional | `ItemType.CONSUMABLE` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/items/item-data.gd) |
| `description` | `String` | Authored explanatory text, not a gameplay handler. | Conditional/optional | `""` | `@export_multiline`; see guide for runtime constraints. | [Schema / methods](../../data/items/item-data.gd) |
| `is_stackable` | `bool` | False limits effective stack to one. | Conditional/optional | `true` | `@export`; see guide for runtime constraints. | [inventory-manager](../../autoloads/inventory-manager.gd) |
| `max_stack` | `int` | Positive per-ID stack capacity when stackable. | Required | `99` | `@export`; see guide for runtime constraints. | [inventory-manager](../../autoloads/inventory-manager.gd), [quest-registry](../../components/quests/quest-registry.gd) |
| `ringgit_value` | `float` | **Metadata/legacy or unused in current execution.** Authored sell/value metadata; no implemented shop transaction consumes it. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/items/item-data.gd) |
| `is_sellable` | `bool` | **Metadata/legacy or unused in current execution.** Authored sale eligibility metadata; no implemented shop transaction consumes it. | Conditional/optional | `true` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/items/item-data.gd) |
| `health_restore` | `int` | Health restored per accepted pickup quantity, not on arbitrary inventory additions. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [inventory-manager](../../autoloads/inventory-manager.gd) |
| `mana_restore` | `float` | Mana restored per accepted pickup quantity. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [inventory-manager](../../autoloads/inventory-manager.gd) |
| `exp_reward` | `int` | XP per accepted pickup, or legacy enemy death XP through adapter (class dependent). | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [inventory-manager](../../autoloads/inventory-manager.gd) |
| `spell_to_unlock` | `SpellData` | Spell learned through pickup hook; no automatic equipment. | Conditional/optional | `null` | `@export`; see guide for runtime constraints. | [inventory-manager](../../autoloads/inventory-manager.gd) |
| `quest_objective_ids` | `Array[String]` | **Metadata/legacy or unused in current execution.** Legacy compatibility metadata; current pickups publish actual item IDs/tags. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/items/item-data.gd) |
| `ingredient_1` | `ItemData` | Recipe input ItemData reference; null means unused input slot. | Conditional/optional | `null` | `@export`; see guide for runtime constraints. | [crafting-ui](../../scenes/crafting-room/crafting-ui.gd) |
| `qty_1` | `int` | Recipe input positive quantity; 0 for unused null ingredient. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [crafting-ui](../../scenes/crafting-room/crafting-ui.gd) |
| `ingredient_2` | `ItemData` | Recipe input ItemData reference; null means unused input slot. | Conditional/optional | `null` | `@export`; see guide for runtime constraints. | [crafting-ui](../../scenes/crafting-room/crafting-ui.gd) |
| `qty_2` | `int` | Recipe input positive quantity; 0 for unused null ingredient. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [crafting-ui](../../scenes/crafting-room/crafting-ui.gd) |
| `ingredient_3` | `ItemData` | Recipe input ItemData reference; null means unused input slot. | Conditional/optional | `null` | `@export`; see guide for runtime constraints. | [crafting-ui](../../scenes/crafting-room/crafting-ui.gd) |
| `qty_3` | `int` | Recipe input positive quantity; 0 for unused null ingredient. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [crafting-ui](../../scenes/crafting-room/crafting-ui.gd) |
| `tags` | `Array[StringName]` | Semantic event/filter tags; not automatic mechanics. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [inventory-manager](../../autoloads/inventory-manager.gd) |

## KnockbackEffect

Source: [data/Resources/spell-effects/knockback-effect.gd](../../data/Resources/spell-effects/knockback-effect.gd). Base: `SpellEffectDefinition`. [Canonical authoring and validation](../authoring/spell-effects.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `force` | `float` | Knockback impulse magnitude, finite nonnegative. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/knockback-effect.gd) |

## LootData

Source: [data/loot/loot-data.gd](../../data/loot/loot-data.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/items-and-loot.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `item` | `ItemData` | Required LootData item reference. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [enemy-loot-component](../../components/NPCs/enemies/enemy-loot-component.gd), [dropped-item](../../components/loot/dropped-item/dropped-item.gd) |
| `drop_chance` | `float` | Independent death roll probability 0–1; fixed quest rewards do not roll it. | Conditional/optional | `0.5` | `@export_range(0, 1.0)`; see guide for runtime constraints. | [enemy-loot-component](../../components/NPCs/enemies/enemy-loot-component.gd) |
| `min_quantity` | `int` | Inclusive drop lower bound; equal min/max required for quest rewards. | Conditional/optional | `1` | `@export`; see guide for runtime constraints. | [enemy-loot-component](../../components/NPCs/enemies/enemy-loot-component.gd), [quest-reward-service](../../components/quests/quest-reward-service.gd) |
| `max_quantity` | `int` | Inclusive upper bound, ≥min and ≤9999; fixed rewards require equal bounds. | Conditional/optional | `1` | `@export`; see guide for runtime constraints. | [enemy-loot-component](../../components/NPCs/enemies/enemy-loot-component.gd) |
| `extra_drops` | `Array[ItemData]` | Explicit bundled item refs sharing parent roll and quantity bounds. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [enemy-loot-component](../../components/NPCs/enemies/enemy-loot-component.gd) |
| `rarity_color` | `Color` | Tint applied to physical loot particles. | Conditional/optional | `Color.WHITE` | `@export`; see guide for runtime constraints. | [dropped-item](../../components/loot/dropped-item/dropped-item.gd) |
| `rarity` | `int` | **Metadata/legacy or unused in current execution.** Common/Uncommon/Rare/Epic label metadata; no automatic tier probability mechanic. | Conditional/optional | `0` | `@export_enum("Common", "Uncommon", "Rare", "Epic")`; see guide for runtime constraints. | [Schema / methods](../../data/loot/loot-data.gd) |

## ModifyStatEffect

Source: [data/Resources/spell-effects/modify-stat-effect.gd](../../data/Resources/spell-effects/modify-stat-effect.gd). Base: `SpellEffectDefinition`. [Canonical authoring and validation](../authoring/spell-effects.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `stat` | `String` | One of speed/damage/mana_regen/defense/cast_speed/dash_charges. | Conditional/optional | `"speed"` | `@export_enum("speed", "damage", "mana_regen", "defense", "cast_speed", "dash_charges")`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/modify-stat-effect.gd) |
| `amount` | `float` | Payload magnitude; exact stat/damage/heal/chain semantics are in the effect guide. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/modify-stat-effect.gd) |
| `duration` | `float` | Effect/trigger lifetime in seconds; validate per subclass. | Conditional/optional | `1.0` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/modify-stat-effect.gd) |
| `stacking` | `ActiveEffectManager.StackPolicy` | REFRESH/REPLACE/STACK/IGNORE; manager counts independent entries. | Conditional/optional | `ActiveEffectManager.StackPolicy.REFRESH` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/modify-stat-effect.gd) |
| `max_stacks` | `int` | Maximum independent stacks; configured policies and manager cap apply. | Conditional/optional | `1` | `@export_range(1, 32)`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/modify-stat-effect.gd) |
| `on_hit_proc_id` | `String` | Stored proc metadata; no generic on-hit proc dispatcher is implemented. | Conditional/optional | `""` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/modify-stat-effect.gd) |

## NPCPresentation

Source: [data/npc/npc-presentation.gd](../../data/npc/npc-presentation.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/npcs-and-dialogue.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `npc_id` | `String` | Stable giver/contact/event identity; distinct from dialogue portrait ID. | Required | `""` | `@export`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd) |
| `display_name` | `String` | Human-readable label; NPC presentation also uses fallback resolution. | Required | `"Quest giver"` | `@export`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd) |
| `portrait` | `Texture2D` | Optional fallback portrait texture. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/npc/npc-presentation.gd) |
| `dialogic_character` | `Resource` | Optional compatible Dialogic Resource exposing portrait/default_portrait data. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/npc/npc-presentation.gd) |
| `dialogue_identity` | `String` | Portrait/timeline selector distinct from NPC ID when needed. | Conditional/optional | `""` | `@export`; see guide for runtime constraints. | [quest-npc-component](../../components/NPCs/quest-npc-component.gd) |
| `offer_dialogue` | `String` | Presentation-level offer text override. | Conditional/optional | `""` | `@export_multiline`; see guide for runtime constraints. | [quest-npc-component](../../components/NPCs/quest-npc-component.gd), [quest-manager](../../autoloads/quest-manager.gd) |
| `accepted` | `String` | Default explicit acceptance reaction. | Conditional/optional | `"Alright! I'll be counting on you. Come back when you've finished."` | `@export_multiline`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd) |
| `declined` | `String` | Default explicit decline reaction. | Conditional/optional | `"No worries! Come find me if you change your mind."` | `@export_multiline`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd) |
| `reoffer_cooldown` | `float` | Temporary reoffer delay after decline; no save of live offer tokens. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd) |

## NPCSpawnValidator

Source: [components/NPCs/npc-spawn-validator.gd](../../components/NPCs/npc-spawn-validator.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/npcs-and-dialogue.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `allowed_region` | `Rect2 (inferred)` | NPC placement bounds relative to spawner. | Conditional/optional | `Rect2(-800, -400, 1600, 800)` | `@export`; see guide for runtime constraints. | [npc-quest-spawner](../../components/NPCs/enemies/spawner/npc-quest-spawner.gd) |
| `body_size` | `Vector2 (inferred)` | NPC placement footprint in world units. | Conditional/optional | `Vector2(84, 236)` | `@export`; see guide for runtime constraints. | [Schema / methods](../../components/NPCs/npc-spawn-validator.gd) |
| `obstacle_margin` | `float` | Extra obstacle-clearance margin. | Conditional/optional | `12` | `@export`; see guide for runtime constraints. | [Schema / methods](../../components/NPCs/npc-spawn-validator.gd) |
| `interaction_clearance` | `float` | Required adjacent full-height player approach lane width. | Conditional/optional | `90` | `@export`; see guide for runtime constraints. | [Schema / methods](../../components/NPCs/npc-spawn-validator.gd) |
| `minimum_separation` | `float` | Minimum spacing from other placed NPC centers. | Conditional/optional | `240` | `@export`; see guide for runtime constraints. | [Schema / methods](../../components/NPCs/npc-spawn-validator.gd) |
| `max_attempts` | `int` | Number of additional random placement candidates. | Conditional/optional | `24` | `@export`; see guide for runtime constraints. | [Schema / methods](../../components/NPCs/npc-spawn-validator.gd) |
| `solid_mask` | `int` | Terrain bits for NPC ground/obstacle checks. | Conditional/optional | `16` | `@export_flags_2d_physics`; see guide for runtime constraints. | [Schema / methods](../../components/NPCs/npc-spawn-validator.gd) |
| `ground_search` | `float` | Maximum downward ground ray distance. | Conditional/optional | `500` | `@export`; see guide for runtime constraints. | [Schema / methods](../../components/NPCs/npc-spawn-validator.gd) |
| `max_step` | `float` | Maximum accepted walking/support height difference. | Conditional/optional | `36` | `@export`; see guide for runtime constraints. | [Schema / methods](../../components/NPCs/npc-spawn-validator.gd) |
| `fallback_enabled` | `bool` | Append fallback feet candidate; safety checks still apply. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [Schema / methods](../../components/NPCs/npc-spawn-validator.gd) |
| `fallback_feet` | `Vector2 (inferred)` | Local feet position used only when fallback enabled. | Conditional/optional | `Vector2.ZERO` | `@export`; see guide for runtime constraints. | [Schema / methods](../../components/NPCs/npc-spawn-validator.gd) |

## NPCSpellcasterData

Source: [data/Resources/spellcaster-npc.gd](../../data/Resources/spellcaster-npc.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/additional-systems.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `caster_name` | `String` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. Human-readable authored name for this definition. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |
| `caster_id` | `String` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. Stable authored identifier; match parent/registry/event references exactly. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |
| `race` | `String` | **Metadata/legacy or unused in current execution.** Legacy authored species label; not consumed by EnemyDefinitionAdapter. | Conditional/optional | `"Kocheen"` | `@export_enum("Kocheen", "Ancheen", "Moshang", "Sarigala", "Baruang", "Arnobs")`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/spellcaster-npc.gd) |
| `magis_archetype` | `String` | **Legacy metadata, unused by the adapter.** Authored caster identity/classification label. | Conditional/optional | `"Mana Manipulation"` | `@export_enum("Mana Manipulation", "Technical", "Alnur", "Alzalam", "Celestial")`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/spellcaster-npc.gd) |
| `magis_comprehension` | `String` | **Legacy metadata, unused by the adapter.** Authored caster identity/classification label. | Conditional/optional | `"Novice"` | `@export_enum("Novice", "Intermediate", "Advanced", "Expert")`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/spellcaster-npc.gd) |
| `portrait` | `Texture2D` | **Metadata/legacy or unused in current execution.** Optional fallback portrait texture. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/spellcaster-npc.gd) |
| `max_hp` | `float` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. Legacy initial HP mapped to EnemyStatsData.max_health. | Conditional/optional | `100.0` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |
| `hp_regen_rate` | `float` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. Legacy HP regeneration mapped to EnemyStatsData.health_regen. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |
| `base_defense` | `float` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. Legacy flat mitigation mapped to EnemyStatsData.defense. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |
| `base_mana_shield` | `float` | **Metadata/legacy or unused in current execution.** Legacy authored shield amount; adapter does not implement mana shielding. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/spellcaster-npc.gd) |
| `max_mana` | `float` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. Mana capacity/initial value; 0 means no mana pool for ordinary enemy. | Conditional/optional | `100.0` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |
| `mana_regen_rate` | `float` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. Legacy mana regeneration mapped to EnemyStatsData.mana_regen. | Conditional/optional | `5.0` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |
| `mana_regen_delay` | `float` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. Legacy delay mapped to EnemyStatsData.regen_delay. | Conditional/optional | `2.0` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |
| `low_mana_threshold` | `float` | **Metadata/legacy or unused in current execution.** Legacy threshold metadata; utility recovery uses its own current logic. | Conditional/optional | `0.25` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/spellcaster-npc.gd) |
| `spell_pool` | `Array[SpellData]` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. Legacy spell references converted into authorized EnemyAbilityData entries. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |
| `preferred_spell_types` | `Array[String]` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. Legacy SpellType names that increase converted ability preference weight. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |
| `forbidden_spell_types` | `Array[String]` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. Legacy SpellType names omitted from converted loadout. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |
| `move_speed` | `float` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. Phase/enemy move/patrol speed. | Conditional/optional | `120.0` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |
| `preferred_range` | `float` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. Desired engagement range, adjusted for pure-melee reach. | Conditional/optional | `250.0` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |
| `too_close_threshold` | `float` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. Legacy retreat range mapped to copied cautious-spellcaster profile. | Conditional/optional | `80.0` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |
| `aggression` | `float` | **Metadata/legacy or unused in current execution.** Legacy authored aggression; not mapped into utility weights by the adapter. | Conditional/optional | `0.5` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/spellcaster-npc.gd) |
| `react_window` | `float` | **Metadata/legacy or unused in current execution.** Legacy reaction timing; no delayed-reaction handler in current adapter. | Conditional/optional | `0.4` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/spellcaster-npc.gd) |
| `cast_delay_min` | `float` | **Metadata/legacy or unused in current execution.** Legacy minimum delay metadata; not mapped into current ability timings. | Conditional/optional | `0.3` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/spellcaster-npc.gd) |
| `cast_delay_max` | `float` | **Metadata/legacy or unused in current execution.** Legacy maximum delay metadata; not mapped into current ability timings. | Conditional/optional | `1.2` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/spellcaster-npc.gd) |
| `combo_chance` | `float` | **Metadata/legacy or unused in current execution.** Legacy probability metadata; no automatic combo handler is installed. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/spellcaster-npc.gd) |
| `counter_chance` | `float` | **Metadata/legacy or unused in current execution.** Legacy probability metadata; no automatic counter handler is installed. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/spellcaster-npc.gd) |
| `stun_resistance` | `float` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. Legacy duration resistance mapped to stun key in EnemyStatsData. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |
| `dot_resistance` | `float` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. Legacy duration resistance mapped to dot key in EnemyStatsData. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |
| `impairment_resistance` | `float` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. Legacy duration resistance mapped to slow key in EnemyStatsData. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |
| `drops_spell_on_defeat` | `bool` | **Metadata/legacy or unused in current execution.** Legacy toggle; adapter does not install a spell-drop hook. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/spellcaster-npc.gd) |
| `dropped_spell` | `SpellData` | **Metadata/legacy or unused in current execution.** Legacy referenced spell; not granted/dropped by the V2 adapter. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/spellcaster-npc.gd) |
| `exp_reward` | `int` | Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. XP per accepted pickup, or legacy enemy death XP through adapter (class dependent). | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [enemy-definition-adapter](../../components/NPCs/enemies/enemy-definition-adapter.gd) |

## ProjectileFieldEffect

Source: [data/Resources/spell-effects/projectile-field-effect.gd](../../data/Resources/spell-effects/projectile-field-effect.gd). Base: `SpellEffectDefinition`. [Canonical authoring and validation](../authoring/spell-effects.md).

Enum `Mode`: `REVERSE`, `ATTRACT`, `SLOW`, `CANCEL`.

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `mode` | `Mode` | Subclass enum selects existing behavior; adding an enum alone does not implement it. | Conditional/optional | `Mode.REVERSE` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/projectile-field-effect.gd) |
| `radius` | `float` | Effect search/field radius; finite constraints depend on subclass. | Conditional/optional | `150.0` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/projectile-field-effect.gd) |
| `strength` | `float` | Vector/projectile field magnitude; DAMP/SLOW have specialized fractional semantics. | Conditional/optional | `0.3` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/projectile-field-effect.gd) |

## QuestData

Source: [data/quests/quest-data.gd](../../data/quests/quest-data.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/quests.md).

Enum `QuestType`: `MAIN`, `SIDE`, `FACTION`, `DEFEAT`, `FETCH`.
Enum `Faculty`: `NONE`, `PHYSICS`, `COMPUTER_SCIENCE`, `ENGINEERING`, `MEDICINE`, `LAW`, `TECHNOLOGY_SCIENCE`.

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `quest_id` | `String` | Stable quest registry/instance/reward-claim identity. | Required | `""` | `@export`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd), [quest-reward-service](../../components/quests/quest-reward-service.gd) |
| `title` | `String` | Quest visible title, required by registry. | Required | `""` | `@export`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd), [quest-registry](../../components/quests/quest-registry.gd) |
| `description` | `String` | Authored explanatory text, not a gameplay handler. | Conditional/optional | `""` | `@export`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd) |
| `type` | `QuestType` | Quest/objective enum; objective selects evaluator behavior, quest type is classification. | Conditional/optional | `QuestType.SIDE` | `@export`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd), [quest-reward-service](../../components/quests/quest-reward-service.gd) |
| `faculty` | `Faculty` | Quest/NPC offering faculty enum; does not auto-register a database. | Conditional/optional | `Faculty.NONE` | `@export`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd), [quest-registry](../../components/quests/quest-registry.gd) |
| `despawn_after_seconds` | `float` | Available offer/NPC-instance despawn timer setting, separate from active expiry. | Conditional/optional | `60.0` | `@export`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd) |
| `objectives` | `Array[QuestObjectiveData]` | Nonempty QuestObjectiveData array with unique local IDs. | Required | `[]` | `@export`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd), [quest-reward-service](../../components/quests/quest-reward-service.gd) |
| `reward_xp` | `int` | Nonnegative XP in the centralized once-only claim transaction. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd), [quest-reward-service](../../components/quests/quest-reward-service.gd) |
| `reward_currency` | `int` | Nonnegative currency in the centralized claim transaction. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd), [quest-reward-service](../../components/quests/quest-reward-service.gd) |
| `reward_items` | `Array[LootData]` | Fixed unbundled LootData rewards using registered item identities. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [quest-reward-service](../../components/quests/quest-reward-service.gd), [quest-registry](../../components/quests/quest-registry.gd) |
| `prerequisite_quest_ids` | `Array[String]` | Registered completed quest IDs required before offering/acceptance. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd), [quest-registry](../../components/quests/quest-registry.gd) |
| `next_quest_id` | `String` | Registered next quest offered for explicit acceptance after commit. | Conditional/optional | `""` | `@export`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd), [quest-registry](../../components/quests/quest-registry.gd) |
| `region_id` | `StringName` | Catalogue/board region filter. | Conditional/optional | `&"flac"` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/quests/quest-data.gd) |
| `pool_id` | `StringName` | Authored quest pool metadata; no new automatic pool picker by itself. | Conditional/optional | `&""` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/quests/quest-data.gd) |
| `tags` | `Array[StringName]` | Semantic event/filter tags; not automatic mechanics. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [quest-reward-service](../../components/quests/quest-reward-service.gd) |
| `repeatable` | `bool` | Allow new completed-quest instances subject to per-instance claim guards. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd), [quest-reward-service](../../components/quests/quest-reward-service.gd) |
| `hand_in_npc_id` | `String` | Required giver ID; empty uses assigned NPC. | Conditional/optional | `""` | `@export`; see guide for runtime constraints. | [quest-reward-service](../../components/quests/quest-reward-service.gd) |
| `auto_accept_next` | `bool` | **Metadata/legacy or unused in current execution.** Serialized compatibility flag; next quests still need explicit acceptance. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/quests/quest-data.gd) |
| `expires_after_seconds` | `float` | Optional active quest wall-clock expiry; 0 disables it. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd), [quest-registry](../../components/quests/quest-registry.gd) |
| `objective_groups` | `Array[QuestObjectiveGroup]` | ALL/ANY group definitions for matching objective group_id. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [quest-reward-service](../../components/quests/quest-reward-service.gd), [quest-instance](../../components/quest-manager/quest-instance.gd) |
| `reward_spells` | `Array[SpellData]` | Registered spells learned by the existing reward transaction. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [quest-reward-service](../../components/quests/quest-reward-service.gd), [quest-registry](../../components/quests/quest-registry.gd) |
| `reward_flags` | `Dictionary[StringName, bool]` | Boolean durable world flags set by claim. | Conditional/optional | `{}` | `@export`; see guide for runtime constraints. | [quest-reward-service](../../components/quests/quest-reward-service.gd) |
| `dialogue_offer` | `String` | Authored offer text, subject to NPC presentation override/fallback policy. | Conditional/optional | `""` | `@export_multiline`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd) |
| `dialogue_incomplete` | `String` | Text for active incomplete objectives. | Conditional/optional | `""` | `@export_multiline`; see guide for runtime constraints. | [Schema / methods](../../data/quests/quest-data.gd) |
| `dialogue_complete` | `String` | Text after successful hand-in. | Conditional/optional | `""` | `@export_multiline`; see guide for runtime constraints. | [Schema / methods](../../data/quests/quest-data.gd) |
| `dialogue_accepted` | `String` | Quest-specific explicit acceptance reaction. | Conditional/optional | `""` | `@export_multiline`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd) |
| `dialogue_declined` | `String` | Quest-specific explicit decline reaction. | Conditional/optional | `""` | `@export_multiline`; see guide for runtime constraints. | [quest-manager](../../autoloads/quest-manager.gd) |

## QuestDatabase

Source: [data/quests/quest-database.gd](../../data/quests/quest-database.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/quests.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `quests` | `Array[QuestData]` | QuestData references; only registry-loaded databases become authoritative catalogue. | Required | `[]` | `@export`; see guide for runtime constraints. | [quest-registry](../../components/quests/quest-registry.gd), [quest-board](../../components/quests/quest-board.gd) |

## QuestObjectiveData

Source: [data/quests/quest-objective-data.gd](../../data/quests/quest-objective-data.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/quests.md).

Enum `ObjectiveType`: `TALK_TO_NPC`, `COLLECT_ITEM`, `DEFEAT_ENEMY`, `REACH_LOCATION`, `SPELL_CAST`, `SPELL_HIT`, `STATUS_APPLIED`, `OBJECT_INTERACTED`, `QUEST_COMPLETED`, `WORLD_FLAG_CHANGED`, `DIALOGUE_COMPLETED`.
Enum `CollectionMode`: `CUMULATIVE`, `CURRENT_HELD`, `DELIVERY`.

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `objective_id` | `String` | Stable progress key unique within one quest. | Required | `""` | `@export`; see guide for runtime constraints. | [quest-objective-evaluator](../../components/quests/quest-objective-evaluator.gd), [quest-instance](../../components/quest-manager/quest-instance.gd) |
| `description` | `String` | Authored explanatory text, not a gameplay handler. | Conditional/optional | `""` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/quests/quest-objective-data.gd) |
| `type` | `ObjectiveType` | Quest/objective enum; objective selects evaluator behavior, quest type is classification. | Required | `ObjectiveType.TALK_TO_NPC` | `@export`; see guide for runtime constraints. | [quest-objective-evaluator](../../components/quests/quest-objective-evaluator.gd), [quest-registry](../../components/quests/quest-registry.gd) |
| `is_optional` | `bool` | Optional objective/group excluded from mandatory completion. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [quest-objective-evaluator](../../components/quests/quest-objective-evaluator.gd), [quest-instance](../../components/quest-manager/quest-instance.gd) |
| `target_id` | `String` | Exact event target identity, unioned with target_ids. | Conditional/optional | `""` | `@export`; see guide for runtime constraints. | [quest-objective-evaluator](../../components/quests/quest-objective-evaluator.gd) |
| `required_amount` | `int` | Positive objective bound, up to 1000000 in registry validation. | Required | `1` | `@export`; see guide for runtime constraints. | [quest-objective-evaluator](../../components/quests/quest-objective-evaluator.gd), [quest-instance](../../components/quest-manager/quest-instance.gd) |
| `requires_objectives` | `Array[String]` | Objective prerequisite IDs; cycles rejected. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [quest-instance](../../components/quest-manager/quest-instance.gd), [quest-registry](../../components/quests/quest-registry.gd) |
| `collection_mode` | `CollectionMode` | CUMULATIVE acquisition vs CURRENT_HELD vs consuming DELIVERY. | Conditional/optional | `CollectionMode.CUMULATIVE` | `@export`; see guide for runtime constraints. | [quest-objective-evaluator](../../components/quests/quest-objective-evaluator.gd), [quest-registry](../../components/quests/quest-registry.gd) |
| `target_ids` | `Array[String]` | Explicit union of alternative target identities. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/quests/quest-objective-data.gd) |
| `target_tags` | `Array[StringName]` | Any matching event tag can match cumulative event objectives. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [quest-objective-evaluator](../../components/quests/quest-objective-evaluator.gd), [quest-registry](../../components/quests/quest-registry.gd) |
| `match_metadata` | `Dictionary` | All configured event metadata key/value constraints must match. | Conditional/optional | `{}` | `@export`; see guide for runtime constraints. | [quest-objective-evaluator](../../components/quests/quest-objective-evaluator.gd) |
| `group_id` | `StringName` | Objective group identity / membership reference. | Conditional/optional | `&""` | `@export`; see guide for runtime constraints. | [quest-instance](../../components/quest-manager/quest-instance.gd), [quest-registry](../../components/quests/quest-registry.gd) |

## QuestObjectiveGroup

Source: [data/quests/quest-objective-group.gd](../../data/quests/quest-objective-group.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/quests.md).

Enum `Policy`: `ALL`, `ANY`.

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `group_id` | `StringName` | Objective group identity / membership reference. | Required | `&""` | `@export`; see guide for runtime constraints. | [quest-instance](../../components/quest-manager/quest-instance.gd), [quest-registry](../../components/quests/quest-registry.gd) |
| `policy` | `Policy` | ALL or ANY required group members. | Conditional/optional | `Policy.ALL` | `@export`; see guide for runtime constraints. | [quest-instance](../../components/quest-manager/quest-instance.gd), [quest-registry](../../components/quests/quest-registry.gd) |
| `minimum_completed` | `int` | Positive ANY requirement; registry checks satisfiability. | Conditional/optional | `1` | `@export`; see guide for runtime constraints. | [quest-instance](../../components/quest-manager/quest-instance.gd), [quest-registry](../../components/quests/quest-registry.gd) |
| `is_optional` | `bool` | Optional objective/group excluded from mandatory completion. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [quest-instance](../../components/quest-manager/quest-instance.gd), [quest-registry](../../components/quests/quest-registry.gd) |

## RemoveStatusEffect

Source: [data/Resources/spell-effects/remove-status-effect.gd](../../data/Resources/spell-effects/remove-status-effect.gd). Base: `SpellEffectDefinition`. [Canonical authoring and validation](../authoring/spell-effects.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `respect_teams` | `bool` | Gate category clears by ally/hostile; named status removal is independent. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/remove-status-effect.gd) |
| `status` | `String` | Existing handler/marker key; not a new mechanic implementation by itself. | Conditional/optional | `""` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/remove-status-effect.gd) |
| `remove_buffs` | `bool` | Clear beneficial entries, respecting team option if requested. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/remove-status-effect.gd) |
| `remove_debuffs` | `bool` | Clear negative entries, respecting team option if requested. | Conditional/optional | `true` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/remove-status-effect.gd) |

## ReplayEffect

Source: [data/Resources/spell-effects/replay-effect.gd](../../data/Resources/spell-effects/replay-effect.gd). Base: `SpellEffectDefinition`. [Canonical authoring and validation](../authoring/spell-effects.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| — | — | No exported fields; runtime contract in methods. | — | — | — | [Source](../../data/Resources/spell-effects/replay-effect.gd) |

## SceneData

Source: [data/Resources/worlds/scene-data.gd](../../data/Resources/worlds/scene-data.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/worlds-and-scenes.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `scene_id` | `String` | Stable trusted SceneData key, or registered destination key on ElevatorFloor. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [scene-registry](../../autoloads/scene-registry.gd) |
| `scene` | `PackedScene` | SceneData destination or SpawnEntityEffect Node2D template; parent-specific contract. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [scene-registry](../../autoloads/scene-registry.gd), [zone-root](../../data/worlds/zone-root.gd) |
| `scene_name` | `String` | Location display label. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [zone-root](../../data/worlds/zone-root.gd) |
| `default_spawn_marker` | `String` | Elevator fallback marker; ordinary ZoneRoot searches PlayerSpawn itself. | Conditional/optional | `"PlayerSpawn"` | `@export`; see guide for runtime constraints. | [elevator-portal](../../components/elevator/elevator-portal.gd) |
| `description` | `String` | Authored explanatory text, not a gameplay handler. | Conditional/optional | `Godot type default` | `@export_multiline`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/worlds/scene-data.gd) |

## SpawnData

Source: [data/npc/enemies/spawn/spawn-data.gd](../../data/npc/enemies/spawn/spawn-data.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/enemies.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `enemy_scene` | `PackedScene` | Required Enemy-derived PackedScene for spawner entry. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [enemy-spawner](../../components/NPCs/enemies/spawner/enemy-spawner.gd) |
| `spawn_weight` | `float` | Positive relative spawner selection weight; zero entries are skipped. | Conditional/optional | `10.0` | `@export_range(0, 100)`; see guide for runtime constraints. | [enemy-spawner](../../components/NPCs/enemies/spawner/enemy-spawner.gd) |
| `enemy_data` | `EnemyData` | Optional SpawnData override, applied before Enemy._ready. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [enemy-spawner](../../components/NPCs/enemies/spawner/enemy-spawner.gd) |

## SpawnEntityEffect

Source: [data/Resources/spell-effects/spawn-entity-effect.gd](../../data/Resources/spell-effects/spawn-entity-effect.gd). Base: `SpellEffectDefinition`. [Canonical authoring and validation](../authoring/spell-effects.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `scene` | `PackedScene` | SceneData destination or SpawnEntityEffect Node2D template; parent-specific contract. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/spawn-entity-effect.gd) |
| `offset` | `Vector2` | Finite spawn offset relative to target. | Conditional/optional | `Vector2.ZERO` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/spawn-entity-effect.gd) |
| `children` | `Array[SpellEffectDefinition]` | Nested ordered effects under the same execution/context contract. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/spawn-entity-effect.gd) |

## SpellData

Source: [data/Resources/ilmu/spell.gd](../../data/Resources/ilmu/spell.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/spells.md).

Enum `SpellCategory`: `PROJECTILE`, `AOE`, `HEALING`, `BUFF`, `DECAST`.
Enum `SpellType`: `OFFENSIVE`, `DEFENSIVE`, `SUPPORTIVE`, `AOE`, `HEALING`, `RECOVERY`, `ENHANCEMENT`, `IMPAIRMENT`, `MOVEMENT`.
Enum `SpellManifest`: `MELEE`, `RANGED`, `PROTECTIVE`, `UTILITY`, `CONTROL`, `RESTORATIVE`.
Enum `BuffType`: `SPEED`, `DAMAGE`, `MANA_REGEN`, `DEFENSE`, `CAST_SPEED`, `DASH_CHARGES`.
Enum `DecastMode`: `TARGETED`, `AOE_PULSE`, `DISPEL_SELF`.
Enum `Delivery`: `LEGACY`, `PROJECTILE`, `SELF`, `DIRECT_TARGET`, `AREA_BURST`, `PERSISTENT_AREA`, `BEAM`, `TRAP`, `SUMMON`.
Enum `Targeting`: `ENEMIES`, `ALLIES`, `ANY`.

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `resonance_bonus` | `float` | **Metadata/legacy or unused in current execution.** Retained bounded resonance tuning; no automatic damage bonus handler. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `off_archetype_penalty` | `float` | **Metadata/legacy or unused in current execution.** Retained bounded penalty metadata; no automatic penalty handler. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `requires_archetype_match` | `bool` | **Metadata/legacy or unused in current execution.** Retained restriction flag; current casting does not enforce this archetype match. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `spell_category` | `SpellCategory` | Legacy payload/delivery adapter and decast target policy; explicit effects take precedence. | Conditional/optional | `SpellCategory.PROJECTILE` | `@export`; see guide for runtime constraints. | [spell-delivery](../../components/spells/spell-delivery.gd), [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `spell_name` | `String` | Human-readable authored name for this definition. | Required | `""` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `spell_id` | `String` | Stable library/authorization/save identifier; exact spelling is significant. | Required | `""` | `@export`; see guide for runtime constraints. | [spell-casting-component](../../components/spells/spell-casting-component.gd) |
| `spell_icon` | `Texture2D` | Texture shown in spell study/equipment/repertoire UI. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `spell_colour` | `Color` | Spell/projectile/field feedback tint. | Conditional/optional | `Color.WHITE` | `@export`; see guide for runtime constraints. | [spell-casting-component](../../components/spells/spell-casting-component.gd), [spell-delivery](../../components/spells/spell-delivery.gd) |
| `spell_flavour_text` | `String` | Authored description used by spell presentation. | Conditional/optional | `""` | `@export_multiline`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `theory_desc` | `String` | Authored spell theory explanation. | Conditional/optional | `""` | `@export_multiline`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `spell_type` | `SpellType` | Authored classification; legacy spellcaster preferences consume this enum. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `spell_manifest` | `SpellManifest` | Authored classification metadata, not the generated spell registry. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `magis_archetype` | `String` | Authored Magis classification; not a player class or automatic resonance mechanic. | Conditional/optional | `"Mana Manipulation"` | `@export_enum("Mana Manipulation", "Ilmiah", "Alnur", "Alzalam", "Semesta")`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `magis_comprehension` | `String` | Classification label; subject value selects the purchase cost multiplier. | Conditional/optional | `"Novice"` | `@export_enum("Novice", "Intermediate", "Advanced", "Expert")`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `spell_incantation` | `Array[String]` | Lowercase direction sequence; exact duplicates invalid, proper prefixes supported. | Required | `[]` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `upfront_cost` | `int` | Mana paid when a cast starts; cancellation rules belong to casting service. | Conditional/optional | `0` | `@export`; see guide for runtime constraints. | [spell-casting-component](../../components/spells/spell-casting-component.gd) |
| `mana_per_second` | `float` | Mana consumed per active channel second. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [spell-casting-component](../../components/spells/spell-casting-component.gd) |
| `cast_time` | `float` | Preparation time, modified by supported buff_cast_speed. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [spell-casting-component](../../components/spells/spell-casting-component.gd) |
| `is_channelled` | `bool` | Enables positive-duration channel stage. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [spell-casting-component](../../components/spells/spell-casting-component.gd) |
| `channel_duration` | `float` | Channel lifetime; ordinary channel dispatches at end, live_channel starts delivery earlier. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [spell-casting-component](../../components/spells/spell-casting-component.gd) |
| `spell_scene` | `PackedScene` | Optional projectile PackedScene; must instantiate SpellEffect; default projectile if empty. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [spell-delivery](../../components/spells/spell-delivery.gd) |
| `projectile_texture` | `Texture2D` | Projectile sprite texture when assigned. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [magis-projectile](../../components/projectiles/magis-projectile.gd) |
| `projectile_particles` | `PackedScene` | Optional projectile particle child scene. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [magis-projectile](../../components/projectiles/magis-projectile.gd) |
| `impact_particles` | `PackedScene` | Optional presentation spawned on impact. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [magis-projectile](../../components/projectiles/magis-projectile.gd) |
| `cast_sound` | `AudioStream` | **Metadata/legacy or unused in current execution.** Retained AudioStream slot; no current casting playback consumer. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `impact_sound` | `AudioStream` | **Metadata/legacy or unused in current execution.** Retained AudioStream slot; no current impact playback consumer. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `projectile_range` | `float` | Positive maximum travel range. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [magis-projectile](../../components/projectiles/magis-projectile.gd) |
| `projectile_size` | `float` | Positive projectile size/scale configuration. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [magis-projectile](../../components/projectiles/magis-projectile.gd) |
| `projectile_damage` | `float` | Legacy DamageEffect amount when no explicit effect payload replaces it. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `projectile_speed` | `float` | Positive projectile movement speed. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [magis-projectile](../../components/projectiles/magis-projectile.gd) |
| `projectile_count` | `int` | Number of projectiles, 1–128. | Conditional/optional | `1` | `@export`; see guide for runtime constraints. | [spell-delivery](../../components/spells/spell-delivery.gd) |
| `projectile_spread` | `float` | Spread angle, finite within ±360 degrees. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [spell-delivery](../../components/spells/spell-delivery.gd) |
| `piercing` | `bool` | Projectile can continue after target contact while preserving per-target hit control. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [magis-projectile](../../components/projectiles/magis-projectile.gd) |
| `is_self_cast` | `bool` | Legacy delivery override to SELF. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd), [magis-projectile](../../components/projectiles/magis-projectile.gd) |
| `aoe_spell_radius` | `float` | Actor area radius; some constructs use it for interception. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [spell-delivery](../../components/spells/spell-delivery.gd), [magis-projectile](../../components/projectiles/magis-projectile.gd) |
| `explosive` | `float` | **Metadata/legacy or unused in current execution.** Retained nonnegative legacy tuning; impact AoE uses aoe_spell_radius, not this value. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `knockback_force` | `float` | Authored knockback force; see canonical guide and consumers for its supported use. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `heal_amount` | `float` | Legacy immediate healing amount. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `heal_over_time` | `bool` | Legacy switch from immediate heal to hot payload. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `hot_tick_heal` | `float` | Legacy healing amount per periodic tick. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `hot_tick_interval` | `float` | Legacy hot interval. | Conditional/optional | `1.0` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `hot_duration` | `float` | Legacy hot duration. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `buff_type` | `BuffType` | Legacy enum mapped to one supported buff_stat key. | Conditional/optional | `BuffType.SPEED` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `on_hit_proc_id` | `String` | Stored proc metadata; no generic on-hit proc dispatcher is implemented. | Conditional/optional | `""` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `buff_magnitude` | `float` | Legacy ModifyStatEffect amount; stat consumers determine units. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `buff_duration` | `float` | Legacy buff duration. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `is_stackable` | `bool` | False limits effective stack to one. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `max_stacks` | `int` | Maximum independent stacks; configured policies and manager cap apply. | Conditional/optional | `1` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `decast_mode` | `DecastMode` | Legacy SELF versus area/targeted decast routing. | Conditional/optional | `DecastMode.TARGETED` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `decast_radius` | `float` | Decast area radius when category is DECAST. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [spell-delivery](../../components/spells/spell-delivery.gd) |
| `purge_enemy_buffs` | `bool` | Enable hostile buff clear in legacy decast payload/targeting. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [spell-delivery](../../components/spells/spell-delivery.gd), [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `purge_debuffs` | `bool` | Enable allied debuff clear in legacy decast payload/targeting. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [spell-delivery](../../components/spells/spell-delivery.gd), [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `misfire_silence_duration` | `float` | **Metadata/legacy or unused in current execution.** Retained tuning; current targeted-decast miss path does not implement this silence. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `chain_range` | `float` | **Metadata/legacy or unused in current execution.** Retained legacy tether/chain tuning; ChainEffect uses its own radius. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `chain_max_targets` | `int` | **Metadata/legacy or unused in current execution.** Retained legacy tuning; ChainEffect uses its own bounded hops. | Conditional/optional | `1` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `chain_damage_falloff` | `float` | **Metadata/legacy or unused in current execution.** Retained legacy tuning; ChainEffect uses its implemented .75 factor. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `equilibrium_bias` | `float` | **Metadata/legacy or unused in current execution.** Retained legacy tether tuning; no equilibrium-drain handler. | Conditional/optional | `0.5` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `stunnable` | `bool` | Legacy enables stun payload (name describes application, not receiver immunity). | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `stun_dur` | `float` | Legacy stun duration. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `dot` | `bool` | Legacy enables damage-over-time payload. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [spell-delivery](../../components/spells/spell-delivery.gd), [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `dot_damage` | `float` | Legacy periodic damage per tick. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `dot_interval` | `float` | Legacy periodic damage interval. | Conditional/optional | `0.5` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `dot_duration` | `float` | Legacy damage-over-time duration. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `applies_slow` | `bool` | Legacy enables slow payload. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `slow_factor` | `float` | Legacy slow fraction clamped/validated to 0–1. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `slow_duration` | `float` | Legacy slow duration. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `applies_mana_drain` | `bool` | Legacy enables periodic mana drain payload. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `mana_drain_amount` | `float` | Legacy periodic mana drained per tick. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `mana_drain_duration` | `float` | Legacy drain duration. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `applies_silence` | `bool` | Legacy enables silence payload. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `silence_duration` | `float` | Legacy silence duration. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [legacy-spell-adapter](../../components/spells/legacy-spell-adapter.gd) |
| `status_effects` | `Array[Resource]` | **Metadata/legacy or unused in current execution.** Retained arbitrary Resource hook; actual statuses use typed effects/ActiveEffectManager. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `delivery` | `Delivery` | Select explicit supported delivery or use LEGACY adapter. | Required | `Delivery.LEGACY` | `@export`; see guide for runtime constraints. | [spell-casting-component](../../components/spells/spell-casting-component.gd), [spell-delivery](../../components/spells/spell-delivery.gd) |
| `effects` | `Array[SpellEffectDefinition]` | Ordered typed payload; nonempty SpellData array replaces legacy-derived effects. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [spell-casting-component](../../components/spells/spell-casting-component.gd), [spell-delivery](../../components/spells/spell-delivery.gd) |
| `targeting` | `Targeting` | ENEMIES/ALLIES/ANY relation policy; SELF delivery executes on caster. | Conditional/optional | `Targeting.ENEMIES` | `@export`; see guide for runtime constraints. | [spell-delivery](../../components/spells/spell-delivery.gd) |
| `academic_fields` | `Array[FieldData]` | Referenced FieldData academic identities; not delivery/automatic unlock logic. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `cooldown` | `float` | Seconds until reuse; ordinary ability and spell cooldowns both apply. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [spell-casting-component](../../components/spells/spell-casting-component.gd) |
| `recovery_time` | `float` | Post-execution casting recovery seconds. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [spell-casting-component](../../components/spells/spell-casting-component.gd) |
| `target_range` | `float` | Direct target/beam reach; also contributes to aim placement and enemy range setup. | Conditional/optional | `1000.0` | `@export`; see guide for runtime constraints. | [spell-casting-component](../../components/spells/spell-casting-component.gd), [spell-delivery](../../components/spells/spell-delivery.gd) |
| `area_duration` | `float` | Persistent field or reusable construct lifetime. | Conditional/optional | `3.0` | `@export`; see guide for runtime constraints. | [spell-area-delivery](../../components/spells/spell-area-delivery.gd), [spell-construct](../../components/spells/spell-construct.gd) |
| `area_tick_interval` | `float` | Persistent scan/tick interval, at least .05 for validated persistent delivery. | Conditional/optional | `1.0` | `@export`; see guide for runtime constraints. | [spell-area-delivery](../../components/spells/spell-area-delivery.gd) |
| `beam_width` | `float` | Beam projection/geometry width, must be positive for BEAM. | Conditional/optional | `32.0` | `@export`; see guide for runtime constraints. | [spell-delivery](../../components/spells/spell-delivery.gd), [spell-area-delivery](../../components/spells/spell-area-delivery.gd) |
| `summon_scene` | `PackedScene` | Required Node2D scene for SUMMON delivery; custom behavior needs compatible implementation. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [spell-delivery](../../components/spells/spell-delivery.gd) |
| `aim_placement` | `bool` | Offset cast source along aim by min(target_range,220). | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [spell-casting-component](../../components/spells/spell-casting-component.gd) |
| `has_wave_tag` | `bool` | Opt-in wave identity for projectile/area cancellation. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/spell.gd) |
| `affects_projectiles` | `bool` | Route projectile-field payload through area/projectile scanning. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [spell-delivery](../../components/spells/spell-delivery.gd) |
| `beam_angles` | `Array[float]` | One to five output beam angles, finite within ±180 degrees. | Conditional/optional | `[0.0]` | `@export`; see guide for runtime constraints. | [spell-area-delivery](../../components/spells/spell-area-delivery.gd) |
| `optical_angle` | `float` | Optical-interface angle interpreted by compatible construct/beam code. | Conditional/optional | `0.0` | `@export`; see guide for runtime constraints. | [spell-construct](../../components/spells/spell-construct.gd) |
| `construct_solid` | `bool` | Reusable SpellConstruct creates a solid 150×16 shape, after placement check. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [spell-delivery](../../components/spells/spell-delivery.gd), [spell-construct](../../components/spells/spell-construct.gd) |
| `construct_follow` | `bool` | Reusable construct follows caster; arbitrary summons do not gain this automatically. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [spell-construct](../../components/spells/spell-construct.gd) |
| `construct_reflect` | `bool` | Reusable construct redirects hostile intercepted projectiles rather than cancelling. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [spell-construct](../../components/spells/spell-construct.gd) |
| `live_channel` | `bool` | Only validated for channelled BEAM/PERSISTENT_AREA/TRAP; cancels owned live delivery. | Conditional/optional | `false` | `@export`; see guide for runtime constraints. | [spell-casting-component](../../components/spells/spell-casting-component.gd) |

## SpellEffectDefinition

Source: [data/Resources/spell-effects/spell-effect-definition.gd](../../data/Resources/spell-effects/spell-effect-definition.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/spell-effects.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| — | — | No exported fields; runtime contract in methods. | — | — | — | [Source](../../data/Resources/spell-effects/spell-effect-definition.gd) |

## TeleportEffect

Source: [data/Resources/spell-effects/teleport-effect.gd](../../data/Resources/spell-effects/teleport-effect.gd). Base: `SpellEffectDefinition`. [Canonical authoring and validation](../authoring/spell-effects.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `distance` | `float` | Swept teleport distance along cast direction. | Conditional/optional | `100.0` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/teleport-effect.gd) |

## TriggerEffect

Source: [data/Resources/spell-effects/trigger-effect.gd](../../data/Resources/spell-effects/trigger-effect.gd). Base: `SpellEffectDefinition`. [Canonical authoring and validation](../authoring/spell-effects.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `duration` | `float` | Effect/trigger lifetime in seconds; validate per subclass. | Conditional/optional | `4.0` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/trigger-effect.gd) |
| `hits` | `int` | Trigger damage-event activation count, 1–6. | Conditional/optional | `3` | `@export_range(1, 6)`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/trigger-effect.gd) |
| `children` | `Array[SpellEffectDefinition]` | Nested ordered effects under the same execution/context contract. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/trigger-effect.gd) |

## TutorialData

Source: [data/tutorials/tutorial-data.gd](../../data/tutorials/tutorial-data.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/tutorials.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `tutorial_title` | `String` | **Metadata/legacy or unused in current execution.** Authored tutorial metadata; current panel displays each page_title instead. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/tutorials/tutorial-data.gd) |
| `pages` | `Array[TutorialPage]` | Ordered non-null TutorialPage references. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [tutorial-panel](../../components/panels/tutorials/tutorial-panel.gd) |

## TutorialPage

Source: [data/tutorials/tutorial-page.gd](../../data/tutorials/tutorial-page.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/tutorials.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `page_title` | `String` | Visible current tutorial page title. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [tutorial-panel](../../components/panels/tutorials/tutorial-panel.gd) |
| `page_desc` | `String` | Multiline current tutorial page content. | Required | `Godot type default` | `@export_multiline()`; see guide for runtime constraints. | [tutorial-panel](../../components/panels/tutorials/tutorial-panel.gd) |
| `page_image` | `Texture2D` | Optional tutorial image; empty hides image widget. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [tutorial-panel](../../components/panels/tutorials/tutorial-panel.gd) |

## VectorEffect

Source: [data/Resources/spell-effects/vector-effect.gd](../../data/Resources/spell-effects/vector-effect.gd). Base: `SpellEffectDefinition`. [Canonical authoring and validation](../authoring/spell-effects.md).

Enum `Mode`: `IMPULSE`, `ATTRACT`, `ORBIT`, `DAMP`, `LIFT`.

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `mode` | `Mode` | Subclass enum selects existing behavior; adding an enum alone does not implement it. | Conditional/optional | `Mode.IMPULSE` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/vector-effect.gd) |
| `strength` | `float` | Vector/projectile field magnitude; DAMP/SLOW have specialized fractional semantics. | Conditional/optional | `180.0` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/vector-effect.gd) |
| `capability` | `StringName` | Optional metadata presence gate, not a newly installed ability. | Conditional/optional | `&""` | `@export`; see guide for runtime constraints. | [validate / execute](../../data/Resources/spell-effects/vector-effect.gd) |

## subjectData

Source: [data/Resources/ilmu/subject.gd](../../data/Resources/ilmu/subject.gd). Base: `Resource`. [Canonical authoring and validation](../authoring/courses-and-subjects.md).

| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `subject_name` | `String` | Human-readable authored name for this definition. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/subject.gd) |
| `subject_icon` | `Texture2D` | Authored subject icon; see canonical guide and consumers for its supported use. | Conditional/optional | `Godot type default` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/subject.gd) |
| `subject_id` | `String` | Stable authored identifier; match parent/registry/event references exactly. | Required | `Godot type default` | `@export`; see guide for runtime constraints. | [player-data](../../autoloads/player-data.gd), [subject-panel](../../scenes/spell-tree/subject-panel.gd) |
| `subject_archetype` | `String` | Academic category selected from the schema enum. | Conditional/optional | `"Life Sciences"` | `@export_enum("Life Sciences", "Physical Sciences", "Mathematics", "Computer Science", "Social Sciences", "Humanities", "Arts", "Engineering", "Technology", "Language")`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/subject.gd) |
| `field_of_study` | `String` | Subject academic context displayed by study UI. | Conditional/optional | `Godot type default` | `@export_multiline`; see guide for runtime constraints. | [subject-panel](../../scenes/spell-tree/subject-panel.gd) |
| `theoretical_foundation` | `String` | Subject academic explanation for study presentation. | Conditional/optional | `Godot type default` | `@export_multiline`; see guide for runtime constraints. | [subject-panel](../../scenes/spell-tree/subject-panel.gd) |
| `casters_notes` | `String` | Subject practical casting notes for study presentation. | Conditional/optional | `Godot type default` | `@export_multiline`; see guide for runtime constraints. | [subject-panel](../../scenes/spell-tree/subject-panel.gd) |
| `magis_archetype` | `String` | Authored Magis classification; not a player class or automatic resonance mechanic. | Conditional/optional | `"Mana Manipulation"` | `@export_enum ("Mana Manipulation", "Ilmiah", "Alnur", "Alzalam","Semesta")`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/subject.gd) |
| `magis_comprehension` | `String (inferred)` | Classification label; subject value selects the purchase cost multiplier. | Conditional/optional | `"Novice"` | `@export_enum("Novice", "Intermediate", "Advanced", "Expert")`; see guide for runtime constraints. | [player-data](../../autoloads/player-data.gd) |
| `difficulty_level` | `int` | Inspector 1–5; subject difficulty contributes quadratically to purchase cost. | Conditional/optional | `Godot type default` | `@export_range(1,5)`; see guide for runtime constraints. | [player-data](../../autoloads/player-data.gd) |
| `prerequisites` | `Array[String]` | Completed subject IDs; course and subject purchase gates. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [player-data](../../autoloads/player-data.gd), [subject-panel](../../scenes/spell-tree/subject-panel.gd) |
| `contained_spells` | `Array[SpellData]` | Spells learned after a successful once-only subject purchase; equipment is separate. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [player-data](../../autoloads/player-data.gd), [subject-panel](../../scenes/spell-tree/subject-panel.gd) |
| `academic_fields` | `Array[FieldData]` | Referenced FieldData academic identities; not delivery/automatic unlock logic. | Conditional/optional | `[]` | `@export`; see guide for runtime constraints. | [Schema / methods](../../data/Resources/ilmu/subject.gd) |
| `comprehension_requirements` | `Dictionary[StringName, int]` | Field StringName → minimum rank; actual rank must be awarded deliberately. | Conditional/optional | `{}` | `@export`; see guide for runtime constraints. | [player-data](../../autoloads/player-data.gd) |

## Persistence and runtime values

Stable field/subject/spell/item/quest/scene/giver identities and dictionary/event targets are documented in the [identifier guide](identifiers-and-conventions.md). Resource files contain authored defaults, not live HP, cast queues, objective progress or cooldowns. Save V1 stores its explicit supported runtime state and resolves registered IDs; it does not dump these Resource objects into JSON. A declaration with no behavioral consumer must not be advertised as an implemented mechanic.

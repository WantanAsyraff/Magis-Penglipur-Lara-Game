# BossAttackData.gd
# One attack entry. Add these to a BossPhaseData's attack pool.
class_name BossAttackData
extends Resource

enum AttackKind { MELEE_SLAM, MELEE_DASH, RANGED_BURST, AOE_SLAM, SUMMON }

@export_group("Identity")
@export var attack_name: String = "Attack"
@export var kind: AttackKind = AttackKind.MELEE_SLAM

## Higher weight = more likely to be chosen. Relative to other attacks in the pool.
@export var weight: float = 1.0

## Seconds before the next attack can fire after this one finishes.
@export var cooldown: float = 1.5

## Windup delay in seconds before the hit lands (for animation sync).
@export var windup: float = 0.3

@export_group("Melee")
## Damage for slam or dash attacks.
@export var melee_damage: float = 25.0
## Range in pixels for slam hit detection.
@export var melee_range: float = 80.0
## Speed multiplier during a dash (applied to boss chase_speed).
@export var dash_speed_multiplier: float = 3.0
## How long the dash lasts in seconds.
@export var dash_duration: float = 0.25

@export_group("Ranged")
## SpellData to fire for ranged burst. Uses MagicProjectile.
@export var ranged_spell: SpellData = null
## How many projectiles to fire in the burst.
@export var burst_count: int = 3
## Delay between each projectile in a burst.
@export var burst_interval: float = 0.15
## Spread angle in degrees across the burst.
@export var burst_spread: float = 30.0

@export_group("AOE")
## Radius of the AOE hit.
@export var aoe_radius: float = 120.0
## Damage dealt to player if inside radius.
@export var aoe_damage: float = 30.0
## Knockback force applied outward from center.
@export var aoe_knockback: float = 400.0
## Warning time in seconds before AOE detonates (show telegraph here).
@export var aoe_warning_duration: float = 0.8

@export_group("Summon")
## Scene to instantiate as a minion.
@export var minion_scene: PackedScene = null
## How many minions to spawn.
@export var minion_count: int = 2
## Spread radius around the boss spawn position.
@export var spawn_radius: float = 80.0

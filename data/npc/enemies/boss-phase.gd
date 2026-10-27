# BossPhaseData.gd
# Defines one phase of the boss fight.
# Create multiple .tres files and assign them to Boss.phases in order.
class_name BossPhaseData
extends Resource

@export_group("Phase Identity")
@export var phase_name: String = "Phase 1"

## Boss transitions INTO this phase when HP drops to or below this ratio (0.0–1.0).
## Phase 1 should be 1.0 (starts immediately). Phase 2 might be 0.6, Phase 3 0.3, etc.
@export_range(0.0, 1.0) var enter_at_health_ratio: float = 1.0

@export_group("Movement")
## Move speed while in this phase.
@export var move_speed: float = 90.0
## Chase speed while in this phase.
@export var chase_speed: float = 160.0

@export_group("Attacks")
## Pool of attacks available in this phase. Chosen by weighted random.
@export var attacks: Array[BossAttackData] = []

@export_group("Phase Transition")
## If true, boss becomes briefly invincible during phase transition.
@export var invincible_on_transition: bool = true
## How long the invincibility lasts during transition.
@export var transition_invincible_duration: float = 1.5
## Animation to play on phase transition. Leave empty to skip.
@export var transition_animation: String = "phase_transition"

## Negative values preserve the boss's base mitigation.
@export var defense: float = -1
@export var incoming_multiplier: float = -1
@export var status_resistances: Dictionary[String, float] = {}

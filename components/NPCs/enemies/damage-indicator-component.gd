# DamageIndicatorComponent.gd
# Attach as a child of any node that has a HitboxComponent.
# Listens to the sibling HitboxComponent's signals and spawns floating damage numbers.
#
# SETUP:
#   1. Add this node as a child of your Enemy, Player, or Boss.
#   2. It auto-finds the sibling HitboxComponent on _ready().
#   No other wiring needed.

class_name DamageIndicatorComponent
extends Node

# ─────────────────────────────────────────
# EXPORTS
# ─────────────────────────────────────────
@export_group("Damage Numbers")
## Font to use for damage numbers. Leave empty to use the default theme font.
@export var font: Font = null

## Base font size.
@export var font_size: int = 18

## Color for normal damage.
@export var damage_color: Color = Color(1.0, 0.3, 0.3)

## Color for critical hits (damage above crit_threshold).
@export var crit_color: Color = Color(1.0, 0.85, 0.0)

## Damage value above which the number is treated as a crit visually.
@export var crit_threshold: float = 30.0

## Color for heal numbers.
@export var heal_color: Color = Color(0.3, 1.0, 0.4)

## Color for mana drain numbers.
@export var mana_drain_color: Color = Color(0.3, 0.5, 1.0)

@export_group("Animation")
## How far upward the number floats in pixels.
@export var float_distance: float = 40.0

## How long the number stays visible in seconds.
@export var lifetime: float = 0.8

## Horizontal random spread so numbers don't stack.
@export var horizontal_spread: float = 20.0

## Scale punch on spawn (crit gets a bigger punch).
@export var spawn_scale: float = 1.3

## If true, crit numbers are larger.
@export var crit_scale: float = 1.8

@export_group("Offset")
## Vertical offset above the parent node where numbers spawn.
@export var spawn_offset_y: float = -40.0

# ─────────────────────────────────────────
# INTERNAL
# ─────────────────────────────────────────
var _hitbox: HitboxComponent = null
var _parent_node: Node2D = null

# ─────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	_parent_node = get_parent() as Node2D
	if _parent_node == null:
		push_warning("DamageIndicatorComponent: parent must be a Node2D or subclass.")
		return

	# Auto-find sibling HitboxComponent
	_hitbox = _parent_node.get_node_or_null("HitboxComponent") as HitboxComponent
	if _hitbox == null:
		push_warning("DamageIndicatorComponent: no sibling HitboxComponent found on %s." % _parent_node.name)
		return

	_hitbox.damage_taken.connect(_on_damage_taken)
	_hitbox.healed.connect(_on_healed)
	_hitbox.mana_drained.connect(_on_mana_drained)
	_hitbox.status_applied.connect(_on_status_applied)

# ─────────────────────────────────────────
# SIGNAL HANDLERS
# ─────────────────────────────────────────
func _on_damage_taken(amount: float) -> void:
	var is_crit := amount >= crit_threshold
	var color := crit_color if is_crit else damage_color
	var scale := crit_scale if is_crit else spawn_scale
	var text := "-%s" % _format_number(amount)
	_spawn_label(text, color, scale)

func _on_healed(amount: float) -> void:
	var text := "+%s" % _format_number(amount)
	_spawn_label(text, heal_color, spawn_scale)

func _on_mana_drained(amount: float) -> void:
	var text := "-%s MP" % _format_number(amount)
	_spawn_label(text, mana_drain_color, spawn_scale)

func _on_status_applied(effect_name: String) -> void:
	match effect_name:
		"stun":    _spawn_label("Stunned!", Color(1.0, 0.8, 0.0), spawn_scale)
		"silence": _spawn_label("Silenced!", Color(0.7, 0.3, 1.0), spawn_scale)
		"slow":    _spawn_label("Slowed!", Color(0.4, 0.8, 1.0), spawn_scale)

# ─────────────────────────────────────────
# LABEL SPAWNING
# ─────────────────────────────────────────
func _spawn_label(text: String, color: Color, scale_factor: float) -> void:
	if _parent_node == null:
		return

	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	if font:
		label.add_theme_font_override("font", font)

	# Position: above parent with random horizontal spread
	var spread := randf_range(-horizontal_spread, horizontal_spread)
	label.global_position = _parent_node.global_position + Vector2(spread, spawn_offset_y)

	# Make sure it renders above game world
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	get_tree().current_scene.add_child(canvas)
	canvas.add_child(label)

	# Convert global position to canvas-local
	label.position = _parent_node.global_position + Vector2(spread, spawn_offset_y)

	# Animate: float up and fade out
	label.scale = Vector2.ONE * scale_factor
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - float_distance, lifetime)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, lifetime)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(label, "scale", Vector2.ONE, lifetime * 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Clean up after animation
	await get_tree().create_timer(lifetime).timeout
	canvas.queue_free()

# ─────────────────────────────────────────
# UTILITY
# ─────────────────────────────────────────
func _format_number(value: float) -> String:
	# Show as int if whole number, otherwise 1 decimal
	if fmod(value, 1.0) == 0.0:
		return str(int(value))
	return "%.1f" % value

# DamageIndicatorComponent.gd
class_name DamageIndicatorComponent
extends Node

@export_group("Damage Numbers")
@export var font: Font = null
@export var font_size: int = 18
@export var damage_color: Color = Color(1.0, 0.3, 0.3)
@export var crit_color: Color = Color(1.0, 0.85, 0.0)
@export var crit_threshold: float = 30.0
@export var heal_color: Color = Color(0.3, 1.0, 0.4)
@export var mana_drain_color: Color = Color(0.3, 0.5, 1.0)

@export_group("Animation")
@export var float_distance: float = 40.0
@export var lifetime: float = 0.8
@export var horizontal_spread: float = 20.0
@export var vertical_spread: float = 15.0
@export var spawn_scale: float = 1.3
@export var crit_scale: float = 1.8

@export_group("Offset")
@export var spawn_offset_y: float = -40.0
@export var stagger_step: float = 12.0
@export var stagger_reset: int = 5

var _hitbox: HitboxComponent = null
var _parent_node: Node2D = null
var _spawn_count: int = 0

func _ready() -> void:
	_parent_node = get_parent() as Node2D
	if _parent_node == null:
		push_warning("DamageIndicatorComponent: parent must be Node2D.")
		return

	_hitbox = _parent_node.get_node_or_null("HitboxComponent") as HitboxComponent
	if _hitbox == null:
		push_warning("DamageIndicatorComponent: no sibling HitboxComponent on %s." % _parent_node.name)
		return

	_hitbox.damage_taken.connect(_on_damage_taken)
	_hitbox.healed.connect(_on_healed)
	_hitbox.mana_drained.connect(_on_mana_drained)
	if _hitbox.has_signal("status_applied"):
		_hitbox.status_applied.connect(_on_status_applied)

func _on_damage_taken(amount: float) -> void:
	var is_crit := amount >= crit_threshold
	_spawn_label(
		"-%s" % _format_number(amount),
		crit_color if is_crit else damage_color,
		crit_scale if is_crit else spawn_scale
	)

func _on_healed(amount: float) -> void:
	_spawn_label("+%s" % _format_number(amount), heal_color, spawn_scale)

func _on_mana_drained(amount: float) -> void:
	_spawn_label("-%s MP" % _format_number(amount), mana_drain_color, spawn_scale)

func _on_status_applied(effect_name: String) -> void:
	match effect_name:
		"stun":    _spawn_label("Stunned!",  Color(1.0, 0.8, 0.0), spawn_scale)
		"silence": _spawn_label("Silenced!", Color(0.7, 0.3, 1.0), spawn_scale)
		"slow":    _spawn_label("Slowed!",   Color(0.4, 0.8, 1.0), spawn_scale)

func _spawn_label(text: String, color: Color, scale_factor: float) -> void:
	if _parent_node == null:
		return

	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	if font:
		label.add_theme_font_override("font", font)

	var spread_x := randf_range(-horizontal_spread, horizontal_spread)
	var spread_y := randf_range(-vertical_spread, vertical_spread)
	var stagger_y := (_spawn_count % stagger_reset) * stagger_step
	label.position = _parent_node.global_position + Vector2(spread_x, spawn_offset_y + spread_y - stagger_y)
	label.scale = Vector2.ONE * scale_factor
	label.z_index = 10

	_spawn_count += 1
	get_tree().current_scene.add_child(label)

	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - float_distance, lifetime) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, lifetime) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)

func _format_number(value: float) -> String:
	if fmod(value, 1.0) == 0.0:
		return str(int(value))
	return "%.1f" % value

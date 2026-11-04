class_name WeaponVisualController extends Node2D
## Presentation only. Existing attacks/hit detection own all combat behavior.
@export var default_visual: WeaponVisualData
@onready var attachment: Node2D = $WeaponAttachment
@onready var visual: Node2D = $WeaponAttachment/WeaponVisual
@onready var animation_player: AnimationPlayer = $WeaponAnimationPlayer
@onready var hit_origin: Marker2D = $WeaponAttachment/WeaponHitOrigin
@onready var effects_origin: Marker2D = $WeaponAttachment/WeaponEffectsOrigin
var player: Player
var equipped: ItemData
var definition: WeaponVisualData
var left := false
var pose := "weapon_idle"
var holstered := false

func _ready() -> void:
	player = get_parent() as Player
	Inventory_Manager.equipment_changed.connect(_equipment_changed)
	player.ready.connect(_bind, CONNECT_ONE_SHOT)
	animation_player.animation_finished.connect(_animation_finished)
	_sync(Inventory_Manager.get_equipped(Inventory_Manager.SlotType.WEAPON))
func _bind() -> void:
	if not player.is_multiplayer_authority(): hide(); set_process(false); return
	player.casting.cast_completed.connect(func(_context): play_presentation(&"weapon_cast"))
	player.hitbox.died.connect(hide)
	player.presentation_died.connect(hide)
func _equipment_changed(slot: int, item: ItemData) -> void:
	if slot == Inventory_Manager.SlotType.WEAPON: _sync(item)
func _sync(item: ItemData) -> void:
	if not is_inside_tree() or not player.is_inside_tree(): return
	if not player.is_multiplayer_authority(): hide(); return
	if item == equipped and definition != null: return
	equipped = item
	animation_player.stop()
	for child in visual.get_children(): visual.remove_child(child); child.queue_free()
	for child in effects_origin.get_children(): effects_origin.remove_child(child); child.queue_free()
	if animation_player.has_animation_library("asset"): animation_player.remove_animation_library("asset")
	visible = item != null
	if item == null:
		definition = null; return
	definition = item.weapon_visual if item.weapon_visual else default_visual
	if definition == null: return
	if definition.scene:
		var instance := definition.scene.instantiate()
		if instance is Node2D: visual.add_child(instance)
		else: instance.free(); push_warning("Weapon scene root must be Node2D")
	elif definition.texture or (definition.use_inventory_icon_fallback and item.item_icon):
		var sprite := Sprite2D.new()
		sprite.texture = definition.texture if definition.texture else item.item_icon
		visual.add_child(sprite)
	else:
		# Authored geometric placeholder, no collision or damage behavior.
		var placeholder := preload("res://components/characters/player/weapons/weapon-placeholder.tscn").instantiate()
		visual.add_child(placeholder)
	visual.scale = definition.visual_scale; z_index = definition.draw_order
	if definition.effect_scene: effects_origin.add_child(definition.effect_scene.instantiate())
	if definition.animations: animation_player.add_animation_library("asset", definition.animations)
	_update_facing()
	play_presentation(&"weapon_draw")
func _update_facing() -> void:
	if definition == null: return
	left = player.get_node("PlayerSprite").flip_h
	position = definition.left_offset if left else definition.offset
	rotation_degrees = definition.left_rotation_degrees if left else definition.rotation_degrees
	scale.x = -1.0 if left and definition.mirror_left else 1.0
func _process(_delta: float) -> void:
	if definition == null or not visible: return
	_update_facing()
	if holstered: return
	if player.get_meta("combat_dead", false): hide(); return
	var desired := "weapon_cast" if player._in_casting_stance else ("weapon_block" if player._is_blocking else "weapon_idle")
	if desired != pose and (animation_player.current_animation.is_empty() or pose in ["weapon_idle", "weapon_block", "weapon_cast"]):
		play_presentation(StringName(desired))
## Call from an existing attack event when melee attacks are authored. No new action or damage.
func present_attack(index: int = 1, airborne: bool = false) -> void:
	play_presentation(&"weapon_attack_air" if airborne else (&"weapon_attack_2" if index == 2 else &"weapon_attack_1"))
func play_presentation(animation: StringName) -> void:
	if equipped == null or not visible: return
	holstered = animation == &"weapon_holster"
	visual.show()
	pose = animation
	var asset_name := "asset/" + String(animation)
	animation_player.play(asset_name if animation_player.has_animation(asset_name) else String(animation))
func _animation_finished(animation: StringName) -> void:
	if String(animation).ends_with("weapon_holster"):
		visual.hide(); return
	visual.show()
	if String(animation).ends_with("weapon_block"): return
	pose = ""

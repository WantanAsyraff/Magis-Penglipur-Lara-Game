class_name WeaponVisualData extends Resource
## Independent in-world art; inventory icons are used only when explicitly enabled.
@export var texture: Texture2D
@export var scene: PackedScene
@export var animations: AnimationLibrary
@export var offset := Vector2(24, -20)
@export var rotation_degrees := -15.0
@export var visual_scale := Vector2.ONE
@export var draw_order := 1
@export var left_offset := Vector2(-24, -20)
@export var left_rotation_degrees := 15.0
@export var mirror_left := true
@export var effect_scene: PackedScene
@export var use_inventory_icon_fallback := false

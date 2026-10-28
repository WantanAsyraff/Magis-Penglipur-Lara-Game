class_name SpellSlot
extends PanelContainer

signal spell_selected(spell: SpellData)

const DIRECTION_ICONS := {
	"up":    "res://assets/ui/spells/casting-icon-up.png",
	"down":  "res://assets/ui/spells/casting-icon-down.png",
	"left":  "res://assets/ui/spells/casting-icon-left.png",
	"right": "res://assets/ui/spells/casting-icon-right.png",
}

const DIRECTION_TEXTURES := {
	"up": preload("res://assets/ui/spells/casting-icon-up.png"),
	"down": preload("res://assets/ui/spells/casting-icon-down.png"),
	"left": preload("res://assets/ui/spells/casting-icon-left.png"),
	"right": preload("res://assets/ui/spells/casting-icon-right.png"),
}

@export var spell_data: SpellData
@export var is_equipped: bool = false

@onready var spellMove_box: HBoxContainer = %SpellMoveHBoxContainer
@onready var spellCostLabel: Label = %SpellCostLabel

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_ALL
	if spell_data:
		display_spell()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		spell_selected.emit(spell_data)
		accept_event()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			spell_selected.emit(spell_data)

func display_spell() -> void:
	if not spell_data:
		return
	%SpellIcon.texture = spell_data.spell_icon
	%SpellNameLabel.text = spell_data.spell_name
	tooltip_text = spell_data.spell_flavour_text
	for child in spellMove_box.get_children():
		spellMove_box.remove_child(child)
		child.queue_free()
	var steps := spell_data.spell_incantation.filter(func(s): return s != "")
	for direction in steps:
		var key: String = direction.to_lower()
		if key in DIRECTION_ICONS:
			var icon := TextureRect.new()
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon.texture = DIRECTION_TEXTURES[key]
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(24, 24)
			spellMove_box.add_child(icon)
	spellCostLabel.text = str(spell_data.upfront_cost) + " MP" + ("  •  Equipped" if is_equipped else "")
	var panel := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	panel.border_color = Color("b89e63") if is_equipped else Color("38424f")
	panel.bg_color = Color("242b32") if is_equipped else Color("1b222c")
	add_theme_stylebox_override("panel", panel)

func set_spell(data: SpellData, equipped: bool = false) -> void:
	spell_data = data
	is_equipped = equipped
	if is_node_ready():
		display_spell()

class_name SpellSlot
extends Control

signal spell_selected(spell: SpellData)

@export var spell_data: SpellData

@onready var spellNameLabel: Label = %SpellNameLabel
@onready var spellMoveLabel: Label = %SpellMoveLabel
@onready var spellCostLabel: Label = %SpellCostLabel

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if spell_data:
		display_spell()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			spell_selected.emit(spell_data)

func display_spell() -> void:
	if not spell_data:
		return
	spellNameLabel.text = spell_data.spell_name
	spellMoveLabel.text = " - ".join(spell_data.spell_incantation.filter(func(s): return s != ""))
	spellCostLabel.text = str(spell_data.upfront_cost) + " MP"

func set_spell(data: SpellData) -> void:
	spell_data = data
	if is_node_ready():
		display_spell()

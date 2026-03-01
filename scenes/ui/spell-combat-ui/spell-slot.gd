class_name SpellSlot
extends Control

@export var spell_data: SpellData

@onready var spellNameLabel: Label = %SpellNameLabel
@onready var spellMoveLabel: Label = %SpellMoveLabel
@onready var spellCostLabel: Label = %SpellCostLabel

func _ready() -> void:
	if spell_data:
		display_spell()

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

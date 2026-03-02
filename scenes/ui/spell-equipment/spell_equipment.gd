extends Control

const SPELL_SLOT = preload("res://scenes/ui/spell-combat-ui/spell-slot.tscn")

@onready var vbox: VBoxContainer = %VBoxContainer

func _ready() -> void:
	Player_Global_Data.spells_updated.connect(_populate_vbox)
	_populate_vbox()

func _populate_vbox() -> void:
	for child in vbox.get_children():
		child.free()
	for spell in Player_Global_Data.learned_spells:
		var slot = SPELL_SLOT.instantiate()
		vbox.add_child(slot)
		slot.set_spell(spell)
		slot.spell_selected.connect(_on_spell_selected)

func _on_spell_selected(spell: SpellData) -> void:
	print(spell.spell_name) # replace with whatever you want to do

extends Node

var all_spells: Dictionary = {}  # spell_id -> SpellData
var incantation_map: Dictionary = {}  # "down,down,right,up" -> SpellData

func _ready():
	_load_all_spells()
	_build_incantation_map()

func _load_all_spells():
	var spells_dir = "res://data/magis/spells/"
	var dir = DirAccess.open(spells_dir)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var spell = load(spells_dir + file_name) as SpellData
				if spell:
					all_spells[spell.spell_id] = spell
			file_name = dir.get_next()

func _build_incantation_map():
	for spell in all_spells.values():
		var key = _array_to_key(spell.spell_incantation)
		incantation_map[key] = spell

func _array_to_key(arr: Array) -> String:
	return ",".join(arr)  # ["down","down","right","up"] -> "down,down,right,up"

func get_spell_by_incantation(sequence: Array) -> SpellData:
	var key = _array_to_key(sequence)
	return incantation_map.get(key)

func get_spell_by_id(spell_id: String) -> SpellData:
	return all_spells.get(spell_id)

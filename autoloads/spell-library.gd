extends Node
const Manifest = preload("res://data/magis/spell-manifest.gd")
var all_spells: Dictionary = {}
var incantation_map: Dictionary = {}
var validation_errors: PackedStringArray = []
var validation_warnings: PackedStringArray = []

func _ready() -> void:
	_load_all_spells()
	_build_incantation_map()

func register_spell(spell: SpellData) -> bool:
	if spell == null:
		validation_errors.append("Missing spell resource")
		return false
	if spell.spell_id.is_empty() or all_spells.has(spell.spell_id):
		validation_errors.append("Empty or duplicate spell ID: " + spell.spell_id)
		return false
	for error in SpellValidator.validate(spell):
		validation_errors.append(spell.spell_id + ": " + error)
	# Keep invalid legacy content visible for diagnosis; casting fails safely.
	all_spells[spell.spell_id] = spell
	if spell.academic_fields.is_empty():
		validation_warnings.append(spell.spell_id + ": uses legacy academic classification")
	return true

func _load_all_spells() -> void:
	all_spells.clear()
	validation_errors.clear()
	validation_warnings.clear()
	var loaded_paths: Array[String] = []
	for spell in Manifest.SPELLS:
		register_spell(spell)
		loaded_paths.append(spell.resource_path)
	# Editor discovery catches unbaked additions. The manifest remains export authority.
	if OS.has_feature("editor"):
		for file in DirAccess.get_files_at("res://data/magis/spells/"):
			var path := "res://data/magis/spells/" + file
			if file.ends_with(".tres") and not loaded_paths.has(path):
				register_spell(load(path) as SpellData)
				validation_warnings.append("Rebake spell manifest: " + path)

func _build_incantation_map() -> void:
	incantation_map.clear()
	for spell in all_spells.values():
		var key := _array_to_key(spell.spell_incantation)
		if key.is_empty():
			validation_errors.append(spell.spell_id + ": empty incantation")
		elif incantation_map.has(key):
			validation_errors.append("Duplicate incantation: " + key)
		else:
			incantation_map[key] = spell
	for key in incantation_map:
		for other in incantation_map:
			if other.begins_with(key + ","):
				validation_warnings.append("Incantation prefix: " + key + " -> " + other)

func _array_to_key(arr: Array) -> String:
	return ",".join(arr)
func get_spell_by_incantation(sequence: Array) -> SpellData:
	return incantation_map.get(_array_to_key(sequence))
func get_spell_by_id(spell_id: String) -> SpellData:
	return all_spells.get(spell_id)

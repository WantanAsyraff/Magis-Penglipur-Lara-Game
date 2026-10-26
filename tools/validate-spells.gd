@tool
extends EditorScript

func _run() -> void:
	var library = load("res://autoloads/spell-library.gd").new()
	library._load_all_spells()
	library._build_incantation_map()
	for error in library.validation_errors:
		push_error(error)
	for warning in library.validation_warnings:
		push_warning(warning)
	print("Spell validation: %d spells, %d errors, %d warnings" % [library.all_spells.size(), library.validation_errors.size(), library.validation_warnings.size()])
	library.free()

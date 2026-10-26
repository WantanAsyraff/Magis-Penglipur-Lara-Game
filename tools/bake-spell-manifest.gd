@tool
extends EditorScript
func _run() -> void:
	var output := "extends RefCounted\n\nconst SPELLS = [\n"
	for file in DirAccess.get_files_at("res://data/magis/spells/"):
		if file.ends_with(".tres"):
			output += '\tpreload("res://data/magis/spells/%s"),\n' % file
	output += "]\n"
	var handle := FileAccess.open("res://data/magis/spell-manifest.gd", FileAccess.WRITE)
	handle.store_string(output)

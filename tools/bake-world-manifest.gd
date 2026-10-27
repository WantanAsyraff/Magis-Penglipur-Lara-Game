@tool
extends EditorScript

func _run() -> void:
	var paths := _scan_dir("res://data/worlds/hubs/")
	paths.sort()
	var lines: Array[String] = []
	lines.append("# AUTO-GENERATED — run tools/bake-world-manifest.gd to update")
	lines.append("# Do not edit manually.")
	lines.append("extends Node")
	lines.append("")
	lines.append("const BAKED_PATHS: PackedStringArray = [")
	for p in paths:
		lines.append('\t"%s",' % p)
	lines.append("]")
	var file := FileAccess.open("res://autoloads/world-manifest-paths.gd", FileAccess.WRITE)
	file.store_string("\n".join(lines))
	file.close()
	print("Baked %d paths to world-manifest-paths.gd" % paths.size())

func _scan_dir(path: String) -> PackedStringArray:
	var result: PackedStringArray = []
	var dir := DirAccess.open(path)
	if not dir:
		return result
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			result.append_array(_scan_dir(path + entry + "/"))
		elif entry.ends_with(".tres") and not entry.begins_with("_"):
			result.append(path + entry)
		entry = dir.get_next()
	dir.list_dir_end()
	return result

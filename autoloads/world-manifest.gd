# WorldManifest.gd
# Scans res://data/worlds/hubs/ recursively and registers all .tres files.
# To add a new scene: drop the .tres into the correct folder, done.
# To exclude a WIP scene: prefix the filename with _
extends Node

var _registry: Node

const WORLDS_PATH = "res://data/worlds/hubs/"

func _ready() -> void:
	_registry = get_node("/root/Scene_Registry")
	if not _registry:
		push_error("WorldManifest: Could not find SceneRegistry autoload. Check Project > Autoloads.")
		return

	var paths := _scan_dir(WORLDS_PATH)
	_registry.register_paths(paths)

	if OS.is_debug_build():
		print("─── WorldManifest: registered %d scenes ───" % paths.size())
		for p in paths:
			print("  • %s" % p)
		_validate_scene_ids()

func _scan_dir(path: String) -> PackedStringArray:
	var result: PackedStringArray = []
	var dir := DirAccess.open(path)
	if not dir:
		push_error("WorldManifest: Could not open %s" % path)
		return result

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full_path := path + entry
		if dir.current_is_dir():
			result.append_array(_scan_dir(full_path + "/"))
		elif entry.ends_with(".tres") and not entry.begins_with("_"):
			result.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	return result

# ─────────────────────────────────────────
# VALIDATION
# Prints warnings for scene_ids that don't follow the convention:
#   - lowercase only
#   - underscores instead of spaces or hyphens
#   - no empty IDs
# Run at startup in debug builds to catch stale or mismatched IDs early.
# ─────────────────────────────────────────
func _validate_scene_ids() -> void:
	print("─── WorldManifest: validating scene_ids ───")
	var issues := 0
	for id in _registry.get_all_scene_ids():
		if id.is_empty():
			push_warning("  ⚠ empty scene_id found")
			issues += 1
		elif id != id.to_lower():
			push_warning("  ⚠ '%s' has uppercase letters — scene_ids should be lowercase" % id)
			issues += 1
		elif "-" in id:
			push_warning("  ⚠ '%s' has hyphens — use underscores instead" % id)
			issues += 1
		elif " " in id:
			push_warning("  ⚠ '%s' has spaces — use underscores instead" % id)
			issues += 1
	if issues == 0:
		print("  ✓ all %d scene_ids look clean" % _registry.get_all_scene_ids().size())
	else:
		print("  %d issue(s) found — fix scene_id fields in the affected .tres files" % issues)

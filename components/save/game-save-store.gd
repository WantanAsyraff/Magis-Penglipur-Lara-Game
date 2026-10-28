class_name GameSaveStore extends RefCounted
const MAX_BYTES := 32000000
const ROOT := "user://campaign-v1/"

static func valid_path(path: String) -> bool:
	return path.begins_with(ROOT) and not path.contains("..") and path.trim_prefix(ROOT).is_valid_filename() and path.ends_with(".json")

static func read(path: String) -> Dictionary:
	if not valid_path(path) or not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES: return {}
	var parser := JSON.new()
	var parsed := parser.parse(file.get_as_text())
	var envelope: Variant = parser.data if parsed == OK else null
	file.close()
	if not envelope is Dictionary or not envelope.get("payload") is String or not envelope.get("sha256") is String: return {}
	if envelope.payload.sha256_text() != envelope.sha256: return {}
	if parser.parse(envelope.payload) != OK: return {}
	var payload: Variant = parser.data
	return payload if payload is Dictionary else {}

static func write(path: String, data: Dictionary, previous_valid: bool) -> String:
	if not valid_path(path) or data.is_empty(): return "Invalid save destination or snapshot."
	var result := DirAccess.make_dir_recursive_absolute(ROOT)
	if result != OK: return "Cannot create save directory: " + error_string(result)
	# Stale temporary files are never promoted. A new complete write replaces them.
	var payload := JSON.stringify(data)
	var envelope := JSON.stringify({"payload": payload, "sha256": payload.sha256_text()})
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return "Cannot open temporary save: " + error_string(FileAccess.get_open_error())
	file.store_string(envelope)
	file.flush()
	result = file.get_error()
	file.close()
	if result != OK: return "Cannot flush save: " + error_string(result)
	if previous_valid:
		result = DirAccess.copy_absolute(path, path.trim_suffix(".json") + "-backup.json.tmp")
		if result != OK: return "Cannot preserve previous save: " + error_string(result)
		result = DirAccess.rename_absolute(path.trim_suffix(".json") + "-backup.json.tmp", path.trim_suffix(".json") + "-backup.json")
		if result != OK: return "Cannot replace backup: " + error_string(result)
	result = DirAccess.rename_absolute(path + ".tmp", path)
	return "" if result == OK else "Cannot atomically replace save: " + error_string(result)

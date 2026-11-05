@tool
class_name DestructibleObject extends StaticBody2D
@export var config: DestructibleConfig:
	set(value):
		config = value
		if Engine.is_editor_hint(): update_configuration_warnings()
func _enter_tree() -> void:
	if Engine.is_editor_hint(): return
	set_meta("faction_id", &"neutral"); set_meta("spell_team", &"neutral"); set_meta("structural", true)
	add_to_group("destructible")
func _get_configuration_warnings() -> PackedStringArray:
	return config.validate() if config else PackedStringArray(["Assign a DestructibleConfig Resource"])

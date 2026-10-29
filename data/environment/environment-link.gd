class_name EnvironmentLink extends Resource
## Target path is relative to the owning prop; resolves a typed Actuator child.
enum Port { POWER, ENABLE, INPUT, UNLOCK }
@export var target: NodePath
@export var port: Port = Port.POWER
@export var inverted: bool = false
func validate() -> PackedStringArray:
	return PackedStringArray(["Link requires a target path"]) if target.is_empty() else PackedStringArray()

class_name InteractionActuator extends Node
signal changed(active: bool)
@export var links: Array[EnvironmentLink] = []
@export var input_sources: Array[NodePath] = []
var enabled := false
var powered := true
var unlocked := true
var output := false
var logic: EnvironmentDeviceData.Logic = EnvironmentDeviceData.Logic.NONE
var inputs: Dictionary = {}
func configure(data: EnvironmentDeviceData) -> void:
	enabled = data.initial_enabled
	powered = data.initial_power
	unlocked = data.key_id.is_empty()
	logic = data.logic
	output = effective()
func effective() -> bool:
	var input_ok := true
	if logic != EnvironmentDeviceData.Logic.NONE:
		input_ok = logic == EnvironmentDeviceData.Logic.AND and not input_sources.is_empty()
		for path in input_sources:
			var source := get_parent().get_node_or_null(path)
			var value: bool = is_instance_valid(source) and inputs.get(source.get_instance_id(),false)
			if logic == EnvironmentDeviceData.Logic.AND: input_ok = input_ok and value
			else: input_ok = input_ok or value
	return enabled and powered and unlocked and input_ok
func receive(value: bool, port: EnvironmentLink.Port, source: Node = null, pulse: EnvironmentPulse = null) -> void:
	if not SpellExecutor.is_authoritative(self): return
	if pulse == null: pulse = EnvironmentPulse.new()
	if not pulse.enter(self,port): return
	match port:
		EnvironmentLink.Port.POWER: powered = value
		EnvironmentLink.Port.ENABLE: enabled = value
		EnvironmentLink.Port.UNLOCK: unlocked = value
		EnvironmentLink.Port.INPUT:
			if is_instance_valid(source): inputs[source.get_instance_id()] = value
	_recompute(pulse)
func toggle() -> void:
	receive(not enabled,EnvironmentLink.Port.ENABLE)
func _recompute(pulse: EnvironmentPulse, force: bool = false) -> void:
	var value := effective()
	if value == output and not force: return
	output = value
	changed.emit(output)
	propagate(pulse)
func propagate(pulse: EnvironmentPulse = null) -> void:
	if pulse == null: pulse = EnvironmentPulse.new()
	for link in links:
		if link == null or not link.validate().is_empty(): continue
		var target := get_parent().get_node_or_null(link.target)
		if target == null: push_warning("Missing mechanism link: "+str(link.target)); continue
		var actuator := target.get_node_or_null("Actuator") as InteractionActuator
		if actuator: actuator.receive(not output if link.inverted else output,link.port,get_parent(),pulse)
func publish_initial() -> void:
	_recompute(EnvironmentPulse.new(),true)

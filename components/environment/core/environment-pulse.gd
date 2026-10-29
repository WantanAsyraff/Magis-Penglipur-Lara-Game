class_name EnvironmentPulse extends RefCounted
## One propagation transaction may visit each actuator/port once; cycles terminate.
var visited: Dictionary = {}
func enter(node: Node, port: int) -> bool:
	var key := str(node.get_instance_id())+":"+str(port)
	if visited.has(key) or visited.size() >= 256: return false
	visited[key] = true
	return true

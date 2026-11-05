class_name DestructionBudget extends RefCounted
var remaining_destructions := 32
var remaining_spawns := 128
var max_depth := 8
var root_event_id := Crypto.new().generate_random_bytes(16).hex_encode()
func reserve_destruction(depth: int) -> bool:
	if depth > max_depth or remaining_destructions <= 0: return false
	remaining_destructions -= 1
	return true
func reserve_spawn() -> bool:
	if remaining_spawns <= 0: return false
	remaining_spawns -= 1
	return true

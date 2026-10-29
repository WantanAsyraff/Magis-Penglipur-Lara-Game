class_name ItemActionResult extends RefCounted
var ok := false
var message := ""
var world_drop: Node2D
static func success(text: String = "Done", dropped: Node2D = null) -> ItemActionResult:
	var result := ItemActionResult.new(); result.ok = true; result.message = text; result.world_drop = dropped; return result
static func failure(text: String) -> ItemActionResult:
	var result := ItemActionResult.new(); result.message = text; return result

class_name ItemPickupComponent extends Area2D
var _parent_item: DroppedItem
var _is_collectible: bool = false
var _elapsed: float = 0
func init_component(parent: DroppedItem) -> void:
	_parent_item = parent
	if not body_entered.is_connected(_on_body_entered): body_entered.connect(_on_body_entered)
	_parent_item.modulate.a = .5
func _physics_process(delta: float) -> void:
	if _is_collectible or not is_instance_valid(_parent_item): return
	_elapsed += delta
	if _elapsed >= .2: _make_collectible()
func _make_collectible() -> void:
	if not is_instance_valid(_parent_item) or _parent_item.is_queued_for_deletion(): return
	_is_collectible = true
	_parent_item.modulate.a = 1
	for body in get_overlapping_bodies(): _on_body_entered(body)
func _on_body_entered(body: Node2D) -> void:
	if _is_collectible and is_instance_valid(_parent_item) and body.is_in_group("player"): _parent_item.pickup(body)
func _apply_loot_logic() -> void:
	if is_instance_valid(_parent_item): _parent_item.pickup()

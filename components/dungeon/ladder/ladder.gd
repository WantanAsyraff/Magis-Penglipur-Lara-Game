class_name Ladder
extends Area2D

var _players_on_ladder: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_players_on_ladder.append(body)
	body.set_meta("on_ladder", self)

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_players_on_ladder.erase(body)
	if body.has_meta("on_ladder") and body.get_meta("on_ladder") == self:
		body.remove_meta("on_ladder")

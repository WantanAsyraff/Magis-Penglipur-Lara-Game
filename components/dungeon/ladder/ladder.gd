class_name Ladder
extends Area2D

# ─────────────────────────────────────────
# STATE
# ─────────────────────────────────────────
var _players_on_ladder: Array = []

# ─────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	for body in _players_on_ladder:
		if not body.has_meta("climbing_ladder"):
			# Not yet climbing — check if they pressed up
			if Input.is_action_just_pressed("ui_up"):
				body.set_meta("climbing_ladder", self)
				body.set_meta("on_ladder", self)
		else:
			# Already climbing — let go if they press down at the bottom
			# or jump (handled by the player script reading the meta)
			pass

# ─────────────────────────────────────────
# DETECTION
# ─────────────────────────────────────────
func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_players_on_ladder.append(body)
	# Only mark as "near" ladder — climbing starts on input
	body.set_meta("near_ladder", self)

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_players_on_ladder.erase(body)
	# Clear all ladder state when leaving the area
	for key in ["near_ladder", "on_ladder", "climbing_ladder"]:
		if body.has_meta(key) and body.get_meta(key) == self:
			body.remove_meta(key)

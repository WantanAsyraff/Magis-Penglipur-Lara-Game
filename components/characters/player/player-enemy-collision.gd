class_name PlayerEnemyCollision extends RefCounted
## Body exceptions leave terrain, other monsters, projectiles and hurtbox queries intact.
## Called by either actor on spawn, so player/enemy spawn order does not matter.
static func configure(body: CharacterBody2D) -> void:
	var is_player := body.is_in_group("player")
	if not is_player and body.get_meta("spell_team", &"") != &"enemy": return
	var candidates := body.get_tree().get_nodes_in_group("combat_target" if is_player else "player")
	for candidate in candidates:
		if candidate == body or not candidate is CharacterBody2D: continue
		if is_player and candidate.get_meta("spell_team", &"") != &"enemy": continue
		body.add_collision_exception_with(candidate)
		candidate.add_collision_exception_with(body)

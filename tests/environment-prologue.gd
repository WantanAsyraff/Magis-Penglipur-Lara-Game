extends Node2D
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+message)
func _ready() -> void:
	SaveManager.loading = true
	var learned := Player_Global_Data.learned_spells.duplicate()
	for slug in ["rumah-yan-entrance","yan-exam-tutorial"]:
		var scene := load("res://scenes/worlds/hubs/story/prologue/"+slug+".tscn").instantiate() as Node
		add_child(scene)
		for i in 20: await get_tree().physics_frame
		var addon := scene.get_node("World/GameComponents/Environment").get_child(0)
		check(addon.get_child_count() >= 12,"Authored optional apparatus loads in "+slug)
		check(Dialogic.current_timeline == null,"Restoration starts no new dialogue in "+slug)
		var player := Player_Manager.get_local_player() as Player
		player.position = Vector2(450,780)
		Input.action_press("move_right")
		for i in 700:
			await get_tree().physics_frame
			if player.position.x > 4100: break
		Input.action_release("move_right")
		check(player.position.x > 4100,"Main prologue route remains traversable without activating new mechanisms: "+slug)
		if slug == "yan-exam-tutorial": check(not addon.get_node("Turret").actuator.output,"School training turret starts safely unpowered")
		scene.free()
	check(Player_Global_Data.learned_spells == learned,"Optional apparatus does not grant unapproved campaign spells")
	SaveManager.loading = false
	print("ENVIRONMENT_PROLOGUE: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

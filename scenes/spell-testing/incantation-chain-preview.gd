extends Node

# Render the production Player, HUD, resources and delivery pipeline; no fake casts.
var player: Player
var caption: Label
var folder := "res://docs/previews/incantation-assistant/"
func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Run this preview with a display to capture the actual renderer")
		get_tree().quit(1)
		return
	var lab := preload("res://scenes/spell-testing/physics-curriculum-lab.tscn").instantiate()
	add_child(lab)
	lab.selector.get_parent().hide()
	player = lab.player
	player.incantation_strategy = IncantationResolver.Strategy.CHAINED
	var spells: Array[SpellData] = []
	for id in ["phys-strike", "phys-resonate", "phys-shatterwave"]:
		spells.append(load("res://data/magis/spells/" + id + ".tres"))
	Player_Global_Data.equipped_spells.assign(spells)
	Player_Global_Data.spells_updated.emit()
	Player_Global_Data.assistance_mode = 0
	player._sync_spells_from_global()
	player._enter_casting_stance()
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	caption = Label.new()
	caption.position = Vector2(650, 30)
	caption.add_theme_font_size_override("font_size", 24)
	layer.add_child(caption)
	await capture("01-empty", "Guided • equipped chain in the Physics laboratory")
	player._add_sequence("down")
	player._add_sequence("left")
	await capture("02-prefix", "DOWN → LEFT • valid next input and remaining spell directions")
	player._add_sequence("down")
	await get_tree().create_timer(0.35).timeout
	await capture("03-strike", "Strike executed • continue LEFT for Resonate")
	player._add_sequence("left")
	await get_tree().create_timer(0.35).timeout
	await capture("04-resonate", "Resonate executed • continue DOWN for Shatterwave")
	player._add_sequence("down")
	await get_tree().create_timer(0.4).timeout
	await capture("05-chain-complete", "Strike → Resonate → Shatterwave • three actual spell executions")
	player.casting.cooldowns.clear()
	Player_Global_Data.p_curr_mana = 0
	for key in ["down", "left", "down"]: player._add_sequence(key)
	await capture("06-mana-failure", "Valid syntax • failed execution: Not enough mana")
	player._clear_sequence()
	player.incantation_rejected.emit()
	await capture("07-invalid", "Invalid directional input has separate feedback")
	Player_Global_Data.assistance_mode = 1
	Player_Global_Data.assistance_changed.emit(1)
	player._add_sequence("down")
	await capture("08-minimal", "Minimal • sequence and result without prediction")
	Player_Global_Data.assistance_mode = 2
	Player_Global_Data.assistance_changed.emit(2)
	await capture("09-off", "Off • core HUD and repertoire remain available")
	Player_Global_Data.assistance_mode = 0
	Player_Global_Data.assistance_changed.emit(0)
	player._exit_casting_stance()
	await capture("10-outside-stance", "Outside casting stance • assistant hidden")
	print("CHAIN_PREVIEW: 10 rendered captures saved to " + folder)
	get_tree().quit()

func capture(file: String, text: String) -> void:
	caption.text = text
	await get_tree().create_timer(0.12).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(folder)
	var error := get_viewport().get_texture().get_image().save_png(folder + file + ".png")
	if error != OK: push_error("Capture failed: " + error_string(error))

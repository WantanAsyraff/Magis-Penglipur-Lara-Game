extends Node2D
const POHON = preload("res://components/NPCs/enemies/zalam-manifestations/pohon/pohon.tscn")
const BUNGA = preload("res://components/NPCs/enemies/zalam-manifestations/bunga/bunga.tscn")
const GUARDIAN = preload("res://data/npc/enemies/definitions/training-guardian.tres")
var enemies: Array[Enemy] = []
var player: Player
var overlay: Label
var labels: Dictionary = {}
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(.05, .07, .09))
	_floor(Vector2(0, 200), Vector2(6000, 40))
	_floor(Vector2(750, -50), Vector2(40, 460))
	_floor(Vector2(-400, -80), Vector2(350, 28))
	_floor(Vector2(1300, -110), Vector2(350, 28))
	player = Player_Manager.spawn_player(self, Vector2(0, 80)) as Player
	for spell in [load("res://data/magis/spells/phys-force.tres"), load("res://data/magis/spells/thermal-kinetic.tres"), load("res://data/magis/spells/phys-resonate.tres")]:
		Player_Global_Data.add_spell(spell)
		Player_Global_Data.equip_spell(spell)
	Player_Global_Data.combat_mode = true
	var canvas := CanvasLayer.new()
	add_child(canvas)
	overlay = Label.new()
	var panel := PanelContainer.new()
	canvas.add_child(panel)
	panel.anchor_left = 1
	panel.anchor_right = 1
	panel.offset_left = -670
	panel.offset_right = -20
	panel.offset_top = 16
	var style := StyleBoxFlat.new()
	style.bg_color = Color(.07, .1, .14, .95)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	overlay.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay.add_theme_font_size_override("font_size", 18)
	panel.add_child(overlay)
	_spawn(POHON, Vector2(-750, 0))
	_spawn(BUNGA, Vector2(450, 40))
	if "--capture-enemy-arena" in OS.get_cmdline_user_args(): _capture_preview()
func _spawn(scene: PackedScene, point: Vector2, data: EnemyData = null) -> void:
	var enemy := scene.instantiate() as Enemy
	if data: enemy.enemy_data = data
	enemy.position = point
	add_child(enemy)
	enemies.append(enemy)
	var label := Label.new()
	label.position = Vector2(-100, -160)
	label.scale = Vector2.ONE / enemy.scale
	label.add_theme_font_size_override("font_size", 22)
	enemy.add_child(label)
	labels[enemy.get_instance_id()] = label
func _process(_delta: float) -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())
	for enemy in enemies:
		var label: Label = labels[enemy.get_instance_id()]
		var cooldowns: Array[String] = []
		for key in enemy.combat.cooldowns:
			if enemy.combat.cooldowns[key] > 0: cooldowns.append("%s %.1fs" % [key, enemy.combat.cooldowns[key]])
		label.text = "%s | HP %.0f | MP %.0f\n%s | %s\nTarget: %s | CD: %s" % [enemy.enemy_name, enemy.current_health, enemy.spell_mana, Enemy.State.keys()[enemy.current_state], enemy.ai.selected.action_id if enemy.ai.selected else &"none", enemy.detection.player.name if is_instance_valid(enemy.detection.player) else "none", ", ".join(cooldowns)]
	overlay.text = "ENEMY PIPELINE V2\nF1: add Pohon | F2: add Bunga | F3: clear enemies | F4: refill player\nF5: resource-only guardian | F6: stun enemies | F7: defeat enemies\nO: casting | I/J/K/L: directions | P: interrupt\nWall at x=750 tests occlusion. Raised platforms test patrol edges.\nActive enemies: %d (arena cap 8)" % enemies.size()
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_F1:
			if enemies.size() < 8: _spawn(POHON, player.global_position + Vector2(600, -150))
		KEY_F2:
			if enemies.size() < 8: _spawn(BUNGA, player.global_position + Vector2(-450, -50))
		KEY_F3:
			for enemy in enemies: enemy.queue_free()
		KEY_F4:
			Player_Global_Data.p_curr_health = Player_Global_Data.p_max_health
			Player_Global_Data.p_curr_mana = Player_Global_Data.p_max_mana
		KEY_F5:
			if enemies.size() < 8: _spawn(load("res://components/NPCs/enemies/Enemy.tscn"), player.global_position + Vector2(350, -100), GUARDIAN)
		KEY_F6:
			for enemy in enemies: enemy.hitbox._apply_stun(3)
		KEY_F7:
			for enemy in enemies: enemy.hitbox.receive_damage(10000, player)
func _floor(at: Vector2, dimensions: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 16
	body.add_to_group("world")
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = dimensions
	shape.shape = rectangle
	body.add_child(shape)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([-dimensions/2, Vector2(dimensions.x/2, -dimensions.y/2), dimensions/2, Vector2(-dimensions.x/2, dimensions.y/2)])
	visual.color = Color(.2, .27, .3)
	body.add_child(visual)
	add_child(body)
	body.position = at

func _capture_preview() -> void:
	for i in 60: await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/magis-enemy-pipeline.png")

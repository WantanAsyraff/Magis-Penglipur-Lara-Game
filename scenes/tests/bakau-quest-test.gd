extends Node2D
const MONSTERS = [preload("res://components/NPCs/enemies/zalam-manifestations/fishes/snakehead-murrel.tscn"), preload("res://components/NPCs/enemies/zalam-manifestations/bakau/dragonfly.tscn"), preload("res://components/NPCs/enemies/zalam-manifestations/bakau/stone-crab.tscn"), preload("res://components/NPCs/enemies/zalam-manifestations/bakau/crocodile.tscn")]
var player: Player
var board: QuestBoard
var enemies: Array[Enemy] = []
var status: Label
var inventory_label: Label
var save_label: String = ""
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(.04, .10, .11))
	_floor(Vector2(0, 240), Vector2(6000, 40))
	_floor(Vector2(750, 40), Vector2(40, 360))
	_floor(Vector2(-350, 80), Vector2(260, 28))
	_floor(Vector2(1250, 50), Vector2(300, 28))
	player = Player_Manager.spawn_player(self, Vector2(-550, 100)) as Player
	for spell in [load("res://data/magis/spells/phys-force.tres"), load("res://data/magis/spells/phys-strike.tres"), load("res://data/magis/spells/phys-terminal.tres")]:
		Player_Global_Data.add_spell(spell)
		Player_Global_Data.equip_spell(spell)
	Player_Global_Data.combat_mode = true
	board = QuestBoard.new()
	board.npc_id = "bakau_field_researcher"
	board.position = Vector2(-650, 175)
	board.database = load("res://data/quests/bakau-database.tres")
	add_child(board)
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	var hud := VBoxContainer.new()
	hud.position = Vector2(1220, 16)
	hud.custom_minimum_size.x = 660
	canvas.add_child(hud)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 18)
	hud.add_child(status)
	inventory_label = Label.new()
	inventory_label.add_theme_font_size_override("font_size", 16)
	hud.add_child(inventory_label)
	for i in 4: spawn_monster(i)
	if "--capture-bakau" in OS.get_cmdline_user_args(): _capture()
func spawn_monster(kind: int) -> Enemy:
	enemies = enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())
	if enemies.size() >= 16: return null
	var enemy := MONSTERS[kind].instantiate() as Enemy
	enemy.position = player.global_position + Vector2(450 + kind * 140, -70)
	add_child(enemy)
	enemies.append(enemy)
	return enemy
func _process(_delta: float) -> void:
	if status == null: return
	status.text = "BAKAU QUEST FIELD LAB\nE near researcher: offer, accept and hand in all ten quests\nF1–F4: spawn fish, dragonfly, crab, crocodile (cap 16)\nF5: refill health/mana | F6: actual enemy defeats\nF7: collect spawned loot through pickup API | F8: journal\nF9: save | F10: load | F11: toggle inventory\nDrops use provisional independent rates. No progress shortcuts.\n" + save_label
	var lines: Array[String] = ["Inventory"]
	for item in Inventory_Manager.get_all_items(): lines.append("%s ×%d" % [item.item_name, Inventory_Manager.get_item_quantity(item.item_id)])
	inventory_label.text = "\n".join(lines)
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_F1: spawn_monster(0)
		KEY_F2: spawn_monster(1)
		KEY_F3: spawn_monster(2)
		KEY_F4: spawn_monster(3)
		KEY_F5:
			Player_Global_Data.p_curr_health = Player_Global_Data.p_max_health
			Player_Global_Data.p_curr_mana = Player_Global_Data.p_max_mana
		KEY_F6:
			for enemy in enemies:
				if is_instance_valid(enemy) and not enemy.is_queued_for_deletion(): enemy.hitbox.receive_damage(100000, player)
		KEY_F7:
			for item in get_children():
				if item is DroppedItem and not item.is_queued_for_deletion(): item.pickup(player)
		KEY_F8: board.open()
		KEY_F9: save_label = "Saved quest, inventory and reward state." if QuestManager.save_game() else "Save failed: " + QuestManager.last_error
		KEY_F10: save_label = "Loaded quest, inventory and reward state." if QuestManager.load_game() else "No valid matching save."
		KEY_F11: inventory_label.visible = not inventory_label.visible
func _floor(at: Vector2, size: Vector2) -> void:
	var node := StaticBody2D.new()
	node.collision_layer = 16
	node.add_to_group("world")
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	node.add_child(collision)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([-size/2, Vector2(size.x/2, -size.y/2), size/2, Vector2(-size.x/2, size.y/2)])
	visual.color = Color(.16, .30, .25)
	node.add_child(visual)
	add_child(node)
	node.position = at
func _capture() -> void:
	for i in 60: await get_tree().physics_frame
	board.open()
	for i in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/magis-bakau-quests.png")

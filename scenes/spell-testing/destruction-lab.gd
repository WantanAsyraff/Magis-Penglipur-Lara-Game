extends Node2D
## Actual Player and production spell delivery; no injected hit/health UI responses.
@export var debug_mode := true
const BASE := "res://components/environment/destruction/"
const PRESETS := ["wooden-crate", "glass-barrier", "stone-block", "fragile-platform", "explosive-barrel", "poison-canister", "fragmentation-container", "minion-pod"]
const LOADOUT: Array[SpellData] = [preload("res://data/magis/spells/phys-force.tres"),preload("res://data/magis/spells/phys-strike.tres"),preload("res://data/magis/spells/phys-resonate.tres"),preload("res://data/magis/spells/phys-shatterwave.tres")]
var player: Player
var props: Array[DestructibleObject] = []
var room: Node2D
var _equipped: Array[SpellData] = []
var _previous_player: Node2D
var overview: Camera2D
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("101b28"))
	_equipped.assign(Player_Global_Data.equipped_spells)
	_previous_player = Player_Manager.get_local_player()
	floor_at(Vector2(0,220),Vector2(3300,40))
	floor_at(Vector2(-300,-220),Vector2(1900,24))
	for index in 3: floor_at(Vector2(-1250 + index*170,100-index*100),Vector2(130,18))
	room = Node2D.new(); room.name = "DestructionStations"; add_child(room)
	reset_props()
	Player_Global_Data.equipped_spells.assign(LOADOUT); Player_Global_Data.spells_updated.emit()
	Player_Global_Data.p_curr_health = Player_Global_Data.p_max_health; Player_Global_Data.p_curr_mana = Player_Global_Data.p_max_mana
	Player_Global_Data.combat_mode = true; Player_Global_Data.p_moveable = true
	player = load("res://scenes/combat/boss-prototype-player.tscn").instantiate() as Player
	player.set("training_spells",LOADOUT.duplicate()); player.position = Vector2(-1230,65)
	add_child(player); Player_Manager.players[Player_Manager.get_local_peer_id()] = player
	overview = Camera2D.new(); overview.position = Vector2(0,-100); overview.zoom = Vector2(0.55,0.55); add_child(overview)
	overview.enabled = false
	if debug_mode:
		var layer := CanvasLayer.new(); add_child(layer)
		var hint := Label.new(); hint.text = "DESTRUCTION LAB · R select prop · O casting · I/J/K/L incantation\nF6 cast Force at selected prop · F7 reset · F8 refill · F9 overview · F10 Physics lab"
		hint.position = Vector2(24,340); hint.add_theme_font_size_override("font_size",16); layer.add_child(hint)
func floor_at(at: Vector2, extent: Vector2) -> void:
	var body := StaticBody2D.new(); body.collision_layer = 16; body.add_to_group("world"); body.position = at
	var shape := CollisionShape2D.new(); var rect := RectangleShape2D.new(); rect.size = extent; shape.shape = rect; body.add_child(shape)
	var visual := Polygon2D.new(); visual.color = Color("344758"); visual.polygon = PackedVector2Array([-extent/2,Vector2(extent.x/2,-extent.y/2),extent/2,Vector2(-extent.x/2,extent.y/2)]); body.add_child(visual); add_child(body)
func reset_props() -> void:
	if room:
		for child in room.get_children(): child.free()
		if room.has_meta("_destruction_runtime"): room.remove_meta("_destruction_runtime")
	var runtime := get_meta("_destruction_runtime",null) as DestructionRuntime if has_meta("_destruction_runtime") else null
	if runtime: runtime.free(); remove_meta("_destruction_runtime")
	props.clear()
	for index in PRESETS.size():
		var prop := load(BASE + "presets/" + PRESETS[index] + ".tscn").instantiate() as DestructibleObject
		prop.position = Vector2(-910+index*260,200-prop.get_node("SolidCollision").shape.size.y/2)
		room.add_child(prop); props.append(prop)
		if debug_mode:
			var label := Label.new(); label.text = prop.config.display_name; label.position = Vector2(-90,-110); label.add_theme_font_size_override("font_size",16); prop.add_child(label)
	for index in 12:
		var prop := load(BASE+"presets/explosive-barrel.tscn").instantiate() as DestructibleObject
		prop.config = prop.config.duplicate(true); prop.position = Vector2(-1100+index*125,-270)
		var explosion := prop.config.behaviors[0] as AreaExplosionBehavior
		explosion.base_damage = 100; explosion.targets.require_line_of_sight = false
		room.add_child(prop); props.append(prop)
func _unhandled_key_input(event: InputEvent) -> void:
	if not debug_mode or not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode if event.physical_keycode else event.keycode:
		KEY_F6:
			player.casting.cooldowns.clear(); player._cast_resolved(LOADOUT[0])
		KEY_F7: reset_props()
		KEY_F8: Player_Global_Data.p_curr_mana = Player_Global_Data.p_max_mana; Player_Global_Data.p_curr_health = Player_Global_Data.p_max_health
		KEY_F9:
			overview.enabled = not overview.enabled
			if overview.enabled: overview.make_current()
			else: player.camera.make_current()
		KEY_F10: get_tree().change_scene_to_file("res://scenes/spell-testing/physics-curriculum-lab.tscn")
func _exit_tree() -> void:
	Player_Global_Data.equipped_spells.assign(_equipped); Player_Global_Data.spells_updated.emit()
	if is_instance_valid(_previous_player): Player_Manager.players[Player_Manager.get_local_peer_id()] = _previous_player
	else: Player_Manager.players.erase(Player_Manager.get_local_peer_id())

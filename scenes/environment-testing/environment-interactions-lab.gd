class_name EnvironmentLab extends Node2D
signal initialized
const LOADOUT: Array[SpellData] = [
	preload("res://data/magis/spells/thermal-kinetic.tres"),
	preload("res://data/magis/spells/phys-force.tres"),
	preload("res://data/magis/spells/phys-strike.tres"),
	preload("res://data/magis/spells/phys-resonate.tres"),
]
var player: Player
var station_index := 1
var _snapshot: Dictionary = {}
var _previous_player: Node2D
var _return_position := Vector2.ZERO
var controls: VBoxContainer
var _had_keys := false
var _keys: Array = []
func _ready() -> void:
	_initialize.call_deferred()
func _initialize() -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		push_error("Environmental lab is an offline test scene"); return
	for property in ["p_curr_health","p_curr_mana","combat_mode","p_moveable","p_jumpable","current_dash_charges","is_casting","is_dashing"]:
		_snapshot[property] = Player_Global_Data.get(property)
	_snapshot.learned = Player_Global_Data.learned_spells.duplicate()
	_snapshot.equipped = Player_Global_Data.equipped_spells.duplicate()
	_had_keys = Player_Global_Data.has_meta("keys"); _keys = Player_Global_Data.get_meta("keys",[]).duplicate()
	_previous_player = Player_Manager.get_local_player(); _return_position = Player_Manager.last_player_position
	Player_Global_Data.equipped_spells.assign(LOADOUT)
	Player_Global_Data.combat_mode = true; Player_Global_Data.p_moveable = true; Player_Global_Data.p_jumpable = true
	Player_Global_Data.p_curr_health = Player_Global_Data.p_max_health; Player_Global_Data.p_curr_mana = Player_Global_Data.p_max_mana
	player = load("res://scenes/combat/boss-prototype-player.tscn").instantiate()
	player.training_spells.assign(LOADOUT); player.set_meta("quest_owner_id","")
	player.position = Vector2(150,400); add_child(player)
	Player_Manager.players[Player_Manager.get_local_peer_id()] = player
	player.camera.get_node("UI").scale = Vector2(.55,.55)
	player.camera.enabled = false; player.camera.overworldUI.hide(); player.camera.combatUI.show()
	player.get_node("PlayerDeathComponent").set_process(false)
	player.mana_regen_rate = 35
	$LabCamera.make_current()
	_build_controls()
	Player_Global_Data.spells_updated.emit()
	initialized.emit()
	if "--capture-environment" in OS.get_cmdline_user_args(): load("res://tests/environment-preview.gd").capture(self)
func _build_controls() -> void:
	var canvas := CanvasLayer.new(); add_child(canvas)
	var panel := VBoxContainer.new(); controls = panel; panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT); panel.position = Vector2(get_viewport_rect().size.x-580,12); canvas.add_child(panel)
	var title := Label.new(); title.text = "ENVIRONMENT LAB · temporary loadout"; panel.add_child(title)
	var row := HBoxContainer.new(); panel.add_child(row)
	for i in range(1,13):
		var button := Button.new(); button.text = "%02d" % i; button.focus_mode = Control.FOCUS_NONE; row.add_child(button); button.pressed.connect(visit.bind(i))
	var actions := HBoxContainer.new(); panel.add_child(actions)
	for entry in [["Reset station",reset_station],["Reset room",reset_room],["Exit lab",exit_lab]]:
		var button := Button.new(); button.text = entry[0]; button.focus_mode = Control.FOCUS_NONE; actions.add_child(button); button.pressed.connect(entry[1])
	var footer := Label.new(); footer.text = "F interact · E push · Q enemies · R devices · B phone\nO toggles casting; use I/J/K/L for the equipped incantations."; footer.add_theme_font_size_override("font_size",14); panel.add_child(footer)
func _process(_delta: float) -> void:
	if is_instance_valid(controls): controls.position = Vector2(get_viewport_rect().size.x-580,12)
func visit(index: int) -> void:
	station_index = clampi(index,1,12)
	var station: Node2D = $Stations.get_node("Station%02d" % station_index)
	player.casting.cancel("Station changed"); player._exit_casting_stance(); player.environment_target.clear(); player.target_lock.locked_target = null; player.target_lock.refresh()
	player.global_position = station.global_position+Vector2(150,400); player.velocity = Vector2.ZERO; player.reset_physics_interpolation()
	$LabCamera.global_position = station.global_position+Vector2(900,260); $LabCamera.reset_physics_interpolation()
func reset_station() -> void:
	_reset($Stations.get_node("Station%02d" % station_index)); visit(station_index)
func reset_room() -> void:
	for station in $Stations.get_children(): _reset(station)
	visit(1)
func _reset(station: Node) -> void:
	for prop in station.get_children():
		if prop is EnvironmentDevice or prop is EnvironmentMovingPlatform or prop is EnvironmentCrate: prop.reset()
	for prop in station.get_children():
		if prop is EnvironmentDevice or prop is EnvironmentMovingPlatform: prop.actuator.call_deferred("publish_initial")
	if is_instance_valid(player):
		CombatLifecycle.cleanup(player); player.hitbox.clear_all_effects()
		Player_Global_Data.p_curr_health = Player_Global_Data.p_max_health; Player_Global_Data.p_curr_mana = Player_Global_Data.p_max_mana
func exit_lab() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/intro-menus/main-menu.tscn")
func _exit_tree() -> void:
	if _snapshot.is_empty(): return
	Player_Global_Data.learned_spells.assign(_snapshot.learned); Player_Global_Data.equipped_spells.assign(_snapshot.equipped)
	for property in _snapshot:
		if property not in ["learned","equipped"]: Player_Global_Data.set(property,_snapshot[property])
	if _had_keys: Player_Global_Data.set_meta("keys",_keys)
	elif Player_Global_Data.has_meta("keys"): Player_Global_Data.remove_meta("keys")
	Player_Manager.last_player_position = _return_position
	if is_instance_valid(_previous_player): Player_Manager.players[Player_Manager.get_local_peer_id()] = _previous_player
	else: Player_Manager.players.erase(Player_Manager.get_local_peer_id())
	Player_Global_Data.spells_updated.emit()

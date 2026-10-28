class_name BossPrototypeRoom extends Node2D

enum State { READY, INTRO, ACTIVE, VICTORY, DEFEAT, RESETTING }
signal initialized
signal encounter_state_changed(state: State)
const PLAYER := preload("res://scenes/combat/boss-prototype-player.tscn")
const GUARDIAN := preload("res://components/NPCs/enemies/boss/resonance-guardian.tscn")
const HEALTH_BAR := preload("res://scenes/ui/boss/boss-health-bar.tscn")
const LOADOUT: Array[SpellData] = [
	preload("res://data/magis/spells/phys-force.tres"),
	preload("res://data/magis/spells/phys-strike.tres"),
	preload("res://data/magis/spells/phys-resonate.tres"),
	preload("res://data/magis/spells/phys-shatterwave.tres"),
]
@export var intro_duration: float = 1.0
@export var player_health: int = 400
@export var player_mana: float = 400
@export var mana_regeneration: float = 18
@export_file("*.tscn") var return_scene: String = ""
var state: State = State.RESETTING
var player: Player
var boss: Boss
var health_ui: BossHealthBar
var _epoch: int = 0
var _snapshot: Dictionary = {}
var _return_position := Vector2.ZERO
var _ready_done := false
var _previous_player: Node2D
@onready var actors: Node2D = $Actors
@onready var title: Label = %EncounterTitle
@onready var description: Label = %EncounterDescription
@onready var menu: PanelContainer = %EncounterMenu
@onready var begin_button: Button = %Begin
@onready var retry_button: Button = %Retry
@onready var exit_button: Button = %Return

func _ready() -> void:
	# Let autoload campaign restoration finish before snapshotting caller state.
	_initialize.call_deferred()

func _initialize() -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		title.text = "Standalone prototype"
		description.text = "Open this room in an offline session."
		begin_button.disabled = true
		retry_button.hide()
		exit_button.pressed.connect(_return_to_area)
		initialized.emit()
		return
	_snapshot = {
		"learned": Player_Global_Data.learned_spells.duplicate(), "equipped": Player_Global_Data.equipped_spells.duplicate(),
		"health": Player_Global_Data.p_curr_health, "mana": Player_Global_Data.p_curr_mana,
		"combat": Player_Global_Data.combat_mode, "moveable": Player_Global_Data.p_moveable,
		"jumpable": Player_Global_Data.p_jumpable, "dash_charges": Player_Global_Data.current_dash_charges,
	}
	_previous_player = Player_Manager.get_local_player()
	_return_position = Player_Manager.last_player_position
	if return_scene.is_empty():
		var previous := Player_Global_Data.current_scene
		if previous != scene_file_path and ResourceLoader.exists(previous): return_scene = previous
	exit_button.text = "Return to previous area" if not return_scene.is_empty() else "Return to main menu"
	begin_button.pressed.connect(begin_encounter)
	retry_button.pressed.connect(retry_encounter)
	exit_button.pressed.connect(_return_to_area)
	$StartTrigger.body_entered.connect(func(body):
		if body == player and state == State.READY: begin_encounter())
	Player_Global_Data.health_changed.connect(_on_player_health)
	Player_Global_Data.equipped_spells.assign(LOADOUT)
	Player_Global_Data.spells_updated.emit()
	_spawn_encounter()
	_set_state(State.READY)
	_ready_done = true
	initialized.emit()
	if "--capture-boss-prototype" in OS.get_cmdline_user_args():
		load("res://tests/boss-prototype-preview.gd").capture(self)

func _spawn_encounter() -> void:
	Player_Global_Data.combat_mode = false
	Player_Global_Data.p_curr_health = mini(player_health, Player_Global_Data.p_max_health)
	Player_Global_Data.p_curr_mana = minf(player_mana, Player_Global_Data.p_max_mana)
	Player_Global_Data.p_moveable = true
	Player_Global_Data.p_jumpable = true
	Player_Global_Data.is_casting = false
	Player_Global_Data.is_dashing = false
	player = PLAYER.instantiate() as Player
	player.set("training_spells", LOADOUT.duplicate())
	player.set_meta("quest_owner_id", "")
	player.set_multiplayer_authority(Player_Manager.get_local_peer_id())
	player.position = $PlayerSpawn.position
	actors.add_child(player)
	Player_Manager.players[Player_Manager.get_local_peer_id()] = player
	# This room owns defeat/retry; the shared player's campaign death routing stays intact elsewhere.
	player.get_node("PlayerDeathComponent").set_process(false)
	player.get_node("GodModeComponent").set_process_unhandled_input(false)
	player.mana_regen_rate = mana_regeneration
	player.camera.enabled = false
	player.camera.overworldUI.hide()
	player.camera.combatUI.show()
	# Leave the room's two-line controls footer below the status / ability row.
	var status_hud := player.camera.get_node("UI/StatusEffectsHUD") as StatusEffectsHUD
	status_hud.push_panel.offset_top -= 56
	status_hud.push_panel.offset_bottom -= 56
	$ArenaCamera.make_current()
	player.camera.top_level = true
	player.camera.global_position = Vector2(1200, 0)
	player.camera.zoom = Vector2(.7, .7)
	player.camera.position_smoothing_enabled = false
	player.camera.reset_smoothing()
	boss = GUARDIAN.instantiate() as Boss
	boss.combat_enabled = false
	boss.position = $BossSpawn.position
	actors.add_child(boss)
	boss.boss_died.connect(_on_boss_died)
	if is_instance_valid(health_ui):
		health_ui.get_parent().remove_child(health_ui)
		health_ui.queue_free()
	health_ui = HEALTH_BAR.instantiate() as BossHealthBar
	$CanvasLayer.add_child(health_ui)
	health_ui.bind_boss(boss)

func _set_state(value: State) -> void:
	state = value
	menu.visible = state != State.ACTIVE
	begin_button.visible = state == State.READY
	retry_button.visible = state in [State.VICTORY, State.DEFEAT]
	exit_button.visible = state in [State.READY, State.VICTORY, State.DEFEAT]
	match state:
		State.READY:
			title.text = "Penjaga Resonans"
			description.text = "Three phases. Watch the warnings, then counterattack.\nBegin here or cross the center of the arena."
		State.INTRO:
			title.text = "The guardian awakens"
			description.text = "Penjaga Resonans · 500 HP"
		State.VICTORY:
			title.text = "Victory"
			description.text = "Penjaga Resonans has fallen."
		State.DEFEAT:
			title.text = "Defeat"
			description.text = "Watch the windup. Leave the warning area before impact."
		State.RESETTING:
			title.text = "Resetting encounter…"
			description.text = ""
	encounter_state_changed.emit(state)

func begin_encounter() -> void:
	if state != State.READY or not is_instance_valid(boss): return
	_epoch += 1
	var token := _epoch
	_set_state(State.INTRO)
	Player_Global_Data.p_moveable = false
	player.set_process_unhandled_input(false)
	await get_tree().create_timer(maxf(intro_duration, .01), false).timeout
	if not is_inside_tree() or token != _epoch or state != State.INTRO: return
	Player_Global_Data.p_moveable = true
	player.set_process_unhandled_input(true)
	Player_Global_Data.combat_mode = true
	boss.set_combat_enabled(true)
	_set_state(State.ACTIVE)

func _on_boss_died() -> void:
	if state == State.ACTIVE: _finish(State.VICTORY)

func _on_player_health(value: int) -> void:
	if state == State.ACTIVE and value <= 0:
		player._on_died()
		_finish(State.DEFEAT)

func _finish(result: State) -> void:
	if state != State.ACTIVE: return
	_epoch += 1
	boss.set_combat_enabled(false)
	player.is_dashing = false
	player.velocity = Vector2.ZERO
	player.casting.cancel("Encounter ended")
	player._exit_casting_stance()
	CombatLifecycle.cleanup(player)
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.hitbox.set_invincible(true)
	# The menu owns input now; retries restore movement without a scene reload.
	Player_Global_Data.p_moveable = true
	_set_state(result)
	retry_button.grab_focus()

func retry_encounter() -> void:
	if state not in [State.VICTORY, State.DEFEAT]: return
	_epoch += 1
	var token := _epoch
	_set_state(State.RESETTING)
	if is_instance_valid(boss): boss.set_combat_enabled(false)
	for actor in actors.get_children():
		CombatLifecycle.cleanup(actor)
		actor.queue_free()
	await get_tree().process_frame
	if not is_inside_tree() or token != _epoch: return
	Player_Manager.players.erase(Player_Manager.get_local_peer_id())
	_spawn_encounter()
	_set_state(State.READY)
	await begin_encounter()

func _return_to_area() -> void:
	var destination := return_scene
	if destination.is_empty() or not ResourceLoader.exists(destination):
		destination = "res://scenes/ui/menus/intro-menus/main-menu.tscn"
	Player_Manager.last_player_position = _return_position
	get_tree().change_scene_to_file(destination)

func _exit_tree() -> void:
	_epoch += 1
	if not _ready_done: return
	state = State.RESETTING
	if is_instance_valid(boss): boss.set_combat_enabled(false)
	if is_instance_valid(player):
		player.casting.cancel("Leaving prototype")
		CombatLifecycle.cleanup(player)
		player.set_process_unhandled_input(false)
	Player_Manager.players.erase(Player_Manager.get_local_peer_id())
	if is_instance_valid(_previous_player) and not _previous_player.is_queued_for_deletion():
		Player_Manager.players[Player_Manager.get_local_peer_id()] = _previous_player
	Player_Global_Data.learned_spells.assign(_snapshot.learned)
	Player_Global_Data.equipped_spells.assign(_snapshot.equipped)
	Player_Global_Data.p_curr_health = _snapshot.health
	Player_Global_Data.p_curr_mana = _snapshot.mana
	Player_Global_Data.p_moveable = _snapshot.moveable
	Player_Global_Data.p_jumpable = _snapshot.jumpable
	Player_Global_Data.is_dashing = false
	Player_Global_Data.current_dash_charges = _snapshot.dash_charges
	Player_Global_Data.is_casting = false
	Player_Global_Data.combat_mode = _snapshot.combat
	Player_Global_Data.spells_updated.emit()

func _draw() -> void:
	draw_rect(Rect2(-4000, -4000, 10000, 10000), Color("101b28"))
	for x in range(0, 2401, 300):
		draw_line(Vector2(x, -500), Vector2(x, 460), Color("1c2c3c"), 2)
	draw_arc(Vector2(1200, -80), 260, 0, TAU, 96, Color("253c50"), 4, true)
	draw_arc(Vector2(1200, -80), 220, 0, TAU, 96, Color("203347"), 2, true)
	for i in 8:
		var angle := TAU * i / 8
		draw_line(Vector2(1200, -80) + Vector2.from_angle(angle) * 205, Vector2(1200, -80) + Vector2.from_angle(angle) * 275, Color("2f4c61"), 4)
	draw_rect(Rect2(-80, 480, 2560, 4000), Color("354657"))
	draw_line(Vector2(0, 480), Vector2(2400, 480), Color("b79c65"), 4)
	for x in range(0, 2400, 120): draw_line(Vector2(x, 500), Vector2(x + 100, 500), Color("4c6071"), 3)
	draw_rect(Rect2(-80, -900, 80, 1540), Color("25374a"))
	draw_rect(Rect2(2400, -900, 80, 1540), Color("25374a"))

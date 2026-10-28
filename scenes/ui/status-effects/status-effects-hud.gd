class_name StatusEffectsHUD extends HBoxContainer
@export var max_icons: int = 8
var actor: Player
var manager: ActiveEffectManager
var icons: Array[StatusEffectIcon] = []
var overflow: Label
var elapsed: float = 0
var dialogue_active := false
func _ready() -> void:
	add_theme_constant_override("separation", 5)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in max_icons:
		var icon := preload("res://scenes/ui/status-effects/status-effect-icon.tscn").instantiate() as StatusEffectIcon
		add_child(icon)
		icons.append(icon)
	overflow = Label.new()
	add_child(overflow)
	Dialogic.timeline_started.connect(func(): dialogue_active = true; hide())
	Dialogic.timeline_ended.connect(func(): dialogue_active = false; refresh())
	Player_Manager.local_player_changed.connect(_local_changed)
	bind_player(Player_Manager.get_local_player() as Player)
func _local_changed(player: Node2D) -> void:
	if not is_inside_tree(): return
	bind_player(player as Player)

func bind_player(player: Player) -> void:
	if manager and manager.changed.is_connected(_changed): manager.changed.disconnect(_changed)
	actor = player
	manager = actor.hitbox.effects if is_instance_valid(actor) else null
	if manager: manager.changed.connect(_changed)
	refresh()
func _exit_tree() -> void:
	if Player_Manager.local_player_changed.is_connected(_local_changed): Player_Manager.local_player_changed.disconnect(_local_changed)
	if manager and manager.changed.is_connected(_changed): manager.changed.disconnect(_changed)
func _changed(_key: String) -> void:
	refresh()
func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < .1: return
	elapsed = 0
	var local := Player_Manager.get_local_player() as Player
	if actor != local: bind_player(local)
	else: refresh()
func grouped_entries() -> Array[Dictionary]:
	var groups := {}
	if manager:
		for entry in manager.get_entries():
			# Classification is part of identity, allowing mixed-origin keys to remain accurate.
			var id: String = entry.key + (":buff" if entry.beneficial else ":debuff")
			if not groups.has(id): groups[id] = {"key": entry.key, "count": 0, "remaining": 0.0, "duration": 0.0, "beneficial": entry.beneficial}
			groups[id].count += 1
			groups[id].remaining = maxf(groups[id].remaining, entry.remaining)
			groups[id].duration = maxf(groups[id].duration, entry.duration)
	var result: Array[Dictionary] = []
	result.assign(groups.values())
	result.sort_custom(func(a,b):
		if a.beneficial != b.beneficial: return not a.beneficial
		var pa: int = StatusPresentation.describe(a.key)[3]
		var pb: int = StatusPresentation.describe(b.key)[3]
		return pa < pb if pa != pb else a.key < b.key)
	return result
func refresh() -> void:
	if not is_inside_tree() or not is_node_ready(): return
	var rows := grouped_entries()
	var phone := get_tree().get_first_node_in_group("phone_ui")
	var phone_open: bool = phone != null and phone.phone_selected
	visible = not phone_open and not rows.is_empty() and is_instance_valid(actor) and not actor.get_meta("combat_dead",false) and Player_Global_Data.is_alive() and not get_tree().paused and not dialogue_active and not QuestOfferDialog.is_open()
	for i in icons.size():
		icons[i].visible = i < rows.size()
		if i < rows.size(): icons[i].present(rows[i])
	overflow.visible = rows.size() > max_icons
	overflow.text = "+%d" % (rows.size()-max_icons)
	overflow.tooltip_text = "Additional active effects"
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED: hide()

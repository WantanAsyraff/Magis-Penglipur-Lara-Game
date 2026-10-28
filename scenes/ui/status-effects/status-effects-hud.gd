class_name StatusEffectsHUD extends Control
@export var max_icons: int = 8
var actor: Player
var manager: ActiveEffectManager
var icons: Array[StatusEffectIcon] = []
var effect_row: GridContainer
var push_panel: PanelContainer
var push_label: Label
var push_progress: ProgressBar
var overflow: Label
var elapsed: float = 0
var dialogue_active := false
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_row = GridContainer.new()
	effect_row.name = "ActiveEffects"
	effect_row.add_theme_constant_override("h_separation", 8)
	effect_row.add_theme_constant_override("v_separation", 8)
	effect_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(effect_row)
	effect_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	push_panel = PanelContainer.new()
	push_panel.custom_minimum_size = Vector2(112, 52)
	push_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.08, 0.12, 0.92)
	style.border_color = Color(0.4, 0.8, 0.95)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 8
	style.content_margin_right = 8
	push_panel.add_theme_stylebox_override("panel", style)
	add_child(push_panel)
	push_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	push_panel.offset_left = 24
	push_panel.offset_top = -76
	push_panel.offset_right = 136
	push_panel.offset_bottom = -20
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	push_panel.add_child(column)
	push_label = Label.new()
	push_label.add_theme_font_size_override("font_size", 15)
	column.add_child(push_label)
	push_progress = ProgressBar.new()
	push_progress.custom_minimum_size.y = 5
	push_progress.show_percentage = false
	push_progress.max_value = 1.0
	column.add_child(push_progress)
	for i in max_icons:
		var icon := preload("res://scenes/ui/status-effects/status-effect-icon.tscn").instantiate() as StatusEffectIcon
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		effect_row.add_child(icon)
		icons.append(icon)
	overflow = Label.new()
	effect_row.add_child(overflow)
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
	push_panel.visible = is_instance_valid(actor) and actor.combat_mode and actor.pushback != null
	if push_panel.visible:
		var ability := actor.pushback
		var keys := InputMap.action_get_events("pushback")
		var key := keys[0].as_text() if not keys.is_empty() else "Push"
		if not keys.is_empty() and keys[0] is InputEventKey:
			var event := keys[0] as InputEventKey
			key = OS.get_keycode_string(event.physical_keycode if event.physical_keycode else event.keycode)
		push_label.text = "%s  Push · %s" % [key, "%.1fs" % ability.remaining if ability.remaining > 0 else "Ready"]
		push_panel.tooltip_text = "Push nearby enemies away. %.1fs cooldown. Interactions take priority." % ability.cooldown
		push_progress.value = 1.0 - ability.remaining / maxf(ability.cooldown, 0.001)
	visible = not phone_open and (not rows.is_empty() or push_panel.visible) and is_instance_valid(actor) and not actor.get_meta("combat_dead",false) and Player_Global_Data.is_alive() and not get_tree().paused and not dialogue_active and not QuestOfferDialog.is_open()
	effect_row.visible = not rows.is_empty()
	var limit := _layout_effects(rows.size())
	for i in icons.size():
		icons[i].visible = i < mini(rows.size(),limit)
		if i < mini(rows.size(),limit): icons[i].present(rows[i])
	overflow.visible = rows.size() > limit
	overflow.text = "+%d" % (rows.size()-limit)
	overflow.tooltip_text = "Additional active effects"
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED: hide()

func _layout_effects(group_count: int) -> int:
	if not is_instance_valid(actor): return max_icons
	var ui: Control = actor.camera.combatUI if actor.combat_mode else actor.camera.overworldUI
	var panel := ui.get_node("PanelContainer") as Control
	var rect := panel.get_global_rect()
	var screen := get_viewport_rect().size
	var left := maxf(rect.end.x + 16,678)
	var top := maxf(rect.position.y + (rect.size.y - 52)/2.0,128)
	if screen.x - left - 24 < 52:
		left = 24
		top = rect.end.y + 16
	var available := maxf(52,screen.x-left-24)
	effect_row.columns = clampi(int((available+8)/60.0),1,max_icons)
	effect_row.position = Vector2(left,top)
	effect_row.size = Vector2(available,0)
	var rows := maxi(1,int((screen.y-top-24+8)/60.0))
	var slots := rows * effect_row.columns
	if group_count > mini(max_icons,slots): slots -= 1
	return clampi(slots,0,max_icons)

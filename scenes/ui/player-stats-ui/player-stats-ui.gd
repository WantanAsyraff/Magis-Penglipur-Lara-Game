class_name UserStatsUI extends PhoneAppPage
var profile_name: Label
var role_label: Label
var mood_label: Label
var level_label: Label
var currency_label: Label
var status_label: Label
var health_bar: ProgressBar
var mana_bar: ProgressBar
var health_label: Label
var mana_label: Label
var dash_label: Label
var xp_label: Label
var quest_label: Label
var subjects_label: Label
var academic_labels: Array[Label] = []
var repertoire: VBoxContainer
var details_scroll: ScrollContainer
var _stamp := 0
var _elapsed := 0.0
func _ready() -> void:
	build_page("Profile","MAGIS / PERSONAL RECORD","Your progress, your studies, your journey.")
	var identity := card(NAVY); identity.custom_minimum_size.x = 295; page_body.add_child(identity)
	var identity_body := column(10); identity.add_child(identity_body)
	identity_body.add_child(text("STUDENT RECORD",12,Color("a4c9c2")))
	var portrait := TextureRect.new(); portrait.texture = preload("res://assets/player/yan-concept-art.png"); portrait.custom_minimum_size = Vector2(0,110); portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL; portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; identity_body.add_child(portrait)
	profile_name = text("",26,Color.WHITE); profile_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; identity_body.add_child(profile_name)
	role_label = text("",15,Color("c6d5d7")); role_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; identity_body.add_child(role_label)
	level_label = text("",16,Color("b5d9ce")); identity_body.add_child(level_label)
	mood_label = text("",14,Color("c6d5d7")); mood_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; identity_body.add_child(mood_label)
	for field in [profile_name,role_label,mood_label]:
		field.max_lines_visible = 2; field.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var spacer := Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL; identity_body.add_child(spacer)
	identity_body.add_child(HSeparator.new()); identity_body.add_child(text("WALLET",12,Color("a4c9c2")))
	currency_label = text("",26,Color.WHITE); identity_body.add_child(currency_label)
	var scroll := ScrollContainer.new(); details_scroll = scroll; scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.follow_focus = true; page_body.add_child(scroll)
	var content := column(18); content.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(content)
	var heading := HBoxContainer.new(); content.add_child(heading)
	var heading_text := text("At a glance",22); heading_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL; heading.add_child(heading_text)
	status_label = text("",14,ACCENT); heading.add_child(status_label)
	var vitals := HBoxContainer.new(); vitals.add_theme_constant_override("separation",14); content.add_child(vitals)
	var health := _vital(vitals,"HEALTH",Color("4b8c76")); health_label = health.label; health_bar = health.bar
	var mana := _vital(vitals,"MANA",Color("577c9e")); mana_label = mana.label; mana_bar = mana.bar
	dash_label = text("",14,MUTED); content.add_child(dash_label)
	var progress := card(); content.add_child(progress); var progress_body := column(12); progress.add_child(progress_body); progress_body.add_child(text("Progression",20))
	xp_label = _field(progress_body,"Experience"); quest_label = _field(progress_body,"Quests completed"); subjects_label = _field(progress_body,"Subjects completed")
	var academic := card(); content.add_child(academic); var academic_body := column(12); academic.add_child(academic_body); academic_body.add_child(text("Academic path",20))
	for title in ["Field","Major","Minor"]: academic_labels.append(_field(academic_body,title))
	var spells := card(); content.add_child(spells); repertoire = column(10); spells.add_child(repertoire)
	_refresh()
func _vital(parent: Control, title: String, color: Color) -> Dictionary:
	var panel := card(); panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; parent.add_child(panel)
	var body := column(10); panel.add_child(body); body.add_child(text(title,12,MUTED)); var value := text("",25); body.add_child(value)
	var bar := ProgressBar.new(); bar.show_percentage = false; bar.custom_minimum_size.y = 7
	var fill := StyleBoxFlat.new(); fill.bg_color = color; fill.set_corner_radius_all(4); bar.add_theme_stylebox_override("fill",fill)
	var bg := StyleBoxFlat.new(); bg.bg_color = Color("e6eae3"); bg.set_corner_radius_all(4); bar.add_theme_stylebox_override("background",bg); body.add_child(bar)
	return {"label":value,"bar":bar}
func _field(parent: Control, title: String) -> Label:
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation",20); parent.add_child(row)
	var key := text(title,14,MUTED); key.custom_minimum_size.x = 150; row.add_child(key)
	var value := text("",16); value.size_flags_horizontal = Control.SIZE_EXPAND_FILL; value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; row.add_child(value); return value
func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < .2: return
	_elapsed = 0
	_refresh()
func _refresh() -> void:
	var actor := Player_Manager.get_local_player() as Player
	var dash_max := actor.get_max_dash_charges() if actor != null else Player_Global_Data.MAX_DASH_CHARGES
	var state := [dash_max,Player_Global_Data.p_name,Player_Global_Data.p_role,Player_Global_Data.p_mood,Player_Global_Data.player_level,Player_Global_Data.player_exp,Player_Global_Data.p_curr_ringgit,Player_Global_Data.p_curr_health,Player_Global_Data.p_max_health,Player_Global_Data.p_curr_mana,Player_Global_Data.p_max_mana,Player_Global_Data.current_dash_charges,Player_Global_Data.MAX_DASH_CHARGES,Player_Global_Data.combat_mode,Player_Global_Data.is_casting,Player_Global_Data.completed_quests.size(),Player_Global_Data.completed_subjects.size(),Player_Global_Data.current_field,Player_Global_Data.current_major,Player_Global_Data.current_minor,Player_Global_Data.learned_spells,Player_Global_Data.equipped_spells]
	var stamp := hash(state)
	if _stamp == stamp: return
	_stamp = stamp
	profile_name.text = Player_Global_Data.p_name if not Player_Global_Data.p_name.is_empty() else "Your profile"
	profile_name.tooltip_text = profile_name.text
	role_label.text = Player_Global_Data.p_role if not Player_Global_Data.p_role.is_empty() else "No role selected"
	mood_label.text = "Mood  ·  "+(Player_Global_Data.p_mood if not Player_Global_Data.p_mood.is_empty() else "—")
	role_label.tooltip_text = role_label.text; mood_label.tooltip_text = mood_label.text
	level_label.text = "LEVEL %d" % Player_Global_Data.player_level; currency_label.text = "RM %.2f" % Player_Global_Data.p_curr_ringgit
	status_label.text = "Casting" if Player_Global_Data.is_casting else ("In combat" if Player_Global_Data.combat_mode else "Exploring")
	health_label.text = "%d / %d" % [Player_Global_Data.p_curr_health,Player_Global_Data.p_max_health]; health_bar.max_value = maxf(1,Player_Global_Data.p_max_health); health_bar.value = Player_Global_Data.p_curr_health
	mana_label.text = "%.0f / %.0f" % [Player_Global_Data.p_curr_mana,Player_Global_Data.p_max_mana]; mana_bar.max_value = maxf(1,Player_Global_Data.p_max_mana); mana_bar.value = Player_Global_Data.p_curr_mana
	dash_label.text = "Dash charges  ·  %d / %d" % [Player_Global_Data.current_dash_charges,dash_max]
	xp_label.text = "%.0f XP" % Player_Global_Data.player_exp; quest_label.text = str(Player_Global_Data.completed_quests.size()); subjects_label.text = str(Player_Global_Data.completed_subjects.size())
	var academic := [Player_Global_Data.current_field,Player_Global_Data.current_major,Player_Global_Data.current_minor]
	for i in 3: academic_labels[i].text = academic[i] if not academic[i].is_empty() else "Not selected"
	for child in repertoire.get_children(): repertoire.remove_child(child); child.queue_free()
	repertoire.add_child(text("Spell repertoire",20))
	if Player_Global_Data.learned_spells.is_empty(): repertoire.add_child(text("No spells learned yet.",14,MUTED))
	for spell in Player_Global_Data.learned_spells:
		if spell == null: continue
		var row := HBoxContainer.new(); repertoire.add_child(row); var name_ := text(spell.spell_name,16); name_.size_flags_horizontal = Control.SIZE_EXPAND_FILL; name_.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; row.add_child(name_)
		if Player_Global_Data.is_spell_equipped(spell): row.add_child(text("Equipped",13,ACCENT))

func _input(event: InputEvent) -> void:
	super._input(event)
	if get_viewport().is_input_handled() or details_scroll == null: return
	var direction := int(event.is_action_pressed("ui_down"))-int(event.is_action_pressed("ui_up"))
	if event.is_action_pressed("ui_page_down"): direction = 4
	elif event.is_action_pressed("ui_page_up"): direction = -4
	if direction != 0:
		details_scroll.scroll_vertical += direction*70
		get_viewport().set_input_as_handled()

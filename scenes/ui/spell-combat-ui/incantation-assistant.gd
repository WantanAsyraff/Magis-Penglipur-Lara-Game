class_name IncantationAssistant extends Control

const ICONS := SpellSlot.DIRECTION_TEXTURES
const STATUS := ["Recognized", "Queued", "Preparing", "Channeling", "Executing", "Cast!", "Failed", "Interrupted", "Cancelled"]
var player: Player
var successes: Dictionary = {}
var success_row: HBoxContainer
var counts: Dictionary = {}
var shown_chain: int = 0
var last_sequence: Array[String] = []
var pulse: Tween
var panel: PanelContainer
var sequence_scroll: ScrollContainer
var sequence_row: HBoxContainer
var next_row: HBoxContainer
var predictions: GridContainer
var more_label: Label
var result: Label
var result_icon: TextureRect
var chain_label: Label
var mana_label: Label
var guided: VBoxContainer
var invalid_feedback: bool = false
var dialogue_active: bool = false
var forecast_signature: String = ""
var feedback_audio: AudioStreamPlayer
var input_tone: AudioStreamWAV
var success_tone: AudioStreamWAV
var refresh_timer: Timer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("17202aef")
	style.border_color = Color("b89e63")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	box.add_child(header)
	var title := Label.new()
	title.text = "INCANTATION"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color("d3bd86"))
	header.add_child(title)
	mana_label = Label.new()
	mana_label.add_theme_font_size_override("font_size", 14)
	header.add_child(mana_label)
	chain_label = Label.new()
	header.add_child(chain_label)
	success_row = HBoxContainer.new()
	header.add_child(success_row)
	sequence_row = HBoxContainer.new()
	sequence_scroll = ScrollContainer.new()
	sequence_scroll.custom_minimum_size.y = 32
	sequence_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(sequence_scroll)
	sequence_scroll.add_child(sequence_row)
	var feedback := HBoxContainer.new()
	box.add_child(feedback)
	result_icon = _icon(null, 28)
	feedback.add_child(result_icon)
	result = Label.new()
	result.text = "Enter a direction to begin"
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback.add_child(result)
	guided = VBoxContainer.new()
	box.add_child(guided)
	next_row = HBoxContainer.new()
	guided.add_child(next_row)
	predictions = GridContainer.new()
	predictions.columns = 3
	predictions.add_theme_constant_override("h_separation", 14)
	guided.add_child(predictions)
	more_label = Label.new()
	more_label.add_theme_font_size_override("font_size", 13)
	guided.add_child(more_label)
	refresh_timer = Timer.new()
	refresh_timer.wait_time = 0.2
	add_child(refresh_timer)
	refresh_timer.timeout.connect(_refresh_forecast)
	# Children must never consume combat or pause input.
	_ignore_mouse(self)
	feedback_audio = AudioStreamPlayer.new()
	feedback_audio.volume_db = -25
	feedback_audio.max_polyphony = 2
	add_child(feedback_audio)
	input_tone = _tone(440, 0.035)
	success_tone = _tone(660, 0.10)
	hide()

func _tone(frequency: float, duration: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples := int(duration * stream.mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	for i in samples:
		var amplitude := sin(TAU * frequency * i / stream.mix_rate) * (1.0 - float(i) / samples)
		bytes.encode_s16(i * 2, int(amplitude * 8000))
	stream.data = bytes
	return stream

func _play(stream: AudioStream) -> void:
	if visible and stream:
		feedback_audio.stream = stream
		feedback_audio.play()

func _ignore_mouse(node: Node) -> void:
	if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children(): _ignore_mouse(child)

func bind_player(actor: Player) -> void:
	player = actor
	player.incantations.changed.connect(_refresh_sequence)
	player.incantation_rejected.connect(_rejected)
	player.casting.request_status.connect(_request_status)
	Player_Global_Data.casting_changed.connect(_visibility_changed)
	Player_Global_Data.assistance_changed.connect(_mode_changed)
	Player_Global_Data.mana_changed.connect(_mana_changed)
	player.hitbox.died.connect(_died)
	Dialogic.timeline_started.connect(_dialogue_started)
	Dialogic.timeline_ended.connect(_dialogue_ended)
	_refresh_sequence()
	_visibility_changed(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED: hide()
	if what == NOTIFICATION_UNPAUSED and is_instance_valid(player): _visibility_changed(player._in_casting_stance)

func _visibility_changed(_casting: bool) -> void:
	visible = is_instance_valid(player) and player._in_casting_stance and Player_Global_Data.assistance_mode != 2 and not get_tree().paused and not dialogue_active and not player.get_meta("combat_dead", false)
	if visible:
		_refresh_sequence()
		refresh_timer.start()
	else:
		refresh_timer.stop()

func _dialogue_started() -> void:
	dialogue_active = true
	_visibility_changed(false)

func _dialogue_ended() -> void:
	dialogue_active = false
	_visibility_changed(false)

func _mode_changed(_mode: int) -> void:
	_visibility_changed(false)

func _mana_changed(_mana: float) -> void:
	if visible: _refresh_forecast()

func _died() -> void:
	counts.clear()
	successes.clear()
	hide()
	refresh_timer.stop()

func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _icon(texture: Texture2D, pixels: int = 26) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(pixels, pixels)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

func _directions(row: Node, keys: Array[String]) -> void:
	for key in keys: row.add_child(_icon(ICONS.get(key)))

func _refresh_sequence() -> void:
	if not is_instance_valid(player): return
	var sequence := player.incantations.get_sequence_snapshot()
	if sequence != last_sequence:
		if invalid_feedback and not sequence.is_empty():
			invalid_feedback = false
			result.text = "Form an incantation"
			result.modulate = Color.WHITE
			result_icon.texture = null
		if sequence.size() > last_sequence.size(): _play(input_tone)
		_clear(sequence_row)
		_directions(sequence_row, sequence)
		if sequence.is_empty():
			var hint := Label.new()
			hint.text = "Ready for a new incantation"
			hint.modulate = Color("a9b1ba")
			sequence_row.add_child(hint)
		if pulse: pulse.kill()
		result_icon.modulate = Color.WHITE
		sequence_row.modulate = Color(1.35, 1.25, 1.0)
		pulse = create_tween()
		pulse.tween_property(sequence_row, "modulate", Color.WHITE, 0.18)
		last_sequence = sequence
		sequence_scroll.set_deferred("scroll_horizontal", 100000)
	_refresh_forecast()

func _refresh_forecast() -> void:
	if not is_instance_valid(player): return
	var signature := str(player.incantations.get_sequence_snapshot()) + str(Player_Global_Data.assistance_mode) + str(int(Player_Global_Data.p_curr_mana))
	for candidate in player.incantations.get_reachable_chain_spells():
		signature += candidate.spell_id + player.casting.preview_restriction(candidate, Player_Global_Data.p_curr_mana)
	if signature == forecast_signature: return
	forecast_signature = signature
	guided.visible = Player_Global_Data.assistance_mode == 0
	mana_label.visible = guided.visible
	offset_top = -490 if guided.visible else -273
	_clear(next_row)
	_clear(predictions)
	if not guided.visible:
		_fit_content.call_deferred()
		return
	var label := Label.new()
	label.text = "START" if player.incantations.sequence.is_empty() else "CONTINUE"
	next_row.add_child(label)
	_directions(next_row, player.incantations.get_continuation_keys())
	var restarts := player.incantations.get_restart_keys()
	if not restarts.is_empty():
		var restart_label := Label.new()
		restart_label.text = "  NEW CHAIN"
		restart_label.modulate = Color("a9b1ba")
		next_row.add_child(restart_label)
		_directions(next_row, restarts)
	mana_label.text = "%.0f / %.0f MP • forecast" % [Player_Global_Data.p_curr_mana, Player_Global_Data.p_max_mana]
	var candidates := player.incantations.get_reachable_chain_spells()
	for i in mini(3, candidates.size()):
		var spell := candidates[i]
		var card := VBoxContainer.new()
		card.custom_minimum_size.x = 220
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		predictions.add_child(card)
		var heading := HBoxContainer.new()
		card.add_child(heading)
		heading.add_child(_icon(spell.spell_icon, 24))
		var name_label := Label.new()
		name_label.text = spell.spell_name + " • " + cost_text(spell)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.add_theme_font_size_override("font_size", 14)
		heading.add_child(name_label)
		var remaining_scroll := ScrollContainer.new()
		remaining_scroll.custom_minimum_size.y = 32
		remaining_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		card.add_child(remaining_scroll)
		var remaining := HBoxContainer.new()
		remaining_scroll.add_child(remaining)
		_directions(remaining, spell.spell_incantation.slice(player.incantations.sequence.size()))
		var readiness := Label.new()
		readiness.text = player.casting.preview_restriction(spell, Player_Global_Data.p_curr_mana)
		readiness.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		readiness.add_theme_font_size_override("font_size", 13)
		card.add_child(readiness)
		if i > 0: card.modulate = Color(0.75, 0.78, 0.82)
	more_label.visible = candidates.size() > 3
	more_label.text = "%d more possibilities • full list in repertoire" % maxi(0, candidates.size() - 3)
	_ignore_mouse(guided)
	_fit_content.call_deferred()

func _fit_content() -> void:
	if is_instance_valid(panel):
		offset_top = offset_bottom - maxf(128, panel.get_combined_minimum_size().y)

static func cost_text(spell: SpellData) -> String:
	return "%s MP" % str(spell.upfront_cost) + (" + %s MP/s (duration estimate)" % str(spell.mana_per_second) if spell.is_channelled else "")

func _request_status(_id: int, chain: int, spell: SpellData, status: SpellCastingComponent.RequestStatus, reason: String) -> void:
	if spell == null: return
	invalid_feedback = false
	shown_chain = chain
	if status == SpellCastingComponent.RequestStatus.COMPLETED:
		_play(spell.cast_sound if spell.cast_sound else success_tone)
		counts[chain] = counts.get(chain, 0) + 1
		if not successes.has(chain): successes[chain] = []
		successes[chain].append(spell)
		if successes[chain].size() > 5: successes[chain].pop_front()
		# Only completed historical chains are retired; the queue holds at most eight.
		for old in counts.keys():
			if old < chain - 64:
				counts.erase(old)
				successes.erase(old)
	_clear(success_row)
	if successes.has(chain):
		var executed := Label.new()
		executed.text = "✓"
		success_row.add_child(executed)
		for completed in successes[chain].slice(-5):
			var badge := _icon(completed.spell_icon, 22)
			badge.tooltip_text = completed.spell_name
			success_row.add_child(badge)
	result_icon.texture = spell.spell_icon
	result.text = spell.spell_name + " — " + STATUS[status] + (": " + reason if not reason.is_empty() else "") + " • " + cost_text(spell)
	result.modulate = Color("edac9b") if status >= SpellCastingComponent.RequestStatus.FAILED else Color("d8e9c8")
	_fit_content.call_deferred()
	chain_label.text = "Chain ×%d" % counts.get(chain, 0)
	if status == SpellCastingComponent.RequestStatus.COMPLETED:
		if pulse: pulse.kill()
		sequence_row.modulate = Color.WHITE
		result_icon.modulate = Color(1.8, 1.6, 1.1)
		pulse = create_tween()
		pulse.tween_property(result_icon, "modulate", Color.WHITE, 0.22)

func _rejected() -> void:
	invalid_feedback = true
	result.text = "Invalid direction • incantation cleared"
	result.modulate = Color("edac9b")

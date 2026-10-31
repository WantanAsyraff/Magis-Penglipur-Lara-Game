extends Node
signal sequence_finished(sequence: CutsceneSequence, outcome: int)
enum Outcome { NATURAL, SKIPPED, INTERRUPTED }
const HOLD_SECONDS := .8
var sequence: CutsceneSequence
var story_owner: Node
var elapsed := 0.0
var _holding := false
var _mouse_holding := false
var _terminal := false
var _finishing := false
var _outcome := Outcome.INTERRUPTED
var _before := {}
var _hud_before: Array[Dictionary] = []
var _owned_timeline: DialogicTimeline
var _blocks_skip := false
var last_recap := ""
var layer: CanvasLayer
var skip_button: Button
var progress: ProgressBar
var recap_button: Button
var _recap_time := 0.0
var recap_dialog: AcceptDialog
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Dialogic.timeline_ended.connect(_timeline_ended)
	Dialogic.signal_event.connect(_signal)
	Dialogic.timeline_started.connect(_timeline_started)
	Player_Manager.local_player_changed.connect(_player_changed)
	_build_ui()
func _player_changed(_player: Node2D) -> void:
	if sequence != null: _hide_gameplay_hud()
func _build_ui() -> void:
	layer = CanvasLayer.new(); layer.layer = 110; add_child(layer)
	var panel := VBoxContainer.new(); panel.mouse_filter = Control.MOUSE_FILTER_IGNORE; panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT); panel.offset_left = -350; panel.offset_right = -36; panel.offset_top = -96; panel.offset_bottom = -24; layer.add_child(panel)
	skip_button = Button.new(); skip_button.text = "F1 / R3 · Hold to skip  ››"; skip_button.theme = load("res://assets/styles/inventory-theme.tres"); panel.add_child(skip_button)
	skip_button.button_down.connect(func(): _mouse_holding = true)
	skip_button.button_up.connect(func(): _mouse_holding = false; elapsed = 0)
	progress = ProgressBar.new(); progress.max_value = HOLD_SECONDS; progress.show_percentage = false; progress.custom_minimum_size.y = 4; panel.add_child(progress)
	recap_button = Button.new(); recap_button.text = "Scene skipped · View recap"; recap_button.theme = skip_button.theme; panel.add_child(recap_button); recap_button.hide()
	recap_button.pressed.connect(_show_recap)
	skip_button.hide(); progress.hide()
func flag_for(data: CutsceneSequence) -> String:
	return "story_sequence:"+data.sequence_id
func play(owner_: Node, data: CutsceneSequence) -> bool:
	if SaveManager.loading or QuestOfferDialog.is_open() or sequence != null or Dialogic.current_timeline != null or get_tree().paused or not is_instance_valid(owner_) or not owner_.is_inside_tree() or data == null or not data.validate().is_empty(): return false
	if data.grant_spell and Spell_Library.get_spell_by_id(data.grant_spell.spell_id) != data.grant_spell: return false
	if QuestManager.world_flags.get(flag_for(data),false):
		_apply_context(data,false); return false
	dismiss_recap()
	recap_button.hide()
	sequence = data; story_owner = owner_; _terminal = false; _finishing = false; _holding = false; _mouse_holding = false; elapsed = 0; _outcome = Outcome.INTERRUPTED
	_before = {"movement":Player_Global_Data.p_moveable,"phone":Player_Global_Data.phone_visible,"combat":Player_Global_Data.combat_mode}
	_hud_before.clear()
	_hide_gameplay_hud()
	Player_Global_Data.p_moveable = false; Player_Global_Data.phone_visible = false
	var timeline := load(data.timeline_path) as DialogicTimeline
	timeline.process(); _blocks_skip = false
	for event in timeline.events:
		if event is DialogicChoiceEvent or event is DialogicJumpEvent: _blocks_skip = true
	_owned_timeline = timeline
	owner_.tree_exiting.connect(_owner_exiting,CONNECT_ONE_SHOT)
	Dialogic.Styles.load_style(data.style_path)
	Dialogic.start(timeline)
	return true
func eligible() -> bool:
	return sequence != null and sequence.skippable and not _finishing and not _blocks_skip and not SaveManager.loading and not get_tree().paused and not QuestOfferDialog.is_open() and Dialogic.current_timeline == _owned_timeline and Dialogic.current_state != Dialogic.States.AWAITING_CHOICE
func _signal(value: Variant) -> void:
	if sequence != null and Dialogic.current_timeline == _owned_timeline and str(value) == sequence.completion_signal: _terminal = true
func _timeline_started() -> void:
	if sequence != null and Dialogic.current_timeline != _owned_timeline: interrupt()
func _timeline_ended() -> void:
	if sequence == null: return
	var outcome := Outcome.INTERRUPTED if SaveManager.loading or not is_instance_valid(story_owner) or not story_owner.is_inside_tree() else (_outcome if _finishing else (Outcome.NATURAL if _terminal else Outcome.INTERRUPTED))
	_resolve(outcome)
func _apply_context(data: CutsceneSequence, grant: bool = true) -> void:
	Player_Global_Data.p_moveable = true; Player_Global_Data.combat_mode = data.combat_after; Player_Global_Data.phone_visible = data.phone_after
	if grant and data.grant_spell:
		Player_Global_Data.add_spell(data.grant_spell); Player_Global_Data.equip_spell(data.grant_spell)
func _resolve(outcome: Outcome) -> void:
	if sequence == null: return
	var done := sequence
	if is_instance_valid(story_owner) and story_owner.tree_exiting.is_connected(_owner_exiting): story_owner.tree_exiting.disconnect(_owner_exiting)
	sequence = null; story_owner = null; _owned_timeline = null; _holding = false; _mouse_holding = false; elapsed = 0
	skip_button.hide(); progress.hide()
	_restore_gameplay_hud()
	if outcome != Outcome.INTERRUPTED:
		_apply_context(done)
		QuestManager.set_world_flag(flag_for(done),true)
		SaveManager.request_autosave()
		if outcome == Outcome.SKIPPED and not done.recap.is_empty(): last_recap = done.recap; recap_button.show(); _recap_time = 12
	elif not SaveManager.loading:
		Player_Global_Data.p_moveable = _before.get("movement",true); Player_Global_Data.phone_visible = _before.get("phone",false); Player_Global_Data.combat_mode = _before.get("combat",false)
	sequence_finished.emit(done,outcome)
func request_skip() -> bool:
	if not eligible(): return false
	_finishing = true; _outcome = Outcome.SKIPPED; _holding = false; _mouse_holding = false
	Dialogic.end_timeline(true); return true
func interrupt() -> void:
	if sequence == null: return
	var ours := Dialogic.current_timeline == _owned_timeline
	_resolve(Outcome.INTERRUPTED)
	if ours: Dialogic.end_timeline(true)
func _owner_exiting() -> void:
	interrupt()
func _process(delta: float) -> void:
	if SceneManager.is_transitioning or (is_instance_valid(ModalService.holder) and ModalService.holder != recap_dialog): dismiss_recap()
	var available := eligible()
	if available:
		for binding in InputMap.action_get_events("cutscene_skip"):
			if binding is InputEventKey:
				skip_button.text = OS.get_keycode_string(binding.physical_keycode if binding.physical_keycode else binding.keycode)+" / R3 · Hold to skip  ››"; break
	skip_button.visible = available; progress.visible = available
	if available and (_holding or _mouse_holding):
		elapsed = minf(HOLD_SECONDS,elapsed+delta)
		if elapsed >= HOLD_SECONDS: request_skip()
	else: elapsed = 0
	progress.value = elapsed
	if _recap_time > 0:
		_recap_time -= delta
		if _recap_time <= 0: recap_button.hide()
func _input(event: InputEvent) -> void:
	if sequence == null: return
	if event.is_action("cutscene_skip") and not event.is_echo():
		_holding = event.is_pressed() and eligible()
		if not _holding: elapsed = 0
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.is_action("ui_accept") and skip_button.has_focus() and eligible():
		_holding = event.is_pressed()
		if not _holding: elapsed = 0
		get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: _holding = false; _mouse_holding = false; elapsed = 0
func _show_recap() -> void:
	if sequence != null or last_recap.is_empty(): return
	var dialog := AcceptDialog.new(); recap_dialog = dialog; dialog.title = "Story recap"; dialog.dialog_text = last_recap; dialog.process_mode = Node.PROCESS_MODE_ALWAYS; layer.add_child(dialog)
	if not ModalService.acquire(dialog): dialog.queue_free(); return
	dialog.confirmed.connect(func(): ModalService.release(dialog); dialog.queue_free())
	dialog.canceled.connect(func(): ModalService.release(dialog); dialog.queue_free())
	dialog.window_input.connect(func(event: InputEvent):
		if event.is_action_pressed("ui_cancel"):
			dialog.set_input_as_handled(); ModalService.release(dialog); dialog.queue_free())
	dialog.popup_centered(Vector2i(520,180))

func dismiss_recap() -> void:
	if is_instance_valid(recap_dialog): ModalService.release(recap_dialog); recap_dialog.queue_free(); recap_dialog = null
	recap_button.hide()

func _hide_gameplay_hud() -> void:
	for camera in get_tree().get_nodes_in_group("camera"):
		if camera is PlayerCamera:
			for control in [camera.combatUI,camera.overworldUI,camera.get_node_or_null("UI/StatusEffectsHUD")]:
				if control is Control and not _hud_before.any(func(entry): return entry.node.get_ref() == control):
					_hud_before.append({"node":weakref(control),"visible":control.visible}); control.hide()
func _restore_gameplay_hud() -> void:
	for entry in _hud_before:
		var control: Control = entry.node.get_ref()
		if is_instance_valid(control): control.visible = entry.visible
	_hud_before.clear()

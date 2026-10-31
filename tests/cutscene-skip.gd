extends Node2D
var checks := 0
var failures := 0
var outcomes: Array[int] = []
var story: Node
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+message)
func settle() -> void:
	for i in 5: await get_tree().process_frame
func input_event(code: int, pressed: bool, joy: bool = false) -> void:
	var event: InputEvent
	if joy:
		event = InputEventJoypadButton.new(); event.button_index = code; event.pressed = pressed
	else:
		event = InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = pressed
	get_viewport().push_input(event,true)
func fresh(definition: String) -> CutsceneSequence:
	var data: CutsceneSequence = load("res://data/story/"+definition+".tres")
	QuestManager.world_flags.erase(CutsceneFlow.flag_for(data))
	return data
func _ready() -> void:
	await get_tree().process_frame
	QuestManager.persistence_enabled = false; Player_Global_Data.p_moveable = true
	Player_Global_Data.learned_spells.clear(); Player_Global_Data.equipped_spells.clear()
	story = Node.new(); add_child(story)
	CutsceneFlow.sequence_finished.connect(func(_data,outcome): outcomes.append(outcome))
	check(not CutsceneFlow.skip_button.visible,"Skip UI is hidden during ordinary gameplay")
	var school := fresh("school-entrance")
	check(CutsceneFlow.play(story,school),"Explicitly authored school sequence starts")
	await settle()
	check(CutsceneFlow.eligible() and CutsceneFlow.skip_button.visible and not Player_Global_Data.p_moveable,"Eligible cutscene shows skip control and reserves player movement")
	input_event(KEY_F1,true); await get_tree().create_timer(.2).timeout; input_event(KEY_F1,false); await settle()
	check(CutsceneFlow.sequence != null and is_zero_approx(CutsceneFlow.elapsed),"Releasing before the hold duration cancels the skip")
	input_event(KEY_F1,true); await get_tree().create_timer(1.0).timeout; input_event(KEY_F1,false); await settle()
	check(outcomes == [CutsceneFlow.Outcome.SKIPPED],"Real keyboard hold produces exactly one skipped completion")
	var chill: SpellData = load("res://data/magis/spells/thermal-kinetic.tres")
	check(Player_Global_Data.learned_spells == [chill] and Player_Global_Data.equipped_spells == [chill],"Skipped school intro grants and equips only Kinetic Chill once")
	check(Player_Global_Data.p_moveable and Player_Global_Data.combat_mode,"School skip restores control and leaves practical examination gameplay available")
	check(Dialogic.current_timeline == null and not CutsceneFlow.skip_button.visible,"Successful skip removes dialogue and skip UI")
	check(QuestManager.world_flags.get(CutsceneFlow.flag_for(school),false),"Sequence completion uses the existing persistent world flag")
	check(not CutsceneFlow.request_skip() and outcomes.size() == 1,"Repeated skip requests cannot duplicate completion")
	Player_Global_Data.equipped_spells.clear()
	check(not CutsceneFlow.play(story,school) and Player_Global_Data.equipped_spells.is_empty(),"Completed introduction does not replay or overwrite later equipment choices")
	CutsceneFlow._show_recap(); await settle()
	check(CutsceneFlow.recap_dialog.visible and get_tree().paused,"Optional authored recap owns a responsive modal pause")
	var cancel := InputEventJoypadButton.new(); cancel.button_index = JOY_BUTTON_B; cancel.pressed = true
	CutsceneFlow.recap_dialog.window_input.emit(cancel); await settle()
	check(not get_tree().paused and not is_instance_valid(ModalService.holder),"Controller cancel releases recap pause ownership")
	var other_modal := Control.new(); add_child(other_modal)
	ModalService.acquire(other_modal); await settle()
	check(not CutsceneFlow.recap_button.visible,"Story recap does not cover another exclusive app")
	ModalService.release(other_modal); other_modal.queue_free(); await settle()
	var invalid := school.duplicate() as CutsceneSequence; invalid.style_path = "res://data/items/equipment/student-lab-robe.tres"
	check(not CutsceneFlow.play(story,invalid),"A non-style Resource is rejected before cutscene state changes")
	var kampung := fresh("kampung-intro")
	CutsceneFlow.play(story,kampung); await settle()
	input_event(JOY_BUTTON_RIGHT_STICK,true,true); await get_tree().create_timer(.9).timeout; input_event(JOY_BUTTON_RIGHT_STICK,false,true); await settle()
	check(outcomes.back() == CutsceneFlow.Outcome.SKIPPED and not Player_Global_Data.combat_mode,"Controller skip action completes kampung in non-combat state")
	check(CutsceneFlow.last_recap == kampung.recap and CutsceneFlow.recap_button.visible,"Successful skip offers the authored optional recap")
	kampung = fresh("kampung-intro"); CutsceneFlow.play(story,kampung); await settle()
	CutsceneFlow.skip_button.button_down.emit(); await get_tree().create_timer(.9).timeout; CutsceneFlow.skip_button.button_up.emit(); await settle()
	check(outcomes.back() == CutsceneFlow.Outcome.SKIPPED,"Mouse/button hold follows the same guarded completion path")
	var natural := CutsceneSequence.new(); natural.sequence_id = "test.natural"; natural.timeline_path = "res://tests/fixtures/inventory-v2/natural.dtl"; natural.completion_signal = "story:completed:test.natural"; natural.skippable = true
	CutsceneFlow.play(story,natural); await settle()
	for i in 25:
		if Dialogic.current_timeline == null: break
		var advance := InputEventAction.new(); advance.action = "dialogic_default_action"; advance.pressed = true; get_viewport().push_input(advance,true)
		await get_tree().create_timer(.12).timeout
	await settle()
	check(outcomes.back() == CutsceneFlow.Outcome.NATURAL and QuestManager.world_flags.get(CutsceneFlow.flag_for(natural),false),"Natural dialogue advance reaches its authored completion marker")
	kampung = fresh("kampung-intro"); CutsceneFlow.play(story,kampung); await settle()
	Dialogic.end_timeline(true); await settle()
	check(outcomes.back() == CutsceneFlow.Outcome.INTERRUPTED and not QuestManager.world_flags.get(CutsceneFlow.flag_for(kampung),false),"External timeline interruption awards no story completion")
	check(Player_Global_Data.p_moveable,"Interruption restores prior movement state")
	CutsceneFlow.play(story,kampung); await settle(); SaveManager.loading = true
	Dialogic.end_timeline(true); await settle(); SaveManager.loading = false; Player_Global_Data.p_moveable = true
	check(outcomes.back() == CutsceneFlow.Outcome.INTERRUPTED and not QuestManager.world_flags.get(CutsceneFlow.flag_for(kampung),false),"Load cancellation cannot award sequence progress")
	CutsceneFlow.play(story,kampung); await settle()
	var state := Dialogic.current_state; Dialogic.current_state = Dialogic.States.AWAITING_CHOICE
	check(not CutsceneFlow.eligible() and not CutsceneFlow.request_skip(),"Required choice states cannot be skipped")
	Dialogic.current_state = state; CutsceneFlow.interrupt(); await settle()
	var choice := CutsceneSequence.new(); choice.sequence_id = "test.choice"; choice.timeline_path = "res://tests/fixtures/inventory-v2/choice.dtl"; choice.completion_signal = "story:completed:test.choice"; choice.skippable = true
	CutsceneFlow.play(story,choice); await settle()
	check(CutsceneFlow._blocks_skip and not CutsceneFlow.eligible(),"A timeline containing future mandatory choices is never skippable")
	CutsceneFlow.interrupt(); await settle()
	var external := CutsceneSequence.new(); external.sequence_id = "test.external-choice"; external.timeline_path = "res://tests/fixtures/inventory-v2/external-choice.dtl"; external.completion_signal = "story:completed:test.external-choice"; external.skippable = true
	CutsceneFlow.play(story,external); await settle()
	check(CutsceneFlow._blocks_skip and not CutsceneFlow.request_skip(),"External timeline jumps cannot hide mandatory choices from skip preflight")
	CutsceneFlow.interrupt(); await settle()
	var temporary_owner := Node.new(); add_child(temporary_owner)
	CutsceneFlow.play(temporary_owner,kampung); await settle(); temporary_owner.queue_free(); await settle()
	check(CutsceneFlow.sequence == null and outcomes.back() == CutsceneFlow.Outcome.INTERRUPTED and not QuestManager.world_flags.get(CutsceneFlow.flag_for(kampung),false),"Exiting the owning scene cancels without story progress")
	var opted_out := kampung.duplicate() as CutsceneSequence; opted_out.skippable = false
	CutsceneFlow.play(story,opted_out); await settle()
	check(not CutsceneFlow.skip_button.visible and not CutsceneFlow.request_skip(),"Non-opted-in narrative operations never expose skip")
	CutsceneFlow.interrupt(); await settle()
	Dialogic.start("res://tests/fixtures/inventory-v2/natural.dtl"); await settle()
	check(CutsceneFlow.sequence == null and not CutsceneFlow.skip_button.visible,"Ordinary direct/NPC dialogue remains unchanged")
	Dialogic.end_timeline(true); await settle()
	check(not get_tree().paused and not is_instance_valid(ModalService.holder),"No pause or modal state remains stuck")
	print("CUTSCENE_SKIP: %d checks, %d failures" % [checks,failures]); get_tree().quit(1 if failures else 0)

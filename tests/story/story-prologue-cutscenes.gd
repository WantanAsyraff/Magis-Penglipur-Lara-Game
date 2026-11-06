extends Node

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PROLOGUE_CUTSCENES: " + label)

func frames() -> void:
	for i in 5: await get_tree().process_frame

func _ready() -> void:
	await frames()
	SaveManager.session_ready = true
	StoryDirector._on_restored()
	var intro: CutsceneSequence = load("res://data/story/kampung-intro.tres")
	var school: CutsceneSequence = load("res://data/story/school-entrance.tres")
	QuestManager.world_flags.erase(CutsceneFlow.flag_for(intro))
	QuestManager.world_flags.erase(CutsceneFlow.flag_for(school))
	check(CutsceneFlow.play(self, intro), "real kampung sequence starts")
	await frames()
	for i in 130:
		if CutsceneFlow.sequence == null: break
		var advance := InputEventAction.new()
		advance.action = "dialogic_default_action"
		advance.pressed = true
		get_viewport().push_input(advance, true)
		await get_tree().create_timer(.10).timeout
	await frames()
	check(CutsceneFlow.sequence == null and QuestManager.world_flags.get(CutsceneFlow.flag_for(intro), false), "natural kampung completion records canonical flag")
	check(StoryDirector.get_current_stage_id() == &"prologue.leave_house", "natural completion advances story")
	QuestManager.world_flags.erase(CutsceneFlow.flag_for(intro))
	StoryDirector.state.clear()
	StoryDirector._on_restored()
	check(CutsceneFlow.play(self, intro), "kampung replay fixture starts")
	await frames()
	CutsceneFlow.interrupt()
	await frames()
	check(StoryDirector.get_current_stage_id() == &"prologue.wake_up" and not QuestManager.world_flags.get(CutsceneFlow.flag_for(intro), false), "interruption cannot advance")
	check(CutsceneFlow.play(self, intro), "kampung skip fixture starts")
	await frames()
	check(CutsceneFlow.request_skip(), "successful intro skip accepted")
	await frames()
	check(StoryDirector.get_current_stage_id() == &"prologue.leave_house", "skip advances story once")
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.LOCATION_REACHED, "prologue.school_entrance", 1, QuestManager.active_owner_id))
	await frames()
	check(StoryDirector.get_current_stage_id() == &"prologue.reach_school", "arrival event reaches school stage")
	check(CutsceneFlow.play(self, school), "real school sequence starts")
	await frames()
	check(CutsceneFlow.request_skip(), "successful school skip accepted")
	await frames()
	check(StoryDirector.get_current_stage_id() == &"prologue.spm_practical", "school skip advances to practical")
	var chill: SpellData = load("res://data/magis/spells/thermal-kinetic.tres")
	check(Player_Global_Data.learned_spells.has(chill), "CutsceneFlow grants canonical Kinetic Chill")
	var before := Player_Global_Data.learned_spells.size()
	check(not CutsceneFlow.play(self, school) and Player_Global_Data.learned_spells.size() == before, "completed school sequence cannot grant twice")
	print("PROLOGUE_CUTSCENES: %d checks, %d failures" % [checks, failures])
	get_tree().quit(failures)

extends Node
func _ready() -> void:
	for size in [10, 100, 500]:
		var database := StoryDatabase.new()
		var arc := StoryArcData.new(); arc.arc_id = &"benchmark.arc"; arc.initial_chapter_id = &"benchmark.chapter"
		var chapter := StoryChapterData.new(); chapter.chapter_id = &"benchmark.chapter"; chapter.initial_stage_id = &"benchmark.0"
		var stages: Array[StoryStageData] = []
		for index in size:
			var stage := StoryStageData.new(); stage.stage_id = StringName("benchmark.%d" % index); stage.display_name = "Stage %d" % index
			for step in [1, 2]:
				if index + step >= size: continue
				var transition := StoryTransitionData.new(); transition.transition_id = StringName("benchmark.%d.%d" % [index, step]); transition.target_stage_id = StringName("benchmark.%d" % [index + step]); transition.automatic = false
				stage.transitions.append(transition)
			stages.append(stage)
		chapter.stages = stages; arc.chapters = [chapter]; database.arcs = [arc]
		var started := Time.get_ticks_usec()
		var analysis := StoryGraphAnalyzer.analyze(database)
		var elapsed := Time.get_ticks_usec() - started
		if analysis.nodes.size() != size or analysis.issues.any(func(issue: Dictionary): return issue.severity == "ERROR"):
			push_error("STORY_DEBUG_BENCH: invalid graph %d" % size); get_tree().quit(1); return
		print("STORY_DEBUG_BENCH: %d stages, %d edges, %d us" % [size, analysis.edges.size(), elapsed])
	get_tree().quit(0)

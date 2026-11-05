class_name StoryActionContext extends RefCounted
var director: Node
var registry: StoryRegistry
var source: StoryStageData
var destination: StoryStageData
var transition: StoryTransitionData
var event: GameplayEvent
var receipt: String
func _init(d: Node, s: StoryStageData, target: StoryStageData, t: StoryTransitionData, e: GameplayEvent) -> void:
 director = d
 registry = d.registry
 source = s
 destination = target
 transition = t
 event = e
 receipt = String(d.state.arc_id) + ":" + String(d.state.chapter_id) + ":" + String(t.transition_id)

# TutorialComponent.gd
# Attach as a child of any NPC scene.
# Spawns a tutorial panel CanvasLayer and awaits its close signal.
# Emits tutorial_started / tutorial_ended so the NPC can sequence correctly.
class_name TutorialComponent
extends Node

# -------------------------
# SIGNALS
# -------------------------
signal tutorial_started
signal tutorial_ended

# -------------------------
# EXPORTS
# -------------------------
@export var has_tutorial: bool = false
@export var tutorial_panel_scene: PackedScene
@export var tutorial_data: TutorialData

# -------------------------
# API
# -------------------------

## Shows the tutorial panel if configured. Returns false if nothing to show.
func try_show() -> bool:
	if not has_tutorial:
		return false
	if not tutorial_panel_scene or not tutorial_data:
		push_warning("TutorialComponent: has_tutorial is true but panel scene or data is missing.")
		return false

	tutorial_started.emit()
	Player_Global_Data.p_moveable = false

	var layer := CanvasLayer.new()
	var panel: PanelTutorial = tutorial_panel_scene.instantiate()
	panel.data = tutorial_data
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(panel)
	get_tree().current_scene.add_child(layer)

	await panel.closed

	layer.queue_free()
	Player_Global_Data.p_moveable = true
	tutorial_ended.emit()
	return true

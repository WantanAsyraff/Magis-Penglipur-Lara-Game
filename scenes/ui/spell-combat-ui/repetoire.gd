class_name RepetoirePanel
extends PanelContainer

const SPELL_SLOT = preload("res://scenes/ui/spell-combat-ui/spell-slot.tscn")

@onready var grid: GridContainer = %RepetoireGrid

var tween: Tween

func _ready() -> void:
	hide()
	Player_Global_Data.spells_updated.connect(_populate_grid)
	Player_Global_Data.casting_changed.connect(_on_casting_changed)
	_populate_grid()

func _on_casting_changed(casting: bool) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	var viewport := get_viewport_rect().size
	var target_x := viewport.x - size.x
	var target_y := viewport.y - size.y

	if casting:
		position = Vector2(target_x / 2, viewport.y)
		show()
		tween.tween_property(self, "position:y", target_y, 0.4)
	else:
		tween.tween_property(self, "position:y", viewport.y, 0.4)
		await tween.finished
		hide()

func _populate_grid() -> void:
	for child in grid.get_children():
		child.queue_free()
	await get_tree().process_frame
	for spell in Player_Global_Data.equipped_spells:
		var slot = SPELL_SLOT.instantiate()
		grid.add_child(slot)
		slot.set_spell(spell)

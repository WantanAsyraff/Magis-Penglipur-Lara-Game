class_name RepetoirePanel
extends Control

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

	var viewport := get_viewport_rect().size
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	size = Vector2(350, 420)
	position = Vector2(viewport.x - size.x - 24, viewport.y - size.y - 76)
	visible = casting
	modulate.a = 0.0 if casting else 1.0
	if casting:
		tween = create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.18)

func _populate_grid() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	for spell in Player_Global_Data.equipped_spells:
		var slot = SPELL_SLOT.instantiate()
		grid.add_child(slot)
		slot.set_spell(spell)

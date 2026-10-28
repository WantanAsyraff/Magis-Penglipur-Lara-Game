extends Node2D
const COURSE = preload("res://data/magis/ilmiah/physics-field/physical-science.tres")
var spells: Array[SpellData] = []
var player: Player
var selector: OptionButton
var readout: Label
var targets: Array[PhysicsLabTarget] = []
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(.035, .045, .07))
	floor_at(Vector2(500, 250), Vector2(2600, 30))
	floor_at(Vector2(600, 110), Vector2(30, 250))
	floor_at(Vector2(-250, 80), Vector2(160, 20))
	var glass := floor_at(Vector2(890, 110), Vector2(18, 250))
	glass.set_meta("optical_interface", -45.0)
	for spec in [[Vector2(200, 210), "Stationary", false], [Vector2(400, 210), "Moving", true], [Vector2(700, 210), "Cluster A", false], [Vector2(750, 210), "Cluster B", false], [Vector2(800, 210), "Cluster C", false], [Vector2(-150, 210), "Magnetic structure", false]]:
		var dummy := PhysicsLabTarget.new()
		dummy.title = spec[1]
		dummy.moving = spec[2]
		add_child(dummy)
		dummy.position = spec[0]
		dummy.home = spec[0]
		dummy.set_meta("structural", true)
		dummy.set_meta("magnetic", true)
		targets.append(dummy)
	targets[0].hitbox.effects.apply("resonance", 60, {"amount": 1})
	for subject in COURSE.subjects:
		for spell in subject.contained_spells:
			spells.append(spell)
			Player_Global_Data.add_spell(spell)
			Player_Global_Data.equip_spell(spell)
	Player_Global_Data.combat_mode = true
	player = Player_Manager.spawn_player(self, Vector2(0, 180)) as Player
	player.incantation_strategy = IncantationResolver.Strategy.CONFIRMATION
	player._sync_spells_from_global()
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := VBoxContainer.new()
	panel.position = Vector2(16, 12)
	canvas.add_child(panel)
	selector = OptionButton.new()
	for spell in spells: selector.add_item(spell.spell_name)
	selector.item_selected.connect(func(_i): update_readout())
	panel.add_child(selector)
	for spec in [["Cast selected (F6)", cast_selected], ["Reset targets (F7)", reset_targets], ["Refill mana (F8)", refill]]:
		var button := Button.new()
		button.text = spec[0]
		button.pressed.connect(spec[1])
		panel.add_child(button)
	readout = Label.new()
	readout.add_theme_font_size_override("font_size", 14)
	panel.add_child(readout)
	player.casting.cast_failed.connect(func(reason): update_readout(); readout.text += "\nFailed: " + reason)
	player.casting.cast_completed.connect(func(_c): update_readout())
	update_readout()
func floor_at(at: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 16
	body.add_to_group("world")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([-size/2, Vector2(size.x/2,-size.y/2), size/2, Vector2(-size.x/2,size.y/2)])
	visual.color = Color(.22, .28, .35)
	body.add_child(visual)
	add_child(body)
	body.position = at
	return body
func cast_selected() -> void:
	player._cast_resolved(spells[selector.selected])
func reset_targets() -> void:
	for target in targets: target.reset_target()
func refill() -> void:
	Player_Global_Data.p_curr_mana = Player_Global_Data.p_max_mana
	update_readout()
func update_readout() -> void:
	if readout == null: return
	var spell := spells[selector.selected]
	readout.text = "%s | Mana %d | Sequence: %s\n%s\nO: stance / confirm | I J K L: up left down right | P: clear sequence; bind Cancel Cast in settings\nAim toward a target for direct casts. Platforms expire.\nGray wall blocks beams; right-hand interface turns them -45 degrees." % [spell.spell_name, spell.upfront_cost, ", ".join(spell.spell_incantation), spell.spell_flavour_text]
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F6: cast_selected()
			KEY_F7: reset_targets()
			KEY_F8: refill()

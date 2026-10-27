extends Node2D

@export var test_spell: SpellData = preload("res://data/magis/examples/physics-force-v2.tres")
@onready var target: CharacterBody2D = $Target
@onready var hitbox: HitboxComponent = $Target/HitboxComponent
@onready var readout: Label = $CanvasLayer/Readout
var health: float = 100

func _ready() -> void:
	var errors := SpellValidator.validate(test_spell)
	if not errors.is_empty():
		readout.text = "Invalid test spell: " + str(errors)
		return
	Player_Global_Data.add_spell(test_spell)
	Player_Global_Data.equip_spell(test_spell)
	Player_Global_Data.combat_mode = true
	Player_Manager.spawn_player(self, Vector2(0, -100))
	hitbox.damage_taken.connect(func(amount):
		health -= amount
		_update_readout())
	hitbox.healed.connect(func(amount):
		health = minf(health + amount, 100)
		_update_readout())
	_update_readout()

func _update_readout() -> void:
	readout.text = "Spell lab: %s\nO: casting stance / confirm | I J K L: up left down right\nP: clear and interrupt | Sequence: %s\nTarget HP: %.0f (resets on defeat)" % [test_spell.spell_name, ", ".join(test_spell.spell_incantation), health]
	if health <= 0:
		health = 100
		hitbox.clear_all_effects()

func _physics_process(delta: float) -> void:
	target.velocity.y += 3000 * delta
	target.velocity.x = move_toward(target.velocity.x, 0, 400 * delta)
	target.move_and_slide()

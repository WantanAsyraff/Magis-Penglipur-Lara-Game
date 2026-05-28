#crafting-room.gd
extends Control

@export_group("NPC")
@export var npc_name: String = ""
@export var npc_portrait: Texture2D
@export var npc_dialogue: String = ""

@export_group("Recipes")
@export var available_recipes: Array[ItemData] = []

@onready var crafting_panel = %CraftingRoomPanel
@onready var crafting_ui: CraftingUI = find_child("CraftingUI") as CraftingUI

func _ready() -> void:
	print("[CraftingRoom] _ready called")
	print("[CraftingRoom] crafting_ui found: ", crafting_ui)
	print("[CraftingRoom] recipes count: ", available_recipes.size())
	var ctx := get_node("/root/Crafting_Context")
	ctx.npc_name = npc_name
	ctx.npc_portrait = npc_portrait
	ctx.npc_dialogue = npc_dialogue
	ctx.available_recipes = available_recipes
	crafting_ui.closed.connect(_on_crafting_ui_closed)

func _on_crafting_ui_closed() -> void:
	print("[CraftingRoom] crafting UI closed, showing panel")
	crafting_panel.show()

func _on_crafting_button_pressed() -> void:
	print("[CraftingRoom] crafting button pressed")
	crafting_ui.open()
	crafting_panel.hide()

func _on_leave_button_pressed() -> void:
		var prev := Player_Manager.previous_scene_path
		if prev == "":
			push_error("[CraftingRoom] No previous scene stored in Player_Manager.")
			return
		if SceneManager:
			SceneManager.change_scene(prev)
		else:
			push_error("[CraftingRoom] SceneManager not found!")

class_name CraftingUI
extends Control

signal closed

# -------------------------
# EXPORTS
# -------------------------
@export_group("Visuals")
@export var background_texture: Texture2D
@export var panel_style: StyleBox

# -------------------------
# ONREADY
# -------------------------
@onready var ing_slot_1: IngredientSlot = %IngredientSlot
@onready var ing_slot_2: IngredientSlot = %IngredientSlot2
@onready var ing_slot_3: IngredientSlot = %IngredientSlot3
@onready var recipe_list: VBoxContainer = %RecipesListVBoxContainer
@onready var back_btn: Button = %BackButton
@onready var craft_btn: Button = %CraftingButton

# -------------------------
# STATE
# -------------------------
var npc_name: String = ""
var npc_portrait: Texture2D = null
var npc_dialogue: String = ""
var available_recipes: Array[ItemData] = []
var selected_recipe: ItemData = null

# -------------------------
# HELPERS
# -------------------------
func _get_inv() -> Node:
	var inv := get_node_or_null("/root/Inventory_Manager")
	if inv == null:
		push_error("[CraftingUI] Inventory_Manager not found in Autoload!")
	return inv

# -------------------------
# LIFECYCLE
# -------------------------
func _ready() -> void:
	print("[CraftingUI] _ready called")
	craft_btn.disabled = true
	hide()

# -------------------------
# OPEN / CLOSE
# -------------------------
func open() -> void:
	print("[CraftingUI] open() called")
	# read context here instead, guaranteed CraftingRoom has already written it
	var ctx := get_node("/root/Crafting_Context")
	npc_name = ctx.npc_name
	npc_portrait = ctx.npc_portrait
	npc_dialogue = ctx.npc_dialogue
	available_recipes = ctx.available_recipes
	print("[CraftingUI] open() recipes count: ", available_recipes.size())
	if has_node("%NPCPortrait") and npc_portrait:
		%NPCPortrait.texture = npc_portrait
	if has_node("%NPCDialogue") and npc_dialogue != "":
		%NPCDialogue.text = npc_dialogue
	if has_node("%NPCName") and npc_name != "":
		%NPCName.text = npc_name
	show()
	_populate_list(available_recipes)

func _on_back_button_pressed() -> void:
	print("[CraftingUI] back button pressed")
	hide()
	closed.emit()

# -------------------------
# RECIPE LIST
# -------------------------
func _populate_list(recipes: Array[ItemData]) -> void:
	print("[CraftingUI] _populate_list called with ", recipes.size(), " recipes")
	for child in recipe_list.get_children():
		child.queue_free()
	for recipe in recipes:
		print("[CraftingUI] adding recipe slot for: ", recipe.item_name)
		var slot := preload("res://scenes/crafting-room/recipe-slot.tscn").instantiate()
		slot.setup(recipe)
		slot.selected.connect(_on_recipe_selected)
		recipe_list.add_child(slot)

func _on_recipe_selected(recipe: ItemData) -> void:
	print("[CraftingUI] recipe selected: ", recipe.item_name)
	selected_recipe = recipe
	print("[CraftingUI] ingredient 1: ", recipe.ingredient_1.item_name if recipe.ingredient_1 else "none")
	print("[CraftingUI] ingredient 2: ", recipe.ingredient_2.item_name if recipe.ingredient_2 else "none")
	print("[CraftingUI] ingredient 3: ", recipe.ingredient_3.item_name if recipe.ingredient_3 else "none")
	ing_slot_1.setup(recipe.ingredient_1, recipe.qty_1)
	ing_slot_2.setup(recipe.ingredient_2, recipe.qty_2)
	ing_slot_3.setup(recipe.ingredient_3, recipe.qty_3)
	_refresh_craft_button()

# -------------------------
# CRAFTING
# -------------------------
func _can_craft(recipe: ItemData) -> bool:
	if recipe == null:
		print("[CraftingUI] _can_craft: recipe is null")
		return false
	var inv := _get_inv()
	if inv == null:
		return false
	var ok1: bool = recipe.ingredient_1 == null or inv.has_item(recipe.ingredient_1.item_id, recipe.qty_1)
	var ok2: bool = recipe.ingredient_2 == null or inv.has_item(recipe.ingredient_2.item_id, recipe.qty_2)
	var ok3: bool = recipe.ingredient_3 == null or inv.has_item(recipe.ingredient_3.item_id, recipe.qty_3)
	print("[CraftingUI] _can_craft: ok1=", ok1, " ok2=", ok2, " ok3=", ok3)
	return ok1 and ok2 and ok3

func _refresh_craft_button() -> void:
	var can: bool = _can_craft(selected_recipe)
	print("[CraftingUI] _refresh_craft_button: can_craft=", can)
	craft_btn.disabled = not can

func _on_crafting_button_pressed() -> void:
	print("[CraftingUI] craft button pressed")
	if not _can_craft(selected_recipe):
		print("[CraftingUI] cannot craft, aborting")
		return
	var inv := _get_inv()
	if inv == null:
		return
	if selected_recipe.ingredient_1:
		print("[CraftingUI] removing: ", selected_recipe.ingredient_1.item_name, " x", selected_recipe.qty_1)
		inv.remove_item(selected_recipe.ingredient_1, selected_recipe.qty_1)
	if selected_recipe.ingredient_2:
		print("[CraftingUI] removing: ", selected_recipe.ingredient_2.item_name, " x", selected_recipe.qty_2)
		inv.remove_item(selected_recipe.ingredient_2, selected_recipe.qty_2)
	if selected_recipe.ingredient_3:
		print("[CraftingUI] removing: ", selected_recipe.ingredient_3.item_name, " x", selected_recipe.qty_3)
		inv.remove_item(selected_recipe.ingredient_3, selected_recipe.qty_3)
	print("[CraftingUI] adding crafted item: ", selected_recipe.item_name)
	inv.add_item(selected_recipe, 1)
	_on_recipe_selected(selected_recipe)

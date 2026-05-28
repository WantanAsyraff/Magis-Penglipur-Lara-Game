class_name RecipeSlot
extends Panel

signal selected(recipe: ItemData)

var recipe: ItemData

func setup(data: ItemData) -> void:
	recipe = data
	print("[RecipeSlot] setup called for: ", data.item_name)
	var icon := find_child("TextureRect") as TextureRect
	var label := find_child("ItemLabel") as Label
	print("[RecipeSlot] icon found: ", icon)
	print("[RecipeSlot] label found: ", label)
	if icon:
		icon.texture = data.item_icon
	if label:
		label.text = data.item_name

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("[RecipeSlot] clicked: ", recipe.item_name)
		selected.emit(recipe)

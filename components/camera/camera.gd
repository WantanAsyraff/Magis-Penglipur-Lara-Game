class_name Camera extends Camera2D

@onready var combatUI: Control = %UserInterfaceCombat
@onready var overworldUI: Control = %UserInterfaceOverworld

const SCREEN_SIZE := Vector2(1280, 720)
var cur_screen := Vector2(0, 0)

func _ready():
	set_as_top_level(true)
	global_position = get_parent().global_position
	
	# 1. Connect to the global signal
	Player_Global_Data.combat_mode_changed.connect(_on_combat_mode_changed)
	
	# 2. Set initial UI state
	_on_combat_mode_changed(Player_Global_Data.combat_mode)
	_update_screen(cur_screen)

func _physics_process(_delta):
	# Now only handles the grid-based movement
	var parent_screen : Vector2 = (get_parent().global_position / SCREEN_SIZE).floor()
	if not parent_screen.is_equal_approx(cur_screen):
		_update_screen(parent_screen)

# 3. This runs ONLY when the mode actually changes
func _on_combat_mode_changed(is_combat: bool):
	combatUI.visible = is_combat
	overworldUI.visible = !is_combat

func _update_screen(new_screen : Vector2):
	cur_screen = new_screen
	global_position = cur_screen * SCREEN_SIZE + SCREEN_SIZE * 0.5

extends Node
## Entry point for Xochi.
##
## During development this boots straight into the test level so we can
## iterate on player feel without clicking through menus every time.
## Once the menu is polished, flip the flag below to show it on startup.

## Set to true to show the main menu on startup instead of the test level.
const SHOW_MENU_ON_START: bool = true  # Show menu with world selection on startup
## Set to true to use test level, false to use real Level 1
const USE_TEST_LEVEL: bool = false  # Changed to false for real level


func _ready() -> void:
	if SHOW_MENU_ON_START:
		get_tree().change_scene_to_file.call_deferred("res://scenes/menu/menu_scene.tscn")
	elif USE_TEST_LEVEL:
		# Boot into test level
		get_tree().change_scene_to_file.call_deferred("res://scenes/game/test_level.tscn")
	else:
		# Boot into the real game scene (Level 1 with trajineras!)
		GameState.current_level = 1
		get_tree().change_scene_to_file.call_deferred("res://scenes/game/game_scene.tscn")

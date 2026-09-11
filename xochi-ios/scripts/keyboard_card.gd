extends CenterContainer
## Keep the compact input form in the visible area above an iOS keyboard.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD))

func _process(_delta: float) -> void:
	var screen_height := float(DisplayServer.window_get_size().y)
	var keyboard_height := float(DisplayServer.virtual_keyboard_get_height())
	var viewport_height := get_viewport_rect().size.y
	offset_bottom = -keyboard_height * viewport_height / screen_height if screen_height > 0 else 0.0

extends CanvasLayer
## Handles scene transitions with a smooth black fade-in / fade-out.
## Lives on CanvasLayer 100 so the fade rect always renders on top of everything.

var transition_rect: ColorRect
var is_transitioning: bool = false


func _ready() -> void:
	layer = 100

	transition_rect = ColorRect.new()
	transition_rect.color = Color.BLACK
	transition_rect.anchors_preset = Control.PRESET_FULL_RECT
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_rect.modulate.a = 0.0
	add_child(transition_rect)


func change_scene(scene_path: String, fade_duration: float = 0.5) -> void:
	## Fade to black, swap scenes, fade back in.
	## Calling this while already transitioning is a no-op to prevent double-loads.
	if is_transitioning:
		return
	is_transitioning = true

	# Fade out (current scene disappears behind black)
	var tween_out := create_tween()
	tween_out.tween_property(transition_rect, "modulate:a", 1.0, fade_duration)
	await tween_out.finished

	# Swap to the new scene
	get_tree().change_scene_to_file(scene_path)

	# Fade in (new scene revealed)
	var tween_in := create_tween()
	tween_in.tween_property(transition_rect, "modulate:a", 0.0, fade_duration)
	await tween_in.finished

	is_transitioning = false

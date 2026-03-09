extends CanvasLayer
## Handles scene transitions with a smooth black fade-in / fade-out.
## Lives on CanvasLayer 100 so the fade rect always renders on top of everything.

var transition_rect: ColorRect
var is_transitioning: bool = false
var _pending_scene_path: String = ""
var _pending_scene_data: Dictionary = {}
var _tracked_tweens: Array[Tween] = []


func _ready() -> void:
	layer = 100

	transition_rect = ColorRect.new()
	transition_rect.color = Color.BLACK
	transition_rect.anchors_preset = Control.PRESET_FULL_RECT
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_rect.modulate.a = 0.0
	add_child(transition_rect)


func change_scene(scene_path: String, fade_duration: float = 0.5, scene_data: Dictionary = {}) -> void:
	## Fade to black, swap scenes, fade back in.
	## Calling this while already transitioning is a no-op to prevent double-loads.
	if is_transitioning:
		return
	is_transitioning = true
	_pending_scene_path = scene_path if not scene_data.is_empty() else ""
	_pending_scene_data = scene_data.duplicate(true) if not scene_data.is_empty() else {}

	# Fade out (current scene disappears behind black)
	var tween_out := _make_tween()
	tween_out.tween_property(transition_rect, "modulate:a", 1.0, fade_duration)
	await tween_out.finished

	# Swap to the new scene
	get_tree().change_scene_to_file(scene_path)

	# Fade in (new scene revealed)
	var tween_in := _make_tween()
	tween_in.tween_property(transition_rect, "modulate:a", 0.0, fade_duration)
	await tween_in.finished

	is_transitioning = false


func consume_scene_data(scene_path: String) -> Dictionary:
	## Returns one-shot transition payload for the requested scene path.
	if _pending_scene_path != scene_path:
		return {}

	var data := _pending_scene_data.duplicate(true)
	_pending_scene_path = ""
	_pending_scene_data = {}
	return data


func _exit_tree() -> void:
	release_transition_resources()


func release_transition_resources() -> void:
	for tween in _tracked_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_tracked_tweens.clear()


func _make_tween() -> Tween:
	var tween := create_tween()
	_tracked_tweens.append(tween)
	return tween

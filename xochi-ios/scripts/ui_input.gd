extends Node
## UI input continues while gameplay is paused. It never advances the world.
var main: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and is_instance_valid(main) and main.playing and not main.finished:
		if get_tree().paused: main._resume()
		else: main._pause()
		get_viewport().set_input_as_handled()

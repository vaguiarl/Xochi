extends Node2D
## The original floating calavera, repurposed as an expressive canal spirit.
## This actor supplies presentation only; the encounter owns her decisions.

var active := true
var mood := "curious"
var facing := 1.0
var display_height := 120.0
var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()
var visual_time := 0.0
var _mood_time := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if texture == null and ResourceLoader.exists("res://assets/companion/calaca.png"):
		texture = load("res://assets/companion/calaca.png")
	queue_redraw()

func configure(origin: Vector2) -> void:
	global_position = origin
	reset_state()

func reset_state() -> void:
	active = true
	mood = "curious"
	facing = 1.0
	visual_time = 0.0
	_mood_time = 0.0
	queue_redraw()

func set_mood(value: String) -> void:
	if mood != value:
		mood = value
		_mood_time = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if not active:
		return
	visual_time += delta
	_mood_time += delta
	queue_redraw()

func _draw() -> void:
	if texture == null:
		return
	var speed := 2.0
	var amplitude := 5.0
	var tilt := sin(visual_time * 1.3) * 0.045
	if mood in ["excited", "helpful", "celebrating"]:
		speed = 4.2
		amplitude = 8.0
	elif mood in ["worried", "warning"]:
		speed = 2.8
		amplitude = 3.0
		tilt -= 0.09
	elif mood == "listening":
		amplitude = 2.0
		tilt = 0.09
	var bob := sin(visual_time * speed) * amplitude
	var squash := sin(visual_time * speed) * 0.025
	var texture_size := texture.get_size()
	var width := display_height * texture_size.x / maxf(texture_size.y, 1.0)
	draw_set_transform(Vector2(0.0, bob), tilt, Vector2(facing * (1.0 + squash), 1.0 - squash))
	draw_texture_rect(texture, Rect2(-width / 2.0, -display_height / 2.0, width, display_height), false)
	draw_set_transform(Vector2.ZERO)

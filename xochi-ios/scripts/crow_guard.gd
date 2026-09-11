extends Node2D
## A curious, self-important Crowquistador. Distraction opens a crossing;
## a repeated trick gets a shorter, still usable opening. No lethal attacks.

signal noticed
signal opening_changed(open: bool)
signal state_changed(state_name: String)

const NOTICE_SECONDS := 0.65
const RETURN_SECONDS := 1.1
const OPENINGS := [6.0, 4.8, 3.8]
const TRICKS := ["bell", "splash", "flower"]
const SPRITE_HEIGHT := 142.0

var active := true:
	set(value):
		var was_open := active and state == "investigate"
		active = value
		var now_open := active and state == "investigate"
		if was_open != now_open:
			opening_changed.emit(now_open)
var state := "watch"
var mood := "watchful"
var origin := Vector2.ZERO
var facing := -1.0
var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()
var state_time := 0.0
var visual_time := 0.0
var opening_duration := 6.0
var trick_counts: Dictionary = {}
var last_trick := ""
var investigation_point := Vector2.ZERO
var _return_from := Vector2.ZERO
var _reported_crossing := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if texture == null and ResourceLoader.exists("res://assets/companion/crowquistador.png"):
		texture = load("res://assets/companion/crowquistador.png")
	queue_redraw()

func configure(home: Vector2) -> void:
	origin = home
	reset_state()

func reset_state() -> void:
	var was_open := can_cross()
	global_position = origin
	state = "watch"
	active = true
	mood = "watchful"
	facing = -1.0
	state_time = 0.0
	visual_time = 0.0
	opening_duration = OPENINGS[0]
	trick_counts.clear()
	last_trick = ""
	investigation_point = origin + Vector2(105.0, -5.0)
	_return_from = origin
	_reported_crossing = false
	if was_open: opening_changed.emit(false)
	state_changed.emit(state)
	queue_redraw()

func reset() -> void:
	reset_state()

func set_mood(value: String) -> void:
	# Mood is visual. It must never bypass the authoritative crossing state.
	mood = value
	queue_redraw()

func distract(trick: String = "bell") -> bool:
	if not active or state != "watch" or trick not in TRICKS:
		return false
	last_trick = trick
	var seen: int = int(trick_counts.get(trick, 0))
	opening_duration = float(OPENINGS[mini(seen, OPENINGS.size() - 1)])
	trick_counts[trick] = mini(seen + 1, OPENINGS.size())
	mood = "curious" if seen == 0 else "skeptical"
	_reported_crossing = false
	_enter("notice")
	return true

func can_cross() -> bool:
	return active and state == "investigate"

func remaining_open_time() -> float:
	return maxf(0.0, opening_duration - state_time) if can_cross() else 0.0

func observe_crossing(player_position: Vector2) -> bool:
	# Root calls this only for a character actually attempting the bridge.
	# Seeing Xochi nearby is harmless until she commits to crossing.
	if not active or can_cross() or _reported_crossing:
		return false
	if player_position.distance_to(global_position) > 230.0:
		return false
	_reported_crossing = true
	mood = "surprised"
	noticed.emit()
	queue_redraw()
	return true

func _enter(next_state: String) -> void:
	var was_open := can_cross()
	state = next_state
	state_time = 0.0
	if can_cross() != was_open:
		opening_changed.emit(can_cross())
	state_changed.emit(state)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not active:
		return
	visual_time += delta
	state_time += delta
	match state:
		"watch":
			global_position = origin
			facing = -1.0
		"notice":
			facing = 1.0
			if state_time >= NOTICE_SECONDS:
				mood = "investigating"
				_enter("investigate")
		"investigate":
			var travel := clampf(state_time / 1.0, 0.0, 1.0)
			global_position = origin.lerp(investigation_point, smoothstep(0.0, 1.0, travel))
			facing = 1.0
			if state_time >= opening_duration:
				_return_from = global_position
				mood = "returning"
				_enter("return")
		"return":
			var travel := clampf(state_time / RETURN_SECONDS, 0.0, 1.0)
			global_position = _return_from.lerp(origin, smoothstep(0.0, 1.0, travel))
			facing = -1.0
			if state_time >= RETURN_SECONDS:
				mood = "watchful"
				_reported_crossing = false
				_enter("watch")
	queue_redraw()

func _draw() -> void:
	if texture == null:
		return
	var texture_size := texture.get_size()
	var width := SPRITE_HEIGHT * texture_size.x / maxf(1.0, texture_size.y)
	var bob := sin(visual_time * 3.5) * 3.0
	var lean := sin(visual_time * 1.7) * 0.018
	var scale_y := 1.0 + sin(visual_time * 3.5) * 0.012
	if state == "notice":
		bob -= absf(sin(state_time * 10.0)) * 4.5
		lean = -0.08 if mood == "skeptical" else 0.065
	elif state == "investigate":
		lean = 0.08 + sin(visual_time * 3.0) * 0.025
	elif state == "return":
		lean = -0.09
	if mood == "surprised":
		scale_y += 0.04
	draw_set_transform(Vector2(0.0, bob), lean * facing, Vector2(facing, scale_y))
	draw_texture_rect(texture, Rect2(-width / 2.0, -SPRITE_HEIGHT + 8.0, width, SPRITE_HEIGHT), false)
	draw_set_transform(Vector2.ZERO)
	# These are signals above the original illustrated character, never a
	# replacement face/body. Their meaning is identical in English and Spanish.
	var marker := ""
	if state == "notice": marker = "?"
	elif mood == "surprised" or state == "return": marker = "!"
	if not marker.is_empty():
		var font := ThemeDB.fallback_font
		var marker_width := font.get_string_size(marker, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		draw_string(font, Vector2(-marker_width * 0.5, -SPRITE_HEIGHT - 4.0 + bob), marker,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("ffe0a1"))
	if can_cross():
		var fraction := remaining_open_time() / opening_duration
		var start := Vector2(-28.0, 18.0)
		draw_line(start, start + Vector2(56.0, 0.0), Color(0.1, 0.3, 0.3, 0.7), 4.0, true)
		draw_line(start, start + Vector2(56.0 * fraction, 0.0), Color("aeddb6"), 3.0, true)

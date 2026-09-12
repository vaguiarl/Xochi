extends Node2D
signal noticed
signal caught
signal opening_changed(open: bool)
signal state_changed(state_name: String)
const NOTICE_SECONDS := 0.75
const SPRITE_HEIGHT := 142.0
var active := true
var state := "watch"
var mood := "watchful"
var origin := Vector2.ZERO
var facing := -1.0
var texture: Texture2D
var state_time := 0.0
var visual_time := 0.0
var opening_duration := 4.0
var trick_counts: Dictionary = {}
var last_trick := ""
var investigation_point := Vector2.ZERO
var target: Node2D
var target_hidden := false
var lost_time := 0.0
var last_seen := Vector2.ZERO
var patrol_half_width := 150.0
var bank_min := 900.0
var bank_max := 1750.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture = load("res://assets/companion/crowquistador.png")

func configure(home: Vector2) -> void:
	origin = home
	reset_state()

func reset_state() -> void:
	global_position = origin
	facing = -1
	trick_counts.clear()
	lost_time = 0
	_enter("watch")

func reset() -> void: reset_state()
func set_mood(value: String) -> void: mood = value
func can_cross() -> bool: return active and state == "investigate"
func remaining_open_time() -> float: return maxf(0,opening_duration-state_time) if can_cross() else 0.0

func distract(trick := "bell") -> bool:
	if not active: return false
	last_trick = trick
	var count := int(trick_counts.get(trick,0))
	opening_duration = maxf(3,4-count*.5)
	trick_counts[trick] = count+1
	investigation_point = origin+Vector2(170,0)
	_enter("investigate")
	return true

func observe_crossing(point: Vector2) -> bool:
	return active and not target_hidden and absf(point.y-global_position.y)<95 and absf(point.x-global_position.x)<270 and (point.x-global_position.x)*facing>=-15

func _enter(value: String) -> void:
	state = value
	state_time = 0
	mood = value
	opening_changed.emit(can_cross())
	state_changed.emit(state)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not active: return
	state_time += delta
	visual_time += delta
	var sees := is_instance_valid(target) and observe_crossing(target.global_position)
	if sees: last_seen = target.global_position
	match state:
		"watch":
			global_position.x += facing*55*delta
			if absf(global_position.x-origin.x)>patrol_half_width: facing = -signf(global_position.x-origin.x)
			if sees:
				_enter("notice")
				noticed.emit()
		"notice":
			if not sees: _enter("search")
			elif state_time>=NOTICE_SECONDS: _enter("chase")
		"chase":
			lost_time = 0 if sees else lost_time+delta
			if lost_time>=1.5:
				_enter("search")
			else:
				facing = signf(last_seen.x-global_position.x)
				global_position.x = move_toward(global_position.x,clampf(last_seen.x,bank_min,bank_max),255*delta)
				if is_instance_valid(target) and not target_hidden and global_position.distance_to(target.global_position)<30:
					active = false
					caught.emit()
		"search":
			if sees: _enter("notice")
			elif state_time>2: _enter("return")
		"investigate":
			facing = signf(investigation_point.x-global_position.x)
			global_position.x = move_toward(global_position.x,investigation_point.x,170*delta)
			if state_time>=opening_duration: _enter("return")
		"return":
			facing = signf(origin.x-global_position.x)
			global_position.x = move_toward(global_position.x,origin.x,95*delta)
			if sees: _enter("notice")
			elif absf(global_position.x-origin.x)<3: _enter("watch")
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
	if state == "notice" or state == "chase": marker = "!"
	elif state == "search": marker = "?"
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

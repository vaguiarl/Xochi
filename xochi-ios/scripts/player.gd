extends CharacterBody2D
## Xochi's movement is authoritative; anticipation and squash only affect drawing.
## A touch is owned only after it reaches _unhandled_input, keeping HUD taps safe.

signal died
signal ripple(origin: Vector2, direction: float)
signal jumped(hyper: bool)

const WALK_SPEED := 220.0
const RUN_SPEED := 340.0
const JUMP_SPEED := -480.0
const HYPER_SPEED := -650.0
const GRAVITY := 800.0
const COYOTE_TIME := 0.20
const BUFFER_TIME := 0.15
const HOLD_TIME := 0.40
const SWIPE_DISTANCE := 40.0
const TAP_DISTANCE := 30.0
const TAP_TIME := 0.20
const DOUBLE_SWIPE_TIME := 0.40
const ATTACK_DURATION := 0.25
const ATTACK_COOLDOWN := 0.38

var active := true
var facing := 1.0
var hyper_charges := 2
var reserve_available := false
var invulnerable := 0.0
var attack_time := 0.0
var visual_time := 0.0
var character_texture: Texture2D:
	set(value):
		character_texture = value
		queue_redraw()
var character_atlas: Texture2D:
	set(value):
		character_atlas = value
		_atlas_frames.clear()
		if value != null:
			var cell_size := value.get_size() * 0.5
			for frame in range(4):
				var atlas_frame := AtlasTexture.new()
				atlas_frame.atlas = value
				atlas_frame.region = Rect2(Vector2(frame % 2, floori(frame / 2.0)) * cell_size, cell_size)
				atlas_frame.filter_clip = true
				_atlas_frames.append(atlas_frame)
		queue_redraw()

var _atlas_frames: Array[AtlasTexture] = []
var _coyote := 0.0
var _jump_buffer := 0.0
var _attack_cooldown := 0.0
var _landing_squash := 0.0
var _hyper_flash := 0.0
var _clock := 0.0
var _jumped_from_ground := false
var _was_grounded := false
var _keyboard_blocked := false
var _touch_index := -1
var _touch_generation := 0
var _touch_origin := Vector2.ZERO
var _touch_position := Vector2.ZERO
var _touch_elapsed := 0.0
var _touch_used := false
var _touch_swiped := false
var _touch_jumped := false
var _touch_direction := 0.0
var _touch_running := false
var _hold_next_at := HOLD_TIME
var _last_swipe_at := -10.0
var _last_swipe_direction := 0.0
var _secondary_index := -1
var _secondary_generation := 0
var _secondary_origin := Vector2.ZERO
var _secondary_elapsed := 0.0
var _secondary_used := false
var _secondary_moved := false
var _secondary_hold_next_at := HOLD_TIME
var _trail: Array[Dictionary] = []
var _trail_clock := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	floor_snap_length = 6.0
	floor_stop_on_slope = true
	if get_node_or_null("BodyShape") == null:
		var shape := CollisionShape2D.new()
		shape.name = "BodyShape"
		var capsule := CapsuleShape2D.new()
		capsule.radius = 14.0
		capsule.height = 50.0
		shape.shape = capsule
		shape.position = Vector2(0, -25)
		add_child(shape)
	queue_redraw()


func _physics_process(delta: float) -> void:
	visual_time += delta
	_clock += delta
	invulnerable = maxf(0.0, invulnerable - delta)
	attack_time = maxf(0.0, attack_time - delta)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_landing_squash = maxf(0.0, _landing_squash - delta)
	_hyper_flash = maxf(0.0, _hyper_flash - delta)
	_update_trail(delta)
	if not active:
		queue_redraw()
		return

	var grounded := is_on_floor() and velocity.y >= 0.0
	if grounded:
		_coyote = COYOTE_TIME
		_jumped_from_ground = false
	else:
		_coyote = maxf(0.0, _coyote - delta)
	_advance_touch(delta)
	# A Ripple can complete the story through its signal on this exact tick.
	if not active:
		queue_redraw()
		return
	_try_buffered_jump()
	_jump_buffer = maxf(0.0, _jump_buffer - delta)

	var horizontal := 0.0
	var running := false
	if _keyboard_blocked and not _any_game_key_pressed():
		_keyboard_blocked = false
	if not _keyboard_blocked:
		horizontal = float(Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A))
		running = Input.is_physical_key_pressed(KEY_SHIFT)
	if is_zero_approx(horizontal):
		horizontal = _touch_direction
		running = _touch_running
	if not is_zero_approx(horizontal):
		facing = signf(horizontal)
		velocity.x = move_toward(velocity.x, horizontal * (RUN_SPEED if running else WALK_SPEED), 1700.0 * delta)
	else:
		# A released swipe glides, but its stored momentum never feeds back into speed.
		velocity.x = move_toward(velocity.x, 0.0, (760.0 if grounded else 220.0) * delta)

	if not grounded or velocity.y < 0.0:
		var gravity_scale := 1.0
		if absf(velocity.y) < 50.0:
			gravity_scale = 0.4
		elif velocity.y > 0.0:
			gravity_scale = 1.6
		velocity.y = minf(velocity.y + GRAVITY * gravity_scale * delta, 920.0)
	var falling_speed := velocity.y
	move_and_slide()
	if is_on_floor() and not _was_grounded and falling_speed > 90.0:
		_landing_squash = 0.18
		_coyote = COYOTE_TIME
		_jumped_from_ground = false
		# A press in the final 150 ms of a fall launches on this landing frame.
		_try_buffered_jump()
	_was_grounded = is_on_floor() and velocity.y >= 0.0
	queue_redraw()


func jump_normal() -> void:
	if active:
		_jump_buffer = BUFFER_TIME


func _try_buffered_jump() -> void:
	if _jump_buffer > 0.0 and _coyote > 0.0 and not _jumped_from_ground:
		velocity.y = JUMP_SPEED
		_jump_buffer = 0.0
		_coyote = 0.0
		_jumped_from_ground = true
		jumped.emit(false)


func jump_hyper() -> void:
	if not active:
		return
	if hyper_charges > 0:
		hyper_charges -= 1
	elif reserve_available:
		reserve_available = false
	else:
		return
	velocity.y = HYPER_SPEED
	_jump_buffer = 0.0
	_coyote = 0.0
	_jumped_from_ground = true
	_hyper_flash = 0.48
	jumped.emit(true)
	queue_redraw()


func perform_ripple() -> void:
	if not active or _attack_cooldown > 0.0:
		return
	attack_time = ATTACK_DURATION
	_attack_cooldown = ATTACK_COOLDOWN
	ripple.emit(global_position + Vector2(0, -26), facing)
	queue_redraw()


func take_hit() -> void:
	if not active or invulnerable > 0.0:
		return
	active = false
	velocity = Vector2.ZERO
	clear_input()
	died.emit()
	queue_redraw()


func reset_at(pos: Vector2, has_reserve: bool = false) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	facing = 1.0
	hyper_charges = 2
	reserve_available = has_reserve
	invulnerable = 0.85
	attack_time = 0.0
	_attack_cooldown = 0.0
	_jump_buffer = 0.0
	_coyote = 0.0
	_jumped_from_ground = false
	_was_grounded = false
	_hyper_flash = 0.0
	_landing_squash = 0.0
	_trail.clear()
	clear_input()
	active = true
	reset_physics_interpolation()
	queue_redraw()


func clear_input() -> void:
	_touch_generation += 1
	_touch_index = -1
	_touch_elapsed = 0.0
	_touch_used = false
	_touch_swiped = false
	_touch_jumped = false
	_touch_direction = 0.0
	_touch_running = false
	_hold_next_at = HOLD_TIME
	_last_swipe_at = -10.0
	_last_swipe_direction = 0.0
	_jump_buffer = 0.0
	_keyboard_blocked = _any_game_key_pressed()
	_end_secondary()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		clear_input()


func _any_game_key_pressed() -> bool:
	for key in [KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D, KEY_SPACE, KEY_X, KEY_Z, KEY_SHIFT]:
		if Input.is_physical_key_pressed(key):
			return true
	return false


func _input(event: InputEvent) -> void:
	# GUI may consume the release of a gesture that began on the world. Clean up
	# that owned touch after dispatch; only _unhandled_input can trigger its action.
	if event is InputEventScreenTouch and not event.pressed and event.index == _touch_index:
		if event.canceled:
			_end_touch()
		else:
			_release_if_still_owned.call_deferred(event.index, _touch_generation)
	elif event is InputEventScreenTouch and not event.pressed and event.index == _secondary_index:
		if event.canceled:
			_end_secondary()
		else:
			_release_secondary_if_owned.call_deferred(event.index, _secondary_generation)


func _release_if_still_owned(index: int, generation: int) -> void:
	if _touch_index == index and _touch_generation == generation:
		_end_touch()


func _release_secondary_if_owned(index: int, generation: int) -> void:
	if _secondary_index == index and _secondary_generation == generation:
		_end_secondary()


func _unhandled_input(event: InputEvent) -> void:
	if not active or get_tree().paused:
		return
	if event is InputEventKey and event.pressed and not event.echo and not _keyboard_blocked:
		match event.physical_keycode:
			KEY_SPACE, KEY_UP, KEY_W:
				jump_normal()
			KEY_X:
				jump_hyper()
			KEY_Z:
				perform_ripple()
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_begin_touch(event.index, event.position)
		elif event.pressed and _secondary_index == -1:
			_begin_secondary(event.index, event.position)
		elif not event.pressed and event.index == _touch_index:
			if not event.canceled and not _touch_used and _touch_elapsed < TAP_TIME and event.position.distance_to(_touch_origin) < TAP_DISTANCE:
				jump_hyper()
			_end_touch()
		elif not event.pressed and event.index == _secondary_index:
			if not event.canceled and not _secondary_used and _secondary_elapsed < TAP_TIME and event.position.distance_to(_secondary_origin) < TAP_DISTANCE:
				jump_hyper()
			_end_secondary()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_drag_touch(event.position)
	elif event is InputEventScreenDrag and event.index == _secondary_index:
		var displacement: Vector2 = event.position - _secondary_origin
		if displacement.length() >= SWIPE_DISTANCE and not _secondary_moved:
			_secondary_used = true
			_secondary_moved = true
			if displacement.y < -25.0:
				jump_normal()


func _begin_touch(index: int, pos: Vector2) -> void:
	_touch_generation += 1
	_touch_index = index
	_touch_origin = pos
	_touch_position = pos
	_touch_elapsed = 0.0
	_touch_used = false
	_touch_swiped = false
	_touch_jumped = false
	_touch_direction = 0.0
	_touch_running = false
	_hold_next_at = HOLD_TIME


func _drag_touch(pos: Vector2) -> void:
	_touch_position = pos
	var displacement := pos - _touch_origin
	if displacement.length() < SWIPE_DISTANCE:
		return
	_touch_used = true
	if displacement.y < -25.0 and not _touch_jumped:
		_touch_jumped = true
		jump_normal()
		if absf(displacement.x) > 20.0:
			_touch_direction = signf(displacement.x)
			velocity.x = clampf(displacement.x * 2.0, -RUN_SPEED, RUN_SPEED)
		elif absf(velocity.x) > 20.0:
			_touch_direction = signf(velocity.x)
			_touch_running = absf(velocity.x) > 260.0
	elif absf(displacement.x) >= SWIPE_DISTANCE:
		var direction := signf(displacement.x)
		if not _touch_swiped:
			_touch_running = direction == _last_swipe_direction and _clock - _last_swipe_at < DOUBLE_SWIPE_TIME
			_last_swipe_at = _clock
			_last_swipe_direction = direction
			_touch_swiped = true
			velocity.x = direction * (RUN_SPEED if _touch_running else WALK_SPEED)
		_touch_direction = direction
		facing = direction
	# Any large motion permanently cancels hold recognition for this touch.
	_touch_swiped = true


func _advance_touch(delta: float) -> void:
	if _secondary_index != -1:
		_secondary_elapsed += delta
		if not _secondary_moved and _secondary_elapsed + 0.00001 >= _secondary_hold_next_at:
			_secondary_used = true
			_secondary_hold_next_at += HOLD_TIME
			perform_ripple()
	if _touch_index == -1:
		return
	_touch_elapsed += delta
	if not _touch_swiped and not _touch_jumped and _touch_elapsed + 0.00001 >= _hold_next_at:
		_touch_used = true
		_hold_next_at += HOLD_TIME
		perform_ripple()


func _begin_secondary(index: int, pos: Vector2) -> void:
	_secondary_generation += 1
	_secondary_index = index
	_secondary_origin = pos
	_secondary_elapsed = 0.0
	_secondary_used = false
	_secondary_moved = false
	_secondary_hold_next_at = HOLD_TIME


func _end_secondary() -> void:
	_secondary_generation += 1
	_secondary_index = -1
	_secondary_elapsed = 0.0
	_secondary_used = false
	_secondary_moved = false
	_secondary_hold_next_at = HOLD_TIME


func _end_touch() -> void:
	_touch_generation += 1
	_touch_index = -1
	_touch_direction = 0.0
	_touch_running = false
	_touch_elapsed = 0.0
	_touch_used = false
	_touch_swiped = false
	_touch_jumped = false
	_hold_next_at = HOLD_TIME


func _update_trail(delta: float) -> void:
	for index in range(_trail.size() - 1, -1, -1):
		_trail[index]["life"] -= delta
		if _trail[index]["life"] <= 0:
			_trail.remove_at(index)
	_trail_clock -= delta
	if active and _hyper_flash > 0.0 and _trail_clock <= 0.0:
		_trail_clock = 0.045
		_trail.append({"position": global_position + Vector2(0, -20), "life": 0.3})


func _draw() -> void:
	for mark in _trail:
		var alpha: float = mark["life"] / 0.3
		draw_circle(mark["position"] - global_position, 10.0 * alpha, Color(0.55, 0.98, 0.84, alpha * 0.27))
	var idle := sin(visual_time * 3.6)
	var run_phase := visual_time * (19.0 if absf(velocity.x) > 260.0 else 14.0)
	var walk_amount := minf(absf(velocity.x) / WALK_SPEED, 1.0)
	var squash := sin(_landing_squash / 0.18 * PI) * 0.22
	var airborne_stretch := 0.07 if velocity.y < -150.0 else 0.0
	var bob := -absf(sin(run_phase)) * 2.3 * walk_amount + idle * 0.5
	var body_scale := Vector2(facing * (1.0 + squash - airborne_stretch * 0.5), 1.0 - squash + airborne_stretch)
	var alpha := 0.87 + 0.13 * sin(visual_time * 12.0) if invulnerable > 0.0 else 1.0
	if reserve_available:
		draw_circle(Vector2(0, -28), 42.0 + idle * 2.0, Color(0.54, 0.98, 0.8, 0.10))
		draw_arc(Vector2(0, -28), 38.0 + idle * 2.0, 0, TAU, 48, Color(0.71, 1.0, 0.79, 0.25), 1.3, true)
	draw_set_transform(Vector2(0, bob), 0.0, body_scale)
	var pose_texture: Texture2D = character_texture
	var atlas_pose := false
	var pose_index := 0
	if _atlas_frames.size() == 4:
		if attack_time > 0.0:
			pose_index = 3
			atlas_pose = true
		elif not is_on_floor():
			pose_index = 2
			atlas_pose = true
		elif walk_amount > 0.15:
			pose_index = int(visual_time * (12.0 if absf(velocity.x) > 260.0 else 8.0)) % 2
			atlas_pose = true
		if atlas_pose:
			pose_texture = _atlas_frames[pose_index]
	if pose_texture != null:
		var source_size := pose_texture.get_size()
		var height := 86.0 if atlas_pose else 76.0
		var width := height * source_size.x / maxf(source_size.y, 1.0)
		var foot_anchor := 0.89 if atlas_pose else 0.98
		if atlas_pose and pose_index == 2:
			foot_anchor = 0.83
		var center_anchor := 0.66 if atlas_pose else 0.60
		draw_texture_rect(pose_texture, Rect2(-width * center_anchor, -height * foot_anchor, width, height), false, Color(1, 1, 1, alpha))
	else:
		_draw_axolotl(run_phase, walk_amount, idle, alpha)
	draw_set_transform(Vector2.ZERO)
	if attack_time > 0.0:
		var progress := 1.0 - attack_time / ATTACK_DURATION
		var center := Vector2(facing * (24.0 + progress * 28.0), -25.0)
		var radius := 10.0 + progress * 29.0
		draw_circle(center, radius, Color(0.43, 0.95, 0.89, 0.12 * (1.0 - progress)))
		draw_arc(center, radius, -PI * 0.78, PI * 0.78, 32, Color(0.73, 1.0, 0.94, (1.0 - progress) * 0.9), 3.5, true)
		for petal in range(5):
			var angle := float(petal) * TAU / 5.0 + progress
			draw_circle(center + Vector2.from_angle(angle) * radius, 2.8 * (1.0 - progress), Color(1.0, 0.78, 0.39, 1.0 - progress))


func _draw_axolotl(run_phase: float, walk_amount: float, idle: float, alpha: float) -> void:
	var pink := Color(1.0, 0.67, 0.76, alpha)
	var light := Color(1.0, 0.80, 0.84, alpha)
	var coral := Color(0.92, 0.39, 0.56, alpha)
	var cream := Color(1.0, 0.91, 0.83, alpha)
	var jade := Color(0.13, 0.60, 0.48, alpha)
	var tail_wave := sin(visual_time * 6.0) * 4.0
	var tail := PackedVector2Array([Vector2(-10, -20), Vector2(-28, -10), Vector2(-44, -14 + tail_wave), Vector2(-38, -6 + tail_wave), Vector2(-27, -2), Vector2(-8, -8)])
	draw_colored_polygon(tail, coral.lightened(0.16))
	draw_polyline(PackedVector2Array([Vector2(-36, -10 + tail_wave), Vector2(-24, -8), Vector2(-9, -13)]), pink, 6.0, true)
	# Soft scarf tips trail behind the body without hiding its silhouette.
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -32), Vector2(-28, -27 + idle * 2), Vector2(-24, -34 + idle * 2), Vector2(-7, -38)]), jade.darkened(0.12))
	var left_step := sin(run_phase) * 4.5 * walk_amount
	draw_circle(Vector2(-10, -5 + left_step), 7.3, coral.lightened(0.26))
	draw_circle(Vector2(10, -5 - left_step), 7.3, pink)
	draw_style_box(_round_style(pink, 16.0), Rect2(-18, -37, 36, 32))
	draw_style_box(_round_style(cream, 12.0), Rect2(-12, -29, 25, 22))
	draw_circle(Vector2(-17, -25 + sin(run_phase + 1.0) * walk_amount * 3.0), 6.0, pink)
	draw_circle(Vector2(18, -23 - sin(run_phase + 1.0) * walk_amount * 3.0), 6.0, light)
	# Three feathery gills per side read clearly even at phone scale.
	for side in [-1.0, 1.0]:
		for branch in range(3):
			var root_pos := Vector2(side * 20.0, -46.0 + float(branch - 1) * 6.0)
			var tip := Vector2(side * (33.0 + (3.0 if branch == 1 else 0.0)), -49.0 + float(branch - 1) * 11.0 + idle * 1.3)
			draw_line(root_pos, tip, coral, 5.0, true)
			draw_circle(tip, 3.0, coral)
			var middle := root_pos.lerp(tip, 0.65)
			draw_line(middle, middle + Vector2(side * 3.0, -5.0), coral.lightened(0.12), 2.8, true)
			draw_line(middle, middle + Vector2(side * 4.0, 4.0), coral.lightened(0.12), 2.8, true)
	draw_style_box(_round_style(pink, 20.0), Rect2(-25, -64, 50, 35))
	draw_style_box(_round_style(light, 18.0), Rect2(-21, -63, 43, 27))
	draw_circle(Vector2(-16, -40), 4.8, Color(1.0, 0.53, 0.64, alpha * 0.5))
	draw_circle(Vector2(18, -40), 4.8, Color(1.0, 0.53, 0.64, alpha * 0.5))
	var blinking := fmod(visual_time, 4.1) > 3.95
	for eye_x in [-10.0, 12.0]:
		if blinking:
			draw_line(Vector2(eye_x - 3, -47), Vector2(eye_x + 3, -47), Color(0.24, 0.15, 0.20, alpha), 2.0, true)
		else:
			draw_circle(Vector2(eye_x, -47), 4.4, Color(0.22, 0.14, 0.18, alpha))
			draw_circle(Vector2(eye_x - 1.2, -48.3), 1.4, Color(1, 1, 0.96, alpha))
	draw_arc(Vector2(2, -43), 4.0, 0.2, PI - 0.2, 16, Color(0.44, 0.22, 0.30, alpha), 1.4, true)
	draw_line(Vector2(-16, -32), Vector2(14, -32), jade, 5.0, true)
	draw_circle(Vector2(12, -32), 4.5, jade.lightened(0.12))
	var flower_center := Vector2(-14, -62)
	for petal in range(7):
		var angle := float(petal) * TAU / 7.0
		draw_circle(flower_center + Vector2.from_angle(angle) * 4.0, 3.2, Color(1.0, 0.67, 0.18, alpha))
	draw_circle(flower_center, 3.2, Color(1.0, 0.86, 0.38, alpha))


func _round_style(color: Color, radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(radius))
	return style

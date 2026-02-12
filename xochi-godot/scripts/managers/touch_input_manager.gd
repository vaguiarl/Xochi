extends Node
class_name TouchInputManager
## One-hand touch control system - EXACT port from xochi-web GameScene.js
##
## This is the "phone wizard" touch control system that works beautifully.
## Port of setupTouchControls() from GameScene.js lines 830-1012.
##
## Gestures:
##   SWIPE horizontal = Move with momentum
##   DOUBLE-SWIPE = Run (faster momentum)
##   SWIPE UP = Jump with directional trajectory
##   TAP = Super jump (if available)
##   HOLD = Attack
##
## Usage:
##   var touch_mgr = TouchInputManager.new()
##   add_child(touch_mgr)
##   touch_mgr.setup(player_ref)
##
## The player reads .left, .right, .jump, .attack, .run flags and applies momentum.

# =============================================================================
# CONSTANTS (from original GameScene.js lines 835-845)
# =============================================================================

const TAP_MAX_DURATION: int = 200  # ms
const TAP_MAX_MOVEMENT: int = 30  # px
const SWIPE_MIN_DISTANCE: int = 40  # px
const HOLD_DURATION: int = 400  # ms
const SWIPE_UP_THRESHOLD: int = -25  # px (negative = up)
const WALK_INITIAL_VELOCITY: float = 350.0
const RUN_INITIAL_VELOCITY: float = 420.0
const DOUBLE_SWIPE_WINDOW: int = 400  # ms
const SWIPE_LENGTH_MULTIPLIER: float = 1.5
const MAX_SWIPE_LENGTH: int = 150  # px
const MAX_SWIPE_VELOCITY: float = 350.0

# =============================================================================
# PUBLIC STATE (read by Player)
# =============================================================================

## Touch control flags that player reads each frame
var left: bool = false
var right: bool = false
var jump: bool = false
var attack: bool = false
var run: bool = false
var swipe_velocity_x: float = 0.0

# =============================================================================
# INTERNAL STATE
# =============================================================================

var player: CharacterBody2D = null

## Primary touch tracking (lines 847-854)
var primary_touch := {
	"active": false,
	"pointer_id": 0,
	"origin_x": 0.0,
	"origin_y": 0.0,
	"current_x": 0.0,
	"current_y": 0.0,
	"start_time": 0,
	"last_move_time": 0,
	"hold_timer": null,  # Timer node
	"is_used": false,
	"has_jumped": false,
	"swipe_velocity_x": 0.0,
	"swipe_velocity_y": 0.0,
	"has_triggered_swipe": false
}

## Movement state for momentum and double-swipe detection
var movement_state := {
	"finger_down": false,
	"momentum": 0.0,
	"maintain_direction": 0,  # -1 left, 0 none, 1 right
	"last_swipe_direction": 0,
	"last_swipe_time": 0
}

## UI elements
var pause_button: Control = null
var hint_label: Label = null
var ui_layer: CanvasLayer = null

# =============================================================================
# SETUP
# =============================================================================

func setup(player_ref: CharacterBody2D) -> void:
	## Initialize touch controls for the given player.
	player = player_ref

	# Only show UI on touch devices
	if DisplayServer.is_touchscreen_available():
		_create_ui()


func _create_ui() -> void:
	## Create pause button and control hint (lines 994-1012)
	ui_layer = CanvasLayer.new()
	ui_layer.name = "TouchUI"
	ui_layer.layer = 100  # Above everything
	add_child(ui_layer)

	# Pause button (top-right, viewport-relative)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var pause_x: float = viewport_size.x - 30.0
	var pause_y: float = 30.0

	# Background circle
	var pause_bg := ColorRect.new()
	pause_bg.name = "PauseButton"
	pause_bg.size = Vector2(40, 40)
	pause_bg.position = Vector2(pause_x - 20, pause_y - 20)
	pause_bg.color = Color(0.4, 0.4, 0.4, 0.4)
	pause_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_layer.add_child(pause_bg)

	# "||" text
	var pause_text := Label.new()
	pause_text.text = "||"
	pause_text.position = Vector2(pause_x - 8, pause_y - 10)
	pause_text.add_theme_font_size_override("font_size", 16)
	pause_text.add_theme_color_override("font_color", Color.WHITE)
	pause_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(pause_text)

	pause_button = pause_bg

	# Control hint (bottom center)
	var hint_x: float = viewport_size.x / 2.0
	var hint_y: float = viewport_size.y - 40.0

	hint_label = Label.new()
	hint_label.text = "SWIPE = MOVE  |  DOUBLE-SWIPE = RUN  |  SWIPE UP = JUMP  |  TAP = SUPER JUMP"
	hint_label.position = Vector2(hint_x - 200, hint_y)  # Approximate center
	hint_label.add_theme_font_size_override("font_size", 10)
	hint_label.add_theme_color_override("font_color", Color.WHITE)
	hint_label.add_theme_constant_override("outline_size", 2)
	hint_label.add_theme_color_override("font_outline_color", Color.BLACK)
	hint_label.modulate.a = 0.8
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_layer.add_child(hint_label)

	# Fade out hint after 4 seconds
	var fade_tween := create_tween()
	fade_tween.tween_interval(4.0)
	fade_tween.tween_property(hint_label, "modulate:a", 0.0, 1.0)
	fade_tween.tween_callback(hint_label.queue_free)


# =============================================================================
# INPUT HANDLING (exact port of pointerdown/move/up/cancel from lines 857-992)
# =============================================================================

func _input(event: InputEvent) -> void:
	if not DisplayServer.is_touchscreen_available():
		return

	# POINTER DOWN (lines 857-886)
	if event is InputEventScreenTouch and event.pressed:
		# Check if touch on pause button
		if pause_button and _is_point_in_rect(event.position, pause_button.get_global_rect()):
			if has_node("/root/Events"):
				get_node("/root/Events").game_paused.emit()
			get_viewport().set_input_as_handled()
			return

		if primary_touch.active:
			return

		primary_touch.active = true
		primary_touch.pointer_id = event.index
		primary_touch.origin_x = event.position.x
		primary_touch.origin_y = event.position.y
		primary_touch.current_x = event.position.x
		primary_touch.current_y = event.position.y
		primary_touch.start_time = Time.get_ticks_msec()
		primary_touch.last_move_time = Time.get_ticks_msec()
		primary_touch.is_used = false
		primary_touch.has_jumped = false
		primary_touch.swipe_velocity_x = 0.0
		primary_touch.swipe_velocity_y = 0.0
		primary_touch.has_triggered_swipe = false
		movement_state.finger_down = true

		# Hold timer for attack (lines 874-885)
		var hold_timer := get_tree().create_timer(HOLD_DURATION / 1000.0)
		primary_touch.hold_timer = hold_timer
		hold_timer.timeout.connect(func():
			if primary_touch.active and not primary_touch.is_used:
				var dx: float = primary_touch.current_x - primary_touch.origin_x
				var dy: float = primary_touch.current_y - primary_touch.origin_y
				var dist: float = sqrt(dx*dx + dy*dy)
				if dist < SWIPE_MIN_DISTANCE:
					primary_touch.is_used = true
					attack = true
					await get_tree().create_timer(0.05).timeout
					attack = false
		)

	# POINTER MOVE (lines 889-945)
	elif event is InputEventScreenDrag:
		if not primary_touch.active or event.index != primary_touch.pointer_id:
			return

		var now: int = Time.get_ticks_msec()
		var dt: float = maxf(float(now - primary_touch.last_move_time), 1.0)
		var instant_vel_x: float = (event.position.x - primary_touch.current_x) / dt * 16.0
		primary_touch.swipe_velocity_x = primary_touch.swipe_velocity_x * 0.7 + instant_vel_x * 0.3
		primary_touch.current_x = event.position.x
		primary_touch.current_y = event.position.y
		primary_touch.last_move_time = now

		var dx: float = event.position.x - primary_touch.origin_x
		var dy: float = event.position.y - primary_touch.origin_y
		var distance: float = sqrt(dx*dx + dy*dy)

		if distance > SWIPE_MIN_DISTANCE:
			# Clear hold timer - this is a swipe
			if primary_touch.hold_timer:
				primary_touch.hold_timer = null

			# SWIPE UP = JUMP (lines 910-922)
			if dy < SWIPE_UP_THRESHOLD and not primary_touch.has_jumped:
				primary_touch.has_jumped = true
				primary_touch.is_used = true
				jump = true

				var swipe_angle: float = atan2(-dy, dx)
				var swipe_magnitude: float = minf(distance, 150.0)
				var horizontal_power: float = cos(swipe_angle) * swipe_magnitude * 2.0
				swipe_velocity_x = clampf(horizontal_power, -MAX_SWIPE_VELOCITY, MAX_SWIPE_VELOCITY)

				if dx < -20:
					left = true
					right = false
					movement_state.maintain_direction = -1
				elif dx > 20:
					left = false
					right = true
					movement_state.maintain_direction = 1

				if absf(horizontal_power) > 30:
					movement_state.momentum = horizontal_power

				await get_tree().create_timer(0.05).timeout
				jump = false

			# HORIZONTAL SWIPE = MOMENTUM (lines 924-943)
			elif not primary_touch.has_jumped and not primary_touch.has_triggered_swipe:
				primary_touch.has_triggered_swipe = true
				var swipe_direction: int = 1 if dx > 0 else -1
				var swipe_length: float = minf(absf(dx), float(MAX_SWIPE_LENGTH))
				var swipe_length_factor: float = 1.0 + (swipe_length / float(MAX_SWIPE_LENGTH)) * (SWIPE_LENGTH_MULTIPLIER - 1.0)
				var swipe_speed: float = absf(primary_touch.swipe_velocity_x)
				var swipe_speed_factor: float = minf(swipe_speed / 100.0, 1.5)
				var time_since_last: int = now - movement_state.last_swipe_time
				var is_double_tap: bool = swipe_direction == movement_state.last_swipe_direction and time_since_last < DOUBLE_SWIPE_WINDOW
				var base_velocity: float = RUN_INITIAL_VELOCITY if is_double_tap else WALK_INITIAL_VELOCITY
				run = is_double_tap
				var final_velocity: float = base_velocity * float(swipe_direction) * swipe_length_factor * swipe_speed_factor
				movement_state.momentum = clampf(final_velocity, -MAX_SWIPE_VELOCITY, MAX_SWIPE_VELOCITY)
				movement_state.maintain_direction = swipe_direction
				movement_state.last_swipe_direction = swipe_direction
				movement_state.last_swipe_time = now

				if swipe_direction < 0:
					left = true
					right = false
				else:
					left = false
					right = true

				swipe_velocity_x = movement_state.momentum

	# POINTER UP (lines 948-978)
	elif event is InputEventScreenTouch and not event.pressed:
		if not primary_touch.active or event.index != primary_touch.pointer_id:
			return

		var dx: float = event.position.x - primary_touch.origin_x
		var dy: float = event.position.y - primary_touch.origin_y
		var distance: float = sqrt(dx*dx + dy*dy)
		var elapsed: int = Time.get_ticks_msec() - primary_touch.start_time

		if primary_touch.hold_timer:
			primary_touch.hold_timer = null

		# TAP = Super jump (lines 957-965)
		if not primary_touch.is_used and elapsed < TAP_MAX_DURATION and distance < TAP_MAX_MOVEMENT:
			var game_state = get_node_or_null("/root/GameState")
			if game_state and game_state.super_jumps > 0 and player and not player.is_dead:
				game_state.super_jumps -= 1
				player.velocity.y = -650.0
				var audio_mgr = get_node_or_null("/root/AudioManager")
				if audio_mgr:
					audio_mgr.play_sfx("jump_super")
				_show_super_jump_effect()
				var events = get_node_or_null("/root/Events")
				if events:
					events.super_jump_used.emit()

		# Reset touch state (lines 967-977)
		movement_state.finger_down = false
		movement_state.maintain_direction = 0
		left = false
		right = false
		run = false
		if not primary_touch.has_jumped:
			swipe_velocity_x = 0.0
		primary_touch.active = false
		primary_touch.pointer_id = 0
		primary_touch.is_used = false
		primary_touch.has_jumped = false
		primary_touch.has_triggered_swipe = false


func _is_point_in_rect(point: Vector2, rect: Rect2) -> bool:
	return rect.has_point(point)


# =============================================================================
# SUPER JUMP EFFECT (matching original)
# =============================================================================

func _show_super_jump_effect() -> void:
	## Cyan radial burst particles (12 particles, 360° spread)
	if not player:
		return

	for i in range(12):
		var angle := (float(i) / 12.0) * TAU
		var particle := ColorRect.new()
		particle.size = Vector2(6, 6)
		particle.color = Color("00ffff")
		particle.modulate.a = 0.8

		var start_pos := player.global_position + Vector2(cos(angle), sin(angle)) * 10.0
		var end_pos := player.global_position + Vector2(cos(angle), sin(angle)) * 40.0

		particle.global_position = start_pos - particle.size / 2
		get_tree().root.add_child(particle)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "global_position", end_pos - particle.size / 2, 0.3)
		tween.tween_property(particle, "modulate:a", 0.0, 0.3)
		tween.tween_property(particle, "scale", Vector2(0.5, 0.5), 0.3)
		tween.chain().tween_callback(particle.queue_free)


# =============================================================================
# PUBLIC API
# =============================================================================

func get_horizontal_input() -> float:
	## Returns -1.0 (left), 0.0 (none), or 1.0 (right)
	if left:
		return -1.0
	elif right:
		return 1.0
	else:
		return 0.0


func get_momentum() -> float:
	## Returns current momentum value for player to apply
	return movement_state.momentum


func is_touch_device() -> bool:
	return DisplayServer.is_touchscreen_available()

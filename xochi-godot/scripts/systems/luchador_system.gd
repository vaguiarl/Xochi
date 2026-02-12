extends Node
class_name LuchadorSystem
## Manages the Blue Demon Mask (luchador) power-up mode.
##
## When activated, the player gets 15 seconds of enhanced abilities including
## invincibility, speed boost, jump boost, and a special rolling attack.
## The rolling attack is triggered by double-tapping the attack button while
## airborne -- it launches the player forward at high speed, killing any
## enemy on contact with a satisfying blue flash and screen shake.
##
## Exact port from original game.js lines 5607-5816.
##
## Required autoloads: Events, GameState, AudioManager


# =============================================================================
# REFERENCES
# =============================================================================

## The root game scene node (used for spawning afterimages and floating text).
var scene: Node2D

## The player CharacterBody2D.
var player: CharacterBody2D


# =============================================================================
# STATE
# =============================================================================

## Whether the luchador mode is currently active.
var is_active: bool = false

## Seconds remaining on the luchador power-up.
var timer: float = 0.0

## Whether the player is currently in a rolling attack.
var is_rolling: bool = false

## Direction of the current roll: 1 = right, -1 = left.
var roll_direction: int = 1

## Timestamp of the last attack button press for double-tap detection.
var last_z_press_time: float = 0.0


# =============================================================================
# CONSTANTS
# =============================================================================

## Forward speed during a rolling attack in px/s.
const ROLL_FORWARD_SPEED: float = 400.0

## Slight downward velocity applied at the start of a roll.
const ROLL_DOWNWARD_SPEED: float = 100.0

## Horizontal bounce-back speed when a roll hits a wall.
const ROLL_BOUNCE_BACK_SPEED: float = 150.0

## Maximum number of afterimage sprites in the trail.
const AFTERIMAGE_LIMIT: int = 4

## Duration each afterimage fades over, in seconds.
const AFTERIMAGE_DURATION: float = 0.2

## Time window for double-tap detection, in seconds (300 ms).
const DOUBLE_TAP_WINDOW: float = 0.3

## Squashed sprite scale during a roll (compressed horizontally, stretched vertically).
const ROLL_SCALE: Vector2 = Vector2(0.12, 0.18)

## Normal sprite scale restored after a roll ends.
const NORMAL_SCALE: Vector2 = Vector2(0.15, 0.15)

## Luchador blue tint color used for afterimages and enemy flash.
const LUCHA_BLUE: Color = Color(0.0, 0.4, 1.0)


# =============================================================================
# SETUP
# =============================================================================

## Wire up references after the game scene is fully initialized.
## Must be called before the first _physics_process tick.
func setup(game_scene: Node2D, p_player: CharacterBody2D) -> void:
	scene = game_scene
	player = p_player


# =============================================================================
# PHYSICS LOOP
# =============================================================================

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	timer -= delta

	# Warning at 3 seconds remaining (fires once in the 3.0-2.9 window)
	if timer <= 3.0 and timer > 2.9:
		_show_warning()

	# End when timer expires
	if timer <= 0.0:
		deactivate()
		return

	# Check for rolling attack input (double-tap attack in air)
	_check_roll_input()

	# Update rolling state
	if is_rolling:
		_update_roll()
		_create_afterimage()


# =============================================================================
# ACTIVATION
# =============================================================================

## Activate luchador mode for the given duration. The player receives
## invincibility, speed boost, and jump boost via player.activate_luchador().
## The blue tint is handled by the player's _update_animation().
func activate(duration: float = 15.0) -> void:
	is_active = true
	timer = duration
	is_rolling = false

	# Player gets invincibility + speed/jump boost (handled by player.gd)
	if player and player.has_method("activate_luchador"):
		player.activate_luchador(duration)

	# Signal for any listeners (HUD, achievements, analytics)
	Events.luchador_activated.emit()


# =============================================================================
# ROLLING ATTACK -- DOUBLE-TAP ATTACK IN AIR
# =============================================================================

## Detect double-tap of the attack button. If two presses occur within
## DOUBLE_TAP_WINDOW and the player is airborne, start a rolling attack.
func _check_roll_input() -> void:
	if Input.is_action_just_pressed("attack"):
		var now: float = Time.get_ticks_msec() / 1000.0
		if now - last_z_press_time < DOUBLE_TAP_WINDOW:
			# Double tap detected -- start roll if airborne and not already rolling
			if not player.is_on_floor() and not is_rolling:
				start_roll()
		last_z_press_time = now


## Launch the player into a rolling attack. Applies a strong forward push
## with slight downward velocity, squashes the sprite, and plays the SFX.
func start_roll() -> void:
	is_rolling = true
	var dir: int = 1 if player.facing_right else -1
	roll_direction = dir

	# Strong forward push + slight downward
	player.velocity.x = dir * ROLL_FORWARD_SPEED
	player.velocity.y = ROLL_DOWNWARD_SPEED

	# Visual: squash scale for the "ball" look
	player.sprite.scale = ROLL_SCALE

	AudioManager.play_sfx("stomp")


## Check for roll termination conditions: hitting the ground or a wall.
func _update_roll() -> void:
	# End roll when hitting ground
	if player.is_on_floor():
		end_roll(false)

	# End roll when hitting wall
	if player.is_on_wall():
		end_roll(true)


## End the rolling attack and restore normal sprite scale.
## If the roll hit a wall, apply a bounce-back impulse.
func end_roll(hit_wall: bool = false) -> void:
	is_rolling = false

	# Restore normal scale
	player.sprite.scale = NORMAL_SCALE

	if hit_wall:
		# Bounce back away from the wall
		player.velocity.x = -roll_direction * ROLL_BOUNCE_BACK_SPEED
		player.velocity.y = -100.0


# =============================================================================
# ROLLING ATTACK VS ENEMIES
# =============================================================================

## Called by game_scene when rolling player overlaps an enemy.
## Kills the enemy with knockback, applies blue tint, shakes the camera,
## and awards 200 bonus points with floating "+200 LUCHA!" text.
func roll_hit_enemy(enemy: Node2D) -> void:
	if not is_rolling:
		return

	# Kill enemy with knockback
	if enemy.has_method("hit_by_attack"):
		enemy.hit_by_attack()

	# Blue tint on enemy
	if enemy.has_method("set_modulate"):
		enemy.modulate = LUCHA_BLUE

	# Screen shake via the player's Camera2D
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		var orig: Vector2 = camera.offset
		var tween: Tween = scene.create_tween()
		tween.tween_property(camera, "offset", Vector2(3, -3), 0.03)
		tween.tween_property(camera, "offset", Vector2(-3, 3), 0.03)
		tween.tween_property(camera, "offset", orig, 0.03)

	AudioManager.play_sfx("stomp")
	GameState.score += 200
	_show_floating_text(
		enemy.global_position + Vector2(0, -30),
		"+200 LUCHA!",
		LUCHA_BLUE
	)


# =============================================================================
# AFTERIMAGE TRAIL
# =============================================================================

## Spawns a blue translucent rectangle at the player's current position.
## The afterimage fades out and shrinks over AFTERIMAGE_DURATION seconds,
## then self-destructs. Creates the iconic "speed trail" visual.
func _create_afterimage() -> void:
	if not is_rolling or player == null:
		return

	# Create blue ellipse (approximated as ColorRect) at player position
	var afterimage := ColorRect.new()
	afterimage.size = Vector2(30, 20)
	afterimage.position = player.global_position - Vector2(15, 10)
	afterimage.color = Color(LUCHA_BLUE.r, LUCHA_BLUE.g, LUCHA_BLUE.b, 0.6)
	afterimage.z_index = player.z_index - 1
	scene.add_child(afterimage)

	# Fade out and shrink, then self-destruct
	var tween := scene.create_tween()
	tween.set_parallel(true)
	tween.tween_property(afterimage, "modulate:a", 0.0, AFTERIMAGE_DURATION)
	tween.tween_property(afterimage, "scale", Vector2(0.5, 0.5), AFTERIMAGE_DURATION)
	tween.chain().tween_callback(afterimage.queue_free)


# =============================================================================
# WARNING + DEACTIVATION
# =============================================================================

## Show a red floating warning text above the player when 3 seconds remain.
func _show_warning() -> void:
	_show_floating_text(
		player.global_position + Vector2(0, -50),
		"LUCHADOR ENDING!",
		Color(1.0, 0.4, 0.4)
	)


## Deactivate luchador mode. Ends any active roll, resets state, and signals.
## The player handles its own luchador deactivation via _end_luchador().
func deactivate() -> void:
	is_active = false
	timer = 0.0
	if is_rolling:
		end_roll(false)
	last_z_press_time = 0.0
	# player.gd handles its own luchador deactivation via _end_luchador()
	Events.luchador_ended.emit()


# =============================================================================
# FLOATING TEXT UTILITY
# =============================================================================

## Spawn a floating text label that drifts upward and fades out over 0.6 seconds.
## Used for "+200 LUCHA!" score popups and "LUCHADOR ENDING!" warnings.
func _show_floating_text(pos: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.global_position = pos
	label.z_index = 100
	scene.add_child(label)

	var tween := scene.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 30.0, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(label.queue_free)

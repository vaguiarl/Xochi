extends CharacterBody2D
class_name Player
## Xochi player controller -- the heart of the game.
##
## Every physics value here is an EXACT port from the original game.js.
## Do not adjust numbers without comparing against the web build side-by-side.
## The DKC-style animation bobbing (idle breathing, walk/run tilt) comes from
## original lines 6947-6997 and is replicated with identical sin() frequencies.
##
## Required child nodes:
##   - Sprite2D           (texture swapped per state)
##   - CollisionShape2D   (sized to match 0.15-scale sprite)
##
## Required autoloads (declared in project.godot):
##   - Events             (global signal bus)
##   - GameState           (lives, super_jumps, mace_attacks, score, ...)
##   - AudioManager        (play_sfx / play_music helpers)
##
## NOTE: Events autoload needs these two signals added for the attack system:
##   signal player_attacked(position: Vector2, direction: int)
##   signal thunderbolt_fired(position: Vector2, direction: int)


# =============================================================================
# PHYSICS CONSTANTS -- exact values from original game.js
# =============================================================================

## Horizontal walk speed in pixels per second. FASTER for trajinera hopping!
const WALK_SPEED: float = 220.0

## Horizontal run speed (SPACE held) in pixels per second. FASTER!
const RUN_SPEED: float = 340.0

## Normal jump initial velocity (negative = upward). HIGHER for smoother jumps!
const JUMP_VELOCITY: float = -480.0

## Super jump initial velocity -- mid-air only, costs a super-jump charge.
const SUPER_JUMP_VELOCITY: float = -680.0

## Gravity acceleration. REDUCED for better air control and smoother trajinera hopping!
const GRAVITY: float = 800.0

## Grace period after walking off a ledge. MORE FORGIVING for moving platforms!
const COYOTE_TIME: float = 0.20  # 200 ms for trajinera jumping!

## Window after pressing jump where the press is remembered and applied on land.
const JUMP_BUFFER_TIME: float = 0.15  # 150 ms

## Per-frame velocity multiplier when no directional input is held.
## Applied every _physics_process tick (not delta-scaled -- matches original).
const DECELERATION: float = 0.85

## Per-frame momentum friction multiplier (used for external knockback decay).
const FRICTION: float = 0.92

## Velocities below this magnitude snap to zero to prevent drifting.
const MIN_VELOCITY_THRESHOLD: float = 10.0

## Celeste-style apex hang time: gravity multiplier when near jump peak and holding jump.
const APEX_GRAVITY_MULT: float = 0.4

## Speed threshold to consider the player "at apex" (near zero vertical velocity).
const APEX_VELOCITY_THRESHOLD: float = 80.0

## Asymmetric gravity: fall faster than rise for snappy landings.
const FALL_GRAVITY_MULT: float = 1.6

## Corner correction: pixels to nudge sideways when bonking a corner during a jump.
const CORNER_CORRECTION_PIXELS: float = 8.0

## Sprite scale factor. Original sprites are ~400-500 px; displayed at 0.15
## gives an in-game size of roughly 60-70 px, matching the web build exactly.
const BASE_SCALE: float = 0.15

## Melee attack range in pixels from the player's center.
const ATTACK_RANGE: float = 70.0

## Duration of the attack animation lock in seconds.
const ATTACK_DURATION: float = 0.25

## Duration of invincibility after being hit, in seconds.
const INVINCIBILITY_DURATION: float = 0.8  # Fast arcade feel, not 2.0s dead time!

## Knockback velocity applied upward when hit.
const HIT_KNOCKBACK_Y: float = -200.0

## Bounce velocity after stomping an enemy.
const STOMP_BOUNCE_VELOCITY: float = -250.0

## Luchador mode speed multiplier.
const LUCHADOR_SPEED_MULT: float = 1.3

## Luchador mode jump multiplier.
const LUCHADOR_JUMP_MULT: float = 1.2


# =============================================================================
# PRELOADED TEXTURES
# =============================================================================
# Preload so we never hitch on a texture swap mid-gameplay.

var _tex_walk: Texture2D = preload("res://assets/sprites/player/xochi_walk.png")
var _tex_run: Texture2D = preload("res://assets/sprites/player/xochi_run.png")
var _tex_jump: Texture2D = preload("res://assets/sprites/player/xochi_jump.png")
var _tex_attack: Texture2D = preload("res://assets/sprites/player/xochi_attack.png")


# =============================================================================
# STATE
# =============================================================================

## Remaining coyote-time allowance (seconds). Refilled on floor contact.
var coyote_timer: float = 0.0

## Remaining jump-buffer allowance (seconds). Set on jump press.
var jump_buffer_timer: float = 0.0

## Whether the player was on the floor last frame -- used to detect the moment
## they walk off a ledge so coyote time can begin counting down.
var was_on_floor: bool = false

## Double-tap detection for super jump
var last_jump_time: float = 0.0
const DOUBLE_TAP_WINDOW: float = 0.5  # 500ms window for double-tap (more forgiving)

## True while the attack animation is playing and the attack hitbox is active.
var is_attacking: bool = false

## True during post-hit invincibility frames or elote shield.
var is_invincible: bool = false

## True after lives reach zero. Freezes all input and physics.
var is_dead: bool = false

## Which direction the player is facing. Used for attack direction and flip.
var facing_right: bool = true

## Luchador mask power-up state.
var luchador_active: bool = false

## Seconds remaining on the luchador power-up.
var luchador_timer: float = 0.0

## Walk cycle animation timer (creates leg movement illusion)
var walk_cycle_time: float = 0.0

## Ledge hanging state
enum State { NORMAL, HANGING, CLIMBING }
var current_state: State = State.NORMAL
var ledge_position: Vector2 = Vector2.ZERO
var hang_timer: float = 0.0
const HANG_AUTO_CLIMB_TIME: float = 0.05  # Auto-climb almost immediately
const LEDGE_DETECT_DISTANCE: float = 20.0
const LEDGE_GRAB_HEIGHT: float = 25.0
const CLIMB_HEIGHT: float = 45.0
const CLIMB_DURATION: float = 0.25


# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

## Touch input manager (assigned by GameScene if on touch device).
## Type is set to Variant to avoid loading order issues with class_name.
var touch_input = null  # TouchInputManager assigned at runtime


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Register in the "player" group so enemies and combat systems can find us.
	add_to_group("player")

	# Start with walk texture and correct scale.
	sprite.texture = _tex_walk
	sprite.scale = Vector2(BASE_SCALE, BASE_SCALE)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Handle different states
	if current_state == State.HANGING:
		_update_hanging(delta)
		return  # Skip normal movement when hanging
	elif current_state == State.CLIMBING:
		return  # Climbing is handled by tween, skip physics

	# Normal movement
	_apply_gravity(delta)
	_update_coyote_time(delta)
	_update_jump_buffer(delta)
	_handle_horizontal_movement()
	_handle_jumping()
	_handle_variable_jump_height()
	_handle_attack()
	_update_luchador(delta)
	_apply_touch_momentum()
	_detect_ledge_grab()
	_corner_correction()
	_update_animation()

	move_and_slide()


# =============================================================================
# GRAVITY
# =============================================================================

func _apply_gravity(delta: float) -> void:
	# Don't apply gravity when hanging or climbing
	if current_state != State.NORMAL:
		return

	if not is_on_floor():
		var gravity_mult: float = 1.0

		# Celeste-style apex hang time: when near the peak of a jump and
		# holding jump, apply drastically reduced gravity for satisfying hang time
		var holding_jump: bool = Input.is_action_pressed("jump")
		if touch_input and touch_input.is_touch_device():
			holding_jump = true  # Touch always gets apex benefit

		if velocity.y < 0 and absf(velocity.y) < APEX_VELOCITY_THRESHOLD and holding_jump:
			# At the apex, holding jump -- float!
			gravity_mult = APEX_GRAVITY_MULT
		elif velocity.y > 0:
			# Falling -- snappier descent (asymmetric gravity)
			gravity_mult = FALL_GRAVITY_MULT

		velocity.y += GRAVITY * gravity_mult * delta


# =============================================================================
# CORNER CORRECTION (Celeste-style)
# =============================================================================

func _corner_correction() -> void:
	## When the player bonks their head on a corner while jumping upward,
	## nudge them sideways to slide around it. This prevents frustrating
	## "I clearly made that jump" moments. Checks both left and right offsets.
	if velocity.y >= 0 or is_on_floor():
		return  # Only correct while moving upward

	if not is_on_ceiling():
		return  # No head bonk, nothing to correct

	var space_state := get_world_2d().direct_space_state

	# Try nudging left and right to find an open space above
	for nudge_dir in [-1.0, 1.0]:
		var test_pos := global_position + Vector2(nudge_dir * CORNER_CORRECTION_PIXELS, -2.0)
		var query := PhysicsRayQueryParameters2D.create(
			test_pos, test_pos + Vector2(0, -4.0)
		)
		query.collision_mask = 1 | 2
		query.exclude = [self]

		var result := space_state.intersect_ray(query)
		if not result:
			# Open space found! Nudge the player there
			global_position.x += nudge_dir * CORNER_CORRECTION_PIXELS
			return  # Don't kill upward velocity -- keep the jump going


# =============================================================================
# COYOTE TIME
# =============================================================================

func _update_coyote_time(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	elif was_on_floor and coyote_timer > 0.0:
		coyote_timer -= delta
	else:
		coyote_timer = 0.0

	was_on_floor = is_on_floor()


# =============================================================================
# JUMP BUFFER
# =============================================================================

func _update_jump_buffer(delta: float) -> void:
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	var using_touch: bool = touch_input != null and touch_input.is_touch_device()
	var jump_pressed: bool

	if using_touch:
		jump_pressed = touch_input.jump
	else:
		jump_pressed = Input.is_action_just_pressed("jump")

	if jump_pressed:
		jump_buffer_timer = JUMP_BUFFER_TIME


# =============================================================================
# HORIZONTAL MOVEMENT
# =============================================================================

func _handle_horizontal_movement() -> void:
	# Check if using touch controls
	var using_touch: bool = touch_input != null and touch_input.is_touch_device()

	if using_touch:
		# Touch-based movement with momentum
		var input_dir: float = touch_input.get_horizontal_input()
		var is_running: bool = touch_input.run
		var speed: float = RUN_SPEED if is_running else WALK_SPEED

		# Luchador speed boost
		if luchador_active:
			speed *= LUCHADOR_SPEED_MULT

		if input_dir < 0.0:
			velocity.x = -speed
			facing_right = false
			sprite.flip_h = true
		elif input_dir > 0.0:
			velocity.x = speed
			facing_right = true
			sprite.flip_h = false
		else:
			# Gradual deceleration when no touch input
			velocity.x *= DECELERATION
			if absf(velocity.x) < MIN_VELOCITY_THRESHOLD:
				velocity.x = 0.0
	else:
		# Keyboard/gamepad movement with acceleration-based lerp
		var is_running: bool = Input.is_action_pressed("run")
		var speed: float = RUN_SPEED if is_running else WALK_SPEED

		# Luchador speed boost
		if luchador_active:
			speed *= LUCHADOR_SPEED_MULT

		# Acceleration is faster on the ground, floatier in air (better air control feel)
		var accel_weight: float = 0.25 if is_on_floor() else 0.15

		if Input.is_action_pressed("move_left"):
			velocity.x = lerpf(velocity.x, -speed, accel_weight)
			facing_right = false
			sprite.flip_h = true
		elif Input.is_action_pressed("move_right"):
			velocity.x = lerpf(velocity.x, speed, accel_weight)
			facing_right = true
			sprite.flip_h = false
		else:
			# Gradual deceleration -- faster on ground, slidier in air
			var decel_weight: float = 0.2 if is_on_floor() else 0.1
			velocity.x = lerpf(velocity.x, 0.0, decel_weight)
			if absf(velocity.x) < MIN_VELOCITY_THRESHOLD:
				velocity.x = 0.0


# =============================================================================
# JUMPING
# =============================================================================

func _handle_jumping() -> void:
	# Check if using touch controls
	var using_touch: bool = touch_input != null and touch_input.is_touch_device()

	var jump_just_pressed: bool
	if using_touch:
		jump_just_pressed = touch_input.jump
	else:
		jump_just_pressed = Input.is_action_just_pressed("jump")

	var can_normal_jump: bool = is_on_floor() or coyote_timer > 0.0
	var current_time: float = Time.get_ticks_msec() / 1000.0

	if jump_just_pressed or jump_buffer_timer > 0.0:
		# Check for double-tap (super jump)
		var is_double_tap: bool = false
		if not using_touch and jump_just_pressed:
			var time_since_last_jump: float = current_time - last_jump_time
			if time_since_last_jump < DOUBLE_TAP_WINDOW and not is_on_floor():
				is_double_tap = true
			last_jump_time = current_time

		if is_double_tap and GameState.super_jumps > 0:
			# --- Super jump (double-tap) ---
			GameState.super_jumps -= 1
			velocity.y = SUPER_JUMP_VELOCITY
			jump_buffer_timer = 0.0
			AudioManager.play_sfx("jump_super")
			Events.super_jump_used.emit()
			_show_super_jump_effect()

		elif can_normal_jump:
			# --- Normal ground jump ---
			var jump_vel: float = JUMP_VELOCITY
			if luchador_active:
				jump_vel *= LUCHADOR_JUMP_MULT
			velocity.y = jump_vel
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
			AudioManager.play_sfx("jump")

			# Apply horizontal velocity from touch swipe
			if using_touch and absf(touch_input.swipe_velocity_x) > 30.0:
				velocity.x += touch_input.swipe_velocity_x * 0.5  # 50% of swipe power


## Variable-height jump: releasing jump early halves upward velocity, giving
## the player fine-grained control over arc height.
func _handle_variable_jump_height() -> void:
	var using_touch: bool = touch_input != null and touch_input.is_touch_device()

	# Touch: no variable jump (one-tap for fixed height)
	# Keyboard: release early to cut jump short
	if not using_touch:
		if Input.is_action_just_released("jump") and velocity.y < 0.0:
			velocity.y *= 0.5


# =============================================================================
# ATTACK
# =============================================================================

func _handle_attack() -> void:
	var using_touch: bool = touch_input != null and touch_input.is_touch_device()

	var attack_pressed: bool
	if using_touch:
		attack_pressed = touch_input.attack
	else:
		attack_pressed = Input.is_action_just_pressed("attack")

	if attack_pressed and not is_attacking:
		_start_attack()


func _start_attack() -> void:
	is_attacking = true
	AudioManager.play_sfx("stomp")

	# Melee hitbox -- 70 px in front of the player's center.
	var attack_dir: int = 1 if facing_right else -1
	var attack_pos: Vector2 = global_position + Vector2(attack_dir * ATTACK_RANGE, 0.0)

	# Emit attack signal for GameScene to handle collision checks.
	Events.player_attacked.emit(attack_pos, attack_dir)

	# Thunderbolt projectile if the player has mace-attack charges.
	if GameState.mace_attacks > 0:
		GameState.mace_attacks -= 1
		Events.thunderbolt_fired.emit(global_position, attack_dir)

	# Hold the attack pose, then release.
	await get_tree().create_timer(ATTACK_DURATION).timeout
	is_attacking = false


# =============================================================================
# SUPER JUMP EFFECT
# =============================================================================

func _show_super_jump_effect() -> void:
	# Visual feedback (cyan burst particles) is handled by the GameScene
	# listening to Events.super_jump_used. This function is a hook for any
	# player-local effects we want to add later (screen shake, squash, etc.).
	pass


# =============================================================================
# ANIMATION + BOBBING (DKC-style, from original lines 6947-6997)
# =============================================================================

func _update_animation() -> void:
	var using_touch: bool = touch_input != null and touch_input.is_touch_device()
	var is_moving: bool = absf(velocity.x) > MIN_VELOCITY_THRESHOLD
	var is_in_air: bool = not is_on_floor()
	var is_running: bool
	if using_touch:
		is_running = touch_input.run
	else:
		is_running = Input.is_action_pressed("run")
	var time_ms: float = float(Time.get_ticks_msec())

	# --- Texture + bobbing per state ---
	if is_attacking:
		# Attack: stable pose, no bob, no tilt.
		sprite.texture = _tex_attack
		sprite.scale = Vector2(BASE_SCALE, BASE_SCALE)
		sprite.rotation = 0.0
		sprite.offset.y = 0.0

	elif is_in_air:
		# Jump / fall: clean pose, no bob, no tilt.
		sprite.texture = _tex_jump
		sprite.scale = Vector2(BASE_SCALE, BASE_SCALE)
		sprite.rotation = 0.0
		sprite.offset.y = 0.0

	elif is_moving and is_running:
		# Running: fast bob with aggressive tilt + faster bounce
		sprite.texture = _tex_run
		var run_sin: float = sin(time_ms * 0.025)
		var bob_scale: float = BASE_SCALE + run_sin * 0.008
		var tilt: float = sin(time_ms * 0.025) * 0.08
		sprite.scale = Vector2(bob_scale, bob_scale)
		sprite.rotation = tilt
		# Faster bounce for running
		sprite.offset.y = sin(time_ms * 0.05) * 3.0  # Bigger, faster bounce

	elif is_moving:
		# Walking: gentle bob with subtle tilt + vertical bounce for leg illusion
		sprite.texture = _tex_walk
		var walk_sin: float = sin(time_ms * 0.015)
		var bob_scale: float = BASE_SCALE + walk_sin * 0.006
		var tilt: float = sin(time_ms * 0.015) * 0.05
		sprite.scale = Vector2(bob_scale, bob_scale)
		sprite.rotation = tilt
		# Add vertical bounce to simulate walking steps
		sprite.offset.y = sin(time_ms * 0.03) * 2.0  # Small bounce

	else:
		# Idle: slow breathing animation on scale.
		sprite.texture = _tex_walk
		var breathe: float = sin(time_ms * 0.003) * 0.004
		sprite.scale = Vector2(BASE_SCALE + breathe, BASE_SCALE + breathe)
		sprite.rotation = 0.0
		sprite.offset.y = 0.0

	# --- Color modulation ---
	if luchador_active:
		# Luchador mask: blue tint.
		sprite.modulate = Color(0.5, 0.5, 1.0, 1.0)
	elif is_invincible:
		# Post-hit invincibility: rapid alpha flash.
		sprite.modulate.a = 0.5 + sin(time_ms * 0.02) * 0.5
	else:
		sprite.modulate = Color.WHITE


# =============================================================================
# TOUCH MOMENTUM
# =============================================================================

func _apply_touch_momentum() -> void:
	## Apply momentum from touch swipes (decays with friction).
	if touch_input == null or not touch_input.is_touch_device():
		return

	var momentum: float = touch_input.get_momentum()
	if absf(momentum) > MIN_VELOCITY_THRESHOLD:
		# Add momentum to current velocity (doesn't replace, adds to it)
		velocity.x += momentum * 0.1  # 10% of momentum per frame


# =============================================================================
# LUCHADOR POWER-UP
# =============================================================================

func _update_luchador(delta: float) -> void:
	if not luchador_active:
		return
	luchador_timer -= delta
	if luchador_timer <= 0.0:
		_end_luchador()


## Activate the luchador mask power-up for [param duration] seconds.
## Grants a speed boost, jump boost, and invulnerability to contact damage.
func activate_luchador(duration: float = 15.0) -> void:
	luchador_active = true
	luchador_timer = duration
	Events.luchador_activated.emit()


func _end_luchador() -> void:
	luchador_active = false
	luchador_timer = 0.0
	sprite.modulate = Color.WHITE
	Events.luchador_ended.emit()


# =============================================================================
# LEDGE HANGING & AUTO-CLIMB
# =============================================================================

## Detect if the player is near a ledge they can grab onto.
## Requires holding toward the wall (matching the controls tip).
## Uses a downward raycast ahead of the player to find platform edges.
func _detect_ledge_grab() -> void:
	# Only detect when in air and not already hanging
	if is_on_floor() or current_state != State.NORMAL:
		return

	# Allow grab while falling at moderate speed (not terminal velocity)
	if velocity.y > 300:
		return

	# Must be pressing toward the ledge direction
	var h_input: float = Input.get_axis("move_left", "move_right")
	if touch_input and touch_input.is_touch_device():
		h_input = touch_input.direction
	var pressing_toward: bool = (facing_right and h_input > 0.1) or (not facing_right and h_input < -0.1)
	if not pressing_toward:
		return

	var direction: float = 1.0 if facing_right else -1.0

	# Cast downward from a point ahead of and above the player to find platform surface
	var check_ahead: float = 28.0  # Distance ahead to check
	var check_above: float = -20.0  # Start above player center
	var check_down: float = 50.0   # How far down to look

	var ray_origin := global_position + Vector2(direction * check_ahead, check_above)
	var ray_end := ray_origin + Vector2(0, check_down)

	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(ray_origin, ray_end)
	query.collision_mask = 1 | 2  # Layer 1 (World) + Layer 2 (Platforms/Trajineras)
	query.exclude = [self]

	var result := space_state.intersect_ray(query)

	if result and result.has("position"):
		var platform_top_y: float = result.position.y
		var player_y: float = global_position.y

		# Grab if platform top is near player center (wider window for reliability)
		if platform_top_y > player_y - 35 and platform_top_y < player_y + 20:
			_enter_hanging_state(result.position)


## Enter the hanging state - snap to ledge position and stop movement.
func _enter_hanging_state(ledge_pos: Vector2) -> void:
	current_state = State.HANGING
	ledge_position = ledge_pos
	hang_timer = 0.0

	# Snap to ledge - align hands with ledge edge
	var offset_x: float = 18.0 if facing_right else -18.0
	global_position.x = ledge_pos.x - offset_x
	global_position.y = ledge_pos.y + 15.0

	# Stop all movement
	velocity = Vector2.ZERO


## Update hanging state - wait for auto-climb or manual input.
func _update_hanging(delta: float) -> void:
	hang_timer += delta

	# Keep velocity at zero while hanging
	velocity = Vector2.ZERO

	# Auto-climb after delay OR if jump pressed
	var using_touch: bool = touch_input != null and touch_input.is_touch_device()
	var jump_pressed: bool

	if using_touch:
		jump_pressed = touch_input.jump
	else:
		jump_pressed = Input.is_action_just_pressed("jump")

	if hang_timer > HANG_AUTO_CLIMB_TIME or jump_pressed:
		_enter_climbing_state()
		return

	# Allow dropping by pressing down
	var down_pressed: bool
	if using_touch:
		down_pressed = false  # Touch controls don't have explicit down
	else:
		down_pressed = Input.is_action_pressed("ui_down")

	if down_pressed:
		current_state = State.NORMAL
		velocity.y = 100  # Small drop velocity


## Start climbing animation - move up and over the ledge.
func _enter_climbing_state() -> void:
	current_state = State.CLIMBING

	# Target position: above and slightly forward from ledge
	var forward_offset: float = 10.0 if facing_right else -10.0
	var target_pos := global_position + Vector2(forward_offset, -CLIMB_HEIGHT)

	# Smooth climb animation using tween
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "global_position", target_pos, CLIMB_DURATION)
	tween.tween_callback(_finish_climb)


## Finish the climb - return to normal state.
func _finish_climb() -> void:
	current_state = State.NORMAL
	velocity = Vector2.ZERO


# =============================================================================
# DAMAGE + DEATH
# =============================================================================

## Called by enemy collision or hazard contact. Ignored during invincibility,
## luchador mode, or if already dead.
func hit(damage: int = 1) -> void:
	if is_invincible or is_dead or luchador_active:
		return

	GameState.lives -= damage
	Events.player_hit.emit()

	if GameState.lives <= 0:
		die()
	else:
		# Brief upward knockback + invincibility frames.
		is_invincible = true
		velocity.y = HIT_KNOCKBACK_Y
		AudioManager.play_sfx("hurt")

		# Invincibility lasts INVINCIBILITY_DURATION seconds.
		await get_tree().create_timer(INVINCIBILITY_DURATION).timeout
		is_invincible = false
		sprite.modulate = Color.WHITE


## Kill the player. Freezes input, zeroes velocity, emits player_died.
func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	AudioManager.play_sfx("hurt")
	Events.player_died.emit()


# =============================================================================
# COLLECTIBLE POWER-UPS (called by collectible nodes on pickup)
# =============================================================================

## Elote (corn) shield: grants invincibility with a golden glow.
func activate_elote_invincibility(duration: float = 10.0) -> void:
	is_invincible = true
	# Golden glow while shielded.
	sprite.modulate = Color(1.0, 0.84, 0.0, 1.0)

	await get_tree().create_timer(duration).timeout
	is_invincible = false
	sprite.modulate = Color.WHITE


# =============================================================================
# ENEMY INTERACTION
# =============================================================================

## Bounce upward after successfully stomping an enemy. Called by the enemy or
## the GameScene's stomp-detection logic.
func stomp_bounce() -> void:
	velocity.y = STOMP_BOUNCE_VELOCITY

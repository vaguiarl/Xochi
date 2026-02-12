extends EnemyBase
class_name Crowquistador
## Crowquistador enemy -- armored crow conquistador with Sword Knight personality!
##
## A Kirby Sword Knight-inspired flying swordsman. Rather than mindlessly
## patrolling and shooting projectiles, this enemy reads the player's
## position and chooses from a repertoire of melee sword attacks:
##
##   PATROL      - Lazy flight, sword at rest, scanning for the player.
##   ALERT       - Spots the player! Puffs up, raises sword, picks attack.
##   DIVE_SLASH  - Swoops diagonally at the player with sword extended.
##   SWORD_SPIN  - Close-range 720-degree whirlwind slash.
##   RETREAT     - Flies back to patrol altitude, cooldown before next pass.
##   PARRY       - Reflexive upward sword thrust that blocks stomps!
##
## Skeletal parts:
##   - head (helmet with plume)
##   - body (breastplate armor)
##   - wings (4 sprites: up_left, up_right, down_left, down_right)
##   - tail, legs, sword
##
## No projectiles. The sword IS the weapon.


# =============================================================================
# PRELOADED BODY PARTS
# =============================================================================

var PART_HEAD: Texture2D = null
var PART_BODY: Texture2D = null
var PART_WING_UP_LEFT: Texture2D = null
var PART_WING_UP_RIGHT: Texture2D = null
var PART_WING_DOWN_LEFT: Texture2D = null
var PART_WING_DOWN_RIGHT: Texture2D = null
var PART_TAIL: Texture2D = null
var PART_LEG_LEFT: Texture2D = null
var PART_LEG_RIGHT: Texture2D = null
var PART_SWORD: Texture2D = null

func _load_parts() -> void:
	if PART_HEAD != null:
		return
	PART_HEAD = load("res://assets/sprites/prerendered/enemies/crowquistador_parts/head.png")
	PART_BODY = load("res://assets/sprites/prerendered/enemies/crowquistador_parts/body.png")
	PART_WING_UP_LEFT = load("res://assets/sprites/prerendered/enemies/crowquistador_parts/left_wing_up.png")
	PART_WING_UP_RIGHT = load("res://assets/sprites/prerendered/enemies/crowquistador_parts/right_wing_up.png")
	PART_WING_DOWN_LEFT = load("res://assets/sprites/prerendered/enemies/crowquistador_parts/left_wing_down.png")
	PART_WING_DOWN_RIGHT = load("res://assets/sprites/prerendered/enemies/crowquistador_parts/right_wing_down.png")
	PART_TAIL = load("res://assets/sprites/prerendered/enemies/crowquistador_parts/tail.png")
	PART_LEG_LEFT = load("res://assets/sprites/prerendered/enemies/crowquistador_parts/leg_left.png")
	PART_LEG_RIGHT = load("res://assets/sprites/prerendered/enemies/crowquistador_parts/leg_right.png")
	PART_SWORD = load("res://assets/sprites/prerendered/enemies/crowquistador_parts/sword.png")


# =============================================================================
# AI STATE MACHINE
# =============================================================================

enum State {
	PATROL,
	ALERT,
	DIVE_SLASH,
	SWORD_SPIN,
	RETREAT,
	PARRY,
}

## Current AI state
var state: int = State.PATROL

## Accumulated time in the current state (resets on state transition)
var state_timer: float = 0.0

## General-purpose animation clock (never resets, drives wing flaps and idle sway)
var anim_time: float = 0.0

## Cooldown after RETREAT before re-engaging (seconds)
var cooldown_timer: float = 0.0


# =============================================================================
# TUNING CONSTANTS
# =============================================================================

## Player detection range -- triggers ALERT
const DETECT_RANGE: float = 250.0

## Close range -- triggers SWORD_SPIN instead of DIVE_SLASH
const SPIN_RANGE: float = 80.0

## Parry window -- player must be this close horizontally and above
const PARRY_DX: float = 35.0
const PARRY_DY_MIN: float = 10.0
const PARRY_DY_MAX: float = 60.0

## Dive attack speed (px/s)
const DIVE_SPEED: float = 200.0

## Retreat climb speed (px/s)
const RETREAT_SPEED: float = 100.0

## Patrol horizontal speed (px/s, overridden by setup data)
const DEFAULT_PATROL_SPEED: float = 80.0

## Alert hold time before attacking (seconds)
const ALERT_DURATION: float = 0.6

## Sword spin duration (seconds)
const SPIN_DURATION: float = 0.5

## Parry hold time (seconds)
const PARRY_DURATION: float = 0.3

## Post-retreat cooldown before returning to patrol (seconds)
const RETREAT_COOLDOWN: float = 1.5

## Sword spin damage radius (px)
const SPIN_DAMAGE_RADIUS: float = 40.0

## Dive slash damage radius -- handled by EnemyBase collision, but we also
## check this for the body_entered-style hit during the dive
const DIVE_DAMAGE_RADIUS: float = 22.0

## Afterimage trail: how many ghosts to spawn during DIVE_SLASH
const AFTERIMAGE_INTERVAL: float = 0.08


# =============================================================================
# MOVEMENT STATE
# =============================================================================

## The Y position around which the crowquistador oscillates during PATROL
var base_y: float = 0.0

## Vertical oscillation amplitude in pixels (default 40)
var amplitude: float = 40.0

## True when flapping upward, false when descending (patrol only)
var flap_up: bool = true

## Width of the level for boundary-reversal logic
var level_width: float = 2000.0

## Wing flap animation timer (separate from anim_time for variable speed)
var wing_flap_time: float = 0.0

## Direction vector for DIVE_SLASH (normalized, set when dive begins)
var dive_direction: Vector2 = Vector2.ZERO

## Timer for spawning afterimage ghosts during dive
var afterimage_timer: float = 0.0

## Sword spin accumulated rotation (resets each SWORD_SPIN entry)
var spin_rotation: float = 0.0

## Cached reference to the player (refreshed each frame)
var _player_ref: Node = null

## Sword rest position in rig-local coords (set during rig build)
var sword_rest_pos: Vector2 = Vector2(120, 200)
var sword_rest_rot: float = 0.3


# =============================================================================
# SKELETAL RIG NODES
# =============================================================================

var rig: Node2D
var sprite_head: Sprite2D
var sprite_body: Sprite2D
var sprite_wing_left: Sprite2D
var sprite_wing_right: Sprite2D
var sprite_tail: Sprite2D
var sprite_leg_left: Sprite2D
var sprite_leg_right: Sprite2D
var sprite_sword: Sprite2D


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready():
	super._ready()
	# Flying enemies ignore gravity
	gravity = 0.0
	_load_parts()
	_build_skeletal_rig()


## Build the skeletal animation rig from pre-rendered body parts
func _build_skeletal_rig():
	# Root node for the entire rig (allows flipping)
	rig = Node2D.new()
	rig.name = "Rig"
	add_child(rig)

	# Scale to fit game proportions
	var rig_scale: float = 0.05  # Half size for better gameplay proportion
	rig.scale = Vector2(rig_scale, rig_scale)

	# Build anatomically correct crow: head -> body -> wings -> tail behind, legs below

	# --- Tail (extends backward from body, behind everything) ---
	sprite_tail = Sprite2D.new()
	sprite_tail.name = "Tail"
	sprite_tail.texture = PART_TAIL
	sprite_tail.centered = true
	sprite_tail.position = Vector2(-180, 80)  # Behind and slightly down
	sprite_tail.rotation = -0.2  # Angle backward
	sprite_tail.z_index = -10
	rig.add_child(sprite_tail)

	# --- Wings (on sides of body, clearly visible) ---
	sprite_wing_left = Sprite2D.new()
	sprite_wing_left.name = "WingLeft"
	sprite_wing_left.texture = PART_WING_DOWN_LEFT
	sprite_wing_left.centered = true
	sprite_wing_left.position = Vector2(-180, -20)  # Further left, slightly up
	sprite_wing_left.z_index = -5
	sprite_wing_left.visible = true  # Ensure visible
	rig.add_child(sprite_wing_left)

	sprite_wing_right = Sprite2D.new()
	sprite_wing_right.name = "WingRight"
	sprite_wing_right.texture = PART_WING_DOWN_RIGHT
	sprite_wing_right.centered = true
	sprite_wing_right.position = Vector2(180, -20)  # Further right, slightly up
	sprite_wing_right.z_index = -5
	sprite_wing_right.visible = true  # Ensure visible
	rig.add_child(sprite_wing_right)

	# --- Body (center of crow) ---
	sprite_body = Sprite2D.new()
	sprite_body.name = "Body"
	sprite_body.texture = PART_BODY
	sprite_body.centered = true
	sprite_body.position = Vector2(0, 0)  # Center reference point
	sprite_body.z_index = 0
	rig.add_child(sprite_body)

	# --- Head (above body with helmet) ---
	sprite_head = Sprite2D.new()
	sprite_head.name = "Head"
	sprite_head.texture = PART_HEAD
	sprite_head.centered = true
	sprite_head.position = Vector2(0, -140)  # Above body
	sprite_head.z_index = 5
	rig.add_child(sprite_head)

	# --- Legs (hanging down below body for catching prey) ---
	sprite_leg_left = Sprite2D.new()
	sprite_leg_left.name = "LegLeft"
	sprite_leg_left.texture = PART_LEG_LEFT
	sprite_leg_left.centered = true
	sprite_leg_left.position = Vector2(-40, 250)  # Below body, spread apart
	sprite_leg_left.z_index = 10
	rig.add_child(sprite_leg_left)

	sprite_leg_right = Sprite2D.new()
	sprite_leg_right.name = "LegRight"
	sprite_leg_right.texture = PART_LEG_RIGHT
	sprite_leg_right.centered = true
	sprite_leg_right.position = Vector2(40, 250)  # Below body, spread apart
	sprite_leg_right.z_index = 10
	rig.add_child(sprite_leg_right)

	# --- Sword (held in claw/leg, front layer) ---
	sprite_sword = Sprite2D.new()
	sprite_sword.name = "Sword"
	sprite_sword.texture = PART_SWORD
	sprite_sword.centered = true
	sprite_sword.position = Vector2(120, 200)  # Near right leg area
	sprite_sword.rotation = 0.3  # Slight angle
	sprite_sword.z_index = 15
	rig.add_child(sprite_sword)

	# --- Collision shape ---
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(18, 22)  # Half size collision to match smaller rig
	collision.shape = shape
	add_child(collision)


# =============================================================================
# CONFIGURATION
# =============================================================================

## Configure this crowquistador from spawn data.
## Accepted keys:
##   "dir"         - initial direction: 1 (right) or -1 (left)
##   "speed"       - horizontal patrol speed (default 80)
##   "y"           - base Y position for flap oscillation
##   "amplitude"   - vertical oscillation range (default 40)
##   "level_width" - level width for boundary checks (default 2000)
func setup(data: Dictionary):
	enemy_type = "flying"
	dir = data.get("dir", 1)
	speed = data.get("speed", DEFAULT_PATROL_SPEED)
	base_y = data.get("y", position.y)
	amplitude = data.get("amplitude", 40.0)
	level_width = data.get("level_width", 2000.0)
	state = State.PATROL
	state_timer = 0.0
	cooldown_timer = 0.0


# =============================================================================
# STATE TRANSITIONS
# =============================================================================

## Clean transition between AI states. Resets the state timer and performs
## any one-time setup needed for the new state.
func _change_state(new_state: int) -> void:
	var old_state := state
	state = new_state
	state_timer = 0.0

	match new_state:
		State.ALERT:
			# Stop horizontal movement immediately
			velocity.x = 0.0
			velocity.y = 0.0

		State.DIVE_SLASH:
			# Calculate dive direction toward current player position
			var player := _find_player()
			if player:
				dive_direction = (player.global_position - global_position).normalized()
			else:
				# No player found -- just dive forward
				dive_direction = Vector2(dir, 0.5).normalized()
			afterimage_timer = 0.0

		State.SWORD_SPIN:
			# Reset spin rotation accumulator
			spin_rotation = 0.0
			velocity.x = 0.0
			velocity.y = 0.0

		State.RETREAT:
			# Begin climbing back to base altitude
			cooldown_timer = RETREAT_COOLDOWN
			velocity.x = 0.0

		State.PARRY:
			# Freeze in place with sword up
			velocity.x = 0.0
			velocity.y = 0.0

		State.PATROL:
			# Restore patrol speed
			pass


# =============================================================================
# PHYSICS & AI
# =============================================================================

func _physics_process(delta: float) -> void:
	if not alive:
		return

	# Cache player reference for this frame
	_player_ref = _find_player()

	# Advance animation clock (never resets)
	anim_time += delta
	state_timer += delta

	# --- Check for PARRY opportunity every frame (highest priority) ---
	# Only from states where the crowquistador can react
	if state == State.PATROL or state == State.ALERT or state == State.RETREAT:
		if _should_parry():
			_change_state(State.PARRY)

	# --- Run current state logic ---
	match state:
		State.PATROL:
			_process_patrol(delta)
		State.ALERT:
			_process_alert(delta)
		State.DIVE_SLASH:
			_process_dive_slash(delta)
		State.SWORD_SPIN:
			_process_sword_spin(delta)
		State.RETREAT:
			_process_retreat(delta)
		State.PARRY:
			_process_parry(delta)

	# --- Rig direction (always face movement direction) ---
	if rig:
		rig.scale.x = abs(rig.scale.x) * (1 if dir > 0 else -1)

	# --- Animate body parts ---
	_animate_wings(delta)
	_animate_body(delta)
	_animate_head(delta)
	_animate_legs(delta)
	_animate_sword(delta)
	_animate_tail(delta)

	move_and_slide()


# =============================================================================
# STATE: PATROL
# =============================================================================

## Lazy flight back and forth. Sword at rest, head bobbing, scanning for the
## player. This is the "idle" state that gives the crowquistador personality --
## it looks alive even when not attacking.
func _process_patrol(delta: float) -> void:
	# --- Flap up and down ---
	if flap_up:
		velocity.y = -120.0
		if position.y < base_y - amplitude:
			flap_up = false
	else:
		velocity.y = 100.0
		if position.y > base_y + amplitude:
			flap_up = true

	# --- Horizontal patrol ---
	velocity.x = speed * dir

	# --- Boundary reversal (directional check to avoid toggling) ---
	if position.x < 50 and dir < 0:
		dir = 1
		position.x = 50
	elif position.x > level_width - 50 and dir > 0:
		dir = -1
		position.x = level_width - 50

	# --- Detect player ---
	if _player_ref and _player_ref.get("alive") != false:
		var dist := global_position.distance_to(_player_ref.global_position)
		if dist < DETECT_RANGE:
			# Face the player before alerting
			dir = 1 if _player_ref.global_position.x > global_position.x else -1
			_change_state(State.ALERT)


# =============================================================================
# STATE: ALERT
# =============================================================================

## The crowquistador has spotted the player! It freezes, puffs up, raises its
## sword overhead, and holds for ALERT_DURATION before choosing an attack.
## This telegraph gives the player a fair warning -- Sword Knight style.
func _process_alert(delta: float) -> void:
	# Hold position (velocity already zeroed in _change_state)
	velocity.x = 0.0
	velocity.y = 0.0

	# Keep facing the player during alert
	if _player_ref:
		dir = 1 if _player_ref.global_position.x > global_position.x else -1

	# After hold time, choose attack based on distance
	if state_timer >= ALERT_DURATION:
		if _player_ref:
			var dist := global_position.distance_to(_player_ref.global_position)
			if dist < SPIN_RANGE:
				_change_state(State.SWORD_SPIN)
			else:
				_change_state(State.DIVE_SLASH)
		else:
			# Lost the player -- go back to patrol
			_change_state(State.PATROL)


# =============================================================================
# STATE: DIVE_SLASH
# =============================================================================

## The signature move. The crowquistador swoops diagonally toward the player
## at DIVE_SPEED with sword pointed forward. Spawns afterimage ghosts for a
## dramatic trail effect. Transitions to RETREAT when it reaches player level,
## misses, or travels too far.
func _process_dive_slash(delta: float) -> void:
	# Move along the dive direction
	velocity = dive_direction * DIVE_SPEED

	# Update facing direction based on horizontal movement
	if dive_direction.x != 0:
		dir = 1 if dive_direction.x > 0 else -1

	# --- Afterimage trail ---
	afterimage_timer -= delta
	if afterimage_timer <= 0:
		afterimage_timer = AFTERIMAGE_INTERVAL
		_spawn_afterimage()

	# --- Check for player hit during dive ---
	if _player_ref and _player_ref.get("alive") != false:
		var dist := global_position.distance_to(_player_ref.global_position)
		if dist < DIVE_DAMAGE_RADIUS:
			if _player_ref.has_method("hit"):
				_player_ref.hit()
			_change_state(State.RETREAT)
			return

	# --- End conditions ---
	# Reached or passed the player's Y level (dove past them)
	if _player_ref:
		if dive_direction.y > 0 and global_position.y > _player_ref.global_position.y + 30:
			_change_state(State.RETREAT)
			return

	# Dove too long without hitting anything (safety timeout)
	if state_timer > 2.0:
		_change_state(State.RETREAT)
		return

	# Hit the ground or boundaries
	if is_on_floor() or is_on_wall():
		_change_state(State.RETREAT)
		return

	# Boundary safety
	if position.x < 30 or position.x > level_width - 30:
		_change_state(State.RETREAT)


# =============================================================================
# STATE: SWORD_SPIN
# =============================================================================

## Close-range whirlwind attack. The sword spins 720 degrees around the body
## over SPIN_DURATION. The body shakes slightly for impact feel. Damages the
## player if they are within SPIN_DAMAGE_RADIUS during the spin.
func _process_sword_spin(delta: float) -> void:
	# Hold position with slight shake
	velocity.x = 0.0
	velocity.y = 0.0

	# Accumulate spin rotation (720 degrees = TAU * 2)
	spin_rotation += TAU * 4.0 * delta

	# Check for damage on each frame during spin
	if _player_ref and _player_ref.get("alive") != false:
		var dist := global_position.distance_to(_player_ref.global_position)
		if dist < SPIN_DAMAGE_RADIUS:
			if _player_ref.has_method("hit"):
				_player_ref.hit()

	# End spin after duration
	if state_timer >= SPIN_DURATION:
		_change_state(State.RETREAT)


# =============================================================================
# STATE: RETREAT
# =============================================================================

## After attacking, the crowquistador flies back up to its patrol altitude.
## Wings flap hard (fastest animation speed). Once at base_y, holds a cooldown
## before returning to PATROL. This recovery window is the player's best
## opportunity to counterattack.
func _process_retreat(delta: float) -> void:
	# Fly upward toward base altitude
	var y_diff := base_y - position.y
	if abs(y_diff) > 5.0:
		velocity.y = -RETREAT_SPEED if position.y > base_y else RETREAT_SPEED
		# Drift slightly in patrol direction while climbing
		velocity.x = speed * dir * 0.3
	else:
		# Reached patrol altitude -- run cooldown
		velocity.y = 0.0
		velocity.x = 0.0
		position.y = base_y
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			_change_state(State.PATROL)

	# Boundary check even during retreat
	if position.x < 50 and dir < 0:
		dir = 1
		position.x = 50
	elif position.x > level_width - 50 and dir > 0:
		dir = -1
		position.x = level_width - 50


# =============================================================================
# STATE: PARRY
# =============================================================================

## Reflexive defense! When the player is directly above and falling, the
## crowquistador thrusts its sword straight up. This blocks the stomp and
## bounces the player away -- a nasty surprise that teaches players they
## cannot mindlessly jump on this enemy.
func _process_parry(delta: float) -> void:
	velocity.x = 0.0
	velocity.y = 0.0

	# Check if we actually blocked a stomp this frame
	# (The actual bounce is handled in hit_by_stomp override)

	if state_timer >= PARRY_DURATION:
		_change_state(State.RETREAT)


## Determine if a parry should trigger: player directly above, falling down,
## within the narrow parry window.
func _should_parry() -> bool:
	if _player_ref == null:
		return false
	if _player_ref.get("alive") == false:
		return false

	var dx := abs(_player_ref.global_position.x - global_position.x)
	var dy := global_position.y - _player_ref.global_position.y  # positive = player above

	# Player must be above within the vertical window
	if dy < PARRY_DY_MIN or dy > PARRY_DY_MAX:
		return false

	# Player must be horizontally aligned
	if dx > PARRY_DX:
		return false

	# Player must be falling (velocity.y > 0)
	if _player_ref.velocity.y <= 0:
		return false

	return true


# =============================================================================
# STOMP OVERRIDE -- PARRY MECHANIC
# =============================================================================

## Override EnemyBase stomp handling. During PARRY state, the crowquistador
## blocks the stomp and bounces the player away instead of dying.
func hit_by_stomp():
	if not alive:
		return

	if state == State.PARRY:
		# BLOCKED! Bounce the player upward and away
		if _player_ref and _player_ref.has_method("stomp_bounce"):
			_player_ref.stomp_bounce()
		# Flash white briefly to signal the parry
		modulate = Color(2.0, 2.0, 2.0)
		var tween := create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.15)
		# Transition to retreat after parrying
		_change_state(State.RETREAT)
		return

	# Not parrying -- die normally via EnemyBase
	super.hit_by_stomp()


# =============================================================================
# ANIMATION: WINGS
# =============================================================================

## Wing flap speed varies by state to communicate the crowquistador's mood.
## PATROL = relaxed, ALERT = excited, DIVE = tucked, RETREAT = frantic.
func _animate_wings(delta: float) -> void:
	# Variable wing speed based on state
	match state:
		State.PATROL:
			wing_flap_time += delta * 5.0
		State.ALERT:
			wing_flap_time += delta * 8.0
		State.DIVE_SLASH:
			wing_flap_time += delta * 2.0
		State.SWORD_SPIN:
			wing_flap_time += delta * 6.0
		State.RETREAT:
			wing_flap_time += delta * 10.0
		State.PARRY:
			wing_flap_time += delta * 4.0

	var flap_phase := sin(wing_flap_time)

	if sprite_wing_left and sprite_wing_right:
		# Swap textures based on flap phase
		if flap_phase > 0:
			sprite_wing_left.texture = PART_WING_UP_LEFT
			sprite_wing_right.texture = PART_WING_UP_RIGHT
		else:
			sprite_wing_left.texture = PART_WING_DOWN_LEFT
			sprite_wing_right.texture = PART_WING_DOWN_RIGHT

		# Wings move with flapping motion
		var flap_offset := sin(wing_flap_time) * 6
		sprite_wing_left.position.y = -20 + flap_offset
		sprite_wing_right.position.y = -20 + flap_offset

		# Wings spread out more during up-flap
		if flap_phase > 0:
			sprite_wing_left.position.x = -180 - abs(flap_offset) * 2
			sprite_wing_right.position.x = 180 + abs(flap_offset) * 2
		else:
			sprite_wing_left.position.x = -180
			sprite_wing_right.position.x = 180


# =============================================================================
# ANIMATION: BODY
# =============================================================================

## Body bobbing and state-specific reactions. The puff-up during ALERT and
## the shake during SWORD_SPIN sell the personality.
func _animate_body(delta: float) -> void:
	if not sprite_body:
		return

	match state:
		State.PATROL:
			# Gentle bob from flight dynamics
			sprite_body.position.y = sin(wing_flap_time * 1.3) * 3
			sprite_body.scale = Vector2.ONE

		State.ALERT:
			# Puff up! Scale increases to 1.05 over the alert duration
			var puff := minf(state_timer / ALERT_DURATION, 1.0) * 0.05
			sprite_body.scale = Vector2(1.0 + puff, 1.0 + puff)
			sprite_body.position.y = 0.0

		State.DIVE_SLASH:
			# Tilt body in dive direction
			sprite_body.position.y = 0.0
			sprite_body.scale = Vector2.ONE

		State.SWORD_SPIN:
			# Rapid shake during spin for impact feel
			var shake := sin(anim_time * 60.0) * 4.0
			sprite_body.position.x = shake
			sprite_body.position.y = sin(anim_time * 45.0) * 2.0
			sprite_body.scale = Vector2.ONE

		State.RETREAT:
			sprite_body.position.y = sin(wing_flap_time * 1.3) * 3
			sprite_body.scale = Vector2.ONE
			sprite_body.position.x = 0.0

		State.PARRY:
			sprite_body.position.y = 0.0
			sprite_body.scale = Vector2.ONE
			sprite_body.position.x = 0.0


# =============================================================================
# ANIMATION: HEAD
# =============================================================================

## Head animation. Bobs during patrol, tilts toward player during alert,
## follows dive direction during attack.
func _animate_head(delta: float) -> void:
	if not sprite_head:
		return

	match state:
		State.PATROL:
			# Gentle bob
			sprite_head.position.y = -140 + sin(wing_flap_time * 0.8) * 4
			sprite_head.rotation = 0.0

		State.ALERT:
			# Tilt toward player (the "I see you" look)
			sprite_head.position.y = -140
			var tilt_dir := 1.0 if _player_ref and _player_ref.global_position.x > global_position.x else -1.0
			# Account for rig flip: when dir is -1, rig.scale.x is negative,
			# so we need to invert the tilt to keep it looking correct
			if dir < 0:
				tilt_dir *= -1.0
			sprite_head.rotation = tilt_dir * 0.15

		State.DIVE_SLASH:
			# Head follows dive angle
			sprite_head.position.y = -140
			sprite_head.rotation = dive_direction.angle() * 0.3

		State.SWORD_SPIN:
			# Slight duck during spin
			sprite_head.position.y = -130
			sprite_head.rotation = 0.0

		State.RETREAT, State.PARRY:
			sprite_head.position.y = -140
			sprite_head.rotation = 0.0


# =============================================================================
# ANIMATION: LEGS
# =============================================================================

## Legs dangle naturally and tuck during dives.
func _animate_legs(delta: float) -> void:
	if not sprite_leg_left or not sprite_leg_right:
		return

	match state:
		State.DIVE_SLASH:
			# Tuck legs back during dive
			sprite_leg_left.rotation = 0.3
			sprite_leg_right.rotation = 0.3
			sprite_leg_left.position.y = 240
			sprite_leg_right.position.y = 240

		State.SWORD_SPIN:
			# Legs splay outward from centrifugal force
			sprite_leg_left.rotation = -0.2
			sprite_leg_right.rotation = 0.2
			var spin_offset := sin(spin_rotation * 2.0) * 5
			sprite_leg_left.position.y = 255 + spin_offset
			sprite_leg_right.position.y = 255 - spin_offset

		_:
			# Default dangle
			sprite_leg_left.rotation = sin(wing_flap_time * 0.7) * 0.1
			sprite_leg_right.rotation = sin(wing_flap_time * 0.7 + 0.5) * 0.1
			var leg_bob := sin(wing_flap_time * 1.3) * 2
			sprite_leg_left.position.y = 250 + leg_bob
			sprite_leg_right.position.y = 250 + leg_bob


# =============================================================================
# ANIMATION: SWORD
# =============================================================================

## The sword is the star of the show. Each state has a distinct sword pose
## that telegraphs the crowquistador's intent to observant players.
func _animate_sword(delta: float) -> void:
	if not sprite_sword:
		return

	match state:
		State.PATROL:
			# Gentle sway at rest -- the idle "I have a sword" pose
			sprite_sword.rotation = 0.3 + sin(anim_time * 0.6) * 0.12
			sprite_sword.position = sword_rest_pos

		State.ALERT:
			# Raise sword overhead! Tween-like interpolation over alert duration
			var t := clampf(state_timer / (ALERT_DURATION * 0.5), 0.0, 1.0)
			sprite_sword.rotation = lerpf(0.3, -1.2, t)
			sprite_sword.position.x = lerpf(sword_rest_pos.x, 40, t)
			sprite_sword.position.y = lerpf(sword_rest_pos.y, -100, t)

		State.DIVE_SLASH:
			# Sword points forward-down in the dive direction
			sprite_sword.rotation = -0.8
			sprite_sword.position = Vector2(160, 80)  # Extended forward

		State.SWORD_SPIN:
			# Full speed rotation around the body!
			sprite_sword.rotation = spin_rotation
			# Orbit the sword around body center
			var orbit_radius: float = 180.0
			sprite_sword.position.x = cos(spin_rotation) * orbit_radius
			sprite_sword.position.y = sin(spin_rotation) * orbit_radius

		State.RETREAT:
			# Return sword to rest position smoothly
			var t := clampf(state_timer / 0.4, 0.0, 1.0)
			sprite_sword.rotation = lerpf(sprite_sword.rotation, 0.3, t * 0.1)
			sprite_sword.position.x = lerpf(sprite_sword.position.x, sword_rest_pos.x, t * 0.1)
			sprite_sword.position.y = lerpf(sprite_sword.position.y, sword_rest_pos.y, t * 0.1)

		State.PARRY:
			# Sword straight up! The "not today" pose
			sprite_sword.rotation = -PI / 2.0
			sprite_sword.position = Vector2(0, -160)


# =============================================================================
# ANIMATION: TAIL
# =============================================================================

## Tail sways in the wind during patrol, streams behind during dives.
func _animate_tail(delta: float) -> void:
	if not sprite_tail:
		return

	match state:
		State.DIVE_SLASH:
			# Tail streams behind (opposite of dive direction)
			sprite_tail.rotation = -dive_direction.angle() * 0.5
		_:
			# Gentle wind sway
			sprite_tail.rotation = -0.2 + sin(anim_time * 0.5) * 0.08


# =============================================================================
# VISUAL EFFECTS
# =============================================================================

## Spawn a translucent afterimage ghost at the current position.
## Used during DIVE_SLASH to create a dramatic motion trail.
func _spawn_afterimage() -> void:
	if not rig:
		return

	# Create a snapshot of the current rig as a fading ghost
	var ghost := Sprite2D.new()
	# Use the body texture as the ghost silhouette (full rig snapshot is too expensive)
	ghost.texture = PART_BODY
	ghost.global_position = global_position
	ghost.scale = rig.scale
	ghost.modulate = Color(0.6, 0.4, 1.0, 0.5)  # Purple-tinted, semi-transparent
	ghost.z_index = -1

	get_tree().current_scene.add_child(ghost)

	# Fade out and destroy
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost.queue_free)


# =============================================================================
# UTILITY
# =============================================================================

## Find the player node via group lookup.
func _find_player() -> Node:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

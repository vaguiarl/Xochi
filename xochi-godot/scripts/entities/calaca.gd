extends CharacterBody2D
## Calaca -- Dia de los Muertos sugar skull with mischievous personality.
##
## A colorful sugar calavera wearing a sombrero. FLYING enemy that bobs
## vertically around its spawn height. Unlike dumb patrollers, the Calaca
## has real personality: it spots the player, taunts with excited bobbing,
## swoops down to attack, then lazily retreats to altitude. It also
## dodges upward when the player attempts a stomp from above.
##
## Behavior states:
##   PATROL  - Default horizontal patrol with dreamy sin bob
##   NOTICE  - Spots the player, pauses briefly, bobs excitedly
##   SWOOP   - Dives toward the player's last-seen position
##   RETREAT - Floats back to patrol altitude after a swoop
##   DODGE   - Quick upward dodge when player is directly above
##
## Dies in one stomp or one attack. Contact damage on touch.
## Uses InertialDeformer for volume-preserving squash/stretch/skew.
##
## This enemy does NOT extend EnemyBase. Loaded dynamically by EnemySpawner
## to prevent cascade failures.
##
## Collision setup:
##   Layer 8 (Enemies)
##   Mask 1 | 2 (World + Platforms)


# =============================================================================
# CONSTANTS
# =============================================================================

## Default horizontal patrol speed in px/s.
const DEFAULT_SPEED: float = 60.0

## Swoop dive speed (faster than patrol).
const SWOOP_SPEED: float = 180.0

## Retreat (return to altitude) speed.
const RETREAT_SPEED: float = 80.0

## Dodge upward speed (quick escape from stomp threat).
const DODGE_SPEED: float = 250.0

## How far the calaca can "see" the player (px).
const DETECTION_RANGE: float = 200.0

## How close directly above the player must be to trigger dodge (px horizontal).
const STOMP_DANGER_X: float = 40.0

## How far above the calaca the player must be to trigger dodge (px).
const STOMP_DANGER_Y: float = 80.0

## How long the "notice" taunt lasts before swooping (seconds).
const NOTICE_DURATION: float = 0.5

## How far the dodge carries upward (px).
const DODGE_DISTANCE: float = 60.0

## Cooldown after a swoop before it can notice the player again (seconds).
const SWOOP_COOLDOWN: float = 1.5

## Boundary margin -- reverse direction at level edges (px).
const EDGE_MARGIN: float = 50.0

## Score awarded on kill.
const KILL_SCORE: int = 75

## Duration of the death spin animation (seconds).
const DEATH_DURATION: float = 0.5

## Target height in pixels for the sprite (source is ~805px).
const TARGET_HEIGHT: float = 45.0

## Default vertical bob amplitude in pixels.
const DEFAULT_BOB_AMPLITUDE: float = 30.0

## Vertical bob frequency multiplier (radians per second).
const BOB_FREQUENCY: float = 2.5

## Notice taunt bob speed (faster, excited).
const TAUNT_BOB_SPEED: float = 12.0

## Notice taunt bob amplitude (more aggressive).
const TAUNT_BOB_AMPLITUDE: float = 8.0


# =============================================================================
# STATE
# =============================================================================

enum State { PATROL, NOTICE, SWOOP, RETREAT, DODGE }

## Whether this enemy is alive and can interact with the world.
var alive: bool = true

## Current behavior state.
var _state: State = State.PATROL

## Current movement direction: 1 = right, -1 = left.
var dir: int = 1

## Horizontal movement speed in px/s.
var speed: float = DEFAULT_SPEED

## Width of the current level (for boundary reversal).
var level_width: float = 3000.0

## Base Y position (center of vertical oscillation).
var base_y: float = 0.0

## Accumulated bob time for sin() wave.
var bob_time: float = 0.0

## Peak-to-peak vertical bob distance (half-swing) in pixels.
var bob_amplitude: float = DEFAULT_BOB_AMPLITUDE

## Timer for state durations (notice taunt, cooldown, etc.).
var _state_timer: float = 0.0

## Cooldown timer after swooping.
var _cooldown_timer: float = 0.0

## Target position for the swoop dive.
var _swoop_target: Vector2 = Vector2.ZERO

## Y position before dodging (to return to).
var _dodge_origin_y: float = 0.0

## Cached player reference for awareness behaviors.
var _player: Node2D = null


# =============================================================================
# NODES
# =============================================================================

## The Sprite2D displaying the calaca PNG.
var _sprite: Sprite2D

## The Area2D for contact damage detection with the player.
var _hit_area: Area2D

## Procedural animation component.
var _deformer: Node


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready():
	collision_layer = 8       # Enemies layer (bit 4)
	collision_mask = 1 | 2    # World + Platforms

	add_to_group("enemies")

	# Record spawn height as the bob center.
	base_y = position.y

	_build_sprite()
	_build_collision()
	_build_hit_area()
	_build_deformer()


func _physics_process(delta: float):
	if not alive:
		return

	# Try to find the player if we don't have a reference yet.
	if not is_instance_valid(_player):
		_find_player()

	_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)

	match _state:
		State.PATROL:
			_process_patrol(delta)
		State.NOTICE:
			_process_notice(delta)
		State.SWOOP:
			_process_swoop(delta)
		State.RETREAT:
			_process_retreat(delta)
		State.DODGE:
			_process_dodge(delta)

	# Boundary enforcement (all states).
	if position.x < EDGE_MARGIN and dir < 0:
		dir = 1
		position.x = EDGE_MARGIN
	elif position.x > level_width - EDGE_MARGIN and dir > 0:
		dir = -1
		position.x = level_width - EDGE_MARGIN

	# Flip sprite based on direction.
	if _sprite:
		_sprite.flip_h = (dir < 0)

	move_and_slide()


# =============================================================================
# STATE PROCESSORS
# =============================================================================

func _process_patrol(delta: float):
	## Default: horizontal patrol with dreamy sin bob.
	velocity.x = speed * dir
	velocity.y = 0.0

	bob_time += delta
	position.y = base_y + sin(bob_time * BOB_FREQUENCY) * bob_amplitude

	# Check for player awareness.
	if _cooldown_timer <= 0.0 and _can_see_player():
		# Check stomp danger first (player directly above).
		if _player_above():
			_enter_dodge()
		else:
			_enter_notice()


func _process_notice(delta: float):
	## Taunt: pause movement, bob excitedly, face the player.
	_state_timer -= delta

	# Face the player during taunt.
	if is_instance_valid(_player):
		dir = 1 if _player.global_position.x > global_position.x else -1

	# Excited bobbing (faster, smaller amplitude).
	velocity.x = 0.0
	velocity.y = 0.0
	bob_time += delta
	position.y = base_y + sin(bob_time * TAUNT_BOB_SPEED) * TAUNT_BOB_AMPLITUDE

	# Stomp danger interrupts the taunt.
	if _player_above():
		_enter_dodge()
		return

	if _state_timer <= 0.0:
		_enter_swoop()


func _process_swoop(delta: float):
	## Dive toward the player's last-seen position.
	var to_target: Vector2 = _swoop_target - global_position
	var dist: float = to_target.length()

	if dist < 15.0:
		# Reached the target -- retreat back to altitude.
		_enter_retreat()
		return

	# Stomp danger interrupts the swoop.
	if _player_above():
		_enter_dodge()
		return

	velocity = to_target.normalized() * SWOOP_SPEED

	# Face movement direction.
	if velocity.x != 0.0:
		dir = 1 if velocity.x > 0.0 else -1


func _process_retreat(delta: float):
	## Float back up to patrol altitude.
	var target_y: float = base_y
	var dy: float = target_y - position.y

	if absf(dy) < 5.0:
		# Close enough -- resume patrol.
		position.y = target_y
		_state = State.PATROL
		_cooldown_timer = SWOOP_COOLDOWN
		return

	# Stomp danger interrupts retreat.
	if _player_above():
		_enter_dodge()
		return

	velocity.x = speed * dir * 0.5  # Drift horizontally while retreating.
	velocity.y = signf(dy) * RETREAT_SPEED

	bob_time += delta


func _process_dodge(delta: float):
	## Quick upward escape from stomp danger.
	_state_timer -= delta

	velocity.x = speed * dir * 0.3  # Slight horizontal drift.
	velocity.y = -DODGE_SPEED

	if _state_timer <= 0.0:
		# Update base_y to current position so it doesn't dive back down.
		base_y = position.y
		_state = State.RETREAT
		_cooldown_timer = SWOOP_COOLDOWN


# =============================================================================
# STATE TRANSITIONS
# =============================================================================

func _enter_notice():
	_state = State.NOTICE
	_state_timer = NOTICE_DURATION


func _enter_swoop():
	_state = State.SWOOP
	if is_instance_valid(_player):
		# Target slightly ahead of the player's position.
		_swoop_target = _player.global_position + Vector2(
			_player.velocity.x * 0.15, 0.0
		)
	else:
		_enter_retreat()


func _enter_retreat():
	_state = State.RETREAT


func _enter_dodge():
	_state = State.DODGE
	_dodge_origin_y = position.y
	_state_timer = DODGE_DISTANCE / DODGE_SPEED  # Time to cover the dodge distance.


# =============================================================================
# AWARENESS
# =============================================================================

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]


func _can_see_player() -> bool:
	if not is_instance_valid(_player):
		return false
	return global_position.distance_to(_player.global_position) < DETECTION_RANGE


func _player_above() -> bool:
	## True when the player is directly above and falling -- stomp danger.
	if not is_instance_valid(_player):
		return false
	var dx: float = absf(_player.global_position.x - global_position.x)
	var dy: float = global_position.y - _player.global_position.y  # Positive = player above.
	return dx < STOMP_DANGER_X and dy > 10.0 and dy < STOMP_DANGER_Y and _player.velocity.y > 0.0


# =============================================================================
# CONFIGURATION -- called by the spawner after instantiation
# =============================================================================

## Configure this Calaca from spawn data.
func setup(data: Dictionary):
	dir = data.get("dir", 1)
	speed = data.get("speed", DEFAULT_SPEED)
	level_width = data.get("level_width", 3000.0)
	bob_amplitude = data.get("amplitude", DEFAULT_BOB_AMPLITUDE)
	if data.has("y"):
		base_y = data.get("y")


# =============================================================================
# DAMAGE RESPONSES -- compatible with CombatSystem and LuchadorSystem
# =============================================================================

func hit_by_stomp():
	if not alive:
		return
	alive = false

	if _hit_area:
		_hit_area.set_deferred("monitoring", false)

	GameState.score += KILL_SCORE
	Events.score_changed.emit(GameState.score)
	AudioManager.play_sfx("stomp")

	velocity = Vector2.ZERO
	set_physics_process(false)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.0, 0.05), DEATH_DURATION)
	tween.tween_property(self, "modulate:a", 0.0, DEATH_DURATION * 0.8)
	tween.chain().tween_callback(queue_free)


func hit_by_attack():
	if not alive:
		return
	alive = false

	velocity = Vector2(dir * -200, -150)
	modulate = Color(1, 0.5, 0.5)

	if _hit_area:
		_hit_area.set_deferred("monitoring", false)

	GameState.score += KILL_SCORE
	Events.score_changed.emit(GameState.score)
	AudioManager.play_sfx("stomp")

	set_physics_process(false)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation", TAU * 3, DEATH_DURATION)
	tween.tween_property(self, "scale", Vector2(0.1, 1.8), DEATH_DURATION * 0.3)
	tween.tween_property(self, "modulate:a", 0.0, DEATH_DURATION)
	tween.tween_property(self, "position", position + Vector2(dir * -150, -80), DEATH_DURATION)
	tween.chain().tween_callback(queue_free)


func die():
	if not alive:
		return
	alive = false

	if _hit_area:
		_hit_area.set_deferred("monitoring", false)

	queue_free()


# =============================================================================
# SPRITE SETUP
# =============================================================================

func _build_sprite():
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"

	var tex = load("res://assets/sprites/enemies/calaca.png")
	if tex == null:
		push_warning("Calaca: failed to load sprite, using placeholder")
		_build_placeholder()
		return

	_sprite.texture = tex

	var scale_factor: float = TARGET_HEIGHT / tex.get_height()
	_sprite.scale = Vector2(scale_factor, scale_factor)
	_sprite.centered = true

	add_child(_sprite)


func _build_placeholder():
	var visual := Node2D.new()
	visual.name = "Sprite"

	var body := ColorRect.new()
	body.size = Vector2(30.0, 35.0)
	body.position = Vector2(-15.0, -17.5)
	body.color = Color(0.95, 0.9, 0.8)
	visual.add_child(body)

	var hat := ColorRect.new()
	hat.size = Vector2(45.0, 8.0)
	hat.position = Vector2(-22.5, -25.0)
	hat.color = Color(0.76, 0.6, 0.3)
	visual.add_child(hat)

	var eye_left := ColorRect.new()
	eye_left.size = Vector2(6.0, 6.0)
	eye_left.position = Vector2(-10.0, -8.0)
	eye_left.color = Color(1.0, 0.6, 0.0)
	visual.add_child(eye_left)

	var eye_right := ColorRect.new()
	eye_right.size = Vector2(6.0, 6.0)
	eye_right.position = Vector2(4.0, -8.0)
	eye_right.color = Color(1.0, 0.6, 0.0)
	visual.add_child(eye_right)

	_sprite = null
	add_child(visual)


# =============================================================================
# COLLISION
# =============================================================================

func _build_collision():
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(30.0, 35.0)
	collision.shape = shape
	add_child(collision)


# =============================================================================
# CONTACT DAMAGE
# =============================================================================

func _build_hit_area():
	_hit_area = Area2D.new()
	_hit_area.name = "HitArea"
	_hit_area.collision_layer = 0
	_hit_area.collision_mask = 4
	_hit_area.monitoring = true
	_hit_area.monitorable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(34.0, 38.0)
	shape.shape = rect
	_hit_area.add_child(shape)
	add_child(_hit_area)

	_hit_area.body_entered.connect(_on_body_entered)


# =============================================================================
# PROCEDURAL ANIMATION -- InertialDeformer component
# =============================================================================

func _build_deformer():
	var DeformerScript = load("res://scripts/systems/inertial_deformer.gd")
	if DeformerScript == null:
		push_warning("Calaca: InertialDeformer script not found, no procedural animation")
		return

	_deformer = DeformerScript.new()
	_deformer.name = "InertialDeformer"
	_deformer.squash_amount = 0.15
	_deformer.skew_strength = 0.002
	_deformer.recovery_speed = 6.0
	_deformer.wobble_speed = 2.0
	_deformer.wobble_amount = 0.06
	_deformer.flying = true
	_deformer.direction_bounce = 0.25
	add_child(_deformer)


func _on_body_entered(body: Node):
	if not alive:
		return
	if not body is Player:
		return

	var player_node: Player = body as Player
	if player_node.is_dead:
		return

	var is_stomping: bool = (
		player_node.velocity.y > 0.0
		and not player_node.is_on_floor()
		and player_node.global_position.y < global_position.y - 2.0
	)

	if is_stomping:
		hit_by_stomp()
		player_node.stomp_bounce()
	else:
		player_node.hit()

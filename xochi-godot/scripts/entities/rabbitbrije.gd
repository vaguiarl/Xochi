extends CharacterBody2D
## Rabbitbrije -- Mesoamerican alebrije rabbit, the basic "goomba" enemy.
##
## A colorful folk-art spirit rabbit that patrols back and forth on its
## platform, DKC Gnawty-style -- it NEVER walks off ledges. Reverses at
## walls, level boundaries, AND platform edges.
##
## Dies in one stomp or one attack. Contact damage to the player on touch.
##
## Uses a PNG sprite (res://assets/sprites/enemies/rabbitbrije.png) scaled
## down to ~50px tall for gameplay. The sprite faces RIGHT by default.
##
## This enemy does NOT extend EnemyBase. It is a standalone CharacterBody2D
## loaded dynamically by EnemySpawner to prevent cascade failures.
##
## Procedural squash/stretch/skew is handled by the InertialDeformer child
## node (volume-preserving, Rayman-style). No inline animation math needed.
##
## Collision setup:
##   Layer 8 (Enemies)
##   Mask 1 | 2 (World + Platforms)


# =============================================================================
# CONSTANTS
# =============================================================================

## Default patrol speed in px/s.
const DEFAULT_SPEED: float = 50.0

## Gravity applied to this enemy in px/s^2.
const GRAVITY: float = 900.0

## Boundary margin -- reverse direction at level edges (px).
const EDGE_MARGIN: float = 50.0

## Score awarded on kill.
const KILL_SCORE: int = 50

## Duration of the death shrink animation (seconds).
const DEATH_DURATION: float = 0.3

## Target height in pixels for the sprite (source is ~500px).
const TARGET_HEIGHT: float = 50.0

## How far ahead of center the ledge detector probes (px).
const LEDGE_PROBE_X: float = 28.0

## How far down the ledge detector probes (px). Must reach past the
## platform surface when standing on it.
const LEDGE_PROBE_Y: float = 30.0


# =============================================================================
# STATE
# =============================================================================

## Whether this enemy is alive and can interact with the world.
var alive: bool = true

## Current movement direction: 1 = right, -1 = left.
var dir: int = 1

## Horizontal movement speed in px/s.
var speed: float = DEFAULT_SPEED

## Width of the current level (for boundary reversal).
var level_width: float = 3000.0


# =============================================================================
# NODES
# =============================================================================

## The Sprite2D displaying the rabbitbrije PNG.
var _sprite: Sprite2D

## The Area2D for contact damage detection with the player.
var _hit_area: Area2D

## RayCast2D pointing down-forward to detect platform edges.
var _ledge_ray: RayCast2D

## Procedural animation component.
var _deformer: Node


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready():
	# -- Collision configuration --
	collision_layer = 8       # Enemies layer (bit 4)
	collision_mask = 1 | 2    # World + Platforms

	# Register in the enemies group so combat systems can find us.
	add_to_group("enemies")

	_build_sprite()
	_build_collision()
	_build_hit_area()
	_build_ledge_detector()
	_build_deformer()


func _physics_process(delta: float):
	if not alive:
		return

	# Apply gravity -- Rabbits are ground-bound.
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Horizontal patrol movement.
	velocity.x = speed * dir

	# --- Reversal checks (priority: ledge > wall > boundary) ---

	# Ledge detection: reverse BEFORE walking off the platform edge.
	if is_on_floor() and _ledge_ray and not _ledge_ray.is_colliding():
		dir *= -1
		_sync_ledge_ray()

	# Reverse at walls.
	if is_on_wall():
		dir *= -1
		_sync_ledge_ray()

	# Reverse at level boundaries.
	if position.x < EDGE_MARGIN and dir < 0:
		dir = 1
		position.x = EDGE_MARGIN
		_sync_ledge_ray()
	elif position.x > level_width - EDGE_MARGIN and dir > 0:
		dir = -1
		position.x = level_width - EDGE_MARGIN
		_sync_ledge_ray()

	# Flip sprite based on direction (sprite faces RIGHT by default).
	if _sprite:
		_sprite.flip_h = (dir < 0)

	move_and_slide()


# =============================================================================
# CONFIGURATION -- called by the spawner after instantiation
# =============================================================================

## Configure this Rabbitbrije from spawn data.
## Accepted keys:
##   "dir"         - initial patrol direction: 1 (right) or -1 (left)
##   "speed"       - patrol speed override (default 50)
##   "level_width" - level width for boundary reversal
func setup(data: Dictionary):
	dir = data.get("dir", 1)
	speed = data.get("speed", DEFAULT_SPEED)
	level_width = data.get("level_width", 3000.0)
	_sync_ledge_ray()


# =============================================================================
# DAMAGE RESPONSES -- compatible with CombatSystem and LuchadorSystem
# =============================================================================

## Called when the player stomps on this rabbit (falling from above).
## One-hit kill with squish effect.
func hit_by_stomp():
	if not alive:
		return
	alive = false

	# Disable the hit area so it cannot damage the player post-mortem.
	if _hit_area:
		_hit_area.set_deferred("monitoring", false)

	# Score.
	GameState.score += KILL_SCORE
	Events.score_changed.emit(GameState.score)

	# SFX.
	AudioManager.play_sfx("stomp")

	# Dramatic squash death: pancake flat with volume preservation.
	# Scale X balloons outward as Y collapses to near-zero.
	velocity = Vector2.ZERO
	set_physics_process(false)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.0, 0.05), DEATH_DURATION)
	tween.tween_property(self, "modulate:a", 0.0, DEATH_DURATION * 0.8)
	tween.chain().tween_callback(queue_free)


## Called when the player's melee attack or thunderbolt hits this rabbit.
## One-hit kill with knockback.
func hit_by_attack():
	if not alive:
		return
	alive = false

	# Knockback the corpse away from attacker.
	velocity = Vector2(dir * -200, -150)
	modulate = Color(1, 0.5, 0.5)

	# Disable hit area.
	if _hit_area:
		_hit_area.set_deferred("monitoring", false)

	# Score.
	GameState.score += KILL_SCORE
	Events.score_changed.emit(GameState.score)

	# SFX.
	AudioManager.play_sfx("stomp")

	# Spin + stretch death: enemy spirals away with exaggerated deformation.
	set_physics_process(false)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation", TAU * 3, DEATH_DURATION)
	tween.tween_property(self, "scale", Vector2(0.1, 1.8), DEATH_DURATION * 0.3)
	tween.tween_property(self, "modulate:a", 0.0, DEATH_DURATION)
	tween.tween_property(self, "position", position + Vector2(dir * -150, -80), DEATH_DURATION)
	tween.chain().tween_callback(queue_free)


## Generic instant death -- no animation, no score. Used for cleanup.
func die():
	if not alive:
		return
	alive = false

	if _hit_area:
		_hit_area.set_deferred("monitoring", false)

	queue_free()


# =============================================================================
# SPRITE SETUP -- PNG-based visual
# =============================================================================

func _build_sprite():
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"

	var tex = load("res://assets/sprites/enemies/rabbitbrije.png")
	if tex == null:
		push_warning("Rabbitbrije: failed to load sprite, using placeholder")
		_build_placeholder()
		return

	_sprite.texture = tex

	# Scale to target height for gameplay (source is ~997px tall).
	var scale_factor: float = TARGET_HEIGHT / tex.get_height()
	_sprite.scale = Vector2(scale_factor, scale_factor)
	_sprite.centered = true

	add_child(_sprite)


func _build_placeholder():
	var visual := Node2D.new()
	visual.name = "Sprite"

	# Fluorescent alebrije colors -- impossible to miss!
	var body := ColorRect.new()
	body.size = Vector2(40.0, 45.0)
	body.position = Vector2(-20.0, -22.5)
	body.color = Color(1.0, 0.0, 1.0)  # Hot magenta
	visual.add_child(body)

	# Belly stripe
	var belly := ColorRect.new()
	belly.size = Vector2(30.0, 14.0)
	belly.position = Vector2(-15.0, -6.0)
	belly.color = Color(0.0, 1.0, 0.6)  # Neon green
	visual.add_child(belly)

	# Ears -- tall, neon
	var ear_left := ColorRect.new()
	ear_left.size = Vector2(8.0, 22.0)
	ear_left.position = Vector2(-14.0, -44.0)
	ear_left.color = Color(1.0, 1.0, 0.0)  # Neon yellow
	visual.add_child(ear_left)

	var ear_right := ColorRect.new()
	ear_right.size = Vector2(8.0, 22.0)
	ear_right.position = Vector2(6.0, -44.0)
	ear_right.color = Color(1.0, 1.0, 0.0)  # Neon yellow
	visual.add_child(ear_right)

	# Inner ear
	var inner_left := ColorRect.new()
	inner_left.size = Vector2(4.0, 14.0)
	inner_left.position = Vector2(-12.0, -40.0)
	inner_left.color = Color(1.0, 0.4, 0.0)  # Orange
	visual.add_child(inner_left)

	var inner_right := ColorRect.new()
	inner_right.size = Vector2(4.0, 14.0)
	inner_right.position = Vector2(8.0, -40.0)
	inner_right.color = Color(1.0, 0.4, 0.0)  # Orange
	visual.add_child(inner_right)

	# Eyes -- big white with dark pupils
	var eye_l := ColorRect.new()
	eye_l.size = Vector2(10.0, 10.0)
	eye_l.position = Vector2(-16.0, -18.0)
	eye_l.color = Color.WHITE
	visual.add_child(eye_l)

	var pupil_l := ColorRect.new()
	pupil_l.size = Vector2(5.0, 5.0)
	pupil_l.position = Vector2(-13.0, -15.0)
	pupil_l.color = Color.BLACK
	visual.add_child(pupil_l)

	var eye_r := ColorRect.new()
	eye_r.size = Vector2(10.0, 10.0)
	eye_r.position = Vector2(6.0, -18.0)
	eye_r.color = Color.WHITE
	visual.add_child(eye_r)

	var pupil_r := ColorRect.new()
	pupil_r.size = Vector2(5.0, 5.0)
	pupil_r.position = Vector2(9.0, -15.0)
	pupil_r.color = Color.BLACK
	visual.add_child(pupil_r)

	# Nose
	var nose := ColorRect.new()
	nose.size = Vector2(6.0, 4.0)
	nose.position = Vector2(-3.0, -8.0)
	nose.color = Color(1.0, 0.3, 0.5)
	visual.add_child(nose)

	# Feet
	var foot_l := ColorRect.new()
	foot_l.size = Vector2(12.0, 6.0)
	foot_l.position = Vector2(-18.0, 18.0)
	foot_l.color = Color(0.0, 1.0, 1.0)  # Cyan
	visual.add_child(foot_l)

	var foot_r := ColorRect.new()
	foot_r.size = Vector2(12.0, 6.0)
	foot_r.position = Vector2(6.0, 18.0)
	foot_r.color = Color(0.0, 1.0, 1.0)  # Cyan
	visual.add_child(foot_r)

	_sprite = null
	add_child(visual)


# =============================================================================
# COLLISION -- CharacterBody2D shape for world interaction
# =============================================================================

func _build_collision():
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(50.0, 45.0)
	collision.shape = shape
	add_child(collision)


# =============================================================================
# LEDGE DETECTION -- DKC Gnawty-style platform patrol
# =============================================================================

func _build_ledge_detector():
	## A RayCast2D that probes downward just ahead of the rabbit's feet.
	## When it stops hitting ground, the rabbit is at a platform edge
	## and must reverse direction.

	_ledge_ray = RayCast2D.new()
	_ledge_ray.name = "LedgeDetector"
	_ledge_ray.collision_mask = 1 | 2   # World + Platforms
	_ledge_ray.enabled = true
	_sync_ledge_ray()
	add_child(_ledge_ray)


func _sync_ledge_ray() -> void:
	## Position the probe ahead of the rabbit in its current direction.
	if _ledge_ray:
		_ledge_ray.position = Vector2(LEDGE_PROBE_X * dir, 10.0)
		_ledge_ray.target_position = Vector2(0.0, LEDGE_PROBE_Y)


# =============================================================================
# PROCEDURAL ANIMATION -- InertialDeformer component
# =============================================================================

func _build_deformer():
	## Create an InertialDeformer child node for Rayman-style squash/stretch.
	## The deformer reads our velocity/floor state and writes to our scale/skew.

	var DeformerScript = load("res://scripts/systems/inertial_deformer.gd")
	if DeformerScript == null:
		push_warning("Rabbitbrije: InertialDeformer script not found, no procedural animation")
		return

	_deformer = DeformerScript.new()
	_deformer.name = "InertialDeformer"
	_deformer.squash_amount = 0.3
	_deformer.skew_strength = 0.0015
	_deformer.recovery_speed = 8.0
	_deformer.wobble_speed = 3.0
	_deformer.wobble_amount = 0.04
	_deformer.flying = false
	add_child(_deformer)


# =============================================================================
# CONTACT DAMAGE -- Area2D for player overlap detection
# =============================================================================

func _build_hit_area():
	_hit_area = Area2D.new()
	_hit_area.name = "HitArea"
	_hit_area.collision_layer = 0
	_hit_area.collision_mask = 4       # Detect Player layer (bit 3)
	_hit_area.monitoring = true
	_hit_area.monitorable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(54.0, 48.0)
	shape.shape = rect
	_hit_area.add_child(shape)
	add_child(_hit_area)

	_hit_area.body_entered.connect(_on_body_entered)


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

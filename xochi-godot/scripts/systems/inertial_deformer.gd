extends Node
## InertialDeformer -- Plug-and-play procedural squash, stretch, and skew.
##
## Drop as a child of any CharacterBody2D (or create via code). Reads the
## parent's velocity and floor state each physics frame and applies
## volume-preserving deformation + inertial skew to the parent's transform.
##
## Volume preservation:  scale.x = 1.0 / scale.y   =>   det(basis) = 1
## This keeps the silhouette area constant -- the eye reads it as physically
## correct even at extreme deformations (stomp squash, jump stretch).
##
## Inertial skew:  the character "leans" into acceleration and snaps back
## on deceleration, replacing the need for dedicated run-start / run-stop
## sprite frames.
##
## Two modes:
##   flying = false  (default) -- ground enemy: landing squash, jump stretch
##   flying = true             -- floating enemy: dreamy wobble, direction bounce
##
## Compatible with duck-typed "alive" property: stops deforming when parent dies.


# =============================================================================
# TUNABLES (Inspector)
# =============================================================================

## Maximum deformation magnitude (0 = none, 1 = extreme).
## At 0.3 a landing squash compresses Y to 0.7 and expands X to ~1.43.
@export_range(0.0, 1.0, 0.01) var squash_amount: float = 0.3

## Horizontal lean per px/s of velocity. Higher = more exaggerated lean.
@export_range(0.0, 0.01, 0.0001) var skew_strength: float = 0.0015

## Spring-back speed for both scale and skew recovery (higher = snappier).
@export_range(1.0, 20.0, 0.5) var recovery_speed: float = 8.0

## Idle breathing oscillation frequency in rad/s.
@export_range(0.5, 10.0, 0.1) var wobble_speed: float = 3.0

## Idle breathing amplitude (fraction of scale, e.g. 0.04 = 4%).
@export_range(0.0, 0.2, 0.005) var wobble_amount: float = 0.04

## Flying mode: dreamy wobble + direction-change bounce instead of
## ground-based landing detection.
@export var flying: bool = false

## Direction-change bounce magnitude (flying mode only).
@export_range(0.0, 0.5, 0.01) var direction_bounce: float = 0.25


# =============================================================================
# INTERNAL STATE
# =============================================================================

## Cached reference to the parent CharacterBody2D.
var _body: CharacterBody2D

## Deformation target scale (lerped toward each frame).
var _target_sy: float = 1.0

## Previous frame's Y velocity -- used to detect landing impacts.
var _prev_vel_y: float = 0.0

## Previous movement direction sign -- used to detect reversals (flying mode).
var _prev_dir_sign: float = 0.0

## Accumulated time for sin() wobble wave.
var _t: float = 0.0


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_body = get_parent() as CharacterBody2D
	if not _body:
		push_error("InertialDeformer: parent must be a CharacterBody2D, got %s" % get_parent())
		set_physics_process(false)
		return

	# Randomize phase so identical enemies don't breathe in sync.
	_t = randf() * TAU


func _physics_process(delta: float) -> void:
	# Stop deforming if parent is dead (duck-typed).
	var parent_alive: Variant = _body.get("alive")
	if parent_alive is bool and not parent_alive:
		return

	_t += delta

	# --- Compute target deformation ---
	if flying:
		_compute_flying()
	else:
		_compute_ground()

	# --- Volume-preserving scale application ---
	# Clamp sy away from zero to avoid division explosion.
	var sy: float = clampf(_target_sy, 0.15, 3.0)
	var sx: float = 1.0 / sy  # det(basis) = sx * sy = 1.0
	var goal: Vector2 = Vector2(sx, sy)

	_body.scale = _body.scale.lerp(goal, recovery_speed * delta)

	# --- Inertial skew ---
	var target_skew: float = -_body.velocity.x * skew_strength
	_body.skew = lerpf(_body.skew, target_skew, recovery_speed * 0.6 * delta)

	# Store for next frame (must come AFTER the checks above).
	_prev_vel_y = _body.velocity.y


# =============================================================================
# GROUND MODE -- landing squash, jump stretch, idle breathing
# =============================================================================

func _compute_ground() -> void:
	var just_landed: bool = _body.is_on_floor() and _prev_vel_y > 100.0

	if just_landed:
		# Impact squash: stronger falls → bigger squash (clamped).
		var impact: float = clampf(_prev_vel_y / 500.0, 0.0, 1.0)
		_target_sy = 1.0 - squash_amount * impact

	elif not _body.is_on_floor() and _body.velocity.y < -50.0:
		# Rising: vertical stretch (tall and narrow).
		_target_sy = 1.0 + squash_amount * 0.4

	elif not _body.is_on_floor() and _body.velocity.y > 100.0:
		# Falling fast: slight squash anticipating impact.
		_target_sy = 1.0 - squash_amount * 0.2

	else:
		# Idle / on ground: gentle breathing wobble.
		_target_sy = 1.0 - sin(_t * wobble_speed) * wobble_amount


# =============================================================================
# FLYING MODE -- dreamy wobble, direction-change bounce
# =============================================================================

func _compute_flying() -> void:
	# Floating wobble: sin + offset cos for organic asymmetry.
	var wobble: float = sin(_t * wobble_speed) * wobble_amount
	var cross: float = cos(_t * wobble_speed * 0.7) * wobble_amount * 0.5
	_target_sy = 1.0 - wobble + cross

	# Direction change bounce: brief vertical squash when reversing.
	var current_dir: float = signf(_body.velocity.x)
	if current_dir != 0.0 and current_dir != _prev_dir_sign:
		_target_sy -= direction_bounce
	if current_dir != 0.0:
		_prev_dir_sign = current_dir

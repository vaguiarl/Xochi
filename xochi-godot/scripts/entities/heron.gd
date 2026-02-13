extends EnemyBase
## Heron enemy -- flies vertically, patrols horizontally, SHOOTS at the player!
##
## Exact port from original game.js lines 7006-7039.
##
## Movement:
##   - Flap oscillation: bobs +/- 40 px from base Y position.
##   - Horizontal patrol at configurable speed (default 80 px/s).
##   - Reverses direction at world bounds (50 px margin).
##
## Shooting:
##   - Every 2-4 seconds (randomized) checks if player is within 400 px.
##   - Fires a small red projectile toward the player's current position.
##   - Projectile speed: 200 px/s, lifetime: 3 seconds.
##   - On hit, calls player.hit() and self-destructs.


# =============================================================================
# STATE
# =============================================================================

## The Y position around which the heron oscillates.
var base_y: float = 0.0

## True when flapping upward, false when descending.
var flap_up: bool = true

## Countdown to next shooting attempt.
var shoot_timer: float = 0.0

## Width of the level for boundary-reversal logic.
var level_width: float = 2000.0


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready():
	super._ready()
	# Flying enemies ignore gravity entirely
	gravity = 0.0


# =============================================================================
# CONFIGURATION
# =============================================================================

## Configure this heron from spawn data.
## Accepted keys:
##   "dir"         - initial direction: 1 (right) or -1 (left)
##   "speed"       - horizontal patrol speed (default 80)
##   "y"           - base Y position for flap oscillation
##   "level_width" - level width for boundary checks (default 2000)
func setup(data: Dictionary):
	enemy_type = "flying"
	dir = data.get("dir", 1)
	speed = data.get("speed", 80.0)
	base_y = data.get("y", position.y)
	shoot_timer = randf_range(1.0, 3.0)  # Random delay before first shot
	level_width = data.get("level_width", 2000.0)


# =============================================================================
# PHYSICS
# =============================================================================

func _physics_process(delta):
	if not alive:
		return

	# --- Flap up and down (from original lines 7011-7018) ---
	if flap_up:
		velocity.y = -120.0
		if position.y < base_y - 40:
			flap_up = false
	else:
		velocity.y = 100.0
		if position.y > base_y + 40:
			flap_up = true

	# --- Horizontal movement ---
	velocity.x = speed * dir

	# --- Reverse at world bounds (only when moving toward the boundary) ---
	if position.x < 50 and dir < 0:
		dir = 1
		position.x = 50
	elif position.x > level_width - 50 and dir > 0:
		dir = -1
		position.x = level_width - 50

	# --- Flip visual ---
	if has_node("Visual"):
		$Visual.scale.x = -1 if dir > 0 else 1

	# --- SHOOT at player! (from original lines 7027-7039) ---
	shoot_timer -= delta
	if shoot_timer <= 0:
		_try_shoot()
		shoot_timer = randf_range(2.0, 4.0)  # Next shot in 2-4 seconds

	move_and_slide()


# =============================================================================
# SHOOTING
# =============================================================================

## Attempt to shoot at the player. Only fires if player is within 400 px.
func _try_shoot():
	var player = _find_player()
	if player == null:
		return

	var dist = position.distance_to(player.global_position)
	if dist < 400:
		_fire_projectile(player.global_position)


## Spawn a small red projectile that flies toward the target position.
func _fire_projectile(target_pos: Vector2):
	var projectile = Area2D.new()
	projectile.position = global_position
	projectile.collision_layer = 8  # Enemy layer
	projectile.collision_mask = 4   # Hits player layer

	# Collision shape -- small circle
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	projectile.add_child(shape)

	# Visual -- small red square (placeholder until art is ready)
	var visual = ColorRect.new()
	visual.size = Vector2(8, 8)
	visual.position = Vector2(-4, -4)
	visual.color = Color(1.0, 0.2, 0.2)
	projectile.add_child(visual)

	# Calculate direction to player at the moment of firing
	var dir_to_player = (target_pos - global_position).normalized()
	var proj_speed = 200.0

	# Store velocity and lifetime
	projectile.set_meta("velocity", dir_to_player * proj_speed)
	projectile.set_meta("lifetime", 3.0)

	# CRITICAL FIX: Add simple script to move and auto-cleanup projectile
	var projectile_script := GDScript.new()
	projectile_script.source_code = """
extends Area2D

func _physics_process(delta):
	# Move projectile
	var vel = get_meta('velocity', Vector2.ZERO)
	position += vel * delta

	# Tick down lifetime
	var lifetime = get_meta('lifetime', 0.0) - delta
	set_meta('lifetime', lifetime)

	# Auto-delete when expired
	if lifetime <= 0:
		queue_free()
"""
	projectile_script.reload()
	projectile.set_script(projectile_script)

	# Add to the scene tree (parent is the current game scene root)
	get_tree().current_scene.add_child(projectile)

	# Damage the player on body contact
	projectile.body_entered.connect(func(body):
		if body is Player:
			body.hit()
			projectile.queue_free()
	)


## Find the player node via group lookup.
func _find_player() -> Node:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

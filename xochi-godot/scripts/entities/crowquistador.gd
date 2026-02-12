extends EnemyBase
class_name Crowquistador
## Crowquistador enemy -- whimsical crow conquistador with skeletal animation!
##
## Similar movement to Heron (flies, patrols, shoots) but with DKC-style
## pre-rendered 3D sprites assembled as a skeletal rig for procedural animation.
##
## Skeletal parts:
##   - head (helmet with plume)
##   - body (breastplate armor)
##   - wings (4 sprites: up_left, up_right, down_left, down_right)
##   - tail, legs, sword
##
## Movement:
##   - Flap oscillation: bobs +/- 40 px from base Y position
##   - Horizontal patrol at configurable speed (default 80 px/s)
##   - Reverses direction at world bounds (50 px margin)
##
## Shooting:
##   - Every 2-4 seconds checks if player is within 400 px
##   - Fires a small red projectile toward the player
##   - Projectile speed: 200 px/s, lifetime: 3 seconds


# =============================================================================
# PRELOADED BODY PARTS
# =============================================================================

const PART_HEAD: Texture2D = preload("res://assets/sprites/prerendered/enemies/crowquistador_parts/head.png")
const PART_BODY: Texture2D = preload("res://assets/sprites/prerendered/enemies/crowquistador_parts/body.png")
const PART_WING_UP_LEFT: Texture2D = preload("res://assets/sprites/prerendered/enemies/crowquistador_parts/left_wing_up.png")
const PART_WING_UP_RIGHT: Texture2D = preload("res://assets/sprites/prerendered/enemies/crowquistador_parts/right_wing_up.png")
const PART_WING_DOWN_LEFT: Texture2D = preload("res://assets/sprites/prerendered/enemies/crowquistador_parts/left_wing_down.png")
const PART_WING_DOWN_RIGHT: Texture2D = preload("res://assets/sprites/prerendered/enemies/crowquistador_parts/right_wing_down.png")
const PART_TAIL: Texture2D = preload("res://assets/sprites/prerendered/enemies/crowquistador_parts/tail.png")
const PART_LEG_LEFT: Texture2D = preload("res://assets/sprites/prerendered/enemies/crowquistador_parts/leg_left.png")
const PART_LEG_RIGHT: Texture2D = preload("res://assets/sprites/prerendered/enemies/crowquistador_parts/leg_right.png")
const PART_SWORD: Texture2D = preload("res://assets/sprites/prerendered/enemies/crowquistador_parts/sword.png")


# =============================================================================
# STATE
# =============================================================================

## The Y position around which the crowquistador oscillates
var base_y: float = 0.0

## Vertical oscillation amplitude in pixels (default 40)
var amplitude: float = 40.0

## True when flapping upward, false when descending
var flap_up: bool = true

## Countdown to next shooting attempt
var shoot_timer: float = 0.0

## Width of the level for boundary-reversal logic
var level_width: float = 2000.0

## Wing flap animation timer
var wing_flap_time: float = 0.0


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
	_build_skeletal_rig()


## Build the skeletal animation rig from pre-rendered body parts
func _build_skeletal_rig():
	# Root node for the entire rig (allows flipping)
	rig = Node2D.new()
	rig.name = "Rig"
	add_child(rig)

	# Scale to fit game proportions
	var rig_scale: float = 0.10  # Larger for better visibility
	rig.scale = Vector2(rig_scale, rig_scale)

	# Build anatomically correct crow: head → body → wings → tail behind, legs below

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
	shape.size = Vector2(35, 45)  # Slightly bigger collision
	collision.shape = shape
	add_child(collision)


# =============================================================================
# CONFIGURATION
# =============================================================================

## Configure this crowquistador from spawn data
## Accepted keys:
##   "dir"         - initial direction: 1 (right) or -1 (left)
##   "speed"       - horizontal patrol speed (default 80)
##   "y"           - base Y position for flap oscillation
##   "amplitude"   - vertical oscillation range (default 40)
##   "level_width" - level width for boundary checks (default 2000)
func setup(data: Dictionary):
	enemy_type = "flying"
	dir = data.get("dir", 1)
	speed = data.get("speed", 80.0)
	base_y = data.get("y", position.y)
	amplitude = data.get("amplitude", 40.0)  # FIXED: Use custom amplitude!
	shoot_timer = randf_range(1.0, 3.0)  # Random delay before first shot
	level_width = data.get("level_width", 2000.0)


# =============================================================================
# PHYSICS & ANIMATION
# =============================================================================

func _physics_process(delta):
	if not alive:
		return

	# --- Flap up and down ---
	if flap_up:
		velocity.y = -120.0
		if position.y < base_y - amplitude:  # FIXED: Use custom amplitude!
			flap_up = false
	else:
		velocity.y = 100.0
		if position.y > base_y + amplitude:  # FIXED: Use custom amplitude!
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

	# --- Flip the entire rig when changing direction ---
	if rig:
		rig.scale.x = abs(rig.scale.x) * (1 if dir > 0 else -1)

	# --- Animate wing flapping ---
	wing_flap_time += delta * 5.0  # Clear flap speed
	var flap_phase := sin(wing_flap_time)

	if sprite_wing_left and sprite_wing_right:
		# Swap textures based on flap phase - clear alternation
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

	# --- Body bobs gently (flight dynamics) ---
	if sprite_body:
		sprite_body.position.y = 0 + sin(wing_flap_time * 1.3) * 3

	# --- Head bobs with body ---
	if sprite_head:
		sprite_head.position.y = -140 + sin(wing_flap_time * 0.8) * 4

	# --- Legs dangle naturally below ---
	if sprite_leg_left and sprite_leg_right:
		# Legs sway slightly as crow flies
		sprite_leg_left.rotation = sin(wing_flap_time * 0.7) * 0.1
		sprite_leg_right.rotation = sin(wing_flap_time * 0.7 + 0.5) * 0.1

		# Legs also move slightly with body bobbing
		var leg_bob := sin(wing_flap_time * 1.3) * 2
		sprite_leg_left.position.y = 250 + leg_bob
		sprite_leg_right.position.y = 250 + leg_bob

	# --- Sword sways (held in claw) ---
	if sprite_sword:
		sprite_sword.rotation = 0.3 + sin(wing_flap_time * 0.6) * 0.12

	# --- Tail streams behind ---
	if sprite_tail:
		# Tail sways gently in the wind
		sprite_tail.rotation = -0.2 + sin(wing_flap_time * 0.5) * 0.08

	# --- SHOOT at player! ---
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


## Spawn a small red projectile that flies toward the target position
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

	# Visual -- small red square (could be a fireball sprite later)
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

	# Add to the scene tree
	get_tree().current_scene.add_child(projectile)

	# Damage the player on body contact
	projectile.body_entered.connect(func(body):
		if body is Player:
			body.hit()
			projectile.queue_free()
	)


## Find the player node via group lookup
func _find_player() -> Node:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

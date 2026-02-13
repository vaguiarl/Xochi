extends EnemyBase
## Seagull enemy -- walks back and forth on ground or platforms.
##
## Exact port from original game.js lines 7001-7072.
##
## Ground type:  walks at 60 px/s, reverses when hitting a wall.
## Platform type: walks at 40 px/s, reverses at platform edges AND walls.
##
## Setup is done via the setup() method after instantiation, which receives
## a Dictionary with type, dir, and (for platform enemies) edge bounds.


# =============================================================================
# PLATFORM PATROL BOUNDS
# =============================================================================

## Left edge of the platform patrol range (only used for platform type).
var platform_left: float = 0.0

## Right edge of the platform patrol range (only used for platform type).
var platform_right: float = 0.0


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready():
	super._ready()


# =============================================================================
# CONFIGURATION
# =============================================================================

## Configure this gull from spawn data.
## Accepted keys:
##   "type"           - "ground" (default) or "platform"
##   "dir"            - initial direction: 1 (right) or -1 (left)
##   "platform_left"  - left patrol bound (platform type only)
##   "platform_right" - right patrol bound (platform type only)
func setup(data: Dictionary):
	enemy_type = data.get("type", "ground")
	dir = data.get("dir", 1)
	speed = 60.0 if enemy_type == "ground" else 40.0

	if enemy_type == "platform":
		platform_left = data.get("platform_left", position.x - 60)
		platform_right = data.get("platform_right", position.x + 60)


# =============================================================================
# PHYSICS
# =============================================================================

func _physics_process(delta):
	if not alive:
		return

	# Apply gravity -- gulls are ground-bound
	if not is_on_floor():
		velocity.y += gravity * delta

	if enemy_type == "platform":
		# Platform enemy: reverse at platform edges
		if position.x <= platform_left:
			dir = 1
		elif position.x >= platform_right:
			dir = -1

		# Also reverse at walls
		if is_on_wall():
			dir *= -1

		velocity.x = speed * dir
	else:
		# Ground enemy: reverse at walls
		if is_on_wall():
			dir *= -1
		velocity.x = speed * dir

	# Flip sprite based on direction
	# (Visual child node -- scale.x flips the entire visual subtree)
	if has_node("Visual"):
		$Visual.scale.x = -1 if dir > 0 else 1

	move_and_slide()

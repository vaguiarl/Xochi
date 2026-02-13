extends CharacterBody2D
## Ahuizotl -- Aztec water monster that patrols at the water surface in
## upscroller levels.
##
## The Ahuizotl is a creature from Aztec mythology: a water dog-monkey hybrid
## with a human hand at the tip of its tail. It lurks at the water's surface
## and drags unwary swimmers to their doom. In Xochi, it replaces the generic
## alligator from the original game.js with something rooted in the
## Mesoamerican setting.
##
## This enemy does NOT extend EnemyBase because it is a fully self-contained
## water creature with custom physics (no gravity, surface tracking, lunging).
## It provides its own hit_by_stomp(), hit_by_attack(), and die() methods so
## the CombatSystem can interact with it, and it detects player contact via
## an Area2D child node rather than relying on the stomp-check loop.
##
## Visual design: procedural ColorRect rig -- no sprites required. The body is
## an elongated dark green shape with a lighter belly, two glowing eyes, a red
## mouth line (brightens when lunging), and a stubby tail nub. Scale is 1.0
## (native pixel size, ~40x14 px body).
##
## State machine:
##   PATROL  -- glide horizontally at the water surface, eyes scanning
##   ALERT   -- player spotted! slow down, eyes turn red (0.5s warning)
##   LUNGE   -- dash toward the player at 250 px/s (max 1s)
##   RETREAT -- return to water surface, 2s cooldown before next alert
##   DEAD    -- stomped or attacked, gray out, sink, queue_free
##
## Collision setup:
##   Layer 8 (Enemies) -- same as EnemyBase
##   Mask 1 | 2 | 4 (World + Platforms + Player)
##
## Required autoloads: Events, GameState, AudioManager


# =============================================================================
# CONSTANTS
# =============================================================================

## Horizontal patrol speed range (randomised per instance for variety).
const PATROL_SPEED_MIN: float = 60.0
const PATROL_SPEED_MAX: float = 80.0

## Speed during the LUNGE dash (px/s).
const LUNGE_SPEED: float = 250.0

## Maximum duration of a lunge before it auto-expires (seconds).
const LUNGE_MAX_DURATION: float = 1.0

## Duration of the ALERT state -- telegraph before lunging (seconds).
const ALERT_DURATION: float = 0.5

## Cooldown in RETREAT before the creature can ALERT again (seconds).
const RETREAT_COOLDOWN: float = 2.0

## Detection radius: player must be within this distance to trigger ALERT.
const DETECT_RADIUS: float = 300.0

## How far above the water surface the body floats (negative = above surface).
const SURFACE_OFFSET: float = -5.0

## Retreat ascent speed (px/s) -- how fast the creature rises back to surface.
const RETREAT_RISE_SPEED: float = 150.0

## Score awarded on kill (stomp or attack).
const KILL_SCORE: int = 100

## Boundary margin -- reverse direction when this close to level edges.
const EDGE_MARGIN: float = 50.0


# =============================================================================
# STATE
# =============================================================================

## Whether this creature is alive and can interact with the world.
var alive: bool = true

## Current AI state.
enum State { PATROL, ALERT, LUNGE, RETREAT, DEAD }
var state: State = State.PATROL

## Time accumulated in the current state (seconds).
var state_timer: float = 0.0

## Current movement direction: 1 = right, -1 = left.
var dir: int = 1

## Horizontal movement speed in px/s (set in setup from PATROL_SPEED range).
var speed: float = 70.0

## Y position of the water surface in world coordinates. Updated each frame
## from the WaterSystem if one is present on the scene tree.
var water_y: float = 9999.0

## Width of the current level (for boundary reversal).
var level_width: float = 2000.0

## Cached player reference (looked up lazily).
var _player: Node = null

## Direction vector captured at the moment of lunge (normalised).
var _lunge_dir: Vector2 = Vector2.ZERO

## Animation timer for idle bob and eye glow effects.
var _anim_time: float = 0.0


# =============================================================================
# VISUAL RIG NODES -- built procedurally in _build_visuals()
# =============================================================================

var _rig: Node2D
var _body_rect: ColorRect
var _belly_rect: ColorRect
var _eye_left: ColorRect
var _eye_right: ColorRect
var _pupil_left: ColorRect
var _pupil_right: ColorRect
var _mouth_rect: ColorRect
var _tail_nub: ColorRect
var _tail_hand: ColorRect

## The Area2D used to detect overlap with the player.
var _hit_area: Area2D


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready():
	# -- Collision configuration --
	collision_layer = 8       # Enemies layer (bit 4)
	collision_mask = 1 | 2    # World + Platforms (no Player on body itself)

	# Register in the enemies group so combat systems and luchador roll
	# can find us via get_nodes_in_group("enemies").
	add_to_group("enemies")

	_build_visuals()
	_build_hit_area()


func _physics_process(delta: float):
	if not alive:
		return

	_anim_time += delta
	state_timer += delta

	# Keep tracking the water surface if a WaterSystem exists.
	_track_water_surface()

	# Find the player once and cache the reference.
	if _player == null or not is_instance_valid(_player):
		_player = _find_player()

	# State machine dispatch.
	match state:
		State.PATROL:
			_state_patrol(delta)
		State.ALERT:
			_state_alert(delta)
		State.LUNGE:
			_state_lunge(delta)
		State.RETREAT:
			_state_retreat(delta)

	# Flip the rig to face movement direction.
	if _rig:
		_rig.scale.x = 1.0 if dir >= 0 else -1.0

	# Subtle idle bob (sin wave on the whole rig, gentle and menacing).
	if _rig and state != State.LUNGE:
		_rig.position.y = sin(_anim_time * 3.0) * 1.5

	move_and_slide()


# =============================================================================
# CONFIGURATION -- called by the spawner after instantiation
# =============================================================================

## Configure this Ahuizotl from spawn data.
## Accepted keys:
##   "dir"         - initial patrol direction: 1 (right) or -1 (left)
##   "speed"       - patrol speed override (default random 60-80)
##   "water_y"     - initial water surface Y position
##   "level_width" - level width for boundary reversal
func setup(data: Dictionary):
	dir = data.get("dir", 1)
	speed = data.get("speed", randf_range(PATROL_SPEED_MIN, PATROL_SPEED_MAX))
	water_y = data.get("water_y", position.y)
	level_width = data.get("level_width", 2000.0)

	# Start at the water surface.
	position.y = water_y + SURFACE_OFFSET


# =============================================================================
# WATER SURFACE TRACKING
# =============================================================================

func _track_water_surface():
	## Finds the WaterSystem on the scene tree and reads its current water_y.
	## This keeps the Ahuizotl glued to the rising water in upscroller levels.
	var ws_nodes = get_tree().get_nodes_in_group("water_system")
	if ws_nodes.size() > 0:
		var ws = ws_nodes[0]
		if ws.has_method("get_water_y"):
			water_y = ws.get_water_y()
			return

	# Fallback: look for a WaterSystem node by class.
	var root = get_tree().current_scene
	if root == null:
		return
	var ws_node = root.get_node_or_null("WaterSystem")
	if ws_node != null and ws_node.has_method("get_water_y"):
		water_y = ws_node.get_water_y()


# =============================================================================
# STATE: PATROL -- cruise along the water surface
# =============================================================================

func _state_patrol(delta: float):
	## Glide horizontally at the water surface. Eyes are yellow-green, mouth is
	## closed (dark line). Reverse at level boundaries.

	# Stick to the water surface.
	position.y = water_y + SURFACE_OFFSET

	# Horizontal movement.
	velocity.x = speed * dir
	velocity.y = 0.0

	# Reverse at level boundaries.
	if position.x < EDGE_MARGIN and dir < 0:
		dir = 1
		position.x = EDGE_MARGIN
	elif position.x > level_width - EDGE_MARGIN and dir > 0:
		dir = -1
		position.x = level_width - EDGE_MARGIN

	# Eye color: calm yellow-green.
	_set_eye_color(Color(0.9, 0.85, 0.1))
	# Mouth: dark closed line.
	if _mouth_rect:
		_mouth_rect.color = Color(0.15, 0.08, 0.05)

	# Player detection -- transition to ALERT if close enough.
	if _player != null and is_instance_valid(_player) and not _player.is_dead:
		var dist: float = global_position.distance_to(_player.global_position)
		# Only alert if player is near/below the water surface (within 80 px
		# above, or below it entirely). Don't bother lunging at a player who
		# is safely high above the water.
		var player_near_water: bool = _player.global_position.y > water_y - 80.0
		if dist < DETECT_RADIUS and player_near_water:
			_enter_state(State.ALERT)


# =============================================================================
# STATE: ALERT -- telegraph the incoming lunge
# =============================================================================

func _state_alert(_delta: float):
	## Slow down, eyes turn red, mouth opens. The player gets a 0.5s warning
	## to get out of the way. Direction adjusts to face the player.

	# Slow patrol speed (decelerate to a crawl).
	velocity.x = speed * dir * 0.25
	velocity.y = 0.0

	# Stay at water surface.
	position.y = water_y + SURFACE_OFFSET

	# Face the player.
	if _player != null and is_instance_valid(_player):
		dir = 1 if _player.global_position.x > global_position.x else -1

	# Visual: angry red eyes, mouth opens.
	var flash: float = sin(_anim_time * 20.0) * 0.5 + 0.5
	_set_eye_color(Color(1.0, 0.1 + flash * 0.2, 0.0))
	if _mouth_rect:
		_mouth_rect.color = Color(0.8 + flash * 0.2, 0.1, 0.05)

	# Transition to LUNGE after the telegraph duration.
	if state_timer >= ALERT_DURATION:
		# Capture lunge direction toward the player's current position.
		if _player != null and is_instance_valid(_player):
			_lunge_dir = (
				_player.global_position - global_position
			).normalized()
		else:
			_lunge_dir = Vector2(dir, 0.0)
		_enter_state(State.LUNGE)


# =============================================================================
# STATE: LUNGE -- dash toward the player!
# =============================================================================

func _state_lunge(_delta: float):
	## Dash along the captured lunge direction at LUNGE_SPEED. The creature
	## leaves the water surface and travels in a straight line. After
	## LUNGE_MAX_DURATION or if it travels beyond a reasonable distance,
	## transition to RETREAT.

	velocity = _lunge_dir * LUNGE_SPEED

	# Visual: bright red eyes, wide open red mouth.
	_set_eye_color(Color(1.0, 0.0, 0.0))
	if _mouth_rect:
		_mouth_rect.color = Color(1.0, 0.15, 0.05)
		_mouth_rect.size.y = 4  # Wider mouth when lunging (open maw)

	# Body darkens slightly during lunge for a menacing silhouette.
	if _body_rect:
		_body_rect.color = Color(0.12, 0.28, 0.1)

	# Expire the lunge after the max duration.
	if state_timer >= LUNGE_MAX_DURATION:
		_enter_state(State.RETREAT)


# =============================================================================
# STATE: RETREAT -- return to the water surface
# =============================================================================

func _state_retreat(_delta: float):
	## Rise (or sink) back to the water surface, then wait for the cooldown
	## before resuming patrol. Eyes return to yellow-green.

	var target_y: float = water_y + SURFACE_OFFSET
	var y_diff: float = target_y - position.y

	if absf(y_diff) > 2.0:
		# Move toward the surface.
		velocity.y = sign(y_diff) * RETREAT_RISE_SPEED
		velocity.x = speed * dir * 0.3  # Gentle drift while returning
	else:
		# Arrived at surface -- lock Y and drift.
		position.y = target_y
		velocity.y = 0.0
		velocity.x = speed * dir * 0.4

	# Restore visuals to calm state progressively.
	var calm_t: float = clampf(state_timer / RETREAT_COOLDOWN, 0.0, 1.0)
	_set_eye_color(Color(1.0, 0.1, 0.0).lerp(Color(0.9, 0.85, 0.1), calm_t))
	if _mouth_rect:
		_mouth_rect.color = Color(0.8, 0.1, 0.05).lerp(Color(0.15, 0.08, 0.05), calm_t)
		_mouth_rect.size.y = lerpf(4.0, 2.0, calm_t)

	if _body_rect:
		_body_rect.color = Color(0.12, 0.28, 0.1).lerp(Color(0.15, 0.32, 0.12), calm_t)

	# Transition back to PATROL after the cooldown.
	if state_timer >= RETREAT_COOLDOWN:
		_enter_state(State.PATROL)


# =============================================================================
# STATE TRANSITIONS
# =============================================================================

func _enter_state(new_state: State):
	state = new_state
	state_timer = 0.0

	# Reset mouth size when leaving LUNGE.
	if new_state != State.LUNGE and _mouth_rect:
		_mouth_rect.size.y = 2


# =============================================================================
# DAMAGE RESPONSES -- compatible with CombatSystem and LuchadorSystem
# =============================================================================

## Called when the player stomps on this creature (falling from above).
## Grays out, awards score, and destroys after 300 ms.
func hit_by_stomp():
	if not alive:
		return
	alive = false
	state = State.DEAD

	# Gray tint, stop all movement, disable physics.
	modulate = Color(0.53, 0.53, 0.53)
	velocity = Vector2.ZERO
	set_physics_process(false)

	# Disable the hit area so it cannot damage the player post-mortem.
	if _hit_area:
		_hit_area.set_deferred("monitoring", false)

	# Score.
	GameState.score += KILL_SCORE
	Events.score_changed.emit(GameState.score)

	# SFX.
	AudioManager.play_sfx("stomp")

	# Sink slightly then destroy.
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y + 20.0, 0.3)
	tween.tween_callback(queue_free)


## Called when the player's melee attack or thunderbolt hits this creature.
## Knockback, red tint, awards score, and destroys after 500 ms.
func hit_by_attack():
	if not alive:
		return
	alive = false
	state = State.DEAD

	# Knock the corpse away from its facing direction.
	velocity = Vector2(dir * -200, -200)
	modulate = Color(1, 0.5, 0.5)
	set_physics_process(false)

	# Disable the hit area.
	if _hit_area:
		_hit_area.set_deferred("monitoring", false)

	# Score.
	GameState.score += KILL_SCORE
	Events.score_changed.emit(GameState.score)

	# SFX.
	AudioManager.play_sfx("stomp")

	# Destroy after 500 ms.
	await get_tree().create_timer(0.5).timeout
	queue_free()


## Generic instant death -- no animation, no score. Used for cleanup.
func die():
	if not alive:
		return
	alive = false
	state = State.DEAD
	queue_free()


# =============================================================================
# PLAYER CONTACT DETECTION -- Area2D overlap
# =============================================================================

func _build_hit_area():
	## Creates an Area2D child that detects overlap with the player's
	## CharacterBody2D. When the player touches the Ahuizotl, the player
	## takes damage. When the player lands on top of it (stomp), the
	## creature dies instead.

	_hit_area = Area2D.new()
	_hit_area.name = "HitArea"
	_hit_area.collision_layer = 0      # The area itself does not occupy a layer
	_hit_area.collision_mask = 4       # Detect Player layer (bit 3)
	_hit_area.monitoring = true
	_hit_area.monitorable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40.0, 14.0)
	shape.shape = rect
	_hit_area.add_child(shape)
	add_child(_hit_area)

	_hit_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node):
	## Triggered when a physics body (hopefully the player) overlaps the
	## hit area. Determines stomp vs. contact damage.
	if not alive:
		return
	if not body is Player:
		return

	var player_node: Player = body as Player

	# Stomp check: player is falling and above the creature.
	var is_stomping: bool = (
		player_node.velocity.y > 0.0
		and not player_node.is_on_floor()
		and player_node.global_position.y < global_position.y - 2.0
	)

	if is_stomping:
		hit_by_stomp()
		player_node.stomp_bounce()
	else:
		# Contact damage -- the Ahuizotl bites!
		player_node.hit()


# =============================================================================
# PROCEDURAL VISUAL RIG -- Aztec water creature built from ColorRects
# =============================================================================

func _build_visuals():
	## Constructs the Ahuizotl's visual appearance entirely from ColorRects.
	## The creature looks like a low-profile aquatic predator: elongated dark
	## green body barely breaking the water surface, with glowing eyes and a
	## menacing mouth line. A small nub tail with a tiny "hand" shape hints
	## at the mythological origin.
	##
	## All positions are relative to the rig's origin (center of body).
	## Total footprint: roughly 48 x 16 px.

	_rig = Node2D.new()
	_rig.name = "Rig"
	add_child(_rig)

	# --- Collision shape (on the CharacterBody2D, not the rig) ---
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40.0, 14.0)
	collision.shape = shape
	add_child(collision)

	# --- Body: elongated dark green oval (approximated as a rect) ---
	_body_rect = ColorRect.new()
	_body_rect.size = Vector2(40.0, 14.0)
	_body_rect.position = Vector2(-20.0, -7.0)
	_body_rect.color = Color(0.15, 0.32, 0.12)  # Dark swamp green
	_rig.add_child(_body_rect)

	# --- Belly: lighter green underside ---
	_belly_rect = ColorRect.new()
	_belly_rect.size = Vector2(32.0, 5.0)
	_belly_rect.position = Vector2(-16.0, 2.0)
	_belly_rect.color = Color(0.35, 0.55, 0.25)  # Lighter green
	_rig.add_child(_belly_rect)

	# --- Snout: slightly protruding front ---
	var snout := ColorRect.new()
	snout.size = Vector2(8.0, 10.0)
	snout.position = Vector2(18.0, -5.0)
	snout.color = Color(0.18, 0.35, 0.14)  # Slightly different green
	_rig.add_child(snout)

	# --- Eye left (top of head, rear) ---
	_eye_left = ColorRect.new()
	_eye_left.size = Vector2(5.0, 4.0)
	_eye_left.position = Vector2(8.0, -8.0)
	_eye_left.color = Color(0.9, 0.85, 0.1)  # Yellow-green
	_eye_left.z_index = 2
	_rig.add_child(_eye_left)

	# --- Eye right (top of head, front) ---
	_eye_right = ColorRect.new()
	_eye_right.size = Vector2(5.0, 4.0)
	_eye_right.position = Vector2(16.0, -8.0)
	_eye_right.color = Color(0.9, 0.85, 0.1)
	_eye_right.z_index = 2
	_rig.add_child(_eye_right)

	# --- Pupil left (slit pupil inside eye) ---
	_pupil_left = ColorRect.new()
	_pupil_left.size = Vector2(2.0, 3.0)
	_pupil_left.position = Vector2(9.5, -7.5)
	_pupil_left.color = Color(0.05, 0.05, 0.0)
	_pupil_left.z_index = 3
	_rig.add_child(_pupil_left)

	# --- Pupil right ---
	_pupil_right = ColorRect.new()
	_pupil_right.size = Vector2(2.0, 3.0)
	_pupil_right.position = Vector2(17.5, -7.5)
	_pupil_right.color = Color(0.05, 0.05, 0.0)
	_pupil_right.z_index = 3
	_rig.add_child(_pupil_right)

	# --- Mouth line (runs along the front of the snout) ---
	_mouth_rect = ColorRect.new()
	_mouth_rect.size = Vector2(12.0, 2.0)
	_mouth_rect.position = Vector2(14.0, 1.0)
	_mouth_rect.color = Color(0.15, 0.08, 0.05)  # Dark line
	_mouth_rect.z_index = 1
	_rig.add_child(_mouth_rect)

	# --- Nostrils (two tiny dots on the snout tip) ---
	var nostril_left := ColorRect.new()
	nostril_left.size = Vector2(2.0, 2.0)
	nostril_left.position = Vector2(24.0, -4.0)
	nostril_left.color = Color(0.08, 0.15, 0.06)
	_rig.add_child(nostril_left)

	var nostril_right := ColorRect.new()
	nostril_right.size = Vector2(2.0, 2.0)
	nostril_right.position = Vector2(24.0, -1.0)
	nostril_right.color = Color(0.08, 0.15, 0.06)
	_rig.add_child(nostril_right)

	# --- Tail nub (rear of body) ---
	_tail_nub = ColorRect.new()
	_tail_nub.size = Vector2(8.0, 8.0)
	_tail_nub.position = Vector2(-26.0, -4.0)
	_tail_nub.color = Color(0.13, 0.28, 0.10)
	_rig.add_child(_tail_nub)

	# --- Tail "hand" (the mythological hand on the tail tip) ---
	# Represented as a tiny lighter shape at the end of the tail.
	_tail_hand = ColorRect.new()
	_tail_hand.size = Vector2(5.0, 6.0)
	_tail_hand.position = Vector2(-32.0, -3.0)
	_tail_hand.color = Color(0.55, 0.45, 0.35)  # Skin/tan color
	_tail_hand.z_index = 1
	_rig.add_child(_tail_hand)

	# --- Tiny "fingers" on the tail hand (3 small rects) ---
	for i in 3:
		var finger := ColorRect.new()
		finger.size = Vector2(2.0, 3.0)
		finger.position = Vector2(-33.0 - i * 2.0, -2.0 + i * 1.5)
		finger.color = Color(0.5, 0.4, 0.3)
		finger.z_index = 1
		_rig.add_child(finger)

	# --- Dorsal ridge (bumps along the spine for texture) ---
	for i in 4:
		var bump := ColorRect.new()
		bump.size = Vector2(4.0, 3.0)
		bump.position = Vector2(-10.0 + i * 8.0, -9.0)
		bump.color = Color(0.12, 0.25, 0.09)
		_rig.add_child(bump)

	# --- Water ripple lines (decorative, sit at the creature's waterline) ---
	for i in 3:
		var ripple := ColorRect.new()
		ripple.size = Vector2(10.0 + i * 4.0, 1.0)
		ripple.position = Vector2(-14.0 - i * 3.0, 6.0 + i * 2.0)
		ripple.color = Color(0.4, 0.7, 0.85, 0.3 - i * 0.08)
		ripple.z_index = -1
		_rig.add_child(ripple)


# =============================================================================
# VISUAL HELPERS
# =============================================================================

func _set_eye_color(color: Color):
	if _eye_left:
		_eye_left.color = color
	if _eye_right:
		_eye_right.color = color


# =============================================================================
# UTILITY
# =============================================================================

## Find the player node via group lookup.
func _find_player() -> Node:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

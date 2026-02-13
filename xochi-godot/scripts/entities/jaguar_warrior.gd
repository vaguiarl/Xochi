extends CharacterBody2D
## Jaguar Warrior (Ocelotl) -- elite Aztec ground enemy with 4-state AI.
##
## The Ocelotl is an Aztec Jaguar Knight: a fearsome warrior draped in jaguar
## skin, wielding an obsidian macuahuitl club. In Aztec society these were the
## most decorated soldiers, earning their rank through battlefield captures.
## In Xochi, the Jaguar Warrior is a mid-tier elite enemy that patrols the
## ground, stalks the player when detected, and pounces with a devastating
## leap attack.
##
## This enemy does NOT extend EnemyBase because it has a complex multi-state
## AI (patrol -> stalk -> pounce -> recover) with a 2-hit health system,
## procedural damage indicators, and state-driven animation. It provides its
## own hit_by_stomp(), hit_by_attack(), and die() methods for compatibility
## with the CombatSystem and LuchadorSystem (duck typing via has_method).
##
## Visual design: procedural ColorRect rig -- no sprites required. An amber/
## gold jaguar body with dark spots, obsidian helmet crest, glowing eyes that
## change color by AI state, white fangs, and a macuahuitl obsidian club.
## Total footprint: roughly 30x24 px.
##
## State machine:
##   PATROL  -- walk back and forth, scan for player (speed 45 px/s)
##   STALK   -- crouch and slowly approach player (speed 30 px/s, 0.8s)
##   POUNCE  -- leap at player in an arc (300 px/s horizontal, 0.6s max)
##   RECOVER -- land dizzy, vulnerability window (1.2s, speed 0)
##   DEAD    -- gray tint, shrink, queue_free after 0.4s
##
## Health: 2 hits to kill. At hp=1 the body darkens and extra damage spots
## appear. At hp=0 the warrior enters the DEAD state.
##
## Collision setup:
##   Layer 8 (Enemies) -- same as all Xochi enemies
##   Mask 1 | 2 (World + Platforms)
##
## Required autoloads: Events, GameState, AudioManager


# =============================================================================
# CONSTANTS
# =============================================================================

## Horizontal patrol speed in px/s.
const PATROL_SPEED: float = 45.0

## Horizontal speed while stalking the player in px/s.
const STALK_SPEED: float = 30.0

## Duration of the STALK state before transitioning to POUNCE (seconds).
const STALK_DURATION: float = 0.8

## Horizontal velocity during pounce (px/s, multiplied by direction).
const POUNCE_VELOCITY_X: float = 300.0

## Vertical velocity at pounce start (negative = upward arc).
const POUNCE_VELOCITY_Y: float = -200.0

## Maximum airborne time for the pounce before forced recovery (seconds).
const POUNCE_MAX_DURATION: float = 0.6

## Duration of the RECOVER state -- the vulnerability window (seconds).
const RECOVER_DURATION: float = 1.2

## Duration of the DEAD state animation before queue_free (seconds).
const DEAD_DURATION: float = 0.4

## Gravity applied to this enemy in px/s^2.
const GRAVITY: float = 900.0

## Maximum hit points -- takes this many hits to kill.
const MAX_HP: int = 2

## Score awarded on kill (stomp or attack).
const KILL_SCORE: int = 200

## Player detection range: horizontal distance in px (each side).
const DETECT_RANGE_X: float = 250.0

## Player detection range: vertical distance in px (above and below).
const DETECT_RANGE_Y: float = 100.0

## Boundary margin -- reverse patrol direction at level edges (px).
const EDGE_MARGIN: float = 50.0

## Wobble amplitude during RECOVER state (radians).
const RECOVER_WOBBLE_AMP: float = 0.1

## Wobble frequency during RECOVER state (rad/s).
const RECOVER_WOBBLE_FREQ: float = 12.0


# =============================================================================
# STATE
# =============================================================================

## Whether this enemy is alive and can interact with the world.
var alive: bool = true

## Current hit points. Starts at MAX_HP (2), decremented by stomps/attacks.
var hp: int = MAX_HP

## Current AI state.
enum State { PATROL, STALK, POUNCE, RECOVER, DEAD }
var state: State = State.PATROL

## Time accumulated in the current state (seconds).
var state_timer: float = 0.0

## Current movement direction: 1 = right, -1 = left.
var dir: int = 1

## Horizontal movement speed in px/s (set by setup()).
var speed: float = PATROL_SPEED

## Width of the current level (for boundary reversal).
var level_width: float = 2000.0

## Cached player reference (looked up lazily).
var _player: Node = null

## Whether the player is inside the detection Area2D.
var _player_in_range: bool = false

## Animation timer for idle bob and visual effects.
var _anim_time: float = 0.0


# =============================================================================
# VISUAL RIG NODES -- built procedurally in _build_visuals()
# =============================================================================

var _visual: Node2D           # Root of the visual rig (flipped for direction)
var _body_rect: ColorRect     # Main jaguar body (30x20)
var _head_rect: ColorRect     # Head (14x12)
var _eye_left: ColorRect      # Left eye (4x3)
var _eye_right: ColorRect     # Right eye (4x3)
var _pupil_left: ColorRect    # Left pupil (2x2)
var _pupil_right: ColorRect   # Right pupil (2x2)
var _helmet_crest: ColorRect  # Obsidian helmet crest (8x6)
var _fang_left: ColorRect     # Left fang (2x4)
var _fang_right: ColorRect    # Right fang (2x4)
var _leg_left: ColorRect      # Left leg (6x8)
var _leg_right: ColorRect     # Right leg (6x8)
var _weapon: ColorRect        # Macuahuitl club shaft (4x14)
var _weapon_edge: ColorRect   # Obsidian blade edge (2x10)
var _spots: Array[ColorRect] = []       # Jaguar spots on body
var _damage_spots: Array[ColorRect] = [] # Extra dark spots shown at hp=1

## The Area2D for player proximity detection (large, 500x200).
var _detect_area: Area2D

## The Area2D for contact damage (body-sized, tighter).
var _hit_area: Area2D


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready():
	# -- Collision configuration --
	collision_layer = 8       # Enemies layer (bit 4)
	collision_mask = 1 | 2    # World + Platforms

	# Register in the enemies group so combat systems can find us.
	add_to_group("enemies")

	_build_visuals()
	_build_detect_area()
	_build_hit_area()


func _physics_process(delta: float):
	if not alive:
		return

	_anim_time += delta
	state_timer += delta

	# Apply gravity -- Jaguar Warriors are ground-bound.
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Find the player once and cache the reference.
	if _player == null or not is_instance_valid(_player):
		_player = _find_player()

	# State machine dispatch.
	match state:
		State.PATROL:
			_state_patrol(delta)
		State.STALK:
			_state_stalk(delta)
		State.POUNCE:
			_state_pounce(delta)
		State.RECOVER:
			_state_recover(delta)

	# Flip the visual rig to face movement direction.
	if _visual:
		_visual.scale.x = 1.0 if dir >= 0 else -1.0

	# State-driven animation.
	_animate(delta)

	move_and_slide()


# =============================================================================
# CONFIGURATION -- called by the spawner after instantiation
# =============================================================================

## Configure this Jaguar Warrior from spawn data.
## Accepted keys:
##   "dir"         - initial patrol direction: 1 (right) or -1 (left)
##   "speed"       - patrol speed override (default PATROL_SPEED)
##   "level_width" - level width for boundary reversal
func setup(data: Dictionary):
	dir = data.get("dir", 1)
	speed = data.get("speed", PATROL_SPEED)
	level_width = data.get("level_width", 2000.0)


# =============================================================================
# STATE: PATROL -- walk back and forth, scan for player
# =============================================================================

func _state_patrol(_delta: float):
	## Walk horizontally, apply gravity, reverse at walls and level edges.
	## Scan for the player within the detection zone.

	# Horizontal movement at patrol speed.
	velocity.x = speed * dir

	# Reverse at walls.
	if is_on_wall():
		dir *= -1

	# Reverse at level boundaries.
	if position.x < EDGE_MARGIN and dir < 0:
		dir = 1
		position.x = EDGE_MARGIN
	elif position.x > level_width - EDGE_MARGIN and dir > 0:
		dir = -1
		position.x = level_width - EDGE_MARGIN

	# Eye color: calm green (PATROL).
	_set_eye_color(Color(0.2, 0.9, 0.2))

	# Check if player is within detection range and transition to STALK.
	if _player_in_range and _player != null and is_instance_valid(_player):
		if not _player.is_dead:
			# Face the player before stalking.
			dir = 1 if _player.global_position.x > global_position.x else -1
			_enter_state(State.STALK)


# =============================================================================
# STATE: STALK -- crouch and slowly approach
# =============================================================================

func _state_stalk(_delta: float):
	## Crouch down (visual squash), slowly approach the player's direction.
	## Eyes turn yellow. After STALK_DURATION, pounce.

	# Update facing direction to track the player.
	if _player != null and is_instance_valid(_player):
		dir = 1 if _player.global_position.x > global_position.x else -1

	# Slow approach.
	velocity.x = STALK_SPEED * dir

	# Eye color: warning yellow (STALK).
	_set_eye_color(Color(1.0, 0.9, 0.1))

	# Transition to POUNCE after the stalk duration.
	if state_timer >= STALK_DURATION:
		_enter_state(State.POUNCE)


# =============================================================================
# STATE: POUNCE -- leap at the player in an arc
# =============================================================================

func _state_pounce(_delta: float):
	## Launch in an arc toward the player. Damages on contact (handled by
	## the _hit_area). After POUNCE_MAX_DURATION or hitting a wall, recover.

	# Eye color: bright red (POUNCE -- maximum aggression).
	_set_eye_color(Color(1.0, 0.15, 0.1))

	# The velocity was set on state entry (_enter_state handles the launch).
	# Gravity is applied in _physics_process so the arc happens naturally.

	# End pounce if we hit a wall or the timer expires.
	if is_on_wall() or state_timer >= POUNCE_MAX_DURATION:
		_enter_state(State.RECOVER)

	# Also end pounce if we land back on the floor (after being airborne).
	# Only check after a brief moment so the initial launch isn't cancelled.
	if state_timer > 0.1 and is_on_floor():
		_enter_state(State.RECOVER)


# =============================================================================
# STATE: RECOVER -- dizzy landing, vulnerability window
# =============================================================================

func _state_recover(_delta: float):
	## Stand still, wobble. This is the window where the player can safely
	## stomp or attack without getting contact-damaged.

	# No horizontal movement during recovery.
	velocity.x = 0.0

	# Eye color: dim/dazed (recovering).
	_set_eye_color(Color(0.5, 0.5, 0.3))

	# Transition back to PATROL after the recovery duration.
	if state_timer >= RECOVER_DURATION:
		_enter_state(State.PATROL)


# =============================================================================
# STATE TRANSITIONS
# =============================================================================

func _enter_state(new_state: State):
	state = new_state
	state_timer = 0.0

	match new_state:
		State.PATROL:
			# Reset visual transforms that STALK/POUNCE/RECOVER may have set.
			if _visual:
				_visual.scale.y = 1.0
				_visual.scale.x = 1.0 if dir >= 0 else -1.0
				_visual.rotation = 0.0

		State.STALK:
			# No special velocity -- handled in _state_stalk.
			pass

		State.POUNCE:
			# Launch the warrior into the air toward the player.
			velocity.x = dir * POUNCE_VELOCITY_X
			velocity.y = POUNCE_VELOCITY_Y

		State.RECOVER:
			# Kill horizontal momentum on landing.
			velocity.x = 0.0

		State.DEAD:
			# Handled in _start_death_sequence().
			pass


# =============================================================================
# ANIMATION -- state-driven visual effects
# =============================================================================

func _animate(_delta: float):
	if _visual == null:
		return

	match state:
		State.PATROL:
			# Gentle body bob via sin(time) on the visual's Y position.
			_visual.position.y = sin(_anim_time * 3.0) * 2.0
			_visual.rotation = 0.0
			# Ensure normal proportions (reset from other states).
			_visual.scale.y = 1.0
			var abs_x := absf(_visual.scale.x)
			_visual.scale.x = abs_x if dir >= 0 else -abs_x

		State.STALK:
			# Crouch squash: shorter and wider, menacing.
			_visual.scale.y = 0.85
			var stalk_abs_x := 1.1
			_visual.scale.x = stalk_abs_x if dir >= 0 else -stalk_abs_x
			_visual.position.y = 2.0  # Lowered stance
			_visual.rotation = 0.0

		State.POUNCE:
			# Stretch: taller and narrower for the leap.
			_visual.scale.y = 1.15
			var pounce_abs_x := 0.9
			_visual.scale.x = pounce_abs_x if dir >= 0 else -pounce_abs_x
			_visual.position.y = 0.0
			# Rotate the weapon forward (handled in _weapon rotation below).
			if _weapon:
				_weapon.rotation = -0.3 if dir >= 0 else 0.3
			if _weapon_edge:
				_weapon_edge.rotation = -0.3 if dir >= 0 else 0.3

		State.RECOVER:
			# Wobble: rotation oscillates back and forth (dizzy).
			_visual.rotation = sin(_anim_time * RECOVER_WOBBLE_FREQ) * RECOVER_WOBBLE_AMP
			_visual.scale.y = 1.0
			var recover_abs_x := 1.0
			_visual.scale.x = recover_abs_x if dir >= 0 else -recover_abs_x
			_visual.position.y = 0.0
			# Reset weapon rotation.
			if _weapon:
				_weapon.rotation = 0.0
			if _weapon_edge:
				_weapon_edge.rotation = 0.0

	# Reset weapon rotation for non-pounce states (safety net).
	if state != State.POUNCE:
		if _weapon:
			_weapon.rotation = 0.0
		if _weapon_edge:
			_weapon_edge.rotation = 0.0


# =============================================================================
# DAMAGE RESPONSES -- compatible with CombatSystem and LuchadorSystem
# =============================================================================

## Called when the player stomps on this warrior (falling from above).
## Reduces hp by 1. If hp reaches 0, awards score and starts death sequence.
## Otherwise applies hit feedback and bounces the player.
func hit_by_stomp():
	if not alive:
		return

	hp -= 1

	if hp <= 0:
		# Final blow -- die with score and effects.
		alive = false
		state = State.DEAD

		# Disable the hit area so it cannot damage the player post-mortem.
		if _hit_area:
			_hit_area.set_deferred("monitoring", false)
		if _detect_area:
			_detect_area.set_deferred("monitoring", false)

		# Score.
		GameState.score += KILL_SCORE
		Events.score_changed.emit(GameState.score)

		# SFX.
		AudioManager.play_sfx("stomp")

		_start_death_sequence()
	else:
		# Survived the hit -- show damage and enter recovery.
		AudioManager.play_sfx("stomp")
		_apply_damage_visuals()
		_enter_state(State.RECOVER)


## Called when the player's melee attack or thunderbolt hits this warrior.
## Reduces hp by 1. If hp reaches 0, awards score with knockback death.
## Otherwise applies damage feedback and brief knockback.
func hit_by_attack():
	if not alive:
		return

	hp -= 1

	if hp <= 0:
		# Final blow -- die with knockback and score.
		alive = false
		state = State.DEAD

		# Knockback the corpse away from the attacker.
		velocity = Vector2(dir * -200, -200)
		modulate = Color(1, 0.5, 0.5)

		# Disable hit areas.
		if _hit_area:
			_hit_area.set_deferred("monitoring", false)
		if _detect_area:
			_detect_area.set_deferred("monitoring", false)

		# Score.
		GameState.score += KILL_SCORE
		Events.score_changed.emit(GameState.score)

		# SFX.
		AudioManager.play_sfx("stomp")

		_start_death_sequence()
	else:
		# Survived -- knockback, damage visuals, and enter recovery.
		velocity.x = dir * -120
		velocity.y = -80
		AudioManager.play_sfx("stomp")
		_apply_damage_visuals()
		_enter_state(State.RECOVER)


## Generic instant death -- no animation, no score. Used for cleanup.
func die():
	if not alive:
		return
	alive = false
	state = State.DEAD

	if _hit_area:
		_hit_area.set_deferred("monitoring", false)
	if _detect_area:
		_detect_area.set_deferred("monitoring", false)

	queue_free()


# =============================================================================
# DEATH SEQUENCE
# =============================================================================

func _start_death_sequence():
	## Gray tint, shrink to nothing, then queue_free. This runs for both
	## stomp and attack kills after hp reaches 0.

	# Gray out.
	modulate = Color(0.53, 0.53, 0.53)
	velocity = Vector2.ZERO
	set_physics_process(false)

	# Shrink and fade.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), DEAD_DURATION)
	tween.tween_property(self, "modulate:a", 0.0, DEAD_DURATION)
	tween.chain().tween_callback(queue_free)


# =============================================================================
# DAMAGE VISUALS -- shown when hp drops below MAX_HP
# =============================================================================

func _apply_damage_visuals():
	## Darken the body and reveal extra damage spots to telegraph that
	## the warrior has been wounded. Called when hp drops to 1.

	if _body_rect:
		# Darken the body amber to a bruised brownish-gold.
		_body_rect.color = Color(0.6, 0.4, 0.1)

	if _head_rect:
		_head_rect.color = Color(0.55, 0.35, 0.08)

	# Show pre-built damage spots (hidden until first hit).
	for spot in _damage_spots:
		spot.visible = true


# =============================================================================
# PLAYER DETECTION -- Area2D for proximity scanning
# =============================================================================

func _build_detect_area():
	## Creates a large Area2D child (500x200 px, centered) for detecting
	## when the player enters stalking range. This covers 250px to each
	## side horizontally and 100px above/below vertically.

	_detect_area = Area2D.new()
	_detect_area.name = "DetectArea"
	_detect_area.collision_layer = 0    # Does not occupy any layer
	_detect_area.collision_mask = 4     # Detect Player layer (bit 3)
	_detect_area.monitoring = true
	_detect_area.monitorable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(DETECT_RANGE_X * 2.0, DETECT_RANGE_Y * 2.0)
	shape.shape = rect
	_detect_area.add_child(shape)
	add_child(_detect_area)

	_detect_area.body_entered.connect(_on_detect_body_entered)
	_detect_area.body_exited.connect(_on_detect_body_exited)


func _on_detect_body_entered(body: Node):
	if body is Player:
		_player_in_range = true
		_player = body


func _on_detect_body_exited(body: Node):
	if body is Player:
		_player_in_range = false


# =============================================================================
# CONTACT DAMAGE -- Area2D for body collision with player
# =============================================================================

func _build_hit_area():
	## Creates a body-sized Area2D child for inflicting contact damage.
	## The Jaguar Warrior damages the player on touch EXCEPT during the
	## RECOVER state (vulnerability window) and DEAD state.
	## If the player is falling from above, it counts as a stomp instead.

	_hit_area = Area2D.new()
	_hit_area.name = "HitArea"
	_hit_area.collision_layer = 0    # Does not occupy any layer
	_hit_area.collision_mask = 4     # Detect Player layer (bit 3)
	_hit_area.monitoring = true
	_hit_area.monitorable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28.0, 20.0)  # Body-sized hitbox
	shape.shape = rect
	_hit_area.add_child(shape)
	add_child(_hit_area)

	_hit_area.body_entered.connect(_on_hit_body_entered)


func _on_hit_body_entered(body: Node):
	## Determines whether player contact is a stomp or contact damage.
	if not alive:
		return
	if not body is Player:
		return
	if state == State.DEAD or state == State.RECOVER:
		return

	var player_node: Player = body as Player
	if player_node.is_dead:
		return

	# Stomp check: player is falling and positioned above the warrior.
	var is_stomping: bool = (
		player_node.velocity.y > 0.0
		and not player_node.is_on_floor()
		and player_node.global_position.y < global_position.y - 2.0
	)

	if is_stomping:
		# Let the stomp be handled via hit_by_stomp + player bounce.
		hit_by_stomp()
		player_node.stomp_bounce()
	else:
		# Contact damage -- the Jaguar Warrior slashes!
		player_node.hit()


# =============================================================================
# PROCEDURAL VISUAL RIG -- Aztec Jaguar Knight built from ColorRects
# =============================================================================

func _build_visuals():
	## Constructs the Jaguar Warrior's visual appearance entirely from
	## ColorRects. The warrior looks like a stocky, amber-gold figure in
	## jaguar skin with dark spots, an obsidian helmet crest, glowing eyes,
	## white fangs, and a macuahuitl obsidian war club.
	##
	## All positions are relative to the visual rig's origin (center of body).
	## Total footprint: roughly 30x24 px.

	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)

	# --- Collision shape (on the CharacterBody2D, not the rig) ---
	var collision := CollisionShape2D.new()
	var col_shape := RectangleShape2D.new()
	col_shape.size = Vector2(28.0, 20.0)
	collision.shape = col_shape
	add_child(collision)

	# --- Legs: two amber pillars at the bottom, slightly spread ---
	_leg_left = ColorRect.new()
	_leg_left.size = Vector2(6.0, 8.0)
	_leg_left.position = Vector2(-10.0, 2.0)
	_leg_left.color = Color(0.85, 0.65, 0.15)  # Amber
	_visual.add_child(_leg_left)

	_leg_right = ColorRect.new()
	_leg_right.size = Vector2(6.0, 8.0)
	_leg_right.position = Vector2(4.0, 2.0)
	_leg_right.color = Color(0.85, 0.65, 0.15)
	_visual.add_child(_leg_right)

	# --- Body: main jaguar body (30x20) centered ---
	_body_rect = ColorRect.new()
	_body_rect.size = Vector2(30.0, 20.0)
	_body_rect.position = Vector2(-15.0, -14.0)
	_body_rect.color = Color(0.85, 0.65, 0.15)  # Amber/gold jaguar skin
	_body_rect.z_index = 1
	_visual.add_child(_body_rect)

	# --- Jaguar spots: 5 small dark brown patches scattered on body ---
	var spot_positions := [
		Vector2(-8.0, -10.0),
		Vector2(2.0, -6.0),
		Vector2(-4.0, -2.0),
		Vector2(8.0, -10.0),
		Vector2(5.0, -3.0),
	]
	for spot_pos in spot_positions:
		var spot := ColorRect.new()
		spot.size = Vector2(4.0, 4.0)
		spot.position = spot_pos
		spot.color = Color(0.35, 0.2, 0.05)  # Dark brown
		spot.z_index = 2
		_visual.add_child(spot)
		_spots.append(spot)

	# --- Extra damage spots (hidden until hp=1) ---
	var damage_spot_positions := [
		Vector2(-6.0, -7.0),
		Vector2(0.0, -11.0),
		Vector2(6.0, -5.0),
	]
	for dspot_pos in damage_spot_positions:
		var dspot := ColorRect.new()
		dspot.size = Vector2(5.0, 5.0)
		dspot.position = dspot_pos
		dspot.color = Color(0.2, 0.1, 0.02)  # Very dark brown -- bruise marks
		dspot.z_index = 3
		dspot.visible = false  # Hidden until damaged
		_visual.add_child(dspot)
		_damage_spots.append(dspot)

	# --- Head: slightly darker amber, at front ---
	_head_rect = ColorRect.new()
	_head_rect.size = Vector2(14.0, 12.0)
	_head_rect.position = Vector2(8.0, -16.0)
	_head_rect.color = Color(0.75, 0.55, 0.1)  # Darker amber
	_head_rect.z_index = 4
	_visual.add_child(_head_rect)

	# --- Helmet crest: dark obsidian block on top of head ---
	_helmet_crest = ColorRect.new()
	_helmet_crest.size = Vector2(8.0, 6.0)
	_helmet_crest.position = Vector2(11.0, -22.0)
	_helmet_crest.color = Color(0.15, 0.15, 0.2)  # Obsidian dark
	_helmet_crest.z_index = 5
	_visual.add_child(_helmet_crest)

	# --- Eyes: two glowing rects (color changes by state) ---
	_eye_left = ColorRect.new()
	_eye_left.size = Vector2(4.0, 3.0)
	_eye_left.position = Vector2(10.0, -14.0)
	_eye_left.color = Color(0.2, 0.9, 0.2)  # Green (PATROL default)
	_eye_left.z_index = 6
	_visual.add_child(_eye_left)

	_eye_right = ColorRect.new()
	_eye_right.size = Vector2(4.0, 3.0)
	_eye_right.position = Vector2(16.0, -14.0)
	_eye_right.color = Color(0.2, 0.9, 0.2)
	_eye_right.z_index = 6
	_visual.add_child(_eye_right)

	# --- Pupils: two small black dots inside the eyes ---
	_pupil_left = ColorRect.new()
	_pupil_left.size = Vector2(2.0, 2.0)
	_pupil_left.position = Vector2(11.0, -13.5)
	_pupil_left.color = Color(0.0, 0.0, 0.0)
	_pupil_left.z_index = 7
	_visual.add_child(_pupil_left)

	_pupil_right = ColorRect.new()
	_pupil_right.size = Vector2(2.0, 2.0)
	_pupil_right.position = Vector2(17.0, -13.5)
	_pupil_right.color = Color(0.0, 0.0, 0.0)
	_pupil_right.z_index = 7
	_visual.add_child(_pupil_right)

	# --- Fangs: two white rectangles hanging from head bottom ---
	_fang_left = ColorRect.new()
	_fang_left.size = Vector2(2.0, 4.0)
	_fang_left.position = Vector2(11.0, -5.0)
	_fang_left.color = Color(0.95, 0.95, 0.9)  # Off-white
	_fang_left.z_index = 5
	_visual.add_child(_fang_left)

	_fang_right = ColorRect.new()
	_fang_right.size = Vector2(2.0, 4.0)
	_fang_right.position = Vector2(17.0, -5.0)
	_fang_right.color = Color(0.95, 0.95, 0.9)
	_fang_right.z_index = 5
	_visual.add_child(_fang_right)

	# --- Weapon: macuahuitl club shaft (dark obsidian) ---
	_weapon = ColorRect.new()
	_weapon.size = Vector2(4.0, 14.0)
	_weapon.position = Vector2(20.0, -12.0)
	_weapon.color = Color(0.1, 0.1, 0.15)  # Dark obsidian
	_weapon.z_index = 3
	_visual.add_child(_weapon)

	# --- Weapon edge: obsidian blade with cyan tint ---
	_weapon_edge = ColorRect.new()
	_weapon_edge.size = Vector2(2.0, 10.0)
	_weapon_edge.position = Vector2(24.0, -10.0)
	_weapon_edge.color = Color(0.2, 0.25, 0.35)  # Lighter obsidian, cyan tint
	_weapon_edge.z_index = 3
	_visual.add_child(_weapon_edge)


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

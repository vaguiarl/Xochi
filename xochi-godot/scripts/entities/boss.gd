extends CharacterBody2D
class_name DarkXochi
## Dark Xochi -- the boss encounter for levels 5 and 10.
##
## A dark-tinted evil doppelganger of the player. Uses the same xochi_walk.png
## sprite with a sinister purple/magenta modulate. Cycles through a DKC2-style
## 4-state AI loop: APPROACH -> TELEGRAPH -> ATTACK -> RECOVER.
##
## Exact port from original game.js lines 4542-6002 and 7074-7258.
## All timings, speeds, health values, and state transitions match the original
## pixel-for-pixel. This is the climax of worlds 3 and 5 -- it MUST feel like
## a real boss fight: threatening during APPROACH/ATTACK, tense during TELEGRAPH,
## and satisfying to stomp during RECOVER.
##
## Scene tree (built programmatically in _ready, no .tscn needed):
##   DarkXochi (CharacterBody2D)
##     Sprite2D       -- xochi_walk.png at 0.15 scale, dark purple modulate
##     CollisionShape2D -- RectangleShape2D 30x50
##
## Collision setup:
##   - Layer 32 (Boss layer, bit 6)
##   - Mask 1 | 2 (World + Platforms)
##
## Required autoloads: Events, GameState, AudioManager


# =============================================================================
# PHYSICS CONSTANTS
# =============================================================================

## Gravity matches the player and the project setting exactly.
const GRAVITY: float = 900.0

## Sprite scale -- identical to the player's BASE_SCALE.
const BASE_SCALE: float = 0.15

## Jump velocity when chasing the player (APPROACH state).
const APPROACH_JUMP_VELOCITY: float = -380.0

## Jump velocity during LEAP attack.
const LEAP_JUMP_VELOCITY: float = -450.0

## Horizontal velocity multiplier during LEAP attack.
const LEAP_HORIZONTAL_SPEED: float = 300.0

## Mace swing hit radius in pixels.
const MACE_SWING_RADIUS: float = 100.0

## Visual radius of the mace swing arc.
const MACE_SWING_ARC_RADIUS: float = 60.0

## Player height above boss threshold to trigger a jump (pixels).
const JUMP_HEIGHT_THRESHOLD: float = 120.0

## Distance to player that triggers transition from APPROACH to TELEGRAPH.
const TELEGRAPH_TRIGGER_DISTANCE: float = 120.0

## Player bounce velocity after a successful stomp on the boss.
const STOMP_BOUNCE_VELOCITY: float = -400.0

## Invincibility duration after taking a hit (milliseconds as seconds).
const HIT_INVINCIBILITY_TIME: float = 0.5

## Duration of the ATTACK state (seconds).
const ATTACK_DURATION: float = 0.4

## Duration of the TELEGRAPH state (seconds).
const TELEGRAPH_DURATION: float = 0.5

## Score awarded on defeat.
const DEFEAT_SCORE: int = 5000


# =============================================================================
# TINT COLORS -- exact hex values from the original game.js
# =============================================================================

## Dark purple tint during APPROACH (the default "evil" look).
const TINT_DARK: Color = Color(0.13, 0.0, 0.13)

## Yellow flash during TELEGRAPH warning.
const TINT_TELEGRAPH_YELLOW: Color = Color(1.0, 1.0, 0.0)

## Red-orange flash during TELEGRAPH warning.
const TINT_TELEGRAPH_RED: Color = Color(1.0, 0.27, 0.0)

## Red tint during ATTACK state.
const TINT_ATTACK: Color = Color(1.0, 0.0, 0.0)

## Gray tint during RECOVER state (VULNERABLE!).
const TINT_RECOVER: Color = Color(0.4, 0.4, 0.53)

## Lighter gray for the "window closing" flash in late RECOVER.
const TINT_RECOVER_LIGHT: Color = Color(0.6, 0.6, 0.73)

## Magenta color used for effects (swing arc, shockwave, defeat particles).
const COLOR_MAGENTA: Color = Color(0.8, 0.0, 0.6)


# =============================================================================
# PRELOADED TEXTURES
# =============================================================================
## Uses the player's walk sprite -- Dark Xochi IS the player's shadow.

var _tex_walk: Texture2D = null


# =============================================================================
# EXPORTED / CONFIGURABLE PROPERTIES
# =============================================================================

## Which level this boss is on. Determines speed, health, and timing.
var level_num: int = 5

## Maximum health points -- set from GameState.DIFFICULTY_SETTINGS in setup().
var max_health: int = 4

## Current health points.
var health: int = 4

## Base horizontal movement speed in APPROACH state (px/s).
var base_speed: float = 80.0

## Time spent in APPROACH state before transitioning (seconds).
var approach_time: float = 2.0

## Time spent in TELEGRAPH state -- the "get ready!" warning (seconds).
var telegraph_time: float = 0.5

## Base time spent in RECOVER state -- the vulnerable window (seconds).
var recover_time: float = 1.5


# =============================================================================
# STATE MACHINE
# =============================================================================

## Current AI state: IDLE, APPROACH, TELEGRAPH, ATTACK, RECOVER, DEAD.
var state: String = "IDLE"

## Time elapsed in the current state (seconds). Resets on state transition.
var state_timer: float = 0.0

## Which attack to use next. Alternates: 0 = LEAP, 1 = MACE SWING.
var attack_type: int = 0

## True during brief post-hit invincibility frames. Prevents damage stacking.
var is_invincible: bool = false

## Dynamic speed multiplier that increases as health drops.
## Formula: 1.0 + (1.0 - hp_ratio) * 0.5
## At full HP = 1.0x, at low HP = up to 1.5x. Creates escalating tension.
var speed_multiplier: float = 1.0

## True after the intro sequence completes and the AI loop begins.
var ai_active: bool = false


# =============================================================================
# REFERENCES
# =============================================================================

## Cached reference to the player. Set in setup().
var player_ref: CharacterBody2D = null

## The "!" warning label shown during TELEGRAPH state.
var telegraph_label: Label = null

## The floating text label for state indicators ("LEAP!", "SWING!", "TIRED...").
var action_label: Label = null

## CanvasLayer holding the boss health bar UI (fixed on screen).
var health_bar_layer: CanvasLayer = null

## The health bar fill rectangle -- scales horizontally with health percentage.
var health_bar_fill: ColorRect = null

## The health bar name label.
var health_bar_name_label: Label = null

## The baby axolotl spawn position for after defeat.
var baby_position: Vector2 = Vector2.ZERO


# =============================================================================
# NODE REFERENCES (created in _ready)
# =============================================================================

## The Sprite2D child showing the boss's appearance.
var sprite: Sprite2D = null

## The CollisionShape2D child defining the boss's physics hitbox.
var collision: CollisionShape2D = null


# =============================================================================
# INTERNAL TRACKING
# =============================================================================

## Accumulated time in milliseconds for telegraph flash animation.
var _telegraph_flash_timer: float = 0.0

## Whether the boss is currently facing right.
var _facing_right: bool = false

## Whether the shockwave has been spawned for the current LEAP landing.
var _shockwave_spawned: bool = false

## Whether the mace swing visual has been spawned this ATTACK cycle.
var _swing_visual_spawned: bool = false

## Whether the LEAP attack has been launched this ATTACK cycle.
var _leap_launched: bool = false


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	## Build the scene tree programmatically. No .tscn file needed -- the boss
	## is a runtime-constructed entity spawned by the GameScene on levels 5/10.

	# -- Collision configuration --
	collision_layer = 32   # Boss layer (bit 6)
	collision_mask = 1 | 2 # World (1) + Platforms (2)

	# -- Sprite2D child --
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	if _tex_walk == null:
		_tex_walk = load("res://assets/sprites/player/xochi_walk.png")
	sprite.texture = _tex_walk
	sprite.scale = Vector2(BASE_SCALE, BASE_SCALE)
	add_child(sprite)

	# -- CollisionShape2D child --
	collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(30.0, 50.0)
	collision.shape = shape
	add_child(collision)

	# Start invisible -- the intro sequence fades us in.
	modulate = TINT_DARK
	modulate.a = 0.0

	# Register in the "boss" group so combat systems can find us.
	add_to_group("boss")


func _physics_process(delta: float) -> void:
	## Main physics loop. Applies gravity, runs the state machine, and calls
	## move_and_slide(). Only active after the intro sequence completes.

	if state == "DEAD":
		return

	# Gravity -- always applied when airborne, regardless of state.
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Only run AI after intro completes.
	if ai_active:
		_update_speed_multiplier()
		_run_state_machine(delta)

	move_and_slide()


# =============================================================================
# SETUP -- called by GameScene after instantiation
# =============================================================================

func setup(p_level_num: int, p_player: CharacterBody2D, spawn_pos: Vector2) -> void:
	## Configures the boss for the given level. Must be called before play_intro().
	##
	## Sets level-specific values (speed, health, timings) from GameState's
	## difficulty settings, positions the boss at spawn_pos, and caches the
	## player reference for AI targeting.

	level_num = p_level_num
	player_ref = p_player
	position = spawn_pos

	# -- Level-specific base values --
	if level_num >= 10:
		base_speed = 100.0
		approach_time = 1.5
		recover_time = 1.2
	else:
		base_speed = 80.0
		approach_time = 2.0
		recover_time = 1.5

	# -- Health from difficulty settings --
	var settings: Dictionary = GameState.get_settings()
	var boss_health_map: Dictionary = settings.get("boss_health", { 5: 4, 10: 5 })

	# The dictionary keys from game_state.gd are integers (5, 10).
	max_health = boss_health_map.get(level_num, 4)
	health = max_health

	# -- Baby spawn position (from level data or offset from boss) --
	baby_position = spawn_pos + Vector2(0, -20)

	# Start in IDLE -- intro plays first, then transitions to APPROACH.
	state = "IDLE"
	ai_active = false


# =============================================================================
# INTRO SEQUENCE -- async cinematic before the fight begins
# =============================================================================

func play_intro(callback: Callable) -> void:
	## Plays the boss entrance cinematic: fade in from invisible with a dramatic
	## title card. The AI state machine does NOT start until this completes.
	##
	## [param callback] is called when the intro finishes and the fight begins.
	## This allows the GameScene to pause player input, play boss music, etc.

	# Start fully invisible.
	modulate.a = 0.0

	# Delay before the reveal.
	await get_tree().create_timer(0.5).timeout

	# -- Show dramatic title text --
	var intro_label := Label.new()
	intro_label.text = "DARK XOCHI APPEARS!"
	intro_label.add_theme_font_size_override("font_size", 48)
	intro_label.add_theme_color_override("font_color", COLOR_MAGENTA)
	intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_label.position = Vector2(-200, -120)
	intro_label.size = Vector2(400, 60)
	intro_label.z_index = 100
	add_child(intro_label)

	# -- Fade the boss sprite in over 500ms --
	var fade_in_tween := create_tween()
	fade_in_tween.tween_property(self, "modulate:a", 1.0, 0.5)

	# -- Create the health bar UI --
	_create_health_bar()

	# Wait for the full intro duration (2 seconds total from start).
	await get_tree().create_timer(1.5).timeout

	# -- Fade out the intro text --
	var text_fade := create_tween()
	text_fade.tween_property(intro_label, "modulate:a", 0.0, 0.3)
	await text_fade.finished
	intro_label.queue_free()

	# -- Activate the AI and start fighting! --
	state = "APPROACH"
	state_timer = 0.0
	ai_active = true
	modulate = TINT_DARK

	# Notify the GameScene that the boss is ready.
	if callback.is_valid():
		callback.call()


# =============================================================================
# HEALTH BAR UI -- CanvasLayer fixed on screen
# =============================================================================

func _create_health_bar() -> void:
	## Creates the boss health bar on a CanvasLayer so it stays fixed on screen.
	## Shows "DARK XOCHI" label and a magenta fill bar that scales with health.

	health_bar_layer = CanvasLayer.new()
	health_bar_layer.name = "BossHealthBar"
	health_bar_layer.layer = 15  # Above game, below pause overlay
	add_child(health_bar_layer)

	# -- Container Control for positioning and fade animation --
	var container := Control.new()
	container.name = "Container"
	container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar_layer.add_child(container)

	# -- "DARK XOCHI" name label --
	health_bar_name_label = Label.new()
	health_bar_name_label.text = "DARK XOCHI"
	health_bar_name_label.add_theme_font_size_override("font_size", 20)
	health_bar_name_label.add_theme_color_override("font_color", COLOR_MAGENTA)
	health_bar_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_bar_name_label.position = Vector2(300, 40)
	health_bar_name_label.size = Vector2(200, 26)
	container.add_child(health_bar_name_label)

	# -- Health bar background (dark purple) --
	var bar_bg := ColorRect.new()
	bar_bg.name = "BarBG"
	bar_bg.size = Vector2(200, 20)
	bar_bg.position = Vector2(300, 68)
	bar_bg.color = Color(0.15, 0.0, 0.15)
	container.add_child(bar_bg)

	# -- Health bar fill (magenta, scales with health) --
	health_bar_fill = ColorRect.new()
	health_bar_fill.name = "BarFill"
	health_bar_fill.size = Vector2(200, 20)
	health_bar_fill.position = Vector2(300, 68)
	health_bar_fill.color = COLOR_MAGENTA
	container.add_child(health_bar_fill)

	# -- Start invisible, fade in over 1 second --
	container.modulate.a = 0.0
	var fade_tween := create_tween()
	fade_tween.tween_property(container, "modulate:a", 1.0, 1.0)


func _update_health_bar() -> void:
	## Scales the health bar fill to reflect current HP as a percentage.
	if health_bar_fill != null and is_instance_valid(health_bar_fill):
		var hp_ratio: float = float(health) / float(max_health) if max_health > 0 else 0.0
		health_bar_fill.size.x = 200.0 * hp_ratio


# =============================================================================
# SPEED MULTIPLIER -- escalating tension as boss weakens
# =============================================================================

func _update_speed_multiplier() -> void:
	## Recalculates the speed multiplier based on current HP ratio.
	## At full HP: 1.0x. At 0 HP: 1.5x. Linear interpolation.
	## This makes the fight progressively more intense -- the boss gets
	## desperate and faster as it takes damage. DKC2-style escalation.
	var hp_ratio: float = float(health) / float(max_health) if max_health > 0 else 0.0
	speed_multiplier = 1.0 + (1.0 - hp_ratio) * 0.5


# =============================================================================
# STATE MACHINE -- the brain of Dark Xochi
# =============================================================================

func _run_state_machine(delta: float) -> void:
	## Dispatches to the current state's update function.
	## Each state handles its own movement, animation, and transition logic.

	state_timer += delta

	match state:
		"APPROACH":
			_state_approach(delta)
		"TELEGRAPH":
			_state_telegraph(delta)
		"ATTACK":
			_state_attack(delta)
		"RECOVER":
			_state_recover(delta)


# =============================================================================
# STATE: APPROACH -- hunting the player
# =============================================================================

func _state_approach(_delta: float) -> void:
	## Walk toward the player aggressively. Jump if blocked or player is above.
	## Transition to TELEGRAPH when close enough or timer expires.
	## Tint: dark purple (not vulnerable to melee, but stomps always work).

	if player_ref == null or not is_instance_valid(player_ref):
		return

	# -- Determine direction toward player --
	var dir_to_player: float = sign(player_ref.global_position.x - global_position.x)
	_facing_right = dir_to_player > 0
	sprite.flip_h = not _facing_right

	# -- Move toward player --
	velocity.x = dir_to_player * base_speed * speed_multiplier

	# -- Jump if blocked horizontally or player is high above --
	var player_above: bool = (player_ref.global_position.y < global_position.y - JUMP_HEIGHT_THRESHOLD)
	if is_on_floor() and (is_on_wall() or player_above):
		velocity.y = APPROACH_JUMP_VELOCITY

	# -- Apply tint --
	if not is_invincible:
		modulate = TINT_DARK

	# -- Transition check: close enough or timer expired --
	var dist_to_player: float = global_position.distance_to(player_ref.global_position)
	var approach_elapsed: bool = state_timer >= approach_time

	if dist_to_player < TELEGRAPH_TRIGGER_DISTANCE or approach_elapsed:
		_enter_state("TELEGRAPH")


# =============================================================================
# STATE: TELEGRAPH -- warning flash before attack
# =============================================================================

func _state_telegraph(delta: float) -> void:
	## Stop moving, flash yellow/red to warn the player, show "!" above head.
	## This is the tension moment -- the player knows an attack is coming.
	## Duration: 500ms, then transition to ATTACK.

	# -- Stop horizontal movement --
	velocity.x = 0.0

	# -- Flash between yellow and red-orange every 100ms --
	_telegraph_flash_timer += delta
	var flash_cycle: int = int(_telegraph_flash_timer / 0.1)
	if flash_cycle % 2 == 0:
		modulate = TINT_TELEGRAPH_YELLOW
	else:
		modulate = TINT_TELEGRAPH_RED

	# -- Transition to ATTACK when timer expires --
	if state_timer >= TELEGRAPH_DURATION:
		_remove_telegraph_label()
		_enter_state("ATTACK")


# =============================================================================
# STATE: ATTACK -- danger zone!
# =============================================================================

func _state_attack(_delta: float) -> void:
	## Execute the current attack type: LEAP (0) or MACE SWING (1).
	## Duration: 400ms, then transition to RECOVER (if on floor for LEAP).
	## Tint: red (dangerous -- touching the boss hurts the player).

	modulate = TINT_ATTACK

	if player_ref == null or not is_instance_valid(player_ref):
		return

	if attack_type == 0:
		# -- LEAP ATTACK: jump toward the player --
		_attack_leap()
	else:
		# -- MACE SWING: wide melee arc --
		_attack_mace_swing()

	# -- Transition to RECOVER after duration and landing --
	if state_timer >= ATTACK_DURATION:
		if attack_type == 0:
			# LEAP: must be on floor to transition (landing completes the attack)
			if is_on_floor():
				# Spawn ground pound shockwave on landing
				if not _shockwave_spawned:
					_spawn_shockwave()
					_shockwave_spawned = true
				_enter_state("RECOVER")
		else:
			# MACE SWING: transitions after fixed duration
			_enter_state("RECOVER")


func _attack_leap() -> void:
	## LEAP attack: launch toward the player with a powerful arc jump.
	## Shows "LEAP!" text. On landing, creates a ground pound shockwave.

	if not _leap_launched:
		_leap_launched = true

		# Direction toward player at moment of launch.
		var dir: float = sign(player_ref.global_position.x - global_position.x)
		_facing_right = dir > 0
		sprite.flip_h = not _facing_right

		velocity.y = LEAP_JUMP_VELOCITY
		velocity.x = dir * LEAP_HORIZONTAL_SPEED * speed_multiplier

		_show_action_text("LEAP!", TINT_ATTACK)
		AudioManager.play_sfx("jump")


func _attack_mace_swing() -> void:
	## MACE SWING attack: wide melee arc that damages the player if within range.
	## Shows a magenta semicircle visual and "SWING!" text.

	velocity.x = 0.0

	if not _swing_visual_spawned:
		_swing_visual_spawned = true

		_show_action_text("SWING!", COLOR_MAGENTA)
		_spawn_mace_swing_visual()
		AudioManager.play_sfx("stomp")

		# -- Check if player is within swing range --
		if player_ref != null and is_instance_valid(player_ref):
			var dist: float = global_position.distance_to(player_ref.global_position)
			if dist < MACE_SWING_RADIUS:
				# Hit the player!
				player_ref.hit(1)


# =============================================================================
# STATE: RECOVER -- the vulnerable window
# =============================================================================

func _state_recover(delta: float) -> void:
	## Stop moving, wobble tiredly, show "TIRED..." text.
	## This is the ONLY state where melee attacks damage the boss.
	## (Stomps damage the boss in ANY state -- a core design decision that
	## rewards skilled play without making the fight unfair.)
	##
	## Duration: recover_time / speed_mult (shorter as boss weakens).
	## Last 500ms: flash to warn the window is closing.

	velocity.x = 0.0

	# -- Wobble animation: rotation oscillation --
	var time_ms: float = float(Time.get_ticks_msec())
	rotation_degrees = sin(time_ms / 100.0) * 5.0

	# -- Calculate effective recover duration (shortened by speed_mult) --
	var effective_recover_time: float = recover_time / speed_multiplier

	# -- Flash warning in the last 500ms --
	var time_remaining: float = effective_recover_time - state_timer
	if time_remaining < 0.5:
		# Flash between gray and lighter gray
		var flash_cycle: int = int(state_timer / 0.1)
		if flash_cycle % 2 == 0:
			modulate = TINT_RECOVER
		else:
			modulate = TINT_RECOVER_LIGHT
	else:
		if not is_invincible:
			modulate = TINT_RECOVER

	# -- Transition back to APPROACH when timer expires --
	if state_timer >= effective_recover_time:
		rotation_degrees = 0.0
		_remove_action_label()
		_enter_state("APPROACH")


# =============================================================================
# STATE TRANSITIONS
# =============================================================================

func _enter_state(new_state: String) -> void:
	## Transitions to a new AI state. Resets the state timer and performs
	## any state-entry setup (labels, flags, etc.).

	var old_state: String = state
	state = new_state
	state_timer = 0.0

	# -- Clean up old state --
	match old_state:
		"TELEGRAPH":
			_remove_telegraph_label()
			_telegraph_flash_timer = 0.0
		"ATTACK":
			_remove_action_label()
			_shockwave_spawned = false
			_swing_visual_spawned = false
			_leap_launched = false
		"RECOVER":
			_remove_action_label()
			rotation_degrees = 0.0

	# -- Set up new state --
	match new_state:
		"APPROACH":
			modulate = TINT_DARK
		"TELEGRAPH":
			_telegraph_flash_timer = 0.0
			_show_telegraph_label()
		"ATTACK":
			modulate = TINT_ATTACK
			# Reset attack-specific flags.
			_shockwave_spawned = false
			_swing_visual_spawned = false
			_leap_launched = false
		"RECOVER":
			modulate = TINT_RECOVER
			# Toggle attack type for next cycle: 0 -> 1 -> 0 -> 1...
			attack_type = 1 - attack_type
			_show_action_text("TIRED...", Color("88ff88"))


# =============================================================================
# DAMAGE SYSTEM
# =============================================================================

func take_damage(amount: int = 1) -> void:
	## Reduces health, plays hit feedback, applies knockback, and checks for
	## defeat. Called by the combat system on stomp (any state) or melee
	## (RECOVER state only).
	##
	## Hit feedback: brief white flash, knockback away from player, floating
	## "HIT! X/Y" text, and 500ms invincibility to prevent damage stacking.

	if is_invincible or state == "DEAD":
		return

	# -- Reduce health --
	health -= amount
	if health < 0:
		health = 0

	# -- Update health bar --
	_update_health_bar()

	# -- Emit damage signal --
	Events.boss_damaged.emit(health, max_health)

	# -- SFX --
	AudioManager.play_sfx("stomp")

	# -- Floating "HIT!" text --
	_show_floating_text(
		"HIT! %d/%d" % [max_health - health, max_health],
		Color.WHITE,
		global_position + Vector2(0, -60)
	)

	# -- Knockback away from player --
	if player_ref != null and is_instance_valid(player_ref):
		var knockback_dir: float = sign(global_position.x - player_ref.global_position.x)
		if knockback_dir == 0:
			knockback_dir = 1.0
		velocity.x = knockback_dir * 200.0
		velocity.y = -150.0

	# -- Brief invincibility to prevent rapid damage stacking --
	is_invincible = true

	# -- White flash then back to state tint --
	var flash_tween := create_tween()
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.05)
	flash_tween.tween_interval(0.1)

	# -- Check for defeat --
	if health <= 0:
		defeat_sequence()
		return

	# After flash, return to state tint and reset to APPROACH.
	flash_tween.tween_callback(func():
		_enter_state("APPROACH")
	)

	# Remove invincibility after the protection window.
	flash_tween.tween_interval(HIT_INVINCIBILITY_TIME)
	flash_tween.tween_callback(func():
		is_invincible = false
	)


## Called by the combat system when the player stomps the boss.
## Stomps ALWAYS damage the boss regardless of state -- this is intentional.
## It rewards skilled players who can land on the boss during any phase.
func hit_by_stomp() -> void:
	take_damage(1)
	# Player bounce is handled by the caller (combat system / game scene).


## Called by the combat system when the player's melee attack hits during RECOVER.
## Melee only works in RECOVER state -- the vulnerable window.
func hit_by_melee() -> void:
	if state == "RECOVER":
		take_damage(1)


# =============================================================================
# DEFEAT SEQUENCE -- the big payoff
# =============================================================================

func defeat_sequence() -> void:
	## The boss is destroyed! Play a dramatic death sequence with flashing,
	## particles, score award, and baby axolotl spawn. This is the reward for
	## a hard-fought boss fight -- make it feel GOOD.

	state = "DEAD"
	ai_active = false
	velocity = Vector2.ZERO
	rotation_degrees = 0.0

	# -- Show dramatic defeat text --
	_show_action_text("NOOOOO!", COLOR_MAGENTA)

	# -- Rapid white/red flash (10 flashes at 100ms each = 1 second) --
	var flash_tween := create_tween()
	for i in 10:
		if i % 2 == 0:
			flash_tween.tween_property(self, "modulate", Color.WHITE, 0.05)
		else:
			flash_tween.tween_property(self, "modulate", Color.RED, 0.05)

	await flash_tween.finished

	# -- Explosion particles: 20 magenta rects that fly outward --
	_spawn_defeat_particles()

	# -- Fade out the boss sprite --
	var fade_tween := create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await fade_tween.finished

	# -- Award score --
	GameState.score += DEFEAT_SCORE
	Events.score_changed.emit(GameState.score)
	_show_floating_text(
		"+%d POINTS!" % DEFEAT_SCORE,
		Color.YELLOW,
		global_position + Vector2(0, -80)
	)

	# -- Destroy health bar --
	if health_bar_layer != null and is_instance_valid(health_bar_layer):
		health_bar_layer.queue_free()
		health_bar_layer = null

	# -- Emit defeat signal --
	Events.boss_defeated.emit()

	# -- After delay, spawn baby axolotl at the boss's position --
	await get_tree().create_timer(1.5).timeout
	_spawn_baby_axolotl()


# =============================================================================
# BABY AXOLOTL SPAWN (post-defeat reward)
# =============================================================================

func _spawn_baby_axolotl() -> void:
	## Spawns a baby axolotl collectible at the boss's last position.
	## The GameScene's existing baby pickup logic will handle the rest.

	# Find the parent scene (GameScene) to add the baby to.
	var game_scene: Node = get_parent()
	if game_scene == null:
		return

	# Try to find the Collectibles container in the game scene.
	var collectibles_node: Node = game_scene.get_node_or_null("Collectibles")
	if collectibles_node == null:
		# Fallback: add directly to game scene.
		collectibles_node = game_scene

	# -- Create baby axolotl marker (same structure as GameScene._create_baby) --
	var marker := Node2D.new()
	marker.name = "BabyAxolotl"
	marker.position = baby_position
	marker.set_meta("type", "baby")
	marker.set_meta("base_y", baby_position.y)
	marker.set_meta("bob_offset", 0.0)

	# Body (pink)
	var body_rect := ColorRect.new()
	body_rect.size = Vector2(24.0, 24.0)
	body_rect.position = Vector2(-12.0, -12.0)
	body_rect.color = Color("FF88AA")
	marker.add_child(body_rect)

	# Face highlight
	var face := ColorRect.new()
	face.size = Vector2(14.0, 10.0)
	face.position = Vector2(-7.0, -8.0)
	face.color = Color("FFBBCC")
	marker.add_child(face)

	# Sparkle ring
	var sparkle := ColorRect.new()
	sparkle.name = "Sparkle"
	sparkle.size = Vector2(36.0, 36.0)
	sparkle.position = Vector2(-18.0, -18.0)
	sparkle.color = Color(1.0, 0.8, 0.9, 0.3)
	marker.add_child(sparkle)

	collectibles_node.add_child(marker)

	# Dramatic entrance: scale up from zero.
	marker.scale = Vector2.ZERO
	var pop_tween := create_tween()
	pop_tween.tween_property(marker, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


# =============================================================================
# VISUAL EFFECTS
# =============================================================================

func _show_telegraph_label() -> void:
	## Shows the "!" warning text above the boss's head during TELEGRAPH state.
	## Yellow text with red outline, size 36.

	_remove_telegraph_label()

	telegraph_label = Label.new()
	telegraph_label.text = "!"
	telegraph_label.add_theme_font_size_override("font_size", 36)
	telegraph_label.add_theme_color_override("font_color", TINT_TELEGRAPH_YELLOW)
	telegraph_label.add_theme_constant_override("outline_size", 4)
	telegraph_label.add_theme_color_override("font_outline_color", TINT_TELEGRAPH_RED)
	telegraph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	telegraph_label.position = Vector2(-10, -70)
	telegraph_label.size = Vector2(20, 40)
	telegraph_label.z_index = 100
	add_child(telegraph_label)


func _remove_telegraph_label() -> void:
	## Removes the "!" warning label if it exists.
	if telegraph_label != null and is_instance_valid(telegraph_label):
		telegraph_label.queue_free()
		telegraph_label = null


func _show_action_text(text: String, color: Color) -> void:
	## Shows a floating action label above the boss (e.g. "LEAP!", "SWING!",
	## "TIRED...", "NOOOOO!"). Replaces any existing action label.

	_remove_action_label()

	action_label = Label.new()
	action_label.text = text
	action_label.add_theme_font_size_override("font_size", 20)
	action_label.add_theme_color_override("font_color", color)
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_label.position = Vector2(-60, -80)
	action_label.size = Vector2(120, 28)
	action_label.z_index = 100
	add_child(action_label)


func _remove_action_label() -> void:
	## Removes the floating action label if it exists.
	if action_label != null and is_instance_valid(action_label):
		action_label.queue_free()
		action_label = null


func _show_floating_text(text: String, color: Color, pos: Vector2) -> void:
	## Creates a floating text label at the given world position that drifts
	## upward and fades out. Used for damage numbers and score popups.

	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 100
	parent_node.add_child(label)

	# Float upward and fade out over 1 second.
	var tween := parent_node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 60.0, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.chain().tween_callback(label.queue_free)


func _spawn_mace_swing_visual() -> void:
	## Spawns a magenta semicircle visual representing the mace swing arc.
	## The visual is a ColorRect approximation that fades out quickly.

	var swing_dir: float = -1.0 if _facing_right else 1.0
	var offset_x: float = swing_dir * -MACE_SWING_ARC_RADIUS * 0.5

	# Semicircle approximated as a wide, short, rounded ColorRect.
	var arc := ColorRect.new()
	arc.size = Vector2(MACE_SWING_ARC_RADIUS * 2.0, MACE_SWING_ARC_RADIUS)
	arc.position = Vector2(offset_x - MACE_SWING_ARC_RADIUS, -MACE_SWING_ARC_RADIUS * 0.5)
	arc.color = Color(COLOR_MAGENTA.r, COLOR_MAGENTA.g, COLOR_MAGENTA.b, 0.5)
	arc.z_index = 50
	add_child(arc)

	# Fade out and remove.
	var tween := create_tween()
	tween.tween_property(arc, "modulate:a", 0.0, 0.3)
	tween.tween_callback(arc.queue_free)


func _spawn_shockwave() -> void:
	## Spawns a ground pound shockwave when landing from a LEAP attack.
	## Two magenta rectangles expand outward from the landing point and fade.
	## This is the visual punctuation on the LEAP -- it makes the landing
	## feel impactful even if the player dodged.

	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	# -- Left shockwave --
	var wave_left := ColorRect.new()
	wave_left.size = Vector2(20.0, 8.0)
	wave_left.position = global_position + Vector2(-10.0, 20.0)
	wave_left.color = Color(COLOR_MAGENTA.r, COLOR_MAGENTA.g, COLOR_MAGENTA.b, 0.7)
	wave_left.z_index = 50
	parent_node.add_child(wave_left)

	# -- Right shockwave --
	var wave_right := ColorRect.new()
	wave_right.size = Vector2(20.0, 8.0)
	wave_right.position = global_position + Vector2(-10.0, 20.0)
	wave_right.color = Color(COLOR_MAGENTA.r, COLOR_MAGENTA.g, COLOR_MAGENTA.b, 0.7)
	wave_right.z_index = 50
	parent_node.add_child(wave_right)

	# -- Expand outward and fade --
	var tween_left := parent_node.create_tween()
	tween_left.set_parallel(true)
	tween_left.tween_property(wave_left, "position:x", global_position.x - 150.0, 0.4)
	tween_left.tween_property(wave_left, "size:x", 80.0, 0.4)
	tween_left.tween_property(wave_left, "modulate:a", 0.0, 0.4)
	tween_left.chain().tween_callback(wave_left.queue_free)

	var tween_right := parent_node.create_tween()
	tween_right.set_parallel(true)
	tween_right.tween_property(wave_right, "position:x", global_position.x + 80.0, 0.4)
	tween_right.tween_property(wave_right, "size:x", 80.0, 0.4)
	tween_right.tween_property(wave_right, "modulate:a", 0.0, 0.4)
	tween_right.chain().tween_callback(wave_right.queue_free)

	# SFX for the impact.
	AudioManager.play_sfx("land")


func _spawn_defeat_particles() -> void:
	## Spawns 20 magenta explosion particles that fly outward from the boss.
	## Each particle is a small ColorRect that moves in a random direction
	## and fades out. This is the climactic visual payoff for defeating the boss.

	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in 20:
		var particle := ColorRect.new()
		particle.size = Vector2(6.0, 6.0)
		particle.position = global_position + Vector2(-3.0, -3.0)
		particle.color = COLOR_MAGENTA
		particle.z_index = 80
		parent_node.add_child(particle)

		# Random outward direction and speed.
		var angle: float = rng.randf_range(0.0, TAU)
		var speed: float = rng.randf_range(80.0, 200.0)
		var end_pos: Vector2 = particle.position + Vector2(cos(angle), sin(angle)) * speed

		# Fly outward and fade.
		var tween := parent_node.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", end_pos, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(particle, "modulate:a", 0.0, 0.6)
		tween.chain().tween_callback(particle.queue_free)

extends CharacterBody2D
class_name DarkXochi
## Dark Xochi -- the boss encounter for levels 5 and 10.
##
## Multi-phase boss with 4 attacks, taunt system, and escalating difficulty.
## Phase 1 (100%-60% HP): LEAP + SWING. Cocky taunts.
## Phase 2 (59%-30% HP): Adds SHADOW_BOLT ranged. Frustrated taunts.
## Phase 3 (29%-0% HP): Adds DARK_RAIN (lv10 only). Desperate/respect taunts.
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

const GRAVITY: float = 900.0
const BASE_SCALE: float = 0.15
const APPROACH_JUMP_VELOCITY: float = -380.0
const LEAP_JUMP_VELOCITY: float = -450.0
const LEAP_HORIZONTAL_SPEED: float = 300.0
const MACE_SWING_RADIUS: float = 100.0
const MACE_SWING_ARC_RADIUS: float = 60.0
const JUMP_HEIGHT_THRESHOLD: float = 120.0
const TELEGRAPH_TRIGGER_DISTANCE: float = 120.0
const STOMP_BOUNCE_VELOCITY: float = -400.0
const HIT_INVINCIBILITY_TIME: float = 0.5
const ATTACK_DURATION: float = 0.4
const TELEGRAPH_DURATION: float = 0.5
const DEFEAT_SCORE: int = 5000

## Shadow bolt projectile constants
const SHADOW_BOLT_SPEED: float = 250.0
const SHADOW_BOLT_LIFETIME: float = 2.5
const SHADOW_BOLT_CHARGE_TIME: float = 0.3

## Dark rain constants (lv10 phase 3)
const DARK_RAIN_BOLT_COUNT: int = 5
const DARK_RAIN_BOLT_SPEED: float = 300.0
const DARK_RAIN_STAGGER: float = 0.3
const DARK_RAIN_WARNING_TIME: float = 0.5
const ARENA_WALL_MARGIN: float = 28.0
const ARENA_FALL_RECOVERY_BUFFER: float = 180.0


# =============================================================================
# TINT COLORS
# =============================================================================

const TINT_DARK: Color = Color(0.13, 0.0, 0.13)
const TINT_TELEGRAPH_YELLOW: Color = Color(1.0, 1.0, 0.0)
const TINT_TELEGRAPH_RED: Color = Color(1.0, 0.27, 0.0)
const TINT_ATTACK: Color = Color(1.0, 0.0, 0.0)
const TINT_RECOVER: Color = Color(0.4, 0.4, 0.53)
const TINT_RECOVER_LIGHT: Color = Color(0.6, 0.6, 0.73)
const COLOR_MAGENTA: Color = Color(0.8, 0.0, 0.6)
const TINT_PHASE_TRANSITION: Color = Color(1.0, 0.0, 1.0)


# =============================================================================
# TEXTURES
# =============================================================================

var _tex_walk: Texture2D = null


# =============================================================================
# CONFIGURABLE PROPERTIES
# =============================================================================

var level_num: int = 5
var max_health: int = 4
var health: int = 4
var base_speed: float = 80.0
var approach_time: float = 2.0
var telegraph_time: float = 0.5
var recover_time: float = 1.5


# =============================================================================
# STATE MACHINE
# =============================================================================

## Current AI state: IDLE, APPROACH, TELEGRAPH, ATTACK, RECOVER, TAUNT,
## SHADOW_BOLT, DARK_RAIN, PHASE_TRANSITION, DEAD.
var state: String = "IDLE"
var state_timer: float = 0.0

## Attack type for the current ATTACK state: "LEAP" or "SWING"
var attack_type: String = "LEAP"

var is_invincible: bool = false
var speed_multiplier: float = 1.0
var ai_active: bool = false

## Current phase (1, 2, or 3). Determines available attacks and timings.
var current_phase: int = 1

## Whether DARK_RAIN has been used this phase 3 entry (one guaranteed use).
var _dark_rain_used_initial: bool = false


# =============================================================================
# REFERENCES
# =============================================================================

var player_ref: CharacterBody2D = null
var telegraph_label: Label = null
var action_label: Label = null
var health_bar_layer: CanvasLayer = null
var health_bar_fill: ColorRect = null
var health_bar_name_label: Label = null
var baby_position: Vector2 = Vector2.ZERO


# =============================================================================
# NODE REFERENCES (created in _ready)
# =============================================================================

var sprite: Sprite2D = null
var collision: CollisionShape2D = null
var arena_left: float = -INF
var arena_right: float = INF
var arena_floor_y: float = INF


# =============================================================================
# INTERNAL TRACKING
# =============================================================================

var _telegraph_flash_timer: float = 0.0
var _facing_right: bool = false
var _shockwave_spawned: bool = false
var _swing_visual_spawned: bool = false
var _leap_launched: bool = false

## Shadow bolt tracking
var _shadow_bolt_fired: bool = false
var _shadow_bolt_charge_timer: float = 0.0

## Dark rain tracking
var _dark_rain_started: bool = false
var _dark_rain_bolts_spawned: int = 0
var _dark_rain_spawn_timer: float = 0.0
var _dark_rain_warnings_shown: bool = false

## RNG for attack selection and taunts
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _tracked_tweens: Array[Tween] = []
var _tracked_timers: Array[Timer] = []


# =============================================================================
# TAUNT SYSTEM
# =============================================================================

var taunt_cooldown: float = 0.0
var approach_cycles_since_taunt: int = 0
var _taunt_bubble: Control = null
var _taunt_canvas: CanvasLayer = null

## Pre-written taunt lines organized by trigger category.
var taunt_lines: Dictionary = {
	"intro_lv5": [
		"Ah, you made it! I was getting bored.",
	],
	"intro_lv10": [
		"Back for more? Bold. Foolish. But bold.",
	],
	"phase2": [
		"Not bad... for a flower picker.",
		"Okay, playtime is over.",
		"You actually hit me? Impressive.",
	],
	"phase3": [
		"You're better than I expected.",
		"Fine. No more games.",
	],
	"phase3_lv10": [
		"This is where it ends -- for one of us.",
	],
	"approach": [
		"Running? Smart. But I'm faster.",
		"The babies don't need you. They need ME.",
		"Your flowers won't save you here.",
		"Do you ever wonder who waters MY gardens?",
	],
	"hit_player": [
		"Too slow!",
		"That one's free. Next one costs more.",
		"The canals send their regards.",
	],
	"stomped": [
		"Lucky shot.",
		"Ow! My beautiful shadow scales!",
		"You'll pay for that.",
	],
	"recover": [
		"Just... catching my breath...",
		"Don't get any ideas...",
		"I'm not tired, I'm... strategizing.",
	],
	"near_death": [
		"This isn't over...",
	],
	"near_death_lv10": [
		"Xochimilco will remember my name!",
	],
	"defeat": [
		"The shadows... will return...",
	],
	"defeat_lv10": [
		"You win... this time. Guard the canals well.",
	],
}


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_rng.randomize()

	collision_layer = 32
	collision_mask = 1 | 2

	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	if _tex_walk == null:
		_tex_walk = load("res://assets/sprites/player/xochi_walk.png")
	sprite.texture = _tex_walk
	sprite.scale = Vector2(BASE_SCALE, BASE_SCALE)
	add_child(sprite)

	collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(30.0, 50.0)
	collision.shape = shape
	add_child(collision)

	_set_boss_tint(TINT_DARK)
	_set_boss_alpha(0.0)

	add_to_group("boss")


func _exit_tree() -> void:
	_cleanup_async_resources()
	_remove_taunt_bubble()
	_remove_action_label()
	_remove_telegraph_label()
	if health_bar_layer != null and is_instance_valid(health_bar_layer):
		health_bar_layer.queue_free()
		health_bar_layer = null


func _physics_process(delta: float) -> void:
	if state == "DEAD":
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Tick taunt cooldown
	if taunt_cooldown > 0.0:
		taunt_cooldown -= delta

	if ai_active:
		_update_speed_multiplier()
		_run_state_machine(delta)

	move_and_slide()
	_enforce_arena_bounds()


func _set_boss_tint(color: Color) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var target := color
	target.a = sprite.modulate.a
	sprite.modulate = target


func _set_boss_alpha(alpha: float) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var target := sprite.modulate
	target.a = alpha
	sprite.modulate = target


func _get_boss_half_height() -> float:
	if collision != null and collision.shape is RectangleShape2D:
		return collision.shape.size.y * 0.5
	return 25.0


func _enforce_arena_bounds() -> void:
	if arena_right > arena_left + ARENA_WALL_MARGIN * 2.0:
		var clamped_x := clampf(global_position.x, arena_left + ARENA_WALL_MARGIN, arena_right - ARENA_WALL_MARGIN)
		if not is_equal_approx(clamped_x, global_position.x):
			global_position.x = clamped_x
			velocity.x = 0.0

	if arena_floor_y < INF and global_position.y > arena_floor_y + ARENA_FALL_RECOVERY_BUFFER:
		global_position.y = arena_floor_y - _get_boss_half_height() - 2.0
		velocity = Vector2.ZERO


# =============================================================================
# SETUP
# =============================================================================

func setup(p_level_num: int, p_player: CharacterBody2D, spawn_pos: Vector2, arena_data: Dictionary = {}) -> void:
	level_num = p_level_num
	player_ref = p_player
	position = spawn_pos
	arena_left = float(arena_data.get("left", -INF))
	arena_right = float(arena_data.get("right", INF))
	arena_floor_y = float(arena_data.get("floor_y", INF))

	# Phase 1 base timings (will be adjusted by _apply_phase_timings)
	if level_num >= 10:
		base_speed = 100.0
	else:
		base_speed = 80.0

	current_phase = 1
	_apply_phase_timings()

	var settings: Dictionary = GameState.get_settings()
	var boss_health_map: Dictionary = settings.get("boss_health", { 5: 4, 10: 5 })
	max_health = boss_health_map.get(level_num, 4)
	health = max_health

	baby_position = spawn_pos + Vector2(0, -20)

	state = "IDLE"
	ai_active = false


# =============================================================================
# PHASE SYSTEM
# =============================================================================

func _apply_phase_timings() -> void:
	## Sets approach_time, recover_time, telegraph_time based on phase and level.
	if level_num >= 10:
		match current_phase:
			1:
				approach_time = 1.5
				recover_time = 1.2
				telegraph_time = 0.5
			2:
				approach_time = 1.2
				recover_time = 0.9
				telegraph_time = 0.4
			3:
				approach_time = 0.8
				recover_time = 0.6
				telegraph_time = 0.3
	else:
		match current_phase:
			1:
				approach_time = 2.0
				recover_time = 1.5
				telegraph_time = 0.5
			2:
				approach_time = 1.6
				recover_time = 1.2
				telegraph_time = 0.4
			3:
				approach_time = 1.2
				recover_time = 0.8
				telegraph_time = 0.3


func _get_speed_cap() -> float:
	## Returns the speed multiplier cap for the current phase.
	match current_phase:
		1: return 1.2
		2: return 1.4
		3: return 1.6
	return 1.2


func _check_phase_transition() -> void:
	## Called after taking damage. Checks if HP crossed a phase threshold.
	var hp_ratio: float = float(health) / float(max_health) if max_health > 0 else 0.0
	var new_phase: int = current_phase

	if hp_ratio <= 0.29 and current_phase < 3:
		new_phase = 3
	elif hp_ratio <= 0.59 and current_phase < 2:
		new_phase = 2

	if new_phase != current_phase:
		current_phase = new_phase
		_apply_phase_timings()
		_dark_rain_used_initial = false
		_enter_state("PHASE_TRANSITION")


# =============================================================================
# INTRO SEQUENCE
# =============================================================================

func play_intro(callback: Callable) -> void:
	_set_boss_tint(TINT_DARK)
	_set_boss_alpha(0.0)

	await _make_delay(0.5)

	# -- Show personality intro instead of generic text --
	var intro_text: String
	if level_num >= 10:
		intro_text = _pick_taunt("intro_lv10")
	else:
		intro_text = _pick_taunt("intro_lv5")

	var intro_label := Label.new()
	intro_label.text = intro_text
	intro_label.add_theme_font_size_override("font_size", 36)
	intro_label.add_theme_color_override("font_color", COLOR_MAGENTA)
	intro_label.add_theme_constant_override("outline_size", 3)
	intro_label.add_theme_color_override("font_outline_color", Color.BLACK)
	intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_label.position = Vector2(-250, -120)
	intro_label.size = Vector2(500, 60)
	intro_label.z_index = 100
	add_child(intro_label)

	var fade_in_tween := _track_tween(create_tween())
	fade_in_tween.tween_property(sprite, "modulate:a", 1.0, 0.5)

	_create_health_bar()

	await _make_delay(2.0)

	var text_fade := _track_tween(create_tween())
	text_fade.tween_property(intro_label, "modulate:a", 0.0, 0.3)
	await text_fade.finished
	intro_label.queue_free()

	state = "APPROACH"
	state_timer = 0.0
	ai_active = true
	_set_boss_tint(TINT_DARK)
	_set_boss_alpha(1.0)

	if callback.is_valid():
		callback.call()


# =============================================================================
# HEALTH BAR UI
# =============================================================================

func _create_health_bar() -> void:
	health_bar_layer = CanvasLayer.new()
	health_bar_layer.name = "BossHealthBar"
	health_bar_layer.layer = 15
	add_child(health_bar_layer)

	var container := Control.new()
	container.name = "Container"
	container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar_layer.add_child(container)

	health_bar_name_label = Label.new()
	health_bar_name_label.text = "DARK XOCHI"
	health_bar_name_label.add_theme_font_size_override("font_size", 20)
	health_bar_name_label.add_theme_color_override("font_color", COLOR_MAGENTA)
	health_bar_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_bar_name_label.position = Vector2(300, 40)
	health_bar_name_label.size = Vector2(200, 26)
	container.add_child(health_bar_name_label)

	var bar_bg := ColorRect.new()
	bar_bg.name = "BarBG"
	bar_bg.size = Vector2(200, 20)
	bar_bg.position = Vector2(300, 68)
	bar_bg.color = Color(0.15, 0.0, 0.15)
	container.add_child(bar_bg)

	health_bar_fill = ColorRect.new()
	health_bar_fill.name = "BarFill"
	health_bar_fill.size = Vector2(200, 20)
	health_bar_fill.position = Vector2(300, 68)
	health_bar_fill.color = COLOR_MAGENTA
	container.add_child(health_bar_fill)

	container.modulate.a = 0.0
	var fade_tween := _track_tween(create_tween())
	fade_tween.tween_property(container, "modulate:a", 1.0, 1.0)


func _update_health_bar() -> void:
	if health_bar_fill != null and is_instance_valid(health_bar_fill):
		var hp_ratio: float = float(health) / float(max_health) if max_health > 0 else 0.0
		health_bar_fill.size.x = 200.0 * hp_ratio


# =============================================================================
# SPEED MULTIPLIER
# =============================================================================

func _update_speed_multiplier() -> void:
	var hp_ratio: float = float(health) / float(max_health) if max_health > 0 else 0.0
	var cap: float = _get_speed_cap()
	speed_multiplier = minf(1.0 + (1.0 - hp_ratio) * 0.6, cap)


# =============================================================================
# STATE MACHINE
# =============================================================================

func _run_state_machine(delta: float) -> void:
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
		"TAUNT":
			_state_taunt(delta)
		"SHADOW_BOLT":
			_state_shadow_bolt(delta)
		"DARK_RAIN":
			_state_dark_rain(delta)
		"PHASE_TRANSITION":
			_state_phase_transition(delta)


# =============================================================================
# STATE: APPROACH
# =============================================================================

func _state_approach(_delta: float) -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return

	var dir_to_player: float = sign(player_ref.global_position.x - global_position.x)
	_facing_right = dir_to_player > 0
	sprite.flip_h = not _facing_right

	velocity.x = dir_to_player * base_speed * speed_multiplier

	var player_above: bool = (player_ref.global_position.y < global_position.y - JUMP_HEIGHT_THRESHOLD)
	if is_on_floor() and (is_on_wall() or player_above):
		velocity.y = APPROACH_JUMP_VELOCITY

	if not is_invincible:
		_set_boss_tint(TINT_DARK)

	# -- Approach taunt (max once per 3 cycles, respecting cooldown) --
	approach_cycles_since_taunt += 1

	var dist_to_player: float = global_position.distance_to(player_ref.global_position)
	var approach_elapsed: bool = state_timer >= approach_time

	if dist_to_player < TELEGRAPH_TRIGGER_DISTANCE or approach_elapsed:
		_enter_state("TELEGRAPH")


# =============================================================================
# STATE: TELEGRAPH
# =============================================================================

func _state_telegraph(delta: float) -> void:
	velocity.x = 0.0

	_telegraph_flash_timer += delta
	var flash_cycle: int = int(_telegraph_flash_timer / 0.1)
	if flash_cycle % 2 == 0:
		_set_boss_tint(TINT_TELEGRAPH_YELLOW)
	else:
		_set_boss_tint(TINT_TELEGRAPH_RED)

	if state_timer >= telegraph_time:
		_remove_telegraph_label()

		# Choose attack based on distance + phase
		var chosen_attack: String = _choose_attack()

		if chosen_attack == "SHADOW_BOLT":
			_enter_state("SHADOW_BOLT")
		elif chosen_attack == "DARK_RAIN":
			_enter_state("DARK_RAIN")
		else:
			attack_type = chosen_attack
			_enter_state("ATTACK")


# =============================================================================
# ATTACK SELECTION (contextual, not alternating)
# =============================================================================

func _choose_attack() -> String:
	## Picks an attack based on distance to player and current phase.
	if player_ref == null or not is_instance_valid(player_ref):
		return "LEAP"

	var dist: float = global_position.distance_to(player_ref.global_position)
	var roll: float = _rng.randf()

	# Check for DARK_RAIN (lv10, phase 3 only)
	if current_phase >= 3 and level_num >= 10:
		if not _dark_rain_used_initial:
			_dark_rain_used_initial = true
			return "DARK_RAIN"
		if roll < 0.2:
			return "DARK_RAIN"
		# Re-roll for the remaining attacks
		roll = _rng.randf()

	var has_bolt: bool = current_phase >= 2

	if dist > 200.0 and has_bolt:
		# Far range: favor shadow bolt
		if roll < 0.6:
			return "SHADOW_BOLT"
		elif roll < 0.9:
			return "LEAP"
		else:
			return "SWING"
	elif dist < 120.0:
		# Close range: favor swing
		if roll < 0.6:
			return "SWING"
		elif roll < 0.9:
			return "LEAP"
		elif has_bolt:
			return "SHADOW_BOLT"
		else:
			return "SWING"
	else:
		# Mid range: favor leap
		if roll < 0.5:
			return "LEAP"
		elif roll < 0.8:
			return "SWING"
		elif has_bolt:
			return "SHADOW_BOLT"
		else:
			return "LEAP"


# =============================================================================
# STATE: ATTACK (LEAP or SWING)
# =============================================================================

func _state_attack(_delta: float) -> void:
	_set_boss_tint(TINT_ATTACK)

	if player_ref == null or not is_instance_valid(player_ref):
		return

	if attack_type == "LEAP":
		_attack_leap()
	else:
		_attack_mace_swing()

	if state_timer >= ATTACK_DURATION:
		if attack_type == "LEAP":
			if is_on_floor():
				if not _shockwave_spawned:
					_spawn_shockwave()
					_shockwave_spawned = true
				_enter_state("RECOVER")
		else:
			_enter_state("RECOVER")


func _attack_leap() -> void:
	if not _leap_launched:
		_leap_launched = true

		var dir: float = sign(player_ref.global_position.x - global_position.x)
		_facing_right = dir > 0
		sprite.flip_h = not _facing_right

		velocity.y = LEAP_JUMP_VELOCITY
		velocity.x = dir * LEAP_HORIZONTAL_SPEED * speed_multiplier

		_show_action_text("LEAP!", TINT_ATTACK)
		AudioManager.play_sfx("jump")


func _attack_mace_swing() -> void:
	velocity.x = 0.0

	if not _swing_visual_spawned:
		_swing_visual_spawned = true

		_show_action_text("SWING!", COLOR_MAGENTA)
		_spawn_mace_swing_visual()
		AudioManager.play_sfx("stomp")

		if player_ref != null and is_instance_valid(player_ref):
			var dist: float = global_position.distance_to(player_ref.global_position)
			if dist < MACE_SWING_RADIUS:
				player_ref.hit(1)
				_try_taunt("hit_player")


# =============================================================================
# STATE: SHADOW_BOLT (Phase 2+ ranged attack)
# =============================================================================

func _state_shadow_bolt(delta: float) -> void:
	velocity.x = 0.0

	if not _shadow_bolt_fired:
		# Charge-up phase: boss glows brighter
		_shadow_bolt_charge_timer += delta
		var charge_ratio: float = _shadow_bolt_charge_timer / SHADOW_BOLT_CHARGE_TIME
		_set_boss_tint(TINT_DARK.lerp(Color(0.6, 0.0, 0.6), charge_ratio))

		if not _shadow_bolt_fired and _shadow_bolt_charge_timer < SHADOW_BOLT_CHARGE_TIME:
			if not is_instance_valid(action_label):
				_show_action_text("...", COLOR_MAGENTA)
			return

		# Fire!
		_shadow_bolt_fired = true
		_remove_action_label()
		_show_action_text("SHADOW BOLT!", COLOR_MAGENTA)
		_spawn_shadow_bolt()
		AudioManager.play_sfx("stomp")
		_set_boss_tint(TINT_ATTACK)

	# After firing, wait briefly then recover
	if _shadow_bolt_fired and state_timer >= SHADOW_BOLT_CHARGE_TIME + 0.3:
		_enter_state("RECOVER")


func _spawn_shadow_bolt() -> void:
	## Fires a magenta diamond projectile toward the player's current position.
	if player_ref == null or not is_instance_valid(player_ref):
		return

	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var spawn_pos: Vector2 = global_position + Vector2(0, -10)
	var target_pos: Vector2 = player_ref.global_position
	var direction: Vector2 = (target_pos - spawn_pos).normalized()

	var bolt := Node2D.new()
	bolt.name = "ShadowBolt"
	bolt.position = spawn_pos
	bolt.z_index = 60

	# 8x8 magenta diamond (rotated square)
	var diamond := ColorRect.new()
	diamond.size = Vector2(8, 8)
	diamond.position = Vector2(-4, -4)
	diamond.color = COLOR_MAGENTA
	diamond.rotation_degrees = 45.0
	bolt.add_child(diamond)

	# Glow effect
	var glow := ColorRect.new()
	glow.size = Vector2(12, 12)
	glow.position = Vector2(-6, -6)
	glow.color = Color(COLOR_MAGENTA.r, COLOR_MAGENTA.g, COLOR_MAGENTA.b, 0.3)
	glow.rotation_degrees = 45.0
	bolt.add_child(glow)

	bolt.set_meta("velocity", direction * SHADOW_BOLT_SPEED)
	bolt.set_meta("lifetime", SHADOW_BOLT_LIFETIME)
	bolt.set_meta("is_boss_projectile", true)

	parent_node.add_child(bolt)


# =============================================================================
# STATE: DARK_RAIN (Level 10 Phase 3 only)
# =============================================================================

func _state_dark_rain(delta: float) -> void:
	if not _dark_rain_started:
		_dark_rain_started = true
		_dark_rain_bolts_spawned = 0
		_dark_rain_spawn_timer = 0.0
		_dark_rain_warnings_shown = false

		_show_action_text("DARK RAIN!", Color(1.0, 0.0, 1.0))

		# Jump to arena center
		var parent_node: Node = get_parent()
		if parent_node != null:
			# Estimate arena center from current position
			velocity.y = -400.0
			velocity.x = 0.0

	# Hover at top briefly (clamp fall speed)
	if velocity.y > 50.0:
		velocity.y = 50.0

	_set_boss_tint(TINT_PHASE_TRANSITION)

	# Show warning markers on ground before bolts arrive
	if not _dark_rain_warnings_shown and state_timer >= 0.3:
		_dark_rain_warnings_shown = true
		_spawn_dark_rain_warnings()

	# Spawn bolts at staggered intervals
	if state_timer >= DARK_RAIN_WARNING_TIME:
		_dark_rain_spawn_timer += delta
		while _dark_rain_bolts_spawned < DARK_RAIN_BOLT_COUNT and _dark_rain_spawn_timer >= DARK_RAIN_STAGGER:
			_dark_rain_spawn_timer -= DARK_RAIN_STAGGER
			_spawn_dark_rain_bolt(_dark_rain_bolts_spawned)
			_dark_rain_bolts_spawned += 1

	# All bolts spawned + extra time for them to land
	var total_time: float = DARK_RAIN_WARNING_TIME + (DARK_RAIN_BOLT_COUNT * DARK_RAIN_STAGGER) + 0.8
	if state_timer >= total_time:
		_enter_state("RECOVER")


func _spawn_dark_rain_warnings() -> void:
	## Flashing red markers on the ground showing where bolts will fall.
	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var base_x: float = global_position.x
	var ground_y: float = global_position.y + 100  # Approximate ground level

	for i in DARK_RAIN_BOLT_COUNT:
		var offset_x: float = (i - 2) * 60.0  # Spread: -120, -60, 0, 60, 120
		var marker := ColorRect.new()
		marker.size = Vector2(16, 4)
		marker.position = Vector2(base_x + offset_x - 8, ground_y)
		marker.color = Color(1.0, 0.0, 0.0, 0.6)
		marker.z_index = 40
		parent_node.add_child(marker)

		# Flash and fade
		var tween := _track_tween(parent_node.create_tween())
		tween.tween_property(marker, "modulate:a", 0.2, 0.15)
		tween.tween_property(marker, "modulate:a", 1.0, 0.15)
		tween.tween_property(marker, "modulate:a", 0.2, 0.15)
		tween.tween_property(marker, "modulate:a", 1.0, 0.15)
		tween.tween_callback(marker.queue_free)


func _spawn_dark_rain_bolt(index: int) -> void:
	## Spawns a single shadow bolt falling from the top of the screen.
	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var base_x: float = global_position.x
	var offset_x: float = (index - 2) * 60.0 + _rng.randf_range(-10.0, 10.0)
	var spawn_y: float = global_position.y - 200  # Well above the boss

	var bolt := Node2D.new()
	bolt.name = "DarkRainBolt_%d" % index
	bolt.position = Vector2(base_x + offset_x, spawn_y)
	bolt.z_index = 60

	var diamond := ColorRect.new()
	diamond.size = Vector2(8, 8)
	diamond.position = Vector2(-4, -4)
	diamond.color = COLOR_MAGENTA
	diamond.rotation_degrees = 45.0
	bolt.add_child(diamond)

	var trail := ColorRect.new()
	trail.size = Vector2(4, 16)
	trail.position = Vector2(-2, -20)
	trail.color = Color(COLOR_MAGENTA.r, COLOR_MAGENTA.g, COLOR_MAGENTA.b, 0.5)
	bolt.add_child(trail)

	bolt.set_meta("velocity", Vector2(0, DARK_RAIN_BOLT_SPEED))
	bolt.set_meta("lifetime", 2.0)
	bolt.set_meta("is_boss_projectile", true)

	parent_node.add_child(bolt)
	AudioManager.play_sfx("jump")


# =============================================================================
# STATE: RECOVER
# =============================================================================

func _state_recover(delta: float) -> void:
	velocity.x = 0.0

	var time_ms: float = float(Time.get_ticks_msec())
	rotation_degrees = sin(time_ms / 100.0) * 5.0

	var effective_recover_time: float = recover_time / speed_multiplier

	var time_remaining: float = effective_recover_time - state_timer
	if time_remaining < 0.5:
		var flash_cycle: int = int(state_timer / 0.1)
		if flash_cycle % 2 == 0:
			_set_boss_tint(TINT_RECOVER)
		else:
			_set_boss_tint(TINT_RECOVER_LIGHT)
	else:
		if not is_invincible:
			_set_boss_tint(TINT_RECOVER)

	if state_timer >= effective_recover_time:
		rotation_degrees = 0.0
		_remove_action_label()

		# 30% chance of taunt state between recover and approach (if cooldown allows)
		if taunt_cooldown <= 0.0 and _rng.randf() < 0.3:
			_enter_state("TAUNT")
		else:
			_enter_state("APPROACH")


# =============================================================================
# STATE: TAUNT (personality breather between cycles)
# =============================================================================

func _state_taunt(_delta: float) -> void:
	velocity.x = 0.0

	if not is_invincible:
		_set_boss_tint(TINT_DARK)

	# Taunt lasts 1.5s, NOT vulnerable (distinct from RECOVER)
	if state_timer >= 1.5:
		_remove_taunt_bubble()
		_enter_state("APPROACH")


# =============================================================================
# STATE: PHASE_TRANSITION (dramatic moment on phase change)
# =============================================================================

func _state_phase_transition(_delta: float) -> void:
	velocity.x = 0.0

	# Brief invincibility during transition
	is_invincible = true

	# Flash effect
	var flash_cycle: int = int(state_timer / 0.08)
	if flash_cycle % 2 == 0:
		_set_boss_tint(Color.WHITE)
	else:
		_set_boss_tint(TINT_PHASE_TRANSITION)

	# Show phase taunt at start
	if state_timer < 0.1:
		var category: String
		if current_phase == 3:
			category = "phase3_lv10" if level_num >= 10 else "phase3"
		else:
			category = "phase2"
		_show_taunt(_pick_taunt(category))

	# Duration: 1.5s
	if state_timer >= 1.5:
		is_invincible = false
		_remove_taunt_bubble()
		_enter_state("APPROACH")


# =============================================================================
# STATE TRANSITIONS
# =============================================================================

func _enter_state(new_state: String) -> void:
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
		"SHADOW_BOLT":
			_remove_action_label()
			_shadow_bolt_fired = false
			_shadow_bolt_charge_timer = 0.0
		"DARK_RAIN":
			_remove_action_label()
			_dark_rain_started = false
		"TAUNT":
			_remove_taunt_bubble()
		"PHASE_TRANSITION":
			_remove_taunt_bubble()

	# -- Set up new state --
	match new_state:
		"APPROACH":
			_set_boss_tint(TINT_DARK)
			# Maybe show approach taunt
			if approach_cycles_since_taunt >= 3 and taunt_cooldown <= 0.0:
				if _rng.randf() < 0.4:
					_try_taunt("approach")
					approach_cycles_since_taunt = 0
		"TELEGRAPH":
			_telegraph_flash_timer = 0.0
			_show_telegraph_label()
		"ATTACK":
			_set_boss_tint(TINT_ATTACK)
			_shockwave_spawned = false
			_swing_visual_spawned = false
			_leap_launched = false
		"RECOVER":
			_set_boss_tint(TINT_RECOVER)
			# Show recover taunt instead of generic "TIRED..."
			var recover_line: String = _pick_taunt("recover")
			_show_action_text(recover_line, Color("88ff88"))
		"SHADOW_BOLT":
			_shadow_bolt_fired = false
			_shadow_bolt_charge_timer = 0.0
		"DARK_RAIN":
			_dark_rain_started = false
			_dark_rain_bolts_spawned = 0
			_dark_rain_spawn_timer = 0.0
			_dark_rain_warnings_shown = false
		"TAUNT":
			# Pick a context-appropriate taunt
			var category: String = "approach"
			if current_phase == 3:
				category = "phase3_lv10" if level_num >= 10 else "phase3"
			elif current_phase == 2:
				category = "phase2"
			_show_taunt(_pick_taunt(category))
			taunt_cooldown = 3.0


# =============================================================================
# DAMAGE SYSTEM
# =============================================================================

func take_damage(amount: int = 1) -> void:
	if is_invincible or state == "DEAD":
		return

	health -= amount
	if health < 0:
		health = 0

	_update_health_bar()

	Events.boss_damaged.emit(health, max_health)
	AudioManager.play_sfx("stomp")

	_show_floating_text(
		"HIT! %d/%d" % [max_health - health, max_health],
		Color.WHITE,
		global_position + Vector2(0, -60)
	)

	# Stomp taunt
	_try_taunt("stomped")

	if player_ref != null and is_instance_valid(player_ref):
		var knockback_dir: float = sign(global_position.x - player_ref.global_position.x)
		if knockback_dir == 0:
			knockback_dir = 1.0
		velocity.x = knockback_dir * 200.0
		velocity.y = -150.0

	is_invincible = true

	var flash_tween := _track_tween(create_tween())
	var flash_color := Color.WHITE
	flash_color.a = sprite.modulate.a
	flash_tween.tween_property(sprite, "modulate", flash_color, 0.05)
	flash_tween.tween_interval(0.1)

	if health <= 0:
		defeat_sequence()
		return

	# Near death taunt (1 HP)
	if health == 1:
		if level_num >= 10:
			_try_taunt("near_death_lv10")
		else:
			_try_taunt("near_death")

	# Check for phase transition
	flash_tween.tween_callback(func():
		if state != "DEAD" and state != "PHASE_TRANSITION":
			_check_phase_transition()
			# If no phase transition happened, go to APPROACH
			if state != "PHASE_TRANSITION":
				_enter_state("APPROACH")
	)

	flash_tween.tween_interval(HIT_INVINCIBILITY_TIME)
	flash_tween.tween_callback(func():
		if state != "PHASE_TRANSITION":
			is_invincible = false
	)


func hit_by_stomp() -> void:
	take_damage(1)


func hit_by_melee() -> void:
	if state == "RECOVER":
		take_damage(1)


# =============================================================================
# DEFEAT SEQUENCE
# =============================================================================

func defeat_sequence() -> void:
	state = "DEAD"
	ai_active = false
	velocity = Vector2.ZERO
	rotation_degrees = 0.0

	# Personality defeat line
	var defeat_text: String
	if level_num >= 10:
		defeat_text = _pick_taunt("defeat_lv10")
	else:
		defeat_text = _pick_taunt("defeat")
	_show_action_text(defeat_text, COLOR_MAGENTA)

	var flash_tween := _track_tween(create_tween())
	for i in 10:
		if i % 2 == 0:
			var flash_color := Color.WHITE
			flash_color.a = sprite.modulate.a
			flash_tween.tween_property(sprite, "modulate", flash_color, 0.05)
		else:
			var hurt_color := Color.RED
			hurt_color.a = sprite.modulate.a
			flash_tween.tween_property(sprite, "modulate", hurt_color, 0.05)

	await flash_tween.finished

	_spawn_defeat_particles()

	# Clean up any remaining boss projectiles
	_cleanup_boss_projectiles()

	var fade_tween := _track_tween(create_tween())
	fade_tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	await fade_tween.finished

	GameState.score += DEFEAT_SCORE
	Events.score_changed.emit(GameState.score)
	_show_floating_text(
		"+%d POINTS!" % DEFEAT_SCORE,
		Color.YELLOW,
		global_position + Vector2(0, -80)
	)

	if health_bar_layer != null and is_instance_valid(health_bar_layer):
		health_bar_layer.queue_free()
		health_bar_layer = null

	_remove_taunt_bubble()

	Events.boss_defeated.emit()


func _cleanup_boss_projectiles() -> void:
	## Remove all shadow bolt / dark rain projectiles from the scene.
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	for child in parent_node.get_children():
		if child.has_meta("is_boss_projectile"):
			child.queue_free()

# =============================================================================
# TAUNT DISPLAY SYSTEM
# =============================================================================

func _pick_taunt(category: String) -> String:
	## Returns a random line from the given category.
	var lines: Array = taunt_lines.get(category, [])
	if lines.is_empty():
		return ""
	return lines[_rng.randi_range(0, lines.size() - 1)]


func _try_taunt(category: String) -> void:
	## Shows a taunt if cooldown allows. Respects the 3s minimum between taunts.
	if taunt_cooldown > 0.0:
		return
	var text: String = _pick_taunt(category)
	if text.is_empty():
		return
	_show_taunt(text)
	taunt_cooldown = 3.0


func _show_taunt(text: String) -> void:
	## Displays a speech bubble above the boss with the given text.
	## Auto-fades after 2 seconds. Uses a CanvasLayer to stay on screen.
	if text.is_empty():
		return

	_remove_taunt_bubble()

	# Create a simple speech bubble as a child of the boss (moves with it)
	_taunt_bubble = Control.new()
	_taunt_bubble.name = "TauntBubble"
	_taunt_bubble.z_index = 110
	_taunt_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Background panel
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.8)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_taunt_bubble.add_child(bg)

	# Text label
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", COLOR_MAGENTA)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Size the bubble to fit text
	var text_width: float = minf(text.length() * 8.0, 250.0)
	label.size = Vector2(text_width, 0)
	label.position = Vector2(4, 4)

	bg.size = Vector2(text_width + 8, 40)
	bg.position = Vector2(0, 0)

	_taunt_bubble.add_child(label)
	_taunt_bubble.position = Vector2(-text_width * 0.5, -110)
	_taunt_bubble.size = Vector2(text_width + 8, 40)

	add_child(_taunt_bubble)

	# Auto-fade after 2 seconds
	var fade_tween := _track_tween(create_tween())
	fade_tween.tween_interval(1.5)
	fade_tween.tween_property(_taunt_bubble, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(func():
		_remove_taunt_bubble()
	)


func _remove_taunt_bubble() -> void:
	if _taunt_bubble != null and is_instance_valid(_taunt_bubble):
		_taunt_bubble.queue_free()
		_taunt_bubble = null


# =============================================================================
# VISUAL EFFECTS
# =============================================================================

func _show_telegraph_label() -> void:
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
	if telegraph_label != null and is_instance_valid(telegraph_label):
		telegraph_label.queue_free()
		telegraph_label = null


func _show_action_text(text: String, color: Color) -> void:
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
	if action_label != null and is_instance_valid(action_label):
		action_label.queue_free()
		action_label = null


func _show_floating_text(text: String, color: Color, pos: Vector2) -> void:
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

	var tween := _track_tween(parent_node.create_tween())
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 60.0, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.chain().tween_callback(label.queue_free)


func _spawn_mace_swing_visual() -> void:
	var swing_dir: float = -1.0 if _facing_right else 1.0
	var offset_x: float = swing_dir * -MACE_SWING_ARC_RADIUS * 0.5

	var arc := ColorRect.new()
	arc.size = Vector2(MACE_SWING_ARC_RADIUS * 2.0, MACE_SWING_ARC_RADIUS)
	arc.position = Vector2(offset_x - MACE_SWING_ARC_RADIUS, -MACE_SWING_ARC_RADIUS * 0.5)
	arc.color = Color(COLOR_MAGENTA.r, COLOR_MAGENTA.g, COLOR_MAGENTA.b, 0.5)
	arc.z_index = 50
	add_child(arc)

	var tween := _track_tween(create_tween())
	tween.tween_property(arc, "modulate:a", 0.0, 0.3)
	tween.tween_callback(arc.queue_free)


func _spawn_shockwave() -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var wave_left := ColorRect.new()
	wave_left.size = Vector2(20.0, 8.0)
	wave_left.position = global_position + Vector2(-10.0, 20.0)
	wave_left.color = Color(COLOR_MAGENTA.r, COLOR_MAGENTA.g, COLOR_MAGENTA.b, 0.7)
	wave_left.z_index = 50
	parent_node.add_child(wave_left)

	var wave_right := ColorRect.new()
	wave_right.size = Vector2(20.0, 8.0)
	wave_right.position = global_position + Vector2(-10.0, 20.0)
	wave_right.color = Color(COLOR_MAGENTA.r, COLOR_MAGENTA.g, COLOR_MAGENTA.b, 0.7)
	wave_right.z_index = 50
	parent_node.add_child(wave_right)

	var tween_left := _track_tween(parent_node.create_tween())
	tween_left.set_parallel(true)
	tween_left.tween_property(wave_left, "position:x", global_position.x - 150.0, 0.4)
	tween_left.tween_property(wave_left, "size:x", 80.0, 0.4)
	tween_left.tween_property(wave_left, "modulate:a", 0.0, 0.4)
	tween_left.chain().tween_callback(wave_left.queue_free)

	var tween_right := _track_tween(parent_node.create_tween())
	tween_right.set_parallel(true)
	tween_right.tween_property(wave_right, "position:x", global_position.x + 80.0, 0.4)
	tween_right.tween_property(wave_right, "size:x", 80.0, 0.4)
	tween_right.tween_property(wave_right, "modulate:a", 0.0, 0.4)
	tween_right.chain().tween_callback(wave_right.queue_free)

	AudioManager.play_sfx("land")


func _spawn_defeat_particles() -> void:
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

		var angle: float = rng.randf_range(0.0, TAU)
		var speed: float = rng.randf_range(80.0, 200.0)
		var end_pos: Vector2 = particle.position + Vector2(cos(angle), sin(angle)) * speed

		var tween := _track_tween(parent_node.create_tween())
		tween.set_parallel(true)
		tween.tween_property(particle, "position", end_pos, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(particle, "modulate:a", 0.0, 0.6)
		tween.chain().tween_callback(particle.queue_free)


func _track_tween(tween: Tween) -> Tween:
	_tracked_tweens.append(tween)
	return tween


func _make_delay(duration: float) -> Signal:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = duration
	add_child(timer)
	_tracked_timers.append(timer)
	timer.timeout.connect(func():
		_tracked_timers.erase(timer)
		if is_instance_valid(timer):
			timer.queue_free()
	, CONNECT_ONE_SHOT)
	timer.start()
	return timer.timeout


func _cleanup_async_resources() -> void:
	for tween in _tracked_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_tracked_tweens.clear()

	for timer in _tracked_timers:
		if timer and is_instance_valid(timer):
			timer.stop()
			timer.queue_free()
	_tracked_timers.clear()

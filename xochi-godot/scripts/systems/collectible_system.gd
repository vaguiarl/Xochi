extends Node
class_name CollectibleSystem
## Manages ALL collectible pickups in Xochi: flowers, elotes, powerups,
## luchador masks, and baby rescue celebrations.
##
## Converts the visual-only Node2D markers created by GameScene into
## interactive pickups using distance-based overlap checks in _physics_process.
## Each collectible type has unique rewards, VFX, and state mutations that are
## exact ports from the original game.js.
##
## Usage:
##   var cs = CollectibleSystem.new()
##   cs.setup(self, player, collectibles_node)
##   add_child(cs)
##
## Required autoloads: Events, GameState, AudioManager


# =============================================================================
# PICKUP RADII -- distance thresholds for each collectible type
# =============================================================================

## Flowers (coins) -- small, plentiful, tight radius for satisfying collection.
const FLOWER_PICKUP_RADIUS: float = 30.0

## Elotes (stars) -- slightly larger radius, rare and important.
const ELOTE_PICKUP_RADIUS: float = 35.0

## Powerups -- same tight feel as flowers.
const POWERUP_PICKUP_RADIUS: float = 30.0

## Luchador mask -- generous radius, one per level, exciting moment.
const LUCHADOR_PICKUP_RADIUS: float = 35.0


# =============================================================================
# REWARD VALUES
# =============================================================================

## Score awarded per flower collected.
const FLOWER_SCORE: int = 10

## Score awarded per elote collected.
const ELOTE_SCORE: int = 500

## Score awarded per luchador mask collected.
const LUCHADOR_SCORE: int = 1000

## Flowers needed for a bonus super jump.
const FLOWERS_PER_SUPER_JUMP: int = 10

## Flowers needed for an extra life (consumed on award).
const FLOWERS_PER_LIFE: int = 100

## Duration of elote invincibility in seconds.
const ELOTE_INVINCIBILITY_DURATION: float = 8.0

## Duration of luchador mode in seconds.
const LUCHADOR_DURATION: float = 15.0

## Interval between elote particle trail spawns in seconds.
const ELOTE_TRAIL_INTERVAL: float = 0.1


# =============================================================================
# VFX CONSTANTS
# =============================================================================

## Duration of floating score text animation.
const FLOAT_TEXT_DURATION: float = 0.6

## Pixels the floating text rises during animation.
const FLOAT_TEXT_RISE: float = 30.0

## Duration of big announcement text animation.
const BIG_TEXT_DURATION: float = 1.0

## Scale multiplier for big text pop effect.
const BIG_TEXT_SCALE: float = 1.3

## Default particle burst count.
const DEFAULT_PARTICLE_COUNT: int = 8

## Particle burst radius in pixels.
const DEFAULT_PARTICLE_RADIUS: float = 50.0

## Particle fade-out duration in seconds.
const PARTICLE_DURATION: float = 0.6


# =============================================================================
# REFERENCES
# =============================================================================

## The root GameScene node (used for spawning VFX, accessing level data).
var scene: Node2D

## The player CharacterBody2D.
var player: CharacterBody2D

## The Node2D container holding all collectible marker nodes.
var collectibles_node: Node2D

## CanvasLayer for big announcement text, created once and reused.
var _text_canvas: CanvasLayer

## Timer node for the elote particle trail effect.
var _elote_trail_timer: Timer

## Whether the elote trail is currently active.
var _elote_trail_active: bool = false

## Whether the luchador mask has been spawned for this level.
var _luchador_spawned: bool = false


# =============================================================================
# LIFECYCLE
# =============================================================================

## Wire up references after the game scene is fully initialized.
## Must be called before the first _physics_process tick.
func setup(game_scene: Node2D, p_player: CharacterBody2D, p_collectibles: Node2D) -> void:
	scene = game_scene
	player = p_player
	collectibles_node = p_collectibles

	# Create a persistent CanvasLayer for big text announcements.
	# Layer 15 puts it above gameplay but below pause overlay (50).
	_text_canvas = CanvasLayer.new()
	_text_canvas.name = "CollectibleTextLayer"
	_text_canvas.layer = 15
	scene.add_child(_text_canvas)

	# Create the elote particle trail timer (reusable).
	_elote_trail_timer = Timer.new()
	_elote_trail_timer.name = "EloteTrailTimer"
	_elote_trail_timer.wait_time = ELOTE_TRAIL_INTERVAL
	_elote_trail_timer.one_shot = false
	_elote_trail_timer.timeout.connect(_on_elote_trail_tick)
	add_child(_elote_trail_timer)

	# Spawn the luchador mask on a random platform in the middle third.
	_spawn_luchador_mask()


func _physics_process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	if player.is_dead:
		return
	if collectibles_node == null:
		return

	_check_pickups()


# =============================================================================
# PICKUP DETECTION -- distance-based overlap checks every physics tick
# =============================================================================

func _check_pickups() -> void:
	## Iterate all collectible children and check distance to the player.
	## When within pickup radius, trigger the appropriate collection behavior.
	## We snapshot the children array because pickups call queue_free().
	var items: Array = collectibles_node.get_children().duplicate()
	var player_pos: Vector2 = player.global_position

	for item in items:
		if not is_instance_valid(item):
			continue

		var item_type: String = item.get_meta("type", "")
		var distance: float = player_pos.distance_to(item.global_position)

		match item_type:
			"flower":
				if distance < FLOWER_PICKUP_RADIUS:
					_collect_flower(item)

			"elote":
				if distance < ELOTE_PICKUP_RADIUS:
					_collect_elote(item)

			"powerup":
				if distance < POWERUP_PICKUP_RADIUS:
					_collect_powerup(item)

			"luchador":
				if distance < LUCHADOR_PICKUP_RADIUS:
					_collect_luchador(item)

			# Baby is handled by game_scene.gd _check_baby_pickup().
			# We do NOT duplicate that logic here.


# =============================================================================
# FLOWER COLLECTION (original game.js lines 5498-5543)
# =============================================================================

func _collect_flower(item: Node2D) -> void:
	var pos: Vector2 = item.global_position

	# Award score
	GameState.score += FLOWER_SCORE
	Events.score_changed.emit(GameState.score)

	# Increment flower count
	GameState.flowers += 1

	# Play SFX
	AudioManager.play_sfx("flower")

	# Floating "+10" text in orange
	_show_floating_text(pos, "+%d" % FLOWER_SCORE, Color("ff8c00"))

	# Orange petal particle burst
	_create_particle_burst(pos, DEFAULT_PARTICLE_COUNT, Color("ff8c00"), DEFAULT_PARTICLE_RADIUS)

	# Bonus: every 10 flowers grants +1 super jump
	if GameState.flowers % FLOWERS_PER_SUPER_JUMP == 0:
		GameState.super_jumps += 1
		Events.super_jump_gained.emit()
		_show_big_text("+1 SUPER JUMP!", Color("00ffff"))

	# Bonus: every 100 flowers grants an extra life (costs 100 flowers)
	if GameState.flowers >= FLOWERS_PER_LIFE:
		GameState.flowers -= FLOWERS_PER_LIFE
		GameState.lives += 1
		_show_big_text("1UP!", Color("ff8c00"))

	# Emit collection signal with updated count
	Events.flower_collected.emit(GameState.flowers)

	# Remove the collectible from the scene tree
	item.queue_free()


# =============================================================================
# ELOTE COLLECTION (original game.js lines 5547-5605)
# =============================================================================

func _collect_elote(item: Node2D) -> void:
	var index: int = item.get_meta("index", 0)
	var level_num: int = scene.get("level_num") if scene.get("level_num") != null else GameState.current_level
	var elote_id: String = "%d-%d" % [level_num, index]

	# Skip if already collected in a previous session
	if elote_id in GameState.stars:
		item.queue_free()
		return

	var pos: Vector2 = item.global_position

	# Award score
	GameState.score += ELOTE_SCORE
	Events.score_changed.emit(GameState.score)

	# Record collection
	GameState.stars.append(elote_id)

	# Play SFX
	AudioManager.play_sfx("powerup")

	# Big announcement text
	_show_big_text("ELOTE! INVINCIBLE!", Color("ffd700"))

	# Gold particle burst at pickup location
	_create_particle_burst(pos, 12, Color("ffd700"), 60.0)

	# Activate 8-second invincibility with golden glow on the player
	if player.has_method("activate_elote_invincibility"):
		player.activate_elote_invincibility(ELOTE_INVINCIBILITY_DURATION)

	# Start the corn kernel particle trail for the invincibility duration
	_start_elote_trail(ELOTE_INVINCIBILITY_DURATION)

	# Emit collection signal
	Events.elote_collected.emit(level_num, index)

	# Save progress immediately (elotes are permanent collectibles)
	GameState.save_game()

	# Remove the collectible
	item.queue_free()


# =============================================================================
# POWERUP COLLECTION (original game.js lines 5488-5495)
# =============================================================================
# In the original, ALL powerups from level data are "super_jump" type,
# and they grant BOTH +1 super jump AND +1 mace attack.

func _collect_powerup(item: Node2D) -> void:
	var pos: Vector2 = item.global_position

	# Grant both resources (exact from original -- every powerup is dual)
	GameState.super_jumps += 1
	GameState.mace_attacks += 1

	# Play SFX
	AudioManager.play_sfx("powerup")

	# Big announcement text
	_show_big_text("+1 JUMP! +1 THUNDER!", Color("00ffff"))

	# Cyan particle burst
	_create_particle_burst(pos, DEFAULT_PARTICLE_COUNT, Color("00ffff"), DEFAULT_PARTICLE_RADIUS)

	# Emit signal
	Events.super_jump_gained.emit()

	# Remove the collectible
	item.queue_free()


# =============================================================================
# LUCHADOR MASK COLLECTION
# =============================================================================

func _collect_luchador(item: Node2D) -> void:
	var pos: Vector2 = item.global_position

	# Award score
	GameState.score += LUCHADOR_SCORE
	Events.score_changed.emit(GameState.score)

	# Play SFX
	AudioManager.play_sfx("powerup")

	# Big announcement text
	_show_big_text("LUCHADOR MODE!", Color("0066ff"))

	# Blue particle burst (16 particles, bigger spread)
	_create_particle_burst(pos, 16, Color("0066ff"), 70.0)

	# Activate luchador mode on the player
	if player.has_method("activate_luchador"):
		player.activate_luchador(LUCHADOR_DURATION)

	# Remove the collectible
	item.queue_free()


# =============================================================================
# LUCHADOR MASK SPAWNING -- one per level on a random platform
# =============================================================================

func _spawn_luchador_mask() -> void:
	## Find a platform in the middle third of the level and place a luchador mask
	## on top of it. This gives the player a powerful but temporary boost once
	## per level, rewarding exploration of the mid-section.

	if _luchador_spawned:
		return

	# Access level data from the game scene
	var level_data: Dictionary = scene.level_data if scene.get("level_data") != null else {}
	var platforms: Array = level_data.get("platforms", [])
	var level_width: float = level_data.get("width", 3000.0)

	if platforms.is_empty():
		return

	# Filter platforms in the middle third of the level
	var third: float = level_width / 3.0
	var mid_start: float = third
	var mid_end: float = third * 2.0
	var candidates: Array = []

	for plat in platforms:
		var px: float = 0.0
		var py: float = 0.0
		var pw: float = 100.0
		var ph: float = 20.0

		if plat is Dictionary:
			px = plat.get("x", 0.0)
			py = plat.get("y", 0.0)
			pw = plat.get("w", 100.0)
			ph = plat.get("h", 20.0)

		# Platform center must be in the middle third
		var center_x: float = px + pw * 0.5
		if center_x >= mid_start and center_x <= mid_end:
			# Skip very thick ground platforms (h > 40) -- those are floor segments
			if ph <= 40.0:
				candidates.append(plat)

	if candidates.is_empty():
		# Fallback: use any platform that is not a ground slab
		for plat in platforms:
			if plat is Dictionary and plat.get("h", 20.0) <= 40.0:
				candidates.append(plat)

	if candidates.is_empty():
		return

	# Pick a random candidate
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var chosen: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]

	var spawn_x: float = chosen.get("x", 0.0) + chosen.get("w", 100.0) * 0.5
	var spawn_y: float = chosen.get("y", 0.0) - 20.0  # 20 px above platform surface

	# Create the luchador mask marker (magenta diamond, similar style to powerups)
	var marker := Node2D.new()
	marker.name = "LuchadorMask"
	marker.position = Vector2(spawn_x, spawn_y)
	marker.set_meta("type", "luchador")
	marker.set_meta("base_y", spawn_y)
	marker.set_meta("bob_offset", randf() * TAU)

	# Diamond body -- magenta/blue
	var diamond := ColorRect.new()
	diamond.size = Vector2(20.0, 20.0)
	diamond.position = Vector2(-10.0, -10.0)
	diamond.rotation = PI / 4.0
	diamond.color = Color("0066ff")
	marker.add_child(diamond)

	# Inner mask shape -- white center
	var center := ColorRect.new()
	center.size = Vector2(10.0, 10.0)
	center.position = Vector2(-5.0, -5.0)
	center.color = Color("aaccff")
	marker.add_child(center)

	# Eye holes -- two small dark squares for the mask look
	var left_eye := ColorRect.new()
	left_eye.size = Vector2(3.0, 3.0)
	left_eye.position = Vector2(-5.0, -3.0)
	left_eye.color = Color("002244")
	marker.add_child(left_eye)

	var right_eye := ColorRect.new()
	right_eye.size = Vector2(3.0, 3.0)
	right_eye.position = Vector2(2.0, -3.0)
	right_eye.color = Color("002244")
	marker.add_child(right_eye)

	collectibles_node.add_child(marker)
	_luchador_spawned = true


# =============================================================================
# BABY RESCUE CELEBRATION
# =============================================================================
# The actual baby pickup detection and level completion logic lives in
# game_scene.gd _check_baby_pickup() -> _complete_level(). This function
# provides the celebratory VFX that should be called from there.

func celebrate_baby_rescue(baby_pos: Vector2) -> void:
	## Call this from game_scene.gd when the baby is picked up to add
	## the rescue celebration VFX: big text, particles, SFX.

	AudioManager.play_sfx("powerup")
	_show_big_text("BABY RESCUED!", Color("ff88aa"))

	# Pink particle burst (16 particles, big spread)
	_create_particle_burst(baby_pos, 16, Color("ff88aa"), 80.0)

	# Secondary gold sparkle burst
	_create_particle_burst(baby_pos, 8, Color("ffd700"), 50.0)


# =============================================================================
# VISUAL EFFECTS -- FLOATING TEXT
# =============================================================================

func _show_floating_text(pos: Vector2, text: String, color: Color) -> void:
	## Creates a Label at the world position that rises upward and fades out.
	## Used for score popups like "+10", "+500", etc.
	## The label is added to the scene (not CanvasLayer) so it moves with
	## the game world and feels spatially connected to the pickup location.

	var label := Label.new()
	label.text = text
	label.position = pos - Vector2(20.0, 15.0)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.z_index = 100

	# Drop shadow for readability against any background
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

	scene.add_child(label)

	# Tween: rise upward and fade out simultaneously
	var tween := scene.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 15.0 - FLOAT_TEXT_RISE, FLOAT_TEXT_DURATION)
	tween.tween_property(label, "modulate:a", 0.0, FLOAT_TEXT_DURATION)
	tween.chain().tween_callback(label.queue_free)


# =============================================================================
# VISUAL EFFECTS -- BIG ANNOUNCEMENT TEXT
# =============================================================================

func _show_big_text(text: String, color: Color) -> void:
	## Creates a large centered label on the CanvasLayer that scales up and
	## fades out. Used for milestone announcements like "+1 SUPER JUMP!",
	## "ELOTE! INVINCIBLE!", "LUCHADOR MODE!", "1UP!", etc.

	if _text_canvas == null:
		return

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Drop shadow for readability
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)

	# Position centered on screen. Viewport size fallback to 800x600.
	var viewport_size: Vector2 = Vector2(800.0, 600.0)
	var vp := get_viewport()
	if vp:
		viewport_size = vp.get_visible_rect().size
	label.position = Vector2(viewport_size.x * 0.5 - 200.0, viewport_size.y * 0.35)
	label.size = Vector2(400.0, 60.0)

	# Start at normal scale
	label.pivot_offset = Vector2(200.0, 30.0)
	label.scale = Vector2.ONE

	_text_canvas.add_child(label)

	# Tween: scale up to 1.3x while fading out over 1.0 second
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2(BIG_TEXT_SCALE, BIG_TEXT_SCALE), BIG_TEXT_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, BIG_TEXT_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(label.queue_free)


# =============================================================================
# VISUAL EFFECTS -- PARTICLE BURST
# =============================================================================

func _create_particle_burst(pos: Vector2, count: int, color: Color, radius: float = 50.0) -> void:
	## Creates a circular burst of small ColorRect particles that fly outward
	## from `pos` and fade out. Each particle gets a slightly randomized color
	## for visual richness. Particles are added to the scene (world-space).

	for i in count:
		var particle := ColorRect.new()
		particle.size = Vector2(4.0, 4.0)
		particle.position = pos - Vector2(2.0, 2.0)
		particle.z_index = 100

		# Vary color slightly for each particle (hue shift + brightness)
		var hue_shift: float = randf_range(-0.05, 0.05)
		var brightness_shift: float = randf_range(-0.15, 0.15)
		var particle_color := color
		particle_color.h = fmod(particle_color.h + hue_shift, 1.0)
		particle_color.v = clampf(particle_color.v + brightness_shift, 0.2, 1.0)
		particle.color = particle_color

		scene.add_child(particle)

		# Calculate target position in a circular pattern with slight randomness
		var angle: float = (float(i) / float(count)) * TAU + randf_range(-0.2, 0.2)
		var dist: float = radius * randf_range(0.6, 1.0)
		var target_x: float = pos.x + cos(angle) * dist
		var target_y: float = pos.y + sin(angle) * dist

		# Tween: fly outward and fade
		var tween := scene.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position:x", target_x - 2.0, PARTICLE_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(particle, "position:y", target_y - 2.0, PARTICLE_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(particle, "modulate:a", 0.0, PARTICLE_DURATION).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(particle.queue_free)


# =============================================================================
# VISUAL EFFECTS -- ELOTE PARTICLE TRAIL
# =============================================================================

func _start_elote_trail(duration: float) -> void:
	## Starts a repeating timer that spawns gold/yellow particles around the
	## player every 100ms, creating a glowing corn kernel trail effect during
	## elote invincibility. Auto-stops after the specified duration.

	_elote_trail_active = true
	_elote_trail_timer.start()

	# Schedule the trail to stop after the invincibility duration.
	# We use a one-shot timer so the trail persists exactly as long as the shield.
	var stop_timer := Timer.new()
	stop_timer.name = "EloteTrailStop"
	stop_timer.wait_time = duration
	stop_timer.one_shot = true
	stop_timer.timeout.connect(func():
		_stop_elote_trail()
		stop_timer.queue_free()
	)
	add_child(stop_timer)
	stop_timer.start()


func _stop_elote_trail() -> void:
	## Stops the elote particle trail.
	_elote_trail_active = false
	if _elote_trail_timer:
		_elote_trail_timer.stop()


func _on_elote_trail_tick() -> void:
	## Called every ELOTE_TRAIL_INTERVAL seconds while the trail is active.
	## Spawns 2-3 gold/yellow particles near the player that fall down and fade.

	if not _elote_trail_active:
		_elote_trail_timer.stop()
		return

	if player == null or not is_instance_valid(player):
		_stop_elote_trail()
		return

	# Spawn 2-3 particles near the player
	var spawn_count: int = randi_range(2, 3)
	for i in spawn_count:
		var particle := ColorRect.new()
		particle.size = Vector2(3.0, 3.0)

		# Scatter around the player position
		var offset_x: float = randf_range(-15.0, 15.0)
		var offset_y: float = randf_range(-20.0, 10.0)
		particle.position = player.global_position + Vector2(offset_x, offset_y)
		particle.z_index = 95

		# Random gold/yellow color
		var colors: Array[Color] = [
			Color("ffd700"),  # Gold
			Color("ffcc00"),  # Yellow-gold
			Color("ffaa00"),  # Dark gold
			Color("ffee44"),  # Bright yellow
		]
		particle.color = colors[randi() % colors.size()]

		scene.add_child(particle)

		# Particles fall downward 30 px and fade out
		var tween := scene.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position:y", particle.position.y + 30.0, 0.5)
		tween.tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.chain().tween_callback(particle.queue_free)


# =============================================================================
# CLEANUP
# =============================================================================

func _exit_tree() -> void:
	_stop_elote_trail()

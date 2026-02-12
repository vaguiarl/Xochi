extends Node2D
## GameScene -- the core gameplay scene for Xochi.
##
## This is the heart of the game. It loads a level from LevelData, builds
## the sky gradient, parallax layers, platforms, trajineras (moving boats),
## collectibles, water/death zones, the HUD, and manages the full game loop.
##
## Ported from the original game.js with special attention to:
##   - Six-layer parallax backgrounds (lines 842-1040)
##   - Trajinera movement system (the SOUL of the game)
##   - Camera zoom/follow (lines 3997-4025)
##   - World intro text with fade animation
##
## Required autoloads (declared in project.godot):
##   - Events             (global signal bus)
##   - GameState           (lives, super_jumps, mace_attacks, score, ...)
##   - AudioManager        (play_sfx / play_music / play_for_level)
##   - SceneManager        (scene transitions with fade)
##
## Required class:
##   - LevelData           (class_name LevelData, provides get_level_data())


# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when the player reaches the baby axolotl and completes the level.
signal level_completed(level_num: int)


# =============================================================================
# CONSTANTS
# =============================================================================

## Collision layers matching project.godot layer_names:
##   Layer 1 = World, Layer 2 = Platforms, Layer 3 = Player,
##   Layer 4 = Enemies, Layer 5 = Collectibles, Layer 6 = Boss
const COLLISION_LAYER_WORLD: int = 1
const COLLISION_LAYER_PLATFORMS: int = 2
const COLLISION_LAYER_PLAYER: int = 4
const COLLISION_LAYER_ENEMIES: int = 8
const COLLISION_LAYER_COLLECTIBLES: int = 16
const COLLISION_LAYER_BOSS: int = 32

## Z-index assignments for visual layering.
const Z_SKY: int = -110
const Z_PARALLAX_BASE: int = -100
const Z_WATER: int = -5
const Z_PLATFORMS: int = 0
const Z_COLLECTIBLES: int = 5
const Z_TRAJINERAS: int = 2
const Z_PLAYER: int = 10
const Z_ENEMIES: int = 8
const Z_HUD: int = 100

## Parallax layer configuration: [scroll_factor, alpha, description]
## Six layers from far background to near foreground.
const PARALLAX_LAYERS: Array = [
	{"scroll": 0.05, "alpha": 0.3, "name": "far_mountains"},
	{"scroll": 0.15, "alpha": 0.5, "name": "mid_mountains"},
	{"scroll": 0.25, "alpha": 0.65, "name": "rolling_hills"},
	{"scroll": 0.40, "alpha": 0.8, "name": "vegetation"},
	{"scroll": 0.60, "alpha": 0.4, "name": "mist_bands"},
	{"scroll": 0.80, "alpha": 1.0, "name": "foreground_grass"},
]

## Duration of world intro text display in seconds.
const WORLD_INTRO_DURATION: float = 3.0

## Duration of world intro fade animation in seconds.
const WORLD_INTRO_FADE_TIME: float = 0.8

## Collectible bob animation speed (radians per second).
const COLLECTIBLE_BOB_SPEED: float = 3.0

## Collectible bob amplitude in pixels.
const COLLECTIBLE_BOB_AMPLITUDE: float = 4.0

## Collectible pulse speed for elotes (radians per second).
const COLLECTIBLE_PULSE_SPEED: float = 4.0

## Baby axolotl sparkle speed (radians per second).
const BABY_SPARKLE_SPEED: float = 5.0

## Minimum distance from baby to trigger level completion.
const BABY_PICKUP_RADIUS: float = 40.0

## Trajinera vertical bob amplitude in pixels.
const TRAJINERA_BOB_AMPLITUDE: float = 2.0

## Trajinera vertical bob speed (radians per second).
const TRAJINERA_BOB_SPEED: float = 2.0

## Water surface wave amplitude in pixels.
const WATER_WAVE_AMPLITUDE: float = 3.0

## Water surface wave speed (radians per second).
const WATER_WAVE_SPEED: float = 1.5


# =============================================================================
# PRELOADED ASSETS
# =============================================================================

## Beautiful DKC-style pre-rendered 3D trajinera sprites (green screen removed)
const TRAJINERA_1: Texture2D = preload("res://assets/sprites/prerendered/environment/trajineras/trajinera_1.png")
const TRAJINERA_2: Texture2D = preload("res://assets/sprites/prerendered/environment/trajineras/trajinera_2.png")
const TRAJINERA_3: Texture2D = preload("res://assets/sprites/prerendered/environment/trajineras/trajinera_3.png")

## Array of all trajinera textures for random selection
const TRAJINERA_TEXTURES: Array[Texture2D] = [TRAJINERA_1, TRAJINERA_2, TRAJINERA_3]


# =============================================================================
# STATE
# =============================================================================

## The current level number (1-11). Set from GameState.current_level in _ready.
var level_num: int = 1

## The full level data dictionary returned by LevelData.get_level_data().
## Contains: width, height, theme, platforms, trajineras, coins, stars,
## powerups, enemies, baby_position, water_y, player_spawn, etc.
var level_data: Dictionary = {}

## Reference to the spawned player instance.
var player: CharacterBody2D = null

## Whether the level has been completed (prevents double-triggering).
var level_complete: bool = false

## Whether the game is currently paused.
var is_paused: bool = false

## Accumulated time for animations (seconds). Reset never -- just accumulates.
var anim_time: float = 0.0

## Debounce flag to prevent multiple X presses during restart
var restart_in_progress: bool = false


# =============================================================================
# CONTAINER NODE REFERENCES
# =============================================================================
## Organizational parent nodes for different entity types.
## Using containers keeps the scene tree clean and makes batch operations easy.

var sky_node: Node2D
var parallax_bg: ParallaxBackground
var platforms_node: Node2D
var trajineras_node: Node2D
var collectibles_node: Node2D
var enemies_node: Node2D
var water_node: Node2D
var hud_layer: CanvasLayer
var pause_layer: CanvasLayer


# =============================================================================
# HUD LABEL REFERENCES
# =============================================================================

var hud_score_label: Label
var hud_lives_label: Label
var hud_flowers_label: Label
var hud_super_jumps_label: Label
var hud_mace_attacks_label: Label
var hud_level_name_label: Label


# =============================================================================
# PRELOADED SCENES
# =============================================================================

var _player_scene: PackedScene = preload("res://scenes/game/player.tscn")


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	## Main entry point. Reads the current level from GameState, loads its data,
	## builds every visual and gameplay element, then starts music and shows the
	## world intro if this is the first level of a new world.

	level_num = GameState.current_level
	level_data = LevelData.get_level_data(level_num)

	_create_containers()
	_build_sky_gradient()
	_build_parallax()
	_create_platforms()
	_create_trajineras()
	_spawn_player()
	_setup_camera()
	_create_collectibles()
	_create_water()
	_create_hud()
	_create_pause_overlay()
	_spawn_enemies()
	_setup_combat()
	_setup_collectible_system()
	_setup_luchador_system()
	_setup_boss()
	_setup_water_system()
	_setup_escape_system()
	_start_music()

	# Show world intro on the first level of each world
	if GameState.is_first_level_of_world(level_num):
		_show_world_intro()

	# Connect global signals
	Events.player_died.connect(_on_player_died)
	Events.level_completed.connect(_on_level_completed_signal)
	Events.game_paused.connect(_toggle_pause)

	# Connect viewport signals for responsive layout
	ViewportManager.orientation_changed.connect(_on_orientation_changed)
	ViewportManager.viewport_resized.connect(_on_viewport_resized)


func _physics_process(delta: float) -> void:
	## The game loop. Runs every physics tick (default 60 Hz).
	## Handles trajinera movement, collectible animations, water death checks,
	## and HUD updates.
	if level_complete:
		return

	anim_time += delta

	_update_trajineras(delta)
	_update_collectibles(delta)
	_check_water_death()
	_update_water_effects(delta)
	_check_baby_pickup()
	_update_hud()

	# Luchador rolling attack -- check for enemy overlap each tick
	if luchador_system and luchador_system.is_active and luchador_system.is_rolling:
		_check_luchador_roll_hits()


func _input(event: InputEvent) -> void:
	## Handles pause toggle and quick restart.
	if event.is_action_pressed("pause_game"):
		_toggle_pause()

	# ANY key = INSTANT restart when dead (X, Z, Space, Enter, arrow keys...)
	# DEBOUNCE: Only allow one restart press to prevent queue-ups
	if player != null and player.is_dead and not restart_in_progress:
		if event is InputEventKey and event.pressed and not event.echo:
			restart_in_progress = true  # Prevent double-press
			# Reset lives if game over (xochi 1.0 style - always can retry!)
			if GameState.lives <= 0:
				GameState.lives = GameState.get_settings()["lives"]
			get_tree().reload_current_scene()  # INSTANT scene reload!


func _exit_tree() -> void:
	## Clean up signal connections when the scene is freed.
	if Events.player_died.is_connected(_on_player_died):
		Events.player_died.disconnect(_on_player_died)
	if Events.level_completed.is_connected(_on_level_completed_signal):
		Events.level_completed.disconnect(_on_level_completed_signal)
	if Events.boss_defeated.is_connected(_on_boss_defeated):
		Events.boss_defeated.disconnect(_on_boss_defeated)


# =============================================================================
# CONTAINER CREATION
# =============================================================================

func _create_containers() -> void:
	## Creates organizational parent nodes for each entity type.
	## This keeps the scene tree clean and allows batch operations like
	## "hide all collectibles" or "freeze all enemies."

	sky_node = Node2D.new()
	sky_node.name = "Sky"
	sky_node.z_index = Z_SKY
	add_child(sky_node)

	# ParallaxBackground is a special Godot node that handles scroll offsets
	# automatically based on the current camera position.
	parallax_bg = ParallaxBackground.new()
	parallax_bg.name = "ParallaxBackground"
	add_child(parallax_bg)

	platforms_node = Node2D.new()
	platforms_node.name = "Platforms"
	platforms_node.z_index = Z_PLATFORMS
	add_child(platforms_node)

	trajineras_node = Node2D.new()
	trajineras_node.name = "Trajineras"
	trajineras_node.z_index = Z_TRAJINERAS
	add_child(trajineras_node)

	collectibles_node = Node2D.new()
	collectibles_node.name = "Collectibles"
	collectibles_node.z_index = Z_COLLECTIBLES
	add_child(collectibles_node)

	enemies_node = Node2D.new()
	enemies_node.name = "Enemies"
	enemies_node.z_index = Z_ENEMIES
	add_child(enemies_node)

	water_node = Node2D.new()
	water_node.name = "Water"
	water_node.z_index = Z_WATER
	add_child(water_node)


# =============================================================================
# SKY GRADIENT (per-world themed background)
# =============================================================================

func _build_sky_gradient() -> void:
	## Builds the sky background using the world's 6-color sky palette.
	## Each color becomes a horizontal band spanning the full level width.
	## The bands are drawn at z_index -110 so they sit behind everything.
	##
	## Port of the original buildSkyGradient logic. The +2 pixel overlap on
	## each stripe prevents subpixel gaps during camera scrolling.

	var world_num: int = GameState.get_world_for_level(level_num)
	var world_data: Dictionary = GameState.WORLDS[world_num]
	var sky_colors: Array = world_data["sky"]

	var level_width: float = level_data.get("width", 3000.0)
	var level_height: float = level_data.get("height", 600.0)
	var stripe_count: int = sky_colors.size()
	var stripe_h: float = level_height / stripe_count

	for i in stripe_count:
		var rect := ColorRect.new()
		rect.position = Vector2(0, i * stripe_h)
		# +2 overlap prevents subpixel seam artifacts during camera scroll
		rect.size = Vector2(level_width, stripe_h + 2.0)
		rect.color = sky_colors[i]
		rect.z_index = Z_SKY
		sky_node.add_child(rect)


# =============================================================================
# SIX-LAYER PARALLAX BACKGROUND
# =============================================================================
# Ported from buildParallaxLayers (original game.js lines 842-1040).
# Six atmospheric layers create depth:
#   Layer 1: Far mountains  -- barely moves, very transparent
#   Layer 2: Mid mountains  -- gentle scroll
#   Layer 3: Rolling hills  -- moderate scroll
#   Layer 4: Vegetation     -- trees/bushes, near-opaque
#   Layer 5: Mist bands     -- atmospheric fog overlay
#   Layer 6: Foreground grass -- almost 1:1 with camera, fully opaque

func _build_parallax() -> void:
	## Builds all six parallax layers using Godot's ParallaxBackground system.
	## Each layer uses procedurally generated polygon shapes colored from the
	## world theme palette. The scroll factors create the depth illusion.

	var world_num: int = GameState.get_world_for_level(level_num)
	var world_data: Dictionary = GameState.WORLDS[world_num]
	var level_width: float = level_data.get("width", 3000.0)
	var level_height: float = level_data.get("height", 600.0)

	for i in PARALLAX_LAYERS.size():
		var layer_config: Dictionary = PARALLAX_LAYERS[i]
		var layer := ParallaxLayer.new()
		layer.name = layer_config["name"]
		layer.motion_scale = Vector2(layer_config["scroll"], 1.0)
		layer.z_index = Z_PARALLAX_BASE + i

		var layer_visual := Node2D.new()
		layer_visual.modulate.a = layer_config["alpha"]

		match i:
			0:
				# Far mountains: large gentle peaks
				_draw_mountain_layer(layer_visual, level_width, level_height,
					world_data["mountain"], 0.6, 80.0, 300.0)
			1:
				# Mid mountains: medium peaks, slightly taller variation
				_draw_mountain_layer(layer_visual, level_width, level_height,
					world_data["mountain"].lightened(0.15), 0.5, 60.0, 250.0)
			2:
				# Rolling hills: smooth undulating terrain
				_draw_hill_layer(layer_visual, level_width, level_height,
					world_data["hill"], 120.0)
			3:
				# Vegetation: trees and bushes
				_draw_vegetation_layer(layer_visual, level_width, level_height,
					world_data["vegetation"])
			4:
				# Mist bands: horizontal fog strips
				_draw_mist_layer(layer_visual, level_width, level_height,
					world_data["fog"])
			5:
				# Foreground grass: ground-level greenery
				_draw_grass_layer(layer_visual, level_width, level_height,
					world_data["vegetation"])

		layer.add_child(layer_visual)
		parallax_bg.add_child(layer)


func _draw_mountain_layer(parent: Node2D, level_w: float, level_h: float,
		color: Color, height_ratio: float, min_peak: float, max_peak: float) -> void:
	## Draws a silhouette mountain range as a series of overlapping triangular
	## peaks. Uses ColorRect approximations since we cannot draw arbitrary
	## polygons with ColorRect. Each "mountain" is a tall narrow rect.

	var base_y: float = level_h * height_ratio
	var mountain_count: int = int(level_w / 150.0) + 2
	# Use a deterministic seed based on height_ratio so layers look different
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(color.to_html()) + int(height_ratio * 1000.0)

	for j in mountain_count:
		var peak_height: float = rng.randf_range(min_peak, max_peak)
		var peak_width: float = rng.randf_range(100.0, 250.0)
		var x_pos: float = j * 150.0 + rng.randf_range(-40.0, 40.0)

		var mountain := ColorRect.new()
		mountain.size = Vector2(peak_width, peak_height)
		mountain.position = Vector2(x_pos - peak_width * 0.5, base_y - peak_height)
		mountain.color = color.darkened(rng.randf_range(0.0, 0.15))
		parent.add_child(mountain)

	# Base fill below mountains to the bottom of the level
	var base_fill := ColorRect.new()
	base_fill.size = Vector2(level_w + 200.0, level_h - base_y + 50.0)
	base_fill.position = Vector2(-100.0, base_y)
	base_fill.color = color.darkened(0.1)
	parent.add_child(base_fill)


func _draw_hill_layer(parent: Node2D, level_w: float, level_h: float,
		color: Color, hill_height: float) -> void:
	## Draws rolling hills as overlapping rounded rectangles at varying heights.
	## Creates a smooth undulating horizon line.

	var base_y: float = level_h * 0.55
	var hill_count: int = int(level_w / 120.0) + 2
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(color.to_html()) + 42

	for j in hill_count:
		var h: float = rng.randf_range(hill_height * 0.6, hill_height)
		var w: float = rng.randf_range(180.0, 320.0)
		var x_pos: float = j * 120.0 + rng.randf_range(-30.0, 30.0)
		var y_offset: float = rng.randf_range(-20.0, 20.0)

		var hill := ColorRect.new()
		hill.size = Vector2(w, h)
		hill.position = Vector2(x_pos - w * 0.5, base_y - h + y_offset)
		hill.color = color.darkened(rng.randf_range(0.0, 0.1))
		parent.add_child(hill)

	# Base fill
	var base_fill := ColorRect.new()
	base_fill.size = Vector2(level_w + 200.0, level_h - base_y + 50.0)
	base_fill.position = Vector2(-100.0, base_y)
	base_fill.color = color.darkened(0.05)
	parent.add_child(base_fill)


func _draw_vegetation_layer(parent: Node2D, level_w: float, level_h: float,
		vegetation_colors: Array) -> void:
	## Draws a vegetation layer with tree-like rectangular shapes at varying
	## heights. Uses the world's vegetation color palette for variety.

	var base_y: float = level_h * 0.65
	var tree_count: int = int(level_w / 80.0) + 2
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(vegetation_colors[0].to_html()) + 99

	for j in tree_count:
		var trunk_h: float = rng.randf_range(40.0, 100.0)
		var canopy_w: float = rng.randf_range(30.0, 60.0)
		var canopy_h: float = rng.randf_range(25.0, 50.0)
		var x_pos: float = j * 80.0 + rng.randf_range(-20.0, 20.0)
		var color_idx: int = rng.randi_range(0, vegetation_colors.size() - 1)
		var tree_color: Color = vegetation_colors[color_idx]

		# Trunk
		var trunk := ColorRect.new()
		trunk.size = Vector2(8.0, trunk_h)
		trunk.position = Vector2(x_pos - 4.0, base_y - trunk_h)
		trunk.color = tree_color.darkened(0.3)
		parent.add_child(trunk)

		# Canopy
		var canopy := ColorRect.new()
		canopy.size = Vector2(canopy_w, canopy_h)
		canopy.position = Vector2(x_pos - canopy_w * 0.5, base_y - trunk_h - canopy_h * 0.5)
		canopy.color = tree_color
		parent.add_child(canopy)

	# Base fill
	var base_fill := ColorRect.new()
	base_fill.size = Vector2(level_w + 200.0, level_h - base_y + 50.0)
	base_fill.position = Vector2(-100.0, base_y)
	if vegetation_colors.size() > 0:
		base_fill.color = vegetation_colors[0].darkened(0.2)
	else:
		base_fill.color = Color("336633")
	parent.add_child(base_fill)


func _draw_mist_layer(parent: Node2D, level_w: float, level_h: float,
		fog_color: Color) -> void:
	## Draws horizontal mist/fog bands at various heights across the level.
	## These semi-transparent strips add atmospheric depth between the other
	## parallax layers.

	var band_count: int = 5
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(fog_color.to_html()) + 77

	for j in band_count:
		var band_y: float = rng.randf_range(level_h * 0.2, level_h * 0.8)
		var band_h: float = rng.randf_range(15.0, 40.0)

		var mist := ColorRect.new()
		mist.size = Vector2(level_w + 200.0, band_h)
		mist.position = Vector2(-100.0, band_y)
		mist.color = fog_color
		mist.modulate.a = rng.randf_range(0.15, 0.4)
		parent.add_child(mist)


func _draw_grass_layer(parent: Node2D, level_w: float, level_h: float,
		vegetation_colors: Array) -> void:
	## Draws foreground grass tufts near the bottom of the viewport.
	## These are small rectangles that give a sense of ground-level foliage
	## and move almost 1:1 with the camera for a strong foreground presence.

	var base_y: float = level_h * 0.85
	var tuft_count: int = int(level_w / 40.0) + 2
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("grass") + 55

	for j in tuft_count:
		var tuft_h: float = rng.randf_range(8.0, 25.0)
		var tuft_w: float = rng.randf_range(6.0, 14.0)
		var x_pos: float = j * 40.0 + rng.randf_range(-15.0, 15.0)
		var color_idx: int = rng.randi_range(0, vegetation_colors.size() - 1)

		var tuft := ColorRect.new()
		tuft.size = Vector2(tuft_w, tuft_h)
		tuft.position = Vector2(x_pos, base_y - tuft_h)
		tuft.color = vegetation_colors[color_idx].lightened(0.1)
		parent.add_child(tuft)

	# Ground fill
	var ground := ColorRect.new()
	ground.size = Vector2(level_w + 200.0, level_h - base_y + 50.0)
	ground.position = Vector2(-100.0, base_y)
	if vegetation_colors.size() > 0:
		ground.color = vegetation_colors[0].darkened(0.3)
	else:
		ground.color = Color("224422")
	parent.add_child(ground)


# =============================================================================
# PLATFORM CREATION
# =============================================================================

func _create_platforms() -> void:
	## Iterates over level_data.platforms and creates a StaticBody2D for each.
	## Platforms are the immovable terrain that the player walks and jumps on.

	var platform_array: Array = level_data.get("platforms", [])
	for plat_data in platform_array:
		_create_platform(plat_data)


func _create_platform(data: Dictionary) -> void:
	## Creates a single platform from level data with rich Dia de los Muertos /
	## Mesoamerican-themed procedural visuals. Three distinct visual styles:
	##   - Ground platforms (h > 30): ancient stone foundation with Aztec pattern
	##     band, marigold fringe, and scattered stone texture details.
	##   - Chinampa platforms (is_chinampa): decorated floating gardens with
	##     cempasuchil flowers, hanging vegetation, and papel picado banners.
	##   - Sky/high platforms (y < 150): crystal/gold temple steps with pyramid
	##     profile, accent stripes, and optional skull decorations.
	##
	## All styles share world-specific tinting (lerp 0.25) for visual cohesion.
	## Collision shape and StaticBody2D setup are unchanged from the original.

	var plat_x: float = data.get("x", 0.0)
	var plat_y: float = data.get("y", 0.0)
	var plat_w: float = data.get("w", 100.0)
	var plat_h: float = data.get("h", 20.0)

	var body := StaticBody2D.new()
	# Position at the center of the platform rect for correct collision alignment
	body.position = Vector2(plat_x + plat_w * 0.5, plat_y + plat_h * 0.5)
	body.collision_layer = COLLISION_LAYER_WORLD

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(plat_w, plat_h)
	shape.shape = rect
	body.add_child(shape)

	# --- World tint setup (shared by all platform types) ---
	var world_num: int = GameState.get_world_for_level(level_num)
	var world_data: Dictionary = GameState.WORLDS[world_num]
	var tint: Color = world_data.get("foreground", Color.WHITE)

	# Half-extents for positioning (body is centered, visuals offset from center)
	var hw: float = plat_w * 0.5
	var hh: float = plat_h * 0.5

	# --- Classify platform type ---
	var is_chinampa: bool = data.get("is_chinampa", false)
	var is_ground: bool = plat_h > 30.0
	var is_sky: bool = plat_y < 150.0

	if is_chinampa:
		_decorate_chinampa_platform(body, plat_w, plat_h, hw, hh, tint)
	elif is_ground:
		_decorate_ground_platform(body, plat_w, plat_h, hw, hh, tint)
	elif is_sky:
		_decorate_sky_platform(body, plat_w, plat_h, hw, hh, tint)
	else:
		# Standard floating platform -- gets a lighter version of chinampa style
		_decorate_chinampa_platform(body, plat_w, plat_h, hw, hh, tint)

	platforms_node.add_child(body)


func _apply_platform_tint(color: Color, tint: Color) -> Color:
	## Applies world-specific tinting to a platform color at 0.25 strength.
	return color.lerp(tint, 0.25)


func _decorate_ground_platform(body: StaticBody2D, pw: float, ph: float,
		hw: float, hh: float, tint: Color) -> void:
	## Ancient stone foundation style for thick ground platforms.
	## Layered earth tones, Aztec pattern band, marigold fringe, stone texture.

	# -- Layer 1: Three horizontal stripes (dark bottom, medium middle, light top) --
	var stripe_h: float = ph / 3.0

	# Bottom stripe: dark earth
	var bottom := ColorRect.new()
	bottom.size = Vector2(pw, stripe_h + 1.0)  # +1 overlap prevents seam
	bottom.position = Vector2(-hw, hh - stripe_h)
	bottom.color = _apply_platform_tint(Color("5C3A1E"), tint)
	body.add_child(bottom)

	# Middle stripe: medium brown
	var middle := ColorRect.new()
	middle.size = Vector2(pw, stripe_h + 1.0)
	middle.position = Vector2(-hw, -hh + stripe_h - 1.0)
	middle.color = _apply_platform_tint(Color("7A4F2B"), tint)
	body.add_child(middle)

	# Top stripe: lighter sandstone
	var top_layer := ColorRect.new()
	top_layer.size = Vector2(pw, stripe_h + 1.0)
	top_layer.position = Vector2(-hw, -hh)
	top_layer.color = _apply_platform_tint(Color("A0704A"), tint)
	body.add_child(top_layer)

	# -- Layer 2: Aztec pattern band along the top edge --
	# Small colored squares alternating gold / teal / orange
	var pattern_colors: Array[Color] = [
		_apply_platform_tint(Color("DAA520"), tint),  # Gold
		_apply_platform_tint(Color("2A9D8F"), tint),  # Teal
		_apply_platform_tint(Color("E76F51"), tint),  # Orange
	]
	var block_size: float = 6.0
	var band_y: float = -hh  # Sits at the very top of the platform
	var num_blocks: int = int(pw / block_size)
	for i in num_blocks:
		var block := ColorRect.new()
		block.size = Vector2(block_size - 1.0, 4.0)  # -1 gap between blocks
		block.position = Vector2(-hw + i * block_size, band_y)
		block.color = pattern_colors[i % pattern_colors.size()]
		body.add_child(block)

	# -- Layer 3: Marigold fringe along the very top --
	# Small yellow-orange rectangles sticking up 2-4px with random gaps
	var fringe_x: float = 0.0
	while fringe_x < pw:
		if randf() > 0.35:  # ~65% chance of a fringe piece (random gaps)
			var fringe := ColorRect.new()
			var fringe_h: float = 2.0 + randf() * 2.0  # 2-4px tall
			var fringe_w: float = 3.0 + randf() * 3.0  # 3-6px wide
			fringe.size = Vector2(fringe_w, fringe_h)
			fringe.position = Vector2(-hw + fringe_x, -hh - fringe_h)
			# Warm marigold tones: lerp between orange and gold
			var marigold: Color = Color("FF8C00").lerp(Color("FFD700"), randf())
			fringe.color = _apply_platform_tint(marigold, tint)
			body.add_child(fringe)
		fringe_x += 5.0 + randf() * 4.0  # 5-9px spacing

	# -- Layer 4: Stone texture (3-4 small darker rectangles on the face) --
	var stone_count: int = 3 + int(randf() * 2.0)  # 3-4 stones
	for i in stone_count:
		var stone := ColorRect.new()
		var sw: float = 6.0 + randf() * 10.0
		var sh: float = 3.0 + randf() * 5.0
		stone.size = Vector2(sw, sh)
		# Random position within the platform body, avoiding the top band
		var sx: float = -hw + randf() * (pw - sw)
		var sy: float = -hh + 6.0 + randf() * (ph - sh - 8.0)
		stone.position = Vector2(sx, sy)
		stone.color = _apply_platform_tint(Color("4A3018"), tint)
		stone.modulate.a = 0.4 + randf() * 0.2  # Subtle, not overwhelming
		body.add_child(stone)


func _decorate_chinampa_platform(body: StaticBody2D, pw: float, ph: float,
		hw: float, hh: float, tint: Color) -> void:
	## Decorated floating garden style for chinampa and standard platforms.
	## Green-brown earth base, vegetation strip, cempasuchil flowers,
	## hanging vines, and optional papel picado banner.

	# -- Base: green-brown earth --
	var base := ColorRect.new()
	base.size = Vector2(pw, ph)
	base.position = Vector2(-hw, -hh)
	base.color = _apply_platform_tint(Color("5E6B3A"), tint)
	body.add_child(base)

	# -- Top layer: rich green vegetation strip (top 40% of platform) --
	var veg_h: float = max(ph * 0.4, 4.0)
	var vegetation := ColorRect.new()
	vegetation.size = Vector2(pw, veg_h)
	vegetation.position = Vector2(-hw, -hh)
	vegetation.color = _apply_platform_tint(Color("3B7A1E"), tint)
	body.add_child(vegetation)

	# -- Cempasuchil flowers: 3-5 small orange/gold squares on top --
	var flower_count: int = 3 + int(randf() * 3.0)  # 3-5 flowers
	for i in flower_count:
		var flower := ColorRect.new()
		flower.size = Vector2(4.0, 4.0)
		var fx: float = -hw + 4.0 + randf() * (pw - 12.0)
		var fy: float = -hh - 1.0 + randf() * 2.0  # Sit on top, slight variation
		flower.position = Vector2(fx, fy)
		# Alternate between warm orange and bright gold
		if randf() > 0.5:
			flower.color = _apply_platform_tint(Color("FF8C00"), tint)
		else:
			flower.color = _apply_platform_tint(Color("FFD700"), tint)
		body.add_child(flower)

	# -- Side hanging vegetation: 2-3 small green rectangles dangling below --
	var vine_count: int = 2 + int(randf() * 2.0)  # 2-3 vines
	for i in vine_count:
		var vine := ColorRect.new()
		var vine_w: float = 2.0 + randf() * 2.0  # 2-4px wide
		var vine_h: float = 4.0 + randf() * 4.0  # 4-8px tall
		vine.size = Vector2(vine_w, vine_h)
		# Distribute along the bottom edge with some randomness
		var vx: float = -hw + 6.0 + randf() * (pw - 12.0)
		vine.position = Vector2(vx, hh)  # Hangs from bottom
		vine.color = _apply_platform_tint(Color("2D6B14"), tint)
		vine.modulate.a = 0.75 + randf() * 0.25
		body.add_child(vine)

	# -- Papel picado banner: decorative strip underneath (wide platforms only) --
	if pw > 100.0:
		var banner_y: float = hh + 2.0
		var segment_w: float = 8.0
		var num_segments: int = int((pw - 16.0) / segment_w)
		var banner_colors: Array[Color] = [
			Color("E63946"),  # Red
			Color("FFD700"),  # Gold
			Color("2A9D8F"),  # Teal
			Color("FF8C00"),  # Orange
			Color("9B5DE5"),  # Purple
		]
		for i in num_segments:
			var seg := ColorRect.new()
			seg.size = Vector2(segment_w - 2.0, 2.0)
			seg.position = Vector2(-hw + 8.0 + i * segment_w, banner_y)
			seg.color = _apply_platform_tint(banner_colors[i % banner_colors.size()], tint)
			seg.modulate.a = 0.8
			body.add_child(seg)

	# -- Top edge highlight for depth --
	var edge := ColorRect.new()
	edge.size = Vector2(pw, 1.0)
	edge.position = Vector2(-hw, -hh)
	edge.color = _apply_platform_tint(Color("6BBF3B"), tint)
	body.add_child(edge)


func _decorate_sky_platform(body: StaticBody2D, pw: float, ph: float,
		hw: float, hh: float, tint: Color) -> void:
	## Crystal/gold ancient temple style for high-altitude platforms.
	## Stepped pyramid profile, gold/teal accent stripe, optional skull decoration.

	# -- Main body: warm sandstone --
	var main_body := ColorRect.new()
	main_body.size = Vector2(pw, ph)
	main_body.position = Vector2(-hw, -hh)
	main_body.color = _apply_platform_tint(Color("C4A35A"), tint)
	body.add_child(main_body)

	# -- Stepped pyramid inset: smaller layer on top for depth --
	var inset_margin: float = min(6.0, pw * 0.08)
	var inset_h: float = max(ph * 0.35, 3.0)
	var inset := ColorRect.new()
	inset.size = Vector2(pw - inset_margin * 2.0, inset_h)
	inset.position = Vector2(-hw + inset_margin, -hh)
	inset.color = _apply_platform_tint(Color("D4B86A"), tint)
	body.add_child(inset)

	# -- Gold/teal accent stripe at top --
	var stripe := ColorRect.new()
	stripe.size = Vector2(pw, 2.0)
	stripe.position = Vector2(-hw, -hh)
	stripe.color = _apply_platform_tint(Color("DAA520"), tint)
	body.add_child(stripe)

	# Second accent stripe (teal) just below
	var stripe2 := ColorRect.new()
	stripe2.size = Vector2(pw, 1.0)
	stripe2.position = Vector2(-hw, -hh + 2.0)
	stripe2.color = _apply_platform_tint(Color("2A9D8F"), tint)
	body.add_child(stripe2)

	# -- Bottom edge: darker shadow for grounding --
	var shadow := ColorRect.new()
	shadow.size = Vector2(pw, 2.0)
	shadow.position = Vector2(-hw, hh - 2.0)
	shadow.color = _apply_platform_tint(Color("8B7340"), tint)
	body.add_child(shadow)

	# -- Side step details (left and right edges) --
	var step_w: float = min(4.0, pw * 0.05)
	var left_step := ColorRect.new()
	left_step.size = Vector2(step_w, ph)
	left_step.position = Vector2(-hw, -hh)
	left_step.color = _apply_platform_tint(Color("B89548"), tint)
	body.add_child(left_step)

	var right_step := ColorRect.new()
	right_step.size = Vector2(step_w, ph)
	right_step.position = Vector2(hw - step_w, -hh)
	right_step.color = _apply_platform_tint(Color("B89548"), tint)
	body.add_child(right_step)

	# -- Skull decoration: centered on wide platforms (> 120px) --
	if pw > 120.0:
		# Skull face: 6x6 white square
		var skull := ColorRect.new()
		skull.size = Vector2(6.0, 6.0)
		skull.position = Vector2(-3.0, -hh + 4.0)
		skull.color = _apply_platform_tint(Color("F0E6D2"), tint)
		body.add_child(skull)

		# Left eye: 2x2 black dot
		var eye_l := ColorRect.new()
		eye_l.size = Vector2(2.0, 2.0)
		eye_l.position = Vector2(-2.0, -hh + 5.0)
		eye_l.color = Color("1A1A1A")
		body.add_child(eye_l)

		# Right eye: 2x2 black dot
		var eye_r := ColorRect.new()
		eye_r.size = Vector2(2.0, 2.0)
		eye_r.position = Vector2(1.0, -hh + 5.0)
		eye_r.color = Color("1A1A1A")
		body.add_child(eye_r)


# =============================================================================
# TRAJINERA SYSTEM (MOVING PLATFORMS) -- THE SOUL OF XOCHI
# =============================================================================
# Trajineras are the iconic colorful boats of Xochimilco. In gameplay they are
# moving platforms the player can ride. Each has a painted hull, decorative
# canopy arch, and a nameplate. They bob gently on the water and reverse
# direction at level boundaries.

func _create_trajineras() -> void:
	## Iterates over level_data.trajineras and creates an AnimatableBody2D
	## for each boat. AnimatableBody2D is used instead of CharacterBody2D so
	## the player can ride them without being pushed off.

	var traj_array: Array = level_data.get("trajineras", [])
	for traj_data in traj_array:
		_create_trajinera(traj_data)


func _create_trajinera(data: Dictionary) -> void:
	## Creates a single trajinera (moving boat platform) from level data.
	##
	## Structure:
	##   AnimatableBody2D (physics body the player rides)
	##     CollisionShape2D (flat top surface for riding)
	##     Sprite2D (beautiful pixel art trajinera from nano banana)
	##     Nameplate (Label -- boat's name in a festive font, optional)
	##
	## Movement metadata is stored on the body via set_meta() so the
	## _update_trajineras() loop can read it without needing a custom class.

	var traj_x: float = data.get("x", 0.0)
	var traj_y: float = data.get("y", 0.0)
	var traj_w: float = data.get("w", 120.0)
	var traj_h: float = data.get("h", 20.0)
	var traj_speed: float = data.get("speed", 60.0)
	var traj_dir: float = data.get("dir", 1.0)
	var traj_color: Color = data.get("color", Color("ff6699"))
	var traj_name: String = data.get("name", "Lupita")

	var body := AnimatableBody2D.new()
	body.position = Vector2(traj_x, traj_y)
	body.collision_layer = COLLISION_LAYER_PLATFORMS
	body.collision_mask = 0  # Trajineras don't collide with anything themselves
	body.sync_to_physics = false  # We control movement manually in _physics_process

	# Collision shape: flat top surface for the player to stand on
	# Positioned at the top of the boat hull for proper standing
	# Make it 2x bigger to match the scaled sprite
	# ONE-WAY COLLISION: Xochi can jump up through from below and land on top
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(traj_w * 2.0, traj_h * 2.0)  # 2x bigger to match sprite scale
	shape.shape = rect
	shape.position = Vector2(0, 8)  # Offset slightly down so player stands on visible hull
	shape.one_way_collision = true  # Allow jumping through from below!
	body.add_child(shape)

	# Use specific texture index if provided, otherwise random
	var texture_idx: int = data.get("texture_idx", randi() % TRAJINERA_TEXTURES.size())
	var sprite_texture: Texture2D = TRAJINERA_TEXTURES[texture_idx]

	if sprite_texture != null:
		# Use the beautiful DKC-style pre-rendered 3D side-view sprite
		var sprite := Sprite2D.new()
		sprite.texture = sprite_texture

		# Calculate scale to fit the desired width
		# Make trajineras bigger (2x) so Xochi can jump comfortably onto them
		var sprite_width: float = sprite_texture.get_width()
		var sprite_height: float = sprite_texture.get_height()
		var base_scale: float = traj_w / sprite_width
		var scale_factor: float = base_scale * 2.0  # 2x bigger for comfortable platforming

		sprite.scale = Vector2(scale_factor, scale_factor)

		# Center the sprite horizontally, align hull with collision shape
		sprite.centered = true
		sprite.position = Vector2(0, -sprite_height * scale_factor * 0.35)  # Adjust Y so hull aligns with collision

		body.add_child(sprite)
	else:
		# Fallback to ColorRect trajinera (better version until we get side-view renders)
		# This creates a simple but recognizable boat shape

		# Hull bottom (main boat body)
		var hull := ColorRect.new()
		hull.size = Vector2(traj_w, traj_h)
		hull.position = -Vector2(traj_w, traj_h) * 0.5
		hull.color = traj_color
		body.add_child(hull)

		# Hull trim (darker waterline)
		var trim := ColorRect.new()
		trim.size = Vector2(traj_w, 3.0)
		trim.position = Vector2(-traj_w * 0.5, traj_h * 0.5 - 3.0)
		trim.color = traj_color.darkened(0.4)
		body.add_child(trim)

		# Canopy arch (decorative top)
		var canopy := ColorRect.new()
		canopy.size = Vector2(traj_w * 0.8, 8.0)
		canopy.position = Vector2(-traj_w * 0.4, -traj_h * 0.5 - 24.0)
		canopy.color = traj_color.lightened(0.3)
		body.add_child(canopy)

		# Left support pillar
		var pillar_left := ColorRect.new()
		pillar_left.size = Vector2(4.0, 20.0)
		pillar_left.position = Vector2(-traj_w * 0.4, -traj_h * 0.5 - 20.0)
		pillar_left.color = traj_color.darkened(0.2)
		body.add_child(pillar_left)

		# Right support pillar
		var pillar_right := ColorRect.new()
		pillar_right.size = Vector2(4.0, 20.0)
		pillar_right.position = Vector2(traj_w * 0.4 - 4.0, -traj_h * 0.5 - 20.0)
		pillar_right.color = traj_color.darkened(0.2)
		body.add_child(pillar_right)

		# Nameplate banner
		var banner := ColorRect.new()
		banner.size = Vector2(traj_w * 0.6, 12.0)
		banner.position = Vector2(-traj_w * 0.3, -traj_h * 0.5 - 32.0)
		banner.color = Color("1a1a2e")  # Dark blue banner
		body.add_child(banner)

		# Nameplate text
		var nameplate := Label.new()
		nameplate.text = traj_name
		nameplate.add_theme_font_size_override("font_size", 10)
		nameplate.add_theme_color_override("font_color", Color.WHITE)
		nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nameplate.position = Vector2(-traj_w * 0.3, -traj_h * 0.5 - 34.0)
		nameplate.size = Vector2(traj_w * 0.6, 14.0)
		body.add_child(nameplate)

	# Optional nameplate overlay (can be disabled if sprite has built-in text)
	# Comment this out if you want to use only the sprite's built-in nameplate
	if false:  # Set to true to show custom names over the sprite
		var nameplate := Label.new()
		nameplate.text = traj_name
		nameplate.add_theme_font_size_override("font_size", 9)
		nameplate.add_theme_color_override("font_color", Color.WHITE)
		nameplate.add_theme_color_override("font_outline_color", Color.BLACK)
		nameplate.add_theme_constant_override("outline_size", 2)
		nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nameplate.position = Vector2(-traj_w * 0.3, -25.0)
		nameplate.size = Vector2(traj_w * 0.6, 14.0)
		body.add_child(nameplate)

	# Store movement metadata on the body for the update loop
	body.set_meta("speed", traj_speed)
	body.set_meta("dir", traj_dir)
	body.set_meta("start_x", data.get("start_x", traj_x))
	body.set_meta("level_width", level_data.get("width", 3000.0))
	body.set_meta("base_y", traj_y)
	body.set_meta("bob_offset", randf() * TAU)  # Random phase so boats don't bob in sync

	trajineras_node.add_child(body)


func _update_trajineras(delta: float) -> void:
	## Updates every trajinera's position each physics tick.
	## Movement: horizontal patrol with direction reversal at level bounds.
	## Bobbing: gentle vertical sine wave for water feel.
	##
	## Uses AnimatableBody2D so the player is carried along automatically
	## when standing on the boat.

	for traj in trajineras_node.get_children():
		var speed: float = traj.get_meta("speed")
		var dir: float = traj.get_meta("dir")
		var level_w: float = traj.get_meta("level_width")
		var base_y: float = traj.get_meta("base_y")
		var bob_offset: float = traj.get_meta("bob_offset")

		# Horizontal movement
		traj.position.x += speed * dir * delta

		# Reverse at level bounds with margin
		if traj.position.x < 50.0:
			traj.position.x = 50.0
			dir = 1.0
			traj.set_meta("dir", dir)
		elif traj.position.x > level_w - 50.0:
			traj.position.x = level_w - 50.0
			dir = -1.0
			traj.set_meta("dir", dir)

		# Gentle vertical bobbing -- the water feel
		var bob: float = sin(anim_time * TRAJINERA_BOB_SPEED + bob_offset) * TRAJINERA_BOB_AMPLITUDE
		traj.position.y = base_y + bob


# =============================================================================
# PLAYER SPAWNING
# =============================================================================

func _spawn_player() -> void:
	## Instantiates the player scene and places it at the level's spawn point.
	## The player scene (player.tscn) already includes the CharacterBody2D,
	## Sprite2D, CollisionShape2D, and Camera2D.

	player = _player_scene.instantiate()
	var spawn: Vector2 = Vector2(100.0, 400.0)

	# Level data can provide spawn as a Vector2 or as a dict with x/y keys
	var spawn_data = level_data.get("player_spawn", null)
	if spawn_data is Vector2:
		spawn = spawn_data
	elif spawn_data is Dictionary:
		spawn = Vector2(spawn_data.get("x", 100.0), spawn_data.get("y", 400.0))

	player.position = spawn
	player.z_index = Z_PLAYER
	add_child(player)

	# Set up touch controls if on touch device
	_setup_touch_controls()


# =============================================================================
# TOUCH CONTROLS
# =============================================================================

func _setup_touch_controls() -> void:
	## Set up touch input manager if on a touch device.
	## Only creates the manager if the device has touch capability.
	if not DisplayServer.is_touchscreen_available():
		return

	if player == null:
		return

	# Load TouchInputManager script dynamically to avoid load order issues
	var TouchMgrScript = load("res://scripts/managers/touch_input_manager.gd")
	var touch_manager = TouchMgrScript.new()
	touch_manager.name = "TouchInputManager"
	add_child(touch_manager)
	touch_manager.setup(player)

	# Assign to player so it can read touch input
	player.touch_input = touch_manager

	print("[GameScene] Touch controls initialized")


# =============================================================================
# CAMERA SYSTEM
# =============================================================================
# Ported from original game.js lines 3997-4025.
# The camera is a child of the Player node (already in player.tscn).
# We configure its limits to match the level bounds and set mobile-friendly zoom.

func _setup_camera() -> void:
	## Configures the player's Camera2D for the current level.
	## Differentiates camera behavior by level type: upscroller, escape,
	## boss arena, or standard side-scroller.

	if player == null:
		return

	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera == null:
		return

	var lw: float = level_data.get("width", 3000.0)
	var lh: float = level_data.get("height", 600.0)

	# Set camera limits
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(lw)
	camera.limit_bottom = int(lh)

	# Position smoothing for buttery camera follow
	camera.position_smoothing_enabled = true

	# Mobile-responsive zoom from ViewportManager
	var zoom_val: float = ViewportManager.get_camera_zoom()
	camera.zoom = Vector2(zoom_val, zoom_val)

	var look_ahead: float = ViewportManager.get_camera_lookahead(100.0)

	var is_upscroller: bool = level_data.get("is_upscroller", false)
	var is_escape: bool = level_data.get("is_escape", false)
	var is_boss: bool = level_data.get("is_boss_level", false)

	if is_upscroller:
		# Upscroller: tighter vertical follow, offset to show above player
		camera.position_smoothing_speed = 10.0
		camera.offset = Vector2(-look_ahead * 0.5, -100.0)
	elif is_escape:
		# Escape: show more ahead (player running right)
		camera.position_smoothing_speed = 8.0
		camera.offset = Vector2(-look_ahead, 0.0)
	elif is_boss:
		# Boss: arena feel, reduced look-ahead
		camera.position_smoothing_speed = 6.0
		camera.offset = Vector2(-look_ahead * 0.7, 0.0)
	else:
		# Standard side-scroller: player left of center
		camera.position_smoothing_speed = 8.0
		camera.offset = Vector2(-look_ahead, 0.0)


# =============================================================================
# COLLECTIBLES
# =============================================================================
# Visual markers for all collectible types. Full pickup logic with Area2D
# collision detection comes in Phase 4. For now, these are visual indicators
# that bob, pulse, and sparkle to make the level feel alive.

func _create_collectibles() -> void:
	## Creates visual markers for all collectible types defined in the level data.
	## Types: flowers (coins), elotes (stars), powerups, baby axolotl.

	# Flowers (coins) -- the primary collectible
	var coin_array: Array = level_data.get("coins", [])
	for coin_data in coin_array:
		_create_flower(coin_data)

	# Elotes (stars) -- rare valuable collectibles
	var star_array: Array = level_data.get("stars", [])
	for i in star_array.size():
		_create_elote(star_array[i], i)

	# Powerups -- super jumps, mace attacks, luchador masks
	var powerup_array: Array = level_data.get("powerups", [])
	for pu_data in powerup_array:
		_create_powerup(pu_data)

	# Baby axolotl -- the level goal
	var baby_data = level_data.get("baby_position", null)
	if baby_data != null:
		_create_baby(baby_data)


func _create_flower(data) -> void:
	## Creates a cempasuchil flower (coin) -- bright orange marigold with petals.

	var pos := _parse_position(data)

	var marker := Node2D.new()
	marker.name = "Flower"
	marker.position = pos
	marker.set_meta("type", "flower")
	marker.set_meta("base_y", pos.y)
	marker.set_meta("bob_offset", randf() * TAU)

	# Soft glow halo
	var glow := ColorRect.new()
	glow.size = Vector2(28.0, 28.0)
	glow.position = Vector2(-14.0, -14.0)
	glow.color = Color(1.0, 0.6, 0.0, 0.25)
	marker.add_child(glow)

	# Petals (4 rotated squares forming a flower shape)
	for i in 4:
		var petal := ColorRect.new()
		petal.size = Vector2(10.0, 10.0)
		petal.position = Vector2(-5.0, -12.0)
		petal.pivot_offset = Vector2(5.0, 12.0)
		petal.rotation = i * (TAU / 4.0)
		petal.color = Color(1.0, 0.55 + randf() * 0.15, 0.0)
		marker.add_child(petal)

	# Center disc
	var center := ColorRect.new()
	center.size = Vector2(10.0, 10.0)
	center.position = Vector2(-5.0, -5.0)
	center.color = Color(1.0, 0.9, 0.3)
	marker.add_child(center)

	# Inner seed
	var seed := ColorRect.new()
	seed.size = Vector2(4.0, 4.0)
	seed.position = Vector2(-2.0, -2.0)
	seed.color = Color(0.8, 0.4, 0.0)
	marker.add_child(seed)

	collectibles_node.add_child(marker)


func _create_elote(data, index: int) -> void:
	## Creates an elote (star) visual marker -- golden corn cob with husk.

	var pos := _parse_position(data)

	var marker := Node2D.new()
	marker.name = "Elote_%d" % index
	marker.position = pos
	marker.set_meta("type", "elote")
	marker.set_meta("index", index)
	marker.set_meta("base_y", pos.y)
	marker.set_meta("bob_offset", randf() * TAU)

	# Golden glow halo
	var glow := ColorRect.new()
	glow.size = Vector2(36.0, 36.0)
	glow.position = Vector2(-18.0, -18.0)
	glow.color = Color(1.0, 0.85, 0.0, 0.2)
	marker.add_child(glow)

	# Outer diamond (gold)
	var diamond := ColorRect.new()
	diamond.size = Vector2(22.0, 22.0)
	diamond.position = Vector2(-11.0, -11.0)
	diamond.rotation = PI / 4.0
	diamond.color = Color("FFD700")
	marker.add_child(diamond)

	# Inner diamond (bright)
	var inner := ColorRect.new()
	inner.size = Vector2(12.0, 12.0)
	inner.position = Vector2(-6.0, -6.0)
	inner.rotation = PI / 4.0
	inner.color = Color("FFEE66")
	marker.add_child(inner)

	# Core sparkle (white)
	var core := ColorRect.new()
	core.size = Vector2(6.0, 6.0)
	core.position = Vector2(-3.0, -3.0)
	core.color = Color.WHITE
	marker.add_child(core)

	# Sparkle arms (cross shape)
	var h_arm := ColorRect.new()
	h_arm.size = Vector2(18.0, 2.0)
	h_arm.position = Vector2(-9.0, -1.0)
	h_arm.color = Color(1.0, 1.0, 0.7, 0.6)
	marker.add_child(h_arm)

	var v_arm := ColorRect.new()
	v_arm.size = Vector2(2.0, 18.0)
	v_arm.position = Vector2(-1.0, -9.0)
	v_arm.color = Color(1.0, 1.0, 0.7, 0.6)
	marker.add_child(v_arm)

	collectibles_node.add_child(marker)


func _create_powerup(data) -> void:
	## Creates a powerup visual marker -- glowing orb with pulsing ring.

	var pos := _parse_position(data)
	var pu_type: String = "super_jump"
	if data is Dictionary:
		pu_type = data.get("type", "super_jump")

	var marker := Node2D.new()
	marker.name = "Powerup_%s" % pu_type
	marker.position = pos
	marker.set_meta("type", "powerup")
	marker.set_meta("powerup_type", pu_type)
	marker.set_meta("base_y", pos.y)
	marker.set_meta("bob_offset", randf() * TAU)

	# Color based on powerup type
	var pu_color := Color("00FFFF")  # Cyan default (super jump)
	var glow_color := Color("00FFFF")
	match pu_type:
		"super_jump":
			pu_color = Color("00FFFF")
			glow_color = Color(0.0, 1.0, 1.0, 0.2)
		"mace_attack":
			pu_color = Color("FFD700")
			glow_color = Color(1.0, 0.85, 0.0, 0.2)
		"luchador":
			pu_color = Color("FF44FF")
			glow_color = Color(1.0, 0.3, 1.0, 0.2)

	# Outer glow halo
	var glow := ColorRect.new()
	glow.size = Vector2(36.0, 36.0)
	glow.position = Vector2(-18.0, -18.0)
	glow.color = glow_color
	marker.add_child(glow)

	# Outer ring (rotated diamond)
	var ring := ColorRect.new()
	ring.size = Vector2(24.0, 24.0)
	ring.position = Vector2(-12.0, -12.0)
	ring.rotation = PI / 4.0
	ring.color = pu_color
	marker.add_child(ring)

	# Inner fill (darker)
	var inner := ColorRect.new()
	inner.size = Vector2(16.0, 16.0)
	inner.position = Vector2(-8.0, -8.0)
	inner.rotation = PI / 4.0
	inner.color = Color(pu_color, 0.6)
	marker.add_child(inner)

	# Bright core
	var core := ColorRect.new()
	core.size = Vector2(8.0, 8.0)
	core.position = Vector2(-4.0, -4.0)
	core.color = Color.WHITE
	marker.add_child(core)

	# Power symbol -- vertical bar
	var bar := ColorRect.new()
	bar.size = Vector2(2.0, 10.0)
	bar.position = Vector2(-1.0, -5.0)
	bar.color = pu_color
	marker.add_child(bar)

	collectibles_node.add_child(marker)


func _create_baby(data) -> void:
	## Creates the baby axolotl visual marker -- the level goal.
	## Beautiful pixel art sprite with sparkle effect!
	## When the player reaches this position, the level is complete.

	var pos := _parse_position(data)

	var marker := Node2D.new()
	marker.name = "BabyAxolotl"
	marker.position = pos
	marker.set_meta("type", "baby")
	marker.set_meta("base_y", pos.y)
	marker.set_meta("bob_offset", 0.0)

	# Use the actual baby axolotl sprite!
	var sprite := Sprite2D.new()
	sprite.texture = preload("res://assets/sprites/collectibles/baby_axolotl.png")
	sprite.scale = Vector2(0.07, 0.07)  # Half size of Xochi (she's 0.15)
	marker.add_child(sprite)

	# Sparkle ring (outer glow that pulses)
	var sparkle := ColorRect.new()
	sparkle.name = "Sparkle"
	sparkle.size = Vector2(50.0, 50.0)
	sparkle.position = Vector2(-25.0, -25.0)
	sparkle.color = Color(1.0, 0.9, 0.95, 0.25)
	sparkle.z_index = -1  # Behind the sprite
	marker.add_child(sparkle)

	collectibles_node.add_child(marker)


func _update_collectibles(delta: float) -> void:
	## Animates all collectibles each frame.
	## Flowers bob. Elotes pulse. Powerups bob. Baby sparkles.
	## These subtle animations make the world feel alive even before
	## the full pickup system is implemented.

	for item in collectibles_node.get_children():
		var item_type: String = item.get_meta("type", "")
		var base_y: float = item.get_meta("base_y", item.position.y)
		var bob_offset: float = item.get_meta("bob_offset", 0.0)

		match item_type:
			"flower":
				# Gentle vertical bob
				item.position.y = base_y + sin(anim_time * COLLECTIBLE_BOB_SPEED + bob_offset) * COLLECTIBLE_BOB_AMPLITUDE

			"elote":
				# Bob + pulse scale
				item.position.y = base_y + sin(anim_time * COLLECTIBLE_BOB_SPEED + bob_offset) * COLLECTIBLE_BOB_AMPLITUDE
				var pulse: float = 1.0 + sin(anim_time * COLLECTIBLE_PULSE_SPEED + bob_offset) * 0.15
				item.scale = Vector2(pulse, pulse)

			"powerup":
				# Float and gently rotate
				item.position.y = base_y + sin(anim_time * COLLECTIBLE_BOB_SPEED * 0.8 + bob_offset) * COLLECTIBLE_BOB_AMPLITUDE * 1.5

			"baby":
				# Sparkle: pulsing outer glow
				var sparkle_node: ColorRect = item.get_node_or_null("Sparkle")
				if sparkle_node:
					var sparkle_alpha: float = 0.15 + sin(anim_time * BABY_SPARKLE_SPEED) * 0.15
					sparkle_node.color.a = sparkle_alpha
				# Gentle bob
				item.position.y = base_y + sin(anim_time * COLLECTIBLE_BOB_SPEED * 0.5) * COLLECTIBLE_BOB_AMPLITUDE * 0.5


func _parse_position(data) -> Vector2:
	## Utility to extract a Vector2 position from level data that may be
	## provided as a Vector2, a Dictionary with x/y keys, or an Array.
	if data is Vector2:
		return data
	elif data is Dictionary:
		return Vector2(data.get("x", 0.0), data.get("y", 0.0))
	elif data is Array and data.size() >= 2:
		return Vector2(data[0], data[1])
	return Vector2.ZERO


# =============================================================================
# WATER / DEATH ZONE
# =============================================================================

func _create_water() -> void:
	## Creates a rich multi-layer water effect with foam, highlights, caustics,
	## and reflection strips for a 3D-like depth feel. Also creates the death
	## zone Area2D that kills the player on contact.

	var water_y: float = level_data.get("water_y", 550.0)
	var level_width: float = level_data.get("width", 3000.0)
	var level_height: float = level_data.get("height", 600.0)
	var world_num: int = GameState.get_world_for_level(level_num)
	var world_data: Dictionary = GameState.WORLDS[world_num]
	var water_color: Color = world_data.get("water_color", Color("558899"))
	var water_depth: float = level_height - water_y + 50.0

	# --- Layer 1: Foam line (bright white-cyan at surface, 4px tall) ---
	var foam_rect := ColorRect.new()
	foam_rect.size = Vector2(level_width, 4.0)
	foam_rect.position = Vector2(0, water_y - 2.0)
	foam_rect.color = Color(1.0, 1.0, 1.0, 0.85)
	foam_rect.z_index = Z_WATER + 3
	water_node.add_child(foam_rect)

	# --- Layer 2: Surface highlight (8px, lightened water color) ---
	var surface_rect := ColorRect.new()
	surface_rect.size = Vector2(level_width, 8.0)
	surface_rect.position = Vector2(0, water_y + 2.0)
	surface_rect.color = water_color.lightened(0.4)
	surface_rect.modulate.a = 0.6
	surface_rect.z_index = Z_WATER + 2
	water_node.add_child(surface_rect)

	# --- Layer 3: Upper water (transition zone, 28px) ---
	var upper_water := ColorRect.new()
	upper_water.size = Vector2(level_width, 28.0)
	upper_water.position = Vector2(0, water_y + 12.0)
	upper_water.color = water_color.lightened(0.15)
	upper_water.modulate.a = 0.75
	upper_water.z_index = Z_WATER + 1
	water_node.add_child(upper_water)

	# --- Layer 4: Main water body (bulk, from surface+40 to bottom) ---
	var main_body := ColorRect.new()
	main_body.size = Vector2(level_width, water_depth - 40.0)
	main_body.position = Vector2(0, water_y + 40.0)
	main_body.color = water_color
	main_body.modulate.a = 0.85
	main_body.z_index = Z_WATER
	water_node.add_child(main_body)

	# --- Layer 5: Deep water darkener (bottom 40% of water depth) ---
	var deep_height: float = water_depth * 0.4
	var deep_rect := ColorRect.new()
	deep_rect.size = Vector2(level_width, deep_height)
	deep_rect.position = Vector2(0, water_y + water_depth - deep_height)
	deep_rect.color = water_color.darkened(0.3)
	deep_rect.modulate.a = 0.4
	deep_rect.z_index = Z_WATER - 1
	water_node.add_child(deep_rect)

	# --- Layer 6: Caustic light spots (8-12 bright rectangles) ---
	var caustics_array: Array = []
	var caustic_count: int = randi_range(8, 12)
	for i in caustic_count:
		var caustic := ColorRect.new()
		var cw: float = randf_range(6.0, 10.0)
		var ch: float = randf_range(3.0, 4.0)
		caustic.size = Vector2(cw, ch)
		var cx: float = randf_range(0.0, level_width - cw)
		var cy: float = randf_range(water_y, water_y + 60.0)
		caustic.position = Vector2(cx, cy)
		caustic.color = Color(1.0, 1.0, 1.0, randf_range(0.3, 0.5))
		caustic.z_index = Z_WATER + 2
		# Animation metadata
		caustic.set_meta("phase", randf_range(0.0, TAU))
		caustic.set_meta("speed", randf_range(1.5, 3.0))
		caustic.set_meta("amp", randf_range(2.0, 5.0))
		caustic.set_meta("base_y", cy)
		water_node.add_child(caustic)
		caustics_array.append(caustic)

	# --- Layer 7: Water reflection strips (4-6 long horizontal strips) ---
	var reflections_array: Array = []
	var refl_count: int = randi_range(4, 6)
	for i in refl_count:
		var refl := ColorRect.new()
		var rw: float = randf_range(200.0, 400.0)
		var rh: float = randf_range(2.0, 3.0)
		refl.size = Vector2(rw, rh)
		var rx: float = randf_range(0.0, level_width - rw)
		var ry: float = randf_range(water_y + 20.0, water_y + 80.0)
		refl.position = Vector2(rx, ry)
		refl.color = water_color.lightened(0.25)
		refl.modulate.a = randf_range(0.2, 0.35)
		refl.z_index = Z_WATER + 1
		# Animation metadata
		refl.set_meta("phase", randf_range(0.0, TAU))
		refl.set_meta("base_x", rx)
		water_node.add_child(refl)
		reflections_array.append(refl)

	# --- Death zone Area2D -- triggers player death when entered ---
	var death_area := Area2D.new()
	death_area.name = "WaterDeathZone"
	death_area.position = Vector2(level_width * 0.5, water_y + 30.0)
	death_area.collision_layer = 0
	death_area.collision_mask = COLLISION_LAYER_PLAYER

	var death_shape := CollisionShape2D.new()
	var death_rect := RectangleShape2D.new()
	death_rect.size = Vector2(level_width + 200.0, 60.0)
	death_shape.shape = death_rect
	death_area.add_child(death_shape)

	water_node.add_child(death_area)

	# Store water_y and animated element references for _update_water_effects()
	water_node.set_meta("water_y", water_y)
	water_node.set_meta("foam_line", foam_rect)
	water_node.set_meta("surface_highlight", surface_rect)
	water_node.set_meta("caustics", caustics_array)
	water_node.set_meta("reflections", reflections_array)


func _update_water_effects(delta: float) -> void:
	## Animates water surface foam, caustics, and reflections for 3D-like depth.
	if water_node == null:
		return

	var time_ms := Time.get_ticks_msec() * 0.001

	# Foam line wave
	var foam: ColorRect = water_node.get_meta("foam_line", null)
	if foam:
		foam.position.y = water_node.get_meta("water_y", 550.0) - 2.0 + sin(time_ms * WATER_WAVE_SPEED) * WATER_WAVE_AMPLITUDE

	# Surface highlight wave (slightly offset phase)
	var surface: ColorRect = water_node.get_meta("surface_highlight", null)
	if surface:
		surface.position.y = water_node.get_meta("water_y", 550.0) + 2.0 + sin(time_ms * WATER_WAVE_SPEED + 0.5) * (WATER_WAVE_AMPLITUDE * 0.6)

	# Caustic shimmer -- each spot fades in/out and drifts
	var caustics: Array = water_node.get_meta("caustics", [])
	for caustic in caustics:
		if not is_instance_valid(caustic):
			continue
		var phase: float = caustic.get_meta("phase", 0.0)
		var spd: float = caustic.get_meta("speed", 2.0)
		var amp: float = caustic.get_meta("amp", 3.0)
		var base_y: float = caustic.get_meta("base_y", 0.0)
		# Shimmer: fade alpha in and out
		caustic.modulate.a = 0.15 + abs(sin(time_ms * spd + phase)) * 0.4
		# Gentle drift
		caustic.position.y = base_y + sin(time_ms * spd * 0.7 + phase) * amp

	# Reflection strips -- slow horizontal drift
	var reflections: Array = water_node.get_meta("reflections", [])
	for refl in reflections:
		if not is_instance_valid(refl):
			continue
		var phase: float = refl.get_meta("phase", 0.0)
		var base_x: float = refl.get_meta("base_x", 0.0)
		refl.position.x = base_x + sin(time_ms * 0.3 + phase) * 15.0
		refl.modulate.a = 0.15 + abs(sin(time_ms * 0.8 + phase)) * 0.2


func _check_water_death() -> void:
	## Checks if the player has fallen into the water death zone.
	## INSTANT DEATH - touch the water and you're done!

	# Water/escape systems handle their own death checks
	if water_system or escape_system:
		return

	if player == null or player.is_dead:
		return

	var water_y: float = water_node.get_meta("water_y", 9999.0)
	# Trigger death as soon as player touches water surface
	if player.global_position.y > water_y:
		player.hit(999)  # INSTANT DEATH!


# =============================================================================
# BABY AXOLOTL PICKUP (LEVEL COMPLETION)
# =============================================================================

func _check_baby_pickup() -> void:
	## Checks if the player is close enough to the baby axolotl to pick it up.
	## When picked up, the level is marked complete and the completion sequence
	## begins. Uses distance check; Phase 4 will add proper Area2D collision.

	if player == null or player.is_dead or level_complete:
		return

	var baby_node: Node2D = collectibles_node.get_node_or_null("BabyAxolotl")
	if baby_node == null:
		return

	var distance: float = player.global_position.distance_to(baby_node.global_position)
	if distance < BABY_PICKUP_RADIUS:
		_complete_level()


func _complete_level() -> void:
	## Handles level completion: saves progress, shows a brief celebration,
	## then transitions to the next level or the victory screen.

	level_complete = true

	# Stop the escape flood if it was active -- the player made it!
	if escape_system and escape_system.has_method("stop"):
		escape_system.stop()

	# Record the baby rescue
	if level_num not in GameState.rescued_babies:
		GameState.rescued_babies.append(level_num)

	# Score bonus for completion
	GameState.score += 1000
	Events.score_changed.emit(GameState.score)

	# Emit signals
	level_completed.emit(level_num)
	Events.level_completed.emit(level_num)

	AudioManager.play_sfx("powerup")

	# Quick pause for celebration, then instant next level!
	await get_tree().create_timer(0.8).timeout  # Snappy, not sluggish

	if level_num >= GameState.total_levels:
		# Game won!
		Events.game_won.emit()
		GameState.save_game()
		SceneManager.change_scene("res://scenes/end/end_scene.tscn")
	else:
		# Advance to next level
		GameState.current_level = level_num + 1
		GameState.save_game()
		SceneManager.change_scene("res://scenes/game/game_scene.tscn")


# =============================================================================
# HUD (HEADS-UP DISPLAY)
# =============================================================================

func _create_hud() -> void:
	## Creates the in-game HUD on a CanvasLayer so it stays fixed on screen.
	## Displays: score, lives, flowers, super jumps, mace attacks, level name.

	hud_layer = CanvasLayer.new()
	hud_layer.name = "HUD"
	hud_layer.layer = 10
	add_child(hud_layer)

	# Background strip at the top for readability
	var hud_bg := ColorRect.new()
	hud_bg.size = Vector2(800.0, 32.0)
	hud_bg.position = Vector2.ZERO
	hud_bg.color = Color(0.0, 0.0, 0.0, 0.4)
	hud_layer.add_child(hud_bg)

	# Score (yellow, top-left)
	hud_score_label = _create_hud_label(
		"Score: 0", Vector2(8.0, 4.0), Color("FFD700"), 14)

	# Lives (white, after score)
	hud_lives_label = _create_hud_label(
		"Lives: 3", Vector2(150.0, 4.0), Color.WHITE, 14)

	# Flowers (orange)
	hud_flowers_label = _create_hud_label(
		"Flowers: 0", Vector2(270.0, 4.0), Color("FFA500"), 14)

	# Super jumps (cyan)
	hud_super_jumps_label = _create_hud_label(
		"SJ: 2", Vector2(410.0, 4.0), Color("00FFFF"), 14)

	# Mace attacks (yellow-green)
	hud_mace_attacks_label = _create_hud_label(
		"Mace: 1", Vector2(490.0, 4.0), Color("CCFF00"), 14)

	# Level name (center-right)
	var world_num: int = GameState.get_world_for_level(level_num)
	var world_data: Dictionary = GameState.WORLDS[world_num]
	var level_display_name: String = "%s - Level %d" % [world_data["name"], level_num]
	hud_level_name_label = _create_hud_label(
		level_display_name, Vector2(580.0, 4.0), Color("FFFFFF", 0.8), 13)


func _create_hud_label(text: String, pos: Vector2, color: Color, font_size: int) -> Label:
	## Helper to create a styled HUD label and add it to the HUD layer.
	## Stores the design position as metadata for responsive scaling.
	var label := Label.new()
	label.text = text
	label.position = pos
	label.set_meta("design_position", pos)  # Store for responsive repositioning
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	hud_layer.add_child(label)
	return label


func _update_hud() -> void:
	## Updates HUD labels with current game state values every frame.
	## This is cheap enough to run every tick and ensures the HUD is always
	## in sync with the actual state.

	if hud_score_label:
		hud_score_label.text = "Score: %d" % GameState.score
	if hud_lives_label:
		hud_lives_label.text = "Lives: %d" % GameState.lives
	if hud_flowers_label:
		hud_flowers_label.text = "Flowers: %d" % GameState.flowers
	if hud_super_jumps_label:
		hud_super_jumps_label.text = "SJ: %d" % GameState.super_jumps
	if hud_mace_attacks_label:
		hud_mace_attacks_label.text = "Mace: %d" % GameState.mace_attacks


# =============================================================================
# PAUSE SYSTEM
# =============================================================================

func _create_pause_overlay() -> void:
	## Creates the pause screen overlay. This is a CanvasLayer with a dark
	## semi-transparent background and a "PAUSED" label. Hidden by default.
	## The pause_mode is set so this layer still processes input while paused.

	pause_layer = CanvasLayer.new()
	pause_layer.name = "PauseOverlay"
	pause_layer.layer = 50
	pause_layer.visible = false
	add_child(pause_layer)

	# Dark overlay
	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_layer.add_child(overlay)

	# "PAUSED" text
	var pause_label := Label.new()
	pause_label.text = "PAUSED"
	pause_label.add_theme_font_size_override("font_size", 48)
	pause_label.add_theme_color_override("font_color", Color("FFD700"))
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_label.set_anchors_preset(Control.PRESET_CENTER)
	pause_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pause_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	pause_label.position = Vector2(-200, -40)
	pause_label.size = Vector2(400, 80)
	pause_layer.add_child(pause_label)

	# Resume instruction
	var resume_label := Label.new()
	resume_label.text = "Press ESC to resume"
	resume_label.add_theme_font_size_override("font_size", 18)
	resume_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	resume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resume_label.set_anchors_preset(Control.PRESET_CENTER)
	resume_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	resume_label.position = Vector2(-200, 30)
	resume_label.size = Vector2(400, 30)
	pause_layer.add_child(resume_label)


func _toggle_pause() -> void:
	## Toggles the game between paused and running states.
	## When paused, the scene tree is paused (all _physics_process and
	## _process calls stop) but this node's _input still receives events
	## because we set process_mode appropriately.

	is_paused = !is_paused
	get_tree().paused = is_paused
	pause_layer.visible = is_paused

	# This node must keep processing input while paused so we can unpause
	process_mode = Node.PROCESS_MODE_ALWAYS


# =============================================================================
# ENEMIES + COMBAT (Phase 3)
# =============================================================================

var combat_system: Node = null
var collectible_system: Node = null
var luchador_system: Node = null
var boss: Node = null
var water_system: Node = null
var escape_system: Node = null

func _spawn_enemies() -> void:
	## Spawn enemies from level data using the EnemySpawner utility.
	EnemySpawner.spawn_enemies(level_data, enemies_node)

func _setup_combat() -> void:
	## Create and wire up the combat system for stomp, melee, thunderbolt.
	combat_system = CombatSystem.new()
	combat_system.name = "CombatSystem"
	add_child(combat_system)
	if player:
		combat_system.setup(self, player, enemies_node)


func _setup_collectible_system() -> void:
	## Create the collectible pickup system (Phase 4).
	## Handles Area2D-based detection for flowers, elotes, and powerups.
	collectible_system = CollectibleSystem.new()
	collectible_system.name = "CollectibleSystem"
	add_child(collectible_system)
	if player:
		collectible_system.setup(self, player, collectibles_node)


func _setup_luchador_system() -> void:
	## Create the luchador mask power-up system.
	## Manages the rolling attack, afterimage trail, and enemy kill bonuses.
	luchador_system = LuchadorSystem.new()
	luchador_system.name = "LuchadorSystem"
	add_child(luchador_system)
	if player:
		luchador_system.setup(self, player)


func _setup_boss() -> void:
	## Spawn a Dark Xochi boss on boss levels (5 and 10) if the baby for
	## that level has not already been rescued. Connects defeat signal so
	## the baby axolotl spawns when the boss is killed.
	var is_boss_level: bool = (level_num == 5 or level_num == 10)
	var baby_id: String = "baby-%d" % level_num
	if not is_boss_level or baby_id in GameState.rescued_babies:
		return

	# Spawn position: 300 px right of the player spawn, 100 px up
	var ps: Dictionary = level_data.get("player_spawn", {"x": 100, "y": 400})
	var spawn_pos: Vector2 = Vector2(
		ps.get("x", 100) + 300,
		ps.get("y", 400) - 100
	)

	boss = DarkXochi.new()
	boss.name = "DarkXochi"
	add_child(boss)
	boss.setup(level_num, player, spawn_pos)

	# Connect defeat signal to spawn baby
	Events.boss_defeated.connect(_on_boss_defeated)

	# Start boss intro
	boss.play_intro(func(): pass)  # Boss starts AI after intro


func _setup_water_system() -> void:
	## Set up rising water on upscroller levels (3, 8).
	if not level_data.get("is_upscroller", false):
		return
	if player == null:
		return

	water_system = WaterSystem.new()
	water_system.name = "WaterSystem"
	add_child(water_system)
	water_system.setup(
		self,
		player,
		level_data.get("width", 600.0),
		level_data.get("height", 2500.0)
	)


func _setup_escape_system() -> void:
	## Set up chasing flood on escape levels (7, 9).
	if not level_data.get("is_escape", false):
		return
	if player == null:
		return

	escape_system = EscapeSystem.new()
	escape_system.name = "EscapeSystem"
	add_child(escape_system)
	escape_system.setup(
		player,
		level_data.get("width", 3500.0),
		level_data.get("escape_speed", 120.0),
		level_data.get("water_y", 560.0)
	)


# =============================================================================
# BOSS DEFEAT
# =============================================================================

func _on_boss_defeated() -> void:
	## Spawn the baby axolotl collectible after the boss is defeated,
	## allowing the player to complete the level.
	var baby_node = collectibles_node.get_node_or_null("BabyAxolotl")
	if baby_node == null:
		var baby_data = level_data.get("baby_position", null)
		if baby_data:
			_create_baby(baby_data)


# =============================================================================
# LUCHADOR ROLL HIT DETECTION
# =============================================================================

func _check_luchador_roll_hits() -> void:
	## Check if the rolling luchador player overlaps any enemy.
	## Uses a simple 50 px distance check. When an overlap is detected,
	## the luchador system handles the kill, score, camera shake, and FX.
	if not luchador_system or not player:
		return
	for enemy in enemies_node.get_children():
		if not enemy.visible:
			continue
		if not enemy.has_method("hit_by_attack"):
			continue
		if not enemy.get("alive"):
			continue
		var dist: float = player.global_position.distance_to(enemy.global_position)
		if dist < 50.0:
			luchador_system.roll_hit_enemy(enemy)


# =============================================================================
# MUSIC
# =============================================================================

func _start_music() -> void:
	## Starts the appropriate music track for this level's world.
	## Uses AudioManager.play_for_level which maps level/world numbers
	## to the correct music track.

	var world_num: int = GameState.get_world_for_level(level_num)
	AudioManager.play_for_level(level_num, world_num)


# =============================================================================
# WORLD INTRO TEXT
# =============================================================================

func _show_world_intro() -> void:
	## Displays the world name and subtitle with a fade-in, hold, fade-out
	## animation when entering a new world for the first time. This creates
	## a moment of anticipation and tells the player where they are.
	##
	## The intro is shown on a CanvasLayer so it overlays everything, and
	## it auto-removes itself after the animation completes.

	var world_num: int = GameState.get_world_for_level(level_num)
	var world_data: Dictionary = GameState.WORLDS[world_num]
	var world_name: String = world_data.get("name", "Unknown")
	var world_subtitle: String = world_data.get("subtitle", "")

	# Create a temporary CanvasLayer for the intro
	var intro_layer := CanvasLayer.new()
	intro_layer.name = "WorldIntro"
	intro_layer.layer = 20
	add_child(intro_layer)

	# Wrap everything in a Control so we can animate modulate (CanvasLayer has no modulate)
	var intro_container := Control.new()
	intro_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_layer.add_child(intro_container)

	# Semi-transparent background for readability
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.5)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_container.add_child(bg)

	# World number label
	var world_num_label := Label.new()
	world_num_label.text = "World %d" % world_num
	world_num_label.add_theme_font_size_override("font_size", 22)
	world_num_label.add_theme_color_override("font_color", Color("FFD700"))
	world_num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world_num_label.set_anchors_preset(Control.PRESET_CENTER)
	world_num_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	world_num_label.position = Vector2(-250, -70)
	world_num_label.size = Vector2(500, 30)
	intro_container.add_child(world_num_label)

	# World name label (large)
	var name_label := Label.new()
	name_label.text = world_name
	name_label.add_theme_font_size_override("font_size", 42)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.set_anchors_preset(Control.PRESET_CENTER)
	name_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	name_label.position = Vector2(-250, -35)
	name_label.size = Vector2(500, 50)
	intro_container.add_child(name_label)

	# Subtitle label (smaller, localized name)
	var subtitle_label := Label.new()
	subtitle_label.text = world_subtitle
	subtitle_label.add_theme_font_size_override("font_size", 20)
	subtitle_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.5, 0.8))
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.set_anchors_preset(Control.PRESET_CENTER)
	subtitle_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	subtitle_label.position = Vector2(-250, 25)
	subtitle_label.size = Vector2(500, 30)
	intro_container.add_child(subtitle_label)

	# Decorative separator line
	var separator := ColorRect.new()
	separator.size = Vector2(200, 2)
	separator.color = Color("FFD700", 0.6)
	separator.set_anchors_preset(Control.PRESET_CENTER)
	separator.position = Vector2(-100, 18)
	intro_container.add_child(separator)

	# Fade-in, hold, fade-out animation
	intro_container.modulate.a = 0.0

	# Fade in
	var tween_in := create_tween()
	tween_in.tween_property(intro_container, "modulate:a", 1.0, WORLD_INTRO_FADE_TIME)
	await tween_in.finished

	# Hold
	await get_tree().create_timer(WORLD_INTRO_DURATION).timeout

	# Fade out
	var tween_out := create_tween()
	tween_out.tween_property(intro_container, "modulate:a", 0.0, WORLD_INTRO_FADE_TIME)
	await tween_out.finished

	# Clean up
	intro_layer.queue_free()


# =============================================================================
# PLAYER DEATH HANDLING
# =============================================================================

func _on_player_died() -> void:
	## Handles player death. INSTANT RESPAWN for addictive arcade feel!
	## Die → Brief pause → Press X → Try again! (Pure xochi 1.0 style)

	if GameState.lives <= 0:
		# Game over - show message, wait for X to restart
		await get_tree().create_timer(0.8).timeout
		_show_game_over_text()
		# X key will trigger restart (handled in _input)
	else:
		# INSTANT SCENE RELOAD - clean restart like original xochi 1.0
		await get_tree().create_timer(0.8).timeout
		get_tree().reload_current_scene()


func _show_game_over_text() -> void:
	## Shows "TRY AGAIN" text in center of screen.
	## Pure xochi 1.0 style - minimal, instant retry!

	var retry_label := Label.new()
	retry_label.text = "TRY AGAIN"
	retry_label.add_theme_font_size_override("font_size", 56)
	retry_label.add_theme_color_override("font_color", Color("FFDD00"))  # Gold
	retry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	retry_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Drop shadow for readability
	retry_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	retry_label.add_theme_constant_override("shadow_offset_x", 4)
	retry_label.add_theme_constant_override("shadow_offset_y", 4)

	# Center on screen
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	retry_label.position = Vector2(viewport_size.x * 0.5 - 200.0, viewport_size.y * 0.45)
	retry_label.size = Vector2(400.0, 100.0)
	retry_label.z_index = 100

	# Add to HUD layer
	if hud_layer:
		hud_layer.add_child(retry_label)

	# Pulse animation
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(retry_label, "scale", Vector2(1.15, 1.15), 0.4)
	tween.tween_property(retry_label, "scale", Vector2(1.0, 1.0), 0.4)


func _respawn_player() -> void:
	## Respawns the player at the level's spawn point after death.
	## Resets the player's dead state and repositions them.

	if player == null:
		return

	var spawn: Vector2 = Vector2(100.0, 400.0)
	var spawn_data = level_data.get("player_spawn", null)
	if spawn_data is Vector2:
		spawn = spawn_data
	elif spawn_data is Dictionary:
		spawn = Vector2(spawn_data.get("x", 100.0), spawn_data.get("y", 400.0))

	player.position = spawn
	player.velocity = Vector2.ZERO
	player.is_dead = false
	player.is_invincible = true

	# Brief invincibility after respawn
	await get_tree().create_timer(Player.INVINCIBILITY_DURATION).timeout
	if player and not player.is_dead:
		player.is_invincible = false
		player.sprite.modulate = Color.WHITE


func _on_level_completed_signal(completed_level: int) -> void:
	## Handler for the Events.level_completed global signal.
	## This is separate from the local level_completed signal to allow
	## other systems (achievements, analytics) to react independently.
	pass


# =============================================================================
# UTILITY
# =============================================================================

func get_level_width() -> float:
	## Returns the current level's width in pixels.
	return level_data.get("width", 3000.0)


func get_level_height() -> float:
	## Returns the current level's height in pixels.
	return level_data.get("height", 600.0)


func get_water_y() -> float:
	## Returns the Y position of the water surface.
	return level_data.get("water_y", 550.0)


# =============================================================================
# RESPONSIVE LAYOUT HANDLERS
# =============================================================================

func _on_orientation_changed(portrait: bool) -> void:
	## Called when the device rotates between portrait and landscape.
	## Recalculates camera zoom and UI scale for the new orientation.
	print("[GameScene] Orientation changed: %s" % ("portrait" if portrait else "landscape"))
	_reconfigure_camera()
	_reconfigure_hud()


func _on_viewport_resized(new_size: Vector2) -> void:
	## Called when the viewport size changes (window resize, device rotation).
	## Adjusts camera and HUD to fit the new viewport dimensions.
	print("[GameScene] Viewport resized to: %s" % new_size)
	_reconfigure_camera()
	_reconfigure_hud()


func _reconfigure_camera() -> void:
	## Recalculates camera zoom based on current viewport size.
	if player == null:
		return

	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera == null:
		return

	# Update zoom using ViewportManager
	var zoom_val: float = ViewportManager.get_camera_zoom()
	camera.zoom = Vector2(zoom_val, zoom_val)

	# Update look-ahead offset
	var look_ahead: float = ViewportManager.get_camera_lookahead(100.0)

	var is_upscroller: bool = level_data.get("is_upscroller", false)
	var is_escape: bool = level_data.get("is_escape", false)
	var is_boss: bool = level_data.get("is_boss_level", false)

	if is_upscroller:
		camera.offset = Vector2(-look_ahead * 0.5, -100.0)
	elif is_escape:
		camera.offset = Vector2(-look_ahead, 0.0)
	elif is_boss:
		camera.offset = Vector2(-look_ahead * 0.7, 0.0)
	else:
		camera.offset = Vector2(-look_ahead, 0.0)


func _reconfigure_hud() -> void:
	## Rescales HUD elements based on current viewport size.
	## This ensures text and icons remain readable on different screen sizes.
	if hud_layer == null:
		return

	# Apply UI scale to all HUD labels
	var ui_scale := ViewportManager.get_ui_scale()
	for child in hud_layer.get_children():
		if child is Label or child is Control:
			# Scale the node
			child.scale = Vector2(ui_scale, ui_scale)

			# Reposition using design-to-viewport conversion
			if child.has_meta("design_position"):
				var design_pos: Vector2 = child.get_meta("design_position")
				child.position = ViewportManager.design_to_viewport(design_pos)

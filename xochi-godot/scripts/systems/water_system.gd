extends Node2D
class_name WaterSystem
## Manages rising water on upscroller levels (levels 3 and 8) and DKC2-style
## swimming mechanics when the player is submerged.
##
## The water starts below the screen (at the level's water_y) and rises at a
## constant 60 px/s, pressuring the player to climb. When submerged, the player
## can swim using DKC2-style swimming: hold jump (X) + direction to swim in
## that direction. If no direction is held, the player swims forward.
##
## If the player is more than 100 px below the water surface, they die instantly.
##
## Exact port from the original game.js upscroller logic (lines 4745-7520).
## The visual water uses a CanvasLayer with ColorRects so it stays fixed to the
## camera viewport regardless of camera transform. The system is instantiated
## and setup by game_scene.gd -- do not add it to any scene file.
##
## Usage:
##   var ws = WaterSystem.new()
##   ws.setup(self, player, level_width, level_height)
##   add_child(ws)
##
## Required autoloads: Events, GameState, AudioManager


# =============================================================================
# CONSTANTS -- exact values from original game.js upscroller system
# =============================================================================

## Water rises at a fixed 60 pixels per second. This is the core pressure
## mechanic: the player must climb faster than 60 px/s to survive.
const RISING_SPEED: float = 60.0

## Swimming stroke speed in px/s when holding jump + direction.
const SWIM_SPEED: float = 280.0

## Buoyancy force applied per second while submerged (negative = upward in
## screen space). This provides a gentle upward pull so the player does not
## sink like a stone when idle in water.
const WATER_BUOYANCY: float = 250.0

## Per-frame multiplier on the player's downward velocity while submerged.
## Values less than 1.0 slow the player's falling speed, simulating water drag.
const WATER_FALL_DRAG: float = 0.92

## Per-frame multiplier on horizontal velocity while submerged.
## Slightly less than 1.0 to simulate horizontal water resistance.
const WATER_HORIZONTAL_DRAG: float = 0.98

## Interpolation factor for swimming velocity. Higher = snappier steering.
## At 0.15, the player reaches ~87% of target velocity within ~12 frames.
const SWIM_LERP_FACTOR: float = 0.15

## The player dies instantly if their Y position is more than 100 px below
## the water surface. This prevents trivially swimming under everything.
const TOO_DEEP_THRESHOLD: float = 100.0

## Multiplier applied to the player's upward velocity when exiting the water.
## Values above 1.0 give a satisfying "leaping out of water" boost.
const EXIT_WATER_BOOST: float = 1.3

## How far below the surface (in pixels) the player must be before they are
## considered "in water" rather than just touching the surface. A small grace
## zone of 10 px prevents jittery enter/exit at the exact surface line.
const SURFACE_GRACE_PX: float = 10.0

## Main water body color: a rich teal at 90% opacity.
const WATER_COLOR: Color = Color(0.13, 0.6, 0.67, 0.90)

## Foam line color at the water surface: bright cyan at 75% opacity.
const FOAM_COLOR: Color = Color(0.5, 0.95, 1.0, 0.75)

## Bubble color for ambient and swim-trail bubbles: light cyan at 40% opacity.
const BUBBLE_COLOR: Color = Color(0.67, 0.93, 1.0, 0.4)

## Warning line color (pulsing red at bottom of screen when water approaches).
const WARNING_BASE_COLOR: Color = Color(1.0, 0.0, 0.0, 0.3)

## Height of the foam line at the water surface in pixels.
const FOAM_HEIGHT: float = 16.0

## Height of the warning line at the bottom of screen in pixels.
const WARNING_HEIGHT: float = 4.0

## Offset of the warning line from the bottom of the viewport in pixels.
const WARNING_BOTTOM_OFFSET: float = 30.0

## Probability per physics tick of spawning a swim-trail bubble (0-1).
const SWIM_BUBBLE_CHANCE: float = 0.3

## Probability per physics tick of spawning an ambient bubble (0-1).
const AMBIENT_BUBBLE_CHANCE: float = 0.15

## Blue tint applied to the player sprite while swimming.
const SWIM_TINT: Color = Color(0.4, 0.67, 0.8, 1.0)

## Size of each bubble particle in pixels.
const BUBBLE_SIZE: float = 6.0

## How far bubbles rise before fading out, in pixels.
const BUBBLE_RISE_DISTANCE: float = 30.0

## Duration of the bubble rise + fade animation in seconds.
const BUBBLE_DURATION: float = 0.5


# =============================================================================
# REFERENCES
# =============================================================================

## The root GameScene node (used for spawning VFX in world space).
var scene: Node2D

## The player CharacterBody2D.
var player: CharacterBody2D

## Current level width in pixels.
var level_width: float = 800.0

## Current level height in pixels.
var level_height: float = 2000.0


# =============================================================================
# STATE
# =============================================================================

## Current Y position of the water surface in world coordinates.
## Starts at the level's water_y (typically below the level bottom) and
## decreases over time as the water rises.
var water_y: float = 0.0

## Whether the water system is actively rising and checking swimming state.
var is_active: bool = false

## Whether the player is currently swimming (submerged in water).
var is_swimming: bool = false


# =============================================================================
# VISUAL NODES (created on CanvasLayer for camera-fixed rendering)
# =============================================================================

## CanvasLayer that holds all water visual elements.
## Layer 5 puts water above gameplay (z_index ~0) but below HUD (layer 10).
var water_canvas: CanvasLayer

## The main translucent water body (fills from surface to bottom of screen).
var water_rect: ColorRect

## Bright foam line along the water surface.
var foam_rect: ColorRect

## Pulsing red warning line at the bottom of the screen that intensifies
## as the water approaches the player's current screen position.
var warning_rect: ColorRect


# =============================================================================
# SETUP
# =============================================================================

## Wire up references and initialize the water system.
## Must be called after the game scene is fully initialized (player spawned,
## camera configured). The water starts at the level's water_y and begins
## rising immediately.
func setup(game_scene: Node2D, p_player: CharacterBody2D, p_level_width: float, p_level_height: float) -> void:
	scene = game_scene
	player = p_player
	level_width = p_level_width
	level_height = p_level_height

	# Water starts just below the ground so the player sees it immediately.
	# Previously started at levelHeight + 50 (invisible below screen).
	# With player at y=1900 and ground at y=1950, starting at height - 20
	# (i.e. y=1980) places the water surface ~30px below the player's feet,
	# making the rising threat visible from the first frame.
	water_y = p_level_height - 20.0

	is_active = true
	is_swimming = false

	# Add to group so Ahuizotl enemies can find us via group lookup
	add_to_group("water_system")

	_create_visuals()


# =============================================================================
# VISUAL CREATION
# =============================================================================

func _create_visuals() -> void:
	## Build the CanvasLayer and its three visual elements:
	##   1. water_rect  -- the main water body (teal, translucent)
	##   2. foam_rect   -- bright foam line at the surface
	##   3. warning_rect -- pulsing red line near the bottom of the screen
	##
	## All elements use MOUSE_FILTER_IGNORE so they never intercept input.
	## The CanvasLayer is at layer 5 so it draws above gameplay sprites
	## but below the HUD (layer 10) and pause overlay (layer 50).

	water_canvas = CanvasLayer.new()
	water_canvas.name = "WaterCanvas"
	water_canvas.layer = 5
	add_child(water_canvas)

	# --- Main water body ---
	water_rect = ColorRect.new()
	water_rect.name = "WaterBody"
	water_rect.color = WATER_COLOR
	water_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	water_rect.visible = false
	water_canvas.add_child(water_rect)

	# --- Foam line at surface ---
	foam_rect = ColorRect.new()
	foam_rect.name = "WaterFoam"
	foam_rect.color = FOAM_COLOR
	foam_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foam_rect.visible = false
	water_canvas.add_child(foam_rect)

	# --- Warning line at bottom of screen ---
	warning_rect = ColorRect.new()
	warning_rect.name = "WaterWarning"
	warning_rect.color = WARNING_BASE_COLOR
	warning_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	water_canvas.add_child(warning_rect)


# =============================================================================
# PHYSICS LOOP
# =============================================================================

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	if player == null or not is_instance_valid(player):
		return

	# Rise the water
	water_y -= RISING_SPEED * delta

	# Update visual positions relative to the camera
	_update_visuals()

	# Check swimming state and apply water physics
	_update_swimming(delta)

	# Check if the player is fatally deep
	_check_too_deep()


# =============================================================================
# VISUAL UPDATE -- maps water_y (world space) to screen space each frame
# =============================================================================

func _update_visuals() -> void:
	## Converts the water surface position from world coordinates to screen
	## coordinates, accounting for the camera's position and zoom. Then sizes
	## and positions the three visual elements accordingly.
	##
	## The key formula: screen_y = (world_y - camera_top) * zoom
	## where camera_top is the Y coordinate of the top edge of the viewport
	## in world space.

	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera == null:
		return

	# Get viewport dimensions (in screen pixels)
	var viewport_size: Vector2 = camera.get_viewport_rect().size
	var screen_w: float = viewport_size.x
	var screen_h: float = viewport_size.y

	# Camera center in world space
	var cam_center: Vector2 = camera.get_screen_center_of_mass()
	var zoom: Vector2 = camera.zoom

	# Camera top edge in world space
	var cam_top_y: float = cam_center.y - screen_h / (2.0 * zoom.y)

	# Water surface position in screen pixels
	var screen_water_y: float = (water_y - cam_top_y) * zoom.y

	# --- Water body: from the surface to well past the bottom of the screen ---
	if screen_water_y < screen_h + 100.0:
		water_rect.visible = true
		water_rect.position = Vector2(0.0, screen_water_y)
		# Extend 200 px past the screen bottom to cover any edge cases
		water_rect.size = Vector2(screen_w, screen_h - screen_water_y + 200.0)

		foam_rect.visible = true
		foam_rect.position = Vector2(0.0, screen_water_y - FOAM_HEIGHT * 0.5)
		foam_rect.size = Vector2(screen_w, FOAM_HEIGHT)

		# Wobble the foam for a wave effect
		var wave_offset := sin(Time.get_ticks_msec() * 0.003) * 3.0
		foam_rect.position.y += wave_offset
	else:
		# Water is entirely below the visible screen
		water_rect.visible = false
		foam_rect.visible = false

	# --- Warning line: fixed at the bottom of the screen ---
	# Its opacity increases as the water surface approaches
	warning_rect.position = Vector2(0.0, screen_h - WARNING_BOTTOM_OFFSET)
	warning_rect.size = Vector2(screen_w, WARNING_HEIGHT)

	# Water proximity: 0.0 = water far below screen, 1.0 = water at top of screen
	var water_proximity: float = clampf((screen_h - screen_water_y) / screen_h, 0.0, 1.0)
	warning_rect.color = Color(
		WARNING_BASE_COLOR.r,
		WARNING_BASE_COLOR.g,
		WARNING_BASE_COLOR.b,
		WARNING_BASE_COLOR.a + water_proximity * 0.5
	)


# =============================================================================
# SWIMMING PHYSICS -- DKC2-style swim mechanics
# =============================================================================

func _update_swimming(delta: float) -> void:
	## Checks whether the player is submerged and applies swimming physics.
	##
	## When entering water:
	##   - Apply a blue tint to the player sprite
	##   - Show a "SWIM!" text popup
	##   - Override normal gravity with buoyancy + drag
	##
	## While swimming (hold jump + direction):
	##   - Smoothly interpolate toward SWIM_SPEED in the input direction
	##   - Default swim direction is upward when only jump is held
	##   - Spawn bubble trail particles
	##
	## When exiting water:
	##   - Remove the blue tint
	##   - Boost upward velocity by EXIT_WATER_BOOST for a satisfying leap
	##
	## Ambient bubbles spawn randomly while submerged regardless of input.

	if player.is_dead:
		if is_swimming:
			is_swimming = false
		return

	var is_in_water: bool = player.global_position.y > water_y - SURFACE_GRACE_PX

	if is_in_water:
		if not is_swimming:
			# --- ENTER WATER ---
			is_swimming = true
			# Apply blue tint (but only if not already tinted by luchador/invincibility)
			if not player.luchador_active and not player.is_invincible:
				player.sprite.modulate = SWIM_TINT
			_show_swim_text()

		# --- WATER PHYSICS ---
		# Reduce downward velocity (water resistance on falling)
		if player.velocity.y > 0.0:
			player.velocity.y *= WATER_FALL_DRAG

		# Buoyancy: gentle upward pull
		player.velocity.y -= WATER_BUOYANCY * delta

		# Horizontal drag
		player.velocity.x *= WATER_HORIZONTAL_DRAG

		# --- DKC2 SWIMMING: hold jump + direction ---
		if Input.is_action_pressed("jump"):
			var swim_dir := Vector2.ZERO

			if Input.is_action_pressed("move_left"):
				swim_dir.x = -1.0
			elif Input.is_action_pressed("move_right"):
				swim_dir.x = 1.0

			# Holding jump always pulls upward
			swim_dir.y = -1.0

			# Normalize to prevent faster diagonal movement
			if swim_dir.length_squared() > 0.0:
				swim_dir = swim_dir.normalized()

			# Smooth interpolation toward target swim velocity
			var target_vel: Vector2 = swim_dir * SWIM_SPEED
			player.velocity.x += (target_vel.x - player.velocity.x) * SWIM_LERP_FACTOR
			player.velocity.y += (target_vel.y - player.velocity.y) * SWIM_LERP_FACTOR

			# Bubble trail behind the swimmer
			if randf() < SWIM_BUBBLE_CHANCE:
				var bubble_offset := Vector2(
					-swim_dir.x * 15.0 + randf_range(-5.0, 5.0),
					randf_range(-8.0, 8.0)
				)
				_spawn_bubble(player.global_position + bubble_offset)

		# Ambient bubbles (regardless of swimming input)
		if randf() < AMBIENT_BUBBLE_CHANCE:
			_spawn_bubble(player.global_position + Vector2(
				randf_range(-10.0, 10.0), 10.0
			))

	elif is_swimming:
		# --- EXIT WATER ---
		is_swimming = false

		# Restore sprite color (unless luchador/invincibility is active)
		if not player.luchador_active and not player.is_invincible:
			player.sprite.modulate = Color.WHITE

		# Boost out of water for a satisfying leap
		if player.velocity.y < 0.0:
			player.velocity.y *= EXIT_WATER_BOOST


# =============================================================================
# TOO-DEEP DEATH CHECK
# =============================================================================

func _check_too_deep() -> void:
	## Kills the player if they are more than TOO_DEEP_THRESHOLD pixels below
	## the water surface. This prevents the player from trivially swimming
	## under everything and adds urgency to the upscroller mechanic.

	if player.is_dead:
		return

	if player.global_position.y > water_y + TOO_DEEP_THRESHOLD:
		_show_too_deep_text()
		player.hit(999)  # Instant death


# =============================================================================
# FLOATING TEXT -- "SWIM!" and "TOO DEEP!" popups
# =============================================================================

func _show_swim_text() -> void:
	## Spawns a cyan "SWIM!" label above the player that rises and fades out.
	## Tells the player they have entered the water and can now swim.

	var label := Label.new()
	label.text = "SWIM!"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.4, 0.87, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.global_position = player.global_position + Vector2(-20.0, -30.0)
	label.z_index = 100
	scene.add_child(label)

	var tween := scene.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 30.0, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(label.queue_free)


func _show_too_deep_text() -> void:
	## Spawns a red "TOO DEEP!" label above the player that rises and fades out.
	## Provides clear feedback that the player died from being too far underwater.

	var label := Label.new()
	label.text = "TOO DEEP!"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.27, 0.27))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.global_position = player.global_position + Vector2(-30.0, -30.0)
	label.z_index = 100
	scene.add_child(label)

	var tween := scene.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 30.0, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(label.queue_free)


# =============================================================================
# BUBBLE PARTICLES -- simple ColorRect particles with tweened rise + fade
# =============================================================================

func _spawn_bubble(pos: Vector2) -> void:
	## Spawns a single small bubble particle at the given world position.
	## The bubble rises upward by BUBBLE_RISE_DISTANCE pixels while fading
	## out over BUBBLE_DURATION seconds, then self-destructs.

	var bubble := ColorRect.new()
	bubble.size = Vector2(BUBBLE_SIZE, BUBBLE_SIZE)
	bubble.position = pos - Vector2(BUBBLE_SIZE * 0.5, BUBBLE_SIZE * 0.5)
	bubble.color = BUBBLE_COLOR
	bubble.z_index = 90
	scene.add_child(bubble)

	var tween := scene.create_tween()
	tween.set_parallel(true)
	tween.tween_property(bubble, "position:y", bubble.position.y - BUBBLE_RISE_DISTANCE, BUBBLE_DURATION)
	tween.tween_property(bubble, "modulate:a", 0.0, BUBBLE_DURATION)
	tween.chain().tween_callback(bubble.queue_free)


# =============================================================================
# PUBLIC API
# =============================================================================

## Returns the current Y position of the water surface in world coordinates.
## Useful for other systems (camera, HUD) that need to know water state.
func get_water_y() -> float:
	return water_y


## Override the water_y position. Used when loading from level data that
## specifies a custom starting water_y different from level_height + 50.
func set_water_y(new_y: float) -> void:
	water_y = new_y


## Pause or resume the water system. When paused, the water stops rising
## and swimming physics are not applied. Useful for cutscenes or pause.
func set_active(active: bool) -> void:
	is_active = active


## Returns true if the player is currently swimming (submerged in water).
func get_is_swimming() -> bool:
	return is_swimming


# =============================================================================
# CLEANUP
# =============================================================================

func _exit_tree() -> void:
	## Clean up swimming state when the system is removed from the tree.
	## Restores the player's sprite color if we tinted it.
	if is_swimming and player != null and is_instance_valid(player):
		if not player.luchador_active and not player.is_invincible:
			player.sprite.modulate = Color.WHITE
	is_swimming = false
	is_active = false

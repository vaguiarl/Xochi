extends Node2D
class_name EscapeSystem
## Manages the chasing flood on escape levels (levels 7 and 9).
##
## A towering wall of water advances from the left side of the screen,
## forcing the player to run right. The flood speed is constant
## (120 px/s for level 7, 150 px/s for level 9). If the player falls
## behind the flood wall they die instantly.
##
## Ported from the original game.js:
##   - Flood logic: lines 4774-4816
##   - Escape rendering: lines 7553-7618
##
## Usage:
##   var es = EscapeSystem.new()
##   es.setup(player, level_width, escape_speed, water_y)
##   add_child(es)
##
## Required autoloads: Events, AudioManager


# =============================================================================
# CONFIGURATION -- colors and thresholds from original game.js
# =============================================================================

## Main flood body color: deep blue with slight transparency.
const FLOOD_COLOR: Color = Color(0.07, 0.4, 0.67, 0.9)  # 0x1166aa

## Foamy leading edge color: light blue foam.
const FOAM_COLOR: Color = Color(0.4, 0.8, 1.0, 0.8)  # 0x66ccff

## Spray mist color: near-white blue for splash particles.
const SPRAY_COLOR: Color = Color(0.67, 0.93, 1.0, 0.6)  # 0xaaeeff

## Player dies when their X position falls behind flood_x + this offset.
## The 30 px buffer gives a tiny sliver of reaction time so the death
## doesn't feel unfair when the flood is just barely touching the sprite.
const CATCH_OFFSET: float = 30.0


# =============================================================================
# STATE
# =============================================================================

## World-space X position of the flood front. Starts off-screen left.
var flood_x: float = -100.0

## Flood advance speed in pixels per second (set from level_data["escape_speed"]).
var flood_speed: float = 120.0

## Whether the flood is currently active and advancing.
var is_active: bool = false

## Reference to the player CharacterBody2D.
var player: CharacterBody2D = null

## Total level width in pixels (used for safety bounds).
var level_width: float = 3000.0

## Y position of the water surface for the water-death check.
var water_y: float = 560.0


# =============================================================================
# VISUAL NODE REFERENCES
# =============================================================================
## All visuals are drawn on a CanvasLayer in screen-space so the flood
## overlay moves with the camera and always fills the correct portion of
## the viewport.

## CanvasLayer that holds the flood, foam, and warning strip.
var flood_canvas: CanvasLayer = null

## Main flood body -- a tall ColorRect filling from the left edge to the
## computed flood position in screen space.
var flood_rect: ColorRect = null

## Foamy leading edge -- a thin colored strip at the front of the flood.
var foam_rect: ColorRect = null

## Warning indicator -- a narrow strip on the left edge of the viewport
## that pulses red/orange to alert the player of the approaching flood.
var warning_rect: ColorRect = null

## Tween that drives the warning strip pulse animation.
var _warning_tween: Tween = null


# =============================================================================
# SETUP
# =============================================================================

func setup(p_player: CharacterBody2D, p_level_width: float, p_flood_speed: float, p_water_y: float) -> void:
	## Initialize the escape system with level-specific parameters.
	## Call this once from game_scene.gd _ready() after the player is spawned.
	player = p_player
	level_width = p_level_width
	flood_speed = p_flood_speed
	water_y = p_water_y
	flood_x = -100.0  # Start just off-screen left
	is_active = true

	_create_visuals()
	_show_run_text()


# =============================================================================
# VISUALS -- FLOOD OVERLAY
# =============================================================================

func _create_visuals() -> void:
	## Builds the screen-space flood overlay on a CanvasLayer.
	## Layer 5 sits above gameplay sprites but below the HUD (layer 10)
	## and the pause overlay (layer 50).

	flood_canvas = CanvasLayer.new()
	flood_canvas.name = "FloodCanvas"
	flood_canvas.layer = 5  # Above gameplay, below HUD
	add_child(flood_canvas)

	# --- Main flood body ---
	flood_rect = ColorRect.new()
	flood_rect.color = FLOOD_COLOR
	flood_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flood_rect.visible = false
	flood_canvas.add_child(flood_rect)

	# --- Foamy leading edge ---
	foam_rect = ColorRect.new()
	foam_rect.color = FOAM_COLOR
	foam_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foam_rect.visible = false
	flood_canvas.add_child(foam_rect)

	# --- Warning strip on left edge ---
	# This thin red bar sits at the left margin of the screen and pulses
	# to create urgency. Its color shifts from orange (distant) to red
	# (close) as the flood approaches the visible area.
	warning_rect = ColorRect.new()
	warning_rect.color = Color(1.0, 0.0, 0.0, 0.6)
	warning_rect.size = Vector2(8, 600)
	warning_rect.position = Vector2(22, 0)
	warning_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flood_canvas.add_child(warning_rect)

	# Pulse the warning strip alpha between 0.2 and 1.0 continuously
	_warning_tween = create_tween().set_loops()
	_warning_tween.tween_property(warning_rect, "modulate:a", 0.2, 0.2)
	_warning_tween.tween_property(warning_rect, "modulate:a", 1.0, 0.2)


# =============================================================================
# VISUALS -- "RUN!" TEXT AT LEVEL START
# =============================================================================

func _show_run_text() -> void:
	## Display a large red "RUN!" message at the center of the screen when
	## the escape level begins. The text scales up to 1.3x and fades out
	## over 1.5 seconds, creating an urgent call-to-action moment.

	var run_canvas := CanvasLayer.new()
	run_canvas.name = "RunTextCanvas"
	run_canvas.layer = 15  # Above HUD so it cannot be missed
	add_child(run_canvas)

	var run_label := Label.new()
	run_label.text = "RUN!"
	run_label.add_theme_font_size_override("font_size", 64)
	run_label.add_theme_color_override("font_color", Color(1.0, 0.27, 0.27))

	# Drop shadow for readability against any background
	run_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	run_label.add_theme_constant_override("shadow_offset_x", 3)
	run_label.add_theme_constant_override("shadow_offset_y", 3)

	# Center on screen
	run_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	run_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	run_label.set_anchors_preset(Control.PRESET_CENTER)
	run_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	run_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	run_label.position = Vector2(-150, -80)
	run_label.size = Vector2(300, 100)

	# Set pivot to center so scale animates outward from the middle
	run_label.pivot_offset = Vector2(150, 50)

	run_canvas.add_child(run_label)

	# Animate: scale up 1.3x while fading to transparent over 1.5 s
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(run_label, "scale", Vector2(1.3, 1.3), 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(run_label, "modulate:a", 0.0, 1.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(run_canvas.queue_free)


# =============================================================================
# PHYSICS UPDATE -- flood advance, visual sync, death checks
# =============================================================================

func _physics_process(delta: float) -> void:
	if not is_active or player == null:
		return

	# Advance the flood wall at constant speed
	flood_x += flood_speed * delta

	# Sync the screen-space visuals with the new flood position
	_update_visuals()

	# --- Death check: caught by flood ---
	# If the player's X position is behind the flood front by CATCH_OFFSET
	# pixels, they have been engulfed by the water.
	if player.global_position.x < flood_x + CATCH_OFFSET:
		if not player.is_dead:
			_show_caught_text()
			player.hit(999)  # Instant death (999 damage)

	# --- Death check: fell in water ---
	# If the player drops below the water surface they drown.
	if player.global_position.y > water_y - 10.0:
		if not player.is_dead:
			_show_splash_text()
			player.hit(999)


# =============================================================================
# VISUAL UPDATE -- position flood rects in screen space each frame
# =============================================================================

func _update_visuals() -> void:
	## Converts the world-space flood_x into screen-space coordinates using
	## the player's Camera2D, then sizes the flood and foam rects to fill
	## the correct portion of the viewport.

	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera == null:
		return

	# Calculate where the flood front appears on screen
	var viewport_size: Vector2 = camera.get_viewport_rect().size
	var cam_center: Vector2 = camera.get_screen_center_position()
	var cam_left: float = cam_center.x - viewport_size.x / (2.0 * camera.zoom.x)
	var screen_flood_x: float = (flood_x - cam_left) * camera.zoom.x
	var cam_h: float = viewport_size.y

	# Only show the flood rects when the flood is close enough to be visible
	if screen_flood_x > -200.0:
		# --- Main flood body ---
		# Fills from the left edge of the screen to 50 px past the flood front
		flood_rect.visible = true
		flood_rect.position = Vector2(0.0, 0.0)
		flood_rect.size = Vector2(maxf(0.0, screen_flood_x + 50.0), cam_h)

		# --- Foamy leading edge ---
		# A 30 px wide strip at the front of the flood
		foam_rect.visible = true
		foam_rect.position = Vector2(screen_flood_x + 30.0, 0.0)
		foam_rect.size = Vector2(30.0, cam_h)
	else:
		flood_rect.visible = false
		foam_rect.visible = false

	# --- Warning strip color and intensity ---
	# Ramps from orange (distant) to red (close) as the flood approaches
	# the left edge of the viewport. flood_proximity is 0.0 when the flood
	# is off-screen and 1.0 when it is 150 px into the viewport.
	var flood_proximity: float = clampf(screen_flood_x / 150.0, 0.0, 1.0)
	var base_alpha: float = 0.3 + flood_proximity * 0.6

	if flood_proximity > 0.5:
		# Close: red
		warning_rect.color = Color(1.0, 0.0, 0.0, base_alpha)
	else:
		# Distant: orange
		warning_rect.color = Color(1.0, 0.67, 0.0, base_alpha)


# =============================================================================
# DEATH FEEDBACK -- floating text labels
# =============================================================================

func _show_caught_text() -> void:
	## Shows a "CAUGHT!" label at the player's position that floats upward
	## and fades out. Blue text matches the water theme.

	var label := Label.new()
	label.text = "CAUGHT!"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.27, 0.53, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.global_position = player.global_position + Vector2(-30.0, -30.0)
	label.z_index = 100
	get_parent().add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 30.0, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(label.queue_free)


func _show_splash_text() -> void:
	## Shows a "SPLASH!" label at the player's position that floats upward
	## and fades out. Cyan text matches the water splash feel.

	var label := Label.new()
	label.text = "SPLASH!"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.0, 0.67, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.global_position = player.global_position + Vector2(-25.0, -30.0)
	label.z_index = 100
	get_parent().add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 30.0, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(label.queue_free)


# =============================================================================
# EXTERNAL CONTROL
# =============================================================================

func stop() -> void:
	## Immediately stops the flood advance and hides all visuals.
	## Called by game_scene.gd when the level is completed.
	is_active = false

	if _warning_tween and _warning_tween.is_valid():
		_warning_tween.kill()

	if flood_rect:
		flood_rect.visible = false
	if foam_rect:
		foam_rect.visible = false
	if warning_rect:
		warning_rect.visible = false


func get_flood_x() -> float:
	## Returns the current world-space X position of the flood front.
	## Useful for game_scene.gd or other systems that need to know where
	## the flood is (e.g. to prevent enemies from spawning behind it).
	return flood_x


# =============================================================================
# CLEANUP
# =============================================================================

func _exit_tree() -> void:
	if _warning_tween and _warning_tween.is_valid():
		_warning_tween.kill()

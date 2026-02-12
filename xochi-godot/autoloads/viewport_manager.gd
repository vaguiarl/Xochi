extends Node
## Manages responsive viewport scaling and orientation handling for mobile devices.
##
## Automatically adjusts camera zoom, UI scale, and layout when the device
## orientation changes between portrait and landscape. Also provides utilities
## for touch-friendly UI sizing.
##
## This autoload is initialized before any scenes load and listens for window
## size changes throughout the game's lifetime.

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when the device orientation changes (portrait <-> landscape).
signal orientation_changed(is_portrait: bool)

## Emitted when the viewport size changes (window resize, device rotation).
signal viewport_resized(new_size: Vector2)


# =============================================================================
# STATE
# =============================================================================

## Current viewport size in pixels.
var viewport_size: Vector2 = Vector2(800, 600)

## Current orientation: true = portrait (height > width), false = landscape.
var is_portrait: bool = false

## Design reference size (the original 800x600 web build).
const DESIGN_WIDTH: float = 800.0
const DESIGN_HEIGHT: float = 600.0

## Computed scale factor for UI elements (relative to design size).
var ui_scale: float = 1.0

## Minimum scale to maintain readability on small devices.
const MIN_SCALE: float = 0.6

## Maximum scale to prevent oversized UI on large tablets.
const MAX_SCALE: float = 2.5


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Get initial viewport size
	_update_viewport_size()

	# Connect to window size changes
	if DisplayServer.get_name() != "headless":
		get_tree().get_root().size_changed.connect(_on_viewport_size_changed)

	print("[ViewportManager] Initialized. Size: %s, Portrait: %s, UI Scale: %.2f" % [
		viewport_size, is_portrait, ui_scale
	])


func _update_viewport_size() -> void:
	## Recalculates viewport size, orientation, and UI scale.
	var window := get_viewport().get_visible_rect().size
	if window == Vector2.ZERO:
		window = Vector2(DESIGN_WIDTH, DESIGN_HEIGHT)

	viewport_size = window

	# Determine orientation
	var was_portrait := is_portrait
	is_portrait = viewport_size.y > viewport_size.x

	# Calculate UI scale based on smaller dimension
	var width_scale := viewport_size.x / DESIGN_WIDTH
	var height_scale := viewport_size.y / DESIGN_HEIGHT
	ui_scale = clampf(minf(width_scale, height_scale), MIN_SCALE, MAX_SCALE)

	# Emit signals if orientation changed
	if was_portrait != is_portrait:
		orientation_changed.emit(is_portrait)

	viewport_resized.emit(viewport_size)


func _on_viewport_size_changed() -> void:
	_update_viewport_size()
	print("[ViewportManager] Viewport resized to %s (portrait: %s, scale: %.2f)" % [
		viewport_size, is_portrait, ui_scale
	])


# =============================================================================
# CAMERA UTILITIES
# =============================================================================

## Returns the appropriate camera zoom for the current viewport.
## Matches the original game's mobile zoom logic (game.js line 4582).
func get_camera_zoom() -> float:
	# Original: Math.max(1.0, Math.min(2.2, 600 / game.canvas.height))
	var zoom := clampf(600.0 / viewport_size.y, 1.0, 2.2)
	return zoom


## Returns camera look-ahead offset scaled by current zoom.
func get_camera_lookahead(base_offset: float = 100.0) -> float:
	return base_offset * get_camera_zoom()


# =============================================================================
# UI UTILITIES
# =============================================================================

## Returns a scale factor for UI elements (buttons, text, HUD).
## Use this to scale Control nodes: control.scale = Vector2.ONE * get_ui_scale()
func get_ui_scale() -> float:
	return ui_scale


## Converts a design-space position (relative to 800x600) to viewport space.
func design_to_viewport(design_pos: Vector2) -> Vector2:
	var scale_x := viewport_size.x / DESIGN_WIDTH
	var scale_y := viewport_size.y / DESIGN_HEIGHT
	return Vector2(design_pos.x * scale_x, design_pos.y * scale_y)


## Converts a design-space size to viewport space.
func design_size_to_viewport(design_size: Vector2) -> Vector2:
	var scale_x := viewport_size.x / DESIGN_WIDTH
	var scale_y := viewport_size.y / DESIGN_HEIGHT
	return Vector2(design_size.x * scale_x, design_size.y * scale_y)


## Returns true if the current device is likely a mobile device (small screen).
func is_mobile_device() -> bool:
	# Heuristic: viewport width < 1000px or touch input available
	return viewport_size.x < 1000.0 or DisplayServer.is_touchscreen_available()


## Returns the safe area rectangle (avoids notches, home indicators on iOS).
func get_safe_area() -> Rect2:
	if DisplayServer.get_name() == "iOS" or DisplayServer.get_name() == "Android":
		return DisplayServer.get_display_safe_area()
	else:
		# Desktop: entire viewport is safe
		return Rect2(Vector2.ZERO, viewport_size)


# =============================================================================
# ORIENTATION LOCK UTILITIES
# =============================================================================

## Locks the game to landscape orientation (useful for certain levels).
func lock_landscape() -> void:
	if DisplayServer.get_name() == "Android" or DisplayServer.get_name() == "iOS":
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)


## Locks the game to portrait orientation.
func lock_portrait() -> void:
	if DisplayServer.get_name() == "Android" or DisplayServer.get_name() == "iOS":
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)


## Unlocks orientation, allowing sensor-based rotation.
func unlock_orientation() -> void:
	if DisplayServer.get_name() == "Android" or DisplayServer.get_name() == "iOS":
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR)

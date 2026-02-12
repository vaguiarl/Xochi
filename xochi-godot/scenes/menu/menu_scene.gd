extends Control
## Enhanced main menu for Xochi - full feature port from MenuScene.js.
##
## Features SNES-style gradient background, twinkling stars, floating particles,
## animated title, character preview, scoreboard, difficulty selector, world selector,
## and controls overlay. Fully responsive for mobile and desktop.

# UI References
var title_label: Label
var title_shadow: Label
var subtitle_label: Label
var xochi_preview: Sprite2D
var play_button: Button
var new_game_button: Button
var controls_button: Button
var difficulty_buttons: Array[Button] = []
var world_buttons: Array[Button] = []
var world_tooltip: Label = null
var controls_overlay: Control = null

# Animation
var stars: Array[Node] = []
var particles: Array[Node] = []
var title_tween: Tween = null
var xochi_tween: Tween = null

# Constants
const STAR_COUNT: int = 30
const PARTICLE_COUNT: int = 12
const PARTICLE_COLORS: Array[Color] = [
	Color("4ecdc4"),  # Cyan
	Color("ff6b9d"),  # Pink
	Color("ffdd00")   # Yellow
]


func _ready() -> void:
	# SNES-style gradient background
	RenderingServer.set_default_clear_color(Color("1a0a2e"))
	_create_gradient_background()

	# Animated stars
	_create_stars()

	# Floating particles
	_create_particles()

	# Play menu music
	AudioManager.play_music("music_menu")

	# Build UI
	_create_ui()

	# Connect to viewport changes for responsive layout
	ViewportManager.viewport_resized.connect(_on_viewport_resized)


func _create_gradient_background() -> void:
	## Creates SNES-style vertical gradient stripes.
	var bg_colors: Array[Color] = [
		Color("1a0a2e"), Color("1a1a3e"), Color("2a2a4e"),
		Color("1a2a4e"), Color("1a1a3e"), Color("1a0a2e")
	]

	var stripe_height := ViewportManager.viewport_size.y / bg_colors.size()

	for i in range(bg_colors.size()):
		var stripe := ColorRect.new()
		stripe.color = bg_colors[i]
		stripe.position = Vector2(0, i * stripe_height)
		stripe.size = Vector2(ViewportManager.viewport_size.x, stripe_height + 2)
		stripe.z_index = -100
		add_child(stripe)


func _create_stars() -> void:
	## Creates 30 twinkling stars at random positions.
	for i in range(STAR_COUNT):
		var star_size := randf_range(2.0, 6.0)
		var star := ColorRect.new()
		star.color = Color.WHITE
		star.size = Vector2(star_size, star_size)
		star.position = Vector2(
			randf() * ViewportManager.viewport_size.x,
			randf() * ViewportManager.viewport_size.y
		)
		star.modulate.a = randf_range(0.2, 0.8)
		add_child(star)
		stars.append(star)

		# Twinkling animation
		var tween := create_tween()
		tween.set_loops()
		tween.tween_property(star, "modulate:a", 0.1, randf_range(0.5, 1.5))
		tween.tween_property(star, "modulate:a", randf_range(0.2, 0.8), randf_range(0.5, 1.5))


func _create_particles() -> void:
	## Creates 12 floating particles that rise and fade.
	for i in range(PARTICLE_COUNT):
		var particle_size := randf_range(6.0, 12.0)
		var particle := ColorRect.new()
		particle.color = PARTICLE_COLORS[randi() % PARTICLE_COLORS.size()]
		particle.size = Vector2(particle_size, particle_size)
		particle.position = Vector2(
			randf() * ViewportManager.viewport_size.x,
			ViewportManager.viewport_size.y + 30
		)
		particle.modulate.a = 0.4
		add_child(particle)
		particles.append(particle)

		# Rising/fading animation
		var tween := create_tween()
		tween.set_loops()
		var duration := randf_range(3.0, 5.0)
		tween.tween_property(particle, "position:y", particle.position.y - 120, duration)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, duration)
		tween.parallel().tween_property(particle, "scale", Vector2(0.5, 0.5), duration)
		tween.tween_callback(func():
			particle.position.x = randf() * ViewportManager.viewport_size.x
			particle.position.y = ViewportManager.viewport_size.y + 30
			particle.modulate.a = 0.4
			particle.scale = Vector2.ONE
		)


# =============================================================================
# HELPER: Create a properly centered label (full viewport width)
# =============================================================================

func _make_centered_label(text: String, y_design: float, font_size_base: int, color: Color, outline_color: Color = Color.TRANSPARENT, outline_size_base: int = 0) -> Label:
	## Creates a label that is truly centered across the viewport.
	## In Godot, horizontal_alignment only works when the label has explicit width.
	var ui_scale := ViewportManager.get_ui_scale()
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", int(font_size_base * ui_scale))
	label.add_theme_color_override("font_color", color)
	if outline_color != Color.TRANSPARENT:
		label.add_theme_color_override("font_outline_color", outline_color)
		label.add_theme_constant_override("outline_size", int(outline_size_base * ui_scale))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size.x = ViewportManager.viewport_size.x
	label.position = Vector2(0, ViewportManager.design_to_viewport(Vector2(0, y_design)).y)
	return label


func _create_ui() -> void:
	var center_x := ViewportManager.viewport_size.x / 2.0
	var ui_scale := ViewportManager.get_ui_scale()
	var vw := ViewportManager.viewport_size.x

	# Title shadow
	title_shadow = _make_centered_label("XOCHI", 40, 60, Color("220022"))
	title_shadow.position += Vector2(4, 4)
	add_child(title_shadow)

	# Title main
	title_label = _make_centered_label("XOCHI", 40, 60, Color("ff6b9d"), Color("ffbbcc"), 4)
	add_child(title_label)

	# Title pulse animation
	title_tween = create_tween()
	title_tween.set_loops()
	title_tween.set_ease(Tween.EASE_IN_OUT)
	title_tween.set_trans(Tween.TRANS_SINE)
	title_tween.tween_property(title_label, "scale", Vector2(1.02, 1.02), 1.5)
	title_tween.tween_property(title_label, "scale", Vector2.ONE, 1.5)

	# Subtitle
	subtitle_label = _make_centered_label("Aztec Warrior Adventure", 95, 18, Color("66ddcc"), Color("224444"), 2)
	add_child(subtitle_label)

	# Character preview with glow
	var preview_y := ViewportManager.design_to_viewport(Vector2(0, 140)).y
	var glow := _create_circle(Vector2(center_x, preview_y), 30 * ui_scale, Color("ff6b9d"))
	glow.modulate.a = 0.3
	add_child(glow)

	var glow_tween := create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(glow, "scale", Vector2(1.2, 1.2), 1.0)
	glow_tween.parallel().tween_property(glow, "modulate:a", 0.1, 1.0)
	glow_tween.tween_property(glow, "scale", Vector2.ONE, 1.0)
	glow_tween.parallel().tween_property(glow, "modulate:a", 0.3, 1.0)

	# Xochi warrior sprite (replacing cyan placeholder)
	var xochi_texture := load("res://assets/sprites/player/big_xochi_idle_small.png") as Texture2D
	xochi_preview = Sprite2D.new()
	xochi_preview.texture = xochi_texture
	# Scale to fit ~60px preview area (source is 604x320)
	var sprite_scale := (60.0 * ui_scale) / xochi_texture.get_height()
	xochi_preview.scale = Vector2(sprite_scale, sprite_scale)
	xochi_preview.position = Vector2(center_x, preview_y)
	add_child(xochi_preview)

	# Bobbing animation
	xochi_tween = create_tween()
	xochi_tween.set_loops()
	xochi_tween.set_ease(Tween.EASE_IN_OUT)
	xochi_tween.set_trans(Tween.TRANS_SINE)
	xochi_tween.tween_property(xochi_preview, "position:y", preview_y - 8 * ui_scale, 0.8)
	xochi_tween.tween_property(xochi_preview, "position:y", preview_y, 0.8)

	# Subtle breathing scale animation
	var breath_tween := create_tween()
	breath_tween.set_loops()
	breath_tween.set_ease(Tween.EASE_IN_OUT)
	breath_tween.set_trans(Tween.TRANS_SINE)
	var base_scale := Vector2(sprite_scale, sprite_scale)
	var breath_scale := base_scale * 1.02
	breath_tween.tween_property(xochi_preview, "scale", breath_scale, 1.2)
	breath_tween.tween_property(xochi_preview, "scale", base_scale, 1.2)

	# Scoreboard box
	_create_scoreboard()

	# Difficulty selector
	_create_difficulty_selector()

	# Action buttons
	_create_action_buttons()

	# World selector
	_create_world_selector()


func _create_scoreboard() -> void:
	var center_x := ViewportManager.viewport_size.x / 2.0
	var pos_y := ViewportManager.design_to_viewport(Vector2(0, 200)).y
	var ui_scale := ViewportManager.get_ui_scale()

	var box_w := 280.0 * ui_scale
	var box_h := 60.0 * ui_scale

	# Box shadow
	var shadow := ColorRect.new()
	shadow.color = Color.BLACK
	shadow.modulate.a = 0.5
	shadow.position = Vector2(center_x - box_w / 2 + 3, pos_y - box_h / 2 + 3)
	shadow.size = Vector2(box_w, box_h)
	add_child(shadow)

	# Box outer border
	var outer := ColorRect.new()
	outer.color = Color("4ecdc4")
	outer.position = Vector2(center_x - box_w / 2, pos_y - box_h / 2)
	outer.size = Vector2(box_w, box_h)
	add_child(outer)

	# Box inner
	var inner := ColorRect.new()
	inner.color = Color("1a2a4e")
	inner.position = Vector2(center_x - box_w / 2 + 3, pos_y - box_h / 2 + 3)
	inner.size = Vector2(box_w - 6, box_h - 6)
	add_child(inner)

	# Score text
	var score_label := _make_centered_label("SCORE: %d" % GameState.score, 188, 18, Color("ffee44"), Color("886600"), 2)
	add_child(score_label)

	# High score text
	var high_score_label := _make_centered_label("HIGH SCORE: %d" % GameState.high_score, 210, 13, Color("ff88aa"))
	add_child(high_score_label)

	# Progress text
	var progress_label := _make_centered_label(
		"Level %d/%d | Stars: %d/30 | Rescued: %d/10" % [
			GameState.current_level, GameState.total_levels,
			GameState.stars.size(), GameState.rescued_babies.size()
		], 240, 11, Color("88aacc")
	)
	add_child(progress_label)


func _create_difficulty_selector() -> void:
	var ui_scale := ViewportManager.get_ui_scale()
	var center_x := ViewportManager.viewport_size.x / 2.0

	# Title
	var title := _make_centered_label("DIFFICULTY", 265, 11, Color("aaaaaa"))
	add_child(title)

	# Difficulty buttons — wider buttons with smaller font to prevent text overflow
	var difficulties := ["easy", "medium", "hard"]
	var diff_colors := {
		"easy": {"bg": Color("44aa44"), "text": Color("88ff88"), "label": "EASY"},
		"medium": {"bg": Color("aaaa44"), "text": Color("ffff88"), "label": "MEDIUM"},
		"hard": {"bg": Color("aa4444"), "text": Color("ff8888"), "label": "HARD"}
	}

	var btn_width := 90.0 * ui_scale
	var btn_height := 30.0 * ui_scale
	var btn_gap := 8.0 * ui_scale
	var total_w := 3 * btn_width + 2 * btn_gap
	var start_x := center_x - total_w / 2.0 + btn_width / 2.0
	var y := ViewportManager.design_to_viewport(Vector2(0, 290)).y

	for i in range(difficulties.size()):
		var diff: String = difficulties[i]
		var x := start_x + i * (btn_width + btn_gap)
		var is_selected := GameState.difficulty == diff
		var colors: Dictionary = diff_colors[diff]

		# Border for selected
		if is_selected:
			var border := ColorRect.new()
			border.color = Color.WHITE
			border.position = Vector2(x - btn_width / 2 - 2, y - btn_height / 2 - 2)
			border.size = Vector2(btn_width + 4, btn_height + 4)
			add_child(border)

		# Button
		var btn := _create_button(
			Vector2(x, y),
			Vector2(btn_width, btn_height),
			colors["bg"] if is_selected else Color("333333"),
			colors["bg"],
			colors["label"],
			func(): _on_difficulty_selected(diff),
			14  # Smaller font for difficulty buttons
		)
		difficulty_buttons.append(btn)

	# Description
	var desc_texts := {
		"easy": "5 lives, 3 super jumps, easier gaps",
		"medium": "3 lives, 2 super jumps, balanced",
		"hard": "2 lives, 1 super jump, challenging"
	}
	var desc := _make_centered_label(desc_texts[GameState.difficulty], 315, 10, Color("888888"))
	add_child(desc)


func _create_action_buttons() -> void:
	var ui_scale := ViewportManager.get_ui_scale()

	# Continue/Play button
	var play_text := "CONTINUE" if GameState.current_level > 1 else "PLAY"
	play_button = _create_button(
		ViewportManager.design_to_viewport(Vector2(400, 355)),
		Vector2(200, 42) * ui_scale,
		Color("33bb99"),
		Color("44ccaa"),
		play_text,
		_on_play_pressed,
		20
	)

	# New Game button
	new_game_button = _create_button(
		ViewportManager.design_to_viewport(Vector2(400, 405)),
		Vector2(200, 38) * ui_scale,
		Color("dd5588"),
		Color("ee6699"),
		"NEW GAME",
		_on_new_game_pressed,
		18
	)

	# Controls button
	controls_button = _create_button(
		ViewportManager.design_to_viewport(Vector2(400, 450)),
		Vector2(200, 35) * ui_scale,
		Color("4466aa"),
		Color("5577bb"),
		"CONTROLS",
		_on_controls_pressed,
		16
	)


func _create_world_selector() -> void:
	var ui_scale := ViewportManager.get_ui_scale()
	var center_x := ViewportManager.viewport_size.x / 2.0

	# Title
	var title := _make_centered_label("SELECT WORLD", 485, 11, Color("aaaaaa"))
	add_child(title)

	# World data
	var worlds := [
		{"num": 1, "name": "Dawn", "color": Color("ffaa77")},
		{"num": 2, "name": "Day", "color": Color("55ccee")},
		{"num": 3, "name": "Cave", "color": Color("4466aa")},
		{"num": 4, "name": "Garden", "color": Color("ffcc44")},
		{"num": 5, "name": "Night", "color": Color("6644aa")},
		{"num": 6, "name": "Fiesta", "color": Color("44ccaa")}
	]

	var btn_size := 38.0 * ui_scale
	var btn_gap := 4.0 * ui_scale
	var total_width := worlds.size() * btn_size + (worlds.size() - 1) * btn_gap
	var start_x := center_x - total_width / 2.0 + btn_size / 2.0
	var y := ViewportManager.design_to_viewport(Vector2(0, 510)).y

	for i in range(worlds.size()):
		var world: Dictionary = worlds[i]
		var x := start_x + i * (btn_size + btn_gap)
		var is_current: bool = GameState.get_world_for_level(GameState.current_level) == world["num"]

		# Border for current world
		if is_current:
			var border := ColorRect.new()
			border.color = Color.WHITE
			border.position = Vector2(x - btn_size / 2 - 2, y - btn_size / 2 - 2)
			border.size = Vector2(btn_size + 4, btn_size + 4)
			add_child(border)

		# World button background
		var btn_bg := ColorRect.new()
		btn_bg.color = world["color"]
		btn_bg.position = Vector2(x - btn_size / 2, y - btn_size / 2)
		btn_bg.size = Vector2(btn_size, btn_size)
		add_child(btn_bg)

		# World label — centered within the button
		var btn_label := Label.new()
		btn_label.text = "W%d" % world["num"]
		btn_label.add_theme_font_size_override("font_size", int(12 * ui_scale))
		btn_label.add_theme_color_override("font_color", Color.WHITE)
		btn_label.add_theme_color_override("font_outline_color", Color.BLACK)
		btn_label.add_theme_constant_override("outline_size", 1)
		btn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		btn_label.size = Vector2(btn_size, btn_size)
		btn_label.position = Vector2(x - btn_size / 2, y - btn_size / 2)
		add_child(btn_label)

		# Make interactive
		var btn := Button.new()
		btn.flat = true
		btn.position = Vector2(x - btn_size / 2, y - btn_size / 2)
		btn.custom_minimum_size = Vector2(btn_size, btn_size)
		btn.pressed.connect(func(): _on_world_selected(world["num"]))
		btn.mouse_entered.connect(func(): _on_world_hover(world["num"], Vector2(x, y)))
		btn.mouse_exited.connect(_on_world_unhover)
		add_child(btn)
		world_buttons.append(btn)


func _create_button(pos: Vector2, btn_size: Vector2, base_color: Color, hover_color: Color, text: String, callback: Callable, font_size_base: int = 20) -> Button:
	## Creates a fancy 3D-style button with shadow, highlight, and centered text.
	var ui_scale := ViewportManager.get_ui_scale()
	var font_size := int(font_size_base * ui_scale)

	# Shadow
	var shadow := ColorRect.new()
	shadow.color = Color.BLACK
	shadow.modulate.a = 0.4
	shadow.position = pos + Vector2(3, 3) - btn_size / 2
	shadow.size = btn_size
	add_child(shadow)

	# Dark edge
	var dark_edge := ColorRect.new()
	dark_edge.color = base_color.darkened(0.2)
	dark_edge.position = pos + Vector2(2, 2) - btn_size / 2
	dark_edge.size = btn_size
	add_child(dark_edge)

	# Main button background
	var btn_bg := ColorRect.new()
	btn_bg.color = base_color
	btn_bg.position = pos - (btn_size - Vector2(4, 4)) / 2
	btn_bg.size = btn_size - Vector2(4, 4)
	add_child(btn_bg)

	# Top highlight
	var highlight := ColorRect.new()
	highlight.color = base_color.lightened(0.2)
	highlight.modulate.a = 0.5
	highlight.position = Vector2(pos.x - (btn_size.x - 8) / 2, pos.y - btn_size.y / 4)
	highlight.size = Vector2(btn_size.x - 8, 3)
	add_child(highlight)

	# Text shadow — centered within button bounds
	var text_shadow := Label.new()
	text_shadow.text = text
	text_shadow.add_theme_font_size_override("font_size", font_size)
	text_shadow.add_theme_color_override("font_color", Color.BLACK)
	text_shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_shadow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_shadow.size = btn_size
	text_shadow.position = pos - btn_size / 2 + Vector2(2, 2)
	add_child(text_shadow)

	# Text — centered within button bounds
	var text_label := Label.new()
	text_label.text = text
	text_label.add_theme_font_size_override("font_size", font_size)
	text_label.add_theme_color_override("font_color", Color.WHITE)
	text_label.add_theme_color_override("font_outline_color", Color.BLACK)
	text_label.add_theme_constant_override("outline_size", 1)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.size = btn_size
	text_label.position = pos - btn_size / 2
	text_label.clip_text = true
	add_child(text_label)

	# Interactive button (invisible overlay)
	var btn := Button.new()
	btn.flat = true
	btn.position = pos - btn_size / 2
	btn.custom_minimum_size = btn_size
	btn.pressed.connect(callback)
	btn.mouse_entered.connect(func():
		btn_bg.color = hover_color
		btn.scale = Vector2(1.05, 1.05)
	)
	btn.mouse_exited.connect(func():
		btn_bg.color = base_color
		btn.scale = Vector2.ONE
	)
	add_child(btn)

	return btn


func _create_circle(pos: Vector2, radius: float, color: Color) -> ColorRect:
	## Helper to create a circular ColorRect (approximated with square for simplicity).
	var circle := ColorRect.new()
	circle.color = color
	circle.position = pos - Vector2(radius, radius)
	circle.size = Vector2(radius * 2, radius * 2)
	return circle


# ---- Callbacks ----

func _on_play_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	SceneManager.change_scene("res://scenes/game/game_scene.tscn")


func _on_new_game_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	GameState.reset_game()
	SceneManager.change_scene("res://scenes/game/game_scene.tscn")


func _on_controls_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	_show_controls_overlay()


func _on_difficulty_selected(diff: String) -> void:
	AudioManager.play_sfx("menu_select")
	GameState.difficulty = diff
	var settings := GameState.get_settings()
	GameState.lives = settings["lives"]
	GameState.save_game()
	# Restart scene to update UI
	get_tree().reload_current_scene()


func _on_world_selected(world_num: int) -> void:
	AudioManager.play_sfx("menu_select")
	var start_level := GameState.get_first_level_of_world(world_num)
	GameState.current_level = start_level
	GameState.save_game()
	SceneManager.change_scene("res://scenes/game/game_scene.tscn")


func _on_world_hover(world_num: int, pos: Vector2) -> void:
	if not world_tooltip:
		world_tooltip = Label.new()
		world_tooltip.add_theme_font_size_override("font_size", 11)
		world_tooltip.add_theme_color_override("font_color", Color.WHITE)
		world_tooltip.add_theme_color_override("font_shadow_color", Color.BLACK)
		world_tooltip.add_theme_constant_override("shadow_offset_x", 1)
		world_tooltip.add_theme_constant_override("shadow_offset_y", 1)
		world_tooltip.z_index = 100
		add_child(world_tooltip)

	var world_data: Dictionary = GameState.WORLDS[world_num]
	world_tooltip.text = "%s - %s" % [world_data["name"], world_data["subtitle"]]
	world_tooltip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world_tooltip.size.x = ViewportManager.viewport_size.x
	world_tooltip.position = Vector2(0, ViewportManager.viewport_size.y - 30)
	world_tooltip.visible = true


func _on_world_unhover() -> void:
	if world_tooltip:
		world_tooltip.visible = false


func _show_controls_overlay() -> void:
	## Creates a full-screen controls overlay with keyboard and touch instructions.
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	controls_overlay = overlay
	add_child(overlay)

	# Dark background
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.modulate.a = 0.9
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)

	var ui_scale := ViewportManager.get_ui_scale()
	var vw := ViewportManager.viewport_size.x

	# Title
	var title := Label.new()
	title.text = "CONTROLS"
	title.add_theme_font_size_override("font_size", int(32 * ui_scale))
	title.add_theme_color_override("font_color", Color("4ecdc4"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size.x = vw
	title.position = Vector2(0, ViewportManager.design_to_viewport(Vector2(0, 50)).y)
	overlay.add_child(title)

	# Keyboard section
	var kb_title := Label.new()
	kb_title.text = "-- KEYBOARD --"
	kb_title.add_theme_font_size_override("font_size", int(16 * ui_scale))
	kb_title.add_theme_color_override("font_color", Color("ffcc66"))
	kb_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kb_title.size.x = vw
	kb_title.position = Vector2(0, ViewportManager.design_to_viewport(Vector2(0, 100)).y)
	overlay.add_child(kb_title)

	var kb_controls := [
		{"key": "Arrow Keys / WASD", "action": "Move left and right"},
		{"key": "X", "action": "JUMP"},
		{"key": "X + X (double tap)", "action": "SUPER JUMP (uses power-up)"},
		{"key": "Z", "action": "Attack with mace"},
		{"key": "SPACE (hold)", "action": "Run faster"},
		{"key": "ESC", "action": "Pause game"}
	]

	for i in range(kb_controls.size()):
		var ctrl: Dictionary = kb_controls[i]
		var y := 135 + i * 28

		var key_label := Label.new()
		key_label.text = ctrl["key"]
		key_label.add_theme_font_size_override("font_size", int(13 * ui_scale))
		key_label.add_theme_color_override("font_color", Color.WHITE)
		key_label.position = ViewportManager.design_to_viewport(Vector2(260, y))
		overlay.add_child(key_label)

		var action_label := Label.new()
		action_label.text = ctrl["action"]
		action_label.add_theme_font_size_override("font_size", int(13 * ui_scale))
		action_label.add_theme_color_override("font_color", Color("aaaaaa"))
		action_label.position = ViewportManager.design_to_viewport(Vector2(410, y))
		overlay.add_child(action_label)

	# Touch section
	var touch_title := Label.new()
	touch_title.text = "-- TOUCH / MOBILE --"
	touch_title.add_theme_font_size_override("font_size", int(16 * ui_scale))
	touch_title.add_theme_color_override("font_color", Color("ff6b9d"))
	touch_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	touch_title.size.x = vw
	touch_title.position = Vector2(0, ViewportManager.design_to_viewport(Vector2(0, 320)).y)
	overlay.add_child(touch_title)

	var touch_controls := [
		{"key": "Tap left side", "action": "Move left"},
		{"key": "Tap right side", "action": "Move right"},
		{"key": "Swipe up", "action": "JUMP"},
		{"key": "Double swipe up", "action": "SUPER JUMP"},
		{"key": "Tap center", "action": "Attack"},
		{"key": "Hold while moving", "action": "Run faster"}
	]

	for i in range(touch_controls.size()):
		var ctrl: Dictionary = touch_controls[i]
		var y := 355 + i * 28

		var key_label := Label.new()
		key_label.text = ctrl["key"]
		key_label.add_theme_font_size_override("font_size", int(13 * ui_scale))
		key_label.add_theme_color_override("font_color", Color.WHITE)
		key_label.position = ViewportManager.design_to_viewport(Vector2(260, y))
		overlay.add_child(key_label)

		var action_label := Label.new()
		action_label.text = ctrl["action"]
		action_label.add_theme_font_size_override("font_size", int(13 * ui_scale))
		action_label.add_theme_color_override("font_color", Color("aaaaaa"))
		action_label.position = ViewportManager.design_to_viewport(Vector2(410, y))
		overlay.add_child(action_label)

	# Tip
	var tip := Label.new()
	tip.text = "TIP: Hold toward a wall while falling to grab ledges!"
	tip.add_theme_font_size_override("font_size", int(12 * ui_scale))
	tip.add_theme_color_override("font_color", Color("66ddcc"))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.size.x = vw
	tip.position = Vector2(0, ViewportManager.design_to_viewport(Vector2(0, 530)).y)
	overlay.add_child(tip)

	# Close button
	var close_btn := _create_button(
		ViewportManager.design_to_viewport(Vector2(400, 565)),
		Vector2(150, 35) * ui_scale,
		Color("4ecdc4"),
		Color("6eeede"),
		"GOT IT!",
		_on_controls_close,
		16
	)


func _on_controls_close() -> void:
	AudioManager.play_sfx("menu_select")
	if controls_overlay:
		controls_overlay.queue_free()
		controls_overlay = null


func _input(event: InputEvent) -> void:
	# Keyboard shortcuts to start game
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		_on_play_pressed()

	# Close controls overlay
	if controls_overlay and event.is_action_pressed("ui_cancel"):
		_on_controls_close()


func _on_viewport_resized(new_size: Vector2) -> void:
	## Rebuild UI on viewport resize for responsive layout.
	pass

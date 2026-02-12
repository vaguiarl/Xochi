extends Control
## Victory celebration scene - beautiful Dia de los Muertos themed credits.
##
## Displays congratulations, rescued baby axolotl parade using real sprites,
## Xochi warrior celebration with the actual sprite, enhanced confetti with
## diamond/star shapes, and a warm stats panel. Features staggered animations
## and sinusoidal confetti motion.

# UI References
var play_again_button: Button
var menu_button: Button
var baby_sprites: Array[Node] = []
var xochi_sprite: Sprite2D = null
var confetti_particles: Array[Node] = []

# Animation state for confetti (sinusoidal sway)
var confetti_data: Array[Dictionary] = []
var time_elapsed: float = 0.0

# Constants
const CONFETTI_COUNT: int = 60
const CONFETTI_COLORS: Array[Color] = [
	Color("ff6b9d"),  # Pink (cempasuchil)
	Color("4ecdc4"),  # Teal
	Color("ffe66d"),  # Gold (marigold)
	Color("ff6b6b"),  # Coral
	Color("9b59b6"),  # Purple (Dia de los Muertos)
	Color("ffaa00"),  # Orange (cempasuchil/marigold)
	Color("ffd700"),  # Deep gold
	Color("e74c3c"),  # Rich red
]

# Confetti shape types
enum ConfettiShape { DIAMOND, RECT_WIDE, RECT_TALL, SMALL_SQUARE }


func _ready() -> void:
	# Dark background with warm tint
	RenderingServer.set_default_clear_color(Color("1a1a2e"))

	# Play victory music
	AudioManager.play_music("music_finale")

	# Create confetti (behind everything)
	_create_confetti()

	# Build UI
	_create_ui()


func _process(delta: float) -> void:
	## Update confetti sinusoidal sway each frame.
	time_elapsed += delta
	for i in range(confetti_data.size()):
		if i >= confetti_particles.size():
			break
		var data: Dictionary = confetti_data[i]
		var particle: Node2D = confetti_particles[i] as Node2D
		if particle == null:
			continue
		# Sinusoidal horizontal sway
		var sway_offset: float = sin(time_elapsed * data["sway_speed"] + data["sway_phase"]) * data["sway_amplitude"]
		particle.position.x = data["base_x"] + sway_offset
		# Falling movement
		particle.position.y += data["fall_speed"] * delta
		# Slow rotation
		particle.rotation += data["rot_speed"] * delta
		# Reset when below screen
		if particle.position.y > ViewportManager.viewport_size.y + 30:
			particle.position.y = -30.0
			data["base_x"] = randf() * ViewportManager.viewport_size.x


func _create_confetti() -> void:
	## Creates falling confetti with varied shapes and sinusoidal sway.
	for i in range(CONFETTI_COUNT):
		var base_x: float = randf() * ViewportManager.viewport_size.x
		var start_y: float = randf_range(-ViewportManager.viewport_size.y, ViewportManager.viewport_size.y)
		var color: Color = CONFETTI_COLORS[randi() % CONFETTI_COLORS.size()]
		var shape_type: int = randi() % 4

		# Create a Node2D container for the confetti piece
		var container := Node2D.new()
		container.position = Vector2(base_x, start_y)
		container.rotation = randf() * TAU

		# Create the shape as a Polygon2D for varied shapes
		var polygon := Polygon2D.new()
		polygon.color = color

		match shape_type:
			ConfettiShape.DIAMOND:
				# Diamond shape
				var s: float = randf_range(4, 8)
				polygon.polygon = PackedVector2Array([
					Vector2(0, -s), Vector2(s * 0.6, 0),
					Vector2(0, s), Vector2(-s * 0.6, 0)
				])
			ConfettiShape.RECT_WIDE:
				# Wide rectangle (confetti strip)
				var w: float = randf_range(8, 14)
				var h: float = randf_range(3, 5)
				polygon.polygon = PackedVector2Array([
					Vector2(-w/2, -h/2), Vector2(w/2, -h/2),
					Vector2(w/2, h/2), Vector2(-w/2, h/2)
				])
			ConfettiShape.RECT_TALL:
				# Tall thin rectangle
				var w: float = randf_range(3, 5)
				var h: float = randf_range(8, 14)
				polygon.polygon = PackedVector2Array([
					Vector2(-w/2, -h/2), Vector2(w/2, -h/2),
					Vector2(w/2, h/2), Vector2(-w/2, h/2)
				])
			ConfettiShape.SMALL_SQUARE:
				# Small sparkle square
				var s: float = randf_range(3, 6)
				polygon.polygon = PackedVector2Array([
					Vector2(-s/2, -s/2), Vector2(s/2, -s/2),
					Vector2(s/2, s/2), Vector2(-s/2, s/2)
				])

		container.add_child(polygon)
		add_child(container)
		confetti_particles.append(container)

		# Store animation data for sinusoidal sway
		confetti_data.append({
			"base_x": base_x,
			"fall_speed": randf_range(40.0, 120.0),
			"sway_speed": randf_range(1.5, 4.0),
			"sway_phase": randf() * TAU,
			"sway_amplitude": randf_range(20.0, 60.0),
			"rot_speed": randf_range(-2.0, 2.0),
		})


func _create_ui() -> void:
	var ui_scale: float = ViewportManager.get_ui_scale()

	# ---- Title: "CONGRATULATIONS!" ----
	var title := Label.new()
	title.text = "CONGRATULATIONS!"
	title.add_theme_font_size_override("font_size", int(42 * ui_scale))
	title.add_theme_color_override("font_color", Color("ffe66d"))
	title.add_theme_color_override("font_outline_color", Color("ff6b9d"))
	title.add_theme_constant_override("outline_size", int(4 * ui_scale))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size.x = ViewportManager.viewport_size.x
	title.position = Vector2(0, ViewportManager.design_to_viewport(Vector2(0, 30)).y)
	add_child(title)

	# Pulse animation on title
	var title_tween := create_tween()
	title_tween.set_loops()
	title_tween.set_ease(Tween.EASE_IN_OUT)
	title_tween.set_trans(Tween.TRANS_SINE)
	title_tween.tween_property(title, "scale", Vector2(1.05, 1.05), 1.2)
	title_tween.tween_property(title, "scale", Vector2(1.0, 1.0), 1.2)

	# ---- Subtitle: "All Baby Axolotls Rescued!" ----
	var subtitle := Label.new()
	subtitle.text = "All Baby Axolotls Rescued!"
	subtitle.add_theme_font_size_override("font_size", int(22 * ui_scale))
	subtitle.add_theme_color_override("font_color", Color("ffaa00"))
	subtitle.add_theme_color_override("font_outline_color", Color("8b4513"))
	subtitle.add_theme_constant_override("outline_size", int(2 * ui_scale))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.size.x = ViewportManager.viewport_size.x
	subtitle.position = Vector2(0, ViewportManager.design_to_viewport(Vector2(0, 80)).y)
	add_child(subtitle)

	# ---- "Rescued Babies" label above parade ----
	var parade_label := Label.new()
	parade_label.text = "~ Rescued Babies ~"
	parade_label.add_theme_font_size_override("font_size", int(14 * ui_scale))
	parade_label.add_theme_color_override("font_color", Color("ff6b9d"))
	parade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parade_label.size.x = ViewportManager.viewport_size.x
	parade_label.position = Vector2(0, ViewportManager.design_to_viewport(Vector2(0, 115)).y)
	add_child(parade_label)

	# Baby axolotl parade (real sprites!)
	_create_baby_parade()

	# Xochi character (real sprite!)
	_create_xochi_celebration()

	# Stats section with background panel
	_create_stats()

	# Buttons
	_create_buttons()

	# Thank you message
	var thank_you := Label.new()
	thank_you.text = "Thank you for playing! Made with love for you!"
	thank_you.add_theme_font_size_override("font_size", int(14 * ui_scale))
	thank_you.add_theme_color_override("font_color", Color("aa8866"))
	thank_you.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thank_you.size.x = ViewportManager.viewport_size.x
	thank_you.position = Vector2(0, ViewportManager.design_to_viewport(Vector2(0, 570)).y)
	add_child(thank_you)


func _create_baby_parade() -> void:
	## Creates animated baby axolotl parade using real baby_axolotl.png sprites.
	## Babies march across the screen with bouncy walk animation, staggered entrance,
	## and slightly varied sizes.
	var ui_scale: float = ViewportManager.get_ui_scale()
	var baby_count: int = clampi(GameState.rescued_babies.size(), 1, 10)
	var baby_tex: Texture2D = load("res://assets/sprites/collectibles/baby_axolotl.png")

	# Parade Y position (design space y=170, centered in parade area)
	var parade_y: float = ViewportManager.design_to_viewport(Vector2(0, 175)).y

	# Calculate spacing so babies spread across most of the screen width
	var viewport_w: float = ViewportManager.viewport_size.x
	var total_parade_width: float = viewport_w * 0.6
	var spacing: float = total_parade_width / maxf(baby_count, 1)
	var start_x: float = (viewport_w - total_parade_width) / 2.0 + spacing / 2.0

	for i in range(baby_count):
		var baby := Sprite2D.new()
		baby.texture = baby_tex
		# Slightly random scale for variety (target ~40px tall at ui_scale 1.0)
		var base_scale: float = (40.0 * ui_scale) / baby_tex.get_height()
		var scale_variation: float = randf_range(0.85, 1.15)
		var final_scale: float = base_scale * scale_variation
		baby.scale = Vector2(final_scale, final_scale)

		# Alternate facing direction for some babies
		if randi() % 3 == 0:
			baby.scale.x = -baby.scale.x

		# Start off-screen to the left for staggered entrance
		baby.position = Vector2(-50 * ui_scale, parade_y)
		baby.modulate.a = 0.0  # Start invisible
		add_child(baby)
		baby_sprites.append(baby)

		# Target X position in the parade line
		var target_x: float = start_x + i * spacing

		# Staggered entrance: each baby slides in after a delay
		var entrance_delay: float = 0.3 + i * 0.25
		var entrance_tween := create_tween()
		entrance_tween.tween_interval(entrance_delay)
		entrance_tween.tween_property(baby, "modulate:a", 1.0, 0.3)
		entrance_tween.parallel().tween_property(baby, "position:x", target_x, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

		# Create a looping bounce + rotation after entrance completes
		var bounce_delay: float = entrance_delay + 0.8
		var bounce_tween := create_tween()
		bounce_tween.tween_interval(bounce_delay)
		bounce_tween.tween_callback(func():
			var loop_tween := create_tween()
			loop_tween.set_loops()
			loop_tween.set_ease(Tween.EASE_IN_OUT)
			loop_tween.set_trans(Tween.TRANS_SINE)
			# Bobbing up and down
			var bob_amount: float = randf_range(6, 12) * ui_scale
			var bob_speed: float = randf_range(0.35, 0.55)
			loop_tween.tween_property(baby, "position:y", parade_y - bob_amount, bob_speed)
			loop_tween.tween_property(baby, "position:y", parade_y, bob_speed)
			# Slight rotation wiggle (parallel)
			var rot_tween := create_tween()
			rot_tween.set_loops()
			rot_tween.set_ease(Tween.EASE_IN_OUT)
			rot_tween.set_trans(Tween.TRANS_SINE)
			var rot_amount: float = deg_to_rad(randf_range(5, 12))
			var rot_speed: float = randf_range(0.4, 0.7)
			rot_tween.tween_property(baby, "rotation", rot_amount, rot_speed)
			rot_tween.tween_property(baby, "rotation", -rot_amount, rot_speed)
			rot_tween.tween_property(baby, "rotation", 0.0, rot_speed * 0.5)
		)


func _create_xochi_celebration() -> void:
	## Creates the Xochi warrior celebration using the real walk sprite.
	## Features a gentle breathing/bobbing animation.
	var ui_scale: float = ViewportManager.get_ui_scale()
	var center_x: float = ViewportManager.viewport_size.x / 2.0
	var pos_y: float = ViewportManager.design_to_viewport(Vector2(0, 300)).y

	var xochi_tex: Texture2D = load("res://assets/sprites/player/xochi_walk.png")
	xochi_sprite = Sprite2D.new()
	xochi_sprite.texture = xochi_tex

	# Scale Xochi to be prominent but not overwhelming (~80px tall at ui_scale 1.0)
	var target_height: float = 80.0 * ui_scale
	var xochi_scale: float = target_height / xochi_tex.get_height()
	xochi_sprite.scale = Vector2(xochi_scale, xochi_scale)
	xochi_sprite.position = Vector2(center_x, pos_y)

	# Start with a dramatic entrance
	xochi_sprite.modulate.a = 0.0
	xochi_sprite.scale = Vector2(xochi_scale * 0.5, xochi_scale * 0.5)
	add_child(xochi_sprite)

	# Entrance animation
	var entrance := create_tween()
	entrance.set_ease(Tween.EASE_OUT)
	entrance.set_trans(Tween.TRANS_BACK)
	entrance.tween_interval(0.5)
	entrance.tween_property(xochi_sprite, "modulate:a", 1.0, 0.5)
	entrance.parallel().tween_property(xochi_sprite, "scale", Vector2(xochi_scale, xochi_scale), 0.6)

	# Breathing animation (gentle scale pulse) after entrance
	var breathe := create_tween()
	breathe.tween_interval(1.2)
	breathe.tween_callback(func():
		var loop := create_tween()
		loop.set_loops()
		loop.set_ease(Tween.EASE_IN_OUT)
		loop.set_trans(Tween.TRANS_SINE)
		var breathe_up: float = xochi_scale * 1.03
		var breathe_down: float = xochi_scale * 0.97
		loop.tween_property(xochi_sprite, "scale", Vector2(breathe_up, breathe_up), 1.5)
		loop.tween_property(xochi_sprite, "scale", Vector2(breathe_down, breathe_down), 1.5)
	)

	# Gentle hovering (slight vertical bob)
	var hover := create_tween()
	hover.tween_interval(1.2)
	hover.tween_callback(func():
		var loop := create_tween()
		loop.set_loops()
		loop.set_ease(Tween.EASE_IN_OUT)
		loop.set_trans(Tween.TRANS_SINE)
		loop.tween_property(xochi_sprite, "position:y", pos_y - 8 * ui_scale, 2.0)
		loop.tween_property(xochi_sprite, "position:y", pos_y + 4 * ui_scale, 2.0)
	)


func _create_stats() -> void:
	## Displays adventure statistics with a warm background panel.
	var ui_scale: float = ViewportManager.get_ui_scale()
	var center_x: float = ViewportManager.viewport_size.x / 2.0

	# Stats panel background (warm dark panel)
	var panel_width: float = 360 * ui_scale
	var panel_height: float = 140 * ui_scale
	var panel_y: float = ViewportManager.design_to_viewport(Vector2(0, 365)).y

	var panel_bg := ColorRect.new()
	panel_bg.color = Color(0.1, 0.08, 0.15, 0.7)
	panel_bg.size = Vector2(panel_width, panel_height)
	panel_bg.position = Vector2(center_x - panel_width / 2.0, panel_y)
	add_child(panel_bg)

	# Decorative border lines (top and bottom of panel, warm gold)
	var border_top := ColorRect.new()
	border_top.color = Color("ffaa00")
	border_top.size = Vector2(panel_width - 20 * ui_scale, 2 * ui_scale)
	border_top.position = Vector2(center_x - (panel_width - 20 * ui_scale) / 2.0, panel_y + 4 * ui_scale)
	add_child(border_top)

	var border_bottom := ColorRect.new()
	border_bottom.color = Color("ffaa00")
	border_bottom.size = Vector2(panel_width - 20 * ui_scale, 2 * ui_scale)
	border_bottom.position = Vector2(center_x - (panel_width - 20 * ui_scale) / 2.0, panel_y + panel_height - 6 * ui_scale)
	add_child(border_bottom)

	# Stats title
	var stats_title := Label.new()
	stats_title.text = "YOUR ADVENTURE"
	stats_title.add_theme_font_size_override("font_size", int(18 * ui_scale))
	stats_title.add_theme_color_override("font_color", Color("ffd700"))
	stats_title.add_theme_color_override("font_outline_color", Color("8b4513"))
	stats_title.add_theme_constant_override("outline_size", int(2 * ui_scale))
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_title.size.x = ViewportManager.viewport_size.x
	stats_title.position = Vector2(0, panel_y + 10 * ui_scale)
	add_child(stats_title)

	# Individual stats with warm colors
	var stats: Array[Dictionary] = [
		{"text": "Final Score: %d" % GameState.score, "color": Color("ffe66d")},
		{"text": "Stars Collected: %d/30" % GameState.stars.size(), "color": Color("ffaa00")},
		{"text": "Babies Rescued: %d/10" % GameState.rescued_babies.size(), "color": Color("ff6b9d")},
		{"text": "Difficulty: %s" % GameState.difficulty.capitalize(), "color": Color("4ecdc4")},
	]

	for i in range(stats.size()):
		var stat_label := Label.new()
		stat_label.text = stats[i]["text"]
		stat_label.add_theme_font_size_override("font_size", int(15 * ui_scale))
		stat_label.add_theme_color_override("font_color", stats[i]["color"])
		stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_label.size.x = ViewportManager.viewport_size.x
		stat_label.position = Vector2(0, panel_y + (35 + i * 24) * ui_scale)
		add_child(stat_label)


func _create_buttons() -> void:
	## Creates action buttons with warm Dia de los Muertos styling.
	var ui_scale: float = ViewportManager.get_ui_scale()

	# Play Again button
	play_again_button = _create_button(
		ViewportManager.design_to_viewport(Vector2(300, 540)),
		Vector2(160, 40) * ui_scale,
		Color("ffaa00"),
		"PLAY AGAIN",
		_on_play_again
	)

	# Main Menu button
	menu_button = _create_button(
		ViewportManager.design_to_viewport(Vector2(500, 540)),
		Vector2(160, 40) * ui_scale,
		Color("ff6b9d"),
		"MAIN MENU",
		_on_menu
	)


func _create_button(pos: Vector2, btn_size: Vector2, color: Color, text: String, callback: Callable) -> Button:
	## Creates a styled button with hover effect.
	var ui_scale: float = ViewportManager.get_ui_scale()

	# Background panel
	var bg := ColorRect.new()
	bg.color = color
	bg.size = btn_size
	bg.position = pos - btn_size / 2.0
	add_child(bg)

	# Subtle darker border/shadow
	var shadow := ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.25)
	shadow.size = Vector2(btn_size.x, 3 * ui_scale)
	shadow.position = Vector2(pos.x - btn_size.x / 2.0, pos.y + btn_size.y / 2.0 - 1)
	add_child(shadow)

	# Text label
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", int(16 * ui_scale))
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	label.add_theme_constant_override("outline_size", int(2 * ui_scale))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = btn_size
	label.position = pos - btn_size / 2.0
	add_child(label)

	# Interactive button (invisible, on top)
	var btn := Button.new()
	btn.flat = true
	btn.position = pos - btn_size / 2.0
	btn.custom_minimum_size = btn_size
	btn.pressed.connect(callback)
	btn.mouse_entered.connect(func():
		bg.color = color.lightened(0.2)
		bg.size = btn_size * 1.02
		bg.position = pos - bg.size / 2.0
	)
	btn.mouse_exited.connect(func():
		bg.color = color
		bg.size = btn_size
		bg.position = pos - btn_size / 2.0
	)
	add_child(btn)

	return btn


# ---- Callbacks ----

func _on_play_again() -> void:
	AudioManager.play_sfx("menu_select")

	# Reset game state
	GameState.reset_game()

	# Stop music
	AudioManager.stop_music()

	# Start from beginning with story
	SceneManager.change_scene("res://scenes/story/story_scene.tscn")


func _on_menu() -> void:
	AudioManager.play_sfx("menu_select")

	# Stop music
	AudioManager.stop_music()

	# Return to menu
	SceneManager.change_scene("res://scenes/menu/menu_scene.tscn")

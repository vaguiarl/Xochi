extends Control
## Pause overlay scene - port from PauseScene.js.
##
## Semi-transparent overlay that pauses gameplay and provides options to
## resume, restart, adjust settings, or quit to menu. Music is paused/resumed.

# UI References
var resume_button: Button
var restart_button: Button
var music_button: Button
var sfx_button: Button
var menu_button: Button

# State
var was_music_playing: bool = false


func _ready() -> void:
	# Semi-transparent dark overlay
	var overlay := ColorRect.new()
	overlay.color = Color.BLACK
	overlay.modulate.a = 0.7
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = -1
	add_child(overlay)

	# Pause the game tree
	get_tree().paused = true

	# Pause music
	if AudioManager.current_music and AudioManager.current_music.playing:
		was_music_playing = true
		AudioManager.current_music.stream_paused = true

	# Build UI
	_create_ui()


func _create_ui() -> void:
	var ui_scale := ViewportManager.get_ui_scale()

	# PAUSED title
	var title := Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", int(48 * ui_scale))
	title.add_theme_color_override("font_color", Color("4ecdc4"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = ViewportManager.design_to_viewport(Vector2(400, 100))
	add_child(title)

	# Controls section
	var controls_title := Label.new()
	controls_title.text = "CONTROLS"
	controls_title.add_theme_font_size_override("font_size", int(14 * ui_scale))
	controls_title.add_theme_color_override("font_color", Color("888888"))
	controls_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_title.position = ViewportManager.design_to_viewport(Vector2(400, 155))
	add_child(controls_title)

	var controls_text := Label.new()
	controls_text.text = "X = Jump    Z = Attack    XX = Super Jump"
	controls_text.add_theme_font_size_override("font_size", int(13 * ui_scale))
	controls_text.add_theme_color_override("font_color", Color.WHITE)
	controls_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_text.position = ViewportManager.design_to_viewport(Vector2(400, 180))
	add_child(controls_text)

	var controls_subtext := Label.new()
	controls_subtext.text = "Arrows = Move    SPACE = Run    ESC = Pause"
	controls_subtext.add_theme_font_size_override("font_size", int(11 * ui_scale))
	controls_subtext.add_theme_color_override("font_color", Color("aaaaaa"))
	controls_subtext.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_subtext.position = ViewportManager.design_to_viewport(Vector2(400, 200))
	add_child(controls_subtext)

	# Resume button
	resume_button = _create_button(
		ViewportManager.design_to_viewport(Vector2(400, 250)),
		Vector2(240, 44) * ui_scale,
		Color("4ecdc4"),
		"RESUME",
		_on_resume_pressed
	)

	# Restart button
	restart_button = _create_button(
		ViewportManager.design_to_viewport(Vector2(400, 310)),
		Vector2(240, 44) * ui_scale,
		Color("ffe66d"),
		"RESTART LEVEL",
		_on_restart_pressed
	)

	# Music toggle
	var music_text := "MUSIC: ON" if GameState.music_enabled else "MUSIC: OFF"
	music_button = _create_button(
		ViewportManager.design_to_viewport(Vector2(400, 370)),
		Vector2(240, 44) * ui_scale,
		Color("ff6b9d"),
		music_text,
		_on_music_toggle
	)

	# SFX toggle
	var sfx_text := "SFX: ON" if GameState.sfx_enabled else "SFX: OFF"
	sfx_button = _create_button(
		ViewportManager.design_to_viewport(Vector2(400, 430)),
		Vector2(240, 44) * ui_scale,
		Color("ff6b9d"),
		sfx_text,
		_on_sfx_toggle
	)

	# Main menu button
	menu_button = _create_button(
		ViewportManager.design_to_viewport(Vector2(400, 490)),
		Vector2(240, 44) * ui_scale,
		Color("ff6b6b"),
		"QUIT TO MENU",
		_on_menu_pressed
	)


func _create_button(pos: Vector2, size: Vector2, color: Color, text: String, callback: Callable) -> Button:
	## Creates a rounded button with hover effects.
	var ui_scale := ViewportManager.get_ui_scale()

	# Background
	var bg := ColorRect.new()
	bg.color = color
	bg.position = pos - size / 2
	bg.size = size
	add_child(bg)

	# Text label
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", int(20 * ui_scale))
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = pos - Vector2(size.x / 2, 10)
	add_child(label)

	# Interactive button overlay
	var btn := Button.new()
	btn.flat = true
	btn.position = pos - size / 2
	btn.custom_minimum_size = size
	btn.pressed.connect(callback)
	btn.mouse_entered.connect(func():
		btn.scale = Vector2(1.05, 1.05)
	)
	btn.mouse_exited.connect(func():
		btn.scale = Vector2.ONE
	)
	add_child(btn)

	# Store label reference for updates
	btn.set_meta("label", label)
	btn.set_meta("bg", bg)

	return btn


# ---- Callbacks ----

func _on_resume_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	_resume_game()


func _on_restart_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	get_tree().paused = false

	# Music keeps playing -- same world song loops uninterrupted through restarts.
	# play_for_level() in game_scene will see it's the same track and skip.

	# Reload current level
	SceneManager.change_scene("res://scenes/game/game_scene.tscn")


func _on_music_toggle() -> void:
	AudioManager.play_sfx("menu_select")
	GameState.music_enabled = not GameState.music_enabled
	GameState.save_game()

	# Update button text
	var label: Label = music_button.get_meta("label")
	label.text = "MUSIC: ON" if GameState.music_enabled else "MUSIC: OFF"

	# Toggle music playback
	if AudioManager.current_music:
		if GameState.music_enabled:
			AudioManager.current_music.stream_paused = false
		else:
			AudioManager.current_music.stream_paused = true


func _on_sfx_toggle() -> void:
	AudioManager.play_sfx("menu_select")
	GameState.sfx_enabled = not GameState.sfx_enabled
	GameState.save_game()

	# Update button text
	var label: Label = sfx_button.get_meta("label")
	label.text = "SFX: ON" if GameState.sfx_enabled else "SFX: OFF"


func _on_menu_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	get_tree().paused = false

	# Stop all audio
	AudioManager.stop_music()

	# Return to menu
	SceneManager.change_scene("res://scenes/menu/menu_scene.tscn")


func _resume_game() -> void:
	## Unpause the game and resume music.
	get_tree().paused = false

	# Resume music if it was playing
	if was_music_playing and AudioManager.current_music:
		AudioManager.current_music.stream_paused = false

	# Remove this overlay
	queue_free()


func _input(event: InputEvent) -> void:
	# ESC to resume
	if event.is_action_pressed("ui_cancel"):
		_resume_game()

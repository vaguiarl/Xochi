extends Control
## Story scene with typewriter effect - port from StoryScene.js.
##
## Displays narrative text with typewriter animation, Spanish subtitles,
## and decorative sparkles. Handles story segments for intro, world transitions,
## and ending sequences.

# UI References
var story_text: Label
var subtitle_text: Label
var continue_text: Label
var sparkles: Array[Node] = []

# State
var story_type: String = "intro"
var next_level: int = 1
var slides: Array[Dictionary] = []
var current_slide: int = 0
var typewriter_timer: Timer = null


func _ready() -> void:
	# Dark background
	RenderingServer.set_default_clear_color(Color("1a1a2e"))

	# Get story type from scene parameters
	# TODO: This will be passed via init() when called from SceneManager
	_create_ui()
	_load_story()
	_show_slide(0)


func init(data: Dictionary) -> void:
	## Initialize with story type and next level.
	story_type = data.get("type", "intro")
	next_level = data.get("next_level", 1)


func _create_ui() -> void:
	var ui_scale := ViewportManager.get_ui_scale()

	# Story text (will be filled by typewriter)
	story_text = Label.new()
	story_text.add_theme_font_size_override("font_size", int(28 * ui_scale))
	story_text.add_theme_color_override("font_color", Color("4ecdc4"))
	story_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	story_text.custom_minimum_size = Vector2(600 * ui_scale, 0)
	story_text.position = ViewportManager.design_to_viewport(Vector2(100, 250))
	add_child(story_text)

	# Subtitle text (Spanish translation)
	subtitle_text = Label.new()
	subtitle_text.add_theme_font_size_override("font_size", int(18 * ui_scale))
	subtitle_text.add_theme_color_override("font_color", Color("aaaaaa"))
	subtitle_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	subtitle_text.custom_minimum_size = Vector2(600 * ui_scale, 0)
	subtitle_text.position = ViewportManager.design_to_viewport(Vector2(100, 310))
	subtitle_text.modulate.a = 0.0
	add_child(subtitle_text)

	# Continue instruction
	continue_text = Label.new()
	continue_text.text = "Click or Press Space to Continue"
	continue_text.add_theme_font_size_override("font_size", int(16 * ui_scale))
	continue_text.add_theme_color_override("font_color", Color("888888"))
	continue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_text.position = ViewportManager.design_to_viewport(Vector2(400, 560))
	add_child(continue_text)

	# Create sparkle decorations (will be positioned around text)
	_create_sparkles()


func _create_sparkles() -> void:
	## Creates 8 sparkles in a circle around the text.
	var ui_scale := ViewportManager.get_ui_scale()
	var center := ViewportManager.design_to_viewport(Vector2(400, 280))
	var radius := 200 * ui_scale

	for i in range(8):
		var angle := (i / 8.0) * TAU
		var x := center.x + cos(angle) * radius
		var y := center.y + sin(angle) * radius

		var sparkle := ColorRect.new()
		sparkle.color = Color("4ecdc4")
		sparkle.size = Vector2(8, 8)
		sparkle.position = Vector2(x - 4, y - 4)
		sparkle.modulate.a = 0.6
		add_child(sparkle)
		sparkles.append(sparkle)

		# Twinkling animation
		var tween := create_tween()
		tween.set_loops()
		tween.tween_property(sparkle, "modulate:a", 0.2, 1.0)
		tween.parallel().tween_property(sparkle, "scale", Vector2(1.5, 1.5), 1.0)
		tween.tween_property(sparkle, "modulate:a", 0.6, 1.0)
		tween.parallel().tween_property(sparkle, "scale", Vector2.ONE, 1.0)
		tween.set_delay(i * 0.1)


func _load_story() -> void:
	## Loads story slides based on story type.
	match story_type:
		"intro":
			slides = _get_intro_story()
		"world2":
			slides = _get_world2_story()
		"world3":
			slides = _get_world3_story()
		"world4":
			slides = _get_world4_story()
		"world5":
			slides = _get_world5_story()
		"world6":
			slides = _get_world6_story()
		"ending":
			slides = _get_ending_story()
		_:
			slides = _get_intro_story()


func _get_intro_story() -> Array[Dictionary]:
	return [
		{
			"text": "In the magical waters of Xochimilco lived a happy little axolotl named Xochi...",
			"color": Color("4ecdc4"),
			"subtitle": "En las aguas magicas de Xochimilco..."
		},
		{
			"text": "Xochi loved swimming with her five baby axolotl friends through the floating gardens.",
			"color": Color("ff6b9d"),
			"subtitle": ""
		},
		{
			"text": "But one day, a terrible storm swept through the canals!",
			"color": Color("ff6b6b"),
			"subtitle": "Pero un dia, una terrible tormenta..."
		},
		{
			"text": "The wind scattered the baby axolotls across distant lands...",
			"color": Color("ffe66d"),
			"subtitle": ""
		},
		{
			"text": "Now Xochi must brave the Floating Gardens, Ancient Ruins, and Crystal Caves to rescue her friends!",
			"color": Color("4ecdc4"),
			"subtitle": ""
		},
		{
			"text": "Help Xochi on her adventure!",
			"color": Color("ff6b9d"),
			"subtitle": "¡Ayuda a Xochi en su aventura!",
			"is_last": true
		}
	]


func _get_world2_story() -> Array[Dictionary]:
	return [
		{
			"text": "Xochi found two of her friends! But there are more to rescue...",
			"color": Color("4ecdc4"),
			"subtitle": ""
		},
		{
			"text": "The ancient ruins hold more secrets... and more danger!",
			"color": Color("ffe66d"),
			"subtitle": ""
		},
		{
			"text": "Be brave, Xochi!",
			"color": Color("ff6b9d"),
			"subtitle": "",
			"is_last": true
		}
	]


func _get_world3_story() -> Array[Dictionary]:
	return [
		{
			"text": "Only one baby axolotl remains!",
			"color": Color("4ecdc4"),
			"subtitle": ""
		},
		{
			"text": "Deep in the Crystal Caves, a great challenge awaits...",
			"color": Color("ffe66d"),
			"subtitle": ""
		},
		{
			"text": "This is it, Xochi! Time to bring everyone home!",
			"color": Color("ff6b9d"),
			"subtitle": "",
			"is_last": true
		}
	]


func _get_world4_story() -> Array[Dictionary]:
	return [
		{
			"text": "The Floating Gardens... ancient chinampas stretch as far as the eye can see.",
			"color": Color("88cc66"),
			"subtitle": ""
		},
		{
			"text": "Los Jardines Flotantes guardan secretos ancestrales...",
			"color": Color("ff9955"),
			"subtitle": ""
		},
		{
			"text": "More friends need your help, Xochi! Keep going!",
			"color": Color("ff6b9d"),
			"subtitle": "",
			"is_last": true
		}
	]


func _get_world5_story() -> Array[Dictionary]:
	return [
		{
			"text": "Night falls over the canals of Xochimilco...",
			"color": Color("6677cc"),
			"subtitle": ""
		},
		{
			"text": "Los canales brillan bajo la luz de la luna.",
			"color": Color("ffcc66"),
			"subtitle": ""
		},
		{
			"text": "The darkest hour is before dawn. Stay brave!",
			"color": Color("4ecdc4"),
			"subtitle": "",
			"is_last": true
		}
	]


func _get_world6_story() -> Array[Dictionary]:
	return [
		{
			"text": "The Grand Festival awaits! La Gran Fiesta has begun!",
			"color": Color("FFD700"),
			"subtitle": ""
		},
		{
			"text": "¡La fiesta más grande de Xochimilco te espera!",
			"color": Color("FF69B4"),
			"subtitle": ""
		},
		{
			"text": "One last celebration... and one last friend to save!",
			"color": Color("4ecdc4"),
			"subtitle": "",
			"is_last": true
		}
	]


func _get_ending_story() -> Array[Dictionary]:
	return [
		{
			"text": "¡Lo lograste!",
			"color": Color("ffe66d"),
			"subtitle": "You did it!"
		},
		{
			"text": "All the baby axolotls are safe and sound!",
			"color": Color("4ecdc4"),
			"subtitle": "Todos los ajolotes bebé están sanos y salvos!"
		},
		{
			"text": "The friends swam together back to the magical waters of Xochimilco...",
			"color": Color("ff6b9d"),
			"subtitle": ""
		},
		{
			"text": "The canals glowed with celebration as the axolotls danced through the floating gardens.",
			"color": Color("4ecdc4"),
			"subtitle": ""
		},
		{
			"text": "And they all lived happily ever after!",
			"color": Color("ffe66d"),
			"subtitle": "¡Y vivieron felices para siempre!"
		},
		{
			"text": "THE END\n\n¡Gracias por jugar!\nThank you for playing!",
			"color": Color("ffe66d"),
			"subtitle": "",
			"is_last": true,
			"is_ending": true
		}
	]


func _show_slide(index: int) -> void:
	## Displays a slide with typewriter effect.
	if index >= slides.size():
		return

	var slide: Dictionary = slides[index]

	# Update sparkle colors
	for sparkle in sparkles:
		sparkle.color = slide["color"]

	# Reset text
	story_text.text = ""
	story_text.add_theme_color_override("font_color", slide["color"])
	subtitle_text.text = slide.get("subtitle", "")
	subtitle_text.modulate.a = 0.0

	# Start typewriter effect
	_start_typewriter(slide["text"])

	# Fade in subtitle after delay
	if slide.get("subtitle", "") != "":
		var subtitle_tween := create_tween()
		subtitle_tween.tween_interval(0.5)
		subtitle_tween.tween_property(subtitle_text, "modulate:a", 1.0, 0.8)


func _start_typewriter(full_text: String) -> void:
	## Animates text appearing character by character.
	if typewriter_timer:
		typewriter_timer.stop()
		typewriter_timer.queue_free()

	typewriter_timer = Timer.new()
	typewriter_timer.wait_time = 0.04
	typewriter_timer.one_shot = false
	add_child(typewriter_timer)

	var char_index := 0
	typewriter_timer.timeout.connect(func():
		char_index += 1
		story_text.text = full_text.substr(0, char_index)

		if char_index >= full_text.length():
			typewriter_timer.stop()
	)

	typewriter_timer.start()


func _next_slide() -> void:
	## Advances to next slide or finishes story.
	# Stop typewriter if still running
	if typewriter_timer and typewriter_timer.is_inside_tree():
		typewriter_timer.stop()
		typewriter_timer.queue_free()
		typewriter_timer = null

	current_slide += 1

	if current_slide >= slides.size():
		# Story finished
		_finish_story()
	else:
		# Transition to next slide with fade
		var fade_tween := create_tween()
		fade_tween.tween_property(story_text, "modulate:a", 0.0, 0.3)
		fade_tween.parallel().tween_property(subtitle_text, "modulate:a", 0.0, 0.3)
		fade_tween.tween_callback(func():
			story_text.modulate.a = 1.0
			_show_slide(current_slide)
		)


func _finish_story() -> void:
	## Completes the story and transitions to next scene.
	var last_slide: Dictionary = slides[slides.size() - 1]

	if last_slide.get("is_ending", false):
		# Go to EndScene
		SceneManager.change_scene("res://scenes/end/end_scene.tscn")
	else:
		# Go to GameScene with the next level
		SceneManager.change_scene("res://scenes/game/game_scene.tscn")


func _input(event: InputEvent) -> void:
	# Advance on click or space
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		_next_slide()

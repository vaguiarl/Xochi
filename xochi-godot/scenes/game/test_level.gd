extends Node2D
## Test level for tuning player feel.
##
## Layout:
##   - Two ground segments with a gap in between (for coyote time testing)
##   - Five elevated platforms at varying heights (for jump arc testing)
##   - A few collectible flower markers (visual only for now)
##   - HUD overlay with control instructions
##
## This level exists purely for development. It lets us feel the jump, tweak
## the coyote window, test variable jump height, and verify run speed without
## needing any game logic, enemies, or progression systems.


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.6, 0.8, 0.95))

	# Give player extra super jumps for testing
	GameState.super_jumps = 10

	# ---- Ground segments (with gap for coyote time testing) ----
	_create_platform(Vector2(400, 530), Vector2(1000, 40), Color(0.35, 0.55, 0.2))
	# Gap from x=900 to x=1000 (100px gap -- tight coyote test)
	_create_platform(Vector2(1300, 530), Vector2(600, 40), Color(0.35, 0.55, 0.2))
	# Second gap from x=1600 to x=1750 (150px gap -- wider coyote test)
	_create_platform(Vector2(2100, 530), Vector2(800, 40), Color(0.35, 0.55, 0.2))

	# ---- Elevated platforms at different heights ----
	# Low platform -- easy single jump
	_create_platform(Vector2(500, 400), Vector2(200, 20), Color(0.55, 0.35, 0.2))
	# Medium platform -- tests full jump height
	_create_platform(Vector2(800, 320), Vector2(150, 20), Color(0.55, 0.35, 0.2))
	# High platform -- requires run + full jump or precise arc
	_create_platform(Vector2(1100, 250), Vector2(180, 20), Color(0.55, 0.35, 0.2))
	# Staircase test -- two platforms close together
	_create_platform(Vector2(1500, 380), Vector2(160, 20), Color(0.55, 0.35, 0.2))
	_create_platform(Vector2(1800, 280), Vector2(140, 20), Color(0.55, 0.35, 0.2))

	# ---- Flower markers (visual only, for future collectible testing) ----
	_create_flower_marker(Vector2(600, 370))
	_create_flower_marker(Vector2(850, 290))
	_create_flower_marker(Vector2(1150, 220))
	_create_flower_marker(Vector2(1550, 350))
	_create_flower_marker(Vector2(1850, 250))

	# ---- Spawn player ----
	var player_scene: PackedScene = load("res://scenes/game/player.tscn")
	var player: CharacterBody2D = player_scene.instantiate()
	player.position = Vector2(200, 400)
	add_child(player)

	# ---- HUD instructions ----
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)

	var instructions := Label.new()
	instructions.text = "XOCHI TEST LEVEL -- Tune Player Feel\nA/D or Arrows: Move | SPACE: Run | X: Jump | X+X (double-tap): SUPER JUMP | Z: Attack"
	instructions.position = Vector2(10, 10)
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(instructions)

	var hint := Label.new()
	hint.text = "Gaps test coyote time | Platforms test jump height | Double-tap X in air for SUPER JUMP"
	hint.position = Vector2(10, 55)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	canvas.add_child(hint)

	# Super jump counter
	var sj_label := Label.new()
	sj_label.name = "SuperJumpLabel"
	sj_label.text = "Super Jumps: %d" % GameState.super_jumps
	sj_label.position = Vector2(10, 85)
	sj_label.add_theme_font_size_override("font_size", 14)
	sj_label.add_theme_color_override("font_color", Color("00ffff"))
	canvas.add_child(sj_label)

	# Debug info label (updated every frame)
	var debug_label := Label.new()
	debug_label.name = "DebugLabel"
	debug_label.position = Vector2(10, 560)
	debug_label.add_theme_font_size_override("font_size", 12)
	debug_label.add_theme_color_override("font_color", Color(1, 1, 0, 0.8))
	canvas.add_child(debug_label)


func _input(event: InputEvent) -> void:
	## Cheat codes for testing
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:  # Give super jumps
				GameState.super_jumps += 5
				print("💫 +5 Super Jumps! Total: ", GameState.super_jumps)
			KEY_F2:  # Give lives
				GameState.lives += 5
				print("❤️ +5 Lives! Total: ", GameState.lives)
			KEY_F3:  # Refill super jumps
				GameState.super_jumps = 10
				print("🔋 Refilled super jumps to 10")


func _process(_delta: float) -> void:
	# Update debug readout with player velocity and state
	var debug_label: Label = get_node_or_null("HUD/DebugLabel")
	var sj_label: Label = get_node_or_null("HUD/SuperJumpLabel")

	if sj_label:
		sj_label.text = "Super Jumps: %d" % GameState.super_jumps

	if debug_label == null:
		return
	var player = _find_player()
	if player:
		var on_floor_str: String = "GROUNDED" if player.is_on_floor() else "AIRBORNE"
		debug_label.text = "vel: (%.0f, %.0f) | %s | coyote: %.3f | facing: %s" % [
			player.velocity.x,
			player.velocity.y,
			on_floor_str,
			player.coyote_timer,
			"R" if player.facing_right else "L"
		]


func _find_player() -> CharacterBody2D:
	for child in get_children():
		if child is CharacterBody2D:
			return child
	return null


func _create_platform(pos: Vector2, size: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	# Platforms belong on the World collision layer (layer 1)
	body.collision_layer = 1

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)

	var visual := ColorRect.new()
	visual.size = size
	visual.position = -size / 2
	visual.color = color
	body.add_child(visual)

	add_child(body)


func _create_flower_marker(pos: Vector2) -> void:
	## Visual-only flower marker. A yellow-orange circle with a white center.
	## When the collectible system is built, these become real Area2D pickups.
	var marker := Node2D.new()
	marker.position = pos

	# Outer glow
	var outer := ColorRect.new()
	outer.size = Vector2(16, 16)
	outer.position = Vector2(-8, -8)
	outer.color = Color(1.0, 0.7, 0.1, 0.8)
	marker.add_child(outer)

	# Inner bright center
	var inner := ColorRect.new()
	inner.size = Vector2(8, 8)
	inner.position = Vector2(-4, -4)
	inner.color = Color(1.0, 1.0, 0.8, 1.0)
	marker.add_child(inner)

	add_child(marker)

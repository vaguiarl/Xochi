extends Node
class_name EnemySpawner
## Spawns enemies from level data into the enemies container node.
##
## Usage:
##   EnemySpawner.spawn_enemies(level_data, $Enemies)
##
## Level data format -- the "enemies" array should contain dictionaries:
##   { "type": "ground"|"platform"|"flying"|"water"|"jaguar"|"rabbit"|"calaca", "x": float, "y": float,
##     "dir": int, "speed": float,
##     "platform_left": float, "platform_right": float }
##
## Each enemy gets:
##   - Procedural placeholder visuals (colored rectangles)
##   - A CollisionShape2D sized to the enemy body
##   - Membership in the "enemies" group for easy lookup
##   - A "Visual" child node for directional flipping


# =============================================================================
# SPAWN ENTRY POINT
# =============================================================================

## Parse the "enemies" array from level_data and instantiate each enemy
## as a child of enemies_node.
static func spawn_enemies(level_data: Dictionary, enemies_node: Node2D):
	for enemy_data in level_data.get("enemies", []):
		var type = enemy_data.get("type", "ground")

		# --- Jaguar Warriors are standalone CharacterBody2D (not EnemyBase) ---
		# Loaded dynamically to prevent cascade failures.
		if type == "jaguar":
			var script = load("res://scripts/entities/jaguar_warrior.gd")
			if script == null:
				push_warning("EnemySpawner: failed to load jaguar_warrior.gd, skipping jaguar enemy")
				continue
			var jaguar: CharacterBody2D = script.new()
			jaguar.position = Vector2(enemy_data.x, enemy_data.y)
			jaguar.setup({
				"dir": enemy_data.get("dir", 1),
				"speed": enemy_data.get("speed", 45),
				"level_width": level_data.get("width", 3000)
			})
			jaguar.add_to_group("enemies")
			enemies_node.add_child(jaguar)
			continue

		# --- Rabbitbrije: basic goomba ground patrol (PNG sprite) ---
		# Loaded dynamically to prevent cascade failures.
		if type == "rabbit":
			var script = load("res://scripts/entities/rabbitbrije.gd")
			if script == null:
				push_warning("EnemySpawner: failed to load rabbitbrije.gd, skipping rabbit enemy")
				continue
			var rabbit: CharacterBody2D = script.new()
			rabbit.position = Vector2(enemy_data.x, enemy_data.y)
			rabbit.setup({
				"dir": enemy_data.get("dir", 1),
				"speed": enemy_data.get("speed", 50),
				"level_width": level_data.get("width", 3000)
			})
			rabbit.add_to_group("enemies")
			enemies_node.add_child(rabbit)
			continue

		# --- Calaca: floating sugar skull (PNG sprite) ---
		# Loaded dynamically to prevent cascade failures.
		if type == "calaca":
			var script = load("res://scripts/entities/calaca.gd")
			if script == null:
				push_warning("EnemySpawner: failed to load calaca.gd, skipping calaca enemy")
				continue
			var calaca: CharacterBody2D = script.new()
			calaca.position = Vector2(enemy_data.x, enemy_data.y)
			calaca.setup({
				"dir": enemy_data.get("dir", 1),
				"speed": enemy_data.get("speed", 60),
				"amplitude": enemy_data.get("amplitude", 30.0),
				"y": enemy_data.y,
				"level_width": level_data.get("width", 3000)
			})
			calaca.add_to_group("enemies")
			enemies_node.add_child(calaca)
			continue

		# --- Water enemies (Ahuizotl) are a separate class hierarchy ---
		# Loaded dynamically so a parse error in ahuizotl.gd only breaks
		# water enemies, not the entire spawner (which would hide ALL enemies).
		if type == "water":
			var script = load("res://scripts/entities/ahuizotl.gd")
			if script == null:
				push_warning("EnemySpawner: failed to load ahuizotl.gd, skipping water enemy")
				continue
			var ahuizotl: CharacterBody2D = script.new()
			ahuizotl.position = Vector2(enemy_data.x, enemy_data.y)
			ahuizotl.setup({
				"dir": enemy_data.get("dir", 1),
				"speed": enemy_data.get("speed", 70),
				"water_y": enemy_data.get("y", enemy_data.y),
				"level_width": level_data.get("width", 800)
			})
			ahuizotl.add_to_group("enemies")
			enemies_node.add_child(ahuizotl)
			continue

		var enemy: EnemyBase

		if type == "flying":
			enemy = Crowquistador.new()
			enemy.position = Vector2(enemy_data.x, enemy_data.y)
			enemy.setup({
				"dir": enemy_data.get("dir", 1),
				"speed": enemy_data.get("speed", 80),
				"y": enemy_data.y,
				"amplitude": enemy_data.get("amplitude", 40.0),
				"level_width": level_data.get("width", 2000)
			})

		elif type == "platform":
			enemy = Gull.new()
			enemy.position = Vector2(enemy_data.x, enemy_data.y)
			enemy.setup({
				"type": "platform",
				"dir": enemy_data.get("dir", 1),
				"platform_left": enemy_data.get("platform_left", enemy_data.x - 60),
				"platform_right": enemy_data.get("platform_right", enemy_data.x + 60)
			})

		else:
			# Default: ground gull
			enemy = Gull.new()
			enemy.position = Vector2(enemy_data.x, enemy_data.y)
			enemy.setup({
				"type": "ground",
				"dir": enemy_data.get("dir", 1)
			})

		# --- Procedural placeholder visuals (only for gull enemies) ---
		# Flying/water/jaguar enemies create their own visual rigs
		if type != "flying":
			var visual = Node2D.new()
			visual.name = "Visual"

			# Gull body (rounded white bird shape)
			var body = ColorRect.new()
			body.size = Vector2(20, 16)
			body.position = Vector2(-10, -8)
			body.color = Color(0.95, 0.95, 0.9)  # White
			visual.add_child(body)

			# Body shadow/bottom
			var shadow = ColorRect.new()
			shadow.size = Vector2(16, 4)
			shadow.position = Vector2(-8, 4)
			shadow.color = Color(0.7, 0.7, 0.65)  # Gray shadow
			visual.add_child(shadow)

			# Wing accent
			var wing = ColorRect.new()
			wing.size = Vector2(12, 6)
			wing.position = Vector2(-10, -4)
			wing.color = Color(0.8, 0.8, 0.75)  # Light gray
			visual.add_child(wing)

			# Orange beak
			var beak = ColorRect.new()
			beak.size = Vector2(6, 4)
			beak.position = Vector2(10, -2)
			beak.color = Color(1.0, 0.5, 0.0)  # Orange
			visual.add_child(beak)

			# Eye dot
			var eye = ColorRect.new()
			eye.size = Vector2(2, 2)
			eye.position = Vector2(6, -3)
			eye.color = Color(0.0, 0.0, 0.0)  # Black
			visual.add_child(eye)

			enemy.add_child(visual)

			# --- Collision shape ---
			var collision = CollisionShape2D.new()
			var shape = RectangleShape2D.new()
			shape.size = Vector2(20, 14)
			collision.shape = shape
			enemy.add_child(collision)

		# --- Group membership for combat system lookups ---
		enemy.add_to_group("enemies")

		enemies_node.add_child(enemy)

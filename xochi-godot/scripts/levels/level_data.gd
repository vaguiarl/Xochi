class_name LevelData
extends RefCounted
## Complete level data system -- exact port from original game.js LevelData.js,
## BossArenaGenerator.js, UpscrollerGenerator.js, EscapeGenerator.js.
## Static class: call LevelData.get_level_data(level_num) to get a Dictionary
## ready for the GameScene to instantiate.

# ===========================================================================
# Trajinera Names and Colors (original LevelData.js lines 129-134)
# ===========================================================================

const TRAJINERA_NAMES: Array[String] = [
	"La Lupita", "El Sol", "Frida", "La Estrella", "Amor Eterno",
	"La Rosa", "El Mariachi", "Corazon", "La Luna", "Esperanza",
	"Alegria", "Mi Cielo", "La Paloma", "El Jardin", "Dulce Maria",
	"La Sirena", "El Azteca", "Mariposa", "La Catrina", "Xochitl"
]

const TRAJINERA_COLORS: Array[Color] = [
	Color("ff6b6b"), Color("4ecdc4"), Color("ffe66d"), Color("c44569"), Color("f78fb3"),
	Color("3dc1d3"), Color("f5cd79"), Color("778beb"), Color("63cdda"), Color("e77f67")
]

# ===========================================================================
# Escape flood speeds (from constants.js lines 37-38)
# ===========================================================================

const ESCAPE_FLOOD_SPEED_BASE: float = 120.0
const ESCAPE_FLOOD_SPEED_FAST: float = 150.0

# ===========================================================================
# TILE_SIZE constant (from LevelData.js line 8)
# ===========================================================================

const TILE_SIZE: int = 32


# ===========================================================================
# Main Entry Point -- routes to the correct generator (original getLevelData
# and GameScene.init lines 27-33)
# ===========================================================================

static func get_level_data(level_num: int) -> Dictionary:
	## All 11 levels are handcrafted. No procedural generation.
	var static_levels := _get_static_levels()
	var index: int = clampi(level_num - 1, 0, static_levels.size() - 1)
	var data: Dictionary = static_levels[index]
	data = _enrich_level_data(data, level_num)
	return data


# ===========================================================================
# Helper: Enrich static level data with computed fields
# ===========================================================================

static func _enrich_level_data(data: Dictionary, level_num: int) -> Dictionary:
	## Add theme, flags, and water_y to a static level dictionary.
	var world_num := _get_world_for_level(level_num)
	if not data.has("theme"):
		data["theme"] = _get_world_theme(world_num)
	if not data.has("water_y"):
		# WATER WORLD: water covers bottom ~20% of level height by default
		data["water_y"] = data["height"] * 0.80
	if not data.has("is_boss_level"):
		data["is_boss_level"] = (level_num == 5 or level_num == 10)
	if not data.has("is_upscroller"):
		data["is_upscroller"] = (level_num == 3 or level_num == 8)
	if not data.has("is_escape"):
		data["is_escape"] = (level_num == 7 or level_num == 9)
	if not data.has("is_fiesta"):
		data["is_fiesta"] = (level_num == 11)
	return data


# ===========================================================================
# World/theme helper (mirrors GameState.get_world_for_level)
# ===========================================================================

static func _get_world_for_level(level_num: int) -> int:
	if level_num <= 2: return 1
	if level_num <= 4: return 2
	if level_num == 5: return 3
	if level_num <= 7: return 4
	if level_num <= 9: return 5
	return 6


static func _get_world_theme(world_num: int) -> Dictionary:
	## Return the WORLDS palette from GameState. Falls back to a minimal dict
	## if GameState is not yet available (e.g. during tests).
	if Engine.has_singleton("GameState"):
		var gs = Engine.get_singleton("GameState")
		if gs.WORLDS.has(world_num):
			return gs.WORLDS[world_num]
	# Fallback: return a minimal placeholder so the generator never crashes.
	return {"name": "Unknown", "world_num": world_num}


# ===========================================================================
# Density Multipliers (original LevelData.js lines 560-565)
# ===========================================================================

static func calculate_density_multipliers(level_num: int) -> Dictionary:
	## Returns { enemies, platforms, coins } scaling factors for the given level.
	if level_num <= 2:
		return { "enemies": 0.7, "platforms": 1.2, "coins": 1.0 }
	if level_num <= 5:
		return { "enemies": 1.0, "platforms": 1.0, "coins": 1.2 }
	if level_num <= 8:
		return { "enemies": 1.15, "platforms": 0.9, "coins": 1.3 }
	return { "enemies": 1.15, "platforms": 0.85, "coins": 1.5 }


# ===========================================================================
# Breathing Zones (original LevelData.js lines 568-575)
# ===========================================================================

static func get_breathing_zones(level_width: float, level_num: int) -> Array:
	## Returns Array of { start_x, end_x } safe zones where NO enemies spawn.
	var spacing: float
	if level_num <= 2:
		spacing = 400.0
	elif level_num <= 5:
		spacing = 600.0
	elif level_num <= 8:
		spacing = 850.0
	else:
		spacing = 900.0

	var zones: Array = []
	var center_x: float = 300.0 + spacing
	while center_x < level_width - 300.0:
		zones.append({ "start_x": center_x - 100.0, "end_x": center_x + 100.0 })
		center_x += spacing
	return zones


# ===========================================================================
# Random trajinera name & color helpers
# ===========================================================================

static func _random_trajinera_name() -> String:
	return TRAJINERA_NAMES[randi() % TRAJINERA_NAMES.size()]


static func _random_trajinera_color() -> Color:
	return TRAJINERA_COLORS[randi() % TRAJINERA_COLORS.size()]


# ===========================================================================
# Intro / Outro Section Helpers
# ===========================================================================

static func create_intro_section(level_num: int, water_y: float) -> Dictionary:
	## Returns { platforms, coins, powerups } for the first ~300px of a side-scroller.
	var platforms: Array = []
	var coins: Array = []
	var powerups: Array = []

	# Starting chinampa -- floating garden, not solid ground (WATER WORLD)
	platforms.append({ "x": 50.0, "y": water_y - 20.0, "w": 160.0, "h": 25.0, "is_chinampa": true })

	# Small welcome chinampa
	platforms.append({ "x": 200.0, "y": water_y - 80.0, "w": 120.0, "h": 20.0, "is_chinampa": true })

	# 5-coin intro arc (original level1 pattern)
	for i in range(5):
		var arc_y: float = water_y - 100.0 - sin((float(i) / 4.0) * PI) * 60.0
		coins.append(Vector2(120.0 + i * 30.0, arc_y))

	# Starting powerup for levels 3+
	if level_num >= 3:
		powerups.append(Vector2(150.0, water_y - 120.0))

	return { "platforms": platforms, "coins": coins, "powerups": powerups }


static func create_outro_section(level_num: int, level_width: float, water_y: float) -> Dictionary:
	## Returns { platforms, coins, baby_position } for the last ~300px.
	var platforms: Array = []
	var coins: Array = []

	# Landing chinampa near end (WATER WORLD -- no solid ground)
	platforms.append({
		"x": level_width - 300.0, "y": water_y - 20.0,
		"w": 180.0, "h": 25.0, "is_chinampa": true
	})

	# Elevated baby platform
	platforms.append({
		"x": level_width - 250.0, "y": water_y - 180.0,
		"w": 200.0, "h": 20.0, "is_chinampa": true
	})

	# Arrow pattern pointing to baby (from original level2)
	var arrow_base_x: float = level_width - 350.0
	for i in range(5):
		coins.append(Vector2(arrow_base_x + i * 30.0, water_y - 140.0 - i * 10.0))

	var baby_pos := Vector2(level_width - 150.0, water_y - 220.0)

	return { "platforms": platforms, "coins": coins, "baby_position": baby_pos }


# ===========================================================================
# STATIC HAND-CRAFTED LEVELS 1-6
# (Exact port from original LevelData.js level1 through level6)
# ===========================================================================

static func _get_static_levels() -> Array:
	return [
		_level_1_data(),
		_level_2_data(),
		_level_3_data(),
		_level_4_data(),
		_level_5_data(),
		_level_6_data(),
		_level_7_data(),
		_level_8_data(),
		_level_9_data(),
		_level_10_data(),
		_level_11_data(),
	]


# ---------------------------------------------------------------------------
# Level 1: Floating Gardens Tutorial (original lines 137-202)
# ---------------------------------------------------------------------------

static func _level_1_data() -> Dictionary:
	return {
		"width": 2400.0,
		"height": 600.0,
		"player_spawn": Vector2(100, 470),  # On starting chinampa (y=500, spawn 30px above)
		"baby_position": Vector2(2200, 220),  # Reachable on goal platform
		"water_y": 490.0,  # WATER WORLD: water covers bottom ~18% of 600px level

		"platforms": [
			# Starting island only - rest is water and trajineras!
			{ "x": 50.0, "y": 500.0, "w": 150.0, "h": 30.0, "is_chinampa": true },
			# Mid-level rest stops
			{ "x": 1100.0, "y": 420.0, "w": 120.0, "h": 25.0, "is_chinampa": true },
			{ "x": 1950.0, "y": 320.0, "w": 130.0, "h": 25.0, "is_chinampa": true },
			# Goal platform near baby
			{ "x": 2200.0, "y": 250.0, "w": 140.0, "h": 30.0, "is_chinampa": true },
		],

		"trajineras": [
			# Lane 1 (high) - alternating directions
			{ "x": 300.0, "y": 480.0, "w": 100.0, "h": 25.0, "speed": 35.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 300.0, "lane": 0, "texture_idx": 0 },
			{ "x": 600.0, "y": 480.0, "w": 95.0, "h": 25.0, "speed": 40.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 600.0, "lane": 1, "texture_idx": 1 },
			{ "x": 900.0, "y": 480.0, "w": 100.0, "h": 25.0, "speed": 35.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 900.0, "lane": 2, "texture_idx": 2 },
			{ "x": 1200.0, "y": 480.0, "w": 95.0, "h": 25.0, "speed": 38.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1200.0, "lane": 3, "texture_idx": 0 },

			# Lane 2 (mid-high) - opposite pattern
			{ "x": 450.0, "y": 420.0, "w": 100.0, "h": 25.0, "speed": 42.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 450.0, "lane": 4, "texture_idx": 1 },
			{ "x": 750.0, "y": 420.0, "w": 105.0, "h": 25.0, "speed": 36.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 750.0, "lane": 5, "texture_idx": 2 },
			{ "x": 1050.0, "y": 420.0, "w": 95.0, "h": 25.0, "speed": 40.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1050.0, "lane": 6, "texture_idx": 0 },
			{ "x": 1350.0, "y": 420.0, "w": 100.0, "h": 25.0, "speed": 34.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1350.0, "lane": 7, "texture_idx": 1 },

			# Lane 3 (mid) - fast chaos
			{ "x": 350.0, "y": 360.0, "w": 100.0, "h": 25.0, "speed": 45.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 350.0, "lane": 8, "texture_idx": 2 },
			{ "x": 650.0, "y": 360.0, "w": 95.0, "h": 25.0, "speed": 48.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 650.0, "lane": 9, "texture_idx": 0 },
			{ "x": 950.0, "y": 360.0, "w": 100.0, "h": 25.0, "speed": 44.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 950.0, "lane": 10, "texture_idx": 1 },
			{ "x": 1250.0, "y": 360.0, "w": 105.0, "h": 25.0, "speed": 46.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1250.0, "lane": 11, "texture_idx": 2 },

			# Lane 4 (low-mid) - dense traffic
			{ "x": 500.0, "y": 300.0, "w": 95.0, "h": 25.0, "speed": 50.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 500.0, "lane": 12, "texture_idx": 0 },
			{ "x": 800.0, "y": 300.0, "w": 100.0, "h": 25.0, "speed": 40.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 800.0, "lane": 13, "texture_idx": 1 },
			{ "x": 1100.0, "y": 300.0, "w": 95.0, "h": 25.0, "speed": 52.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1100.0, "lane": 14, "texture_idx": 2 },
			{ "x": 1400.0, "y": 300.0, "w": 100.0, "h": 25.0, "speed": 42.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1400.0, "lane": 15, "texture_idx": 0 },

			# Lane 5 (final stretch) - reaching the baby
			{ "x": 1650.0, "y": 340.0, "w": 100.0, "h": 25.0, "speed": 38.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1650.0, "lane": 16, "texture_idx": 1 },
			{ "x": 1900.0, "y": 340.0, "w": 95.0, "h": 25.0, "speed": 44.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1900.0, "lane": 17, "texture_idx": 2 },
			{ "x": 2150.0, "y": 280.0, "w": 100.0, "h": 25.0, "speed": 35.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2150.0, "lane": 18, "texture_idx": 0 },
		],

		"coins": [
			# Intro 5-coin arc
			Vector2(120, 500), Vector2(150, 480), Vector2(180, 470), Vector2(210, 480), Vector2(240, 500),
			# Platforming path coins
			Vector2(200, 480), Vector2(232, 480), Vector2(264, 480),
			Vector2(320, 420), Vector2(352, 420),
			Vector2(560, 340), Vector2(592, 340),
			Vector2(800, 280),
			# Coins over first gap
			Vector2(840, 490), Vector2(860, 470), Vector2(880, 490),
			Vector2(1150, 360), Vector2(1182, 360),
			Vector2(1450, 280),
			# Coins along trajinera path
			Vector2(1100, 440), Vector2(1550, 370),
			Vector2(1750, 340), Vector2(1782, 340),
			Vector2(2000, 240), Vector2(2032, 240),
			Vector2(2200, 190),  # FIXED: Reachable on goal platform
		],

		"stars": [
			Vector2(350, 350),
			Vector2(1150, 250),
			Vector2(2100, 290),  # FIXED: Reachable on final trajinera lane
		],

		"powerups": [
			# Super jumps everywhere - you'll need them!
			Vector2(400, 450),
			Vector2(700, 390),
			Vector2(1000, 330),
			Vector2(850, 280),
			Vector2(550, 270),
			Vector2(1150, 270),
			Vector2(1500, 310),
			Vector2(1800, 310),
			Vector2(2000, 240),  # FIXED: Better positioned for collection
		],

		"enemies": [
			# Flying Crowquistadors
			{ "x": 900.0, "y": 400.0, "type": "flying", "speed": 60.0, "dir": 1, "amplitude": 50.0 },
			{ "x": 1600.0, "y": 350.0, "type": "flying", "speed": 55.0, "dir": 1, "amplitude": 40.0 },
			{ "x": 1300.0, "y": 300.0, "type": "flying", "speed": 50.0, "dir": -1, "amplitude": 45.0 },
			# Rabbitbrijes on chinampa rest stops
			{ "x": 1130.0, "y": 395.0, "type": "rabbit", "speed": 40.0, "dir": 1 },
			{ "x": 1990.0, "y": 295.0, "type": "rabbit", "speed": 45.0, "dir": -1 },
		],

		"is_boss_level": false,
		"is_upscroller": false,
		"is_escape": false,
		"is_fiesta": false,
	}


# ---------------------------------------------------------------------------
# Level 2: Floating Gardens Advanced (original lines 205-279)
# ---------------------------------------------------------------------------

static func _level_2_data() -> Dictionary:
	return {
		"width": 3200.0,
		"height": 600.0,
		"player_spawn": Vector2(100, 470),  # On starting chinampa (y=500, spawn 30px above)
		"baby_position": Vector2(3050, 180),
		"water_y": 490.0,  # WATER WORLD: water covers bottom ~18% of 600px level

		"platforms": [
			# Start island
			{ "x": 50.0, "y": 500.0, "w": 150.0, "h": 30.0, "is_chinampa": true },
			# Mid-level rest stops (3 islands for breaks)
			{ "x": 800.0, "y": 420.0, "w": 130.0, "h": 25.0, "is_chinampa": true },
			{ "x": 1600.0, "y": 380.0, "w": 140.0, "h": 25.0, "is_chinampa": true },
			{ "x": 2400.0, "y": 350.0, "w": 130.0, "h": 25.0, "is_chinampa": true },
			# Goal platform
			{ "x": 3000.0, "y": 220.0, "w": 150.0, "h": 30.0, "is_chinampa": true },
		],

		"trajineras": [
			# LANE 1 (y=490) - 8 boats, entry lane
			{ "x": 300.0, "y": 490.0, "w": 100.0, "h": 25.0, "speed": 40.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 300.0, "lane": 0, "texture_idx": 0 },
			{ "x": 650.0, "y": 490.0, "w": 95.0, "h": 25.0, "speed": 42.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 650.0, "lane": 1, "texture_idx": 1 },
			{ "x": 1000.0, "y": 490.0, "w": 100.0, "h": 25.0, "speed": 38.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1000.0, "lane": 2, "texture_idx": 2 },
			{ "x": 1350.0, "y": 490.0, "w": 95.0, "h": 25.0, "speed": 44.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1350.0, "lane": 3, "texture_idx": 0 },
			{ "x": 1700.0, "y": 490.0, "w": 100.0, "h": 25.0, "speed": 40.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1700.0, "lane": 4, "texture_idx": 1 },
			{ "x": 2050.0, "y": 490.0, "w": 95.0, "h": 25.0, "speed": 46.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2050.0, "lane": 5, "texture_idx": 2 },
			{ "x": 2400.0, "y": 490.0, "w": 100.0, "h": 25.0, "speed": 39.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2400.0, "lane": 6, "texture_idx": 0 },
			{ "x": 2750.0, "y": 490.0, "w": 95.0, "h": 25.0, "speed": 48.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2750.0, "lane": 7, "texture_idx": 1 },

			# LANE 2 (y=430) - 8 boats, mid-high
			{ "x": 400.0, "y": 430.0, "w": 100.0, "h": 25.0, "speed": 50.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 400.0, "lane": 8, "texture_idx": 2 },
			{ "x": 750.0, "y": 430.0, "w": 100.0, "h": 25.0, "speed": 35.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 750.0, "lane": 9, "texture_idx": 0 },
			{ "x": 1100.0, "y": 430.0, "w": 95.0, "h": 25.0, "speed": 52.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1100.0, "lane": 10, "texture_idx": 1 },
			{ "x": 1450.0, "y": 430.0, "w": 100.0, "h": 25.0, "speed": 40.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1450.0, "lane": 11, "texture_idx": 2 },
			{ "x": 1800.0, "y": 430.0, "w": 95.0, "h": 25.0, "speed": 48.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1800.0, "lane": 12, "texture_idx": 0 },
			{ "x": 2150.0, "y": 430.0, "w": 100.0, "h": 25.0, "speed": 36.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2150.0, "lane": 13, "texture_idx": 1 },
			{ "x": 2500.0, "y": 430.0, "w": 95.0, "h": 25.0, "speed": 50.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2500.0, "lane": 14, "texture_idx": 2 },
			{ "x": 2850.0, "y": 430.0, "w": 100.0, "h": 25.0, "speed": 42.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2850.0, "lane": 15, "texture_idx": 0 },

			# LANE 3 (y=360) - 7 boats, fast chaos
			{ "x": 500.0, "y": 360.0, "w": 100.0, "h": 25.0, "speed": 55.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 500.0, "lane": 16, "texture_idx": 1 },
			{ "x": 900.0, "y": 360.0, "w": 95.0, "h": 25.0, "speed": 48.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 900.0, "lane": 17, "texture_idx": 2 },
			{ "x": 1300.0, "y": 360.0, "w": 100.0, "h": 25.0, "speed": 52.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1300.0, "lane": 18, "texture_idx": 0 },
			{ "x": 1700.0, "y": 360.0, "w": 95.0, "h": 25.0, "speed": 50.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1700.0, "lane": 19, "texture_idx": 1 },
			{ "x": 2100.0, "y": 360.0, "w": 100.0, "h": 25.0, "speed": 54.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2100.0, "lane": 20, "texture_idx": 2 },
			{ "x": 2500.0, "y": 360.0, "w": 95.0, "h": 25.0, "speed": 46.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2500.0, "lane": 21, "texture_idx": 0 },
			{ "x": 2900.0, "y": 360.0, "w": 100.0, "h": 25.0, "speed": 51.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2900.0, "lane": 22, "texture_idx": 1 },
		],

		"coins": [
			# Intro arc
			Vector2(120, 480), Vector2(150, 460), Vector2(180, 450), Vector2(210, 460), Vector2(240, 480),
			# Guidance through lanes
			Vector2(340, 490), Vector2(380, 490),
			Vector2(620, 430), Vector2(660, 430),
			Vector2(950, 360), Vector2(990, 360),
			Vector2(1250, 340),
			# Mid-section
			Vector2(1100, 440), Vector2(1550, 400),
			Vector2(1700, 420), Vector2(1800, 360),
			Vector2(2050, 330), Vector2(2150, 450),
			Vector2(2400, 360), Vector2(2500, 420),
			# Endgame
			Vector2(2750, 380), Vector2(2850, 440),
			Vector2(3000, 220), Vector2(3050, 180),
		],

		"stars": [
			Vector2(600, 360),
			Vector2(1500, 300),
			Vector2(2700, 320),
		],

		"powerups": [
			Vector2(350, 480),
			Vector2(650, 420),
			Vector2(950, 350),
			Vector2(1350, 400),
			Vector2(1650, 360),
			Vector2(1950, 430),
			Vector2(2350, 370),
			Vector2(2700, 440),
			Vector2(2950, 240),
		],

		"enemies": [
			# Flying Crowquistadors
			{ "x": 800.0, "y": 400.0, "type": "flying", "speed": 65.0, "dir": 1, "amplitude": 60.0 },
			{ "x": 1400.0, "y": 350.0, "type": "flying", "speed": 70.0, "dir": -1, "amplitude": 50.0 },
			{ "x": 2000.0, "y": 380.0, "type": "flying", "speed": 68.0, "dir": 1, "amplitude": 55.0 },
			{ "x": 2600.0, "y": 320.0, "type": "flying", "speed": 75.0, "dir": -1, "amplitude": 65.0 },
			{ "x": 3000.0, "y": 300.0, "type": "flying", "speed": 60.0, "dir": 1, "amplitude": 70.0 },
			# Rabbitbrijes on chinampa rest islands
			{ "x": 830.0, "y": 395.0, "type": "rabbit", "speed": 40.0, "dir": -1 },
			{ "x": 2430.0, "y": 325.0, "type": "rabbit", "speed": 50.0, "dir": 1 },
		],

		"is_boss_level": false,
		"is_upscroller": false,
		"is_escape": false,
		"is_fiesta": false,
	}


# ---------------------------------------------------------------------------
# Level 3: Upscroller Challenge (original lines 282-357)
# ---------------------------------------------------------------------------



# ---------------------------------------------------------------------------
# Level 3: Upscroller - Ruins Entry (original lines 282-353)
# ---------------------------------------------------------------------------

static func _level_3_data() -> Dictionary:
	return {
		"width": 800.0,
		"height": 2000.0,
		"player_spawn": Vector2(350, 1900),  # On starting chinampa (y=1930, spawn 30px above)
		"baby_position": Vector2(400, 70),
		"water_y": 1980.0,  # WATER WORLD: rising water starts just below starting chinampas

		"platforms": [
			# Starting chinampas -- floating gardens at the water surface, no solid ground
			{ "x": 250.0, "y": 1930.0, "w": 200.0, "h": 25.0, "is_chinampa": true },
			{ "x": 500.0, "y": 1940.0, "w": 150.0, "h": 25.0, "is_chinampa": true },
			# Ascending platforms - cleaner spacing for better flow
			{ "x": 100.0, "y": 1800.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 500.0, "y": 1700.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 200.0, "y": 1600.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 550.0, "y": 1500.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 100.0, "y": 1400.0, "w": 200.0, "h": 20.0, "is_chinampa": true },
			{ "x": 450.0, "y": 1300.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 200.0, "y": 1200.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 550.0, "y": 1100.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 100.0, "y": 1000.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 400.0, "y": 900.0, "w": 200.0, "h": 20.0, "is_chinampa": true },
			{ "x": 150.0, "y": 800.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 500.0, "y": 700.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 200.0, "y": 600.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 450.0, "y": 500.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 100.0, "y": 400.0, "w": 200.0, "h": 20.0, "is_chinampa": true },
			{ "x": 450.0, "y": 300.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 250.0, "y": 200.0, "w": 300.0, "h": 20.0, "is_chinampa": true },
			{ "x": 300.0, "y": 100.0, "w": 200.0, "h": 20.0, "is_chinampa": true },
		],

		"trajineras": [
			# Horizontal rescue trajineras -- moving platforms between static chinampas
			# These give the player something to land on while the water rises

			# Low section (y=1850-1550)
			{ "x": 300.0, "y": 1850.0, "w": 100.0, "h": 25.0, "speed": 45.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 300.0, "lane": 0, "texture_idx": 0 },
			{ "x": 600.0, "y": 1750.0, "w": 95.0, "h": 25.0, "speed": 50.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 600.0, "lane": 1, "texture_idx": 1 },
			{ "x": 200.0, "y": 1650.0, "w": 100.0, "h": 25.0, "speed": 42.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 200.0, "lane": 2, "texture_idx": 2 },
			{ "x": 500.0, "y": 1550.0, "w": 95.0, "h": 25.0, "speed": 48.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 500.0, "lane": 3, "texture_idx": 0 },

			# Mid section (y=1450-1150)
			{ "x": 350.0, "y": 1450.0, "w": 100.0, "h": 25.0, "speed": 55.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 350.0, "lane": 4, "texture_idx": 1 },
			{ "x": 150.0, "y": 1350.0, "w": 95.0, "h": 25.0, "speed": 50.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 150.0, "lane": 5, "texture_idx": 2 },
			{ "x": 600.0, "y": 1250.0, "w": 100.0, "h": 25.0, "speed": 52.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 600.0, "lane": 6, "texture_idx": 0 },
			{ "x": 400.0, "y": 1150.0, "w": 95.0, "h": 25.0, "speed": 46.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 400.0, "lane": 7, "texture_idx": 1 },

			# Upper section (y=1050-750)
			{ "x": 250.0, "y": 1050.0, "w": 100.0, "h": 25.0, "speed": 58.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 250.0, "lane": 8, "texture_idx": 2 },
			{ "x": 550.0, "y": 950.0, "w": 95.0, "h": 25.0, "speed": 52.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 550.0, "lane": 9, "texture_idx": 0 },
			{ "x": 200.0, "y": 850.0, "w": 100.0, "h": 25.0, "speed": 55.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 200.0, "lane": 10, "texture_idx": 1 },
			{ "x": 500.0, "y": 750.0, "w": 95.0, "h": 25.0, "speed": 48.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 500.0, "lane": 11, "texture_idx": 2 },

			# Top section (y=650-350)
			{ "x": 350.0, "y": 650.0, "w": 100.0, "h": 25.0, "speed": 60.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 350.0, "lane": 12, "texture_idx": 0 },
			{ "x": 150.0, "y": 550.0, "w": 95.0, "h": 25.0, "speed": 54.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 150.0, "lane": 13, "texture_idx": 1 },
			{ "x": 600.0, "y": 450.0, "w": 100.0, "h": 25.0, "speed": 56.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 600.0, "lane": 14, "texture_idx": 2 },
			{ "x": 300.0, "y": 350.0, "w": 95.0, "h": 25.0, "speed": 50.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 300.0, "lane": 15, "texture_idx": 0 },
		],

		"coins": [
			Vector2(175, 1760), Vector2(575, 1660),
			Vector2(275, 1560), Vector2(625, 1460),
			Vector2(200, 1360), Vector2(525, 1260),
			Vector2(275, 1160), Vector2(625, 1060),
			Vector2(175, 960), Vector2(500, 860),
			Vector2(225, 760), Vector2(575, 660),
			Vector2(275, 560), Vector2(525, 460),
			Vector2(200, 360), Vector2(525, 260),
			Vector2(400, 160),
		],

		"stars": [
			Vector2(700, 1400),
			Vector2(100, 800),
			Vector2(400, 150),
		],

		"powerups": [
			Vector2(625, 1560),
			Vector2(300, 1200),
			Vector2(500, 900),
			Vector2(200, 600),
			Vector2(500, 300),
		],

		"enemies": [
			# Flying Crowquistadors - far apart to avoid blocking vertical ascent
			{ "x": 400.0, "y": 1200.0, "type": "flying", "speed": 50.0, "dir": 1, "amplitude": 100.0 },
			{ "x": 350.0, "y": 600.0, "type": "flying", "speed": 60.0, "dir": -1, "amplitude": 80.0 },
			{ "x": 600.0, "y": 350.0, "type": "flying", "speed": 55.0, "dir": 1, "amplitude": 70.0 },

			# Ahuizotl water predators - patrol at the rising water surface!
			# They spawn at water level and rise with it
			{ "x": 200.0, "y": 1980.0, "type": "water", "speed": 65.0, "dir": 1 },
			{ "x": 600.0, "y": 1980.0, "type": "water", "speed": 75.0, "dir": -1 },
			{ "x": 400.0, "y": 1980.0, "type": "water", "speed": 70.0, "dir": 1 },

			# Rabbitbrijes on wider ascending platforms
			{ "x": 170.0, "y": 1375.0, "type": "rabbit", "speed": 35.0, "dir": 1 },
			{ "x": 470.0, "y": 875.0, "type": "rabbit", "speed": 40.0, "dir": -1 },
			{ "x": 170.0, "y": 375.0, "type": "rabbit", "speed": 45.0, "dir": 1 },

			# Calacas -- floating sugar skulls adding mid-height threat variety
			{ "x": 350.0, "y": 1000.0, "type": "calaca", "speed": 45.0, "dir": 1, "amplitude": 40.0 },
			{ "x": 500.0, "y": 550.0, "type": "calaca", "speed": 50.0, "dir": -1, "amplitude": 35.0 },
		],

		"is_boss_level": false,
		"is_upscroller": true,
		"is_escape": false,
		"is_fiesta": false,
	}


# ---------------------------------------------------------------------------
# Level 4: Ancient Ruins (original lines 356-430)
# ---------------------------------------------------------------------------

static func _level_4_data() -> Dictionary:
	return {
		"width": 3200.0,
		"height": 700.0,
		"player_spawn": Vector2(100, 520),  # On starting chinampa (y=550, spawn 30px above)
		"baby_position": Vector2(3000, 150),
		"water_y": 540.0,  # WATER WORLD: water covers bottom ~23% of 700px level

		"platforms": [
			# Starting chinampa -- small floating garden, NOT solid ground
			{ "x": 50.0, "y": 550.0, "w": 160.0, "h": 25.0, "is_chinampa": true },
			# Chinampas scattered across the canal network
			{ "x": 350.0, "y": 510.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 550.0, "y": 480.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 850.0, "y": 510.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1100.0, "y": 480.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1350.0, "y": 400.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1600.0, "y": 510.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1850.0, "y": 480.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2100.0, "y": 400.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2350.0, "y": 510.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2600.0, "y": 480.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2850.0, "y": 400.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			# Stepping stone to baby
			{ "x": 2900.0, "y": 270.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2950.0, "y": 180.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
		],

		"trajineras": [
			# LANE 1 (y=520) -- boats at water surface, main traversal
			{ "x": 250.0, "y": 520.0, "w": 95.0, "h": 25.0, "speed": 40.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 250.0, "lane": 0 },
			{ "x": 650.0, "y": 520.0, "w": 90.0, "h": 25.0, "speed": 45.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 650.0, "lane": 1 },
			{ "x": 1000.0, "y": 520.0, "w": 100.0, "h": 25.0, "speed": 38.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1000.0, "lane": 2 },
			{ "x": 1450.0, "y": 520.0, "w": 90.0, "h": 25.0, "speed": 50.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1450.0, "lane": 3 },
			{ "x": 1750.0, "y": 520.0, "w": 95.0, "h": 25.0, "speed": 42.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1750.0, "lane": 4 },
			{ "x": 2200.0, "y": 520.0, "w": 90.0, "h": 25.0, "speed": 48.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2200.0, "lane": 5 },
			{ "x": 2500.0, "y": 520.0, "w": 100.0, "h": 25.0, "speed": 36.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2500.0, "lane": 6 },
			{ "x": 2800.0, "y": 520.0, "w": 85.0, "h": 25.0, "speed": 44.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2800.0, "lane": 7 },
			# LANE 2 (y=460) -- higher boats for mid-level traversal
			{ "x": 450.0, "y": 460.0, "w": 90.0, "h": 25.0, "speed": 50.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 450.0, "lane": 8 },
			{ "x": 950.0, "y": 460.0, "w": 95.0, "h": 25.0, "speed": 42.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 950.0, "lane": 9 },
			{ "x": 1500.0, "y": 460.0, "w": 85.0, "h": 25.0, "speed": 46.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1500.0, "lane": 10 },
			{ "x": 2050.0, "y": 460.0, "w": 95.0, "h": 25.0, "speed": 38.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2050.0, "lane": 11 },
		],

		"coins": [
			Vector2(200, 490), Vector2(232, 490),
			Vector2(400, 470), Vector2(600, 440),
			Vector2(925, 470), Vector2(1150, 440),
			Vector2(1400, 360), Vector2(1650, 470),
			Vector2(1900, 440), Vector2(2150, 360),
			Vector2(2425, 470), Vector2(2650, 440),
			Vector2(2900, 360), Vector2(3000, 140),
			# Extra coins along canal paths
			Vector2(500, 490), Vector2(750, 470),
			Vector2(1550, 440), Vector2(2000, 470),
			Vector2(2300, 400), Vector2(2800, 440),
		],

		"stars": [
			Vector2(550, 350),
			Vector2(1850, 280),
			Vector2(2900, 140),
		],

		"powerups": [
			Vector2(400, 470),
			Vector2(1500, 360),
			Vector2(2600, 440),
		],

		"enemies": [
			# Rabbitbrijes on chinampas (y = platform_y - 30)
			{ "x": 380.0, "y": 480.0, "type": "rabbit", "speed": 50.0, "dir": 1 },
			{ "x": 700.0, "y": 450.0, "type": "flying", "speed": 65.0, "dir": 1, "amplitude": 70.0 },
			{ "x": 1400.0, "y": 370.0, "type": "platform", "speed": 0.0, "dir": 1, "amplitude": 0.0 },
			{ "x": 1650.0, "y": 380.0, "type": "flying", "speed": 70.0, "dir": 1, "amplitude": 60.0 },
			{ "x": 2380.0, "y": 480.0, "type": "rabbit", "speed": 55.0, "dir": -1 },
			{ "x": 2500.0, "y": 350.0, "type": "flying", "speed": 75.0, "dir": 1, "amplitude": 50.0 },
			{ "x": 2900.0, "y": 370.0, "type": "platform", "speed": 0.0, "dir": 1, "amplitude": 0.0 },
			{ "x": 2750.0, "y": 400.0, "type": "flying", "speed": 72.0, "dir": 1, "amplitude": 45.0 },
			{ "x": 1630.0, "y": 480.0, "type": "rabbit", "speed": 45.0, "dir": 1 },
			# Water predators lurking in the canals
			{ "x": 800.0, "y": 540.0, "type": "water", "speed": 50.0, "dir": 1 },
			{ "x": 2000.0, "y": 540.0, "type": "water", "speed": 55.0, "dir": -1 },

			# Calacas -- floating sugar skulls at varied heights among the ruins
			{ "x": 900.0, "y": 420.0, "type": "calaca", "speed": 55.0, "dir": -1, "amplitude": 25.0 },
			{ "x": 1800.0, "y": 350.0, "type": "calaca", "speed": 60.0, "dir": 1, "amplitude": 30.0 },
			{ "x": 2600.0, "y": 300.0, "type": "calaca", "speed": 50.0, "dir": -1, "amplitude": 20.0 },
		],

		"is_boss_level": false,
		"is_upscroller": false,
		"is_escape": false,
		"is_fiesta": false,
	}


# ---------------------------------------------------------------------------
# Level 5: Crystal Cave Boss (original lines 433-488)
# ---------------------------------------------------------------------------

static func _level_5_data() -> Dictionary:
	return {
		"width": 1200.0,
		"height": 800.0,
		"player_spawn": Vector2(100, 580),
		"baby_position": Vector2(1000, 200),
		"water_y": 680.0,  # WATER WORLD: water visible at ~15% of 800px, laps at arena floor

		"platforms": [
			# Arena floor
			{ "x": 0.0, "y": 750.0, "w": 1200.0, "h": 50.0, "is_chinampa": false },
			# Tier 1 - Side platforms (130px from floor, within 144px jump)
			{ "x": 100.0, "y": 620.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 500.0, "y": 620.0, "w": 200.0, "h": 20.0, "is_chinampa": true },
			{ "x": 950.0, "y": 620.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			# Tier 2 - Mid platforms (120px from tier 1)
			{ "x": 200.0, "y": 500.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 500.0, "y": 500.0, "w": 200.0, "h": 20.0, "is_chinampa": true },
			{ "x": 850.0, "y": 500.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			# Tier 3 - Traversal connectors (120px from tier 2)
			{ "x": 50.0, "y": 380.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1050.0, "y": 380.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			# Tier 4 - Top platforms (100px from tier 3)
			{ "x": 350.0, "y": 280.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 700.0, "y": 280.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			# Tier 5 - Summit + baby (80px from tier 4)
			{ "x": 500.0, "y": 200.0, "w": 200.0, "h": 20.0, "is_chinampa": true },
			{ "x": 950.0, "y": 220.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
		],

		"trajineras": [
			# Trajineras bobbing at the water surface around the arena (water_y=680)
			# Slow patrol speeds for boss fight flavor + emergency escape platforms
			{ "x": 100.0, "y": 660.0, "w": 90.0, "h": 25.0, "speed": 30.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 100.0, "lane": 0, "texture_idx": 0 },
			{ "x": 350.0, "y": 665.0, "w": 85.0, "h": 25.0, "speed": 25.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 350.0, "lane": 1, "texture_idx": 1 },
			{ "x": 600.0, "y": 660.0, "w": 95.0, "h": 25.0, "speed": 35.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 600.0, "lane": 2, "texture_idx": 2 },
			{ "x": 850.0, "y": 665.0, "w": 85.0, "h": 25.0, "speed": 28.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 850.0, "lane": 3, "texture_idx": 0 },
			{ "x": 1050.0, "y": 660.0, "w": 90.0, "h": 25.0, "speed": 32.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1050.0, "lane": 4, "texture_idx": 1 },
		],

		"coins": [
			Vector2(175, 580), Vector2(600, 580),
			Vector2(1025, 580), Vector2(275, 460),
			Vector2(600, 460), Vector2(925, 460),
			Vector2(425, 240), Vector2(775, 240),
			Vector2(600, 160),
		],

		"stars": [
			Vector2(100, 340),
			Vector2(600, 150),
			Vector2(1100, 340),
		],

		"powerups": [
			Vector2(600, 580),
			Vector2(600, 160),
		],

		"enemies": [
			{ "x": 300.0, "y": 550.0, "type": "flying", "speed": 60.0, "dir": 1, "amplitude": 60.0 },
			{ "x": 900.0, "y": 550.0, "type": "flying", "speed": 60.0, "dir": 1, "amplitude": 60.0 },
			{ "x": 600.0, "y": 330.0, "type": "flying", "speed": 70.0, "dir": 1, "amplitude": 80.0 },
		],

		"is_boss_level": true,
		"is_upscroller": false,
		"is_escape": false,
		"is_fiesta": false,
	}


# ---------------------------------------------------------------------------
# Level 6: Night Canals (original lines 491-557)
# ---------------------------------------------------------------------------

static func _level_6_data() -> Dictionary:
	return {
		"width": 3000.0,
		"height": 700.0,
		"player_spawn": Vector2(100, 500),  # On starting chinampa (y=530, spawn 30px above)
		"baby_position": Vector2(2800, 200),
		"water_y": 520.0,  # WATER WORLD: water covers bottom ~26% of 700px level

		"platforms": [
			# Starting chinampa -- floating garden at the water surface
			{ "x": 50.0, "y": 530.0, "w": 160.0, "h": 25.0, "is_chinampa": true },
			# Chinampas across the night canals -- no ground, all floating
			{ "x": 250.0, "y": 500.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 500.0, "y": 480.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 800.0, "y": 500.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1050.0, "y": 480.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1300.0, "y": 400.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1550.0, "y": 500.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1800.0, "y": 480.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2050.0, "y": 400.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2300.0, "y": 320.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2550.0, "y": 400.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			# Stepping stone to baby area
			{ "x": 2650.0, "y": 320.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2750.0, "y": 250.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
		],

		"trajineras": [
			# LANE 1 (y=510) -- boats at water surface, main traversal through night canals
			{ "x": 150.0, "y": 510.0, "w": 90.0, "h": 25.0, "speed": 40.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 150.0, "lane": 0 },
			{ "x": 450.0, "y": 510.0, "w": 85.0, "h": 25.0, "speed": 45.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 450.0, "lane": 1 },
			{ "x": 750.0, "y": 510.0, "w": 95.0, "h": 25.0, "speed": 38.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 750.0, "lane": 2 },
			{ "x": 1150.0, "y": 510.0, "w": 90.0, "h": 25.0, "speed": 50.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1150.0, "lane": 3 },
			{ "x": 1550.0, "y": 510.0, "w": 85.0, "h": 25.0, "speed": 42.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1550.0, "lane": 4 },
			{ "x": 1900.0, "y": 510.0, "w": 95.0, "h": 25.0, "speed": 35.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1900.0, "lane": 5 },
			{ "x": 2250.0, "y": 510.0, "w": 90.0, "h": 25.0, "speed": 48.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2250.0, "lane": 6 },
			{ "x": 2600.0, "y": 510.0, "w": 85.0, "h": 25.0, "speed": 40.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2600.0, "lane": 7 },
			# LANE 2 (y=450) -- higher boats for mid-level traversal
			{ "x": 350.0, "y": 450.0, "w": 90.0, "h": 25.0, "speed": 52.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 350.0, "lane": 8 },
			{ "x": 900.0, "y": 450.0, "w": 85.0, "h": 25.0, "speed": 44.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 900.0, "lane": 9 },
			{ "x": 1400.0, "y": 450.0, "w": 95.0, "h": 25.0, "speed": 46.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1400.0, "lane": 10 },
			{ "x": 2100.0, "y": 450.0, "w": 90.0, "h": 25.0, "speed": 40.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2100.0, "lane": 11 },
		],

		"coins": [
			Vector2(200, 490), Vector2(350, 460), Vector2(550, 440),
			Vector2(875, 460), Vector2(1100, 440), Vector2(1350, 360),
			Vector2(1600, 460), Vector2(1850, 440), Vector2(2100, 360),
			Vector2(2350, 280), Vector2(2600, 360), Vector2(2800, 210),
			# Extra coins along canal paths
			Vector2(700, 460), Vector2(1450, 440),
			Vector2(1950, 460), Vector2(2200, 320), Vector2(2700, 280),
		],

		"stars": [
			Vector2(500, 350),
			Vector2(1300, 280),
			Vector2(2700, 180),
		],

		"powerups": [
			Vector2(400, 460),
			Vector2(1200, 440),
			Vector2(2200, 360),
		],

		"enemies": [
			# No ground enemies -- replaced with chinampa rabbits and canal hunters
			{ "x": 280.0, "y": 470.0, "type": "rabbit", "speed": 40.0, "dir": 1 },
			{ "x": 650.0, "y": 450.0, "type": "flying", "speed": 70.0, "dir": 1, "amplitude": 60.0 },
			{ "x": 1200.0, "y": 380.0, "type": "flying", "speed": 65.0, "dir": 1, "amplitude": 70.0 },
			{ "x": 1580.0, "y": 470.0, "type": "rabbit", "speed": 45.0, "dir": -1 },
			{ "x": 1700.0, "y": 400.0, "type": "flying", "speed": 75.0, "dir": 1, "amplitude": 50.0 },
			{ "x": 2400.0, "y": 300.0, "type": "flying", "speed": 80.0, "dir": 1, "amplitude": 60.0 },
			# Water predators in the canals
			{ "x": 600.0, "y": 520.0, "type": "water", "speed": 50.0, "dir": 1 },
			{ "x": 1500.0, "y": 520.0, "type": "water", "speed": 55.0, "dir": -1 },
			{ "x": 2300.0, "y": 520.0, "type": "water", "speed": 60.0, "dir": 1 },

			# Calacas -- night canals are perfect for floating sugar skulls
			{ "x": 500.0, "y": 350.0, "type": "calaca", "speed": 55.0, "dir": 1, "amplitude": 25.0 },
			{ "x": 1400.0, "y": 320.0, "type": "calaca", "speed": 60.0, "dir": -1, "amplitude": 30.0 },
			{ "x": 2200.0, "y": 280.0, "type": "calaca", "speed": 65.0, "dir": 1, "amplitude": 20.0 },
		],

		"is_boss_level": false,
		"is_upscroller": false,
		"is_escape": false,
		"is_fiesta": false,
	}


# ---------------------------------------------------------------------------
# Level 7: Floating Gardens Escape (World 4)
# ---------------------------------------------------------------------------

static func _level_7_data() -> Dictionary:
	return {
		"width": 3500.0,
		"height": 700.0,
		"player_spawn": Vector2(100, 490),  # On starting chinampa (y=520, spawn 30px above)
		"baby_position": Vector2(3300, 350),
		"water_y": 510.0,  # WATER WORLD: flood chases through canals, water covers ~27%
		"escape_speed": 120.0,

		"platforms": [
			# Starting chinampa -- small floating garden
			{ "x": 50.0, "y": 520.0, "w": 160.0, "h": 25.0, "is_chinampa": true },

			# Chinampas forming the escape route -- all floating over canal water
			{ "x": 300.0, "y": 500.0, "w": 140.0, "h": 20.0, "is_chinampa": true },
			{ "x": 550.0, "y": 490.0, "w": 130.0, "h": 20.0, "is_chinampa": true },
			{ "x": 800.0, "y": 480.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1050.0, "y": 500.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1300.0, "y": 490.0, "w": 140.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1550.0, "y": 480.0, "w": 130.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1800.0, "y": 500.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2050.0, "y": 490.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2300.0, "y": 480.0, "w": 140.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2550.0, "y": 500.0, "w": 130.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2800.0, "y": 490.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 3050.0, "y": 480.0, "w": 120.0, "h": 20.0, "is_chinampa": true },

			# Higher chinampas for advanced players with elotes/stars
			{ "x": 350.0, "y": 400.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 850.0, "y": 380.0, "w": 130.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1500.0, "y": 400.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2100.0, "y": 390.0, "w": 130.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2700.0, "y": 410.0, "w": 120.0, "h": 20.0, "is_chinampa": true },

			# Baby platform at far right
			{ "x": 3200.0, "y": 380.0, "w": 200.0, "h": 20.0, "is_chinampa": true },
		],

		"trajineras": [
			# 8 trajineras across the escape route -- boats bobbing in the flood
			{ "x": 200.0, "y": 500.0, "w": 85.0, "h": 25.0, "speed": 45.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 200.0, "lane": 0, "texture_idx": 0 },
			{ "x": 500.0, "y": 495.0, "w": 90.0, "h": 25.0, "speed": 50.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 500.0, "lane": 1, "texture_idx": 1 },
			{ "x": 900.0, "y": 500.0, "w": 85.0, "h": 25.0, "speed": 42.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 900.0, "lane": 2, "texture_idx": 2 },
			{ "x": 1200.0, "y": 495.0, "w": 90.0, "h": 25.0, "speed": 55.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1200.0, "lane": 3, "texture_idx": 0 },
			{ "x": 1650.0, "y": 500.0, "w": 85.0, "h": 25.0, "speed": 48.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1650.0, "lane": 4, "texture_idx": 1 },
			{ "x": 2000.0, "y": 495.0, "w": 90.0, "h": 25.0, "speed": 40.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2000.0, "lane": 5, "texture_idx": 2 },
			{ "x": 2450.0, "y": 500.0, "w": 85.0, "h": 25.0, "speed": 52.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2450.0, "lane": 6, "texture_idx": 0 },
			{ "x": 3100.0, "y": 495.0, "w": 90.0, "h": 25.0, "speed": 44.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 3100.0, "lane": 7, "texture_idx": 1 },
		],

		"coins": [
			# Canal escape path coins -- on and above chinampas
			Vector2(200, 480), Vector2(350, 460), Vector2(500, 450),
			Vector2(700, 460), Vector2(900, 450), Vector2(1050, 460),
			Vector2(1200, 450), Vector2(1400, 460), Vector2(1600, 450),
			Vector2(1800, 460), Vector2(2000, 450), Vector2(2200, 460),
			Vector2(2400, 450), Vector2(2600, 460), Vector2(2800, 450),
			Vector2(3000, 460), Vector2(3200, 380), Vector2(3300, 350),
		],

		"stars": [
			# 3 stars in hard-to-reach positions above escape path
			Vector2(400, 360),
			Vector2(1550, 360),
			Vector2(2750, 370),
		],

		"powerups": [
			# 3 powerups spaced across the escape route
			Vector2(600, 450),
			Vector2(1500, 460),
			Vector2(2500, 460),
		],

		"enemies": [
			# Rabbits on chinampas -- they bounce as you flee
			{ "x": 330.0, "y": 470.0, "type": "rabbit", "speed": 40.0, "dir": 1 },
			{ "x": 1080.0, "y": 470.0, "type": "rabbit", "speed": 45.0, "dir": -1 },
			{ "x": 2330.0, "y": 450.0, "type": "rabbit", "speed": 50.0, "dir": 1 },
			# Flying enemies over the canals
			{ "x": 500.0, "y": 420.0, "type": "flying", "speed": 70.0, "dir": 1, "amplitude": 60.0 },
			{ "x": 1100.0, "y": 400.0, "type": "flying", "speed": 75.0, "dir": -1, "amplitude": 70.0 },
			{ "x": 1800.0, "y": 410.0, "type": "flying", "speed": 65.0, "dir": 1, "amplitude": 50.0 },
			{ "x": 2500.0, "y": 400.0, "type": "flying", "speed": 80.0, "dir": -1, "amplitude": 65.0 },
			# Water predators in the rising flood
			{ "x": 800.0, "y": 510.0, "type": "water", "speed": 55.0, "dir": -1 },
			{ "x": 1900.0, "y": 510.0, "type": "water", "speed": 60.0, "dir": 1 },
			{ "x": 2900.0, "y": 510.0, "type": "water", "speed": 50.0, "dir": -1 },

			# Calacas -- spirits floating above the escape path
			{ "x": 1400.0, "y": 380.0, "type": "calaca", "speed": 60.0, "dir": 1, "amplitude": 25.0 },
			{ "x": 2700.0, "y": 370.0, "type": "calaca", "speed": 65.0, "dir": -1, "amplitude": 30.0 },
		],

		"is_boss_level": false,
		"is_upscroller": false,
		"is_escape": true,
		"is_fiesta": false,
	}


# ---------------------------------------------------------------------------
# Level 8: Night Canals Upscroller (World 5)
# ---------------------------------------------------------------------------

static func _level_8_data() -> Dictionary:
	return {
		"width": 800.0,
		"height": 2500.0,
		"player_spawn": Vector2(350, 2370),  # On starting chinampa (y=2400, spawn 30px above)
		"baby_position": Vector2(400, 70),
		"water_y": 2430.0,  # WATER WORLD: rising water starts just below starting chinampas

		"platforms": [
			# Starting chinampas -- floating gardens at the canal surface, no solid ground
			{ "x": 250.0, "y": 2400.0, "w": 200.0, "h": 25.0, "is_chinampa": true },
			{ "x": 500.0, "y": 2410.0, "w": 150.0, "h": 25.0, "is_chinampa": true },

			# Ascending zigzag chinampas -- alternating left/right every 100-120px
			# All vertical gaps <= 130px from the platform below
			# Section 1: Bottom (y=2450 -> 1900)
			{ "x": 500.0, "y": 2330.0, "w": 150.0, "h": 20.0, "is_chinampa": true },  # 120px from ground
			{ "x": 150.0, "y": 2220.0, "w": 150.0, "h": 20.0, "is_chinampa": true },  # 110px
			{ "x": 550.0, "y": 2110.0, "w": 150.0, "h": 20.0, "is_chinampa": true },  # 110px
			{ "x": 100.0, "y": 2000.0, "w": 150.0, "h": 20.0, "is_chinampa": true },  # 110px
			{ "x": 500.0, "y": 1900.0, "w": 150.0, "h": 20.0, "is_chinampa": true },  # 100px

			# Rest platform 1 (wide, ~y=1850)
			{ "x": 250.0, "y": 1800.0, "w": 300.0, "h": 20.0, "is_chinampa": true },  # 100px

			# Section 2: Mid-low (y=1800 -> 1200)
			{ "x": 100.0, "y": 1690.0, "w": 150.0, "h": 20.0, "is_chinampa": true },  # 110px
			{ "x": 550.0, "y": 1580.0, "w": 150.0, "h": 20.0, "is_chinampa": true },  # 110px
			{ "x": 150.0, "y": 1470.0, "w": 150.0, "h": 20.0, "is_chinampa": true },  # 110px
			{ "x": 500.0, "y": 1370.0, "w": 150.0, "h": 20.0, "is_chinampa": true },  # 100px
			{ "x": 100.0, "y": 1260.0, "w": 150.0, "h": 20.0, "is_chinampa": true },  # 110px

			# Rest platform 2 (wide, ~y=1200)
			{ "x": 250.0, "y": 1170.0, "w": 280.0, "h": 20.0, "is_chinampa": true },  # 90px

			# Section 3: Mid-high (y=1170 -> 600)
			{ "x": 550.0, "y": 1060.0, "w": 150.0, "h": 20.0, "is_chinampa": true },  # 110px
			{ "x": 100.0, "y": 960.0, "w": 150.0, "h": 20.0, "is_chinampa": true },   # 100px
			{ "x": 500.0, "y": 850.0, "w": 150.0, "h": 20.0, "is_chinampa": true },   # 110px
			{ "x": 150.0, "y": 740.0, "w": 150.0, "h": 20.0, "is_chinampa": true },   # 110px
			{ "x": 550.0, "y": 640.0, "w": 150.0, "h": 20.0, "is_chinampa": true },   # 100px

			# Rest platform 3 (wide, ~y=560)
			{ "x": 200.0, "y": 540.0, "w": 250.0, "h": 20.0, "is_chinampa": true },   # 100px

			# Section 4: Top (y=540 -> 100)
			{ "x": 100.0, "y": 430.0, "w": 150.0, "h": 20.0, "is_chinampa": true },   # 110px
			{ "x": 550.0, "y": 320.0, "w": 150.0, "h": 20.0, "is_chinampa": true },   # 110px
			{ "x": 150.0, "y": 210.0, "w": 150.0, "h": 20.0, "is_chinampa": true },   # 110px

			# Summit platform with baby
			{ "x": 300.0, "y": 100.0, "w": 200.0, "h": 20.0, "is_chinampa": true },   # 110px
		],

		"trajineras": [
			# 12 trajineras at various heights as rescue/stepping platforms
			# Alternating left/right, filling in between static chinampas

			# Bottom section
			{ "x": 300.0, "y": 2380.0, "w": 95.0, "h": 25.0, "speed": 45.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 300.0, "lane": 0, "texture_idx": 0 },
			{ "x": 400.0, "y": 2160.0, "w": 90.0, "h": 25.0, "speed": 50.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 400.0, "lane": 1, "texture_idx": 1 },
			{ "x": 300.0, "y": 1950.0, "w": 95.0, "h": 25.0, "speed": 42.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 300.0, "lane": 2, "texture_idx": 2 },

			# Mid-low section
			{ "x": 350.0, "y": 1740.0, "w": 85.0, "h": 25.0, "speed": 48.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 350.0, "lane": 3, "texture_idx": 0 },
			{ "x": 300.0, "y": 1530.0, "w": 95.0, "h": 25.0, "speed": 55.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 300.0, "lane": 4, "texture_idx": 1 },
			{ "x": 400.0, "y": 1310.0, "w": 90.0, "h": 25.0, "speed": 46.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 400.0, "lane": 5, "texture_idx": 2 },

			# Mid-high section
			{ "x": 350.0, "y": 1110.0, "w": 95.0, "h": 25.0, "speed": 52.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 350.0, "lane": 6, "texture_idx": 0 },
			{ "x": 300.0, "y": 900.0, "w": 85.0, "h": 25.0, "speed": 58.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 300.0, "lane": 7, "texture_idx": 1 },
			{ "x": 400.0, "y": 690.0, "w": 95.0, "h": 25.0, "speed": 50.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 400.0, "lane": 8, "texture_idx": 2 },

			# Upper section
			{ "x": 350.0, "y": 490.0, "w": 90.0, "h": 25.0, "speed": 54.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 350.0, "lane": 9, "texture_idx": 0 },
			{ "x": 400.0, "y": 370.0, "w": 85.0, "h": 25.0, "speed": 56.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 400.0, "lane": 10, "texture_idx": 1 },
			{ "x": 300.0, "y": 160.0, "w": 95.0, "h": 25.0, "speed": 48.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 300.0, "lane": 11, "texture_idx": 2 },
		],

		"coins": [
			# 17 coins guiding the path upward
			Vector2(575, 2290), Vector2(225, 2180), Vector2(625, 2070),
			Vector2(175, 1960), Vector2(575, 1860), Vector2(400, 1760),
			Vector2(175, 1650), Vector2(625, 1540), Vector2(225, 1430),
			Vector2(575, 1330), Vector2(175, 1220), Vector2(400, 1130),
			Vector2(625, 1020), Vector2(175, 920), Vector2(575, 810),
			Vector2(225, 700), Vector2(400, 160),
		],

		"stars": [
			# 3 stars off the main path requiring detours
			Vector2(700, 1900),   # Far right, forces risky detour in bottom section
			Vector2(50, 1050),    # Far left edge, tight timing with rising water
			Vector2(700, 400),    # Far right near top, must leap from zigzag path
		],

		"powerups": [
			# 5 powerups spaced vertically
			Vector2(350, 2280),
			Vector2(300, 1750),
			Vector2(350, 1220),
			Vector2(300, 700),
			Vector2(350, 260),
		],

		"enemies": [
			# 5-6 enemies: flying + water
			# Flying enemies patrolling horizontally
			{ "x": 400.0, "y": 1600.0, "type": "flying", "speed": 60.0, "dir": 1, "amplitude": 100.0 },
			{ "x": 350.0, "y": 1100.0, "type": "flying", "speed": 65.0, "dir": -1, "amplitude": 80.0 },
			{ "x": 400.0, "y": 600.0, "type": "flying", "speed": 70.0, "dir": 1, "amplitude": 90.0 },
			# Ahuizotl water enemies -- spawn at water level, rise with the flood
			{ "x": 200.0, "y": 2430.0, "type": "water", "speed": 70.0, "dir": 1 },
			{ "x": 600.0, "y": 2430.0, "type": "water", "speed": 75.0, "dir": -1 },
			{ "x": 400.0, "y": 2430.0, "type": "water", "speed": 65.0, "dir": 1 },

			# Calacas -- ghostly skulls floating in the vertical shaft
			{ "x": 350.0, "y": 1350.0, "type": "calaca", "speed": 50.0, "dir": -1, "amplitude": 35.0 },
			{ "x": 500.0, "y": 800.0, "type": "calaca", "speed": 55.0, "dir": 1, "amplitude": 30.0 },
		],

		"is_boss_level": false,
		"is_upscroller": true,
		"is_escape": false,
		"is_fiesta": false,
	}


# ---------------------------------------------------------------------------
# Level 9: Night Canals Escape (World 5)
# ---------------------------------------------------------------------------

static func _level_9_data() -> Dictionary:
	return {
		"width": 4000.0,
		"height": 700.0,
		"player_spawn": Vector2(100, 470),  # On starting chinampa (y=500, spawn 30px above)
		"baby_position": Vector2(3800, 300),
		"water_y": 490.0,  # WATER WORLD: flood chases through night canals, water covers ~30%
		"escape_speed": 150.0,

		"platforms": [
			# Starting chinampa -- floating garden at water surface
			{ "x": 50.0, "y": 500.0, "w": 160.0, "h": 25.0, "is_chinampa": true },
			# Chinampas -- main escape route, all floating over canal water
			{ "x": 300.0, "y": 480.0, "w": 130.0, "h": 20.0, "is_chinampa": true },
			{ "x": 550.0, "y": 470.0, "w": 140.0, "h": 20.0, "is_chinampa": true },
			{ "x": 800.0, "y": 480.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1050.0, "y": 470.0, "w": 130.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1300.0, "y": 480.0, "w": 140.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1550.0, "y": 470.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1800.0, "y": 480.0, "w": 130.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2050.0, "y": 470.0, "w": 140.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2300.0, "y": 480.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2550.0, "y": 470.0, "w": 130.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2800.0, "y": 480.0, "w": 140.0, "h": 20.0, "is_chinampa": true },
			{ "x": 3050.0, "y": 470.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			# Chinampas -- upper layer for advanced players
			{ "x": 350.0, "y": 390.0, "w": 110.0, "h": 20.0, "is_chinampa": true },
			{ "x": 750.0, "y": 400.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1300.0, "y": 380.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1700.0, "y": 400.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2350.0, "y": 380.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2750.0, "y": 390.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			# High chinampas for star rewards
			{ "x": 600.0, "y": 320.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1500.0, "y": 330.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2600.0, "y": 320.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			# Stepping stones to baby -- elevated chinampas at far right
			{ "x": 3300.0, "y": 470.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 3500.0, "y": 390.0, "w": 110.0, "h": 20.0, "is_chinampa": true },
			{ "x": 3700.0, "y": 330.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
		],

		"trajineras": [
			# 8 trajineras in the night canals -- fast escape boats
			{ "x": 200.0, "y": 480.0, "w": 90.0, "h": 25.0, "speed": 55.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 200.0, "lane": 0, "texture_idx": 0 },
			{ "x": 600.0, "y": 475.0, "w": 85.0, "h": 25.0, "speed": 50.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 600.0, "lane": 1, "texture_idx": 1 },
			{ "x": 1000.0, "y": 480.0, "w": 90.0, "h": 25.0, "speed": 60.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1000.0, "lane": 2, "texture_idx": 2 },
			{ "x": 1450.0, "y": 475.0, "w": 85.0, "h": 25.0, "speed": 45.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1450.0, "lane": 3, "texture_idx": 0 },
			{ "x": 1900.0, "y": 480.0, "w": 90.0, "h": 25.0, "speed": 55.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1900.0, "lane": 4, "texture_idx": 1 },
			{ "x": 2400.0, "y": 475.0, "w": 85.0, "h": 25.0, "speed": 52.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2400.0, "lane": 5, "texture_idx": 2 },
			{ "x": 2900.0, "y": 480.0, "w": 90.0, "h": 25.0, "speed": 48.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2900.0, "lane": 6, "texture_idx": 0 },
			{ "x": 3400.0, "y": 475.0, "w": 85.0, "h": 25.0, "speed": 58.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 3400.0, "lane": 7, "texture_idx": 1 },
		],

		"coins": [
			# Canal escape coins -- on and between chinampas
			Vector2(250, 450), Vector2(400, 440), Vector2(600, 430),
			Vector2(850, 440), Vector2(1100, 430), Vector2(1350, 440),
			Vector2(1600, 430), Vector2(1850, 440), Vector2(2100, 430),
			# Upper chinampa coins
			Vector2(405, 350), Vector2(800, 360), Vector2(1360, 340),
			Vector2(1750, 360), Vector2(2410, 340),
			# High star-tier coins
			Vector2(650, 280), Vector2(1550, 290), Vector2(2650, 280),
			# Approach to baby
			Vector2(3350, 430), Vector2(3560, 350), Vector2(3770, 290),
		],

		"stars": [
			# Hard-to-reach positions on high chinampas
			Vector2(650, 280),
			Vector2(1550, 290),
			Vector2(2650, 280),
		],

		"powerups": [
			Vector2(350, 440),
			Vector2(1200, 440),
			Vector2(2150, 440),
			Vector2(3100, 430),
		],

		"enemies": [
			# Flying enemies over the night canals
			{ "x": 400.0, "y": 370.0, "type": "flying", "speed": 75.0, "dir": 1, "amplitude": 60.0 },
			{ "x": 1000.0, "y": 340.0, "type": "flying", "speed": 80.0, "dir": -1, "amplitude": 70.0 },
			{ "x": 1650.0, "y": 360.0, "type": "flying", "speed": 70.0, "dir": 1, "amplitude": 55.0 },
			{ "x": 2300.0, "y": 340.0, "type": "flying", "speed": 85.0, "dir": -1, "amplitude": 65.0 },
			{ "x": 2900.0, "y": 370.0, "type": "flying", "speed": 75.0, "dir": 1, "amplitude": 50.0 },
			# Rabbits on chinampas
			{ "x": 830.0, "y": 450.0, "type": "rabbit", "speed": 50.0, "dir": -1 },
			{ "x": 1830.0, "y": 450.0, "type": "rabbit", "speed": 55.0, "dir": 1 },
			{ "x": 2830.0, "y": 450.0, "type": "rabbit", "speed": 50.0, "dir": -1 },
			# Water enemies in the canals
			{ "x": 700.0, "y": 490.0, "type": "water", "speed": 50.0, "dir": 1 },
			{ "x": 1500.0, "y": 490.0, "type": "water", "speed": 55.0, "dir": -1 },
			{ "x": 2500.0, "y": 490.0, "type": "water", "speed": 45.0, "dir": 1 },
			{ "x": 3200.0, "y": 490.0, "type": "water", "speed": 60.0, "dir": -1 },
			# Calacas -- night spirits haunting the canal escape route
			{ "x": 800.0, "y": 350.0, "type": "calaca", "speed": 60.0, "dir": 1, "amplitude": 25.0 },
			{ "x": 1800.0, "y": 330.0, "type": "calaca", "speed": 65.0, "dir": -1, "amplitude": 30.0 },
			{ "x": 3000.0, "y": 340.0, "type": "calaca", "speed": 70.0, "dir": 1, "amplitude": 20.0 },
		],

		"is_boss_level": false,
		"is_upscroller": false,
		"is_escape": true,
		"is_fiesta": false,
	}


# ---------------------------------------------------------------------------
# Level 10: La Fiesta Boss Arena (World 6)
# ---------------------------------------------------------------------------

static func _level_10_data() -> Dictionary:
	return {
		"width": 1400.0,
		"height": 900.0,
		"player_spawn": Vector2(100, 800),
		"baby_position": Vector2(1200, 320),
		"water_y": 780.0,  # WATER WORLD: water visible at arena edges, laps at floor

		"platforms": [
			# Arena floor -- full width
			{ "x": 0.0, "y": 850.0, "w": 1400.0, "h": 50.0, "is_chinampa": false },
			# Tier 1 (y=720, 130px from floor y=850)
			{ "x": 80.0, "y": 720.0, "w": 160.0, "h": 20.0, "is_chinampa": true },
			{ "x": 560.0, "y": 720.0, "w": 220.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1160.0, "y": 720.0, "w": 160.0, "h": 20.0, "is_chinampa": true },
			# Tier 2 (y=590, 130px from Tier 1 y=720)
			{ "x": 180.0, "y": 590.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			{ "x": 560.0, "y": 590.0, "w": 220.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1070.0, "y": 590.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			# Tier 3 (y=460, 130px from Tier 2 y=590)
			{ "x": 340.0, "y": 460.0, "w": 160.0, "h": 20.0, "is_chinampa": true },
			{ "x": 900.0, "y": 460.0, "w": 160.0, "h": 20.0, "is_chinampa": true },
			# Top center (y=350, 110px from Tier 3 y=460)
			{ "x": 560.0, "y": 350.0, "w": 220.0, "h": 20.0, "is_chinampa": true },
			# Baby platform (y=370, offset right, 90px from Tier 3 y=460)
			{ "x": 1100.0, "y": 370.0, "w": 150.0, "h": 20.0, "is_chinampa": true },
			# Side escape ledges -- small chinampas on left/right walls between tiers
			{ "x": 0.0, "y": 650.0, "w": 60.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1340.0, "y": 650.0, "w": 60.0, "h": 20.0, "is_chinampa": true },
			{ "x": 0.0, "y": 520.0, "w": 60.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1340.0, "y": 520.0, "w": 60.0, "h": 20.0, "is_chinampa": true },
		],

		"trajineras": [
			# 6 trajineras bobbing at water level around the arena (water_y=780)
			{ "x": 50.0, "y": 760.0, "w": 90.0, "h": 25.0, "speed": 30.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 50.0, "lane": 0, "texture_idx": 0 },
			{ "x": 300.0, "y": 765.0, "w": 85.0, "h": 25.0, "speed": 25.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 300.0, "lane": 1, "texture_idx": 1 },
			{ "x": 550.0, "y": 760.0, "w": 95.0, "h": 25.0, "speed": 35.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 550.0, "lane": 2, "texture_idx": 2 },
			{ "x": 800.0, "y": 765.0, "w": 85.0, "h": 25.0, "speed": 28.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 800.0, "lane": 3, "texture_idx": 0 },
			{ "x": 1050.0, "y": 760.0, "w": 90.0, "h": 25.0, "speed": 32.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1050.0, "lane": 4, "texture_idx": 1 },
			{ "x": 1250.0, "y": 765.0, "w": 85.0, "h": 25.0, "speed": 30.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1250.0, "lane": 5, "texture_idx": 2 },
		],

		"coins": [
			# Floor level coins
			Vector2(200, 810), Vector2(400, 810), Vector2(670, 810),
			Vector2(900, 810), Vector2(1100, 810),
			# Tier 1 coins
			Vector2(160, 680), Vector2(670, 680), Vector2(1240, 680),
			# Tier 2 coins
			Vector2(255, 550), Vector2(670, 550), Vector2(1145, 550),
			# Tier 3 coins
			Vector2(420, 420), Vector2(980, 420),
			# Top coins near baby
			Vector2(670, 310), Vector2(1175, 330),
		],

		"stars": [
			# Hard-to-reach during boss fight
			Vector2(30, 480),
			Vector2(670, 310),
			Vector2(1370, 480),
		],

		"powerups": [
			Vector2(670, 680),
			Vector2(255, 550),
		],

		"enemies": [
			# 3 flying enemies patrolling the arena tiers
			{ "x": 300.0, "y": 550.0, "type": "flying", "speed": 65.0, "dir": 1, "amplitude": 70.0 },
			{ "x": 700.0, "y": 400.0, "type": "flying", "speed": 70.0, "dir": -1, "amplitude": 60.0 },
			{ "x": 1100.0, "y": 550.0, "type": "flying", "speed": 65.0, "dir": 1, "amplitude": 65.0 },
		],

		"is_boss_level": true,
		"is_upscroller": false,
		"is_escape": false,
		"is_fiesta": false,
	}


# ---------------------------------------------------------------------------
# Level 11: La Gran Fiesta -- The Final Celebration (World 6)
# ---------------------------------------------------------------------------

static func _level_11_data() -> Dictionary:
	return {
		"width": 3000.0,
		"height": 600.0,
		"player_spawn": Vector2(100, 440),  # On starting chinampa (y=470, spawn 30px above)
		"baby_position": Vector2(2800, 200),
		"water_y": 460.0,  # WATER WORLD: celebration on water! Covers bottom ~23% of 600px

		"platforms": [
			# Starting chinampa for the fiesta
			{ "x": 50.0, "y": 470.0, "w": 140.0, "h": 25.0, "is_chinampa": true },
			# Festival chinampas -- low tier (floating on the canal water)
			{ "x": 100.0, "y": 470.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 350.0, "y": 480.0, "w": 110.0, "h": 20.0, "is_chinampa": true },
			{ "x": 600.0, "y": 460.0, "w": 130.0, "h": 20.0, "is_chinampa": true },
			{ "x": 900.0, "y": 470.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1200.0, "y": 480.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1500.0, "y": 460.0, "w": 130.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1800.0, "y": 470.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2100.0, "y": 480.0, "w": 110.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2400.0, "y": 460.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			# Festival chinampas -- mid tier (y=370-420, within 90-130px of low tier)
			{ "x": 200.0, "y": 380.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 500.0, "y": 370.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 800.0, "y": 390.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1050.0, "y": 380.0, "w": 110.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1350.0, "y": 370.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1650.0, "y": 390.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1950.0, "y": 380.0, "w": 110.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2250.0, "y": 370.0, "w": 120.0, "h": 20.0, "is_chinampa": true },
			# Festival chinampas -- high tier (y=280-350, within 90-100px of mid tier)
			{ "x": 400.0, "y": 290.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 700.0, "y": 300.0, "w": 110.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1150.0, "y": 280.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			{ "x": 1500.0, "y": 300.0, "w": 110.0, "h": 20.0, "is_chinampa": true },
			{ "x": 2050.0, "y": 290.0, "w": 100.0, "h": 20.0, "is_chinampa": true },
			# Dance floor -- wide platform near the end
			{ "x": 2500.0, "y": 350.0, "w": 400.0, "h": 20.0, "is_chinampa": true },
			# Baby platform -- decorated perch
			{ "x": 2700.0, "y": 230.0, "w": 200.0, "h": 20.0, "is_chinampa": true },
		],

		"trajineras": [
			# MASSIVE fiesta flotilla! Celebration on the canals of Xochimilco!
			# Lane 1 (y=450) -- boats at water surface, celebration parade
			{ "x": 150.0, "y": 450.0, "w": 95.0, "h": 25.0, "speed": 35.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 150.0, "lane": 0, "texture_idx": 0 },
			{ "x": 500.0, "y": 450.0, "w": 90.0, "h": 25.0, "speed": 40.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 500.0, "lane": 1, "texture_idx": 1 },
			{ "x": 850.0, "y": 450.0, "w": 100.0, "h": 25.0, "speed": 38.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 850.0, "lane": 2, "texture_idx": 2 },
			{ "x": 1200.0, "y": 450.0, "w": 90.0, "h": 25.0, "speed": 42.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1200.0, "lane": 3, "texture_idx": 0 },
			{ "x": 1550.0, "y": 450.0, "w": 95.0, "h": 25.0, "speed": 36.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1550.0, "lane": 4, "texture_idx": 1 },
			{ "x": 1900.0, "y": 450.0, "w": 90.0, "h": 25.0, "speed": 44.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1900.0, "lane": 5, "texture_idx": 2 },
			{ "x": 2300.0, "y": 450.0, "w": 95.0, "h": 25.0, "speed": 38.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2300.0, "lane": 6, "texture_idx": 0 },
			{ "x": 2650.0, "y": 450.0, "w": 90.0, "h": 25.0, "speed": 42.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2650.0, "lane": 7, "texture_idx": 1 },
			# Lane 2 (y=400) -- mid-level celebration boats
			{ "x": 300.0, "y": 400.0, "w": 100.0, "h": 25.0, "speed": 45.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 300.0, "lane": 8, "texture_idx": 0 },
			{ "x": 700.0, "y": 400.0, "w": 90.0, "h": 25.0, "speed": 38.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 700.0, "lane": 9, "texture_idx": 1 },
			{ "x": 1100.0, "y": 400.0, "w": 95.0, "h": 25.0, "speed": 50.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1100.0, "lane": 10, "texture_idx": 2 },
			{ "x": 1450.0, "y": 400.0, "w": 100.0, "h": 25.0, "speed": 42.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1450.0, "lane": 11, "texture_idx": 0 },
			{ "x": 1800.0, "y": 400.0, "w": 90.0, "h": 25.0, "speed": 48.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1800.0, "lane": 12, "texture_idx": 1 },
			{ "x": 2200.0, "y": 400.0, "w": 95.0, "h": 25.0, "speed": 36.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2200.0, "lane": 13, "texture_idx": 2 },
			# Lane 3 (y=350) -- upper celebration boats
			{ "x": 450.0, "y": 350.0, "w": 95.0, "h": 25.0, "speed": 50.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 450.0, "lane": 14, "texture_idx": 2 },
			{ "x": 950.0, "y": 350.0, "w": 90.0, "h": 25.0, "speed": 46.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 950.0, "lane": 15, "texture_idx": 0 },
			{ "x": 1600.0, "y": 350.0, "w": 100.0, "h": 25.0, "speed": 40.0, "dir": 1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 1600.0, "lane": 16, "texture_idx": 1 },
			{ "x": 2100.0, "y": 350.0, "w": 90.0, "h": 25.0, "speed": 44.0, "dir": -1, "color": _random_trajinera_color(), "name": _random_trajinera_name(), "start_x": 2100.0, "lane": 17, "texture_idx": 2 },
		],

		"coins": [
			# Fiesta arcs on chinampas and boats -- celebration patterns!
			Vector2(150, 430), Vector2(180, 410), Vector2(210, 430),
			Vector2(350, 440), Vector2(380, 420), Vector2(410, 440),
			Vector2(550, 420), Vector2(580, 400), Vector2(610, 420),
			Vector2(750, 430), Vector2(780, 410), Vector2(810, 430),
			# Mid-section celebration coins
			Vector2(1000, 430), Vector2(1030, 410), Vector2(1060, 430),
			Vector2(1250, 440), Vector2(1280, 420), Vector2(1310, 440),
			Vector2(1500, 420), Vector2(1530, 400), Vector2(1560, 420),
			# Upper platform coins
			Vector2(250, 340), Vector2(560, 330), Vector2(850, 350),
			Vector2(1110, 340), Vector2(1410, 330), Vector2(1710, 350),
			# High altitude coins
			Vector2(450, 250), Vector2(750, 260), Vector2(1200, 240),
			Vector2(1550, 260), Vector2(2100, 250),
			# Dance floor and baby approach
			Vector2(2550, 310), Vector2(2650, 310), Vector2(2750, 310),
			Vector2(2800, 190), Vector2(2850, 310),
		],

		"stars": [
			# 3 elotes placed as milestone rewards
			Vector2(700, 260),
			Vector2(1500, 260),
			Vector2(2600, 280),
		],

		"powerups": [
			# Celebration gifts on chinampas and boats!
			Vector2(300, 440),
			Vector2(660, 380),
			Vector2(1050, 340),
			Vector2(1350, 430),
			Vector2(1700, 350),
			Vector2(2050, 250),
			Vector2(2500, 310),
			Vector2(2750, 190),
		],

		"enemies": [
			# Zero enemies -- this is a celebration!
		],

		"is_boss_level": false,
		"is_upscroller": false,
		"is_escape": false,
		"is_fiesta": true,
	}


# ===========================================================================
# PROCEDURAL GENERATOR -- for levels 7+ fallback
# (original generateProceduralLevel, lines 578-690)
# ===========================================================================

static func generate_procedural_level(level_num: int) -> Dictionary:
	## Generic procedural side-scroller for levels that don't have a specialized
	## generator. Directly ports generateProceduralLevel() from LevelData.js.

	var world_num := _get_world_for_level(level_num)
	var theme := _get_world_theme(world_num)
	var density := calculate_density_multipliers(level_num)

	var base_width: float = 2800.0 + (level_num - 6) * 400.0
	var base_height: float = 700.0 + (100.0 if level_num > 8 else 0.0)
	var breathing_zones := get_breathing_zones(base_width, level_num)

	var platforms: Array = []
	var coins: Array = []
	var stars: Array = []
	var powerups: Array = []
	var enemies: Array = []
	var trajineras: Array = []

	# --- WATER WORLD: Chinampa segments floating on canals (no ground) ---
	var ground_x: float = 0.0
	var ground_y: float = base_height * 0.78  # Chinampas float above water line
	var ground_h: float = 25.0
	var num_ground_segments: int = 5 + int(level_num / 2)

	for i in range(num_ground_segments):
		var segment_width: float = 120.0 + randf() * 80.0  # Smaller, floating chinampas
		platforms.append({
			"x": ground_x, "y": ground_y + randf() * 20.0, "w": segment_width, "h": ground_h,
			"is_chinampa": true
		})
		ground_x += segment_width + 150.0 + randf() * 150.0  # Wider canal gaps

	# Final chinampa to end
	if ground_x < base_width:
		platforms.append({
			"x": ground_x, "y": ground_y, "w": minf(160.0, base_width - ground_x), "h": ground_h,
			"is_chinampa": true
		})

	# --- Floating platforms (scaled by density) ---
	var num_platforms: int = roundi((12 + level_num) * density["platforms"])
	for i in range(num_platforms):
		var px: float = 200.0 + (float(i) / float(num_platforms)) * (base_width - 400.0)
		var py: float = 250.0 + randf() * 350.0
		var pw: float = 80.0 + randf() * 80.0
		platforms.append({
			"x": px, "y": py, "w": pw, "h": 20.0, "is_chinampa": true
		})

	# --- Trajineras for water levels ---
	var num_trajineras: int = mini(5, int(level_num / 2))
	for i in range(num_trajineras):
		var tx: float = 500.0 + i * 500.0
		var tw: float = 80.0 + randf() * 40.0
		trajineras.append({
			"x": tx,
			"y": ground_y - 30.0,
			"w": tw, "h": 25.0,
			"speed": 30.0 + randf() * 30.0,
			"dir": 1 if randf() > 0.5 else -1,
			"color": _random_trajinera_color(),
			"name": _random_trajinera_name(),
			"start_x": tx,
			"lane": i,
		})

	# --- Coins scattered along the level (scaled by density) ---
	var num_coins: int = roundi((15.0 + level_num) * density["coins"])
	for i in range(num_coins):
		coins.append(Vector2(
			150.0 + (float(i) / float(num_coins)) * (base_width - 300.0),
			200.0 + randf() * 400.0
		))

	# --- Stars (3 per level) ---
	stars.append(Vector2(base_width * 0.25, 180.0 + randf() * 150.0))
	stars.append(Vector2(base_width * 0.5, 180.0 + randf() * 150.0))
	stars.append(Vector2(base_width * 0.8, 180.0 + randf() * 150.0))

	# --- Powerups ---
	var num_powerups: int = 2 + int(level_num / 3)
	for i in range(num_powerups):
		powerups.append(Vector2(
			300.0 + i * (base_width / float(num_powerups)),
			250.0 + randf() * 300.0
		))

	# --- Enemies (scaled by density, filtered by breathing zones) ---
	var num_enemies: int = roundi((6.0 + level_num) * density["enemies"])
	for i in range(num_enemies):
		var ex: float = 250.0 + (float(i) / float(num_enemies)) * (base_width - 500.0)

		# Skip enemies that would spawn inside breathing zones
		var in_breathing_zone := false
		for zone in breathing_zones:
			if ex >= zone["start_x"] and ex <= zone["end_x"]:
				in_breathing_zone = true
				break
		if in_breathing_zone:
			continue

		var is_flying: bool = randf() > 0.6
		var enemy_data: Dictionary = {
			"type": "flying" if is_flying else "ground",
			"x": ex,
			"y": (300.0 + randf() * 200.0) if is_flying else (ground_y - 20.0),
			"amplitude": (50.0 + randf() * 50.0) if is_flying else 0.0,
			"speed": (60.0 + randf() * 30.0) if is_flying else 0.0,
			"dir": 1,
		}
		enemies.append(enemy_data)

	var water_y: float = base_height * 0.80  # WATER WORLD: water covers bottom ~20%

	return {
		"width": base_width,
		"height": base_height,
		"player_spawn": Vector2(100, ground_y - 30.0),  # On chinampa, 30px above
		"baby_position": Vector2(base_width - 200.0, 200.0),
		"platforms": platforms,
		"trajineras": trajineras,
		"coins": coins,
		"stars": stars,
		"powerups": powerups,
		"enemies": enemies,
		"theme": theme,
		"water_y": water_y,
		"is_boss_level": false,
		"is_upscroller": false,
		"is_escape": false,
		"is_fiesta": false,
	}


# ===========================================================================
# BOSS ARENA GENERATOR (exact port of BossArenaGenerator.js)
# ===========================================================================

static func generate_boss_arena(level_num: int) -> Dictionary:
	## Generate a boss arena level for level 5 or 10.
	## Exact port from BossArenaGenerator.js.

	# Boss configs (original lines 12-29)
	var configs := {
		5: { "width": 1200.0, "height": 800.0, "world_num": 3, "flying_enemies": 3, "coin_count": 12, "powerup_count": 2 },
		10: { "width": 1400.0, "height": 900.0, "world_num": 6, "flying_enemies": 5, "coin_count": 16, "powerup_count": 2 },
	}

	var cfg: Dictionary = configs.get(level_num, configs[5])
	var w: float = cfg["width"]
	var h: float = cfg["height"]
	var world_num: int = cfg["world_num"]
	var flying_enemy_count: int = cfg["flying_enemies"]
	var theme := _get_world_theme(world_num)

	var platforms: Array = []
	var coins: Array = []
	var stars: Array = []
	var powerups: Array = []
	var enemies: Array = []

	# --- Arena Floor ---
	var floor_h: float = 50.0
	var floor_y: float = h - floor_h
	platforms.append({ "x": 0.0, "y": floor_y, "w": w, "h": floor_h, "is_chinampa": false })

	# --- Tier 1: Low side platforms + center (130px from floor, within 144px jump) ---
	var t1_y: float = floor_y - 130.0
	var side_plat_w: float = roundf(w * 0.14)
	var center_plat_w: float = roundf(w * 0.18)

	# Left side platform
	platforms.append({ "x": roundf(w * 0.06), "y": t1_y, "w": side_plat_w, "h": 20.0, "is_chinampa": true })
	# Center platform
	platforms.append({ "x": roundf(w * 0.41), "y": t1_y - 20.0, "w": center_plat_w, "h": 20.0, "is_chinampa": true })
	# Right side platform
	platforms.append({ "x": roundf(w * 0.80), "y": t1_y, "w": side_plat_w, "h": 20.0, "is_chinampa": true })

	# --- Tier 2: Mid-height platforms (130px from tier 1) ---
	var t2_y: float = floor_y - 260.0
	var mid_plat_w: float = roundf(w * 0.13)

	platforms.append({ "x": roundf(w * 0.14), "y": t2_y, "w": mid_plat_w, "h": 20.0, "is_chinampa": true })
	platforms.append({ "x": roundf(w * 0.41), "y": t2_y - 30.0, "w": center_plat_w, "h": 20.0, "is_chinampa": true })
	platforms.append({ "x": roundf(w * 0.72), "y": t2_y, "w": mid_plat_w, "h": 20.0, "is_chinampa": true })

	# --- Tier 3: High platforms (130px from tier 2) ---
	var t3_y: float = floor_y - 390.0
	var high_plat_w: float = roundf(w * 0.12)

	platforms.append({ "x": roundf(w * 0.26), "y": t3_y, "w": high_plat_w, "h": 20.0, "is_chinampa": true })
	platforms.append({ "x": roundf(w * 0.56), "y": t3_y, "w": high_plat_w, "h": 20.0, "is_chinampa": true })

	# Top center platform -- baby axolotl sits here
	var top_plat_w: float = roundf(w * 0.16)
	var top_plat_x: float = roundf(w * 0.42)
	var top_plat_y: float = t3_y - 120.0
	platforms.append({ "x": top_plat_x, "y": top_plat_y, "w": top_plat_w, "h": 20.0, "is_chinampa": true })

	# Baby platform (slightly offset)
	var baby_plat_w: float = roundf(w * 0.12)
	var baby_plat_x: float = roundf(w * 0.78)
	var baby_plat_y: float = top_plat_y + 20.0
	platforms.append({ "x": baby_plat_x, "y": baby_plat_y, "w": baby_plat_w, "h": 20.0, "is_chinampa": true })

	# --- Side escape route platforms (wall-hugging ledges) ---
	var escape_plat_w: float = 80.0
	# Left wall escapes
	platforms.append({ "x": 20.0, "y": t2_y + 70.0, "w": escape_plat_w, "h": 20.0, "is_chinampa": true })
	platforms.append({ "x": 20.0, "y": t3_y + 60.0, "w": escape_plat_w, "h": 20.0, "is_chinampa": true })
	# Right wall escapes
	platforms.append({ "x": w - escape_plat_w - 20.0, "y": t2_y + 70.0, "w": escape_plat_w, "h": 20.0, "is_chinampa": true })
	platforms.append({ "x": w - escape_plat_w - 20.0, "y": t3_y + 60.0, "w": escape_plat_w, "h": 20.0, "is_chinampa": true })

	# --- Coins ---
	var coin_spacing: float = 32.0

	# Tier 1 coins
	var t1_center_x: float = roundf(w * 0.41) + center_plat_w / 2.0
	coins.append(Vector2(t1_center_x - coin_spacing, t1_y - 60.0))
	coins.append(Vector2(t1_center_x, t1_y - 60.0))
	coins.append(Vector2(t1_center_x + coin_spacing, t1_y - 60.0))

	# Tier 2 coins
	coins.append(Vector2(roundf(w * 0.14) + mid_plat_w / 2.0, t2_y - 40.0))
	coins.append(Vector2(roundf(w * 0.41) + center_plat_w / 2.0, t2_y - 70.0))
	coins.append(Vector2(roundf(w * 0.72) + mid_plat_w / 2.0, t2_y - 40.0))

	# Tier 3 coins
	coins.append(Vector2(roundf(w * 0.26) + high_plat_w / 2.0, t3_y - 40.0))
	coins.append(Vector2(roundf(w * 0.56) + high_plat_w / 2.0, t3_y - 40.0))

	# Top platform coins
	coins.append(Vector2(top_plat_x + top_plat_w / 2.0, top_plat_y - 40.0))

	# Floor-level reward coins (risky, near boss)
	var floor_coin_y: float = floor_y - 40.0
	coins.append(Vector2(roundf(w * 0.25), floor_coin_y))
	coins.append(Vector2(roundf(w * 0.50), floor_coin_y))
	coins.append(Vector2(roundf(w * 0.75), floor_coin_y))

	# Level 10 gets extra coins on escape platforms
	if level_num == 10:
		coins.append(Vector2(60.0, t2_y + 30.0))
		coins.append(Vector2(60.0, t3_y + 20.0))
		coins.append(Vector2(w - 60.0, t2_y + 30.0))
		coins.append(Vector2(w - 60.0, t3_y + 20.0))

	# --- Stars ---
	# Star 1: tucked above the left wall near tier 3
	stars.append(Vector2(50.0, t3_y - 30.0))
	# Star 2: hovering above the top center platform
	stars.append(Vector2(top_plat_x + top_plat_w / 2.0, top_plat_y - 80.0))
	# Star 3: far right, high up above the baby platform
	stars.append(Vector2(w - 60.0, top_plat_y - 50.0))

	# --- Powerups ---
	# Powerup 1: on tier 2 center
	powerups.append(Vector2(roundf(w * 0.41) + center_plat_w / 2.0, t2_y - 40.0))
	# Powerup 2: on the top platform
	powerups.append(Vector2(top_plat_x + top_plat_w / 2.0, top_plat_y - 40.0))

	# --- Flying Enemies ---
	var enemy_y_bands: Array = [
		{ "y": t1_y - 60.0, "amp": 60.0, "spd": 65.0 },
		{ "y": t2_y - 50.0, "amp": 70.0, "spd": 70.0 },
		{ "y": t2_y + 40.0, "amp": 50.0, "spd": 60.0 },
		{ "y": t3_y + 50.0, "amp": 80.0, "spd": 75.0 },
		{ "y": t3_y - 40.0, "amp": 60.0, "spd": 80.0 },
	]

	for i in range(flying_enemy_count):
		var band: Dictionary = enemy_y_bands[i % enemy_y_bands.size()]
		var ex: float = roundf(w * 0.2 + (w * 0.6) * (float(i) / maxf(float(flying_enemy_count - 1), 1.0)))
		enemies.append({
			"type": "flying",
			"x": ex,
			"y": band["y"],
			"amplitude": band["amp"],
			"speed": band["spd"],
			"dir": 1,
		})

	# --- Trajineras (iconic Xochimilco boats near the arena floor) ---
	var trajineras: Array = []
	var trajinera_count: int = 4 if level_num == 5 else 5
	var traj_y: float = floor_y - 30.0  # Slightly above the floor, at water line
	for i in range(trajinera_count):
		var fraction: float = float(i + 1) / float(trajinera_count + 1)
		var tx: float = roundf(w * fraction)
		trajineras.append({
			"x": tx,
			"y": traj_y + roundf(randf() * 10.0 - 5.0),
			"w": 80.0 + roundf(randf() * 20.0),
			"h": 25.0,
			"speed": 25.0 + roundf(randf() * 15.0),
			"dir": 1 if i % 2 == 0 else -1,
			"color": _random_trajinera_color(),
			"name": _random_trajinera_name(),
			"start_x": tx,
			"lane": i,
			"texture_idx": i % 3,
		})

	# --- Spawn positions ---
	var player_spawn := Vector2(100.0, floor_y - 60.0)
	var baby_position := Vector2(baby_plat_x + baby_plat_w / 2.0, baby_plat_y - 30.0)
	var boss_spawn := Vector2(roundf(w / 2.0), floor_y - 80.0)

	return {
		"width": w,
		"height": h,
		"player_spawn": player_spawn,
		"baby_position": baby_position,
		"boss_spawn": boss_spawn,
		"platforms": platforms,
		"trajineras": trajineras,
		"coins": coins,
		"stars": stars,
		"powerups": powerups,
		"enemies": enemies,
		"theme": theme,
		"water_y": h * 0.85,  # WATER WORLD: water visible around boss arena
		"is_boss_level": true,
		"is_upscroller": false,
		"is_escape": false,
		"is_fiesta": false,
	}


# ===========================================================================
# UPSCROLLER GENERATOR (exact port of UpscrollerGenerator.js)
# ===========================================================================

static func generate_upscroller_level(level_num: int) -> Dictionary:
	## Generate an upscroller level for level 3 or 8.
	## Exact port from UpscrollerGenerator.js.

	# Upscroller configs (original lines 16-37)
	var configs := {
		3: {
			"width": 800.0, "height": 2500.0, "world_num": 2,
			"ground_enemies": 4, "flying_enemies": 3, "powerup_count": 2,
			"platform_vertical_gap": 120.0, "rest_platform_interval": 450.0,
		},
		8: {
			"width": 800.0, "height": 3000.0, "world_num": 5,
			"ground_enemies": 5, "flying_enemies": 4, "powerup_count": 3,
			"platform_vertical_gap": 130.0, "rest_platform_interval": 420.0,
		},
	}

	var cfg: Dictionary = configs.get(level_num, configs[3])
	var w: float = cfg["width"]
	var h: float = cfg["height"]
	var world_num: int = cfg["world_num"]
	var ground_enemy_count: int = cfg["ground_enemies"]
	var flying_enemy_count: int = cfg["flying_enemies"]
	var powerup_count: int = cfg["powerup_count"]
	var platform_vertical_gap: float = cfg["platform_vertical_gap"]
	var rest_platform_interval: float = cfg["rest_platform_interval"]

	var theme := _get_world_theme(world_num)

	var platforms: Array = []
	var coins: Array = []
	var stars: Array = []
	var powerups: Array = []
	var enemies: Array = []

	# --- WATER WORLD: Starting chinampas at the water surface (no solid ground) ---
	var ground_h: float = 25.0
	var ground_y: float = h - 70.0
	platforms.append({ "x": 200.0, "y": ground_y, "w": 180.0, "h": ground_h, "is_chinampa": true })
	platforms.append({ "x": 500.0, "y": ground_y + 10.0, "w": 150.0, "h": ground_h, "is_chinampa": true })

	# --- Ascending zigzag platforms ---
	var margin: float = 60.0
	var min_plat_w: float = 100.0
	var max_plat_w: float = 160.0
	var rest_plat_w: float = 300.0
	var top_zone: float = 120.0

	var current_y: float = ground_y - platform_vertical_gap
	var left_side: bool = true
	var last_rest_y: float = ground_y

	while current_y > top_zone + platform_vertical_gap:
		var distance_since_rest: float = last_rest_y - current_y
		var is_rest_platform: bool = distance_since_rest >= rest_platform_interval

		if is_rest_platform:
			# Rest platform -- wider, centered or slightly offset
			var rest_x: float = roundf((w - rest_plat_w) / 2.0) + (-40.0 if left_side else 40.0)
			var clamped_x: float = maxf(margin, minf(w - rest_plat_w - margin, rest_x))
			platforms.append({ "x": clamped_x, "y": current_y, "w": rest_plat_w, "h": 20.0, "is_chinampa": true })

			# Place a coin line on rest platforms
			var coin_start_x: float = clamped_x + 30.0
			var cx: float = coin_start_x
			while cx < clamped_x + rest_plat_w - 30.0:
				coins.append(Vector2(cx, current_y - 40.0))
				cx += 32.0

			last_rest_y = current_y
		else:
			# Normal zigzag platform
			var plat_w: float = min_plat_w + roundf(randf() * (max_plat_w - min_plat_w))
			var plat_x: float

			if left_side:
				plat_x = margin + roundf(randf() * (w / 2.0 - plat_w - margin))
			else:
				plat_x = roundf(w / 2.0) + roundf(randf() * (w / 2.0 - plat_w - margin))

			# Clamp to valid range
			plat_x = maxf(margin, minf(w - plat_w - margin, plat_x))

			platforms.append({ "x": plat_x, "y": current_y, "w": plat_w, "h": 20.0, "is_chinampa": true })

			# Breadcrumb coin above each regular platform
			coins.append(Vector2(plat_x + plat_w / 2.0, current_y - 40.0))

		left_side = not left_side
		current_y -= platform_vertical_gap

	# --- Top platform for baby axolotl ---
	var top_plat_w: float = 250.0
	var top_plat_x: float = roundf((w - top_plat_w) / 2.0)
	var top_plat_y: float = top_zone
	platforms.append({ "x": top_plat_x, "y": top_plat_y, "w": top_plat_w, "h": 20.0, "is_chinampa": true })

	# --- Stars -- 3 at various heights ---
	# Star 1: low section, tucked near a wall
	stars.append(Vector2(w - 60.0, roundf(h * 0.75)))
	# Star 2: mid section, floating off the main path
	stars.append(Vector2(50.0, roundf(h * 0.45)))
	# Star 3: near the top, hard to reach without a super jump
	stars.append(Vector2(w - 50.0, roundf(h * 0.18)))

	# --- Powerups ---
	var powerup_heights: Array = []
	for i in range(powerup_count):
		var fraction: float = float(i + 1) / float(powerup_count + 1)
		var py: float = roundf(ground_y - (ground_y - top_plat_y) * fraction)
		powerup_heights.append(py)

	# Place powerups near platforms at those heights (find closest platform)
	for target_y in powerup_heights:
		var best_plat: Dictionary = {}
		var best_dist: float = INF
		for p in platforms:
			if p["h"] > 30.0:
				continue  # Skip ground
			var dist: float = absf(p["y"] - target_y)
			if dist < best_dist:
				best_dist = dist
				best_plat = p
		if not best_plat.is_empty():
			powerups.append(Vector2(best_plat["x"] + best_plat["w"] / 2.0, best_plat["y"] - 40.0))

	# --- Enemies ---

	# Ground enemies on platforms -- distributed evenly across height
	var plat_candidates: Array = []
	for p in platforms:
		if p["h"] <= 20.0 and p["w"] >= 120.0 and p["y"] > top_zone + 200.0:
			plat_candidates.append(p)

	for i in range(mini(ground_enemy_count, plat_candidates.size())):
		var target_idx: int = roundi(float(i) / float(ground_enemy_count) * float(plat_candidates.size() - 1))
		var plat: Dictionary = plat_candidates[mini(target_idx, plat_candidates.size() - 1)]
		enemies.append({
			"type": "platform",
			"x": plat["x"] + plat["w"] / 2.0,
			"y": plat["y"] - 20.0,
			"speed": 0.0,
			"dir": 1,
			"amplitude": 0.0,
		})

	# Flying enemies in the gaps between platforms
	for i in range(flying_enemy_count):
		var fraction: float = float(i + 1) / float(flying_enemy_count + 1)
		var fy: float = roundf(ground_y - (ground_y - top_plat_y - 100.0) * fraction)
		enemies.append({
			"type": "flying",
			"x": roundf(w * 0.3 + randf() * w * 0.4),
			"y": fy,
			"amplitude": 60.0 + roundf(randf() * 40.0),
			"speed": 50.0 + roundf(randf() * 30.0),
			"dir": 1,
		})

	# --- Trajineras (horizontal rescue platforms at various heights) ---
	# In upscroller levels, trajineras drift side to side between the zigzag
	# platforms, giving the player something to land on when they miss a jump.
	var trajineras: Array = []
	var traj_count: int = 6 if level_num == 8 else 4
	for i in range(traj_count):
		var fraction: float = float(i + 1) / float(traj_count + 1)
		var ty: float = roundf(ground_y - (ground_y - top_plat_y) * fraction)
		# Alternate between left-ish and right-ish starting positions
		var tx: float
		if i % 2 == 0:
			tx = roundf(w * 0.15 + randf() * w * 0.2)
		else:
			tx = roundf(w * 0.55 + randf() * w * 0.2)
		trajineras.append({
			"x": tx,
			"y": ty,
			"w": 90.0 + roundf(randf() * 20.0),
			"h": 25.0,
			"speed": 35.0 + roundf(randf() * 20.0),
			"dir": 1 if i % 2 == 0 else -1,
			"color": _random_trajinera_color(),
			"name": _random_trajinera_name(),
			"start_x": tx,
			"lane": i,
			"texture_idx": i % 3,
		})

	# --- Spawn positions ---
	var player_spawn := Vector2(roundf(w / 2.0), ground_y - 30.0)  # On chinampa
	var baby_position := Vector2(top_plat_x + top_plat_w / 2.0, top_plat_y - 30.0)

	return {
		"width": w,
		"height": h,
		"player_spawn": player_spawn,
		"baby_position": baby_position,
		"platforms": platforms,
		"trajineras": trajineras,
		"coins": coins,
		"stars": stars,
		"powerups": powerups,
		"enemies": enemies,
		"theme": theme,
		"water_y": h - 40.0,  # WATER WORLD: rising water starts just below starting chinampas
		"is_boss_level": false,
		"is_upscroller": true,
		"is_escape": false,
		"is_fiesta": false,
	}


# ===========================================================================
# ESCAPE LEVEL GENERATOR (exact port of EscapeGenerator.js)
# ===========================================================================

static func generate_escape_level(level_num: int) -> Dictionary:
	## Generate an escape level for level 7 or 9.
	## Exact port from EscapeGenerator.js with three segment types:
	##   gap_run, platform_hop, mixed

	# Escape configs (original lines 21-42)
	var configs := {
		7: {
			"width": 3500.0, "height": 700.0, "world_num": 4,
			"escape_speed": ESCAPE_FLOOD_SPEED_BASE,
			"ground_enemies": 5, "flying_enemies": 3,
			"powerup_count": 2, "segment_count": 6,
		},
		9: {
			"width": 4000.0, "height": 700.0, "world_num": 5,
			"escape_speed": ESCAPE_FLOOD_SPEED_FAST,
			"ground_enemies": 6, "flying_enemies": 4,
			"powerup_count": 2, "segment_count": 7,
		},
	}

	var cfg: Dictionary = configs.get(level_num, configs[7])
	var w: float = cfg["width"]
	var h: float = cfg["height"]
	var world_num: int = cfg["world_num"]
	var escape_speed: float = cfg["escape_speed"]
	var ground_enemy_count: int = cfg["ground_enemies"]
	var flying_enemy_count: int = cfg["flying_enemies"]
	var powerup_count: int = cfg["powerup_count"]
	var segment_count: int = cfg["segment_count"]

	var theme := _get_world_theme(world_num)

	var platforms: Array = []
	var coins: Array = []
	var stars: Array = []
	var powerups: Array = []
	var enemies: Array = []

	var ground_h: float = 25.0  # WATER WORLD: thin chinampas, not thick ground
	var ground_y: float = h * 0.75  # Chinampas float at ~75% height, above water
	var segment_width: float = roundf(w / float(segment_count))

	# Segment types cycle: gap_run, platform_hop, mixed
	var segment_types: Array[String] = ["gap_run", "platform_hop", "mixed"]

	# --- Generate segments left to right ---
	var cursor_x: float = 0.0

	for seg in range(segment_count):
		var seg_type: String = segment_types[seg % segment_types.size()]
		var seg_start_x: float = cursor_x
		var seg_end_x: float = minf(cursor_x + segment_width, w)

		match seg_type:
			"gap_run":
				_generate_gap_run_segment(seg_start_x, seg_end_x, ground_y, ground_h, platforms, coins)
			"platform_hop":
				_generate_platform_hop_segment(seg_start_x, seg_end_x, ground_y, h, platforms, coins)
			"mixed":
				_generate_mixed_segment(seg_start_x, seg_end_x, ground_y, ground_h, h, platforms, coins)

		cursor_x = seg_end_x

	# --- Starting safe zone ---
	var has_start_ground := false
	for p in platforms:
		if p["x"] <= 80.0 and p["y"] == ground_y and p["h"] == ground_h:
			has_start_ground = true
			break
	if not has_start_ground:
		platforms.insert(0, { "x": 50.0, "y": ground_y, "w": 160.0, "h": ground_h, "is_chinampa": true })

	# --- Ending safe zone ---
	var has_end_ground := false
	for p in platforms:
		if p["x"] + p["w"] >= w - 100.0 and p["y"] == ground_y and p["h"] == ground_h:
			has_end_ground = true
			break
	if not has_end_ground:
		platforms.append({ "x": w - 200.0, "y": ground_y, "w": 160.0, "h": ground_h, "is_chinampa": true })

	# --- Stars -- one per third of the level ---
	stars.append(Vector2(roundf(w * 0.17), 180.0))
	stars.append(Vector2(roundf(w * 0.50), 160.0))
	stars.append(Vector2(roundf(w * 0.83), 170.0))

	# --- Powerups ---
	for i in range(powerup_count):
		var fraction: float = float(i + 1) / float(powerup_count + 1)
		var px: float = roundf(w * fraction)
		powerups.append(Vector2(px, 280.0 + roundf(randf() * 80.0)))

	# --- Enemies ---

	# Ground enemies distributed along ground segments
	var ground_platforms: Array = []
	for p in platforms:
		if p["h"] == ground_h and p["w"] >= 200.0:
			ground_platforms.append(p)

	for i in range(mini(ground_enemy_count, ground_platforms.size())):
		var idx: int = roundi(float(i) / float(ground_enemy_count) * float(ground_platforms.size() - 1))
		var plat: Dictionary = ground_platforms[mini(idx, ground_platforms.size() - 1)]
		enemies.append({
			"type": "ground",
			"x": plat["x"] + plat["w"] / 2.0 + roundf((randf() - 0.5) * plat["w"] * 0.4),
			"y": ground_y - 20.0,
			"speed": 0.0,
			"dir": 1,
			"amplitude": 0.0,
		})

	# Flying enemies in the upper half
	for i in range(flying_enemy_count):
		var fraction: float = float(i + 1) / float(flying_enemy_count + 1)
		enemies.append({
			"type": "flying",
			"x": roundf(w * fraction),
			"y": 250.0 + roundf(randf() * 150.0),
			"amplitude": 40.0 + roundf(randf() * 40.0),
			"speed": 60.0 + roundf(randf() * 30.0),
			"dir": 1,
		})

	# --- Trajineras (emergency platforms in water gaps between ground segments) ---
	# In escape levels the water is rising, so trajineras in the gaps give
	# panicked players something to land on. Faster speeds to match the urgency.
	var trajineras: Array = []

	# Find gaps between ground-level platforms by sorting them by x position
	var ground_sorted: Array = []
	for p in platforms:
		if p["h"] == ground_h:
			ground_sorted.append(p)
	ground_sorted.sort_custom(func(a, b): return a["x"] < b["x"])

	var traj_lane: int = 0
	for gi in range(ground_sorted.size() - 1):
		var gap_start: float = ground_sorted[gi]["x"] + ground_sorted[gi]["w"]
		var gap_end: float = ground_sorted[gi + 1]["x"]
		var gap_width: float = gap_end - gap_start

		# Only place trajineras in gaps wide enough to matter (>= 100px)
		if gap_width >= 100.0:
			var tx: float = gap_start + gap_width / 2.0 - 45.0
			trajineras.append({
				"x": tx,
				"y": ground_y - 25.0,
				"w": 90.0 + roundf(randf() * 15.0),
				"h": 25.0,
				"speed": 40.0 + roundf(randf() * 20.0),
				"dir": 1 if traj_lane % 2 == 0 else -1,
				"color": _random_trajinera_color(),
				"name": _random_trajinera_name(),
				"start_x": tx,
				"lane": traj_lane,
				"texture_idx": traj_lane % 3,
			})
			traj_lane += 1

	# --- Spawn positions ---
	var player_spawn := Vector2(100.0, ground_y - 30.0)  # On chinampa
	var baby_position := Vector2(w - 150.0, ground_y - 60.0)

	return {
		"width": w,
		"height": h,
		"player_spawn": player_spawn,
		"baby_position": baby_position,
		"platforms": platforms,
		"trajineras": trajineras,
		"coins": coins,
		"stars": stars,
		"powerups": powerups,
		"enemies": enemies,
		"theme": theme,
		"water_y": h * 0.78,  # WATER WORLD: water prominent in escape levels
		"escape_speed": escape_speed,
		"is_boss_level": false,
		"is_upscroller": false,
		"is_escape": true,
		"is_fiesta": false,
	}


# ===========================================================================
# Escape Segment Generators (internal helpers, ports of JS segment functions)
# ===========================================================================

static func _generate_gap_run_segment(
	start_x: float, end_x: float,
	ground_y: float, ground_h: float,
	platforms: Array, coins: Array
) -> void:
	## Gap Run -- chinampas with canal gaps between them (WATER WORLD).
	## Port of generateGapRunSegment() from EscapeGenerator.js.
	var x: float = start_x

	while x < end_x - 80.0:
		var plat_w: float = 100.0 + roundf(randf() * 80.0)  # Smaller chinampas
		var clamped_w: float = minf(plat_w, end_x - x)

		platforms.append({ "x": x, "y": ground_y + randf() * 15.0, "w": clamped_w, "h": ground_h, "is_chinampa": true })

		# Coins along the ground
		var cx: float = x + 40.0
		while cx < x + clamped_w - 40.0:
			coins.append(Vector2(cx, ground_y - 40.0))
			cx += 48.0

		# Gap
		var gap_w: float = 80.0 + roundf(randf() * 60.0)
		x += clamped_w + gap_w

		# Floating coin arc over gap to guide the player
		if x - gap_w > start_x and x < end_x:
			coins.append(Vector2(x - gap_w / 2.0, ground_y - 100.0))


static func _generate_platform_hop_segment(
	start_x: float, end_x: float,
	ground_y: float, level_height: float,
	platforms: Array, coins: Array
) -> void:
	## Platform Hop -- no ground, only floating platforms.
	## Port of generatePlatformHopSegment() from EscapeGenerator.js.
	var x: float = start_x + 40.0
	var platform_count: int = roundi((end_x - start_x) / 160.0)

	for i in range(platform_count):
		if x >= end_x - 60.0:
			break
		var plat_w: float = 80.0 + roundf(randf() * 60.0)
		var plat_y: float = ground_y - 100.0 - roundf(randf() * 200.0)

		platforms.append({ "x": x, "y": plat_y, "w": plat_w, "h": 20.0, "is_chinampa": true })

		# Coin on each platform
		coins.append(Vector2(x + plat_w / 2.0, plat_y - 40.0))

		# Occasional higher alternate platform
		if i % 3 == 1:
			var alt_y: float = plat_y - 100.0 - roundf(randf() * 60.0)
			platforms.append({ "x": x + 20.0, "y": alt_y, "w": plat_w - 20.0, "h": 20.0, "is_chinampa": true })
			coins.append(Vector2(x + plat_w / 2.0, alt_y - 30.0))

		x += plat_w + 80.0 + roundf(randf() * 60.0)


static func _generate_mixed_segment(
	start_x: float, end_x: float,
	ground_y: float, ground_h: float, level_height: float,
	platforms: Array, coins: Array
) -> void:
	## Mixed -- chinampa islands with floating platform shortcuts above (WATER WORLD).
	## Port of generateMixedSegment() from EscapeGenerator.js.
	var x: float = start_x

	while x < end_x - 100.0:
		# Chinampa island
		var island_w: float = 120.0 + roundf(randf() * 80.0)  # Smaller canal islands
		var clamped_w: float = minf(island_w, end_x - x)

		platforms.append({ "x": x, "y": ground_y + randf() * 15.0, "w": clamped_w, "h": ground_h, "is_chinampa": true })

		# Ground coins
		var cx: float = x + 30.0
		while cx < x + clamped_w - 30.0:
			coins.append(Vector2(cx, ground_y - 40.0))
			cx += 48.0

		# Floating shortcut platform above each island
		var float_y: float = ground_y - 180.0 - roundf(randf() * 80.0)
		var float_w: float = 100.0 + roundf(randf() * 60.0)
		platforms.append({ "x": x + 40.0, "y": float_y, "w": float_w, "h": 20.0, "is_chinampa": true })
		coins.append(Vector2(x + 40.0 + float_w / 2.0, float_y - 30.0))

		# Gap between islands
		var gap_w: float = 100.0 + roundf(randf() * 80.0)
		x += clamped_w + gap_w

		# Guide coin over gap
		if x - gap_w > start_x and x < end_x:
			coins.append(Vector2(x - gap_w / 2.0, ground_y - 80.0))


# ===========================================================================
# LA FIESTA GENERATOR (exact port of generateFiestaLevel, LevelData.js 693-774)
# ===========================================================================

static func generate_fiesta_level() -> Dictionary:
	## Level 11: La Fiesta -- celebration finale with NO enemies and lots of
	## trajineras, flowers, and powerups. Direct port from LevelData.js.

	var w: float = 3000.0
	var h: float = 600.0
	var water_y: float = h * 0.77  # WATER WORLD: celebration on canal water!

	var platforms: Array = []
	var trajineras: Array = []
	var coins: Array = []
	var stars: Array = []
	var enemies: Array = []  # NO ENEMIES - pure celebration!
	var powerups: Array = []

	# Starting platform
	platforms.append({ "x": 50.0, "y": water_y - 60.0, "w": 200.0, "h": 40.0, "is_chinampa": true })

	# Flower arch at entrance (15 coins in arc)
	for i in range(15):
		coins.append(Vector2(
			150.0 + i * 20.0,
			water_y - 100.0 - sin((float(i) / 14.0) * PI) * 100.0
		))

	# 6 trajinera lanes with 54 total boats (original lines 714-739)
	var lanes: Array = [
		{ "y": water_y - 80.0,  "dir": 1,  "base_speed": 25.0, "boats": 12 },
		{ "y": water_y - 140.0, "dir": -1, "base_speed": 30.0, "boats": 10 },
		{ "y": water_y - 200.0, "dir": 1,  "base_speed": 35.0, "boats": 10 },
		{ "y": water_y - 260.0, "dir": -1, "base_speed": 28.0, "boats": 8 },
		{ "y": water_y - 320.0, "dir": 1,  "base_speed": 32.0, "boats": 8 },
		{ "y": water_y - 380.0, "dir": -1, "base_speed": 22.0, "boats": 6 },
	]

	for lane_idx in range(lanes.size()):
		var lane: Dictionary = lanes[lane_idx]
		var boat_count: int = lane["boats"]
		var spacing: float = (w - 600.0) / maxf(1.0, float(boat_count))

		for i in range(boat_count):
			var start_offset: float = (i * spacing) + (0.0 if lane_idx % 2 == 0 else spacing / 2.0)
			var x_pos: float = 300.0 + start_offset
			var boat_w: float = 120.0 + randf() * 40.0

			trajineras.append({
				"x": x_pos,
				"y": lane["y"] + (randf() - 0.5) * 15.0,
				"w": boat_w, "h": 28.0,
				"speed": lane["base_speed"] + randf() * 10.0,
				"dir": lane["dir"],
				"color": _random_trajinera_color(),
				"name": _random_trajinera_name(),
				"start_x": x_pos,
				"lane": lane_idx,
			})

	# 100 scattered flowers (coins)
	for i in range(100):
		coins.append(Vector2(
			300.0 + randf() * (w - 600.0),
			water_y - 100.0 - randf() * 300.0
		))

	# 3 easy celebration stars
	stars.append(Vector2(600.0, water_y - 200.0))
	stars.append(Vector2(1500.0, water_y - 250.0))
	stars.append(Vector2(2400.0, water_y - 200.0))

	# Dance floor platform
	platforms.append({ "x": w - 400.0, "y": water_y - 60.0, "w": 350.0, "h": 50.0, "is_chinampa": true })

	# Flower circle around dance floor (20 coins)
	for i in range(20):
		var angle: float = (float(i) / 20.0) * PI * 2.0
		coins.append(Vector2(
			w - 225.0 + cos(angle) * 120.0,
			water_y - 150.0 + sin(angle) * 50.0
		))

	# Lots of powerups
	powerups.append(Vector2(150.0, water_y - 100.0))
	powerups.append(Vector2(250.0, water_y - 150.0))
	var px: float = 400.0
	while px < w - 400.0:
		powerups.append(Vector2(px, water_y - 120.0 - randf() * 200.0))
		px += 200.0

	# Theme for fiesta
	var theme := _get_world_theme(6)

	return {
		"width": w,
		"height": h,
		"player_spawn": Vector2(150.0, water_y - 100.0),
		"baby_position": Vector2(w - 225.0, water_y - 100.0),
		"platforms": platforms,
		"trajineras": trajineras,
		"coins": coins,
		"stars": stars,
		"powerups": powerups,
		"enemies": enemies,
		"theme": theme,
		"water_y": water_y,
		"is_boss_level": false,
		"is_upscroller": false,
		"is_escape": false,
		"is_fiesta": true,
	}


# ===========================================================================
# Utility: Generate a side-scroller level procedurally (from user spec)
# This is the lane-based generator described in the prompt, useful for
# future generated side-scroller content beyond the static levels.
# ===========================================================================

static func generate_level(level_num: int) -> Dictionary:
	## Lane-based side-scroller generator. Uses the 6-lane trajinera system
	## described in the original game.js generateLevel function.

	var w: float = 2000.0 + level_num * 200.0
	var h: float = 600.0
	var water_y: float = h - 40.0

	var density := calculate_density_multipliers(level_num)
	var breathing_zones := get_breathing_zones(w, level_num)
	var world_num := _get_world_for_level(level_num)
	var theme := _get_world_theme(world_num)

	var platforms: Array = []
	var trajineras: Array = []
	var coins: Array = []
	var stars: Array = []
	var enemies: Array = []
	var powerups: Array = []

	# --- Handcrafted intro (first 300px) ---
	var intro := create_intro_section(level_num, water_y)
	platforms.append_array(intro["platforms"])
	coins.append_array(intro["coins"])
	powerups.append_array(intro["powerups"])

	# --- Handcrafted outro (last 300px) ---
	var outro := create_outro_section(level_num, w, water_y)
	platforms.append_array(outro["platforms"])
	coins.append_array(outro["coins"])

	var baby_position: Vector2 = outro["baby_position"]

	# --- Middle section: 6 lanes of trajineras ---
	var lane_defs: Array = [
		{ "y": water_y - 80.0,  "dir": 1,  "base_speed": 30.0, "boat_count": 5 + level_num },
		{ "y": water_y - 150.0, "dir": -1, "base_speed": 40.0, "boat_count": 4 + level_num },
		{ "y": water_y - 220.0, "dir": 1,  "base_speed": 50.0, "boat_count": 4 + level_num },
		{ "y": water_y - 290.0, "dir": -1, "base_speed": 45.0, "boat_count": 3 + level_num },
		{ "y": water_y - 360.0, "dir": 1,  "base_speed": 55.0, "boat_count": 3 + level_num },
		{ "y": water_y - 420.0, "dir": -1, "base_speed": 35.0, "boat_count": 2 + int(level_num / 2) },
	]

	var middle_start: float = 300.0
	var middle_end: float = w - 300.0
	var middle_width: float = middle_end - middle_start

	for lane_idx in range(lane_defs.size()):
		var lane: Dictionary = lane_defs[lane_idx]
		var boat_count: int = lane["boat_count"]
		var spacing: float = middle_width / maxf(1.0, float(boat_count))

		for i in range(boat_count):
			var boat_x: float = middle_start + i * spacing + randf() * (spacing * 0.3)
			var boat_w: float = 80.0 + randf() * 40.0
			trajineras.append({
				"x": boat_x,
				"y": lane["y"] + (randf() - 0.5) * 10.0,
				"w": boat_w, "h": 25.0,
				"speed": lane["base_speed"] + randf() * 15.0,
				"dir": lane["dir"],
				"color": _random_trajinera_color(),
				"name": _random_trajinera_name(),
				"start_x": boat_x,
				"lane": lane_idx,
			})

	# --- Coins: 15 + levelNum * 3 base count, scaled by density ---
	var base_coin_count: int = roundi((15 + level_num * 3) * density["coins"])
	for i in range(base_coin_count):
		coins.append(Vector2(
			middle_start + (float(i) / float(base_coin_count)) * middle_width,
			water_y - 100.0 - randf() * 350.0
		))

	# --- Stars: 3 per level at 20%, 50%, 80% of middle width ---
	stars.append(Vector2(middle_start + middle_width * 0.2, water_y - 300.0 - randf() * 100.0))
	stars.append(Vector2(middle_start + middle_width * 0.5, water_y - 300.0 - randf() * 100.0))
	stars.append(Vector2(middle_start + middle_width * 0.8, water_y - 300.0 - randf() * 100.0))

	# --- Enemies: flying enemies filtered by breathing zones ---
	var settings := _get_difficulty_settings()
	var difficulty_val: float = settings.get("enemy_mult", 1.0)
	var num_enemies: int = roundi((2.0 + difficulty_val * 3.0) * settings.get("enemy_mult", 1.0) * density["enemies"])

	for i in range(num_enemies):
		var ex: float = middle_start + (float(i) / maxf(1.0, float(num_enemies))) * middle_width

		# Skip enemies in breathing zones
		var in_zone := false
		for zone in breathing_zones:
			if ex >= zone["start_x"] and ex <= zone["end_x"]:
				in_zone = true
				break
		if in_zone:
			continue

		enemies.append({
			"type": "flying",
			"x": ex,
			"y": water_y - 150.0 - randf() * 300.0,
			"amplitude": 40.0 + randf() * 60.0,
			"speed": 50.0 + randf() * 40.0,
			"dir": 1 if randf() > 0.5 else -1,
		})

	# --- Powerups: 3 + difficulty * 2, one at start, scattered middle, one at end ---
	var num_powerups: int = roundi(3.0 + difficulty_val * 2.0)
	# One at start (already added in intro for levels 3+, add another if not)
	if level_num < 3:
		powerups.append(Vector2(200.0, water_y - 120.0))
	# Scattered in middle
	for i in range(maxi(0, num_powerups - 2)):
		powerups.append(Vector2(
			middle_start + (float(i + 1) / float(num_powerups)) * middle_width,
			water_y - 100.0 - randf() * 250.0
		))
	# One at end
	powerups.append(Vector2(w - 200.0, water_y - 120.0))

	return {
		"width": w,
		"height": h,
		"player_spawn": Vector2(100.0, water_y - 100.0),
		"baby_position": baby_position,
		"platforms": platforms,
		"trajineras": trajineras,
		"coins": coins,
		"stars": stars,
		"powerups": powerups,
		"enemies": enemies,
		"theme": theme,
		"water_y": water_y,
		"is_boss_level": false,
		"is_upscroller": false,
		"is_escape": false,
		"is_fiesta": false,
	}


# ===========================================================================
# Difficulty settings helper -- reads from GameState autoload
# ===========================================================================

static func _get_difficulty_settings() -> Dictionary:
	## Safely read difficulty settings from GameState. Returns medium defaults
	## if GameState is not yet loaded.
	var gs_node = Engine.get_main_loop()
	if gs_node and gs_node.has_method("get"):
		pass  # Not a simple singleton access

	# Try the autoload path: /root/GameState
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root.has_node("GameState"):
		var gs = tree.root.get_node("GameState")
		if gs.has_method("get_settings"):
			return gs.get_settings()

	# Fallback: medium defaults
	return {
		"lives": 3,
		"starting_super_jumps": 2,
		"starting_mace_attacks": 1,
		"platform_density": 1.0,
		"platform_gap_mult": 1.0,
		"enemy_mult": 1.0,
		"powerup_mult": 1.0,
		"sky_platforms": 3,
		"coin_mult": 1.0,
		"boss_health": { 5: 4, 10: 5 },
	}


# ===========================================================================
# Level metadata queries (useful for UI, story scenes, etc.)
# ===========================================================================

static func is_boss_level(level_num: int) -> bool:
	return level_num == 5 or level_num == 10


static func is_upscroller_level(level_num: int) -> bool:
	return level_num == 3 or level_num == 8


static func is_escape_level(level_num: int) -> bool:
	return level_num == 7 or level_num == 9


static func is_fiesta_level(level_num: int) -> bool:
	return level_num == 11


static func get_level_type_name(level_num: int) -> String:
	if is_boss_level(level_num):
		return "boss"
	if is_upscroller_level(level_num):
		return "upscroller"
	if is_escape_level(level_num):
		return "escape"
	if is_fiesta_level(level_num):
		return "fiesta"
	return "side_scroller"

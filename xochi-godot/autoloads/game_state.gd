extends Node
## Global game state singleton -- exact port from original game.js (lines 82-253).
## Manages player progress, difficulty settings, world palettes, and save/load.

# --- Player / Session State ---
var current_level: int = 1
var total_levels: int = 11
var flowers: int = 0
var lives: int = 3
var stars: Array = []  # Collected elote IDs
var rescued_babies: Array = []
var super_jumps: int = 2  # Medium default
var mace_attacks: int = 1
var score: int = 0
var high_score: int = 0
var music_enabled: bool = true
var sfx_enabled: bool = true
var difficulty: String = "medium"

# --- Difficulty Settings (exact copy from original game.js) ---
var DIFFICULTY_SETTINGS: Dictionary = {
	"easy": {
		"lives": 5,
		"starting_super_jumps": 3,
		"starting_mace_attacks": 2,
		"platform_density": 1.2,
		"platform_gap_mult": 0.85,
		"enemy_mult": 0.7,
		"powerup_mult": 1.3,
		"sky_platforms": 2,
		"coin_mult": 1.2,
		"boss_health": { 5: 3, 10: 4 }
	},
	"medium": {
		"lives": 3,
		"starting_super_jumps": 2,
		"starting_mace_attacks": 1,
		"platform_density": 1.0,
		"platform_gap_mult": 1.0,
		"enemy_mult": 1.0,
		"powerup_mult": 1.0,
		"sky_platforms": 3,
		"coin_mult": 1.0,
		"boss_health": { 5: 4, 10: 5 }
	},
	"hard": {
		"lives": 2,
		"starting_super_jumps": 1,
		"starting_mace_attacks": 1,
		"platform_density": 0.9,
		"platform_gap_mult": 1.1,
		"enemy_mult": 1.2,
		"powerup_mult": 0.8,
		"sky_platforms": 4,
		"coin_mult": 0.9,
		"boss_health": { 5: 5, 10: 7 }
	}
}

# --- WORLDS -- exact palette from original game.js (lines 169-253) ---
var WORLDS: Dictionary = {
	1: {
		"name": "Canal Dawn",
		"subtitle": "El Amanecer",
		"sky": [Color("ffccbb"), Color("ffaa99"), Color("ff8877"), Color("dd6655"), Color("aa5544"), Color("774433")],
		"mountain": Color("446655"), "hill": Color("558866"), "water_color": Color("558899"),
		"background": Color("FFB6C1"), "foreground": Color("8B4513"),
		"midground": Color("D2691E"),
		"vegetation": [Color("9ACD32"), Color("228B22"), Color("6B8E23")],
		"accent": Color("FFD700"), "fog": Color("FFF5E6")
	},
	2: {
		"name": "Bright Trajineras",
		"subtitle": "Trajineras Brillantes",
		"sky": [Color("77ddff"), Color("66ccee"), Color("77ccbb"), Color("99cc88"), Color("bbcc77"), Color("ddcc66")],
		"mountain": Color("447755"), "hill": Color("55aa66"), "water_color": Color("0a5e52"),
		"background": Color("87CEEB"), "foreground": Color("228B22"),
		"midground": Color("32CD32"),
		"vegetation": [Color("7FFF00"), Color("006400"), Color("2E8B57")],
		"accent": Color("FFFF00"), "fog": Color("E8F5E0")
	},
	3: {
		"name": "Crystal Cave",
		"subtitle": "Cueva de Cristal",
		"sky": [Color("334466"), Color("223355"), Color("112244"), Color("001133"), Color("000022"), Color("000011")],
		"mountain": Color("112233"), "hill": Color("223355"), "water_color": Color("224466"),
		"background": Color("191970"), "foreground": Color("483D8B"),
		"midground": Color("6A5ACD"),
		"vegetation": [Color("9370DB"), Color("8A2BE2"), Color("4B0082")],
		"accent": Color("00FFFF"), "fog": Color("E6E6FA")
	},
	4: {
		"name": "Floating Gardens",
		"subtitle": "Jardines Flotantes",
		"sky": [Color("ffbb77"), Color("ff9955"), Color("ff7744"), Color("ee5533"), Color("cc4422"), Color("993311")],
		"mountain": Color("335544"), "hill": Color("77aa55"), "water_color": Color("668877"),
		"background": Color("FF8C00"), "foreground": Color("8B4513"),
		"midground": Color("CD853F"),
		"vegetation": [Color("DAA520"), Color("B8860B"), Color("FF6347")],
		"accent": Color("FF4500"), "fog": Color("FFDAB9")
	},
	5: {
		"name": "Night Canals",
		"subtitle": "Canales de Noche",
		"sky": [Color("223355"), Color("112244"), Color("001133"), Color("001122"), Color("000011"), Color("000000")],
		"mountain": Color("112233"), "hill": Color("223344"), "water_color": Color("113344"),
		"background": Color("000080"), "foreground": Color("2F4F4F"),
		"midground": Color("708090"),
		"vegetation": [Color("4682B4"), Color("5F9EA0"), Color("00CED1")],
		"accent": Color("C0C0C0"), "fog": Color("F8F8FF")
	},
	6: {
		"name": "La Fiesta",
		"subtitle": "The Final Celebration",
		"sky": [Color("FFD700"), Color("FFA500"), Color("FF69B4"), Color("FF1493"), Color("9400D3"), Color("4B0082")],
		"mountain": Color("FF6347"), "hill": Color("FF69B4"), "water_color": Color("40E0D0"),
		"background": Color("FF69B4"), "foreground": Color("FFD700"),
		"midground": Color("FFA500"),
		"vegetation": [Color("FF1493"), Color("00FF00"), Color("FFFF00")],
		"accent": Color("FFFFFF"), "fog": Color("FFE4E1")
	}
}


# --- World / Level Mapping (exact from original) ---

func get_world_for_level(level_num: int) -> int:
	if level_num <= 2: return 1
	if level_num <= 4: return 2
	if level_num <= 6: return 3
	if level_num <= 8: return 4
	if level_num <= 10: return 5
	return 6


func is_first_level_of_world(level_num: int) -> bool:
	return level_num in [1, 3, 5, 7, 9, 11]


func get_first_level_of_world(world_num: int) -> int:
	match world_num:
		1: return 1
		2: return 3
		3: return 5
		4: return 7
		5: return 9
		6: return 11
		_: return 1


func get_settings() -> Dictionary:
	return DIFFICULTY_SETTINGS[difficulty]


# --- Reset / New Game ---

func reset_game() -> void:
	if score > high_score:
		high_score = score
	var settings := get_settings()
	current_level = 1
	flowers = 0
	lives = settings["lives"]
	stars = []
	rescued_babies = []
	super_jumps = settings["starting_super_jumps"]
	mace_attacks = settings["starting_mace_attacks"]
	score = 0
	save_game()


# --- Persistence ---

const SAVE_PATH := "user://xochi_save.json"

func save_game() -> void:
	var save_data := {
		"current_level": current_level,
		"flowers": flowers,
		"lives": lives,
		"stars": stars,
		"rescued_babies": rescued_babies,
		"super_jumps": super_jumps,
		"mace_attacks": mace_attacks,
		"score": score,
		"high_score": high_score,
		"music_enabled": music_enabled,
		"sfx_enabled": sfx_enabled,
		"difficulty": difficulty
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	var result := json.parse(file.get_as_text())
	if result != OK:
		push_warning("GameState: Failed to parse save file.")
		return
	var data: Dictionary = json.data
	current_level = data.get("current_level", 1)
	flowers = data.get("flowers", 0)
	lives = data.get("lives", 3)
	stars = data.get("stars", [])
	rescued_babies = data.get("rescued_babies", [])
	super_jumps = data.get("super_jumps", 2)
	mace_attacks = data.get("mace_attacks", 1)
	score = data.get("score", 0)
	high_score = data.get("high_score", 0)
	music_enabled = data.get("music_enabled", true)
	sfx_enabled = data.get("sfx_enabled", true)
	difficulty = data.get("difficulty", "medium")


# --- Lifecycle ---

func _ready() -> void:
	load_game()

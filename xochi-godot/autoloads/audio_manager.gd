extends Node
## Manages all music and sound effects for Xochi.
##
## MUSIC RULES:
##   - Each world has ONE song that loops continuously.
##   - The song keeps playing uninterrupted through deaths, retries,
##     and level transitions within the same world.
##   - The song ONLY changes when the player advances to a new world.
##   - AudioManager is an autoload (singleton) so it persists across
##     scene reloads. The same-track check in play_music() prevents
##     restarting on retry.
##
## Uses a pooled AudioStreamPlayer approach for overlapping SFX.

var current_music: AudioStreamPlayer = null
var current_track: String = ""
var is_playing: bool = false

const CROSSFADE_DURATION: float = 1.0  # 1 second crossfade
var _crossfade_player: AudioStreamPlayer = null

# SFX pool for overlapping sounds
var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 4

# Music track paths -- loaded lazily at runtime so a missing import
# file cannot crash the autoload and break the entire game.
const MUSIC_PATHS: Dictionary = {
	"music_menu": "res://assets/audio/music/music_menu.ogg",
	"music_gardens": "res://assets/audio/music/music_gardens.ogg",
	"music_world3": "res://assets/audio/music/music_world3.ogg",
	"music_upscroller": "res://assets/audio/music/music_upscroller.ogg",
	"music_night": "res://assets/audio/music/music_night.ogg",
	"music_boss": "res://assets/audio/music/music_boss.ogg",
	"fiesta_de_xochi": "res://assets/audio/music/fiesta_de_xochi.ogg",
	"music_fiesta": "res://assets/audio/music/music_fiesta.ogg",
	"music_finale": "res://assets/audio/music/music_finale.ogg",
}

# Loaded music streams (populated on first use).
var music_tracks: Dictionary = {}

# World → Track mapping
# Each world gets its own unique song. No overrides for boss/escape levels --
# the world song plays through ALL levels in that world, uninterrupted.
const WORLD_TRACKS: Dictionary = {
	1: "music_menu",          # Traviesa Axolotla (same as menu -- the hit!)
	2: "music_world3",        # World 3 track (temple ruins)
	3: "music_upscroller",    # Upscroller intensity
	4: "music_night",         # Xochimilco Moonwake
	5: "music_boss",          # Boss-level intensity
	6: "fiesta_de_xochi",     # Fiesta de Xochi (celebration!)
}

# SFX mapping
var sfx_tracks: Dictionary = {
	"jump": preload("res://assets/audio/sfx/jump_small.ogg"),
	"jump_super": preload("res://assets/audio/sfx/jump_super.ogg"),
	"land": preload("res://assets/audio/sfx/land_soft.ogg"),
	"stomp": preload("res://assets/audio/sfx/stomp.ogg"),
	"hurt": preload("res://assets/audio/sfx/hurt.ogg"),
	"flower": preload("res://assets/audio/sfx/flower.ogg"),
	"menu_select": preload("res://assets/audio/sfx/menu_select.ogg"),
	"powerup": preload("res://assets/audio/sfx/powerup.ogg"),
}


func _ready() -> void:
	current_music = AudioStreamPlayer.new()
	current_music.bus = &"Master"
	add_child(current_music)

	_crossfade_player = AudioStreamPlayer.new()
	_crossfade_player.bus = &"Master"
	add_child(_crossfade_player)

	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		sfx_players.append(player)


# =============================================================================
# MUSIC PLAYBACK
# =============================================================================

func _load_track(key: String) -> AudioStream:
	## Lazy-load a music track. Returns null if the file doesn't exist yet
	## (e.g. Godot hasn't imported it). This prevents autoload crashes.
	if key in music_tracks:
		return music_tracks[key]
	if key not in MUSIC_PATHS:
		return null
	var stream = load(MUSIC_PATHS[key])
	if stream:
		music_tracks[key] = stream
	else:
		push_warning("AudioManager: could not load track '%s'" % key)
	return stream


func play_music(track_key: String) -> void:
	if not GameState.music_enabled:
		return

	# Don't restart the same track -- this is the key to uninterrupted loops.
	if is_playing and current_track == track_key:
		return

	var stream := _load_track(track_key)
	if stream == null:
		return

	if is_playing and current_music.playing:
		# Crossfade: fade out current, fade in new
		_crossfade_player.stream = current_music.stream
		_crossfade_player.volume_db = current_music.volume_db
		_crossfade_player.play(current_music.get_playback_position())

		var fade_out := create_tween()
		fade_out.tween_property(_crossfade_player, "volume_db", -80.0, CROSSFADE_DURATION)
		fade_out.tween_callback(_crossfade_player.stop)

		current_music.stream = stream
		current_music.volume_db = -80.0
		current_music.play()

		var fade_in := create_tween()
		fade_in.tween_property(current_music, "volume_db", linear_to_db(0.4), CROSSFADE_DURATION)
	else:
		stop_music()
		current_music.stream = stream
		current_music.volume_db = linear_to_db(0.4)
		current_music.play()

	current_track = track_key
	is_playing = true


func play_for_world(world_num: int) -> void:
	## Play the world's song. If it's already playing, does nothing
	## (uninterrupted loop through deaths and level transitions).
	var track: String = WORLD_TRACKS.get(world_num, "music_gardens")
	play_music(track)


func play_for_level(level_num: int, world_num: int) -> void:
	## Play music for this level. ALWAYS uses the world's song --
	## no boss/escape overrides. The world song loops uninterrupted
	## until the player advances to the next world.
	play_for_world(world_num)


func stop_music() -> void:
	if current_music and current_music.playing:
		current_music.stop()
	is_playing = false
	current_track = ""


# =============================================================================
# SFX PLAYBACK
# =============================================================================

func play_sfx(sfx_key: String) -> void:
	if not GameState.sfx_enabled:
		return
	if sfx_key not in sfx_tracks:
		return

	for player in sfx_players:
		if not player.playing:
			player.stream = sfx_tracks[sfx_key]
			player.play()
			return

	# All busy -- override the oldest sound.
	sfx_players[0].stream = sfx_tracks[sfx_key]
	sfx_players[0].play()


# =============================================================================
# VOLUME CONTROL
# =============================================================================

func set_music_volume(vol: float) -> void:
	if current_music:
		current_music.volume_db = linear_to_db(vol)

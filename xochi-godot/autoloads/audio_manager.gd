extends Node
## Manages all music and sound effects for Xochi.
## Ported from XochiMusicManager (original game.js lines 7-77).
## Uses a pooled AudioStreamPlayer approach for overlapping SFX.

var current_music: AudioStreamPlayer = null
var current_track: String = ""
var is_playing: bool = false

const CROSSFADE_DURATION: float = 1.0  # 1 second crossfade
var _crossfade_player: AudioStreamPlayer = null  # Second player for crossfade

# SFX pool for overlapping sounds
var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 4

# Music tracks mapping
var music_tracks: Dictionary = {
	"music_menu": preload("res://assets/audio/music/music_menu.ogg"),
	"level_1_xochimilco": preload("res://assets/audio/music/level_1_xochimilco.wav"),
	"music_gardens": preload("res://assets/audio/music/music_gardens.ogg"),
	"music_world3": preload("res://assets/audio/music/music_world3.ogg"),
	"music_night": preload("res://assets/audio/music/music_night.ogg"),
	"music_boss": preload("res://assets/audio/music/music_boss.ogg"),
	"music_upscroller": preload("res://assets/audio/music/music_upscroller.ogg"),
	"music_fiesta": preload("res://assets/audio/music/music_fiesta.ogg"),
	"music_finale": preload("res://assets/audio/music/music_finale.ogg"),
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
	# Create music player
	current_music = AudioStreamPlayer.new()
	current_music.bus = &"Master"
	add_child(current_music)

	# Create crossfade player
	_crossfade_player = AudioStreamPlayer.new()
	_crossfade_player.bus = &"Master"
	add_child(_crossfade_player)

	# Create SFX pool
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		sfx_players.append(player)


# --- Music Playback ---

func play_music(track_key: String) -> void:
	if not GameState.music_enabled:
		return

	# Don't restart the same track
	if is_playing and current_track == track_key:
		return

	if track_key not in music_tracks:
		return

	if is_playing and current_music.playing:
		# Crossfade: fade out current, fade in new
		_crossfade_player.stream = current_music.stream
		_crossfade_player.volume_db = current_music.volume_db
		_crossfade_player.play(current_music.get_playback_position())

		# Fade out the old track on crossfade player
		var fade_out := create_tween()
		fade_out.tween_property(_crossfade_player, "volume_db", -80.0, CROSSFADE_DURATION)
		fade_out.tween_callback(_crossfade_player.stop)

		# Start new track on main player with fade in
		current_music.stream = music_tracks[track_key]
		current_music.volume_db = -80.0
		current_music.play()

		var fade_in := create_tween()
		fade_in.tween_property(current_music, "volume_db", linear_to_db(0.4), CROSSFADE_DURATION)
	else:
		# No current track -- just play
		stop_music()
		current_music.stream = music_tracks[track_key]
		current_music.volume_db = linear_to_db(0.4)
		current_music.play()

	current_track = track_key
	is_playing = true


func play_for_world(world_num: int) -> void:
	## Each world has ONE track that loops continuously across all its levels.
	## The track should NOT restart when transitioning between levels in the
	## same world -- play_music() already handles this via the current_track check.
	var track := "music_menu"
	match world_num:
		1: track = "level_1_xochimilco"  # Traviesa Axolotla for all of World 1
		2: track = "music_gardens"
		3: track = "music_world3"
		4: track = "music_night"
		5: track = "music_night"  # World 5 continues night atmosphere
		_: track = "music_finale"
	play_music(track)


func play_for_level(level_num: int, world_num: int) -> void:
	## Play the appropriate music for this level.
	## DESIGN: World music loops continuously across ALL levels in that world.
	## Only boss levels override with boss music (different atmosphere).
	## Upscroller/escape levels use their world's track for continuity.

	# Boss levels get boss music (clear atmosphere change)
	if level_num == 5 or level_num == 10:
		play_music("music_boss")
		return

	# Fiesta level (celebration!)
	if level_num == 11:
		play_music("music_fiesta")
		return

	# All other levels: use world music (continuous loop, no restart)
	play_for_world(world_num)


func stop_music() -> void:
	if current_music and current_music.playing:
		current_music.stop()
	is_playing = false
	current_track = ""


# --- SFX Playback ---

func play_sfx(sfx_key: String) -> void:
	if not GameState.sfx_enabled:
		return
	if sfx_key not in sfx_tracks:
		return

	# Find an available (idle) SFX player from the pool
	for player in sfx_players:
		if not player.playing:
			player.stream = sfx_tracks[sfx_key]
			player.play()
			return

	# All busy -- override the first player (oldest sound)
	sfx_players[0].stream = sfx_tracks[sfx_key]
	sfx_players[0].play()


# --- Volume Control ---

func set_music_volume(vol: float) -> void:
	if current_music:
		current_music.volume_db = linear_to_db(vol)

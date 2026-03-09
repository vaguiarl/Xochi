extends Node
## Headless autoplay harness that drives the full game loop across scene changes.

const MENU_SCENE_PATH := "res://scenes/menu/menu_scene.tscn"
const STORY_SCENE_PATH := "res://scenes/story/story_scene.tscn"
const GAME_SCENE_PATH := "res://scenes/game/game_scene.tscn"
const END_SCENE_PATH := "res://scenes/end/end_scene.tscn"

const TOTAL_TIMEOUT := 180.0
const MENU_START_DELAY := 0.75
const STORY_ADVANCE_INTERVAL := 0.45
const LEVEL_SETTLE_DELAY := 0.40
const BOSS_HIT_INTERVAL := 0.70
const POST_BOSS_DELAY := 0.40
const CELEBRATION_SKIP_DELAY := 0.35
const END_EXIT_DELAY := 1.00
const SHUTDOWN_GRACE_PERIOD := 1.5

var total_elapsed: float = 0.0
var scene_elapsed: float = 0.0
var action_cooldown: float = 0.0
var current_scene_path: String = ""
var current_scene_id: int = 0
var current_level: int = -1
var completed_levels: Array[int] = []
var _shutdown_started: bool = false
var _shutdown_elapsed: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[Autoplay] enabled")


func _process(delta: float) -> void:
	total_elapsed += delta
	if action_cooldown > 0.0:
		action_cooldown = maxf(0.0, action_cooldown - delta)
	if _shutdown_started:
		_shutdown_elapsed += delta

	if total_elapsed > TOTAL_TIMEOUT:
		_fail("Timed out after %.1fs" % total_elapsed)
		return

	var scene: Node = get_tree().current_scene
	if scene == null:
		if _shutdown_started and _shutdown_elapsed >= SHUTDOWN_GRACE_PERIOD:
			print("[Autoplay] success -> levels %s" % [str(completed_levels)])
			get_tree().quit()
		return

	var scene_path: String = scene.scene_file_path
	var scene_id: int = scene.get_instance_id()
	if scene_path != current_scene_path or scene_id != current_scene_id:
		current_scene_path = scene_path
		current_scene_id = scene_id
		scene_elapsed = 0.0
		action_cooldown = 0.0
		current_level = -1
		_shutdown_started = false
		_shutdown_elapsed = 0.0
		print("[Autoplay] scene -> %s" % scene_path)
	else:
		scene_elapsed += delta

	var timeout := _get_scene_timeout(scene_path)
	if timeout > 0.0 and scene_elapsed > timeout:
		_fail("Scene timeout in %s after %.1fs" % [scene_path, scene_elapsed])
		return

	match scene_path:
		MENU_SCENE_PATH:
			_handle_menu(scene)
		STORY_SCENE_PATH:
			_handle_story(scene)
		GAME_SCENE_PATH:
			_handle_game(scene)
		END_SCENE_PATH:
			_handle_end(scene)


func _get_scene_timeout(scene_path: String) -> float:
	match scene_path:
		MENU_SCENE_PATH:
			return 8.0
		STORY_SCENE_PATH:
			return 20.0
		GAME_SCENE_PATH:
			return 30.0
		END_SCENE_PATH:
			return 10.0
		_:
			return 0.0


func _handle_menu(scene: Node) -> void:
	if scene_elapsed < MENU_START_DELAY or action_cooldown > 0.0:
		return
	if scene.has_method("_on_new_game_pressed"):
		print("[Autoplay] starting new game")
		scene._on_new_game_pressed()
		action_cooldown = 2.0


func _handle_story(scene: Node) -> void:
	if action_cooldown > 0.0:
		return

	var slides = scene.get("slides")
	if slides is Array and slides.is_empty():
		return

	if scene.has_method("_next_slide"):
		scene._next_slide()
		action_cooldown = STORY_ADVANCE_INTERVAL


func _handle_game(scene: Node) -> void:
	var player: Node = scene.get("player")
	if player == null or not is_instance_valid(player):
		return

	var level_num := int(scene.get("level_num"))
	if level_num != current_level:
		current_level = level_num
		print("[Autoplay] level %d" % current_level)

	GameState.lives = max(GameState.lives, 99)
	player.set("is_invincible", true)
	player.set("velocity", Vector2.ZERO)

	if bool(scene.get("level_complete")):
		if current_level not in completed_levels:
			completed_levels.append(current_level)
			print("[Autoplay] cleared level %d" % current_level)
		if bool(scene.get("celebration_active")) and scene_elapsed >= CELEBRATION_SKIP_DELAY and action_cooldown <= 0.0:
			scene._skip_celebration()
			action_cooldown = 0.5
		return

	if scene_elapsed < LEVEL_SETTLE_DELAY:
		return

	var level_data = scene.get("level_data")
	var is_boss_level := false
	if level_data is Dictionary:
		is_boss_level = bool(level_data.get("is_boss_level", false))

	if is_boss_level:
		_handle_boss_level(scene, player)
	else:
		_complete_via_baby(scene, player)


func _handle_boss_level(scene: Node, player: Node) -> void:
	var boss: Node = scene.get("boss")
	if boss != null and is_instance_valid(boss):
		var boss_state := str(boss.get("state"))
		if boss_state != "DEAD":
			if not bool(boss.get("ai_active")):
				return
			if action_cooldown <= 0.0 and not bool(boss.get("is_invincible")):
				boss.hit_by_stomp()
				print("[Autoplay] boss hit -> hp %d" % int(boss.get("health")))
				action_cooldown = BOSS_HIT_INTERVAL
			return

	if action_cooldown > 0.0:
		return

	action_cooldown = POST_BOSS_DELAY
	_complete_via_baby(scene, player)


func _complete_via_baby(scene: Node, player: Node) -> void:
	var baby := _find_baby_node(scene)
	if baby != null and is_instance_valid(baby):
		player.set("global_position", baby.global_position)
		player.set("velocity", Vector2.ZERO)
		if scene.has_method("_check_baby_pickup"):
			scene._check_baby_pickup()
		return

	if scene.has_method("_complete_level"):
		scene._complete_level()


func _find_baby_node(scene: Node) -> Node2D:
	var collectibles: Node = scene.get("collectibles_node")
	if collectibles != null and is_instance_valid(collectibles):
		var baby := collectibles.get_node_or_null("BabyAxolotl")
		if baby != null:
			return baby as Node2D
	return null


func _handle_end(_scene: Node) -> void:
	if not _shutdown_started and scene_elapsed < END_EXIT_DELAY:
		return

	if not _shutdown_started:
		_shutdown_started = true
		_shutdown_elapsed = 0.0
		var end_scene: Node = get_tree().current_scene
		if end_scene != null and end_scene.has_method("_prepare_headless_exit"):
			end_scene._prepare_headless_exit()
		if SceneManager.has_method("release_transition_resources"):
			SceneManager.release_transition_resources()
		if get_tree().has_method("get_processed_tweens"):
			for tween in get_tree().get_processed_tweens():
				if tween and tween.is_valid():
					tween.kill()
		if AudioManager.has_method("release_audio_resources"):
			AudioManager.release_audio_resources()
		if end_scene != null and is_instance_valid(end_scene):
			end_scene.queue_free()
		return

	if _shutdown_elapsed < SHUTDOWN_GRACE_PERIOD:
		return

	print("[Autoplay] success -> levels %s" % [str(completed_levels)])
	get_tree().quit()


func _fail(message: String) -> void:
	push_error("[Autoplay] %s" % message)
	get_tree().quit(1)

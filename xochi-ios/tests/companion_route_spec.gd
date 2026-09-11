extends SceneTree
## Run: godot --headless --fixed-fps 60 --path xochi-ios --script res://tests/companion_route_spec.gd
## All progression uses displayed Button signals, with real controller/physics.
## No teleport, direct completion, charge grants, guard mutation, or microphone.

var game: Node2D
var failures: Array[String] = []
var test_save := ""
var original_save: Dictionary = {}
var song_id := 0
var last_music_position := 0.0
var first_music_position := 0.0
var music_rewinds := 0
var song_stops := 0
var frames := 0
var step_completions: Array[int] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	# A wide phone exercises the world translation as well as the 1280px route.
	root.size = Vector2i(1420, 720)
	root.content_scale_size = Vector2i(1420, 720)
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = "user://companion-learning-v1.json" + suffix
		original_save[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	test_save = "user://companion-route-spec-%s.json" % OS.get_process_id()
	game = load("res://scripts/companion_main.gd").new()
	game.save.save_path = test_save
	root.add_child(game)
	await _ticks(4)
	if not is_instance_valid(game.music):
		failures.append("encounter did not initialize its real music player")
		await _finish()
		return
	song_id = game.music.stream.get_instance_id()
	# The audio mixer advances in real time even when fixed-fps physics runs fast.
	OS.delay_msec(70)
	first_music_position = game.music.get_playback_position()
	last_music_position = first_music_position
	_expect(game.current_screen == "menu", "encounter must start at its menu")
	if not _press("Begin"):
		await _finish()
		return
	await _ticks(2)
	_expect(game.current_screen == "intro", "Begin must display the story introduction")
	if not _press("StartJourney"):
		await _finish()
		return
	await _ticks(8)
	_expect(game.playing and game.step == 0 and game.player.is_on_floor(), "StartJourney must begin the first lesson on real ground")
	_expect(game.player.position.distance_to(Vector2(130, 555)) < 2.0, "wide-phone start must preserve the authored local spawn")
	await _wrong_choice()
	if not await _solve_step(0):
		await _finish()
		return
	if not await _solve_step(1):
		await _finish()
		return
	await _pause_and_take_over_then_rejoin()
	await _pause_during_rejoin()
	for expected in range(2, 8):
		if expected == 5:
			await _miss_opening_and_wait_again()
		if not await _solve_step(expected):
			break
	_expect(game.finished and game.current_screen == "ending" and game.step == 8, "all eight learned actions must reach the actual reunion ending")
	_expect(game.friends_arrived and game.save.data.completed, "ending must reunite friends and persist completion")
	_expect(step_completions == [0, 1, 2, 3, 4, 5, 6, 7], "every lesson must complete once, in order")
	_expect(game.player.hyper_charges == 2, "guided chapter must preserve the two independent hyper charges")
	_expect(game.session_uses.size() == 5 and game.save.data.used_intents.size() == 5, "ending must contain evidence for all five distinct intentions")
	_expect(game.session_spoken == 0 and game.save.data.spoken_practice == 0 and game.save.data.typed_practice == 0, "button choices must never invent spoken or typed practice")
	var persisted = load("res://scripts/learning_progress.gd").new(test_save)
	persisted.read_save()
	_expect(persisted.data.completed and persisted.data.used_intents.size() == 5, "reloading the isolated save must preserve completed evidence")
	OS.delay_msec(70)
	_sample_music()
	_expect(game.music.get_playback_position() > first_music_position + 0.03, "the original song must actually continue advancing during the encounter")
	_expect(music_rewinds == 0 and song_stops == 0, "menu, lessons, pause, Rejoin and ending must preserve the same playing song without restarting")
	await _finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _ticks(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame
		frames += 1
		_sample_music()


func _sample_music() -> void:
	if song_id == 0 or not is_instance_valid(game) or not is_instance_valid(game.music):
		return
	if not game.music.playing or game.music.stream.get_instance_id() != song_id:
		song_stops += 1
	var position_: float = game.music.get_playback_position()
	if position_ < last_music_position - 0.01:
		music_rewinds += 1
	last_music_position = position_


func _find_button(node: Node, name_or_text: String) -> Button:
	if node is Button and node.is_visible_in_tree() and (node.name == name_or_text or node.text == name_or_text):
		return node
	for child in node.get_children():
		var result := _find_button(child, name_or_text)
		if result != null:
			return result
	return null


func _press(name_or_text: String) -> bool:
	var button := _find_button(game.ui, name_or_text)
	if button == null or button.disabled:
		failures.append("missing or disabled displayed button: " + name_or_text + " at lesson " + str(game.step))
		return false
	# Same public activation used by touch/accessibility, with visibility and
	# enabled-state checked. World takeover below uses actual screen events.
	button.pressed.emit()
	return true


func _wrong_choice() -> void:
	var before: Vector2 = game.player.position
	var evidence: Dictionary = game.save.data.duplicate(true)
	_press("Action_wait")
	await _ticks(45)
	_expect(game.step == 0 and game.pending_answer.is_empty() and not game.controller.guiding, "wrong meaning must not start guidance or advance a lesson")
	_expect(game.player.position.distance_to(before) < 1.0 and game.retry_count == 0, "wrong meaning must stay physically safe without causing a retry")
	_expect(game.save.data == evidence and game.hint_used, "wrong choice should offer help without inventing learning evidence")


func _solve_step(expected: int) -> bool:
	if game.step != expected:
		failures.append("expected lesson %s, got %s" % [expected, game.step])
		return false
	var lesson: Dictionary = game.LESSONS[expected]
	var evidence: Dictionary = game.save.data.duplicate(true)
	if not _press("Action_" + lesson.intent):
		return false
	_expect(game.step == expected and not game.pending_answer.is_empty(), "correct choice must establish a pending action before earning its lesson")
	_expect(game.save.data == evidence, "choosing correctly must not record evidence before the physical action")
	await _ticks(5)
	_expect(game.step == expected, "action must not skip the actual walk/jump/wait")
	for tick in range(300):
		if game.step != expected:
			break
		await _ticks(1)
	if game.step != expected + 1:
		failures.append("lesson %s failed to finish: position=%s guiding=%s pending=%s status=%s" % [expected, game.player.position, game.controller.guiding, game.pending_answer, game.status_text])
		return false
	_expect(game.player.is_on_floor() and game.player.position.distance_to(lesson.target) < 24.0, "lesson may complete only after a real floor arrival or grounded wait: " + str(expected))
	_expect(not game.controller.guiding and absf(game.player.velocity.x) < 0.01, "each lesson must finish at a stop before the next instruction")
	_expect(lesson.intent in game.save.data.used_intents, "completed lesson must record its intention")
	step_completions.append(expected)
	print("[CompanionRoute] lesson ", expected + 1, "/8 complete at ", game.player.position)
	return true


func _pause_and_take_over_then_rejoin() -> void:
	var earned: Dictionary = game.save.data.duplicate(true)
	var uses: Dictionary = game.session_uses.duplicate(true)
	_press("Action_come")
	await _ticks(10)
	_press("Pause")
	var paused_position: Vector2 = game.player.position
	var song_position: float = game.music.get_playback_position()
	await _ticks(30)
	# AudioServer publishes its mixer result across process frames. Bound this
	# real-time wait rather than assuming fixed-fps simulation advances audio.
	for audio_tick in range(12):
		OS.delay_msec(25)
		await _ticks(1)
		if game.music.get_playback_position() > song_position:
			break
	_expect(paused and game.current_screen == "pause" and game.player.position == paused_position, "Pause must freeze actual movement while its UI stays active")
	_expect(not game.controller.guiding and game.music.get_playback_position() > song_position, "Pause must cancel guidance while the song continues; before=%s after=%s guiding=%s stream_paused=%s" % [song_position, game.music.get_playback_position(), game.controller.guiding, game.music.stream_paused])
	_press("Keep going")
	await _ticks(15)
	_expect(not paused and game.step == 2 and not game.controller.guiding and game.pending_answer.is_empty(), "resume must request a fresh plan without advancing the unfinished lesson")
	_expect(game.player.position.distance_to(paused_position) < 0.1, "resume must not silently restart the canceled walk")
	_press("Action_come")
	await _ticks(10)
	var old_generation: int = game.generation
	_touch(true, Vector2(350, 400))
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(275, 400)
	drag.relative = Vector2(-75, 0)
	Input.parse_input_event(drag)
	Input.flush_buffered_events()
	await _ticks(3)
	_expect(not game.controller.guiding and game.generation > old_generation and game.player.velocity.x < 0, "real swipe must take control and invalidate delayed voice guidance")
	_touch(false, Vector2(275, 400), true)
	await _ticks(25)
	_expect(game.step == 2 and game.save.data == earned, "interrupted motion must preserve earned lessons and leave the unfinished action uncredited")
	_press("Rejoin")
	_expect(game.retrying and not game.player.active, "Rejoin must use the real retry transition")
	for tick in range(90):
		await _ticks(1)
		if not game.retrying:
			break
	await _ticks(8)
	_expect(not game.retrying and game.retry_count == 1 and game.step == 2, "Rejoin must resume the same unfinished lesson")
	_expect(game.player.position.distance_to(game.LESSONS[2].spawn) < 2.0 and game.player.is_on_floor(), "Rejoin must restore the correct local staging point on wide phones")
	_expect(game.save.data == earned and game.session_uses == uses, "Rejoin must preserve all already-earned learning evidence")
	_expect(game.pending_answer.is_empty() and not game.controller.guiding, "Rejoin must cancel stale pending choices and guidance")


func _pause_during_rejoin() -> void:
	var earned: Dictionary = game.save.data.duplicate(true)
	var uses: Dictionary = game.session_uses.duplicate(true)
	var current_step: int = game.step
	var retries_before: int = game.retry_count
	_press("Rejoin")
	var retry_generation: int = game.generation
	_expect(game.retrying and not game.player.active, "interruption setup must enter the real 480ms retry")
	# Both visible buttons are pressed before the first retry timer tick.
	_press("Pause")
	await _ticks(8)
	_expect(paused and game.current_screen == "pause" and game.generation > retry_generation, "pausing inside Rejoin must invalidate its pending timer")
	_expect(game.save.data == earned and game.step == current_step, "interrupting retry must not change completed evidence or the current lesson")
	_press("Keep going")
	await _ticks(8)
	_expect(not paused and game.current_screen == "game" and game.player.active and not game.retrying, "resume from an interrupted retry must restore an active player")
	_expect(game.step == current_step and game.retry_count == retries_before + 1, "interrupted retry must rejoin once without changing the lesson")
	_expect(game.player.is_on_floor() and game.player.position.distance_to(game.LESSONS[current_step].spawn) < 2.0, "interrupted retry must restore the authored staging point")
	_expect(game.save.data == earned and game.session_uses == uses, "interrupted retry must preserve all earned learning evidence")
	_expect(game.pending_answer.is_empty() and not game.controller.guiding, "interrupted retry must require a fresh instruction")
	# _solve_step(2) follows immediately. Its normal walk lasts beyond the old
	# timer's remaining 480ms, proving a stale callback cannot break fresh guidance.


func _touch(pressed: bool, at: Vector2, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = at
	event.pressed = pressed
	event.canceled = canceled
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _miss_opening_and_wait_again() -> void:
	var saw_first_opening := false
	var saw_closed_again := false
	var reopened := false
	for tick in range(900):
		await _ticks(1)
		if game.guard.can_cross():
			if saw_closed_again:
				reopened = true
				break
			saw_first_opening = true
		elif saw_first_opening:
			saw_closed_again = true
	_expect(reopened and game.step == 5 and game.player.is_on_floor(), "missing the crow's first opening must safely offer another without resetting the lesson")


func _finish() -> void:
	paused = false
	if is_instance_valid(game):
		if is_instance_valid(game.music):
			game.music.stop()
			# Let the real mixer release its Vorbis playback before fast test exit.
			await process_frame
			OS.delay_msec(100)
			await process_frame
			game.music.stream = null
		game.queue_free()
	await process_frame
	OS.delay_msec(120)
	await process_frame
	await process_frame
	for path in original_save:
		var now = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
		_expect(now == original_save[path], "real user save must remain byte-for-byte unchanged: " + path)
	for suffix in ["", ".bak", ".tmp"]:
		if not test_save.is_empty() and FileAccess.file_exists(test_save + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save + suffix))
	if failures.is_empty():
		print("[CompanionRoute] PASS: menu → intro → all eight displayed choices → reunion; wrong choice safe; real boat/bank collisions; pause/manual takeover/Rejoin preserve progress and uninterrupted song; paused retry restores play and ignores its stale timer; missed crow opening returns; isolated save reloaded and removed. Simulated seconds=", snappedf(frames / 60.0, 0.01))
		quit(0)
	else:
		for failure in failures:
			push_error("[CompanionRoute] " + failure)
		quit(1)

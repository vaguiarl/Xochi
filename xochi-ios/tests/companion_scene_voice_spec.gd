extends SceneTree
## Actual encounter, controller, collision and voice adapter; fake native speech.
## The single stage-5 fixture below is not evidence of a full menu-to-ending run.
## Run: godot --headless --fixed-fps 60 --path . --script tests/companion_scene_voice_spec.gd

class NativeDouble extends RefCounted:
	signal transcript(text: String, language: String, final: bool, checkpoint: int, attempt: int, session: int)
	signal interpretation(intent: String, language: String, checkpoint: int, attempt: int, session: int)
	signal status(state: int, message: String, checkpoint: int, attempt: int, session: int)
	var requests: Array[Dictionary] = []
	var examples: Array[String] = []
	var interpretations: Array[Dictionary] = []
	var stops := 0
	func supported_locale(locale: String) -> bool: return locale in ["es", "en"]
	func begin_transcribing(locale: String, cp: int, attempt: int, session: int) -> void:
		requests.append({"locale":locale, "cp":cp, "attempt":attempt, "session":session})
	func intelligence_status(_locale: String) -> String: return "available"
	func interpret_intent(text: String, locale: String, cp: int, attempt: int, session: int) -> void:
		interpretations.append({"text":text, "locale":locale, "cp":cp, "attempt":attempt, "session":session})
	func decide(request: Dictionary, intent: String, language := "es") -> void:
		interpretation.emit(intent, language, request.cp, request.attempt, request.session)
	func stop_listening() -> void: stops += 1
	func speak_example(text: String) -> void: examples.append(text)
	func send(request: Dictionary, text: String, final := true) -> void:
		transcript.emit(text, request.locale, final, request.cp, request.attempt, request.session)
	func send_state(request: Dictionary, state: int) -> void:
		status.emit(state, "Native fixture status", request.cp, request.attempt, request.session)

var game: Node2D
var native := NativeDouble.new()
var failures: Array[String] = []
var original_save: Dictionary = {}
var test_save := ""

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1420, 720)
	root.content_scale_size = Vector2i(1420, 720)
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = "user://companion-learning-v1.json" + suffix
		original_save[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	test_save = "user://companion-scene-voice-spec-%s.json" % OS.get_process_id()
	game = load("res://scripts/companion_main.gd").new()
	game.save.save_path = test_save
	root.add_child(game)
	await _ticks(4)
	game.voice.attach_native(native)
	game.voice.configure("es")
	game._start_journey()
	# Bounded fixture: stage the real player on the boat, then let the authored
	# distraction, microphone transition and jump run through production code.
	game.step = 5
	game.curiosity_seen = true
	game.player.reset_at(game.world.to_global(game.LESSONS[5].spawn))
	game.guard.reset_state()
	game._enter_step()
	for frame in range(100):
		await _ticks(1)
		if game.player.is_on_floor() and game.guard.can_cross(): break
	_expect(game.step == 5 and game.player.is_on_floor() and game.guard.can_cross(), "fixture must reach the real boat floor and authored crow opening")
	if not game.player.is_on_floor() or not game.guard.can_cross():
		await _finish()
		return
	await _frozen_opening_accepts_jump()
	if game.step != 6:
		await _finish()
		return
	await _manual_takeover_rejects_old_voice()
	await _typed_practice_stays_distinct()
	await _typed_dialog_and_stale_interpretation()
	await _pause_requires_fresh_grounded_opt_in()
	await _finish()

func _frozen_opening_accepts_jump() -> void:
	game.mic_button.pressed.emit()
	_expect(native.requests.size() == 1 and game.voice.requesting and not game.voice.listening, "Speak must request capture without claiming the native microphone is already listening")
	var request: Dictionary = native.requests.back()
	native.send_state(request, 2)
	await _ticks(2)
	var opening_time: float = game.guard.state_time
	await _ticks(45)
	_expect(game.voice.listening and not game.guard.is_physics_processing(), "active listening must freeze the actual guard timer")
	_expect(game.guard.can_cross() and is_equal_approx(game.guard.state_time, opening_time), "freezing must preserve an eligible opening, not deactivate the guard")
	native.send(request, "Ahora, salta.", false)
	_expect(game.pending_answer.is_empty() and not game.controller.guiding, "partial speech must not start the real jump")
	var generation_before: int = game.generation
	native.send(request, "¿Puedes saltar hasta la otra orilla?")
	_expect(game.voice.interpreting and native.interpretations.size() == 1 and game.pending_answer.is_empty(), "natural final transcript must wait for interpretation without moving")
	var interpretation_request: Dictionary = native.interpretations.back()
	native.send_state(request, 0)
	await _ticks(45)
	_expect(game.voice.interpreting and game.guard.can_cross() and not game.guard.is_physics_processing() and is_equal_approx(game.guard.state_time, opening_time), "old microphone terminal status and model latency must preserve the real guard opening")
	native.decide(interpretation_request, "jump")
	_expect(game.pending_answer.get("source") == "voice_ai" and game.pending_answer.get("intent") == "jump", "interpreted Spanish direction must reach the scene with model provenance")
	_expect(game.controller.guiding and game.guard.is_physics_processing() and game.generation > generation_before, "accepted voice must restore guard physics before starting the grounded jump")
	_expect(game.session_spoken == 0 and game.save.data.spoken_practice == 0, "recognition alone must not award completed spoken practice")
	var jump_generation: int = game.generation
	var answer: Dictionary = game.pending_answer.duplicate(true)
	var request_count := native.requests.size()
	var example_count := native.examples.size()
	await _ticks(2)
	_expect(game.controller.guiding and not game.player.is_on_floor(), "Hear/Speak race must run during an actual airborne guided jump")
	_expect(game.mic_button.disabled and game.hear_button.disabled, "guidance must disable both speech controls")
	# Call the real handlers as well: a previously queued activation must also
	# remain harmless after the visible buttons become disabled.
	game._hear()
	game._toggle_mic()
	_expect(game.controller.guiding and game.pending_answer == answer and game.generation == jump_generation, "queued Hear/Speak must not cancel or replace the active guided jump")
	_expect(native.requests.size() == request_count and native.examples.size() == example_count, "active guidance must not start capture or example playback")
	native.send(request, "Ahora, salta.")
	native.send_state(request, 2)
	_expect(not game.voice.listening and not game.voice.requesting and game.generation == jump_generation, "consumed native session must not reopen capture or issue a duplicate action")
	for frame in range(300):
		if game.step != 5: break
		await _ticks(1)
	_expect(game.step == 6 and game.player.is_on_floor() and game.player.position.distance_to(game.LESSONS[5].target) < 24, "spoken jump must finish through real bank collision, without teleport or direct completion")
	_expect(game.retry_count == 0 and game.session_spoken == 0 and game.save.data.spoken_practice == 0 and game.session_interpreted == 1 and game.save.data.interpreted_spoken_practice == 1, "physically completed model guidance must stay separate from exact spoken Spanish practice")

func _manual_takeover_rejects_old_voice() -> void:
	game.mic_button.pressed.emit()
	var old_request: Dictionary = native.requests.back()
	native.send_state(old_request, 2)
	await _ticks(2)
	var old_generation: int = game.generation
	var evidence: Dictionary = game.save.data.duplicate(true)
	_touch(true, Vector2(350, 400))
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(275, 400)
	drag.relative = Vector2(-75, 0)
	Input.parse_input_event(drag)
	Input.flush_buffered_events()
	await _ticks(3)
	_expect(game.generation > old_generation and game.player.velocity.x < 0, "real manual swipe must take control and invalidate the listening generation")
	_expect(not game.voice.listening and not game.voice.requesting and game.guard.is_physics_processing(), "touch takeover must release the microphone and resume the guard")
	native.send(old_request, "Espera.")
	native.send_state(old_request, 2)
	# Also exercise the scene's own generation boundary independently of the
	# native adapter, as a deferred signal could already have crossed it.
	game._voice_intent("wait", "es", old_generation)
	_expect(game.pending_answer.is_empty() and not game.controller.guiding and not game.voice.listening, "old native callbacks and an already-queued scene signal must not revive guidance")
	_expect(game.save.data == evidence and game.step == 6, "stale utterance must not create progress or spoken evidence")
	_touch(false, Vector2(275, 400), true)
	await _ticks(25)

func _typed_practice_stays_distinct() -> void:
	var spoken_before: int = game.session_spoken
	var typed_before: int = game.save.data.typed_practice
	game.voice.submit_text("Espera.")
	_expect(game.pending_answer.get("source") == "typed" and game.voice.last_source == "typed", "adapter typed input must retain its source through the actual scene signal")
	for frame in range(120):
		if game.step != 6: break
		await _ticks(1)
	_expect(game.step == 7 and game.save.data.typed_practice == typed_before + 1, "typed Spanish wait must complete through grounded time and record typed practice")
	_expect(game.session_spoken == spoken_before and game.save.data.spoken_practice == spoken_before and game.session_choices.is_empty(), "typed practice must never count as spoken practice or independent meaning choice")

func _typed_dialog_and_stale_interpretation() -> void:
	game._type_guidance()
	_expect(paused and is_instance_valid(game.modal), "typed guidance must open a paused form even with a working microphone")
	var field: LineEdit = game.modal.find_child("GuidanceText", true, false)
	field.text = "Quédate aquí un momentito"
	field.text_submitted.emit(field.text)
	_expect(not paused and game.voice.interpreting and not is_instance_valid(game.modal), "actual typed form submission must use the shared asynchronous interpreter")
	var typed_request: Dictionary = native.interpretations.back()
	native.decide(typed_request, "wait")
	_expect(game.step == 7 and game.pending_answer.is_empty() and not game.controller.guiding, "plausible but wrong AI intent cannot bypass the current Spanish lesson")
	var evidence: Dictionary = game.save.data.duplicate(true)
	game.voice.submit_text("Camina hasta ese puente, Xochi")
	var old_request: Dictionary = native.interpretations.back()
	await _ticks(2)
	_expect(game.voice.interpreting and not game.guard.is_physics_processing(), "typed interpretation also preserves guard timing")
	game._pause()
	_expect(not game.voice.interpreting and paused, "pause must cancel interpretation immediately")
	native.decide(old_request, "bridge")
	game._resume()
	await _ticks(2)
	_expect(game.pending_answer.is_empty() and not game.controller.guiding and game.save.data == evidence, "stale model result after pause cannot walk or award learning evidence")

func _pause_requires_fresh_grounded_opt_in() -> void:
	game.mic_button.pressed.emit()
	var old_request: Dictionary = native.requests.back()
	native.send_state(old_request, 2)
	await _ticks(2)
	var generation_before: int = game.generation
	game.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_expect(paused and game.current_screen == "pause" and game.generation > generation_before, "app suspension must enter the real pause transition and invalidate context")
	_expect(not game.voice.listening and not game.voice.requesting, "suspension must synchronously cancel capture")
	var count_before := native.requests.size()
	native.send_state(old_request, 2)
	native.send(old_request, "Al puente.")
	game._resume()
	await _ticks(3)
	_expect(not paused and not game.voice.listening and not game.voice.requesting and native.requests.size() == count_before, "resume must leave the microphone off until a fresh player opt-in")
	_expect(game.pending_answer.is_empty() and not game.controller.guiding and game.step == 7, "suspended utterance must not start walking on resume")
	game.player.jump_normal(true)
	await _ticks(2)
	_expect(not game.player.is_on_floor(), "airborne microphone guard fixture must use an actual jump")
	game._toggle_mic()
	game._hear()
	_expect(native.requests.size() == count_before and not game.voice.requesting and not game.voice.listening, "airborne touch override must not re-enable capture or speak the lesson")
	for frame in range(150):
		await _ticks(1)
		if game.player.is_on_floor(): break
	_expect(game.player.is_on_floor(), "manual jump must settle before a fresh opt-in")
	game.mic_button.pressed.emit()
	var fresh_request: Dictionary = native.requests.back()
	_expect(native.requests.size() == count_before + 1 and fresh_request.session != old_request.session and game.voice.requesting, "grounded fresh opt-in must create a new native request")
	native.send_state(fresh_request, 2)
	native.send_state(old_request, 0)
	native.send(old_request, "Al puente.")
	_expect(game.voice.listening and game.pending_answer.is_empty(), "old stop/transcript callbacks must not cancel the newly opted-in microphone")
	game.mic_button.pressed.emit()
	await _ticks(2)
	_expect(not game.voice.listening and not game.voice.requesting and game.guard.is_physics_processing(), "explicit Stop mic must cancel capture and resume world timing")

func _touch(pressed: bool, at: Vector2, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = at
	event.pressed = pressed
	event.canceled = canceled
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _ticks(count: int) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _finish() -> void:
	paused = false
	if is_instance_valid(game):
		if is_instance_valid(game.music):
			game.music.stop()
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
		_expect(now == original_save[path], "real user save must remain unchanged: " + path)
	for suffix in ["", ".bak", ".tmp"]:
		if not test_save.is_empty() and FileAccess.file_exists(test_save + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save + suffix))
	if failures.is_empty():
		print("[CompanionSceneVoiceSpec] PASS: fixture stage-5 frozen opening → interpreted spoken jump → real landing; shared typed form, wrong AI meaning and paused inference; stale touch generation rejected; Hear/Speak preserve guided jump; typed practice distinct; pause and airborne microphone guarded; isolated save unchanged. Fake native only; not a full-route or device-speech test.")
		quit(0)
	else:
		for failure in failures: push_error("[CompanionSceneVoiceSpec] " + failure)
		quit(1)

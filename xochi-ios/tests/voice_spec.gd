extends SceneTree
## Pure bridge tests: the native double never requests permission or records audio.
## Run: godot --headless --path xochi-ios --script res://tests/voice_spec.gd

class NativeDouble extends RefCounted:
	signal cheer(checkpoint: int, attempt: int, session: int)
	signal status(state: int, message: String, checkpoint: int, attempt: int, session: int)
	var requests: Array[Dictionary] = []
	var stop_count := 0
	var support := true

	func supported() -> bool:
		return support

	func begin_listening(locale: String, checkpoint: int, attempt: int, session: int) -> void:
		requests.append({"locale": locale, "checkpoint": checkpoint, "attempt": attempt, "session": session})

	func stop_listening() -> void:
		stop_count += 1

	func send_status(request: Dictionary, state: int, message := "Listening on device") -> void:
		status.emit(state, message, request.checkpoint, request.attempt, request.session)

	func send_cheer(request: Dictionary) -> void:
		cheer.emit(request.checkpoint, request.attempt, request.session)


const STOPPED := 0
const REQUESTING := 1
const LISTENING := 2
const UNAVAILABLE := 3
const AWARDED := 4

var failures: Array[String] = []
var cheers := 0
var messages: Array[String] = []
var bridges: Array[Node] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var probe = load("res://scripts/voice_support.gd").new()
	var status_arity := -1
	var cheer_arity := -1
	for method in probe.get_method_list():
		if method.name == "_on_status": status_arity = method.args.size()
		if method.name == "_on_cheer": cheer_arity = method.args.size()
	probe.free()
	if status_arity != 5 or cheer_arity != 3:
		push_error("[VoiceSpec] Bridge is missing the session-scoped, explicit-listening native contract")
		quit(1)
		return
	_test_real_listening_and_one_award()
	_test_award_status_before_cheer()
	_test_stale_context_and_status()
	_test_same_attempt_restart()
	_test_manual_stop()
	_test_unavailable_fallback()
	_test_terminal_states()
	_test_focus_loss()
	for bridge in bridges:
		bridge.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("[VoiceSpec] PASS: actual listening transition, stale context and session rejection, stale status rejection, duplicate award closure, manual stop, unsupported fallback and focus cleanup; no microphone accessed")
		quit(0)
	else:
		for failure in failures:
			push_error("[VoiceSpec] " + failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _fixture(supported := true) -> Dictionary:
	var bridge = load("res://scripts/voice_support.gd").new()
	root.add_child(bridge)
	var native := NativeDouble.new()
	native.support = supported
	bridge._native = native
	bridge.available = supported
	native.cheer.connect(bridge._on_cheer)
	native.status.connect(bridge._on_status)
	bridge.encouragement.connect(func(): cheers += 1)
	bridge.status_changed.connect(func(message: String): messages.append(message))
	bridges.append(bridge)
	return {"bridge": bridge, "native": native}


func _test_real_listening_and_one_award() -> void:
	var fixture := _fixture()
	var bridge = fixture.bridge
	var native: NativeDouble = fixture.native
	var before := cheers
	bridge.start("en", 1, 7)
	_expect(native.requests.size() == 1, "a supported start must reach the native bridge")
	if native.requests.is_empty():
		return
	var request: Dictionary = native.requests.back()
	_expect(request.locale == "en" and request.checkpoint == 1 and request.attempt == 7, "start must preserve locale, checkpoint and attempt")
	# Preparing is not capture. Actual native state, rather than localized
	# status wording, decides when the listening indicator becomes active.
	native.send_status(request, REQUESTING, "Preparing on-device speech")
	_expect(bridge.requesting and not bridge.listening, "requesting must stay distinct from actual listening")
	native.send_status(request, LISTENING, "Listening on device")
	_expect(bridge.listening and not bridge.requesting, "actual native Listening must activate the current session")
	native.send_cheer(request)
	_expect(cheers == before + 1 and not bridge.listening, "a current listening cheer must award exactly once and close listening")
	native.send_cheer(request)
	native.send_status(request, AWARDED, "Second Wind ready")
	native.send_status(request, LISTENING, "Listening on device")
	native.send_cheer(request)
	_expect(cheers == before + 1 and not bridge.listening, "late Listening and duplicate cheers must not reopen a consumed session")


func _test_stale_context_and_status() -> void:
	var fixture := _fixture()
	var bridge = fixture.bridge
	var native: NativeDouble = fixture.native
	bridge.start("en", 0, 3)
	var old: Dictionary = native.requests.back()
	native.send_status(old, LISTENING)
	bridge.start("es", 1, 4)
	var current: Dictionary = native.requests.back()
	native.send_status(current, LISTENING, "Escuchando en el dispositivo")
	var before := cheers
	var status_count := messages.size()
	native.send_status(old, STOPPED, "Microphone off")
	native.send_status(old, LISTENING, "Old session listening")
	native.send_cheer(old)
	_expect(bridge.listening and cheers == before, "old checkpoint/attempt callbacks must not alter the current session")
	_expect(messages.size() == status_count, "stale status text must not overwrite the current UI")
	var wrong_checkpoint := current.duplicate()
	wrong_checkpoint.checkpoint = 0
	var wrong_attempt := current.duplicate()
	wrong_attempt.attempt = 3
	native.send_cheer(wrong_checkpoint)
	native.send_cheer(wrong_attempt)
	native.send_status(wrong_attempt, STOPPED, "Recognition ended")
	_expect(cheers == before and bridge.listening, "checkpoint and attempt must each be validated independently of session")
	native.send_cheer(current)
	_expect(cheers == before + 1, "the current Spanish session must still award after stale events")


func _test_award_status_before_cheer() -> void:
	var fixture := _fixture()
	var bridge = fixture.bridge
	var native: NativeDouble = fixture.native
	bridge.start("es", 1, 7)
	var request: Dictionary = native.requests.back()
	native.send_status(request, LISTENING, "Escuchando en el dispositivo")
	var before := cheers
	native.send_status(request, AWARDED, "¡Segundo aliento listo!")
	_expect(not bridge.listening and not bridge.requesting, "award status must turn off the capture indicator")
	native.send_cheer(request)
	native.send_cheer(request)
	native.send_status(request, LISTENING)
	_expect(cheers == before + 1 and not bridge.listening, "award status arriving before cheer must still yield exactly one boost")


func _test_same_attempt_restart() -> void:
	var fixture := _fixture()
	var bridge = fixture.bridge
	var native: NativeDouble = fixture.native
	bridge.start("en", 2, 8)
	var first: Dictionary = native.requests.back()
	native.send_status(first, LISTENING)
	bridge.stop()
	bridge.start("en", 2, 8)
	var second: Dictionary = native.requests.back()
	_expect(first.session != second.session, "restarting inside one attempt requires a new session token")
	native.send_status(second, LISTENING)
	var before := cheers
	var status_count := messages.size()
	native.send_status(first, STOPPED, "Microphone off")
	native.send_cheer(first)
	_expect(bridge.listening and cheers == before and messages.size() == status_count, "a delayed stop from a previous listening session must not cancel the new one")
	native.send_cheer(second)
	_expect(cheers == before + 1, "the replacement session must remain usable")


func _test_manual_stop() -> void:
	var fixture := _fixture()
	var bridge = fixture.bridge
	var native: NativeDouble = fixture.native
	bridge.start("en", 0, 1)
	var request: Dictionary = native.requests.back()
	native.send_status(request, LISTENING)
	var before := cheers
	var stops := native.stop_count
	bridge.stop()
	_expect(not bridge.listening and native.stop_count == stops + 1, "manual stop must immediately turn off state and ask native capture to stop")
	var status_count := messages.size()
	native.send_status(request, LISTENING)
	native.send_status(request, STOPPED, "Microphone off")
	native.send_cheer(request)
	_expect(not bridge.listening and cheers == before and messages.size() == status_count, "queued native callbacks after manual stop must be inert")
	bridge.stop()
	_expect(not bridge.listening, "repeated stop must remain safe")


func _test_unavailable_fallback() -> void:
	var fixture := _fixture(false)
	var bridge = fixture.bridge
	var native: NativeDouble = fixture.native
	var before := cheers
	bridge.start("en", 0, 1)
	_expect(native.requests.is_empty() and not bridge.listening and cheers == before, "unsupported voice must not start native capture or award power")
	_expect(not messages.is_empty() and "Courage" in messages.back(), "English unsupported state must explain the equal Courage fallback")
	bridge.start("es", 0, 1)
	_expect(native.requests.is_empty() and not bridge.listening and "Ánimo" in messages.back(), "Spanish unsupported state must explain the equal Ánimo fallback")
	bridge.stop()


func _test_focus_loss() -> void:
	var fixture := _fixture()
	var bridge = fixture.bridge
	var native: NativeDouble = fixture.native
	bridge.start("en", 3, 9)
	var request: Dictionary = native.requests.back()
	native.send_status(request, LISTENING)
	var stops := native.stop_count
	var before := cheers
	bridge.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(not bridge.listening and native.stop_count == stops + 1, "application focus loss must immediately stop capture")
	native.send_cheer(request)
	_expect(cheers == before, "a backgrounded session must not award a queued cheer")


func _test_terminal_states() -> void:
	for state in [STOPPED, UNAVAILABLE]:
		var fixture := _fixture()
		var bridge = fixture.bridge
		var native: NativeDouble = fixture.native
		bridge.start("en", 1, 2)
		var request: Dictionary = native.requests.back()
		native.send_status(request, REQUESTING, "Preparing")
		native.send_status(request, LISTENING)
		var before := cheers
		native.send_status(request, state, "Recognition ended" if state == STOPPED else "Speech unavailable. Tap Courage.")
		_expect(not bridge.listening and not bridge.requesting, "terminal status must clear both permission and capture state")
		native.send_cheer(request)
		native.send_status(request, LISTENING)
		native.send_cheer(request)
		_expect(cheers == before and not bridge.listening, "terminal status must reject late capture and cheer callbacks")
	var fixture := _fixture()
	var bridge = fixture.bridge
	var native: NativeDouble = fixture.native
	bridge.start("en", 1, 2)
	var request: Dictionary = native.requests.back()
	native.send_status(request, REQUESTING, "Preparing")
	bridge.stop()
	native.send_status(request, LISTENING)
	_expect(not bridge.listening and not bridge.requesting, "stopping during permission preparation must reject a delayed permission success")

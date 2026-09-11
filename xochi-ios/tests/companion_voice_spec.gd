extends SceneTree
const Intents = preload("res://scripts/spanish_intents.gd")
const Companion = preload("res://scripts/companion_voice.gd")
class NativeDouble extends RefCounted:
	signal transcript(text: String, language: String, final: bool, checkpoint: int, attempt: int, session: int)
	signal status(state: int, message: String, checkpoint: int, attempt: int, session: int)
	signal interpretation(intent: String, language: String, checkpoint: int, attempt: int, session: int)
	var requests: Array[Dictionary] = []
	var ai_requests: Array[Dictionary] = []
	var preparations: Array[String] = []
	var call_order: Array[String] = []
	var ai_status := "unavailable"
	var stops := 0
	var examples: Array[String] = []
	var supported_languages := ["es", "en"]
	func supported_locale(locale: String) -> bool: return locale in supported_languages
	func begin_transcribing(locale: String, cp: int, attempt: int, session: int) -> void:
		call_order.append("begin")
		requests.append({"locale":locale,"cp":cp,"attempt":attempt,"session":session})
	func stop_listening() -> void:
		stops += 1
		call_order.append("stop")
	func intelligence_status(_locale: String) -> String: return ai_status
	func prepare_intelligence(locale: String) -> void:
		preparations.append(locale)
		call_order.append("prepare")
	func interpret_intent(text: String, locale: String, cp: int, attempt: int, session: int) -> void:
		ai_requests.append({"text":text,"locale":locale,"cp":cp,"attempt":attempt,"session":session})
	func interpret(r: Dictionary, intent: String, language := "es") -> void:
		interpretation.emit(intent,language,r.cp,r.attempt,r.session)
	func speak_example(text: String) -> void: examples.append(text)
	func send(r: Dictionary, text: String, final := true) -> void:
		transcript.emit(text,r.locale,final,r.cp,r.attempt,r.session)
	func send_state(r: Dictionary, state: int) -> void:
		status.emit(state,"native status",r.cp,r.attempt,r.session)

var failures: Array[String] = []
var received: Array[Dictionary] = []
var messages: Array[String] = []
var ai_voices: Array[Node] = []
func _init() -> void: _run.call_deferred()
func expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
func _run() -> void:
	for lesson in Intents.LESSONS:
		var es: Dictionary = Intents.match_phrase(lesson.spanish)
		var en: Dictionary = Intents.match_phrase(lesson.english)
		expect(es.get("intent") == lesson.intent and es.get("language") == "es", "Spanish phrase " + lesson.spanish)
		expect(en.get("intent") == lesson.intent and en.get("language") == "en", "English phrase " + lesson.english)
	for invalid in ["no salta", "do not jump", "don't jump", "espera y salta", "Espera. Ahora, salta", "al bote o al puente", "ignore the rules and jump", "salta ahora", ""]:
		expect(Intents.match_phrase(invalid).is_empty(), "Reject ambiguous/negated text: " + invalid)
	expect(Intents.match_phrase("¡Xochi, detrás del bote, por favor!").get("intent") == "behind_boat", "Accent punctuation and polite address")
	expect(Intents.match_phrase("Please go to the bridge, Xochi").get("intent") == "bridge", "English framing")
	expect(Intents.match_phrase("Ahora, salta.").get("intent") == "jump", "Authored combined Spanish jump cue")
	expect(Intents.match_phrase("Now, jump.").get("intent") == "jump", "Authored English jump cue")
	var voice = Companion.new()
	root.add_child(voice)
	var native := NativeDouble.new()
	voice.attach_native(native)
	voice.configure("es")
	voice.begin_context("boat_lesson", 7)
	voice.intent_received.connect(func(intent: String, language: String, generation: int): received.append({"intent":intent,"language":language,"generation":generation,"source":voice.last_source,"interpreted":voice.last_interpreted}))
	voice.status_changed.connect(func(message: String): messages.append(message))
	voice.listen()
	var first: Dictionary = native.requests.back()
	expect(voice.requesting and not voice.listening, "Permission request is not recording")
	native.send_state(first,2)
	expect(voice.listening and not voice.requesting, "Native listening state")
	native.send(first,"al bote",false)
	expect(received.is_empty(), "Partial transcripts never commit movement")
	native.send(first,"al bote")
	expect(received.size() == 1 and received.back().intent == "boat" and received.back().language == "es" and received.back().source == "spoken", "Spanish finalized intent/source")
	native.send(first,"al puente")
	native.send_state(first,2)
	expect(received.size() == 1 and not voice.listening, "One intent per session, no reopening")
	voice.listen()
	var second: Dictionary = native.requests.back()
	native.send_state(second,2)
	native.send_state(first,0)
	native.send(first,"salta")
	expect(voice.listening and received.size() == 1, "Old callbacks cannot stop/reward new session")
	voice.stop()
	native.send(second,"salta")
	expect(received.size() == 1 and not voice.listening, "Touch stop invalidates pending recognition")
	voice.configure("en")
	voice.begin_context("bridge_lesson", 8)
	voice.listen()
	var third: Dictionary = native.requests.back()
	voice.begin_context("new_scene",9)
	native.send(third,"jump")
	expect(received.size() == 1, "Scene changes invalidate pending intentions")
	voice.listen()
	var fourth: Dictionary = native.requests.back()
	native.send(fourth,"behind the boat")
	expect(received.size() == 2 and received.back().intent == "behind_boat" and received.back().language == "en" and received.back().generation == 9, "English rescue recognizer intent/generation")
	voice.listen()
	var fifth: Dictionary = native.requests.back()
	native.send(fifth,"no salta")
	expect(received.size() == 2 and not voice.listening and "choose" in messages.back(), "Unrecognized phrase is harmless and offers comprehension alternative")
	voice.listen()
	var sixth: Dictionary = native.requests.back()
	voice.speak_example("Detrás del bote")
	expect(native.examples == ["Detrás del bote"] and not voice.listening and not voice.requesting, "Authored Spanish example with microphone off in English mode")
	native.send(sixth,"salta")
	expect(received.size() == 2, "Example playback cannot accept stale captured speech")
	voice.speak_example("Tell me a long invented story")
	expect(native.examples.size() == 1, "Only authored examples can speak")
	voice.speak_example("Ahora, salta.")
	expect(native.examples.back() == "Ahora, salta.", "Combined authored jump example speaks")
	voice.submit_text("Espera")
	expect(received.size() == 3 and received.back().source == "typed" and received.back().language == "es", "Typed Spanish is explicitly distinct from spoken practice")
	native.supported_languages = ["en"]
	voice.configure("es")
	voice.listen()
	expect(not voice.available and not voice.requesting, "Selected locale support independently checked")
	voice.configure("en")
	voice.listen()
	var seventh: Dictionary = native.requests.back()
	voice.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	native.send(seventh,"jump")
	expect(received.size() == 3 and not voice.listening, "Background capture canceled")
	var replacement = Companion.new()
	root.add_child(replacement)
	replacement.attach_native(native)
	replacement.configure("en")
	replacement.begin_context("new_scene",9)
	replacement.listen()
	var replacement_request: Dictionary = native.requests.back()
	expect(replacement_request.session != seventh.session, "Replacement nodes must not reuse native session IDs")
	_test_exact_skips_intelligence()
	_test_typed_and_spoken_interpretation()
	_test_interpretation_validation()
	_test_interpretation_cancellation()
	_test_intelligence_availability()
	_test_interpretation_preparation()
	await _test_interpretation_timeout()
	voice.queue_free()
	replacement.queue_free()
	for ai_voice in ai_voices: ai_voice.queue_free()
	await process_frame
	if failures.is_empty():
		print("[CompanionVoiceSpec] PASS: exact fast path; typed/spoken AI fallback; fresh speech-to-AI session; stale/duplicate/invalid output rejection; explicit unknown language/source; manual/retry/background/locale cancellation; availability-gated empty preparation before capture; bounded timeout and harmless fallback. No microphone or model accessed.")
		quit(0)
	else:
		for failure in failures: push_error("[CompanionVoiceSpec] " + failure)
		quit(1)


func _ai_fixture(status := "available") -> Dictionary:
	var voice = Companion.new()
	root.add_child(voice)
	ai_voices.append(voice)
	var native := NativeDouble.new()
	native.ai_status = status
	voice.attach_native(native)
	voice.configure("es")
	voice.begin_context("crossing", 11)
	voice.intent_received.connect(func(intent: String, language: String, generation: int):
		received.append({"intent":intent,"language":language,"generation":generation,"source":voice.last_source,"interpreted":voice.last_interpreted}))
	voice.status_changed.connect(func(message: String): messages.append(message))
	return {"voice":voice,"native":native}


func _test_exact_skips_intelligence() -> void:
	var fixture := _ai_fixture()
	var voice = fixture.voice
	var native: NativeDouble = fixture.native
	var before := received.size()
	voice.submit_text("Espera")
	expect(received.size() == before + 1 and received.back().source == "typed" and not received.back().interpreted and received.back().language == "es", "Exact typed Spanish must deliver immediately with original evidence metadata")
	voice.listen()
	var request: Dictionary = native.requests.back()
	native.send(request, "jump")
	expect(received.size() == before + 2 and received.back().source == "spoken" and received.back().language == "en" and not received.back().interpreted, "Exact spoken English must retain its language even when Spanish capture is selected")
	expect(native.ai_requests.is_empty() and not voice.interpreting, "Exact phrases must never call Apple Intelligence")
	voice.stop()
	expect(voice.last_source == "spoken" and not voice.last_interpreted, "Stop must preserve delivered metadata for the scene to consume")


func _test_typed_and_spoken_interpretation() -> void:
	var fixture := _ai_fixture()
	var voice = fixture.voice
	var native: NativeDouble = fixture.native
	var before := received.size()
	voice.submit_text("¿Podrías quedarte aquí un momentito?")
	expect(voice.interpreting and not voice.listening and not voice.requesting and native.ai_requests.size() == 1, "Natural typed phrasing must enter bounded interpretation without opening capture")
	expect(received.size() == before and "Pensando" in messages.back(), "Thinking must not itself commit an action")
	var typed: Dictionary = native.ai_requests.back()
	native.interpret(typed, "wait", "es")
	expect(received.size() == before + 1 and received.back().source == "typed" and received.back().interpreted and received.back().language == "es", "Typed AI outcome must expose source, AI provenance and detected Spanish before signal delivery")
	voice.stop()
	expect(voice.last_source == "typed" and voice.last_interpreted, "Manual stop must not erase the outcome provenance")
	voice.listen()
	var speech: Dictionary = native.requests.back()
	native.send_state(speech, 2)
	native.send(speech, "Could you hop over to that side?", false)
	expect(native.ai_requests.size() == 1 and voice.listening, "Partial natural speech must not start AI")
	native.send(speech, "Could you hop over to that side?")
	var interpreted: Dictionary = native.ai_requests.back()
	expect(interpreted.session != speech.session and voice.interpreting and not voice.listening, "Final speech must close capture and allocate a fresh AI session")
	native.send_state(speech, 0)
	native.send_state(speech, 3)
	native.send_state(speech, 2)
	native.send(speech, "salta")
	# Speech status is not an interpretation result, even if a broken native
	# callback accidentally labels it with the new interpretation session.
	native.send_state(interpreted, 0)
	expect(voice.interpreting and received.size() == before + 1 and native.ai_requests.size() == 2, "Late microphone terminal/listening events must not cancel or duplicate interpretation")
	native.interpret(interpreted, "jump", "en")
	expect(received.size() == before + 2 and received.back().source == "spoken" and received.back().interpreted and received.back().language == "en", "Spoken AI result must retain detected English, not coerce Spanish capture locale")
	native.interpret(interpreted, "boat", "es")
	expect(received.size() == before + 2 and not voice.interpreting, "AI session must deliver only once")
	voice.submit_text("Please head toward that hiding place")
	native.interpret(native.ai_requests.back(), "behind_boat", "unknown")
	expect(received.back().intent == "behind_boat" and received.back().language == "unknown" and received.back().interpreted, "Unknown language must remain explicit and cannot become Spanish credit")


func _test_interpretation_validation() -> void:
	var fixture := _ai_fixture()
	var voice = fixture.voice
	var native: NativeDouble = fixture.native
	var before := received.size()
	for answer in [["", "unknown"], ["teleport", "es"], ["wait", "es-MX"], ["jump", ""], ["save_game", "en"]]:
		voice.submit_text("Find a way to help my friend")
		native.interpret(native.ai_requests.back(), answer[0], answer[1])
		expect(not voice.interpreting and received.size() == before, "Invalid/empty native intent or language must close harmlessly: " + str(answer))
	voice.submit_text("Please let her know the moment has come")
	var current: Dictionary = native.ai_requests.back()
	for field in ["cp", "attempt", "session"]:
		var bad := current.duplicate()
		bad[field] += 1
		native.interpret(bad, "now", "en")
		expect(voice.interpreting and received.size() == before, "Each context/session field must independently reject a stale AI result: " + field)
	native.interpret(current, "now", "en")
	expect(received.size() == before + 1 and received.back().intent == "now", "A valid current finite intent must still work after stale callbacks")
	voice.begin_context("", -1)
	var requests_before := native.ai_requests.size()
	voice.submit_text("Could you come closer for a moment?")
	voice.submit_text("Ven")
	expect(native.ai_requests.size() == requests_before and received.size() == before + 1, "Neither exact nor AI input may move a character without an active scene context")
	voice.begin_context("crossing", 11)
	voice.submit_text("")
	voice.submit_text("a".repeat(241))
	expect(native.ai_requests.size() == requests_before and not voice.interpreting, "Empty and oversized input must not submit a truncated or unbounded request")


func _test_interpretation_cancellation() -> void:
	for action in ["manual", "retry", "background", "application_paused", "locale", "example"]:
		var fixture := _ai_fixture()
		var voice = fixture.voice
		var native: NativeDouble = fixture.native
		voice.submit_text("Would you take that little boat across?")
		var old: Dictionary = native.ai_requests.back()
		var before := received.size()
		match action:
			"manual": voice.stop()
			"retry": voice.begin_context("crossing-retry", 12)
			"background": voice.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
			"application_paused": voice.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
			"locale": voice.configure("en")
			"example": voice.speak_example("Al bote")
		var messages_before := messages.size()
		native.interpret(old, "boat", "es")
		expect(not voice.interpreting and received.size() == before and messages.size() == messages_before, "Canceled AI must never deliver or replace UI status after " + action)
		voice.submit_text("Could you stay right where you are?")
		var current: Dictionary = native.ai_requests.back()
		native.interpret(old, "jump", "es")
		expect(voice.interpreting and old.session != current.session, "Replacement request needs a fresh session after " + action)
		native.interpret(current, "wait", "en")
		expect(received.size() == before + 1 and received.back().language == "en", "Fresh guidance must work after " + action)
	# A synchronous consumer can also cancel on the status update before delivery.
	var fixture := _ai_fixture()
	var voice = fixture.voice
	var native: NativeDouble = fixture.native
	voice.submit_text("Could you head over here?")
	var before := received.size()
	voice.status_changed.connect(func(message: String):
		if message == "Entendido": voice.stop())
	native.interpret(native.ai_requests.back(), "come", "es")
	expect(received.size() == before, "Status-triggered synchronous cancellation must precede action delivery")


func _test_intelligence_availability() -> void:
	var fixture := _ai_fixture("unsupported_device")
	var voice = fixture.voice
	var native: NativeDouble = fixture.native
	for status in ["disabled", "not_ready", "unsupported_device", "unsupported_locale", "unavailable", "unexpected_status"]:
		native.ai_status = status
		voice.refresh_availability()
		var expected: String = "unavailable" if status == "unexpected_status" else status
		expect(not voice.intelligence_available and voice.intelligence_status == expected and voice.available, "AI availability must retain its reason independently of speech support: " + status)
		voice.submit_text("Could you find the right way across?")
		expect(native.ai_requests.is_empty() and not voice.interpreting, "Unavailable intelligence must fall back without calling the model: " + status)
	var before := received.size()
	voice.submit_text("Espera")
	expect(received.size() == before + 1 and not received.back().interpreted, "Exact fallback must work without Apple Intelligence")
	native.ai_status = "available"
	native.supported_languages = []
	voice.refresh_availability()
	expect(voice.intelligence_available and not voice.available, "Typed interpretation availability must be independent of microphone language support")
	voice.submit_text("Could you please wait beside me?")
	native.interpret(native.ai_requests.back(), "wait", "en")
	expect(received.back().interpreted and received.back().source == "typed", "Natural typed guidance must work when speech capture is unavailable")


func _test_interpretation_preparation() -> void:
	var fixture := _ai_fixture("disabled")
	var voice = fixture.voice
	var native: NativeDouble = fixture.native
	voice.prepare_interpretation()
	expect(native.preparations.is_empty() and not voice.interpreting and not voice.requesting and not voice.listening, "Unavailable intelligence must not prepare a session or open capture")
	native.ai_status = "available"
	var session: int = voice._session
	var before := received.size()
	voice.prepare_interpretation()
	expect(voice.intelligence_available and native.preparations == ["es"], "Public preparation must refresh availability and use the selected locale")
	expect(not voice.interpreting and not voice.requesting and not voice.listening and not voice._active and voice._session == session, "Empty preparation must leave capture, action, context and session state unchanged")
	expect(native.requests.is_empty() and native.ai_requests.is_empty() and received.size() == before, "Preparation must contain no user request and must never deliver an intention")
	voice.configure("en")
	native.call_order.clear()
	voice.listen()
	expect(native.call_order == ["stop", "prepare", "begin"] and native.preparations.back() == "en", "Speech start must stop previous work, prepare the selected locale, then begin capture")
	expect(voice.requesting and not voice.interpreting and native.ai_requests.is_empty(), "Preparing before speech must not mark an interpretation in flight")
	voice.stop()


func _test_interpretation_timeout() -> void:
	var fixture := _ai_fixture()
	var voice = fixture.voice
	var native: NativeDouble = fixture.native
	voice.submit_text("Could you find a safe place to hide?")
	var request: Dictionary = native.ai_requests.back()
	var before := received.size()
	var stops := native.stops
	# The fake deliberately hangs. The real Timer must expire even when gameplay
	# is paused/slowed; fixed-fps makes this deterministic without a six-second wait.
	paused = true
	Engine.time_scale = 0.5
	for tick in range(375):
		await process_frame
	Engine.time_scale = 1.0
	paused = false
	expect(not voice.interpreting and not voice.listening and native.stops > stops and received.size() == before, "A hung native interpretation must time out and cancel native work")
	var messages_before := messages.size()
	native.interpret(request, "behind_boat", "es")
	expect(received.size() == before and messages.size() == messages_before, "A late successful result after timeout must remain inert")

extends Node
## Session-scoped spoken intentions, independent of classic cheering rewards.
signal intent_received(intent: String, language: String, generation: int)
signal status_changed(text: String)
signal availability_changed
const Intents = preload("res://scripts/spanish_intents.gd")
const INTERPRETATION_TIMEOUT := 6.0
const MAX_INTERPRETATION_LENGTH := 240
const AI_INTENTS := ["come", "wait", "boat", "bridge", "behind_boat", "now", "jump"]
const AI_LANGUAGES := ["es", "en", "unknown"]
const INTELLIGENCE_STATES := ["available", "disabled", "not_ready", "unsupported_device", "unsupported_locale", "unavailable"]
enum State { STOPPED, REQUESTING, LISTENING, UNAVAILABLE, AWARDED }
var last_source := ""
var last_interpreted := false
var available := false
var intelligence_available := false
var intelligence_status := "unavailable"
var listening := false
var requesting := false
var interpreting := false
var _native: Object
var _locale := "es"
var _scene_id := ""
var _generation := -1
static var _next_session := 1000000
var _session := 0
var _active := false
var _pending_source := ""
var _interpret_timer: Timer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_interpret_timer = Timer.new()
	_interpret_timer.one_shot = true
	_interpret_timer.ignore_time_scale = true
	_interpret_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_interpret_timer.timeout.connect(_on_interpretation_timeout)
	add_child(_interpret_timer)
	if Engine.has_singleton("XochiVoice"):
		attach_native(Engine.get_singleton("XochiVoice"))

func attach_native(native: Object) -> void:
	stop()
	if is_instance_valid(_native):
		if _native.has_signal("transcript") and _native.transcript.is_connected(_on_transcript): _native.transcript.disconnect(_on_transcript)
		if _native.has_signal("status") and _native.status.is_connected(_on_status): _native.status.disconnect(_on_status)
		if _native.has_signal("interpretation") and _native.interpretation.is_connected(_on_interpretation): _native.interpretation.disconnect(_on_interpretation)
	_native = native
	if is_instance_valid(_native) and _native.has_signal("transcript"):
		_native.transcript.connect(_on_transcript)
	if is_instance_valid(_native) and _native.has_signal("status"):
		_native.status.connect(_on_status)
	if is_instance_valid(_native) and _native.has_signal("interpretation"):
		_native.interpretation.connect(_on_interpretation)
	_refresh_availability()

func configure(locale: String) -> void:
	stop()
	_locale = "es" if locale.begins_with("es") else "en"
	_refresh_availability()

func _refresh_availability() -> void:
	refresh_availability()

func refresh_availability() -> void:
	var next := is_instance_valid(_native) and _native.has_signal("transcript") and _native.has_signal("status") and _native.has_method("begin_transcribing") and _native.has_method("supported_locale") and _native.has_method("stop_listening")
	if next: next = _native.supported_locale(_locale)
	available = next
	intelligence_status = "unavailable"
	var can_interpret := is_instance_valid(_native) and _native.has_signal("interpretation") and _native.has_method("interpret_intent") and _native.has_method("intelligence_status") and _native.has_method("stop_listening")
	if can_interpret:
		var status: String = _native.intelligence_status(_locale)
		if status in INTELLIGENCE_STATES:
			intelligence_status = status
	intelligence_available = intelligence_status == "available"
	availability_changed.emit()

func prepare_interpretation() -> void:
	# Native preparation contains no user text or scene context and never opens
	# capture. Its empty warm session may survive stop() until the next utterance.
	refresh_availability()
	if intelligence_available and is_instance_valid(_native) and _native.has_method("prepare_intelligence"):
		_native.prepare_intelligence(_locale)

func begin_context(scene_id: String, generation: int) -> void:
	stop()
	_scene_id = scene_id
	_generation = generation

func listen() -> void:
	stop()
	last_source = ""
	last_interpreted = false
	_refresh_availability()
	if not available or _scene_id.is_empty() or _generation < 0:
		status_changed.emit(_tr("Voice unavailable. Listen to the phrase, then choose its meaning.", "Voz no disponible. Escucha la frase y elige su significado."))
		return
	prepare_interpretation()
	_active = true
	requesting = true
	status_changed.emit(_tr("Preparing microphone…", "Preparando micrófono…"))
	_native.begin_transcribing(_locale, _generation, 0, _session)

func stop() -> void:
	_next_session += 1
	_session = _next_session
	_active = false
	requesting = false
	listening = false
	interpreting = false
	_pending_source = ""
	if is_instance_valid(_interpret_timer): _interpret_timer.stop()
	if is_instance_valid(_native) and _native.has_method("stop_listening"): _native.stop_listening()

func submit_text(text: String) -> void:
	_handle_text(text, "typed")

func _handle_text(text: String, source: String) -> void:
	# Final speech closes capture and allocates a distinct interpretation session.
	# Its late STOPPED/LISTENING callbacks can never affect the new AI request.
	stop()
	last_source = source
	last_interpreted = false
	if _scene_id.is_empty() or _generation < 0: return
	var match_data: Dictionary = Intents.match_phrase(text)
	if not match_data.is_empty():
		_deliver(match_data.intent, match_data.language, source, false)
		return
	refresh_availability()
	if not intelligence_available or not is_instance_valid(_interpret_timer) or text.strip_edges().is_empty() or text.length() > MAX_INTERPRETATION_LENGTH:
		_fallback()
		return
	_active = true
	interpreting = true
	_pending_source = source
	var checkpoint := _generation
	var session := _session
	_interpret_timer.start(INTERPRETATION_TIMEOUT)
	status_changed.emit(_tr("Thinking…", "Pensando…"))
	if interpreting and _matches(checkpoint, 0, session):
		_native.interpret_intent(text, _locale, checkpoint, 0, session)

func _deliver(intent: String, language: String, source: String, interpreted: bool) -> void:
	var generation := _generation
	var scene_id := _scene_id
	stop()
	last_source = source
	last_interpreted = interpreted
	var session := _session
	status_changed.emit(_tr("Understood", "Entendido"))
	# A scene can synchronously cancel from a status callback, before delivery.
	if session == _session and generation == _generation and scene_id == _scene_id and not scene_id.is_empty():
		intent_received.emit(intent, language, generation)

func _fallback() -> void:
	stop()
	status_changed.emit(_tr("Try a short direction, or choose its meaning.", "Prueba una indicación breve o elige su significado."))

func _on_interpretation_timeout() -> void:
	if interpreting and _active:
		_fallback()

func _on_interpretation(intent: String, language: String, checkpoint: int, attempt: int, session: int) -> void:
	if not interpreting or not _matches(checkpoint, attempt, session): return
	if intent not in AI_INTENTS or language not in AI_LANGUAGES:
		_fallback()
		return
	_deliver(intent, language, _pending_source, true)

func speak_example(text: String) -> void:
	stop()
	# Only replay the authored lesson phrases, never model/user-supplied speech.
	var authored := false
	for phrase in Intents.SPOKEN_EXAMPLES:
		if Intents.normalize(text) == Intents.normalize(phrase): authored = true
	if not authored:
		return
	if is_instance_valid(_native) and _native.has_method("speak_example"):
		_native.speak_example(text)
		status_changed.emit(_tr("Listen, then choose what Xochi should do.", "Escucha y elige qué debe hacer Xochi."))
	else:
		status_changed.emit(_tr("Read the phrase, then choose its meaning.", "Lee la frase y elige su significado."))

func _matches(checkpoint: int, attempt: int, session: int) -> bool:
	return _active and not _scene_id.is_empty() and _generation >= 0 and checkpoint == _generation and attempt == 0 and session == _session

func _on_transcript(text: String, _native_language: String, final: bool, checkpoint: int, attempt: int, session: int) -> void:
	if not final or interpreting or not _matches(checkpoint, attempt, session): return
	_handle_text(text, "spoken")

func _on_status(state: int, message: String, checkpoint: int, attempt: int, session: int) -> void:
	if interpreting or not _matches(checkpoint, attempt, session): return
	match state:
		State.REQUESTING:
			requesting = true
			listening = false
		State.LISTENING:
			requesting = false
			listening = true
		State.STOPPED, State.UNAVAILABLE:
			stop()
			message = _tr("Microphone off. Try again or choose the meaning.", "Micrófono apagado. Reintenta o elige el significado.")
		_:
			return
	status_changed.emit(message)

func _tr(en: String, es: String) -> String:
	return es if _locale == "es" else en

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]: stop()

func _exit_tree() -> void:
	stop()

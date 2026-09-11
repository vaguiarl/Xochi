extends Node
## Session-scoped spoken intentions, independent of classic cheering rewards.
signal intent_received(intent: String, language: String, generation: int)
signal status_changed(text: String)
signal availability_changed
const Intents = preload("res://scripts/spanish_intents.gd")
enum State { STOPPED, REQUESTING, LISTENING, UNAVAILABLE, AWARDED }
var last_source := ""
var available := false
var listening := false
var requesting := false
var _native: Object
var _locale := "es"
var _scene_id := ""
var _generation := -1
static var _next_session := 1000000
var _session := 0
var _active := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Engine.has_singleton("XochiVoice"):
		attach_native(Engine.get_singleton("XochiVoice"))

func attach_native(native: Object) -> void:
	stop()
	if is_instance_valid(_native):
		if _native.has_signal("transcript") and _native.transcript.is_connected(_on_transcript): _native.transcript.disconnect(_on_transcript)
		if _native.has_signal("status") and _native.status.is_connected(_on_status): _native.status.disconnect(_on_status)
	_native = native
	if is_instance_valid(_native) and _native.has_signal("transcript"):
		_native.transcript.connect(_on_transcript)
		_native.status.connect(_on_status)
	_refresh_availability()

func configure(locale: String) -> void:
	stop()
	_locale = "es" if locale.begins_with("es") else "en"
	_refresh_availability()

func _refresh_availability() -> void:
	var next := is_instance_valid(_native) and _native.has_signal("transcript") and _native.has_method("begin_transcribing") and _native.has_method("supported_locale")
	if next: next = _native.supported_locale(_locale)
	available = next
	availability_changed.emit()

func begin_context(scene_id: String, generation: int) -> void:
	stop()
	_scene_id = scene_id
	_generation = generation

func listen() -> void:
	stop()
	_refresh_availability()
	if not available or _scene_id.is_empty() or _generation < 0:
		status_changed.emit(_tr("Voice unavailable. Listen to the phrase, then choose its meaning.", "Voz no disponible. Escucha la frase y elige su significado."))
		return
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
	if is_instance_valid(_native): _native.stop_listening()

func submit_text(text: String) -> void:
	stop()
	if _scene_id.is_empty() or _generation < 0: return
	var match_data: Dictionary = Intents.match_phrase(text)
	if match_data.is_empty():
		status_changed.emit(_tr("Try one direction, or choose its meaning.", "Prueba una indicación o elige su significado."))
		return
	last_source = "typed"
	status_changed.emit(_tr("Understood", "Entendido"))
	intent_received.emit(match_data.intent, match_data.language, _generation)

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
	return _active and checkpoint == _generation and attempt == 0 and session == _session

func _on_transcript(text: String, _native_language: String, final: bool, checkpoint: int, attempt: int, session: int) -> void:
	if not final or not _matches(checkpoint, attempt, session): return
	var match_data: Dictionary = Intents.match_phrase(text)
	var current_generation := _generation
	stop()
	if match_data.is_empty():
		status_changed.emit(_tr("I did not catch that. Try again, or choose the meaning.", "No lo entendí. Inténtalo otra vez o elige el significado."))
		return
	status_changed.emit(_tr("Understood", "Entendido"))
	last_source = "spoken"
	intent_received.emit(match_data.intent, match_data.language, current_generation)

func _on_status(state: int, message: String, checkpoint: int, attempt: int, session: int) -> void:
	if not _matches(checkpoint, attempt, session): return
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

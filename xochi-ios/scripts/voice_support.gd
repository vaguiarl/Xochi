extends Node
signal encouragement
signal status_changed(message: String)
enum State { STOPPED, REQUESTING, LISTENING, UNAVAILABLE, AWARDED }
var available := false
var listening := false
var requesting := false
var _native: Object
var _checkpoint := -1
var _attempt := -1
var _session := 0
var _locale := "en"
var _wanted := false
var _terminal := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Engine.has_singleton("XochiVoice"):
		_native = Engine.get_singleton("XochiVoice")
		available = _native.supported()
		_native.cheer.connect(_on_cheer)
		_native.status.connect(_on_status)

func set_locale(locale: String) -> void:
	_locale = locale

func start(locale: String, checkpoint: int, attempt: int) -> void:
	_locale = locale
	_session += 1
	_checkpoint = checkpoint
	_attempt = attempt
	listening = false
	requesting = false
	_wanted = false
	_terminal = true
	if not available or not is_instance_valid(_native):
		status_changed.emit("Voz local no disponible. Toca Ánimo." if locale == "es" else "On-device voice unavailable. Tap Courage.")
		return
	requesting = true
	_wanted = true
	_terminal = false
	_native.begin_listening(locale, checkpoint, attempt, _session)

func stop() -> void:
	_session += 1
	listening = false
	requesting = false
	_wanted = false
	_terminal = true
	_checkpoint = -1
	_attempt = -1
	if is_instance_valid(_native):
		_native.stop_listening()
	status_changed.emit("Micrófono apagado" if _locale == "es" else "Microphone off")

func _matches(checkpoint: int, attempt: int, session: int) -> bool:
	return checkpoint == _checkpoint and attempt == _attempt and session == _session

func _on_cheer(checkpoint: int, attempt: int, session: int) -> void:
	if not _wanted or not _matches(checkpoint, attempt, session):
		return
	_wanted = false
	_terminal = true
	listening = false
	requesting = false
	status_changed.emit("¡Segundo aliento listo!" if _locale == "es" else "Second Wind ready!")
	encouragement.emit()

func _on_status(state: int, message: String, checkpoint: int, attempt: int, session: int) -> void:
	if not _wanted or not _matches(checkpoint, attempt, session):
		return
	if _terminal:
		return
	match state:
		State.REQUESTING:
			requesting = true
			listening = false
		State.LISTENING:
			requesting = false
			listening = true
		State.STOPPED, State.UNAVAILABLE:
			requesting = false
			listening = false
			_wanted = false
			_terminal = true
		State.AWARDED:
			requesting = false
			listening = false
			_terminal = true
		_:
			return
	status_changed.emit(message)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		stop()

func _exit_tree() -> void:
	stop()

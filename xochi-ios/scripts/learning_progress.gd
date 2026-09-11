extends RefCounted
## The companion chapter owns a separate save; the original journey is preserved.
const PATH := "user://companion-learning-v1.json"
const INTENTS := ["come", "wait", "boat", "bridge", "jump"]
var save_path := PATH
var data := {"version":1, "locale":"en", "voice_language":"es", "music":true, "completed":false, "used_intents":[], "independent_choices":[], "spoken_practice":0, "typed_practice":0, "interpreted_spoken_practice":0, "interpreted_typed_practice":0}

func _init(path: String = PATH) -> void:
	save_path = path

func read_save() -> void:
	for path in [save_path, save_path + ".bak"]:
		if not FileAccess.file_exists(path): continue
		var value = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not value is Dictionary or value.get("version") != 1: continue
		for key in ["locale", "voice_language"]:
			if value.get(key) in ["en", "es"]: data[key] = value[key]
		for key in ["music", "completed"]:
			if value.get(key) is bool: data[key] = value[key]
		for key in ["used_intents", "independent_choices"]:
			data[key] = []
			if value.get(key) is Array:
				for intent in value[key]:
					if intent in INTENTS and intent not in data[key]: data[key].append(intent)
		for key in ["spoken_practice", "typed_practice", "interpreted_spoken_practice", "interpreted_typed_practice"]:
			var amount = value.get(key, 0)
			if (amount is float or amount is int) and amount >= 0 and amount <= 100000 and amount == floor(amount): data[key] = int(amount)
		return

func record(intent: String, source: String, language: String, assisted: bool) -> void:
	if intent not in INTENTS: return
	if intent not in data.used_intents: data.used_intents.append(intent)
	if source == "touch" and not assisted and intent not in data.independent_choices:
		data.independent_choices.append(intent)
	if source == "voice" and language == "es": data.spoken_practice += 1
	if source == "typed" and language == "es": data.typed_practice += 1
	# Model-inferred language is kept separate from exact phrase evidence.
	if source == "voice_ai" and language == "es": data.interpreted_spoken_practice += 1
	if source == "typed_ai" and language == "es": data.interpreted_typed_practice += 1

func write_save() -> bool:
	var directory = DirAccess.open(save_path.get_base_dir())
	if directory == null or directory.get_space_left() < 8192: return false
	var file = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	var absolute = ProjectSettings.globalize_path(save_path)
	if FileAccess.file_exists(save_path): DirAccess.copy_absolute(absolute, absolute + ".bak")
	return DirAccess.rename_absolute(absolute + ".tmp", absolute) == OK

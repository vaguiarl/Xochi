extends RefCounted
## Small, versioned save. Invalid or interrupted writes fall back to safe defaults.
const PATH = "user://song-home-v1.json"
var save_path := PATH
var data: Dictionary = {"version":1, "locale":"en", "checkpoint":0, "completed":false, "music":true, "deaths":0, "courage":false, "flowers":[]}

func _init(path: String = PATH) -> void:
	save_path = path

func read_save() -> void:
	for path in [save_path, save_path + ".bak"]:
		if not FileAccess.file_exists(path):
			continue
		var parser = JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) != OK:
			continue
		var value = parser.data
		if not value is Dictionary or value.get("version") != 1:
			continue
		if not value.get("checkpoint") is float and not value.get("checkpoint") is int:
			continue
		if value.checkpoint < 0 or value.checkpoint > 3 or value.checkpoint != floor(value.checkpoint):
			continue
		if value.get("locale") not in ["en", "es"]:
			continue
		data.locale = value.locale
		data.checkpoint = int(value.checkpoint)
		if value.get("flowers") is Array:
			for id in value.flowers:
				if (id is int or id is float) and id == floor(id) and id >= 0 and id < 8 and not data.flowers.has(int(id)):
					data.flowers.append(int(id))
		for key in ["completed", "music", "courage"]:
			if value.get(key) is bool: data[key] = value[key]
		if (value.get("deaths") is float or value.get("deaths") is int) and value.deaths >= 0 and value.deaths < 1000000:
			data.deaths = int(value.deaths)
		return

func write_save() -> bool:
	# Keep room for the temporary save and backup before starting an atomic write.
	var folder = DirAccess.open(save_path.get_base_dir())
	if folder == null or folder.get_space_left() < 8192:
		return false
	var temp = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if temp == null: return false
	temp.store_string(JSON.stringify(data))
	temp.flush()
	temp.close()
	var absolute = ProjectSettings.globalize_path(save_path)
	if FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(absolute, absolute + ".bak")
	return DirAccess.rename_absolute(absolute + ".tmp", absolute) == OK

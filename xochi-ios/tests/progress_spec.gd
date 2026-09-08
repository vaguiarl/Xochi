extends SceneTree
const TEST_PATH = "user://song-home-progress-spec.json"
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("[ProgressSpec] FAIL: ",message)

func put(text: String) -> void:
	var file = FileAccess.open(TEST_PATH,FileAccess.WRITE)
	file.store_string(text)
	file.close()

func run() -> void:
	var script = load("res://scripts/progress.gd")
	var original = script.new(TEST_PATH)
	original.data.checkpoint = 2
	original.data.courage = true
	original.data.locale = "es"
	expect(original.write_save(),"atomic write succeeds")
	var restored = script.new(TEST_PATH)
	restored.read_save()
	expect(restored.data.checkpoint==2 and restored.data.courage and restored.data.locale=="es","checkpoint, support and locale round trip")
	original.data.checkpoint = 3
	expect(original.write_save(),"second write preserves backup")
	put('{"version":1,"checkpoint":')
	var recovered = script.new(TEST_PATH)
	recovered.read_save()
	expect(recovered.data.checkpoint==2,"interrupted primary restores last complete backup")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH+".bak"))
	for text in ['[]','{"version":1,"checkpoint":99,"locale":"en"}','{"version":1,"checkpoint":"2","locale":"en"}','{"version":2,"checkpoint":1,"locale":"en"}','{"version":1,"checkpoint":1.7,"locale":"en"}']:
		put(text)
		var invalid = script.new(TEST_PATH)
		invalid.read_save()
		expect(invalid.data.checkpoint==0 and not invalid.data.courage,"invalid save falls back without script errors")
	for suffix in ["",".tmp",".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH+suffix))
	if failures==0: print("[ProgressSpec] PASS: round trip, interrupted write backup, invalid shape/type/version/range")
	quit(1 if failures else 0)

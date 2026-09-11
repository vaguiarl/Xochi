extends SceneTree
## Presentation fixtures, deliberately separate from the physical route test.
var game: Node
var save_path := "user://companion-capture-%s.json" % OS.get_process_id()
const OUTPUT := "res://tests/captures/companion"
func _initialize() -> void:
	call_deferred("run")
func shot(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT+"/"+filename+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	game = load("res://companion.tscn").instantiate()
	game.save.save_path = save_path
	root.add_child(game)
	game.locale = "en"
	game._show_menu()
	await shot("01-title")
	game.locale = "es"
	game._show_intro()
	await shot("02-intro-es")
	game.locale = "en"
	game._start_journey()
	await create_timer(.3).timeout
	if paused: game._resume()
	await shot("03-lesson")
	game.step = 3
	game.player.reset_at(game.world.to_global(Vector2(450,555)))
	game._enter_step()
	await create_timer(.2).timeout
	if paused: game._resume()
	await shot("04-boat-choice")
	game.step = 5
	game.player.reset_at(game.world.to_global(Vector2(640,505)))
	game._enter_step()
	await create_timer(1.2).timeout
	if paused: game._resume()
	await shot("05-crow-opening")
	game._pause()
	await shot("06-pause")
	game._resume()
	game.locale = "es"
	game._pause()
	await shot("08-pause-es")
	game._resume()
	game._type_guidance()
	await shot("09-type-es")
	game._resume()
	game.locale = "en"
	game._finish()
	await shot("07-ending")

	game.queue_free()
	await process_frame
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))
	print("[CompanionCapture] PASS: nine screens rendered")
	quit()

extends SceneTree
## Presentation fixtures, deliberately separate from the physical route test.
var game: Node
var saved: Dictionary
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
	root.add_child(game)
	saved = game.save.data.duplicate(true)
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
	game._finish()
	await shot("07-ending")
	game.save.data = saved
	game.save.write_save()
	game.queue_free()
	await process_frame
	await process_frame
	print("[CompanionCapture] PASS: seven screens rendered")
	quit()

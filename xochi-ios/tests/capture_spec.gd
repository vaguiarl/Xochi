extends SceneTree
## Rendered visual fixtures, separate from the physical full-route proof.
## Run with a display: godot --path . --script res://tests/capture_spec.gd
var game: Node
var saved: Dictionary
var output := "res://tests/captures"

func _initialize() -> void:
	call_deferred("run")

func shot(name_: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+name_+".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	saved = game.save.data.duplicate(true)
	game.locale = "en"
	game._show_menu()
	await shot("01-title")
	game.locale = "es"
	game._show_intro()
	await shot("02-story-es")
	game.locale = "en"
	game._start(false)
	await create_timer(.95).timeout
	# A desktop launch can lose focus during boot. Restore this fixture explicitly.
	if game.current_screen == "pause": game._resume()
	assert(game.current_screen == "game")
	await shot("03-garden")
	game._pause()
	assert(game.current_screen == "pause")
	await shot("04-pause")
	game._resume()
	game._reach_checkpoint(3)
	game.player.reset_at(Vector2(4600,555),false)
	game.camera.position = Vector2(4780,360)
	game._toast("",0)
	await create_timer(.15).timeout
	if game.current_screen == "pause": game._resume()
	assert(game.current_screen == "game")
	await shot("05-reflection")
	game._on_win()
	await create_timer(3.2).timeout
	assert(game.current_screen == "ending")
	await shot("06-ending")
	game.save.data = saved
	game.save.write_save()
	game.music.stop()
	game.music_spare.stop()
	await create_timer(.05).timeout
	print("[CaptureSpec] PASS: title, ES story, garden, pause, reflection, ending rendered")
	quit()

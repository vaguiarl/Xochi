extends SceneTree
var game: Node2D
func _init() -> void: run.call_deferred()
func run() -> void:
	game = load("res://scripts/rescue_main.gd").new()
	game.save.save_path = "user://rescue-capture-%s.json" % OS.get_process_id()
	root.add_child(game)
	game._start_journey()
	await create_timer(.3).timeout
	if paused: game._resume()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/captures/rescue-opening.png")
	game.player.reset_at(Vector2(990,555))
	await create_timer(1.5).timeout
	if paused: game._resume()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/captures/rescue-garden.png")
	game.queue_free()
	await process_frame
	quit()

extends SceneTree
## Integration setup probes for pause/retry/ending races; not gameplay completion proof.
var game: Node
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("[LifecycleSpec] FAIL: ",message)

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	var saved = game.save.data.duplicate(true)
	game._start(false)
	await process_frame
	game._pause()
	var escape = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	Input.flush_buffered_events()
	await process_frame
	expect(not paused and game.current_screen=="game","Escape resumes a paused world")
	if paused: game._resume()
	game._on_death()
	await create_timer(.6).timeout
	expect(not game.retrying and game.player.active,"deliberate retry works during spawn protection")
	game._reach_checkpoint(3)
	game.player.reset_at(Vector2(4570,555),false)
	await create_timer(.04).timeout
	game.player.position.x = 4310
	await create_timer(.04).timeout
	expect(game.boss.active,"backtracking cannot freeze a committed boss attack")
	game._on_win()
	game._start(false)
	await create_timer(3.2).timeout
	expect(game.current_screen=="game" and not game.finished,"stale ending cannot interrupt a new journey")
	expect(not game.scenery.completed,"celebration state clears on replay")
	game.save.data.checkpoint = 2
	game.save.data.flowers = [1,3]
	game._start(true)
	expect(game.collected.size()==2 and game.collected.has(1) and game.collected.has(3),"resume preserves earned flowers without granting missed ones")
	game._show_menu()
	expect(game.scenery.scroll==0 and not game.boss.active,"title returns to the opening garden")
	game.save.data = saved
	game.save.write_save()
	game.music.stop()
	game.music_spare.stop()
	await create_timer(.06).timeout
	if failures==0: print("[LifecycleSpec] PASS: paused input, protected retry, boss latch, stale ending, replay, exact flowers, title")
	quit(1 if failures else 0)

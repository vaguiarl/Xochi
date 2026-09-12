extends "res://tests/rescue_route_spec.gd"
func screen_touch(index: int, point: Vector2, pressed: bool, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	event.canceled = canceled
	root.push_input(event)
func drag(index: int, point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = point
	root.push_input(event)
func move_to(x: float, jump := false, double_jump := false) -> void:
	var direction: float = signf(x-game.player.position.x)
	var start := Vector2(250,570)
	screen_touch(0,start,true)
	drag(0,start+Vector2(60*direction,0))
	if jump:
		screen_touch(1,Vector2(800,570),true)
		drag(1,Vector2(800,510))
		screen_touch(1,Vector2(800,510),false)
	for frame in 300:
		await ticks(1)
		if double_jump and frame==28:
			screen_touch(1,Vector2(800,570),true)
			drag(1,Vector2(800,510))
			screen_touch(1,Vector2(800,510),false)
		if (x-game.player.position.x)*direction<20: break
	screen_touch(0,start,false,true)
	for i in 120:
		await ticks(1)
		if game.player.is_on_floor(): break
	print("MANUAL ",game.player.position," friends=",game.rescued_ids," retry=",game.retry_count)
func dwell(id: String, end := false) -> void:
	var boat = game.boats[id]
	for i in 500:
		var phase := fposmod(boat.clock,8.0)
		if (phase>=4 and phase<4.1) if end else (phase<.1): return
		await ticks(1)
func run() -> void:
	root.size = Vector2i(1420,720)
	game = load("res://scripts/rescue_main.gd").new()
	game.save.save_path = "user://rescue-manual-%s.json" % OS.get_process_id()
	root.add_child(game)
	await ticks(5)
	await tap("Begin")
	await tap("StartJourney")
	await ticks(8)
	await move_to(270)
	if "baby_one" not in game.rescued_ids: failures.append("Manual arrival did not rescue baby without Ven")
	if not game.session_uses.is_empty(): failures.append("Manual rescue fabricated learning evidence")
	# Full direct-touch route: no controller commands or position assignment.
	await move_to(450)
	await dwell("lupita")
	await move_to(600,true)
	await dwell("lupita",true)
	await move_to(990,true)
	await tap("Action_distract")
	await move_to(1320)
	await tap("Action_distract")
	await move_to(1660)
	await move_to(1710)
	await move_to(1935,true,true)
	await dwell("frida")
	await move_to(2180,true,true)
	await dwell("frida",true)
	await move_to(2480,true)
	await tap("Action_distract")
	await move_to(2850)
	await tap("Action_distract")
	await move_to(2970)
	await move_to(3170,true)
	await ticks(240)
	if not game.finished or game.rescued_ids.size()!=3: failures.append("Manual route failed to finish")
	if game.player.hyper_charges!=2: failures.append("Manual normal jumps spent hyper stock")
	print("MANUAL ROUTE failures=",failures)
	for suffix in ["", ".bak", ".rescue"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save.save_path+suffix))
	game.queue_free()
	await ticks(3)
	quit(0 if failures.is_empty() else 1)

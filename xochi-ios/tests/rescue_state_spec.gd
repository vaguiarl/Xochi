extends "res://tests/rescue_manual_spec.gd"
func run() -> void:
	root.size = Vector2i(1420,720)
	game = load("res://scripts/rescue_main.gd").new()
	game.save.save_path = "user://rescue-state-%s.json" % OS.get_process_id()
	root.add_child(game)
	await ticks(6)
	await tap("Begin")
	await tap("StartJourney")
	await ticks(8)
	await move_to(270)
	var stream_id: int = game.music.stream.get_instance_id()
	# A physical fall, not a direct retry call, preserves the already-earned baby.
	await move_to(-40)
	await ticks(150)
	if game.retry_count<1 or game.rescued_ids!=["baby_one"]: failures.append("Fall did not preserve rescue")
	if not game.music.playing or game.music.stream.get_instance_id()!=stream_id: failures.append("Retry replaced or stopped song")
	# A destination tap must be consumed and may not spend hyper stock.
	var charges: int = game.player.hyper_charges
	await tap("Destination_lupita")
	if game.player.hyper_charges!=charges: failures.append("Destination leaked a world tap")
	# Real manual touch cancels guidance immediately, even during a boarding wait.
	await tap("Action_come")
	screen_touch(0,Vector2(200,570),true)
	drag(0,Vector2(150,570))
	await ticks(2)
	if game.controller.guiding or not game.plan.is_empty(): failures.append("Manual takeover failed")
	screen_touch(0,Vector2(150,570),false,true)
	await ticks(20)
	# Lifecycle pause interrupts input and does not freeze or restart the song.
	await tap("Pause")
	if not paused or not game.music.playing: failures.append("Pause lifecycle")
	game._resume()
	# State fixtures below isolate perception; route tests separately prove travel.
	game.player.reset_at(Vector2(1250,555))
	await ticks(2)
	game.guard.configure(Vector2(1470,555))
	game.guard.active = true
	await ticks(20)
	if game.guard.state!="notice": failures.append("Crow did not warn before chase")
	await ticks(38)
	if game.guard.state!="chase": failures.append("Crow did not pursue after warning")
	game.player.reset_at(Vector2(1320,555))
	await ticks(100)
	if game.guard.state!="search": failures.append("Reeds did not break pursuit")
	game.guard.distract("bell")
	await ticks(8)
	if game.guard.state!="investigate": failures.append("Bell not investigated")
	game.guard.distract("bell")
	game.guard.distract("bell")
	if game.guard.opening_duration!=3: failures.append("Repeated trick duration must bottom at 3s")
	var boat_time: float = game.boats.lupita.clock
	game.voice.listening = true
	await ticks(15)
	var paused_clock: float = game.boats.lupita.clock
	await ticks(15)
	if absf(game.boats.lupita.clock-paused_clock)>.01: failures.append("Speech planning spent boat timing")
	game.voice.listening = false
	await ticks(10)
	if game.boats.lupita.clock<=boat_time: failures.append("Boat did not resume")
	# Contact while pursuing triggers the actual quick regroup signal.
	game.guard.configure(Vector2(1470,555))
	game.player.reset_at(Vector2(1400,555))
	var retries_before: int = game.retry_count
	await ticks(110)
	if game.retry_count<=retries_before: failures.append("Crow contact did not catch player")
	if "baby_one" not in game.rescued_ids: failures.append("Catch lost earned rescue")
	var retained: Array = game.rescued_ids.duplicate()
	game._save_rescue()
	game._start_journey()
	await ticks(8)
	if game.rescued_ids!=retained: failures.append("Reload did not restore rescue checkpoint")
	print("RESCUE STATES failures=",failures)
	for suffix in ["", ".bak", ".rescue"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save.save_path+suffix))
	game.queue_free()
	await ticks(3)
	quit(0 if failures.is_empty() else 1)

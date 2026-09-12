extends SceneTree
var game: Node2D
var failures: Array[String] = []
var frames := 0
func _init() -> void: run.call_deferred()
func ticks(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame
		frames += 1
func find_button(node: Node, id: String) -> Button:
	if node is Button and node.name==id and node.is_visible_in_tree(): return node
	for child in node.get_children():
		var found := find_button(child,id)
		if found: return found
	return null
func tap(id: String) -> void:
	await ticks(3)
	var button := find_button(game.ui,id)
	if button==null:
		failures.append("Missing visible button "+id)
		return
	var position_: Vector2 = button.get_global_rect().get_center()
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = position_
	down.pressed = true
	root.push_input(down)
	await ticks(2)
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = position_
	up.pressed = false
	root.push_input(up)
	await ticks(3)
func settle(n := 900) -> void:
	for i in n:
		await ticks(1)
		if game.plan.is_empty() and not game.controller.guiding and game.player.is_on_floor(): break
	print("SETTLE pos=",game.player.position," rescued=",game.rescued_ids," selected=",game.selected," plan=",game.plan," status=",game.status_text)
func go(id: String) -> void:
	if game.selected!=id: await tap("Destination_"+id)
	await tap("Action_come")
	await settle()
func run() -> void:
	root.size = Vector2i(1420,720)
	game = load("res://scripts/rescue_main.gd").new()
	game.save.save_path = "user://rescue-route-%s.json" % OS.get_process_id()
	root.add_child(game)
	await ticks(5)
	await tap("Begin")
	await tap("StartJourney")
	await ticks(8)
	await tap("Action_come")
	await settle()
	if "baby_one" not in game.rescued_ids: failures.append("Real touch Ven failed to rescue first baby")
	await tap("Action_come")
	await settle()
	await tap("Action_come")
	await settle()
	await tap("Action_distract")
	await go("rabbit")
	if "rabbit" not in game.rescued_ids: failures.append("Rabbit rescue failed")
	await tap("Action_distract")
	await go("frida")
	if "baby_two" not in game.rescued_ids: failures.append("Frida baby rescue failed")
	await tap("Action_come")
	await settle()
	await tap("Action_distract")
	await go("bridge")
	await tap("Action_distract")
	await go("esperanza")
	await ticks(220)
	if not game.finished: failures.append("Did not depart and reach ending")
	if game.player.hyper_charges!=2: failures.append("UI tap leaked into hyper-jump")
	if game.session_spoken!=0: failures.append("Touch invented speech evidence")
	if not game.music.playing: failures.append("Song stopped")
	print("RESCUE ROUTE frames=",frames," retries=",game.retry_count," failures=",failures)
	for suffix in ["", ".bak", ".tmp", ".rescue", ".rescue.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save.save_path+suffix))
	game.queue_free()
	await ticks(3)
	quit(0 if failures.is_empty() else 1)

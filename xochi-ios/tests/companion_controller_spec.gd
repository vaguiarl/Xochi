extends SceneTree
## godot --headless --fixed-fps 60 --path xochi-ios --script res://tests/companion_controller_spec.gd
## Real collision geometry, translated world, and dispatched touch/key events.

var world: Node2D
var player: CharacterBody2D
var controller: Node
var failures: Array[String] = []
var arrivals := 0
var takeovers := 0
var normal_jumps := 0
var failure_reasons: Array[String] = []
var removable_deck: StaticBody2D


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	world = Node2D.new()
	world.position.x = 76.0
	root.add_child(world)
	_ground(0, 350, 555)
	removable_deck = _ground(350, 500, 555)
	_ground(560, 730, 505)
	_ground(790, 1280, 555)
	player = load("res://scripts/player.gd").new()
	world.add_child(player)
	controller = load("res://scripts/companion_controller.gd").new()
	world.add_child(controller)
	controller.configure(player)
	controller.arrived.connect(func(): arrivals += 1)
	controller.manual_takeover.connect(func(): takeovers += 1)
	controller.failed.connect(func(reason: String): failure_reasons.append(reason))
	player.jumped.connect(func(hyper: bool):
		if not hyper: normal_jumps += 1
	)
	await _test_authored_route()
	await _test_refusal_and_stopping()
	await _test_touch_takeover()
	await _test_keyboard_and_pending_jump()
	await _test_lifetime()
	await _test_dynamic_edge()
	if failures.is_empty():
		print("[CompanionControllerSpec] PASS: translated authored route, actual boat/bank landings, bounded normal double jump, no hyper spending, unsafe-path rejection, hard wait, real touch/key takeover, queued-jump cancellation, pause/retry cleanup and disappearing-edge stop")
		quit(0)
	else:
		for failure in failures:
			push_error("[CompanionControllerSpec] " + failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _ticks(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func _ground(left: float, right: float, top: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = Vector2((left + right) * 0.5, top + 20.0)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(right - left, 40)
	shape.shape = rectangle
	body.add_child(shape)
	world.add_child(body)
	return body


func _reset(at: Vector2) -> void:
	controller.cancel_guidance()
	player.reset_at(world.to_global(at - Vector2(0, 1)))
	await _ticks(8)
	_expect(player.is_on_floor(), "case setup must contact a real floor")


func _segment(at: Vector2, jump := false) -> bool:
	var before := arrivals
	var accepted: bool = controller.guide_to(world.to_global(at), jump)
	_expect(accepted, "authored segment must be accepted: " + str(at))
	for tick in range(260):
		await _ticks(1)
		if not controller.guiding:
			break
	var reached := arrivals == before + 1
	_expect(reached, "segment must arrive exactly once at " + str(at) + "; actual " + str(player.position) + "; failures " + str(failure_reasons))
	_expect(player.is_on_floor(), "arrival must require real landing contact")
	_expect(player.position.distance_to(at) < 7.0, "arrival must settle at the authored feet position")
	_expect(absf(player.velocity.x) < 0.01, "arrival must stop without drifting past the landing")
	return reached


func _test_authored_route() -> void:
	await _reset(Vector2(130, 555))
	for destination in [Vector2(260, 555), Vector2(450, 555)]:
		if not await _segment(destination): return
	var jumps_before := normal_jumps
	if not await _segment(Vector2(640, 505), true): return
	_expect(normal_jumps - jumps_before in [1, 2], "boat crossing must use at most the ordinary ground/air pair")
	jumps_before = normal_jumps
	if not await _segment(Vector2(890, 555), true): return
	_expect(normal_jumps - jumps_before in [1, 2], "bank crossing must use at most the ordinary ground/air pair")
	await _segment(Vector2(1080, 555))
	_expect(player.hyper_charges == 2 and not player.reserve_available, "companion route must never consume or grant hyper/reserve charges")
	# A longer valid segment needs the actual airborne second lift.
	await _reset(Vector2(450, 555))
	jumps_before = normal_jumps
	await _segment(Vector2(810, 555), true)
	_expect(normal_jumps == jumps_before + 2, "long crossing must use the real single normal air jump")
	_expect(player.hyper_charges == 2, "bounded double jump must preserve hyper charges")


func _test_refusal_and_stopping() -> void:
	await _reset(Vector2(450, 555))
	_expect(not controller.guide_to(world.to_global(Vector2(640, 505))), "a walking command must never step across the canal")
	_expect(not controller.guide_to(world.to_global(Vector2(540, 555)), true), "a jump command must reject an unsupported landing")
	_expect(not controller.guide_to(world.to_global(Vector2(1090, 555)), true), "a command beyond the segment bound must be rejected")
	await _ticks(30)
	_expect(absf(player.position.x - 450.0) < 1.0 and not controller.guiding, "refused commands must leave no queued motion")
	await _reset(Vector2(130, 555))
	_expect(controller.guide_to(world.to_global(Vector2(260, 555))), "wait setup should accept a safe walk")
	await _ticks(12)
	controller.wait_here()
	var stop_x := player.position.x
	await _ticks(40)
	_expect(absf(player.position.x - stop_x) < 0.1 and not controller.guiding, "wait must hard-stop the segment and never resume it")


func _touch(index: int, pressed: bool, at: Vector2, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = at
	event.canceled = canceled
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _test_touch_takeover() -> void:
	await _reset(Vector2(200, 555))
	controller.guide_to(world.to_global(Vector2(450, 555)))
	await _ticks(10)
	var before := takeovers
	_touch(0, true, Vector2(300, 400))
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(220, 400)
	drag.relative = Vector2(-80, 0)
	Input.parse_input_event(drag)
	Input.flush_buffered_events()
	await _ticks(3)
	_expect(takeovers == before + 1 and not controller.guiding, "a real world touch must cancel guidance immediately")
	_expect(player.velocity.x < -100.0 and player._touch_index == 0, "takeover must preserve the new swipe and move in its direction")
	_expect(not controller.guide_to(world.to_global(Vector2(450, 555))), "delayed guidance must not steal an already-held touch")
	_touch(0, false, Vector2(220, 400), true)
	await _ticks(45)
	var stopped_x := player.position.x
	await _ticks(30)
	_expect(not controller.guiding and absf(player.position.x - stopped_x) < 0.1, "release must not reactivate the old companion command")


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _test_keyboard_and_pending_jump() -> void:
	await _reset(Vector2(450, 555))
	var before := normal_jumps
	controller.guide_to(world.to_global(Vector2(640, 505)), true)
	# Cancel before the first physics tick: no delayed guided jump may survive.
	_key(KEY_LEFT, true)
	await _ticks(2)
	_expect(not controller.guiding and normal_jumps == before, "manual key takeover must clear the not-yet-launched guided jump")
	_expect(player.velocity.x < 0.0, "real held keyboard motion must take priority")
	_key(KEY_LEFT, false)
	await _ticks(25)
	await _reset(Vector2(450, 555))
	controller.guide_to(world.to_global(Vector2(640, 505)), true)
	_key(KEY_SPACE, true)
	_key(KEY_SPACE, false)
	await _ticks(5)
	_expect(normal_jumps == before + 1 and not controller.guiding, "manual Space must replace the pending guided jump with one normal jump")
	_key(KEY_SPACE, true)
	_key(KEY_SPACE, false)
	await _ticks(1)
	_expect(normal_jumps == before + 2 and player.hyper_charges == 2, "manual takeover must retain normal double jump and independent hyper stock")


func _test_lifetime() -> void:
	await _reset(Vector2(130, 555))
	controller.guide_to(world.to_global(Vector2(450, 555)))
	await _ticks(8)
	paused = true
	await process_frame
	_expect(not controller.guiding and player.guided_direction == 0.0, "pause must cancel guidance")
	paused = false
	await _ticks(8)
	_expect(not controller.guiding and player.velocity.x == 0.0, "resume must not restart companion movement")
	controller.guide_to(world.to_global(Vector2(450, 555)))
	await _ticks(8)
	player.reset_at(world.to_global(Vector2(130, 554)))
	await _ticks(20)
	_expect(not controller.guiding and absf(player.position.x - 130.0) < 0.1, "retry/reset must invalidate the old target")
	controller.guide_to(world.to_global(Vector2(260, 555)))
	player.clear_input()
	await _ticks(20)
	_expect(not controller.guiding and player.guided_direction == 0.0, "explicit input clearing must invalidate guidance")


func _test_dynamic_edge() -> void:
	await _reset(Vector2(290, 555))
	_expect(controller.guide_to(world.to_global(Vector2(450, 555))), "dynamic-edge setup should initially be supported")
	removable_deck.queue_free()
	await _ticks(80)
	_expect(not controller.guiding and player.is_on_floor() and player.position.x < 335.0, "a disappearing deck must stop guidance before Xochi walks off the new edge")
	_expect("edge" in failure_reasons, "scene must receive a recoverable edge failure")

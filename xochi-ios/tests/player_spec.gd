extends SceneTree
## Run: godot --headless --path xochi-ios --script res://tests/player_spec.gd
## Uses real CharacterBody2D contacts for coyote time, buffering and finite drift.

var player: CharacterBody2D
var failures: Array[String] = []
var ripple_count := 0
var death_count := 0
var jump_count := 0
var normal_jump_count := 0


func _init() -> void:
	if "--route" in OS.get_cmdline_user_args():
		_run_route.call_deferred()
	else:
		_run.call_deferred()


func _run() -> void:
	var script = load("res://scripts/player.gd")
	if script == null or not script.can_instantiate():
		push_error("Player script could not be loaded")
		quit(1)
		return
	var world := Node2D.new()
	root.add_child(world)
	var ground := StaticBody2D.new()
	ground.position = Vector2(200, 320)
	var collider := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(200, 40)
	collider.shape = rectangle
	ground.add_child(collider)
	world.add_child(ground)
	player = CharacterBody2D.new()
	player.set_script(script)
	world.add_child(player)
	player.ripple.connect(func(_origin: Vector2, _direction: float): ripple_count += 1)
	player.died.connect(func(): death_count += 1)
	player.jumped.connect(func(hyper: bool):
		jump_count += 1
		if not hyper: normal_jump_count += 1
	)
	player.set_physics_process(false)
	_test_charge_order()
	_test_gesture_lifetime()
	_test_double_swipe()
	_test_multitouch()
	_test_single_death()
	await _test_gui_consumed_release()
	await _test_pause_cancels_gesture()
	player.set_physics_process(true)
	await _test_double_jump_cycle()
	await _test_touch_double_jump()
	await _test_hyper_interleave()
	await _test_coyote()
	await _test_buffer()
	await _test_finite_inertia()
	if failures.is_empty():
		print("[PlayerSpec] PASS: normal double jump, landing/retry reset, hyper interleave limits, reserve order, stale hold, swipe sprint, multitouch actions, GUI-consumed releases, pause cleanup, real coyote window, landing buffer and finite inertia")
		quit(0)
	else:
		for failure in failures:
			push_error("[PlayerSpec] " + failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _ticks(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame


func _grounded_reset() -> void:
	player.reset_at(Vector2(200, 299), false)
	await _ticks(8)
	_expect(player.is_on_floor(), "test setup must make real floor contact")


func _land(maximum_ticks := 180) -> bool:
	for tick in range(maximum_ticks):
		await _ticks(1)
		if player.is_on_floor() and player.velocity.y >= 0.0:
			return true
	return false


func _space() -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.keycode = KEY_SPACE
	key.pressed = true
	player._unhandled_input(key)


func _up_swipe(index: int, start: Vector2) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = index
	touch.position = start
	touch.pressed = true
	player._unhandled_input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = index
	drag.position = start + Vector2(0, -70)
	player._unhandled_input(drag)
	touch.pressed = false
	touch.position = drag.position
	player._unhandled_input(touch)


func _test_double_jump_cycle() -> void:
	await _grounded_reset()
	var before := normal_jump_count
	_space()
	await _ticks(6)
	_expect(normal_jump_count == before + 1 and not player.is_on_floor(), "Space must make a normal takeoff")
	_space()
	await _ticks(1)
	_expect(normal_jump_count == before + 2 and player.velocity.y < -400.0, "a second Space press must make one responsive airborne jump")
	_expect(player.hyper_charges == 2, "normal double jumping must not spend hyper charges")
	_space()
	await _ticks(10)
	_expect(normal_jump_count == before + 2, "a third normal press must not add another airborne jump")
	var landed := await _land()
	_expect(landed, "double jump must return to a real collision surface")
	_space()
	await _ticks(5)
	_space()
	await _ticks(1)
	_expect(normal_jump_count == before + 4, "an actual landing must restore the next ground-plus-air pair")
	player.reset_at(Vector2(200, 299), true)
	await _ticks(8)
	before = normal_jump_count
	_space()
	await _ticks(5)
	_space()
	await _ticks(1)
	_expect(normal_jump_count == before + 2 and player.hyper_charges == 2 and player.reserve_available, "retry must restore double jump and preserve the independent checkpoint hyper stock")


func _test_touch_double_jump() -> void:
	await _grounded_reset()
	var before := normal_jump_count
	_up_swipe(0, Vector2(200, 500))
	await _ticks(5)
	_up_swipe(0, Vector2(200, 500))
	await _ticks(1)
	_expect(normal_jump_count == before + 2 and player.hyper_charges == 2, "two separate upward swipes must ground-jump then air-jump without triggering a hyper tap")
	_up_swipe(0, Vector2(200, 500))
	await _ticks(10)
	_expect(normal_jump_count == before + 2, "a third upward swipe must respect the air-jump limit")
	await _grounded_reset()
	_space()
	await _ticks(4)
	player._begin_touch(0, Vector2(200, 500))
	player._drag_touch(Vector2(270, 500))
	before = normal_jump_count
	_up_swipe(1, Vector2(900, 500))
	await _ticks(1)
	_expect(normal_jump_count == before + 1 and player._touch_index == 0 and player._touch_direction == 1.0, "a secondary-finger upward swipe must air-jump while directional touch remains held")
	_expect(player.hyper_charges == 2, "multitouch normal air-jump must leave hyper charges intact")
	player.clear_input()


func _test_hyper_interleave() -> void:
	await _grounded_reset()
	player.reserve_available = true
	_space()
	await _ticks(5)
	player.jump_hyper()
	await _ticks(5)
	var before := normal_jump_count
	_space()
	await _ticks(1)
	_expect(normal_jump_count == before + 1, "hyper must preserve the still-unused normal airborne jump")
	before = normal_jump_count
	player.jump_hyper()
	await _ticks(1)
	_space()
	await _ticks(10)
	_expect(normal_jump_count == before, "another hyper must not refill an already-used air jump")
	player.jump_hyper()
	await _ticks(1)
	player.clear_input()
	paused = true
	await process_frame
	paused = false
	_space()
	await _ticks(10)
	_expect(normal_jump_count == before and player.hyper_charges == 0 and not player.reserve_available, "reserve hyper, input clearing and pause must not grant another normal air jump")
	await _grounded_reset()
	before = normal_jump_count
	player.jump_hyper()
	await _ticks(5)
	_space()
	await _ticks(1)
	_space()
	await _ticks(10)
	_expect(normal_jump_count == before + 1, "a hyper takeoff must allow one ordinary airborne jump, never two")


func _test_charge_order() -> void:
	player.reset_at(Vector2(200, 299), true)
	player.jump_hyper()
	_expect(player.hyper_charges == 1 and player.reserve_available, "first hyper must spend a regular charge")
	player.jump_hyper()
	_expect(player.hyper_charges == 0 and player.reserve_available, "second hyper must leave reserve untouched")
	player.jump_hyper()
	_expect(player.hyper_charges == 0 and not player.reserve_available, "third hyper must spend the single reserve")
	player.velocity.y = 7.0
	player.jump_hyper()
	_expect(player.velocity.y == 7.0, "exhausted hyper must not change velocity")
	player.reset_at(Vector2(200, 299), true)
	_expect(player.hyper_charges == 2 and player.reserve_available, "retry must restore the checkpoint charge state")


func _test_gesture_lifetime() -> void:
	player.reset_at(Vector2(200, 299))
	var before := ripple_count
	player._begin_touch(1, Vector2.ZERO)
	player._advance_touch(0.30)
	player._end_touch()
	player._begin_touch(2, Vector2.ZERO)
	player._advance_touch(0.10)
	_expect(ripple_count == before, "an old hold must not fire 100 ms into a new touch")
	player._advance_touch(0.29)
	_expect(ripple_count == before, "hold must wait the complete 400 ms")
	player._advance_touch(0.01)
	_expect(ripple_count == before + 1, "hold must trigger exactly at 400 ms")
	player.clear_input()
	player._attack_cooldown = 0.0
	player._advance_touch(1.0)
	_expect(ripple_count == before + 1, "clear_input must cancel all pending holds")
	player._begin_touch(3, Vector2.ZERO)
	var generation: int = player._touch_generation
	player._end_touch()
	player._begin_touch(3, Vector2.ZERO)
	player._release_if_still_owned(3, generation)
	_expect(player._touch_index == 3, "a deferred release must not clear a reused touch ID")
	player.clear_input()


func _test_double_swipe() -> void:
	player.reset_at(Vector2(200, 299))
	player._begin_touch(1, Vector2.ZERO)
	player._drag_touch(Vector2(70, 0))
	_expect(player.velocity.x == 220.0 and not player._touch_running, "single horizontal swipe must walk")
	player._end_touch()
	player._clock += 0.1
	player._begin_touch(2, Vector2.ZERO)
	player._drag_touch(Vector2(70, 0))
	_expect(player.velocity.x == 340.0 and player._touch_running, "a timely second swipe must sprint")
	player.clear_input()
	player._begin_touch(3, Vector2.ZERO)
	player._drag_touch(Vector2(70, 0))
	_expect(not player._touch_running, "reset must forget old double-swipe history")
	player.clear_input()
	_expect(player._touch_index == -1 and player._touch_direction == 0.0 and player._jump_buffer == 0.0, "clear_input must remove all pending movement")


func _test_single_death() -> void:
	player.reset_at(Vector2(200, 299))
	var before := death_count
	player.take_hit()
	_expect(death_count == before, "spawn protection must ignore damage")
	player.invulnerable = 0.0
	player.take_hit()
	player.take_hit()
	_expect(death_count == before + 1 and not player.active, "one life must emit exactly one death")
	player.reset_at(Vector2(200, 299), true)
	_expect(player.active and player.reserve_available and player.invulnerable > 0.0, "retry must restore a playable protected state")


func _test_multitouch() -> void:
	player.reset_at(Vector2(200, 299))
	player._begin_touch(0, Vector2.ZERO)
	player._drag_touch(Vector2(70, 0))
	var finger := InputEventScreenTouch.new()
	finger.index = 1
	finger.position = Vector2(400, 300)
	finger.pressed = true
	player._unhandled_input(finger)
	player._advance_touch(0.08)
	finger.pressed = false
	player._unhandled_input(finger)
	_expect(player.hyper_charges == 1 and player._touch_direction == 1.0 and player._touch_index == 0, "second-finger tap must hyper jump without releasing directional touch")
	finger.pressed = true
	player._unhandled_input(finger)
	var before := ripple_count
	player._advance_touch(0.4)
	_expect(ripple_count == before + 1 and player._touch_direction == 1.0, "second-finger hold must ripple while directional touch stays active")
	player.clear_input()
	_expect(player._secondary_index == -1 and player._touch_index == -1, "pause or retry must cancel both fingers")
	player.velocity.x = 320.0
	player._begin_touch(0, Vector2.ZERO)
	player._drag_touch(Vector2(0, -70))
	_expect(player._touch_direction == 1.0 and player._touch_running, "a vertical upward swipe must preserve existing forward sprint")
	player.clear_input()


func _test_pause_cancels_gesture() -> void:
	player._begin_touch(1, Vector2.ZERO)
	player._advance_touch(0.3)
	paused = true
	await process_frame
	_expect(player._touch_index == -1, "tree pause must cancel an owned touch")
	paused = false
	var before := ripple_count
	player._advance_touch(0.2)
	_expect(ripple_count == before, "resuming must not release a stale hold attack")


func _test_gui_consumed_release() -> void:
	player.reset_at(Vector2(200, 299))
	player._begin_touch(0, Vector2.ZERO)
	player._drag_touch(Vector2(70, 0))
	player._begin_secondary(1, Vector2(500, 300))
	var release := InputEventScreenTouch.new()
	release.index = 1
	release.position = Vector2(500, 300)
	release.pressed = false
	# The release passes _input, then the GUI consumes it. There is deliberately
	# no _unhandled_input call, matching a world touch lifted over a HUD control.
	player._input(release)
	await process_frame
	_expect(player._secondary_index == -1 and player.hyper_charges == 2, "GUI-consumed secondary release must clean up without a hyper jump")
	_expect(player._touch_direction == 1.0, "secondary cleanup must preserve the directional finger")
	release.index = 0
	player._input(release)
	await process_frame
	_expect(player._touch_index == -1 and player._touch_direction == 0.0, "GUI-consumed primary release must stop held movement")
	player._begin_touch(0, Vector2.ZERO)
	release.canceled = true
	player._input(release)
	player._unhandled_input(release)
	_expect(player._touch_index == -1 and player.hyper_charges == 2, "an OS-cancelled touch must never become a tap")


func _test_coyote() -> void:
	await _grounded_reset()
	player.position.x = 340
	await _ticks(8)
	_expect(not player.is_on_floor() and player._coyote > 0.0, "walking off must retain grace after 8 frames")
	player.jump_normal()
	await _ticks(1)
	_expect(player.velocity.y < -450.0, "a jump inside the coyote window must use the full ground-jump lift")
	var before := normal_jump_count
	player.jump_normal()
	await _ticks(1)
	_expect(normal_jump_count == before + 1, "a coyote jump must preserve the ordinary second jump")
	await _grounded_reset()
	player.position.x = 340
	await _ticks(16)
	before = normal_jump_count
	player.jump_normal()
	await _ticks(1)
	_expect(player._coyote == 0.0 and normal_jump_count == before + 1 and player.velocity.y > -450.0, "after coyote expires, walking off must consume the single airborne jump")
	player.jump_normal()
	await _ticks(10)
	_expect(normal_jump_count == before + 1, "expired coyote grace must not add a second airborne jump")


func _test_buffer() -> void:
	await _grounded_reset()
	player.jump_normal()
	await _ticks(5)
	player.jump_normal()
	await _ticks(1)
	for tick in range(180):
		if player.velocity.y > 0.0 and player.position.y >= 276.0:
			break
		await _ticks(1)
	_expect(not player.is_on_floor(), "buffer setup must still be airborne with the ordinary air jump spent")
	player.jump_normal()
	var before := normal_jump_count
	await _ticks(9)
	_expect(normal_jump_count == before + 1 and player.velocity.y < 0.0, "an exhausted-air jump buffered shortly before contact must launch on landing")
	await _grounded_reset()
	player.jump_normal()
	await _ticks(5)
	player.jump_normal()
	await _ticks(1)
	player.jump_normal()
	before = normal_jump_count
	var landed := await _land()
	_expect(landed and normal_jump_count == before, "an old third press must expire before a much later landing")


func _test_finite_inertia() -> void:
	await _grounded_reset()
	player._begin_touch(1, Vector2.ZERO)
	player._drag_touch(Vector2(70, 0))
	player._end_touch()
	await _ticks(1)
	_expect(player.velocity.x > 100.0, "releasing a swipe must preserve initial glide")
	await _ticks(60)
	_expect(is_zero_approx(player.velocity.x), "released momentum must decay completely instead of drifting forever")


func _run_route() -> void:
	# This is a physical traversal check. It starts a new game, then uses only
	# movement, normal jumps, Ripple and the checkpoint's ordinary hyper charges.
	# It never moves entities, grants invulnerability, refills charges or skips land.
	var game = load("res://scripts/main.gd").new()
	game.save.save_path = "user://player-route-spec.json"
	root.add_child(game)
	await process_frame
	game._start(false)
	player = game.player
	player.died.connect(func():
		print("[RouteSpec] death at ", player.position, " nearest threats: ", game.enemies.map(func(enemy): return [enemy.kind, enemy.state, snappedf(enemy.position.x - player.position.x, 1)]))
	)
	var last_attempt := -1
	var last_checkpoint := -1
	var last_floor = null
	var jumps := 0
	var hypers := 0
	var maximum_x := 0.0
	for tick in range(60 * 180):
		await physics_frame
		await process_frame
		maximum_x = maxf(maximum_x, player.position.x)
		if game.attempt != last_attempt:
			last_attempt = game.attempt
			player._begin_touch(0, Vector2(200, 500))
			player._drag_touch(Vector2(270, 500))
			player._begin_secondary(1, Vector2(950, 500))
			last_floor = null
		if game.checkpoint != last_checkpoint:
			last_checkpoint = game.checkpoint
			print("[RouteSpec] checkpoint ", game.checkpoint, " at ", snappedf(tick / 60.0, 0.1), " s; deaths ", game.run_deaths)
		if not player.active or game.retrying:
			continue
		if game.run_deaths > 8:
			break
		for enemy in game.enemies:
			if enemy.kind == "jaguar" and enemy.state == "tell" and enemy.state_time > 0.45 and absf(enemy.position.x - player.position.x) < 190.0 and player.hyper_charges > 0 and player.velocity.y > -100.0:
				player.jump_hyper()
				hypers += 1
		if player.position.x > 4450.0:
			player.clear_input()
			print("[RouteSpec] PASS: new game to arena with actual collisions and ordinary actions; normal jumps=", jumps, ", hyper jumps=", hypers, ", deaths=", game.run_deaths, ", seconds=", snappedf(tick / 60.0, 0.1))
			game.queue_free()
			await process_frame
			await process_frame
			quit(0)
			return
		if player.is_on_floor():
			var under = null
			for platform in game.platforms:
				if absf(player.position.y - platform.position.y) < 10.0 and player.position.x >= platform.position.x - 14.0 and player.position.x < platform.position.x + platform.width + 14.0:
					under = platform
					break
			if under != null:
				if under != last_floor:
					last_floor = under
					print("[RouteSpec] landed ", game.platforms.find(under), " at ", player.position)
				if player.position.x >= under.position.x + under.width - 33.0:
					player.jump_normal()
					jumps += 1
		elif player.velocity.y > 240.0:
			# A rescue tap is allowed only when the trajectory has already dropped
			# below the next reachable deck. This consumes the real finite stock.
			for platform in game.platforms:
				if platform.position.x > player.position.x and platform.position.x - player.position.x < 150.0 and player.position.y > platform.position.y + 12.0:
					if player.hyper_charges > 0:
						player.jump_hyper()
						hypers += 1
					break
	print("[RouteSpec] FAIL: route stopped at checkpoint ", game.checkpoint, ", max x=", maximum_x, ", deaths=", game.run_deaths)
	game.queue_free()
	await process_frame
	await process_frame
	quit(1)

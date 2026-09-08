extends SceneTree
## Menu → all platforms → three real boss openings → reunion ending.
## Movement and attacks use InputEventScreenTouch/Drag through normal dispatch.
## No body placement, health changes, charge grants, invulnerability changes,
## direct jump/attack calls, checkpoint skips or direct win calls are permitted.

var game: Node2D
var player: CharacterBody2D
var boss: Node2D
var touch_down := false
var touch_mode := "none"
var secondary_down := false
var last_state := ""
var dodge_x := 0.0
var wave_jumped := false
var ripples := 0
var jumps := 0
var hypers := 0

func _initialize() -> void:
	call_deferred("_run")

func _screen_touch(index: int, position_: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position_
	event.pressed = pressed
	Input.parse_input_event(event)

func _screen_drag(index: int, position_: Vector2, relative_: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position_
	event.relative = relative_
	Input.parse_input_event(event)

func _touch(pressed: bool) -> void:
	_screen_touch(0, Vector2(450.0, 400.0), pressed)
	touch_down = pressed

func _release() -> void:
	if touch_down:
		_touch(false)
	touch_mode = "none"

func _move(direction: float) -> void:
	if touch_mode != "move":
		_release()
		_touch(true)
		touch_mode = "move"
	var offset := Vector2(signf(direction) * 65.0, 0.0)
	_screen_drag(0, Vector2(450.0, 400.0) + offset, offset)

func _hold() -> void:
	if touch_mode == "hold":
		return
	_release()
	_touch(true)
	touch_mode = "hold"

func _jump() -> void:
	_release()
	_touch(true)
	_screen_drag(0, Vector2(450.0, 335.0), Vector2(0.0, -65.0))
	touch_mode = "jump"

func _toward(x: float, tolerance: float = 12.0) -> void:
	if absf(player.position.x - x) > tolerance:
		_move(x - player.position.x)
	else:
		_release()

func _secondary(pressed: bool) -> void:
	_screen_touch(1, Vector2(950.0, 500.0), pressed)
	secondary_down = pressed

func _route_jump(hyper: bool) -> void:
	if not hyper:
		# A fresh upward swipe retains forward momentum and leaves the second
		# finger's ongoing Ripple hold intact, just as a player can on the phone.
		_jump()
		return
	if secondary_down:
		_secondary(false)
	_secondary(true)
	_secondary(false)
	_secondary(true)

func _find_button(node: Node, text_: String) -> Button:
	if node is Button and node.text == text_:
		return node
	for child in node.get_children():
		var button := _find_button(child, text_)
		if button != null:
			return button
	return null

func _choose_button(text_: String) -> bool:
	var button := _find_button(game.modal, text_)
	if button == null:
		push_error("Missing menu control: " + text_)
		return false
	# Activate the same public Button signal as a touch or accessibility action.
	button.pressed.emit()
	return true

func _run() -> void:
	game = load("res://scripts/main.gd").new()
	game.save.save_path = "user://full-route-spec.json"
	root.add_child(game)
	await process_frame
	if not _choose_button(game.tr2("Begin the journey", "Comenzar el viaje")):
		quit(1)
		return
	await process_frame
	if game.current_screen != "intro" or not _choose_button(game.tr2("Let's bring them home", "Vamos a traerlos a casa")):
		quit(1)
		return
	await process_frame
	player = game.player
	boss = game.boss
	player.jumped.connect(func(hyper: bool):
		if hyper: hypers += 1
		else: jumps += 1)
	player.ripple.connect(func(_origin: Vector2, _direction: float): ripples += 1)
	_move(1.0)
	_secondary(true)
	var arena := false
	var last_checkpoint := -1
	var last_jump_frame := -100
	var maximum_x := 0.0
	for frame in 60 * 180:
		await physics_frame
		await process_frame
		maximum_x = maxf(maximum_x, player.position.x)
		if game.run_deaths > 0:
			push_error("[FullRoute] Hit at %s; checkpoint=%s boss=%s threats=%s" % [player.position, game.checkpoint, boss.state, game.enemies.map(func(enemy): return [enemy.kind, enemy.state, enemy.position])])
			quit(1)
			return
		if game.checkpoint != last_checkpoint:
			last_checkpoint = game.checkpoint
			print("[FullRoute] checkpoint ", game.checkpoint, " at ", snappedf(frame / 60.0, 0.01), " s")
		if not arena:
			if player.position.x > 4450.0:
				if secondary_down: _secondary(false)
				_release()
				arena = true
				print("[FullRoute] arena at ", snappedf(frame / 60.0, 0.01), " s; normal=", jumps, " hyper=", hypers)
				continue
			if frame - last_jump_frame >= 10:
				for enemy in game.enemies:
					if enemy.kind == "jaguar" and enemy.state == "tell" and enemy.state_time > 0.45 and absf(enemy.position.x - player.position.x) < 190.0 and player.hyper_charges > 0 and player.velocity.y > -100.0:
						_route_jump(true)
						last_jump_frame = frame
						break
			if player.is_on_floor() and player.velocity.y >= 0.0 and frame - last_jump_frame >= 10:
				for platform in game.platforms:
					if absf(player.position.y - platform.position.y) < 10.0 and player.position.x >= platform.position.x - 14.0 and player.position.x < platform.position.x + platform.width + 14.0:
						if player.position.x >= platform.position.x + platform.width - 33.0:
							_route_jump(false)
							last_jump_frame = frame
						break
			elif player.velocity.y > 240.0 and frame - last_jump_frame >= 10:
				for platform in game.platforms:
					if platform.position.x > player.position.x and platform.position.x - player.position.x < 150.0 and player.position.y > platform.position.y + 12.0:
						if player.hyper_charges > 0:
							_route_jump(true)
							last_jump_frame = frame
						break
			continue
		if boss.state != last_state:
			print("[FullRoute] boss ", boss.state, " hp=", boss.hp, " at ", snappedf(frame / 60.0, 0.01), " s")
			last_state = boss.state
			if boss.state == "tell":
				wave_jumped = false
				if boss.attack_kind == "leap":
					var away: float = -1.0 if player.position.x < boss.position.x else 1.0
					dodge_x = boss.attack_to.x + away * 180.0
					if dodge_x < boss.arena_left + 30.0 or dodge_x > boss.arena_right - 30.0:
						dodge_x = boss.attack_to.x - away * 180.0
		if game.finished:
			_release()
			for ending_frame in 60 * 5:
				await physics_frame
				await process_frame
				if game.current_screen == "ending":
					if game.checkpoint != 3 or boss.hp != 0 or boss.state != "defeated" or not game.save.data.completed:
						push_error("Ending did not contain all three rescued friends and a defeated reflection")
						quit(1)
						return
					print("[FullRoute] PASS: menu → intro → all four gardens → three real boss openings → reunion ending. Friends=3/3; deaths=", game.run_deaths, "; normal jumps=", jumps, "; finite hyper jumps=", hypers, "; held Ripples=", ripples, "; gameplay seconds=", snappedf(frame / 60.0, 0.01))
					game.music.stop()
					game.music_spare.stop()
					for sound in game.sfx_players: sound.stop()
					await create_timer(0.05, true).timeout
					game.queue_free()
					await process_frame
					await process_frame
					quit(0)
					return
			push_error("Boss finished but reunion ending did not appear")
			quit(1)
			return
		if boss.state == "tell" and boss.attack_kind == "leap" or boss.state == "leap":
			_toward(dodge_x, 8.0)
		elif boss.state == "tell" and boss.attack_kind == "wave":
			if boss.state_time > 0.63 and not wave_jumped:
				_jump()
				wave_jumped = true
			elif not wave_jumped:
				_release()
		elif boss.state == "wave":
			if player.is_on_floor() and boss.state_time > 0.8:
				_release()
		elif boss.state == "exposed":
			var offset: float = boss.position.x - player.position.x
			if touch_mode == "hold":
				pass
			elif absf(offset) > 90.0 or player.facing * offset < 0.0:
				_move(offset)
			else:
				_hold()
		else:
			_release()
	push_error("[FullRoute] Timed out at x=%s, checkpoint=%s, boss=%s, hp=%s" % [maximum_x, game.checkpoint, boss.state, boss.hp])
	quit(1)

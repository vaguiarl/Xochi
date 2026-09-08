extends SceneTree
## Real CharacterBody2D physics plus touch input. The test never moves a body,
## changes boss health, grants immunity, or calls an attack method after setup.

var player: CharacterBody2D
var boss: Node2D
var touch_down := false
var touch_mode := "none"
var last_state := ""
var dodge_x := 0.0
var wave_jumped := false
var damage := 0
var ripples := 0
var jumps := 0

func _initialize() -> void:
	call_deferred("_run")

func _touch(pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = Vector2(450.0, 400.0)
	event.pressed = pressed
	Input.parse_input_event(event)
	touch_down = pressed

func _drag(offset: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = Vector2(450.0, 400.0) + offset
	event.relative = offset
	Input.parse_input_event(event)

func _release() -> void:
	if touch_down:
		# A movement/hold owns this touch, so release cannot become a hyper tap.
		_touch(false)
	touch_mode = "none"

func _move(direction: float) -> void:
	if touch_mode != "move":
		_release()
		_touch(true)
		touch_mode = "move"
	_drag(Vector2(signf(direction) * 65.0, 0.0))

func _hold() -> void:
	if touch_mode == "hold":
		return
	_release()
	_touch(true)
	touch_mode = "hold"

func _jump() -> void:
	_release()
	_touch(true)
	_drag(Vector2(0.0, -65.0))
	touch_mode = "jump"

func _toward(x: float, tolerance: float = 12.0) -> void:
	if absf(player.position.x - x) > tolerance:
		_move(x - player.position.x)
	else:
		_release()

func _run() -> void:
	var floor_body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1500.0, 30.0)
	collision.shape = shape
	collision.position = Vector2(4700.0, 570.0)
	floor_body.add_child(collision)
	root.add_child(floor_body)
	player = load("res://scripts/player.gd").new()
	root.add_child(player)
	player.reset_at(Vector2(4500.0, 555.0))
	player.died.connect(func(): damage += 1)
	player.jumped.connect(func(_hyper: bool): jumps += 1)
	boss = load("res://scripts/boss.gd").new()
	root.add_child(boss)
	boss.configure(Vector2(4830.0, 555.0), player)
	player.ripple.connect(func(origin: Vector2, direction: float):
		ripples += 1
		print("[BossRoute] ripple ", origin, " facing=", direction, " boss=", boss.position, " state=", boss.state)
		boss.receive_ripple(origin, direction))
	for frame in 60 * 60:
		await physics_frame
		if damage > 0:
			push_error("Real touch route was hit: state=%s player=%s boss=%s time=%s" % [boss.state, player.position, boss.position, boss.state_time])
			quit(1)
			return
		if boss.state != last_state:
			print("[BossRoute] ", frame, " ", boss.state, " hp=", boss.hp, " player=", player.position)
			last_state = boss.state
			if boss.state == "tell":
				wave_jumped = false
				if boss.attack_kind == "leap":
					var away: float = -1.0 if player.position.x < boss.position.x else 1.0
					dodge_x = boss.attack_to.x + away * 180.0
					if dodge_x < boss.arena_left + 30.0 or dodge_x > boss.arena_right - 30.0:
						dodge_x = boss.attack_to.x - away * 180.0
		if boss.state == "defeated":
			_release()
			print("[BossRoute] PASS: three openings won through real touch movement, normal jumps and held Ripple; damage=", damage, " ripples=", ripples, " jumps=", jumps, " frames=", frame)
			quit(0)
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
			# Hold the up-swipe through the ring; no automatic airborne steering.
			if player.is_on_floor() and boss.state_time > 0.8:
				_release()
		elif boss.state == "exposed":
			var offset: float = boss.position.x - player.position.x
			if touch_mode == "hold":
				pass
			elif absf(offset) > 90.0:
				_move(offset)
			else:
				# Turn using the same swipe before beginning a stationary hold.
				if player.facing * offset < 0.0:
					_move(offset)
				else:
					_hold()
		else:
			_release()
	push_error("Boss route did not finish within sixty simulated seconds")
	quit(1)

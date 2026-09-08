extends Node2D
## Honest, resettable enemies. Every attack commits to a point before moving.
## The origin is a jaguar's feet, or a crow's body center.

var kind: String = "crow"
var active: bool = true
var state: String = "idle"
var player: Node2D
var home := Vector2.ZERO
var patrol_bounds := Vector2(-90.0, 90.0)
var state_time: float = 0.0
var visual_time: float = 0.0
var attack_from := Vector2.ZERO
var attack_to := Vector2.ZERO
var facing: float = -1.0
var patrol_direction: float = 1.0
var hit_this_attack: bool = false
var stomp_lock: float = 0.0
var ripple_lock: float = 0.0

func _ready() -> void:
	add_to_group("xochi_mvp_enemies")

func configure(enemy_kind: String, origin: Vector2, target: Node2D,
		bounds: Vector2 = Vector2(-90.0, 90.0)) -> void:
	kind = enemy_kind
	home = origin
	player = target
	patrol_bounds = bounds
	reset_state()

func reset_state() -> void:
	global_position = home
	active = true
	state = "idle"
	state_time = 0.0
	visual_time = 0.0
	facing = -1.0
	patrol_direction = 1.0
	hit_this_attack = false
	stomp_lock = 0.0
	ripple_lock = 0.0
	modulate = Color.WHITE
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not active:
		return
	visual_time += delta
	state_time += delta
	stomp_lock = maxf(0.0, stomp_lock - delta)
	ripple_lock = maxf(0.0, ripple_lock - delta)
	if not is_instance_valid(player) or not player.active:
		queue_redraw()
		return
	if kind == "crow":
		_update_crow(delta)
	else:
		_update_jaguar(delta)
	_check_stomp()
	_check_attack_contact()
	queue_redraw()

func _enter(next_state: String) -> void:
	state = next_state
	state_time = 0.0

func _engage_distance(horizontal: float, vertical: float) -> bool:
	return absf(player.global_position.x - global_position.x) < horizontal \
		and absf(player.global_position.y - global_position.y) < vertical

func _can_commit() -> bool:
	# Neighbors take turns announcing attacks. This coordinates pressure without
	# waiting on an LLM, or combining two unavoidable attacks over a narrow boat.
	for neighbor in get_tree().get_nodes_in_group("xochi_mvp_enemies"):
		if neighbor == self or not neighbor.active:
			continue
		if absf(neighbor.global_position.x - global_position.x) < 380.0 \
				and neighbor.state in ["tell", "dive", "pounce"]:
			return false
	return true

func _update_crow(_delta: float) -> void:
	match state:
		"idle":
			global_position = home + Vector2(sin(visual_time * 0.9) * 23.0, sin(visual_time * 2.0) * 7.0)
			if state_time > 0.65 and _engage_distance(330.0, 320.0) and _can_commit():
				attack_from = global_position
				# Predict once, then show that exact destination for a full second.
				var prediction: float = clampf(player.velocity.x * 0.20, -48.0, 48.0)
				attack_to = player.global_position + Vector2(prediction, -27.0)
				attack_to.x = clampf(attack_to.x, home.x - 290.0, home.x + 290.0)
				attack_to.y = clampf(attack_to.y, home.y + 35.0, home.y + 295.0)
				facing = -1.0 if attack_to.x < global_position.x else 1.0
				hit_this_attack = false
				_enter("tell")
		"tell":
			global_position = attack_from + Vector2(0.0, sin(state_time * 25.0) * 1.8)
			if state_time >= 1.0:
				global_position = attack_from
				_enter("dive")
		"dive":
			var t := clampf(state_time / 0.52, 0.0, 1.0)
			global_position = attack_from.lerp(attack_to, t * t * (3.0 - 2.0 * t))
			if t >= 1.0:
				attack_from = global_position
				_enter("recover")
		"recover":
			var t := clampf((state_time - 0.45) / 1.15, 0.0, 1.0)
			global_position = attack_from.lerp(home, t * t * (3.0 - 2.0 * t))
			if state_time >= 1.75:
				_enter("idle")
		"stunned":
			if state_time >= 1.8:
				attack_from = global_position
				_enter("recover")

func _update_jaguar(delta: float) -> void:
	match state:
		"idle":
			global_position.x += patrol_direction * 29.0 * delta
			global_position.y = home.y
			if global_position.x >= home.x + patrol_bounds.y:
				global_position.x = home.x + patrol_bounds.y
				patrol_direction = -1.0
			elif global_position.x <= home.x + patrol_bounds.x:
				global_position.x = home.x + patrol_bounds.x
				patrol_direction = 1.0
			facing = patrol_direction
			if state_time > 0.7 and _engage_distance(275.0, 155.0) and _can_commit():
				attack_from = global_position
				var prediction: float = clampf(player.velocity.x * 0.16, -36.0, 36.0)
				attack_to = Vector2(clampf(player.global_position.x + prediction,
					home.x + patrol_bounds.x - 90.0, home.x + patrol_bounds.y + 90.0), home.y)
				facing = -1.0 if attack_to.x < global_position.x else 1.0
				hit_this_attack = false
				_enter("tell")
		"tell":
			if state_time >= 0.95:
				_enter("pounce")
		"pounce":
			var t := clampf(state_time / 0.60, 0.0, 1.0)
			global_position = attack_from.lerp(attack_to, t)
			global_position.y -= sin(t * PI) * 88.0
			if t >= 1.0:
				_enter("recover")
		"recover":
			if state_time >= 1.5:
				# Walk home naturally instead of teleporting to the patrol route.
				global_position.x = move_toward(global_position.x,
					clampf(global_position.x, home.x + patrol_bounds.x, home.x + patrol_bounds.y), 45.0 * delta)
				if global_position.x >= home.x + patrol_bounds.x and global_position.x <= home.x + patrol_bounds.y:
					_enter("idle")
		"stunned":
			global_position.y = move_toward(global_position.y, home.y, delta * 220.0)
			if state_time >= 1.8:
				_enter("recover")

func receive_ripple(origin: Vector2, direction: float) -> void:
	if not active or ripple_lock > 0.0:
		return
	var center := global_position + Vector2(0.0, 0.0 if kind == "crow" else -23.0)
	# The player's signal already supplies its body center, not its feet.
	var offset := center - origin
	if absf(offset.x) <= 96.0 and absf(offset.y) <= 58.0 and offset.x * direction >= -28.0:
		ripple_lock = 0.35
		_stun()

func _stun() -> void:
	stomp_lock = 0.45
	hit_this_attack = true
	_enter("stunned")

func _check_stomp() -> void:
	if stomp_lock > 0.0 or state == "stunned":
		return
	var top: float = global_position.y - (14.0 if kind == "crow" else 42.0)
	var feet: Vector2 = player.global_position
	if player.velocity.y > 55.0 and absf(feet.x - global_position.x) < 31.0 \
			and feet.y >= top - 12.0 and feet.y <= top + 14.0:
		player.velocity.y = -345.0
		_stun()

func _check_attack_contact() -> void:
	if hit_this_attack or (state != "dive" and state != "pounce"):
		return
	var center := global_position + Vector2(0.0, 0.0 if kind == "crow" else -22.0)
	var player_center: Vector2 = player.global_position + Vector2(0.0, -26.0)
	if center.distance_to(player_center) < 39.0:
		hit_this_attack = true
		player.take_hit()

func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	draw_set_transform(center, 0.0, radii)
	draw_circle(Vector2.ZERO, 1.0, color, true, -1.0, true)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if state == "tell":
		var destination := to_local(attack_to)
		var warning := Color("ffc96f")
		warning.a = 0.55 + sin(visual_time * 13.0) * 0.2
		draw_dashed_line(Vector2(0.0, -8.0), destination, Color(1.0, 0.8, 0.45, 0.36), 2.0, 8.0, true)
		draw_arc(destination, 28.0, 0.0, TAU, 36, warning, 3.0, true)
		draw_line(destination + Vector2(-36.0, 0.0), destination + Vector2(36.0, 0.0), warning, 2.0, true)
	if kind == "crow":
		_draw_crow()
	else:
		_draw_jaguar()
	if state == "stunned":
		for i in 3:
			var angle: float = visual_time * 2.8 + float(i) * TAU / 3.0
			var center := Vector2(cos(angle) * 25.0, -51.0 + sin(angle) * 7.0)
			draw_circle(center, 3.0, Color("ffe8a3"), true, -1.0, true)
			draw_arc(Vector2(0.0, -51.0), 20.0, 0.0, PI, 24, Color(1.0, 0.86, 0.61, 0.5), 1.5, true)

func _draw_crow() -> void:
	var wing: float = sin(visual_time * (16.0 if state == "dive" else 10.0))
	var fold: float = 0.45 if state == "tell" or state == "stunned" else 1.0
	var wing_y: float = -10.0 - wing * 15.0 * fold
	var ink := Color("214655")
	var teal := Color("397580")
	var highlight := Color("74aaa3")
	# Rounded feathers, rather than sharp hostile triangles.
	for side in [-1.0, 1.0]:
		for i in 3:
			var base := Vector2(side * (17.0 + float(i) * 9.0 * fold), wing_y + float(i) * 5.0)
			_ellipse(base, Vector2(14.0, 8.0), ink)
			_ellipse(base + Vector2(0.0, -2.0), Vector2(12.0, 5.0), teal)
	_ellipse(Vector2(0.0, 1.0), Vector2(21.0, 17.0), ink)
	_ellipse(Vector2(0.0, -2.0), Vector2(19.0, 16.0), teal)
	_ellipse(Vector2(-4.0, -6.0), Vector2(10.0, 8.0), highlight)
	_ellipse(Vector2(facing * 11.0, -10.0), Vector2(13.0, 13.0), ink)
	_ellipse(Vector2(facing * 12.0, -12.0), Vector2(11.0, 10.0), teal)
	_ellipse(Vector2(facing * 25.0, -9.0), Vector2(8.0, 4.5), Color("f2bc77"))
	var eye := Vector2(facing * 17.0, -14.0)
	if state == "stunned":
		draw_arc(eye + Vector2(0.0, 2.0), 3.0, PI, TAU, 8, Color("eaf3dc"), 2.0, true)
	else:
		draw_circle(eye, 3.7, Color("eff6d9"), true, -1.0, true)
		draw_circle(eye + Vector2(facing, 0.0), 1.6, Color("1a293d"), true, -1.0, true)
	# The tiny coral flower ties even the opponents to the canal fiesta.
	for i in 5:
		var angle: float = float(i) * TAU / 5.0
		draw_circle(Vector2(-facing * 7.0, -20.0) + Vector2(cos(angle), sin(angle)) * 3.5, 3.0, Color("e99192"), true, -1.0, true)
	draw_circle(Vector2(-facing * 7.0, -20.0), 2.0, Color("ffe0a0"), true, -1.0, true)

func _draw_jaguar() -> void:
	var crouch: float = 6.0 if state == "tell" else 0.0
	var body_y: float = -24.0 + crouch
	var step: float = sin(visual_time * 6.0) * 3.0 if state == "idle" else 0.0
	_ellipse(Vector2(0.0, 1.0), Vector2(39.0, 5.5), Color(0.04, 0.18, 0.2, 0.22))
	var tail := PackedVector2Array()
	for i in 12:
		var t: float = float(i) / 11.0
		tail.append(Vector2(-facing * (20.0 + t * 36.0), body_y + 5.0 - sin(t * PI * 0.8) * 18.0 + sin(visual_time * 2.0 + t * 3.0) * 3.0))
	draw_polyline(tail, Color("685568"), 9.0, true)
	draw_polyline(tail, Color("dca578"), 5.5, true)
	for side in [-1.0, 1.0]:
		_ellipse(Vector2(side * 20.0, -8.0 + step * side), Vector2(9.0, 10.0), Color("715767"))
		_ellipse(Vector2(side * 20.0 + facing * 2.0, -5.0 + step * side), Vector2(10.0, 6.0), Color("f0c797"))
	_ellipse(Vector2(0.0, body_y), Vector2(33.0, 22.0), Color("765e70"))
	_ellipse(Vector2(0.0, body_y - 2.0), Vector2(31.0, 20.0), Color("d5a06d"))
	_ellipse(Vector2(0.0, body_y + 6.0), Vector2(24.0, 12.0), Color("f2d0a1"))
	for spot in [Vector2(-15.0, -8.0), Vector2(0.0, -12.0), Vector2(13.0, -6.0), Vector2(-7.0, 4.0)]:
		draw_arc(Vector2(spot.x, body_y + spot.y), 3.7, 0.0, TAU * 0.82, 12, Color("93756d"), 2.0, true)
	var head := Vector2(facing * 26.0, body_y - 9.0)
	for side in [-1.0, 1.0]:
		draw_circle(head + Vector2(side * 12.0, -13.0), 9.0, Color("765e70"), true, -1.0, true)
		draw_circle(head + Vector2(side * 12.0, -13.0), 5.5, Color("dba396"), true, -1.0, true)
	_ellipse(head, Vector2(21.0, 18.0), Color("e9ba87"))
	_ellipse(head + Vector2(facing * 6.0, 7.0), Vector2(12.0, 8.0), Color("ffe3b7"))
	for side in [-1.0, 1.0]:
		var eye := head + Vector2(side * 8.0 + facing * 2.0, -2.0)
		if state == "stunned":
			draw_line(eye - Vector2(3.0, 0.0), eye + Vector2(3.0, 0.0), Color("514555"), 2.0, true)
		else:
			draw_circle(eye, 3.2, Color("514555"), true, -1.0, true)
			draw_circle(eye + Vector2(-0.7, -0.8), 1.1, Color("fff2d4"), true, -1.0, true)
	_ellipse(head + Vector2(facing * 4.0, 5.0), Vector2(3.5, 2.5), Color("996a79"))
	# A turquoise neck ribbon reads as a mischievous festival spirit.
	draw_line(head + Vector2(-facing * 10.0, 15.0), head + Vector2(facing * 6.0, 18.0), Color("579e9a"), 5.0, true)

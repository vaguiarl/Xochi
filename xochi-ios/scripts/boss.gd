extends Node2D
## A frightened reflection. She commits to a visible destination, then rests.
## Only an exposed recovery accepts Ripple; three hits release her hold.

signal defeated
signal phase_changed(tell: String)

var active: bool = true
var hp: int = 3
var state: String = "idle"
var player: Node2D
var home := Vector2.ZERO
var state_time: float = 0.0
var visual_time: float = 0.0
var attack_from := Vector2.ZERO
var attack_to := Vector2.ZERO
var attack_number: int = 0
var attack_kind: String = "leap"
var facing: float = -1.0
var wave_x: float = 0.0
var wave_direction: float = -1.0
var hit_this_attack: bool = false
var reject_flash: float = 0.0
var hit_flash: float = 0.0
var arena_left: float = 4290.0
var arena_right: float = 5115.0
var character_texture: Texture2D:
	set(value):
		character_texture = value
		queue_redraw()

func configure(origin: Vector2, target: Node2D) -> void:
	home = origin
	player = target
	arena_left = origin.x - 500.0
	arena_right = origin.x + 325.0
	reset_state()

func reset_state() -> void:
	global_position = home
	active = true
	hp = 3
	state = "idle"
	state_time = 0.0
	visual_time = 0.0
	attack_number = 0
	attack_kind = "leap"
	facing = -1.0
	wave_x = home.x
	wave_direction = -1.0
	hit_this_attack = false
	reject_flash = 0.0
	hit_flash = 0.0
	modulate = Color.WHITE
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not active:
		return
	visual_time += delta
	state_time += delta
	reject_flash = maxf(0.0, reject_flash - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	if not is_instance_valid(player) or not player.active:
		queue_redraw()
		return
	match state:
		"idle":
			if state_time >= 1.2 and absf(player.global_position.x - global_position.x) < 610.0:
				_begin_attack()
		"tell":
			if state_time >= (1.05 if hp > 1 else 0.90):
				if attack_kind == "leap":
					_enter("leap")
				else:
					wave_x = global_position.x + wave_direction * 42.0
					_enter("wave")
		"leap":
			var t := clampf(state_time / 0.78, 0.0, 1.0)
			global_position = attack_from.lerp(attack_to, t)
			global_position.y -= sin(t * PI) * 140.0
			_check_leap_contact()
			if t >= 1.0:
				_expose()
		"wave":
			wave_x += wave_direction * (310.0 if hp > 1 else 345.0) * delta
			_check_wave_contact()
			if wave_x < arena_left - 45.0 or wave_x > arena_right + 45.0 or state_time >= 2.75:
				_expose()
		"exposed":
			if state_time >= 2.15:
				_enter("idle")
				phase_changed.emit("watch")
		"hurt":
			if state_time >= 0.9:
				_enter("idle")
				phase_changed.emit("watch")
		"defeated":
			pass
	queue_redraw()

func _enter(next_state: String) -> void:
	state = next_state
	state_time = 0.0

func _begin_attack() -> void:
	attack_number += 1
	attack_from = global_position
	facing = -1.0 if player.global_position.x < global_position.x else 1.0
	# The route choice is based on one observation, never a continuously tracked aim.
	# Far players get a leap, keeping every recovery within reach.
	attack_kind = "leap" if attack_number % 2 == 1 or absf(player.global_position.x - global_position.x) > 260.0 else "wave"
	hit_this_attack = false
	if attack_kind == "leap":
		var prediction: float = clampf(player.velocity.x * 0.13, -40.0, 40.0)
		attack_to = Vector2(clampf(player.global_position.x + prediction, arena_left + 48.0, arena_right - 48.0), home.y)
		phase_changed.emit("leap")
	else:
		wave_direction = facing
		attack_to = Vector2(arena_left if facing < 0.0 else arena_right, home.y)
		phase_changed.emit("wave")
	_enter("tell")

func _expose() -> void:
	global_position.y = home.y
	_enter("exposed")
	phase_changed.emit("exposed")

func receive_ripple(origin: Vector2, direction: float) -> void:
	if not active or hp <= 0:
		return
	var offset := global_position - origin
	if absf(offset.x) > 106.0 or absf(offset.y) > 76.0 or offset.x * direction < -30.0:
		return
	if state != "exposed":
		reject_flash = 0.22
		queue_redraw()
		return
	hp -= 1
	hit_flash = 0.45
	if hp == 0:
		_enter("defeated")
		phase_changed.emit("safe")
		defeated.emit()
	else:
		_enter("hurt")
		phase_changed.emit("comforted")
	queue_redraw()

func _check_leap_contact() -> void:
	if hit_this_attack:
		return
	var player_center: Vector2 = player.global_position + Vector2(0.0, -27.0)
	if player_center.distance_to(global_position + Vector2(0.0, -33.0)) < 43.0:
		hit_this_attack = true
		player.take_hit()

func _check_wave_contact() -> void:
	if hit_this_attack:
		return
	# The visible ring is ankle-high. A normal jump always clears it.
	var feet: Vector2 = player.global_position
	if absf(feet.x - wave_x) < 33.0 and feet.y > home.y - 54.0 and feet.y < home.y + 24.0:
		hit_this_attack = true
		player.take_hit()

func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	draw_set_transform(center, 0.0, radii)
	draw_circle(Vector2.ZERO, 1.0, color, true, -1.0, true)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	var ground_offset: float = home.y - global_position.y
	_ellipse(Vector2(0.0, ground_offset + 2.0), Vector2(42.0, 7.0), Color(0.10, 0.09, 0.25, 0.23))
	if state == "tell":
		var end := to_local(attack_to)
		var tell_color := Color(1.0, 0.73, 0.60, 0.72 + 0.20 * sin(visual_time * 13.0))
		if attack_kind == "leap":
			_ellipse(end + Vector2(0.0, -2.0), Vector2(49.0, 11.0), Color(1.0, 0.57, 0.49, 0.22))
			draw_arc(end + Vector2(0.0, -16.0), 32.0, 0.0, TAU, 48, tell_color, 3.0, true)
			draw_dashed_line(Vector2(0.0, -36.0), end + Vector2(0.0, -18.0), Color(1.0, 0.8, 0.67, 0.35), 2.0, 10.0, true)
			for i in 3:
				var x: float = end.x + (float(i) - 1.0) * 17.0
				draw_line(Vector2(x, end.y - 61.0), Vector2(x, end.y - 36.0), tell_color, 2.0, true)
		else:
			draw_line(Vector2(facing * 43.0, -18.0), end + Vector2(0.0, -18.0), Color(0.79, 0.65, 1.0, 0.23), 35.0, true)
			for i in 5:
				var x: float = facing * (70.0 + float(i) * 44.0)
				var point := Vector2(x, -18.0)
				draw_line(point - Vector2(facing * 8.0, 6.0), point, tell_color, 2.5, true)
				draw_line(point - Vector2(facing * 8.0, -6.0), point, tell_color, 2.5, true)
	if state == "wave":
		var wave := to_local(Vector2(wave_x, home.y - 20.0))
		_ellipse(wave, Vector2(33.0, 25.0), Color(0.74, 0.55, 0.96, 0.12))
		draw_arc(wave, 27.0, 0.0, TAU, 48, Color("c6a7ee"), 5.0, true)
		draw_arc(wave + Vector2(-wave_direction * 9.0, 0.0), 19.0, 0.0, TAU, 36, Color("e4d4ff"), 2.5, true)
		for i in 4:
			var offset := Vector2(-wave_direction * float(i) * 12.0, sin(visual_time * 8.0 + float(i)) * 7.0)
			draw_circle(wave + offset, 3.5, Color(0.84, 0.75, 1.0, 0.7 - float(i) * 0.12), true, -1.0, true)
	_draw_reflection()

func _draw_reflection() -> void:
	var safe: bool = state == "defeated"
	var exposed: bool = state == "exposed" or state == "hurt" or safe
	var bob: float = sin(visual_time * 2.6) * 2.0
	var crouch: float = 6.0 if state == "tell" else 0.0
	var center := Vector2(0.0, -32.0 + bob + crouch)
	if character_texture != null:
		var source_size := character_texture.get_size()
		var height := 88.0
		var width: float = height * source_size.x / maxf(source_size.y, 1.0)
		var tint := Color(0.69, 0.70, 0.96, 0.96)
		if safe:
			tint = Color(0.94, 0.86, 1.0, 0.85)
		if hit_flash > 0.0:
			tint = tint.lerp(Color("fff1d1"), hit_flash * 1.5)
		var stretch: float = 0.08 if state == "leap" else 0.0
		var squash: float = 0.10 if state == "tell" else 0.0
		draw_set_transform(Vector2(0.0, bob + crouch), 0.0,
			Vector2(facing * (1.0 + squash - stretch * 0.5), 1.0 - squash + stretch))
		draw_texture_rect(character_texture, Rect2(-width * 0.5, -height + 6.0, width, height), false, tint)
		draw_set_transform(Vector2.ZERO)
		_draw_reflection_aura(center, exposed, safe, bob)
		return
	var outline := Color("54466f")
	var body := Color("a595c6")
	var light := Color("c6badf")
	var coral := Color("c5a0cb")
	if safe:
		body = Color("ddb9d5")
		light = Color("f2d6e2")
		coral = Color("e9b5c9")
	if hit_flash > 0.0:
		body = body.lerp(Color("fff1d1"), hit_flash * 1.5)
	# A soft moving tail, with no equipment or aggressive silhouette.
	var tail := PackedVector2Array([
		center + Vector2(-facing * 14.0, 14.0),
		center + Vector2(-facing * 34.0, 17.0),
		center + Vector2(-facing * 52.0, 8.0 + sin(visual_time * 2.5) * 5.0),
		center + Vector2(-facing * 47.0, 25.0),
		center + Vector2(-facing * 23.0, 29.0),
		center + Vector2(-facing * 11.0, 23.0),
	])
	draw_colored_polygon(tail, outline)
	draw_polyline(PackedVector2Array([tail[1], tail[2], tail[3], tail[4]]), coral, 6.0, true)
	_ellipse(center + Vector2(0.0, 8.0), Vector2(22.0, 24.0), outline)
	_ellipse(center + Vector2(0.0, 7.0), Vector2(20.0, 22.0), body)
	_ellipse(center + Vector2(0.0, 12.0), Vector2(13.0, 15.0), light)
	for side in [-1.0, 1.0]:
		_ellipse(center + Vector2(side * 14.0, 27.0), Vector2(10.0, 6.0), outline)
		_ellipse(center + Vector2(side * 14.0, 25.0), Vector2(9.0, 5.0), body)
		var arm_y: float = 10.0 if exposed else 4.0
		_ellipse(center + Vector2(side * 22.0, arm_y), Vector2(7.0, 12.0), body)
	var head := center + Vector2(0.0, -20.0)
	for side in [-1.0, 1.0]:
		for i in 3:
			var y: float = -10.0 + float(i) * 10.0
			var tip := head + Vector2(side * (40.0 + sin(visual_time * 2.0 + float(i)) * 2.0), y - 7.0)
			draw_line(head + Vector2(side * 23.0, y * 0.6), tip, outline, 9.0, true)
			draw_line(head + Vector2(side * 24.0, y * 0.6), tip, coral, 6.0, true)
			draw_circle(tip, 4.5, coral, true, -1.0, true)
	_ellipse(head, Vector2(30.0, 23.0), outline)
	_ellipse(head + Vector2(0.0, -1.0), Vector2(28.0, 21.0), body)
	_ellipse(head + Vector2(-7.0, -10.0), Vector2(15.0, 7.0), light)
	for side in [-1.0, 1.0]:
		var eye := head + Vector2(side * 11.0, 0.0)
		if safe:
			draw_arc(eye + Vector2(0.0, 3.0), 4.0, PI, TAU, 12, outline, 2.5, true)
		else:
			_ellipse(eye, Vector2(4.7, 6.0), Color("39334f"))
			draw_circle(eye + Vector2(-1.2, -2.0), 1.8, Color("f8edf1"), true, -1.0, true)
			if not exposed:
				draw_line(eye + Vector2(-side * 3.0, -10.0), eye + Vector2(side * 4.0, -8.0), outline, 1.6, true)
		_ellipse(head + Vector2(side * 18.0, 8.0), Vector2(5.0, 2.8), coral)
	if safe:
		draw_arc(head + Vector2(0.0, 8.0), 4.0, 0.0, PI, 12, outline, 1.6, true)
	else:
		draw_arc(head + Vector2(0.0, 13.0), 3.0, PI, TAU, 12, outline, 1.5, true)
	# A jade scarf and a tiny flower preserve her connection to the heroine.
	draw_line(center + Vector2(-16.0, -1.0), center + Vector2(14.0, 0.0), Color("729d9c"), 6.0, true)
	draw_line(center + Vector2(12.0, 1.0), center + Vector2(17.0, 13.0), Color("729d9c"), 6.0, true)
	var flower := head + Vector2(-17.0, -22.0)
	for i in 5:
		var angle: float = float(i) * TAU / 5.0
		draw_circle(flower + Vector2(cos(angle), sin(angle)) * 4.0, 3.8, Color("d6b8bc"), true, -1.0, true)
	draw_circle(flower, 2.9, Color("ffe0a3"), true, -1.0, true)
	_draw_reflection_aura(center, exposed, safe, bob)

func _draw_reflection_aura(center: Vector2, exposed: bool, safe: bool, bob: float) -> void:
	if exposed and not safe:
		# Gold motes explicitly mark the window in which a Ripple can help.
		for i in 5:
			var angle: float = visual_time * 1.4 + float(i) * TAU / 5.0
			draw_circle(center + Vector2(cos(angle) * 46.0, sin(angle) * 37.0 - 9.0), 3.0, Color("ffe3a0"), true, -1.0, true)
	elif not safe:
		var alpha: float = 0.19 + reject_flash * 2.0
		draw_arc(center + Vector2(0.0, -8.0), 47.0, 0.0, TAU, 64, Color(0.74, 0.69, 0.90, alpha), 2.5, true)
	# Three small knots of worry fade as she is comforted.
	for i in 3:
		var color := Color("ddc5ff") if i < hp else Color(0.70, 0.63, 0.82, 0.18)
		draw_circle(Vector2((float(i) - 1.0) * 14.0, -94.0 + bob), 4.0, color, true, -1.0, true)

extends Node
## One authored movement segment at a time. Never teleports, spends hyper stock,
## retries a failed jump, or resumes after manual input, pause, or player reset.

signal arrived
signal manual_takeover
signal failed(reason: String)

const MAX_DISTANCE := 360.0
const MAX_HEIGHT_CHANGE := 160.0
const MAX_SECONDS := 4.0
const ARRIVAL_DISTANCE := 5.0
const FOOT_MARGIN := 18.0

var player: CharacterBody2D
var guiding := false
var _target := Vector2.ZERO
var _jump_segment := false
var _left_floor := false
var _air_jump_issued := false
var _elapsed := 0.0
var _stuck_time := 0.0
var _last_x := 0.0


func configure(controlled_player: CharacterBody2D) -> void:
	cancel_guidance()
	if is_instance_valid(player):
		if player.manual_input.is_connected(_on_manual_input):
			player.manual_input.disconnect(_on_manual_input)
		if player.input_cleared.is_connected(cancel_guidance):
			player.input_cleared.disconnect(cancel_guidance)
	player = controlled_player
	# Decide steering before CharacterBody2D integrates this frame.
	process_physics_priority = -10
	if is_instance_valid(player):
		player.manual_input.connect(_on_manual_input)
		player.input_cleared.connect(cancel_guidance)


func guide_to(target: Vector2, jump: bool = false) -> bool:
	cancel_guidance()
	if not is_instance_valid(player) or not player.active or not player.is_inside_tree():
		failed.emit("unavailable")
		return false
	if get_tree().paused or player.has_manual_input() or not player.is_on_floor() or player.velocity.y < 0.0:
		failed.emit("not_ready")
		return false
	if not target.is_finite() or absf(target.x - player.global_position.x) > MAX_DISTANCE or absf(target.y - player.global_position.y) > MAX_HEIGHT_CHANGE:
		failed.emit("out_of_range")
		return false
	if not _safe_landing(target):
		failed.emit("unsafe_landing")
		return false
	if not jump and not _walk_supported(player.global_position, target):
		failed.emit("unsafe_walk")
		return false
	_target = target
	_jump_segment = jump
	_left_floor = false
	_air_jump_issued = false
	_elapsed = 0.0
	_stuck_time = 0.0
	_last_x = player.global_position.x
	guiding = true
	if jump and player.global_position.distance_to(target) > ARRIVAL_DISTANCE:
		player.jump_normal(true)
	return true


func wait_here() -> void:
	cancel_guidance()


func cancel_guidance() -> void:
	_end_guidance(true)


func _end_guidance(brake: bool) -> void:
	var was_guiding := guiding
	guiding = false
	if is_instance_valid(player):
		player.clear_guidance()
		if was_guiding and brake and not player.has_manual_input():
			player.velocity.x = 0.0


func _on_manual_input() -> void:
	# Keep current momentum for a manual upward swipe. Never clear the new touch.
	_end_guidance(false)
	manual_takeover.emit()


func _fail(reason: String) -> void:
	cancel_guidance()
	failed.emit(reason)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel_guidance()


func _exit_tree() -> void:
	cancel_guidance()


func _physics_process(delta: float) -> void:
	if not guiding:
		return
	if not is_instance_valid(player) or not player.active or player.has_manual_input():
		_fail("interrupted")
		return
	_elapsed += delta
	if _elapsed > MAX_SECONDS or player.global_position.y > _target.y + 100.0:
		_fail("timeout" if _elapsed > MAX_SECONDS else "missed_landing")
		return
	var grounded := player.is_on_floor() and player.velocity.y >= 0.0
	var remaining := _target.x - player.global_position.x
	if grounded and absf(remaining) <= ARRIVAL_DISTANCE and absf(player.global_position.y - _target.y) < 10.0:
		cancel_guidance()
		arrived.emit()
		return
	if _jump_segment:
		if not grounded:
			_left_floor = true
		elif _left_floor or _elapsed > 0.18:
			# A landing short of the intended spot ends this command, without a hop.
			_fail("short_landing")
			return
		if _left_floor and not _air_jump_issued and player.velocity.y >= -45.0:
			var drop := maxf(0.0, _target.y - player.global_position.y)
			var descent_gravity: float = player.GRAVITY * 1.6
			var fall_seconds: float = (-player.velocity.y + sqrt(player.velocity.y * player.velocity.y + 2.0 * descent_gravity * drop)) / descent_gravity
			# Only add an ordinary second lift when the remaining normal arc cannot
			# reach the landing. The player owns and enforces the one-air-jump limit.
			if absf(remaining) > player.WALK_SPEED * maxf(0.0, fall_seconds) - 12.0 or player.global_position.y > _target.y - 12.0:
				if absf(remaining) > ARRIVAL_DISTANCE:
					_air_jump_issued = true
					player.jump_normal(true)
	else:
		if not grounded or not _safe_landing(player.global_position + Vector2(signf(remaining) * 24.0, 0.0)):
			_fail("edge")
			return
	if absf(remaining) <= ARRIVAL_DISTANCE:
		player.guided_direction = 0.0
		player.velocity.x = 0.0
	else:
		player.guided_direction = clampf(remaining * 6.0 / player.WALK_SPEED, -1.0, 1.0)
		if absf(player.global_position.x - _last_x) < 0.2:
			_stuck_time += delta
		else:
			_stuck_time = 0.0
		if _stuck_time > 0.4:
			_fail("blocked")
	_last_x = player.global_position.x


func _walk_supported(start: Vector2, target: Vector2) -> bool:
	if absf(start.y - target.y) > 8.0:
		return false
	var samples := maxi(1, ceili(absf(target.x - start.x) / 12.0))
	for index in range(samples + 1):
		if not _safe_landing(start.lerp(target, float(index) / samples)):
			return false
	return true


func _safe_landing(feet: Vector2) -> bool:
	for offset in [-FOOT_MARGIN, 0.0, FOOT_MARGIN]:
		var from := feet + Vector2(offset, -8.0)
		var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, 20.0), player.collision_mask, [player.get_rid()])
		var hit := player.get_world_2d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.normal.y > -0.7:
			return false
	return true

extends SceneTree
## Verify crossing opportunities, repeated-trick learning and retry fairness.
## The tests never force a state or write learned counters.

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _advance(guard: Node2D, seconds: float) -> void:
	for tick in int(ceil(seconds * 60.0)):
		guard._physics_process(1.0 / 60.0)

func _wait_for(guard: Node2D, desired: String, limit := 12.0) -> bool:
	for tick in int(ceil(limit * 60.0)):
		if guard.state == desired:
			return true
		guard._physics_process(1.0 / 60.0)
	return guard.state == desired

func _run() -> void:
	var guard = load("res://scripts/crow_guard.gd").new()
	root.add_child(guard)
	guard.configure(Vector2(945.0, 420.0))
	_expect(guard.texture != null and guard.texture.get_width() > 100, "Crowquistador must load its real character art")
	# Test-only source validation: headless CompressedTexture2D.has_alpha()
	# reports the dummy renderer's texture rather than the PNG's real channel.
	var source_image := Image.load_from_file(ProjectSettings.globalize_path("res://assets/companion/crowquistador.png"))
	_expect(source_image != null and source_image.detect_alpha() != Image.ALPHA_NONE,
		"The source sprite must contain real alpha, not a painted checkerboard")
	guard.set_physics_process(false)
	var notices := [0]
	var openings: Array[bool] = []
	guard.noticed.connect(func(): notices[0] += 1)
	guard.opening_changed.connect(func(open: bool): openings.append(open))
	_expect(not guard.can_cross(), "A watched bridge must not claim to be safe")
	_expect(not guard.observe_crossing(Vector2(200.0, 420.0)), "A remote Xochi must not be spotted through the whole scene")
	_expect(guard.observe_crossing(Vector2(860.0, 420.0)), "Attempting the watched bridge must produce a nonlethal notice")
	guard.observe_crossing(Vector2(875.0, 420.0))
	_expect(notices[0] == 1, "One crossing attempt must not spam noticed every frame")
	_expect(not guard.distract("invented_action"), "Unrecognized tricks must never unlock the bridge")
	_expect(guard.distract("bell"), "A recognized distraction must attract a watching guard")
	_advance(guard, 0.4)
	_expect(not guard.can_cross(), "Players must see the guard react before an opening starts")
	_expect(not guard.distract("bell"), "Repeated commands cannot extend a distraction already in progress")
	_expect(_wait_for(guard, "investigate"), "The guard must turn away after noticing the distraction")
	var first_window: float = guard.remaining_open_time()
	_expect(first_window >= 5.9 and guard.can_cross(), "The first distraction must give a generous voice-and-travel window")
	_expect(not guard.observe_crossing(Vector2(1000.0, 420.0)), "A distracted guard must not notice a correctly timed crossing")
	_advance(guard, 3.1)
	_expect(guard.can_cross(), "A crossing begun promptly must have time to finish")
	_expect(_wait_for(guard, "watch"), "A neglected opening must expire and restore a watched bridge")
	_expect(openings == [true, false], "Opening signals must reflect exactly one usable opportunity")
	guard.distract("bell")
	_expect(_wait_for(guard, "investigate"), "A second bell still needs to create a usable chance")
	var second_window: float = guard.remaining_open_time()
	_expect(second_window < first_window and second_window >= 3.8, "A repeated trick should shorten, never eliminate, the opportunity")
	_wait_for(guard, "watch")
	guard.distract("flower")
	_wait_for(guard, "investigate")
	_expect(guard.remaining_open_time() >= 5.9, "Trying a different distraction must recover the full curious response")
	for repetition in 5:
		_wait_for(guard, "watch")
		guard.distract("bell")
		_wait_for(guard, "investigate")
		_expect(guard.remaining_open_time() >= 3.8, "Even a repeatedly reused trick must retain a fair minimum opportunity")
	guard.reset_state()
	_expect(not guard.can_cross() and guard.position == Vector2(945.0, 420.0), "Retry must restore the original bridge and close any stale opening")
	guard.distract("bell")
	_wait_for(guard, "investigate")
	_expect(guard.remaining_open_time() >= 5.9, "Retry must clear learned suspicion rather than punish repeated failures")
	guard.active = false
	var frozen_position: Vector2 = guard.position
	var frozen_time: float = guard.state_time
	_advance(guard, 2.0)
	_expect(guard.position == frozen_position and guard.state_time == frozen_time and not guard.can_cross(), "An inactive actor must freeze and cannot authorize crossing")
	_expect(not openings[-1], "Deactivation must close the published crossing opportunity")
	guard.free()
	if failures.is_empty():
		print("[CrowGuardSpec] PASS: readable opening, nonlethal notice, no command stacking, bounded learned suspicion, alternative tricks, fair retry and inactive freeze")
		quit(0)
	else:
		quit(1)

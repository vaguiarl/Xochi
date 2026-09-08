extends SceneTree
## Run with: godot --headless --path . --script tests/enemy_spec.gd
## Tests committed aim, readable delay, recovery, stomp, and the complete boss cycle.

class Target:
	extends CharacterBody2D
	var active := true
	var hits := 0
	func take_hit() -> void:
		hits += 1

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _tick(actor: Node2D, seconds: float) -> void:
	for frame in int(ceil(seconds * 60.0)):
		actor._physics_process(1.0 / 60.0)

func _until_state(actor: Node2D, desired: String, seconds: float) -> bool:
	for frame in int(ceil(seconds * 60.0)):
		if actor.state == desired:
			return true
		actor._physics_process(1.0 / 60.0)
	return actor.state == desired

func _run() -> void:
	var target := Target.new()
	root.add_child(target)
	target.position = Vector2(180.0, 555.0)
	var enemy_script = load("res://scripts/enemy.gd")
	var crow = enemy_script.new()
	root.add_child(crow)
	crow.configure("crow", Vector2(200.0, 360.0), target)
	crow.set_physics_process(false)
	_tick(crow, 0.70)
	_expect(crow.state == "tell", "Crow must give a visible tell before diving")
	var committed: Vector2 = crow.attack_to
	target.position.x = 430.0
	_tick(crow, 0.80)
	_expect(crow.state == "tell" and target.hits == 0, "Crow cannot hit during its one-second tell")
	_expect(crow.attack_to == committed, "Crow aim must not follow a player who dodges after the tell")
	_tick(crow, 0.80)
	_expect(crow.state == "recover", "Crow must recover after its committed dive")
	_expect(target.hits == 0, "Moving out of the marked crow destination must avoid the attack")
	crow.reset_state()
	_expect(crow.position == Vector2(200.0, 360.0) and crow.state == "idle", "Crow reset must restore its origin and idle delay")
	target.position = Vector2(200.0, 347.0)
	target.velocity = Vector2(0.0, 150.0)
	crow._check_stomp()
	_expect(crow.state == "stunned" and target.velocity.y < -300.0, "A descending stomp must stun and bounce")

	var jaguar = enemy_script.new()
	root.add_child(jaguar)
	target.position = Vector2(580.0, 555.0)
	target.velocity = Vector2.ZERO
	jaguar.configure("jaguar", Vector2(700.0, 555.0), target)
	jaguar.set_physics_process(false)
	_tick(jaguar, 0.75)
	_expect(jaguar.state == "tell", "Jaguar must crouch before pouncing")
	committed = jaguar.attack_to
	target.position = Vector2(900.0, 555.0)
	_tick(jaguar, 1.65)
	_expect(jaguar.attack_to == committed and jaguar.state == "recover", "Jaguar must commit its pounce and give a long recovery")
	_expect(target.hits == 0, "Dodging a jaguar tell must avoid damage")
	jaguar.receive_ripple(jaguar.position - Vector2(40.0, 0.0), 1.0)
	_expect(jaguar.state == "stunned", "Ripple must stun a jaguar in range")
	jaguar.reset_state()
	_expect(jaguar.position == Vector2(700.0, 555.0) and jaguar.state == "idle", "Jaguar reset must erase attack and stun state")
	var neighbor = enemy_script.new()
	root.add_child(neighbor)
	neighbor.configure("crow", Vector2(820.0, 360.0), target)
	neighbor.set_physics_process(false)
	neighbor.state = "tell"
	_expect(not jaguar._can_commit(), "Nearby enemies must take turns committing attacks over narrow boats")
	neighbor.state = "recover"
	_expect(jaguar._can_commit(), "A recovering neighbor must permit the next enemy's readable tell")
	neighbor.free()

	var boss = load("res://scripts/boss.gd").new()
	root.add_child(boss)
	target.position = Vector2(4500.0, 555.0)
	boss.configure(Vector2(4790.0, 555.0), target)
	boss.set_physics_process(false)
	var wins := [0]
	boss.defeated.connect(func(): wins[0] += 1)
	boss.receive_ripple(boss.position - Vector2(50.0, 0.0), 1.0)
	_expect(boss.hp == 3, "Protected boss must ignore Ripple")
	_tick(boss, 1.25)
	_expect(boss.state == "tell" and boss.attack_kind == "leap", "First boss attack must teach the marked leap")
	committed = boss.attack_to
	target.position.x = 4950.0
	_tick(boss, 0.95)
	_expect(boss.state == "tell" and boss.attack_to == committed, "Boss must preserve its visible committed destination")
	_tick(boss, 0.95)
	_expect(boss.state == "exposed", "Boss leap must end with a Ripple window")
	_expect(target.hits == 0, "Dodging the marked boss leap must avoid damage")
	for comfort in 3:
		if comfort > 0:
			# Stay nearby for a wave pattern, then jump its visibly low ring.
			target.position = boss.position + Vector2(140.0, 0.0)
			_tick(boss, 2.15)
			_expect(boss.state == "tell", "Each comfort must lead to another readable attack")
			target.position.y = 430.0
			_tick(boss, 1.1)
			_expect(_until_state(boss, "exposed", 3.0), "Boss attacks must always finish in an exposed window")
			_tick(boss, 1.0)
			_expect(boss.state == "exposed", "A recovery must last long enough to approach and hold Ripple")
			target.position.y = 555.0
		boss.receive_ripple(boss.position - Vector2(50.0, 0.0), 1.0)
		_expect(boss.hp == 2 - comfort, "A valid exposed Ripple must remove exactly one worry knot")
		boss.receive_ripple(boss.position - Vector2(50.0, 0.0), 1.0)
		_expect(boss.hp == 2 - comfort, "A held Ripple cannot consume multiple boss hits in one opening")
	_expect(boss.state == "defeated" and wins[0] == 1, "Three openings must finish the boss exactly once")
	boss.reset_state()
	_expect(boss.hp == 3 and boss.state == "idle" and boss.position == Vector2(4790.0, 555.0), "Boss checkpoint reset must restore the full learnable encounter")

	crow.free()
	jaguar.free()
	boss.free()
	target.free()
	if failures.is_empty():
		print("[EnemySpec] PASS: committed aim, tells, safe dodges, stomp, Ripple, deterministic reset, complete three-hit boss")
		quit(0)
	else:
		print("[EnemySpec] FAIL: ", failures)
		quit(1)

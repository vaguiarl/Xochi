extends Node
class_name CombatSystem
## Manages all combat interactions in Xochi: stomp detection, melee attacks,
## thunderbolt projectiles, and enemy projectile updates.
##
## Attached as a child of the GameScene. Call setup() after the scene is ready
## to wire up references to the player and enemies container node.
##
## Stomp detection logic is an exact port from the original hitEnemy function
## (game.js lines 5818-5849):
##   - Player must be falling (velocity.y > 0)
##   - Player must not be on the floor
##   - Player bottom must overlap enemy top within a vertical tolerance
##   - Player center must be within 40 px horizontally of enemy center
##
## Required autoloads: Events, GameState, AudioManager


# =============================================================================
# REFERENCES
# =============================================================================

## The root game scene node (used for spawning floating text + projectiles).
var game_scene: Node2D

## The player CharacterBody2D.
var player: CharacterBody2D

## The container node holding all enemy instances.
var enemies_node: Node2D

## Active projectiles (thunderbolts and enemy shots) managed by this system.
var projectiles: Array = []


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready():
	# Connect to attack signals from the player
	Events.player_attacked.connect(_on_player_attacked)
	Events.thunderbolt_fired.connect(_on_thunderbolt_fired)


## Wire up references after the game scene is fully initialized.
## Must be called before the first _physics_process tick.
func setup(scene: Node2D, p: CharacterBody2D, e: Node2D):
	game_scene = scene
	player = p
	enemies_node = e


func _physics_process(delta):
	if player == null or not is_instance_valid(player):
		return

	_check_stomp()
	_update_projectiles(delta)
	_update_boss_projectiles(delta)


# =============================================================================
# STOMP DETECTION (from original hitEnemy, lines 5818-5849)
# =============================================================================

func _check_stomp():
	## Player must be falling to stomp
	if player.velocity.y <= 0:
		return
	if player.is_on_floor():
		return

	for enemy in enemies_node.get_children():
		# Support both EnemyBase and Ahuizotl (duck typing via has_method)
		if not enemy.has_method("hit_by_stomp"):
			continue
		if not enemy.get("alive"):
			continue

		# Check vertical overlap: player bottom near enemy top
		var player_bottom = player.global_position.y + 25  # Half collision height
		var enemy_top = enemy.global_position.y - 15

		# Check horizontal overlap: within 40 px
		var x_overlap = abs(player.global_position.x - enemy.global_position.x) < 40

		if player_bottom >= enemy_top and player_bottom <= enemy_top + 30 and x_overlap:
			# STOMP!
			enemy.hit_by_stomp()
			player.stomp_bounce()  # -250 velocity.y
			_show_floating_text(enemy.global_position, "+100", Color.WHITE)
			return  # Only stomp one enemy per frame

	# -- Also check boss group (boss is added to scene root, not enemies_node) --
	for boss in get_tree().get_nodes_in_group("boss"):
		if not boss.has_method("hit_by_stomp"):
			continue
		if boss.get("state") == "DEAD":
			continue

		var player_bottom = player.global_position.y + 25
		var boss_top = boss.global_position.y - 25  # Boss is taller

		var x_overlap = abs(player.global_position.x - boss.global_position.x) < 40

		if player_bottom >= boss_top and player_bottom <= boss_top + 30 and x_overlap:
			boss.hit_by_stomp()
			player.stomp_bounce()
			_show_floating_text(boss.global_position, "STOMPED!", Color.YELLOW)
			return


# =============================================================================
# MELEE ATTACK
# =============================================================================

func _on_player_attacked(attack_pos: Vector2, attack_dir: int):
	## Check all enemies within 70 px melee range
	for enemy in enemies_node.get_children():
		if not enemy.has_method("hit_by_attack"):
			continue
		if not enemy.get("alive"):
			continue

		if attack_pos.distance_to(enemy.global_position) < 70:
			enemy.hit_by_attack()
			_show_floating_text(enemy.global_position, "+100", Color.WHITE)

	# -- Also check boss group (boss uses hit_by_melee, only works in RECOVER) --
	for boss in get_tree().get_nodes_in_group("boss"):
		if not boss.has_method("hit_by_melee"):
			continue
		if boss.get("state") == "DEAD":
			continue

		if attack_pos.distance_to(boss.global_position) < 70:
			boss.hit_by_melee()
			if boss.get("state") == "RECOVER":
				_show_floating_text(boss.global_position, "MELEE HIT!", Color.YELLOW)


# =============================================================================
# THUNDERBOLT PROJECTILE
# =============================================================================

func _on_thunderbolt_fired(from_pos: Vector2, attack_dir: int):
	## Create thunderbolt: yellow bolt, 400 px/s, hits 1 enemy, expires 1.5 s
	var bolt = Area2D.new()
	bolt.position = from_pos
	bolt.collision_layer = 4  # Player layer
	bolt.collision_mask = 8   # Hits enemies

	# Collision shape -- horizontal rectangle for the bolt
	var shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(12, 6)
	shape.shape = rect_shape
	bolt.add_child(shape)

	# Visual -- yellow rectangle (placeholder until art is ready)
	var visual = ColorRect.new()
	visual.size = Vector2(12, 6)
	visual.position = Vector2(-6, -3)
	visual.color = Color(1.0, 1.0, 0.0)  # Bright yellow
	bolt.add_child(visual)

	# Store movement data in metadata
	bolt.set_meta("velocity_x", attack_dir * 400.0)
	bolt.set_meta("lifetime", 1.5)
	bolt.set_meta("alive", true)

	game_scene.add_child(bolt)
	projectiles.append(bolt)

	# Connect for enemy hit detection
	bolt.body_entered.connect(func(body):
		if body.has_method("hit_by_attack") and body.get("alive") and bolt.get_meta("alive"):
			bolt.set_meta("alive", false)
			body.hit_by_attack()
			_show_floating_text(body.global_position, "+100 THUNDER!", Color.YELLOW)
			bolt.queue_free()
	)


# =============================================================================
# PROJECTILE UPDATE LOOP
# =============================================================================

func _update_projectiles(delta):
	var to_remove = []

	for proj in projectiles:
		if not is_instance_valid(proj):
			to_remove.append(proj)
			continue

		# Move projectile -- supports both thunderbolts (velocity_x) and
		# enemy projectiles (velocity Vector2)
		var vel_x = proj.get_meta("velocity_x", 0.0)
		var vel = proj.get_meta("velocity", Vector2.ZERO)

		if vel != Vector2.ZERO:
			proj.position += vel * delta
		else:
			proj.position.x += vel_x * delta

		# Tick down lifetime
		var lifetime = proj.get_meta("lifetime", 0.0) - delta
		proj.set_meta("lifetime", lifetime)

		if lifetime <= 0:
			proj.queue_free()
			to_remove.append(proj)

	# Clean up expired/destroyed projectiles
	for proj in to_remove:
		projectiles.erase(proj)


# =============================================================================
# BOSS PROJECTILE UPDATE (shadow bolts, dark rain)
# =============================================================================

func _update_boss_projectiles(delta):
	## Moves boss projectiles and checks for player collision.
	## Boss projectiles are Node2D children of game_scene with "is_boss_projectile" meta.
	if game_scene == null or not is_instance_valid(game_scene):
		return

	var to_remove: Array = []
	for child in game_scene.get_children():
		if not is_instance_valid(child):
			continue
		if not child.has_meta("is_boss_projectile"):
			continue

		# Move
		var vel: Vector2 = child.get_meta("velocity", Vector2.ZERO)
		if vel != Vector2.ZERO:
			child.position += vel * delta

		# Tick lifetime
		var lifetime: float = child.get_meta("lifetime", 0.0) - delta
		child.set_meta("lifetime", lifetime)

		if lifetime <= 0:
			to_remove.append(child)
			continue

		# Check player collision (distance-based, 20px radius)
		if player != null and is_instance_valid(player):
			if child.global_position.distance_to(player.global_position) < 20.0:
				player.hit(1)
				to_remove.append(child)
				# Particle burst on hit
				_spawn_bolt_hit_particles(child.global_position)
				continue

	for proj in to_remove:
		if is_instance_valid(proj):
			proj.queue_free()


func _spawn_bolt_hit_particles(pos: Vector2):
	## Small magenta particle burst when a boss projectile hits the player.
	if game_scene == null:
		return
	for i in 6:
		var p = ColorRect.new()
		p.size = Vector2(4, 4)
		p.position = pos + Vector2(-2, -2)
		p.color = Color(0.8, 0.0, 0.6)
		p.z_index = 80
		game_scene.add_child(p)

		var angle: float = float(i) / 6.0 * TAU
		var end: Vector2 = p.position + Vector2(cos(angle), sin(angle)) * 30.0
		var tween = game_scene.create_tween()
		tween.set_parallel(true)
		tween.tween_property(p, "position", end, 0.3)
		tween.tween_property(p, "modulate:a", 0.0, 0.3)
		tween.chain().tween_callback(p.queue_free)


# =============================================================================
# FLOATING SCORE TEXT
# =============================================================================

func _show_floating_text(pos: Vector2, text: String, color: Color):
	var label = Label.new()
	label.text = text
	label.position = pos - Vector2(20, 30)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.z_index = 100
	game_scene.add_child(label)

	# Float upward and fade out over 0.8 seconds
	var tween = game_scene.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 80, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)

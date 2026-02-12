extends CharacterBody2D
class_name EnemyBase
## Base class for all Xochi enemies.
##
## Provides shared state (alive, direction, speed, gravity) and common death
## responses (stomp, melee/thunderbolt attack, generic die). Every concrete
## enemy (Gull, Heron, etc.) extends this and overrides _physics_process for
## its specific patrol/movement behaviour.
##
## Collision setup:
##   - Layer 8 (enemy layer, bit 4)
##   - Mask 1 | 2 (World + Platforms)
##
## Required autoloads: Events, GameState, AudioManager


# =============================================================================
# STATE
# =============================================================================

## Whether this enemy is alive and can interact with the player.
var alive: bool = true

## Enemy movement archetype: "ground", "flying", or "platform".
var enemy_type: String = "ground"

## Current movement direction: 1 = right, -1 = left.
var dir: int = 1

## Horizontal movement speed in px/s.
var speed: float = 60.0

## Gravity in px/s^2. Overridden to 0 for flying enemies.
var gravity: float = 900.0


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready():
	collision_layer = 8   # Enemies layer (layer 4, bit value 8)
	collision_mask = 1 | 2  # Collide with World (1) + Platforms (2)


# =============================================================================
# DAMAGE RESPONSES
# =============================================================================

## Called when the player stomps on this enemy (falling from above).
## Grays out, freezes, awards 100 points, and destroys after 300 ms.
func hit_by_stomp():
	if not alive:
		return
	alive = false

	# Gray tint, stop all movement, disable physics processing
	modulate = Color(0.53, 0.53, 0.53)
	velocity = Vector2.ZERO
	set_physics_process(false)

	# Score
	GameState.score += 100
	Events.score_changed.emit(GameState.score)

	# SFX
	AudioManager.play_sfx("stomp")

	# Destroy after 300 ms
	await get_tree().create_timer(0.3).timeout
	queue_free()


## Called when the player's melee attack or thunderbolt hits this enemy.
## Knocks back, tints red, awards 100 points, and destroys after 500 ms.
func hit_by_attack():
	if not alive:
		return
	alive = false

	# Knock the corpse away from its facing direction
	velocity = Vector2(dir * -200, -200)
	modulate = Color(1, 0.5, 0.5)
	set_physics_process(false)

	# Score
	GameState.score += 100
	Events.score_changed.emit(GameState.score)

	# SFX
	AudioManager.play_sfx("stomp")

	# Destroy after 500 ms
	await get_tree().create_timer(0.5).timeout
	queue_free()


## Generic instant death -- no animation, no score. Used for despawning
## enemies that fall off the map or are cleaned up between levels.
func die():
	if not alive:
		return
	alive = false
	queue_free()

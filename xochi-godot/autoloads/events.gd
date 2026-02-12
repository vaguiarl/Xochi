extends Node
## Global signal bus for decoupled communication between game systems.
## All cross-system signals go through here so nodes never need direct references
## to each other. This is the backbone of Xochi's event-driven architecture.

# Collectibles
signal flower_collected(count)
signal elote_collected(level, index)

# Baby rescue
signal baby_rescued(level)

# Player state
signal player_hit
signal player_died
signal life_lost
signal super_jump_used
signal super_jump_gained
signal mace_attack_used

# Player attacks
signal player_attacked(position: Vector2, direction: int)
signal thunderbolt_fired(position: Vector2, direction: int)

# Boss encounters
signal boss_damaged(health, max_health)
signal boss_defeated

# Level progression
signal level_completed(level_num)

# Score
signal score_changed(score)

# Luchador power-up
signal luchador_activated
signal luchador_ended

# Game end states
signal game_over
signal game_won

# Pause/resume
signal game_paused
signal game_resumed

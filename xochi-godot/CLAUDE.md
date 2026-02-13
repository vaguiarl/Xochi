# Xochi - Godot 4 Rebuild

## Project Context
Xochi is a 2D platformer inspired by DKC, set in Mesoamerican mythology. The player controls a warrior navigating through 11 levels across 6 worlds, fighting enemies, collecting cempasuchil flowers, and rescuing baby axolotls.

Rebuilt from the original JavaScript/Phaser web version (`xochi-web/game.js`, 7,883 lines) into Godot 4 with GDScript.

## Tech Stack
- Godot 4.3+ with GDScript (no TypeScript, no C#)
- CharacterBody2D for player and enemies
- Autoloads: GameState, AudioManager, Events, SceneManager, ViewportManager
- Procedural visuals via ColorRect rigs (no external sprites for enemies yet)
- Player uses PNG sprite sheets (`assets/sprites/xochi_walk.png` etc.)

## Architecture
```
scenes/          - .tscn + .gd scene files (menu, game, story, pause, end, ui)
scripts/entities/ - Player, Gull, Crowquistador, Heron, Boss, Ahuizotl
scripts/systems/  - CombatSystem, WaterSystem, EnemySpawner, LuchadorSystem
scripts/levels/   - LevelData (11 levels, 6 worlds, generators)
autoloads/        - GameState, AudioManager, Events, SceneManager, ViewportManager
assets/           - sprites/, audio/music/, audio/sfx/, fonts/
```

## Key Patterns
- Systems follow: setup(scene, player, enemies), _physics_process(delta), destroy
- Enemy combat uses duck typing: `has_method("hit_by_stomp")` and `.get("alive")`
- **ALL enemies** must be dynamically loaded in EnemySpawner via `load()` + null check + `continue`
- **NEVER** use `class_name` on enemy entity scripts — only EnemyBase, Player, DarkXochi, and system scripts may have class_name
- **NEVER** use `preload()` anywhere — all resource loading must use runtime `load()`
- Delete `.godot/global_script_class_cache.cfg` after removing class_name from any script
- Level routing: `LevelData.get_level_data(level_num)` handles static vs generated levels
- Levels 1-6 static, 7+9 escape generator, 8 upscroller generator, 10 boss arena, 11 fiesta
- Music per world (not per level) — AudioManager checks `current_track` to avoid restarts

## General Rules
- **Action over reporting**: Start doing the work immediately, don't summarize state first
- **Real data only**: Never generate fake/placeholder data unless explicitly asked
- **Test incrementally**: After each change, verify it doesn't break existing functionality
- **Port, don't redesign**: Copy the original game.js design decisions exactly
- **Soul first, polish second**: Get game feel right before visual effects

## Gotchas
- **class_name cascade**: `.godot/global_script_class_cache.cfg` caches class_names. If a stale entry points to a script that no longer declares class_name, Godot cascades ALL enemies. Fix: delete the cache file.
- Camera2D: use `get_screen_center_position()` NOT `get_screen_center_of_mass()` (doesn't exist in Godot 4)
- PauseScene references `gameScene.musicManager.currentMusic` for pause/resume
- Crowquistador/Heron boundary fix: check direction before reversing (not `dir *= -1`)
- Water starts at `level_height - 20` not `+ 50` to be visible from the start

## Environment
- macOS (Darwin)
- Godot editor for visual testing — Claude cannot run Godot directly
- Assets from xochi-web can be copied over (sprites, audio)

# Adjust Enemy Type

Safely modify a single enemy type (size, speed, AI, visuals) with isolation guarantees.

## Input
$ARGUMENTS

Argument format: `<enemy_type> <adjustment_description>`
- enemy_type: gull, crowquistador, heron, rabbitbrije, calaca, ahuizotl, jaguar
- adjustment_description: What to change (e.g., "half size", "faster patrol", "new AI state")

Example: `crowquistador half size and faster dive speed`

## Pre-Flight Safety Checks

Before making ANY changes, verify:

### 1. Isolation Check
- Confirm the target script has NO `class_name` declaration
- Confirm EnemySpawner uses `load()` (not static reference) for this enemy
- If either check fails, FIX the isolation issue FIRST before proceeding

### 2. Backup State
- Note the current git hash with `git rev-parse --short HEAD`
- Read the full target script file before modifying

### 3. Dependency Map
File locations by enemy type:
- **gull**: `scripts/entities/gull.gd` (extends EnemyBase)
- **crowquistador**: `scripts/entities/crowquistador.gd` (extends EnemyBase)
- **heron**: `scripts/entities/heron.gd` (extends EnemyBase)
- **rabbitbrije**: `scripts/entities/rabbitbrije.gd` (extends CharacterBody2D, standalone)
- **calaca**: `scripts/entities/calaca.gd` (extends CharacterBody2D, standalone)
- **ahuizotl**: `scripts/entities/ahuizotl.gd` (extends CharacterBody2D, standalone)
- **jaguar**: `scripts/entities/jaguar_warrior.gd` (extends CharacterBody2D, standalone)

## Adjustment Categories

### Size Changes
- Find the visual scale (look for `rig_scale`, `scale_factor`, `TARGET_HEIGHT`, or `rig.scale`)
- Find the collision shape size (look for `RectangleShape2D`, `shape.size`)
- Adjust both proportionally (visual AND collision must match)
- For skeletal rigs (crowquistador): adjust `rig.scale` and collision `shape.size`
- For sprite-based (rabbitbrije, calaca): adjust `TARGET_HEIGHT` constant and collision

### Speed Changes
- Find speed constants (look for `speed`, `PATROL_SPEED`, `DIVE_SPEED`, etc.)
- Adjust specific speeds, not just the base speed
- For AI enemies: consider how speed affects state transitions and timing

### AI Changes
- Read the FULL script first to understand the state machine
- Add new states to the existing enum (don't replace)
- Add state handler functions following the `_process_<state>()` pattern
- Wire transitions in the match statement inside `_physics_process()`
- Keep the duck-typing combat API intact: `alive`, `hit_by_stomp()`, `hit_by_attack()`, `die()`, `setup()`

### Visual Changes
- For skeletal rigs: modify sprite positions/rotations in the `_build_skeletal_rig()` or `_animate_*()` functions
- For sprite-based: modify the sprite loading or scale in `_build_sprite()` or `_ready()`
- Use `load()` for any new textures (never `preload()`)

## Critical Rules

1. **NEVER add `class_name`** to the enemy script
2. **NEVER use `preload()`** - always use runtime `load()`
3. **NEVER modify EnemySpawner** unless adding a new type (existing types are already wired)
4. **NEVER modify EnemyBase** for enemy-specific behavior (override in the enemy script)
5. **Preserve the `setup()` signature** - always accept `data: Dictionary`
6. **Preserve combat API** - `hit_by_stomp()`, `hit_by_attack()`, `die()` must exist
7. **Test incrementally** - make one category of change at a time

## Verification

After changes:
- Confirm the script has NO `class_name` declaration
- Confirm no `preload()` calls exist in the modified file
- Confirm the `setup()`, `hit_by_stomp()`, `hit_by_attack()` methods still exist
- Confirm the `.godot/global_script_class_cache.cfg` does NOT contain the enemy type name as a class
- Read the modified file and verify GDScript syntax

## Rollback

If something breaks:
- Only the modified enemy type should be affected (isolation guarantee)
- Other enemies continue working via EnemySpawner's `load()` + null check + `continue`
- To fully rollback: `git checkout -- scripts/entities/<enemy_name>.gd`

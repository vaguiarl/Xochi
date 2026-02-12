# Audit Xochi Game Code

Run a comprehensive code audit across the Xochi Godot project to catch bugs, missing references, and regressions.

## Input
$ARGUMENTS

## Audit Checklist

### 1. Parse Safety
- Read every .gd file and check for obvious syntax issues
- Verify all `class_name` declarations match their file names
- Check that all `preload()`/`load()` paths point to existing files
- Verify no circular dependencies between scripts

### 2. Signal Wiring
- List all signals defined in `Events.gd` autoload
- For each signal, find all `.connect()` calls and `.emit()` calls
- Flag signals that are emitted but never connected (dead signals)
- Flag signals that are connected but never emitted (dangling listeners)

### 3. Level Data Integrity
- Verify levels 1-11 all have valid data in `level_data.gd`
- Check every level has: platforms, enemies, collectibles, trajineras (where appropriate)
- Verify enemy types match spawner capabilities ("ground", "flying", "platform", "water")
- Check coordinate ranges make sense (no enemies placed outside level bounds)
- Verify baby axolotl placement exists for each level

### 4. Scene Flow
- Trace the full game flow: main → menu → story → game → pause → end
- Verify all `change_scene_to_file()` paths point to existing .tscn files
- Check that GameState.current_level is set correctly before scene transitions
- Verify no references to `test_level.tscn` in production paths

### 5. Combat System
- Verify all enemy types implement required methods: `hit_by_stomp()`, `hit_by_attack()`, `die()`
- Check all enemies have an `alive` property
- Verify stomp detection tolerances are reasonable
- Check projectile cleanup (no leaked nodes)

### 6. Audio Mapping
- Verify every world (1-6) maps to a music track
- Verify special levels (boss, fiesta) have correct overrides
- Check all SFX references point to existing audio files
- Verify music continuity: same world = same track without restart

### 7. Common Regressions
- Check for `dir *= -1` boundary bugs (should use directional checks)
- Check for static class references to non-core entities (should use dynamic load)
- Check for hardcoded `test_level` or `SHOW_MENU_ON_START = false`
- Verify duck typing is used for combat checks (not `is EnemyBase`)

## Output
Produce a categorized report:
- **CRITICAL**: Bugs that will crash the game or break gameplay
- **WARNING**: Issues that may cause subtle problems
- **INFO**: Style issues or minor improvements
- **PASS**: Areas that checked out clean

Include file paths and line numbers for every finding.

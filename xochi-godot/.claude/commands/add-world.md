# Add New World to Xochi

Add a complete new world with levels, music, enemies, and visual theming.

## Input
$ARGUMENTS

## Steps

### 1. Plan the World
- Determine the world number and which levels it contains
- Reference the world structure: World 1 (L1-2), World 2 (L3-4), World 3 (L5), World 4 (L6-7), World 5 (L8-10), World 6 (L11)
- Define the theme: name, subtitle, color palette, atmosphere
- Determine level types: side-scroller, upscroller, escape, boss, or fiesta

### 2. Define Level Data
- Add level entries to `scripts/levels/level_data.gd`
- Each level needs: platforms[], enemies[], collectibles[], trajineras[], baby_axolotl position
- Follow existing density patterns: intro breathing zone (300px), dense middle, outro
- Trajineras: 4-6 per lane section, alternating directions, proper speeds

### 3. Wire Music
- Add music track mapping in `autoloads/audio_manager.gd` `play_for_world()`
- Verify the audio file exists in `assets/audio/music/`
- Ensure music continuity between levels in the same world

### 4. Update World Data
- Add world entry to `GameState.WORLDS` dictionary
- Include: name, subtitle, color, levels array, unlock_condition
- Update `get_first_level_of_world()` if needed

### 5. Visual Theming
- Update parallax layer colors in `game_scene.gd` for the new world
- Add atmosphere particles matching the theme (mist, leaves, fireflies, etc.)
- Set platform decoration style per world

### 6. Menu Integration
- Verify the world appears in the world selector (menu_scene.gd)
- Add tooltip text for the new world
- Set unlock condition (previous world's boss defeated)

### 7. Test Navigation
- Verify: menu → select world → loads correct level
- Verify: complete last level of previous world → transitions to new world
- Verify: music plays correctly and doesn't restart between levels
- Verify: all enemies spawn and are combat-compatible
- Verify: baby axolotl rescue completes each level

## Important
- Match the original game.js level design philosophy: breathing zones between dense sections
- Every level needs at least 1 baby axolotl, coins, and enemies
- Boss worlds (World 3, 5) have different structure — single boss arena level

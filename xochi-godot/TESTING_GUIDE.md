# Xochi Godot - Testing Guide

## Quick Start Testing

### 1. Enable Menu on Startup

Edit `scenes/main/main.gd` line 9:
```gdscript
const SHOW_MENU_ON_START: bool = true  # Change from false
```

### 2. Run the Game

```bash
cd /Users/victoraguiar/Documents/GitHub/Xochi/xochi-godot
godot --path . scenes/main/main.tscn
```

Or open the project in Godot Editor and press F5.

---

## Test Scenarios

### 🎮 Menu Testing

**Expected behavior:**
- Background: 6-color gradient with twinkling stars
- Animated "XOCHI" title with pulse
- Character preview bobbing up/down
- Scoreboard shows current stats
- Difficulty selector works (Easy/Medium/Hard)
- World selector shows 6 worlds
- PLAY button starts game
- NEW GAME resets progress
- CONTROLS button shows overlay

**Test actions:**
1. Click PLAY → Should load GameScene at current level
2. Click NEW GAME → Should reset to Level 1
3. Click CONTROLS → Overlay appears, ESC closes it
4. Click difficulty → Scoreboard updates
5. Hover world buttons → Tooltip appears
6. Press X or SPACE → Game starts

---

### 🎯 GameScene Testing

**Expected behavior:**
- Level loads with platforms, trajineras, collectibles
- Player responds to keyboard/touch input
- Camera follows player with zoom
- HUD shows score, lives, super jumps, etc.
- Music plays for current world

**Test actions:**
1. Move with A/D or arrows
2. Jump with X
3. Attack with Z
4. Press ESC → Pause menu appears
5. Collect flowers → Score increases
6. Rescue baby → Level completes

---

### ⏸️ Pause Testing

**Expected behavior:**
- Semi-transparent overlay
- Game frozen behind overlay
- Music paused
- Can toggle music/SFX settings
- Resume continues game

**Test actions:**
1. In GameScene, press ESC
2. Click RESUME → Game continues, music resumes
3. Click RESTART → Level reloads
4. Toggle MUSIC → Setting persists
5. Toggle SFX → Setting persists
6. Click QUIT → Returns to menu
7. Press ESC → Resumes game

---

### 📖 Story Testing

**Expected behavior:**
- Typewriter text effect
- Spanish subtitles
- Sparkles around edges
- Auto-advance after full text
- Can skip with SPACE

**Test actions:**
1. From menu, if starting new game, should show intro
2. Press SPACE repeatedly to advance slides
3. After final slide, should transition to GameScene
4. Complete World 1 → Story slide should appear between worlds

---

### 🏆 Victory Testing

**Expected behavior:**
- "CONGRATULATIONS!" title
- Baby parade animation
- Stats display (score, stars, babies)
- Confetti falling
- Finale music playing
- PLAY AGAIN resets game
- MAIN MENU returns to menu

**Test actions:**
1. Complete all 10 levels (or use cheat: set GameState.current_level = 11)
2. Click PLAY AGAIN → Resets to Level 1, shows intro
3. Click MAIN MENU → Returns to menu

---

## Touch Controls Testing (Mobile/Tablet)

### Gestures to Test:

1. **Horizontal Swipe** → Player walks with momentum
2. **Double Swipe** (same direction < 400ms) → Player sprints
3. **Swipe Up** → Player jumps with directional trajectory
4. **Tap** (quick touch < 200ms) → Super jump (if available)
5. **Hold** (400ms no movement) → Mace attack

### UI to Test:

1. **Pause button** (top-right circle) → Shows pause menu
2. **Menu buttons** → All buttons should be touch-friendly (40x40px minimum)
3. **Orientation** → Rotate device, UI should adapt

---

## Performance Testing

### Target Framerates:
- Desktop: 60 FPS
- Mobile: 30-60 FPS (depends on device)

### Check for:
- [ ] Smooth animations (no stuttering)
- [ ] Responsive controls (no input lag)
- [ ] Fast scene transitions
- [ ] No memory leaks (run for 5+ minutes)
- [ ] Particles don't slow down game

---

## Debug Console Commands

Open Godot's console (Output tab) to see debug messages:

```
[ViewportManager] Initialized. Size: (800, 600), Portrait: false
[TouchInputManager] Initialized for touch device
[GameScene] Touch controls initialized
[GameScene] Level 1 loaded
```

---

## Common Issues & Solutions

### Issue: Menu doesn't show on startup
**Solution:** Check `scenes/main/main.gd` line 9, set `SHOW_MENU_ON_START = true`

### Issue: No music playing
**Solution:** Check GameState.music_enabled is true, verify .ogg files exist in assets/audio/

### Issue: Touch controls not working
**Solution:** Verify DisplayServer.is_touchscreen_available() returns true, check TouchInputManager is instantiated

### Issue: Pause menu doesn't appear
**Solution:** Add pause handler in GameScene _input(), verify "pause_game" action exists in project.godot

### Issue: Level doesn't complete
**Solution:** Verify baby rescue triggers _complete_level(), check Events.level_completed signal

### Issue: UI too small/large on mobile
**Solution:** ViewportManager should auto-scale, verify it's initialized first in autoload order

---

## Cheat Codes (for testing)

Add to GameScene for quick testing:

```gdscript
func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_F1:  # Give super jumps
                GameState.super_jumps += 10
            KEY_F2:  # Give lives
                GameState.lives += 5
            KEY_F3:  # Skip to next level
                GameState.current_level += 1
                get_tree().reload_current_scene()
            KEY_F4:  # Unlock all worlds
                GameState.current_level = 10
            KEY_F5:  # Complete current level
                _complete_level()
```

---

## What to Look For

### ✅ Good Signs:
- Smooth 60 FPS gameplay
- Responsive controls (< 50ms input lag)
- Beautiful animated backgrounds
- Music playing without glitches
- UI scales properly on different resolutions
- Touch controls feel natural
- No console errors

### ⚠️ Warning Signs:
- Framerate drops below 30 FPS
- Input lag or unresponsive controls
- Missing sprites (pink placeholders)
- Music stuttering or not playing
- UI elements off-screen or overlapping
- Touch gestures not registering
- Console errors or warnings

---

## Reporting Issues

If you find bugs, note:
1. **What you were doing** (steps to reproduce)
2. **What happened** (actual behavior)
3. **What you expected** (expected behavior)
4. **Platform** (Desktop/Mobile, OS version)
5. **Console output** (any error messages)

Example:
> **Bug**: Pause menu doesn't close
> **Steps**: 1. Press ESC in game, 2. Click RESUME button
> **Expected**: Game resumes, pause menu disappears
> **Actual**: Menu stays visible, game still paused
> **Platform**: Desktop macOS 14.6
> **Console**: No errors

---

## Next Steps After Testing

1. ✅ Verify all 4 UI scenes work correctly
2. ✅ Test full game flow: Menu → Game → Victory
3. ✅ Test pause/resume functionality
4. ✅ Test touch controls on mobile device
5. ✅ Check responsive layout in portrait/landscape
6. 🔲 Replace placeholder sprites with real art
7. 🔲 Add save system (Phase 10)
8. 🔲 Polish animations and timing
9. 🔲 Add gamepad support
10. 🔲 Final QA pass

---

**Happy Testing!** 🎮

Report any issues you find and we'll fix them before moving to Phase 10 (Save System).

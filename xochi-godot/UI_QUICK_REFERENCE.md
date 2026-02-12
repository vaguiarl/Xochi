# UI Scenes Quick Reference

## How to Use Each Scene

### MenuScene
**Path:** `res://scenes/menu/menu_scene.tscn`

**Usage:**
```gdscript
# Set as main scene in project settings, or
SceneManager.change_scene("res://scenes/menu/menu_scene.tscn")
```

**What it does:**
- Entry point for the game
- Displays title, stats, difficulty selector
- Provides world selection
- Shows controls overlay

**Key Methods:**
- None (self-contained, no public API)

---

### PauseScene
**Path:** `res://scenes/pause/pause_scene.tscn`

**Usage:**
```gdscript
# In GameScene or any gameplay scene:
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("pause_game"):
        var pause_scene = preload("res://scenes/pause/pause_scene.tscn").instantiate()
        get_tree().root.add_child(pause_scene)
```

**What it does:**
- Overlays on top of game
- Pauses game tree
- Pauses music
- Provides resume/restart/quit options
- Toggle audio settings

**Important:**
- Has `process_mode = 3` (PROCESS_MODE_ALWAYS)
- Sets `get_tree().paused = true`
- Automatically resumes on RESUME or ESC

---

### StoryScene
**Path:** `res://scenes/story/story_scene.tscn`

**Usage:**
```gdscript
# Transition to story scene with parameters:
SceneManager.change_scene("res://scenes/story/story_scene.tscn")

# Then in the new scene instance, call init():
# (This will be handled by SceneManager in the future)
var story_scene = get_tree().current_scene
story_scene.init({
    "type": "intro",  # or "world2", "world3", etc.
    "next_level": 1
})
```

**Story Types:**
- `"intro"`: Opening story (6 slides)
- `"world2"`: World 2 transition (3 slides)
- `"world3"`: World 3 transition (3 slides)
- `"world4"`: World 4 transition (3 slides)
- `"world5"`: World 5 transition (3 slides)
- `"world6"`: World 6 transition (3 slides)
- `"ending"`: Victory ending (6 slides)

**What it does:**
- Shows narrative text with typewriter effect
- Displays Spanish subtitles
- Sparkle decorations
- Advances on SPACE or click
- Transitions to GameScene or EndScene when complete

---

### EndScene
**Path:** `res://scenes/end/end_scene.tscn`

**Usage:**
```gdscript
# When game is complete:
SceneManager.change_scene("res://scenes/end/end_scene.tscn")
```

**What it does:**
- Celebrates victory
- Shows baby axolotl parade
- Displays final stats
- Provides play again or return to menu options
- Plays finale music
- Shows confetti effects

---

## Scene Transition Flow

```
Game Start
    ↓
MenuScene (entry point)
    ↓ [PLAY/CONTINUE]
GameScene
    ↓ [ESC]
PauseScene (overlay)
    ↓ [RESUME]
GameScene
    ↓ [Level Complete - World Transition]
StoryScene (world transition)
    ↓
GameScene (next level)
    ↓ [All Levels Complete]
StoryScene (ending)
    ↓
EndScene
    ↓ [PLAY AGAIN]
StoryScene (intro)
    ↓
GameScene (level 1)
```

---

## Common UI Patterns

### Creating Buttons
All scenes use a similar button pattern:

```gdscript
func _create_button(pos: Vector2, size: Vector2, color: Color, text: String, callback: Callable) -> Button:
    # Background
    var bg := ColorRect.new()
    bg.color = color
    bg.position = pos - size / 2
    bg.size = size
    add_child(bg)

    # Text label
    var label := Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.position = pos - Vector2(size.x / 2, 10)
    add_child(label)

    # Interactive overlay
    var btn := Button.new()
    btn.flat = true
    btn.position = pos - size / 2
    btn.custom_minimum_size = size
    btn.pressed.connect(callback)
    btn.mouse_entered.connect(func(): btn.scale = Vector2(1.05, 1.05))
    btn.mouse_exited.connect(func(): btn.scale = Vector2.ONE)
    add_child(btn)

    return btn
```

### Responsive Positioning
All scenes use ViewportManager:

```gdscript
# Convert design coordinates (800x600) to viewport:
var screen_pos = ViewportManager.design_to_viewport(Vector2(400, 300))

# Get UI scale factor:
var ui_scale = ViewportManager.get_ui_scale()

# Scale font sizes:
label.add_theme_font_size_override("font_size", int(20 * ui_scale))

# Scale element sizes:
button.custom_minimum_size = Vector2(200, 50) * ui_scale
```

### Playing Audio
All scenes use AudioManager:

```gdscript
# Play background music:
AudioManager.play_music("music_menu")  # or "music_finale"

# Play sound effect:
AudioManager.play_sfx("menu_select")

# Stop music:
AudioManager.stop_music()

# Pause/resume music:
AudioManager.current_music.stream_paused = true
AudioManager.current_music.stream_paused = false
```

### Tween Animations
Common tween patterns:

```gdscript
# Simple property animation:
var tween = create_tween()
tween.tween_property(node, "position:y", target_y, 1.0)

# Looping animation:
var tween = create_tween()
tween.set_loops()
tween.tween_property(node, "scale", Vector2(1.1, 1.1), 1.0)
tween.tween_property(node, "scale", Vector2.ONE, 1.0)

# Parallel animations:
var tween = create_tween()
tween.tween_property(node, "position:y", target_y, 1.0)
tween.parallel().tween_property(node, "modulate:a", 0.0, 1.0)

# Callbacks:
var tween = create_tween()
tween.tween_property(node, "position:y", target_y, 1.0)
tween.tween_callback(func(): print("Animation complete!"))
```

---

## Color Reference

```gdscript
# Primary colors
const COLOR_CYAN = Color("4ecdc4")
const COLOR_PINK = Color("ff6b9d")
const COLOR_YELLOW = Color("ffe66d")
const COLOR_RED = Color("ff6b6b")

# UI colors
const COLOR_BG_DARK = Color("1a1a2e")
const COLOR_BG_MID = Color("2a2a4e")
const COLOR_TEXT_LIGHT = Color("ffffff")
const COLOR_TEXT_DIM = Color("888888")

# Button colors
const COLOR_BTN_PRIMARY = Color("4ecdc4")
const COLOR_BTN_SECONDARY = Color("ff6b9d")
const COLOR_BTN_WARNING = Color("ff6b6b")
const COLOR_BTN_SUCCESS = Color("44aa44")

# Difficulty colors
const COLOR_EASY = Color("44aa44")
const COLOR_MEDIUM = Color("aaaa44")
const COLOR_HARD = Color("aa4444")
```

---

## Keyboard Shortcuts

### MenuScene
- `X` or `SPACE`: Start game
- `ESC`: Close controls overlay

### PauseScene
- `ESC`: Resume game

### StoryScene
- `SPACE` or `Click`: Advance to next slide

### All Scenes
- Built-in Godot actions:
  - `ui_accept`: Confirm (Enter/Space)
  - `ui_cancel`: Cancel (ESC)
  - `jump`: Jump (X)
  - `pause_game`: Pause (ESC)

---

## Debugging Tips

### Scene not loading?
Check:
1. Scene path is correct (case-sensitive)
2. Scene file (.tscn) exists
3. Script (.gd) is attached to root node
4. No syntax errors in script

### UI not visible?
Check:
1. ViewportManager is loaded (autoload)
2. Control node has proper anchors/size
3. z_index is not negative (unless intentional)
4. Node is added as child of scene root

### Buttons not clickable?
Check:
1. Button has `mouse_filter = MOUSE_FILTER_STOP` (default)
2. Button is not behind another node
3. Button size is large enough (min 40x40)
4. Scene is not paused (unless process_mode allows)

### Tweens not working?
Check:
1. Node is in scene tree before creating tween
2. Tween target exists and is valid
3. Property path is correct (e.g., "position:y" not "position.y")
4. Duration is > 0

---

## Performance Tips

1. **Limit particle count**: 30 stars, 12 particles, 50 confetti max
2. **Use ColorRect for simple shapes**: Faster than Sprite2D for solid colors
3. **Cache viewport calculations**: Don't call `design_to_viewport()` in `_process()`
4. **Reuse nodes**: Don't create/destroy nodes every frame
5. **Set tween delays**: Stagger animations to avoid all starting at once
6. **Use `one_shot` timers**: For typewriter effect, not polling in `_process()`

---

## Future Improvements

### Easy Wins
- [ ] Add gamepad navigation support
- [ ] Add button sound variations (different pitch/volume)
- [ ] Add fade-in animations on scene load
- [ ] Add keyboard focus indicators

### Medium Effort
- [ ] Replace placeholder sprites with actual artwork
- [ ] Add particle trails to cursor
- [ ] Add blur shader to PauseScene background
- [ ] Add volume sliders for music/sfx

### Advanced
- [ ] Add localization for multiple languages
- [ ] Add accessibility features (screen reader, high contrast)
- [ ] Add custom shaders for effects
- [ ] Add achievements system integration

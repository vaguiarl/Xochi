# Integrate Sprite Asset

Process and integrate a new sprite asset into the Xochi Godot project. Handles green screen removal, watermark cleanup, scaling, and wiring into GDScript.

## Input
$ARGUMENTS

The argument should be a path to the source PNG/JPG image, optionally followed by:
- Entity name (e.g., "rabbitbrije", "jaguarbrije")
- Entity type: "enemy", "player", "environment", "ui"
- Destination subfolder override

Example: `/path/to/sprite.png rabbitbrije enemy`

## Steps

### 1. Locate and analyze the source file

Find the raw sprite image at the path provided. If it's a directory, process all PNG/JPG files in it. Read the image to check:
- Dimensions and orientation
- Whether it has a green screen / solid color background
- Whether it's a sprite sheet (multiple frames) or single image
- Whether there are watermarks (common in AI-generated art)

### 2. Green screen removal (ImageMagick — primary method)

Use ImageMagick 7 (`magick` command) for all image processing. It's installed at `/opt/homebrew/bin/magick`.

**Step 2a — Initial removal (broad green range):**
```bash
magick "$INPUT" -alpha off \
  -fill none -fuzz 30% -draw "color 0,0 floodfill" \
  -channel alpha -blur 0x1 -level 50%,100% \
  "$OUTPUT_STEP1"
```

If floodfill doesn't work well (e.g., green patches inside the sprite), use the channel-based approach:
```bash
magick "$INPUT" \
  \( +clone -colorspace HSL -channel G -separate +channel \) \
  \( +clone -colorspace HSL -channel B -separate +channel \) \
  -delete 1,2 \
  -alpha copy \
  "$OUTPUT_STEP1"
```

**Step 2b — Targeted green channel removal (HSV-based):**
```bash
magick "$INPUT" \
  \( +clone -colorspace HSB -channel 0 -separate +channel \
     -threshold 22% \( +clone -threshold 50% \) -compose difference -composite \
     -negate \) \
  \( +clone -colorspace HSB -channel 1 -separate +channel -threshold 30% \) \
  -compose multiply -composite \
  -alpha copy \
  "$OUTPUT_STEP2"
```

**Step 2c — Despill (remove green fringe from edges):**
```bash
magick "$OUTPUT_STEP2" \
  \( +clone -channel G -evaluate Multiply 0.5 +channel \) \
  -compose CopyGreen -composite \
  "$OUTPUT_STEP3"
```

**Preferred one-liner for most green screens:**
```bash
magick "$INPUT" \
  -fuzz 25% -transparent "rgb(0,177,64)" \
  -fuzz 20% -transparent "rgb(0,255,0)" \
  -fuzz 15% -transparent "rgb(34,139,34)" \
  -channel alpha -blur 0x0.5 -level 40%,100% +channel \
  "$OUTPUT"
```

If the green screen color is non-standard, sample it first:
```bash
# Sample the top-left corner pixel color
magick "$INPUT" -crop 1x1+0+0 -format "%[hex:u.p{0,0}]" info:
```

### 3. Watermark removal

If AI-generated art has watermarks (usually bottom-right corner):
```bash
# Crop to remove bottom watermark area
magick "$OUTPUT" -gravity South -chop 0x40 "$OUTPUT_CROPPED"

# Or blank out a specific region
magick "$OUTPUT" -region 200x50+800+900 -alpha transparent +region "$OUTPUT_CLEAN"
```

### 4. Trim and crop to content

```bash
magick "$OUTPUT" -trim +repage "$OUTPUT_TRIMMED"
```

### 5. Validate output

Run validation to ensure clean removal:
```bash
# Count remaining greenish pixels (should be 0 or very low)
magick "$OUTPUT_TRIMMED" -colorspace HSB \
  \( -clone 0 -channel 0 -separate +channel -threshold 22% \
     \( +clone -threshold 50% \) -compose difference -composite \) \
  \( -clone 0 -channel 1 -separate +channel -threshold 25% \) \
  -delete 0 -compose multiply -composite \
  -format "%[fx:mean*100]" info:
```

If green percentage > 1%, re-process with higher fuzz values (30%, 35%, 40%).

Also visually inspect by reading the output PNG with the Read tool.

### 6. Scale for Godot

Xochi enemies are typically rendered at ~50px tall in-game. Scale the sprite:
```bash
# Scale to target height, nearest-neighbor for pixel art feel
magick "$OUTPUT_TRIMMED" -filter Point -resize x64 "$FINAL"

# Or for smoother sprites (non-pixel-art style):
magick "$OUTPUT_TRIMMED" -resize x128 "$FINAL"
```

The GDScript side handles final scaling with `sprite.scale = sprite_height / texture_height`.

### 7. Place in project

Copy the final processed sprite to the correct location:
- Character sprites → `assets/sprites/`
- Enemy sprites → `assets/sprites/enemies/`
- Environment sprites → `assets/sprites/environment/`
- UI sprites → `assets/sprites/ui/`

Always preserve the original source file — never modify it in place.

### 7b. Create Godot .import file

**CRITICAL**: Godot 4 cannot load textures without a `.import` file next to the PNG. Without it, `load()` returns null and the sprite shows as a placeholder (pink cube).

Create `<sprite_path>.import` alongside the PNG with the standard texture import config (see `/project:add-enemy` skill for the full template). Key fields:
- `importer="texture"`
- `type="CompressedTexture2D"`
- `uid="uid://d<unique_8chars>"` (generate unique)
- `process/fix_alpha_border=true`

The actual `.ctex` cache file will be created by Godot on next editor open.

### 8. Wire into code

For enemies, create or update the .gd script:
- Use `Sprite2D` with `load("res://assets/sprites/enemies/<name>.png")`
- Scale to ~50px tall: `sprite.scale = Vector2.ONE * (50.0 / texture.get_height())`
- Preserve existing collision shapes (typically RectangleShape2D ~30x40)

For new enemies, also:
- Add the type to `scripts/systems/enemy_spawner.gd` using dynamic `load()` (NOT static class_name reference — prevents cascade failures)
- Add enemy placements to levels in `scripts/levels/level_data.gd`

### 9. Report

Show the final sprite dimensions, file size, and confirm placement. If the sprite was wired into a script, show the relevant code changes.

## Fallback: Python/Pillow

If ImageMagick is unavailable, create a temp venv and use Pillow:
```bash
python3 -m venv /tmp/imgenv && source /tmp/imgenv/bin/activate && pip install Pillow
```

Then use HSV-based green detection:
- Hue range: 80-165 (green spectrum)
- Saturation threshold: >30%
- Also check RGB green ratio: G > R*1.2 and G > B*1.2

## Important

- NEVER skip validation — every sprite must pass the green fringe check
- If source image perspective looks wrong (top-down when it should be side-view), flag it immediately
- Preserve the original file — always work on a copy
- Non-EnemyBase enemies MUST use dynamic `load()` in EnemySpawner to prevent cascade failures
- Enemy combat interface requires: `alive` property, `hit_by_stomp()`, `hit_by_attack()`, `die()`, `setup()` methods

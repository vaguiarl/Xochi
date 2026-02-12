# Add New Enemy Type to Xochi

Full pipeline: process PNG sprite, create enemy script, wire into spawner and levels.

## Input
$ARGUMENTS

Argument format: `<source_image_path> <enemy_name> [movement_type]`
- source_image_path: Path to PNG (may have green screen background)
- enemy_name: e.g., "rabbitbrije", "calaca", "serpentbrije"
- movement_type: "ground" (default), "flying", "swimming", "platform"

Example: `/Users/victoraguiar/Documents/GitHub/Xochi/nanoart/serpent.png serpentbrije ground`

## Steps

### 1. Process the Sprite

Use ImageMagick (`/opt/homebrew/bin/magick`) for all image processing.

**Sample the background color:**
```bash
magick "$INPUT" -crop 1x1+0+0 -format "%[hex:u.p{0,0}]" info:
```

**Green screen removal (flood fill from all 4 corners):**
```bash
magick "$INPUT" \
  -fuzz 22% -fill none -draw "color 0,0 floodfill" \
  -fuzz 22% -fill none -draw "color 0,$((HEIGHT-1)) floodfill" \
  -fuzz 22% -fill none -draw "color $((WIDTH-1)),0 floodfill" \
  -fuzz 22% -fill none -draw "color $((WIDTH-1)),$((HEIGHT-1)) floodfill" \
  -channel alpha -blur 0x0.5 -level 50%,100% +channel \
  -trim +repage \
  "$OUTPUT"
```

Get dimensions first with `magick identify "$INPUT"` to know WIDTH and HEIGHT.

If green fringe remains, increase fuzz to 25%, 28%, 30%.

**White background removal:**
```bash
magick "$INPUT" -fuzz 15% -transparent white -trim +repage "$OUTPUT"
```

**Watermark removal** (common in AI-generated art, usually bottom-right):
```bash
magick "$OUTPUT" -region 200x150+$((WIDTH-200))+$((HEIGHT-150)) -alpha transparent +region "$OUTPUT"
```

**Final output location:** `assets/sprites/enemies/<enemy_name>.png`

### 2. Create the Godot .import File

**CRITICAL**: Godot 4 cannot load textures without an `.import` file. You MUST create one alongside the PNG. Without it, `load()` returns null and the enemy shows as a placeholder.

Create `assets/sprites/enemies/<enemy_name>.png.import`:
```ini
[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://d<unique_8chars>"
path="res://.godot/imported/<enemy_name>.png-<random_32hex>.ctex"
metadata={
"vram_texture": false
}

[deps]

source_file="res://assets/sprites/enemies/<enemy_name>.png"
dest_files=["res://.godot/imported/<enemy_name>.png-<random_32hex>.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
```

Generate unique values for `uid` and the hex hash. The actual `.ctex` file will be created by Godot on next editor open.

### 3. Validate the Sprite

Read the processed PNG to visually verify:
- Green screen fully removed
- No watermark artifacts
- Subject is intact (not clipped)
- Transparency works

### 4. Create the Entity Script

Create `scripts/entities/<enemy_name>.gd`:

**IMPORTANT rules:**
- Extend `CharacterBody2D` directly (standalone, NOT EnemyBase)
- Do NOT use `class_name` (prevents cascade failures)
- Load sprite with `load()` (not `preload()` — runtime loading)
- Include fallback placeholder if sprite fails to load
- Collision: Layer 8 (Enemies), Mask 1|2 (World + Platforms)
- Contact damage via Area2D monitoring Player layer (bit 3)

**Required duck-typing combat API:**
- `var alive: bool = true`
- `func hit_by_stomp()` — one-hit kill with squish/spin animation
- `func hit_by_attack()` — one-hit kill with knockback
- `func die()` — instant cleanup (no score)
- `func setup(data: Dictionary)` — config from spawner

**Movement patterns:**
- **Ground**: Apply gravity, `move_and_slide()`, reverse at walls/edges
- **Flying**: No gravity, `sin()` vertical oscillation, horizontal patrol
- **Swimming**: No gravity, wave-like movement, stays near water_y
- **Platform**: Like ground but bounded between platform_left/platform_right

**Sprite setup:**
```gdscript
var tex = load("res://assets/sprites/enemies/<name>.png")
if tex:
    sprite.texture = tex
    var scale_factor: float = TARGET_HEIGHT / tex.get_height()
    sprite.scale = Vector2(scale_factor, scale_factor)
```

Target heights: ground ~50px, flying ~45px, swimming ~40px.

### 5. Integrate with EnemySpawner

Edit `scripts/systems/enemy_spawner.gd`:
- Add new type to the comment at the top (line 9)
- Add a spawn block using **dynamic loading** (between existing handlers):

```gdscript
if type == "<enemy_name>":
    var script = load("res://scripts/entities/<enemy_name>.gd")
    if script == null:
        push_warning("EnemySpawner: failed to load <enemy_name>.gd, skipping")
        continue
    var enemy: CharacterBody2D = script.new()
    enemy.position = Vector2(enemy_data.x, enemy_data.y)
    enemy.setup({
        "dir": enemy_data.get("dir", 1),
        "speed": enemy_data.get("speed", 50),
        "level_width": level_data.get("width", 3000)
    })
    enemy.add_to_group("enemies")
    enemies_node.add_child(enemy)
    continue
```

### 6. Add to Level Data

Edit `scripts/levels/level_data.gd`:
- Add enemy entries to appropriate levels' "enemies" arrays
- Format: `{ "type": "<enemy_name>", "x": float, "y": float, "dir": 1, "speed": float }`
- For flying enemies, add `"amplitude": float` and set Y above platforms
- For ground enemies, set Y ~30px above the platform surface
- Start with 2-3 placements in early levels, increase in later levels
- Respect breathing zones (safe areas with no enemies)
- Skip boss levels (5, 10) and fiesta level (11)

### 7. Verify

After all changes:
- Read the processed sprite to confirm it looks correct
- Verify the .import file exists alongside the PNG
- Verify the enemy script has all required methods
- Verify the EnemySpawner has the new type handler
- Verify level data has enemy placements

## Important

- NEVER use `class_name` on new enemy scripts — prevents cascade failures
- ALWAYS create the `.import` file — without it, Godot shows placeholder
- ALWAYS use dynamic `load()` in EnemySpawner, never static references
- Preserve the original source file — always work on a copy
- Source art is typically in `/Users/victoraguiar/Documents/GitHub/Xochi/nanoart/`

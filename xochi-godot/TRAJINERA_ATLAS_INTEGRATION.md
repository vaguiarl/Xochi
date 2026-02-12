# 🚤 Trajinera Atlas Integration - Step 3

## What We're Doing

Using **AtlasTexture** to extract each trajinera from the sprite sheet without needing external image processing tools. Godot handles everything!

---

## Code Changes to `scenes/game/game_scene.gd`

### Replace the PRELOADED ASSETS section:

```gdscript
# =============================================================================
# PRELOADED ASSETS
# =============================================================================

## Trajinera sprite sheet (contains all 3 trajineras on green screen)
const TRAJINERA_SHEET: Texture2D = preload("res://assets/sprites/prerendered/environment/trajineras/trajinera_sheet.png")

## Extract individual trajineras using AtlasTexture regions
## These coordinates define where each trajinera is in the sprite sheet
## Format: Region2(x, y, width, height) - adjust based on actual positions

static func _create_trajinera_atlas(region_x: float, region_y: float, region_w: float, region_h: float) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = TRAJINERA_SHEET
	atlas.region = Rect2(region_x, region_y, region_w, region_h)
	# Enable filter to remove green screen pixels
	atlas.set_filter_clip(true)
	return atlas

## Individual trajinera textures extracted from sheet
## Coordinates are approximate - adjust after seeing in Godot
const TRAJINERA_FIESTA: AtlasTexture = null  # Will be created at runtime
const TRAJINERA_SOL: AtlasTexture = null
const TRAJINERA_AMOR: AtlasTexture = null

## Runtime initialization of atlas textures
static var _trajinera_textures_initialized: bool = false
static var _fiesta_texture: AtlasTexture
static var _sol_texture: AtlasTexture
static var _amor_texture: AtlasTexture

static func _init_trajinera_textures() -> void:
	if _trajinera_textures_initialized:
		return

	# LA FIESTA (top) - approximate region, adjust as needed
	_fiesta_texture = _create_trajinera_atlas(250, 0, 900, 400)

	# EL SOL (bottom-left)
	_sol_texture = _create_trajinera_atlas(0, 440, 700, 360)

	# AMOR (bottom-right)
	_amor_texture = _create_trajinera_atlas(750, 440, 700, 360)

	_trajinera_textures_initialized = true

## Get array of all trajinera textures
static func get_trajinera_textures() -> Array[AtlasTexture]:
	_init_trajinera_textures()
	return [_fiesta_texture, _sol_texture, _amor_texture]
```

### Update `_create_trajinera()` function:

Find the section where it loads the sprite texture and replace:

```gdscript
func _create_trajinera(data: Dictionary) -> void:
	# ... (existing code for position, collision, etc.) ...

	# Initialize atlas textures if not already done
	if not _trajinera_textures_initialized:
		_init_trajinera_textures()

	# Randomly select a trajinera from the sheet
	var textures := get_trajinera_textures()
	var sprite_texture: Texture2D = textures[randi() % textures.size()]

	if sprite_texture != null:
		# Use the beautiful pre-rendered side-view sprite
		var sprite := Sprite2D.new()
		sprite.texture = sprite_texture

		# Calculate scale to fit the desired width
		var sprite_width: float = sprite_texture.get_width()
		var sprite_height: float = sprite_texture.get_height()
		var scale_factor: float = traj_w / sprite_width

		sprite.scale = Vector2(scale_factor, scale_factor)

		# Center the sprite
		sprite.centered = true
		sprite.position = Vector2(0, -sprite_height * scale_factor * 0.3)  # Adjust Y to align hull with collision

		# Remove green screen via shader or transparency
		# The AtlasTexture should already have the texture, but if green shows through:
		sprite.material = _create_chroma_key_material()

		body.add_child(sprite)
	else:
		# Fallback (should not happen)
		push_warning("Failed to load trajinera atlas")
		# ... (existing ColorRect fallback code) ...

	# ... (rest of existing code) ...
```

### Add Chroma Key Shader Function:

Add this helper function to remove green screen dynamically:

```gdscript
static var _chroma_key_material: ShaderMaterial = null

static func _create_chroma_key_material() -> ShaderMaterial:
	if _chroma_key_material != null:
		return _chroma_key_material

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	// Remove green screen (RGB: 0, 255, 0)
	float green_dist = distance(color.rgb, vec3(0.0, 1.0, 0.0));

	// If pixel is greenish, make it transparent
	if (green_dist < 0.2) {
		color.a = 0.0;
	}

	COLOR = color;
}
"""

	_chroma_key_material = ShaderMaterial.new()
	_chroma_key_material.shader = shader

	return _chroma_key_material
```

---

## Testing & Adjusting Coordinates

### 1. First Run:
```bash
godot --headless --quit --editor  # Import sprite sheet
./run.sh
```

### 2. Check Results:

If trajineras look cut off or have extra space:
- Open `trajinera_sheet.png` in Godot's FileSystem
- Note the actual pixel positions of each boat
- Update the region coordinates in `_create_trajinera_atlas()` calls

### 3. Finding Exact Coordinates:

Open in any image viewer and measure:
- LA FIESTA (top): starts at Y=0, approximately X=250, width ~900px
- EL SOL (bottom-left): starts around X=0, Y=440
- AMOR (bottom-right): starts around X=750, Y=440

---

## Collision Shape Alignment

The player needs to land on the **hull** (bottom part of boat).

Adjust collision shape Y offset if needed:

```gdscript
# In _create_trajinera():
shape.position = Vector2(0, 10)  # Adjust this value so player lands on visible hull
```

Test by:
1. Running game
2. Jumping onto trajinera
3. Checking if Xochi lands cleanly on the hull or floats/sinks

---

## Alternative: Manual Sprite Extraction (Optional)

If you want separate PNG files instead of atlas:

### Using Preview.app (macOS):
1. Open `side_view_trajineras.png` in Preview
2. Tools > Rectangular Selection
3. Select one trajinera
4. Edit > Copy
5. File > New from Clipboard
6. File > Export > PNG > Save as `fiesta.png`
7. Repeat for other two

Then use individual files instead of AtlasTexture.

---

## Expected Result

After integration you should see:
- ✅ 3 beautiful side-view trajineras in Level 1
- ✅ "LA FIESTA", "EL SOL", "AMOR" appearing randomly
- ✅ No green screen background (transparent or removed via shader)
- ✅ Proper scale (120-160px wide in-game)
- ✅ Xochi can jump onto them and ride them
- ✅ Trajineras move left/right and bob gently

---

## Next Steps

1. **Implement the code changes** (I'll do this now)
2. **Test the game** (`./run.sh`)
3. **Adjust atlas regions** if sprites are cut off
4. **Fine-tune collision** so Xochi lands perfectly on hull
5. **Report back** with screenshot!

Then we can use this same pipeline for all future sprites (enemies, collectibles, Xochi animations)!

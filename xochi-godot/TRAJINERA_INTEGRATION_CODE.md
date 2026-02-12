# 🚤 Trajinera Side-View Integration Code

## Once You Have the 3 Side-View Renders

### 1. File Setup

Place the renders in:
```
assets/sprites/prerendered/environment/trajineras/
├── fiesta.png      (LA FIESTA - pink/red flowers)
├── sol.png         (EL SOL - yellow sunflowers)
└── amor.png        (AMOR - yellow flowers)
```

### 2. Code Changes to `scenes/game/game_scene.gd`

Replace the `TRAJINERA_TEXTURE` constant section:

```gdscript
# =============================================================================
# PRELOADED ASSETS
# =============================================================================

## Trajinera sprite textures (preloaded DKC-style pre-rendered 3D sprites)
const TRAJINERA_FIESTA: Texture2D = preload("res://assets/sprites/prerendered/environment/trajineras/fiesta.png")
const TRAJINERA_SOL: Texture2D = preload("res://assets/sprites/prerendered/environment/trajineras/sol.png")
const TRAJINERA_AMOR: Texture2D = preload("res://assets/sprites/prerendered/environment/trajineras/amor.png")

## Array of all trajinera textures for random selection
const TRAJINERA_TEXTURES: Array[Texture2D] = [
	TRAJINERA_FIESTA,
	TRAJINERA_SOL,
	TRAJINERA_AMOR
]
```

### 3. Update `_create_trajinera()` Function

Change the texture loading section:

```gdscript
func _create_trajinera(data: Dictionary) -> void:
	# ... (existing code for position, collision, etc.) ...

	# Use one of the pre-rendered 3D trajinera sprites (DKC style)
	var sprite_texture: Texture2D = TRAJINERA_TEXTURES[randi() % TRAJINERA_TEXTURES.size()]

	if sprite_texture != null:
		# Use the beautiful pre-rendered 3D sprite
		var sprite := Sprite2D.new()
		sprite.texture = sprite_texture

		# Calculate scale to fit the desired width
		var sprite_width: float = sprite_texture.get_width()
		var sprite_height: float = sprite_texture.get_height()
		var scale_factor: float = traj_w / sprite_width

		sprite.scale = Vector2(scale_factor, scale_factor)

		# Center the sprite
		sprite.offset = Vector2(sprite_width / 2.0, sprite_height / 2.0)

		# NO color tinting - preserve the pre-rendered colors!
		# sprite.modulate = Color.WHITE  # Pure white = no tint

		body.add_child(sprite)
	else:
		# Fallback to ColorRect if sprite fails to load
		push_warning("Failed to load trajinera sprite, using fallback")
		var hull := ColorRect.new()
		hull.size = Vector2(traj_w, traj_h + 30)
		hull.position = -Vector2(traj_w, traj_h + 30) * 0.5
		hull.color = traj_color
		body.add_child(hull)

	# ... (rest of existing code for metadata, etc.) ...
```

### 4. Optional: Name-Based Selection

If you want specific trajineras to appear in certain levels:

```gdscript
# Map trajinera names to textures
var sprite_texture: Texture2D = null
match traj_name:
	"LA FIESTA", "Fiesta":
		sprite_texture = TRAJINERA_FIESTA
	"EL SOL", "Sol":
		sprite_texture = TRAJINERA_SOL
	"AMOR", "Amor":
		sprite_texture = TRAJINERA_AMOR
	_:
		# Random if name doesn't match
		sprite_texture = TRAJINERA_TEXTURES[randi() % TRAJINERA_TEXTURES.size()]
```

---

## Testing

After integration:

```bash
cd /Users/victoraguiar/Documents/GitHub/Xochi/xochi-godot
godot --headless --quit --editor  # Import new sprites
./run.sh  # Run game
```

You should see:
- ✅ Three different trajinera designs appearing randomly
- ✅ Clean side-view silhouettes (no confusing perspective)
- ✅ Beautiful pre-rendered 3D look like DKC
- ✅ Proper scaling to fit game platforms

---

## What to Look For

**Good signs:**
- Trajineras look clear and readable
- Side profile shows hull + canopy arch
- Colors are vibrant and match Mexican aesthetic
- No "cube" appearance
- Easy to see where to land

**If scale is wrong:**
Adjust the scale multiplier:
```gdscript
var scale_factor: float = (traj_w / sprite_width) * 1.2  // Make 20% bigger
var scale_factor: float = (traj_w / sprite_width) * 0.8  // Make 20% smaller
```

**If position is wrong:**
Adjust the sprite offset or collision shape position.

---

## Next Steps

Once trajineras look good:
1. Take a screenshot and show me!
2. We'll start on Xochi character animations (walk cycle)
3. Then enemies, collectibles, etc.

The DKC pipeline is starting! 🎮✨

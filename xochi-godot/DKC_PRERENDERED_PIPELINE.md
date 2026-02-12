# 🎮 DKC-Style Pre-Rendered 3D Sprite Pipeline for Xochi

## Overview

This document outlines how to create **pre-rendered 3D sprites** like Donkey Kong Country for Xochi. The workflow:
1. Create 3D models (Blender or AI tools)
2. Render from fixed side-view camera angle
3. Export as transparent PNG sprite sheets
4. Import to Godot as AnimatedSprite2D resources

This gives the iconic "chunky 3D" DKC look while keeping 2D gameplay simple.

---

## 🚤 Phase 1: Trajinera Side-View (Immediate)

### Option A: Request from Nano Banana

Ask nano banana to render the existing 3D trajinera models from **pure side view**:

```
Render this 3D Mexican trajinera boat from PURE SIDE VIEW ONLY,
camera at 90 degrees (perfectly flat side profile), no perspective,
no depth, no interior visible, just the side silhouette of the boat
hull and decorative canopy arch, 1024x512 pixels, transparent
background PNG, vibrant colors preserved (blue hull, colorful
canopy), clean render like Donkey Kong Country sprites, high quality
anti-aliased edges
```

**What you need:**
- Pure side profile (90° camera angle)
- Transparent background
- High resolution (1024x512, we'll scale down later)
- Clean anti-aliased edges

**Deliver 3 versions:**
1. "LA FIESTA" - Pink/red flowers
2. "EL SOL" - Yellow/orange sunflowers
3. "AMOR" - Yellow flowers

### Option B: Use Blender (If You Have the .FBX/.OBJ Files)

If nano banana can export the 3D model files:

1. **Import to Blender**:
   - File > Import > FBX/OBJ/GLTF
   - Load trajinera model

2. **Set up camera**:
   ```
   Camera position: (0, 0, -10)
   Camera rotation: (90°, 0°, 0°)
   Camera type: Orthographic
   Orthographic scale: 5.0
   ```

3. **Render settings**:
   - Resolution: 1024x512
   - Background: Transparent (Film > Transparent enabled)
   - File format: PNG with RGBA
   - Samples: 128 (for clean edges)

4. **Render**:
   - F12 to render
   - Image > Save As > PNG

---

## 🎨 Phase 2: Full Asset Pipeline

Once we have trajineras working, expand to all game assets.

### Assets Needed:

#### **Characters:**
- **Xochi (player)**: 16x16 sprite base, rendered at 128x128
  - Idle: 4 frames (breathing)
  - Walk: 8 frames
  - Run: 8 frames
  - Jump: 1 frame (arc pose)
  - Fall: 1 frame
  - Attack: 4 frames (swing mace)
  - Hurt: 2 frames (flash)

#### **Enemies:**
- **Seagull (ground)**: 32x32 base, rendered at 256x256
  - Walk: 6 frames
  - Turn: 2 frames
  - Death: 4 frames (squash)

- **Heron (flying)**: 48x48 base, rendered at 384x384
  - Fly: 6 frames (wing flap)
  - Shoot: 3 frames
  - Death: 4 frames

- **Boss (Dark Xochi)**: 64x64 base, rendered at 512x512
  - Idle: 4 frames
  - Walk: 8 frames
  - Telegraph: 3 frames (warning flash)
  - Attack: 6 frames
  - Dizzy: 4 frames (wobble)

#### **Collectibles:**
- **Cempasúchil flower**: 16x16, rendered at 128x128, 4 frames (shimmer)
- **Elote (corn)**: 16x16, rendered at 128x128, 1 frame
- **Baby axolotl**: 32x32, rendered at 256x256, 4 frames (bob)
- **Feather powerup**: 16x16, rendered at 128x128, 4 frames (float)
- **Luchador mask**: 24x24, rendered at 192x192, 1 frame

#### **Environment:**
- **Trajineras**: 160x80 base, rendered at 1024x512, 1 frame each (6 colors)
- **Platforms**: Tile sets 32x32, rendered at 256x256
- **Background elements**: Trees, mountains, buildings

---

## 🎬 DKC Rendering Style Guide

To match Donkey Kong Country's aesthetic:

### **Lighting:**
- 3-point lighting setup (key, fill, rim)
- Slightly exaggerated rim light for "pop"
- Warm key light (yellowish)
- Cool fill light (blueish shadows)

### **Materials:**
- Slightly glossy surfaces (not matte, not mirror)
- Exaggerated colors (saturated, vibrant)
- Subtle texture details (wood grain, fabric weave)

### **Camera:**
- **Always orthographic** (no perspective distortion)
- **Fixed angle** per asset type:
  - Side-scrolling sprites: 90° side view
  - Top-down items: 45° isometric (optional)
- **Consistent scale** (character = 128px height at render time)

### **Anti-aliasing:**
- High sample count (128-256 samples)
- Clean edges that scale down well
- Transparent background with proper alpha

### **Color palette:**
DKC used limited but vibrant colors. For Xochi:
- **Blues**: Cyan (#4ECDC4), Sky (#55CCEE)
- **Oranges**: Bright (#FFA500), Marigold (#FF8C00)
- **Pinks**: Hot (#FF6B9D), Soft (#FFBBCC)
- **Yellows**: Golden (#FFD700), Bright (#FFEE44)
- **Greens**: Teal (#44CCAA), Lime (#88CC44)
- **Purples**: Deep (#6644AA), Lavender (#AA88CC)

---

## 🔧 Blender Setup (Full Pipeline)

### Installation:
```bash
brew install --cask blender
# Or download from blender.org
```

### Project structure:
```
Xochi-3D-Assets/
├── models/
│   ├── characters/
│   │   ├── xochi.blend
│   │   └── dark_xochi.blend
│   ├── enemies/
│   │   ├── seagull.blend
│   │   └── heron.blend
│   ├── environment/
│   │   ├── trajinera_1.blend
│   │   └── platforms.blend
│   └── collectibles/
│       ├── flower.blend
│       └── axolotl.blend
├── renders/
│   ├── xochi_walk_001.png
│   ├── xochi_walk_002.png
│   └── ...
└── scripts/
    └── batch_render.py  # Automation script
```

### Blender Batch Render Script:

```python
# batch_render.py - Run in Blender's scripting console
import bpy
import os

# Configuration
output_dir = "/path/to/renders/"
frames = range(1, 9)  # 8 frames for walk cycle
resolution_x = 128
resolution_y = 128

# Set render settings
bpy.context.scene.render.resolution_x = resolution_x
bpy.context.scene.render.resolution_y = resolution_y
bpy.context.scene.render.film_transparent = True
bpy.context.scene.render.image_settings.file_format = 'PNG'
bpy.context.scene.render.image_settings.color_mode = 'RGBA'

# Render each frame
for frame in frames:
    bpy.context.scene.frame_set(frame)
    output_path = os.path.join(output_dir, f"xochi_walk_{frame:03d}.png")
    bpy.context.scene.render.filepath = output_path
    bpy.ops.render.render(write_still=True)
    print(f"Rendered frame {frame}")

print("Batch render complete!")
```

---

## 📦 Sprite Sheet Organization

### Naming convention:
```
[asset]_[animation]_[frame].png

Examples:
xochi_idle_001.png
xochi_walk_001.png ... xochi_walk_008.png
seagull_walk_001.png ... seagull_walk_006.png
trajinera_pink.png
flower_shimmer_001.png ... flower_shimmer_004.png
```

### Directory structure in Godot:
```
assets/sprites/prerendered/
├── characters/
│   ├── xochi/
│   │   ├── idle/ (4 frames)
│   │   ├── walk/ (8 frames)
│   │   ├── run/ (8 frames)
│   │   ├── jump/ (1 frame)
│   │   └── attack/ (4 frames)
│   └── boss/
│       └── ...
├── enemies/
│   ├── seagull/
│   └── heron/
├── environment/
│   ├── trajineras/
│   │   ├── trajinera_pink.png
│   │   ├── trajinera_yellow.png
│   │   └── ...
│   └── platforms/
└── collectibles/
    ├── flowers/
    ├── powerups/
    └── babies/
```

---

## 🎮 Godot Integration

### Creating AnimatedSprite2D Resources:

1. **Import renders**:
   - Drag PNGs into Godot FileSystem
   - Godot auto-creates .import files

2. **Create SpriteFrames resource**:
   - Right-click in FileSystem > New Resource > SpriteFrames
   - Save as `xochi_animations.tres`

3. **Add animations**:
   - Open SpriteFrames in inspector
   - Add animation: "idle", "walk", "run", "jump", "attack"
   - For each animation:
     - Click animation name
     - Add frames by dragging PNGs
     - Set FPS (8-12 for walk, 1 for static)

4. **Use in scenes**:
   ```gdscript
   # In player.gd
   @onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

   sprite.sprite_frames = preload("res://assets/sprites/prerendered/characters/xochi/xochi_animations.tres")
   sprite.play("idle")

   # In _physics_process:
   if velocity.x != 0:
       sprite.play("walk")
   else:
       sprite.play("idle")
   ```

### For static sprites (trajineras):

Keep current Sprite2D approach, just swap texture:
```gdscript
const TRAJINERA_PINK: Texture2D = preload("res://assets/sprites/prerendered/environment/trajineras/trajinera_pink.png")
const TRAJINERA_YELLOW: Texture2D = preload("res://assets/sprites/prerendered/environment/trajineras/trajinera_yellow.png")
# etc.

# In _create_trajinera():
sprite.texture = TRAJINERA_PINK  # or randomly select
```

---

## 🎯 Immediate Next Steps

### 1. Get Trajinera Side-View Renders (TODAY)

Ask nano banana:
```
Render these 3 Mexican trajinera boats from PURE SIDE VIEW (90° angle),
no perspective, transparent background, 1024x512 pixels each, vibrant
colors, clean anti-aliased edges like Donkey Kong Country sprites:

1. "LA FIESTA" - pink/red flowers, blue hull
2. "EL SOL" - yellow sunflowers, blue hull
3. "AMOR" - yellow flowers, blue hull

Deliver as 3 separate PNG files with transparency.
```

### 2. Test in Godot (30 minutes)

Once you have the PNGs:
1. Copy to `assets/sprites/prerendered/environment/trajineras/`
2. Update game_scene.gd to load them:
   ```gdscript
   const TRAJINERA_FIESTA: Texture2D = preload("res://assets/sprites/prerendered/environment/trajineras/fiesta.png")
   const TRAJINERA_SOL: Texture2D = preload("res://assets/sprites/prerendered/environment/trajineras/sol.png")
   const TRAJINERA_AMOR: Texture2D = preload("res://assets/sprites/prerendered/environment/trajineras/amor.png")

   const TRAJINERA_TEXTURES: Array[Texture2D] = [
       TRAJINERA_FIESTA,
       TRAJINERA_SOL,
       TRAJINERA_AMOR
   ]

   # In _create_trajinera():
   sprite.texture = TRAJINERA_TEXTURES[randi() % TRAJINERA_TEXTURES.size()]
   ```

3. Run game, see beautiful side-view 3D trajineras!

### 3. Plan Character Pipeline (NEXT SESSION)

Once trajineras work, we'll tackle:
- Xochi walk cycle (8 frames)
- Enemy animations
- Collectible shimmers

---

## 📊 Asset Production Timeline

**Week 1**: Environment assets
- ✅ Trajineras (3 renders) - TODAY
- Platforms (tile set)
- Background props

**Week 2**: Characters
- Xochi animations (40 frames total)
- Boss animations (30 frames total)

**Week 3**: Enemies & Collectibles
- Seagull (12 frames)
- Heron (13 frames)
- Collectibles (10 frames total)

**Week 4**: Polish & Integration
- Particle effects
- UI elements
- Final touch-ups

---

## 🎨 Style References

**Study these DKC techniques:**
- Character proportions (big heads, chunky limbs)
- Exaggerated poses (weight shift, squash/stretch)
- Rim lighting for "pop"
- Limited but vibrant color palette
- Clean silhouettes

**Xochi should feel like:**
- DKC's chunky 3D aesthetic
- Mexican folk art vibrant colors
- Aztec warrior character design
- Platformer readability (clear hitboxes)

---

## 💡 Pro Tips

1. **Render larger, scale down**: Render at 2-4x target size for crisp edges
2. **Consistent lighting**: Save Blender lighting setup, reuse for all assets
3. **Animation keys**: Use odd numbers (3, 5, 7) for smoother loops
4. **Sprite sheets**: Pack frames into atlases to reduce draw calls
5. **Test early**: Import rough renders to Godot ASAP to verify scale/feel

---

## 🚀 Let's Start!

**Right now**: Get those trajinera side-view renders from nano banana.

Once you have them, ping me and I'll help integrate them into the game!

Then we'll tackle the full character animation pipeline. 🎮✨

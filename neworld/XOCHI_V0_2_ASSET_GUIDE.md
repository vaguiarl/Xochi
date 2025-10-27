# Xóchi v0.2 — Asset Swap Guide (For Cursor)

**Goal:** Replace the original art in your Pygame project with a full **Xochimilco** theme using **drop‑in PNG atlases** and **JSON remaps only**. No Python code changes required.

This guide assumes your project structure is like:
```
super-mario-python-master/
├─ main.py
├─ classes/
├─ entities/
├─ sprites/
└─ img/
```
> If your folders differ, adapt paths accordingly.

---

## 1) Files to copy

Copy all PNGs from this package into your project’s `img/` directory:

- `img/xochi_characters_v2.png`  – Xóchi player small/big frames
- `img/birds_enemies.png`        – Gull (Goomba) & Heron (Koopa) frames
- `img/xochi_tiles.png`          – Chinampa soil, pier, stone, water, reeds, bridge, sluice/lever
- `img/xochi_fx.png`             – Splash, sparks, petal burst, dash trail
- `img/xochi_items.png`          – Star spin, shrine, UI icons
- `img/xochi_parallax.png`       – Night skyline parallax (optional)

> Keep the filenames exactly as provided. We’ll remap JSON to point to them.

---

## 2) Player Sprite Pack — `sprites/Mario.json`

Open `sprites/Mario.json` and update:

1. **Sprite sheet URL**
```jsonc
"spriteSheetURL": "./img/xochi_characters_v2.png",
"size": [16, 16]
```

2. **Coordinates** (top‑left origin). Keep **existing names** so game code works unchanged.

### Small (16×16) — Row A at y=0
| Name           | x  | y  |
|----------------|----|----|
| mario_idle     | 0  | 0  |
| mario_run1     | 32 | 0  |
| mario_run2     | 48 | 0  |
| mario_run3     | 64 | 0  |
| mario_break    | 80 | 0  |
| mario_jump     | 96 | 0  |
| mario_dead     | 112| 0  |

> Note: An extra `idle2` frame exists at (16,0) for future polish; not required by the current code.

### Big (16×32) — Row B at y=16
Add `xsize:16, ysize:32` for big frames.
| Name              | x  | y  | xsize | ysize |
|-------------------|----|----|-------|-------|
| mario_big_idle    | 0  | 16 | 16    | 32    |
| mario_big_run1    | 32 | 16 | 16    | 32    |
| mario_big_run2    | 48 | 16 | 16    | 32    |
| mario_big_run3    | 64 | 16 | 16    | 32    |
| mario_big_jump    | 80 | 16 | 16    | 32    |
| mario_big_break   | 96 | 16 | 16    | 32    |

> There’s an optional `idle2` at (16,16) you can map later.

**Other fields**
```jsonc
"scalefactor": 2,
"colorKey": -1,   // use PNG alpha
"collision": false
```

---

## 3) Goomba → Gull (Conscript) — `sprites/Goomba.json`

Point to the birds sheet and remap frames:

```jsonc
"spriteSheetURL": "./img/birds_enemies.png"
```

**Gull (16×16 @ y=0)**
| Goomba name   | x  | y  |
|---------------|----|----|
| goomba_walk1  | 0  | 0  |
| goomba_walk2  | 16 | 0  |
| goomba_dead   | 32 | 0  |

> Keep other fields as‑is (`scalefactor`, etc.).

---

## 4) Koopa → Heron (Halberdier) — `sprites/Koopa.json`

Point to the birds sheet and remap frames:

```jsonc
"spriteSheetURL": "./img/birds_enemies.png"
```

**Heron (17×32 @ y=16)** — Set `xsize:17, ysize:32` for these entries.
| Koopa name           | x  | y  | xsize | ysize |
|----------------------|----|----|-------|-------|
| koopa_walk1          | 0  | 16 | 17    | 32    |
| koopa_walk2          | 17 | 16 | 17    | 32    |
| koopa_shell          | 34 | 16 | 17    | 32    |  // map to 'guard' pose
| koopa_shell_moving   | 51 | 16 | 17    | 32    |  // map to 'hit' pose

> If your Koopa pack uses more names (walk3/4), map them to `walk1/2` duplicates.

---

## 5) Background & Tiles — `sprites/BackgroundSprites.json`

Point to `xochi_tiles.png` (and optionally add separate entries that reference `xochi_parallax.png` for parallax layers if your engine supports it).

```jsonc
"spriteSheetURL": "./img/xochi_tiles.png"
```

**Suggested tile mappings (16×16):**
| Name               | x  | y  | Notes                  |
|--------------------|----|----|------------------------|
| ground_soil_0      | 0  | 0  | chinampa soil variant  |
| ground_soil_1      | 16 | 0  |                        |
| ground_soil_2      | 32 | 0  |                        |
| pier_wood          | 0  | 16 |                        |
| pier_wood_1        | 16 | 16 |                        |
| pier_wood_2        | 32 | 16 |                        |
| stone_dock_0       | 0  | 32 |                        |
| stone_dock_1       | 16 | 32 |                        |
| stone_dock_2       | 32 | 32 |                        |
| water_surface_0    | 0  | 48 | loop with 1 & 2        |
| water_surface_1    | 16 | 48 |                        |
| water_surface_2    | 32 | 48 |                        |
| reeds_0            | 0  | 64 | non‑solid              |
| reeds_1            | 16 | 64 |                        |
| reeds_2            | 32 | 64 |                        |
| rope_bridge_0      | 0  | 80 |                        |
| rope_bridge_1      | 16 | 80 |                        |
| rope_bridge_2      | 32 | 80 |                        |
| sluice_gate        | 0  | 96 | solid/visual gate      |
| lever_tile         | 16 | 96 | lever graphic          |

**Optional parallax (separate entry)**  
If your background system references multiple sheets, create a second pack:
```jsonc
{{
  "spriteSheetURL": "./img/xochi_parallax.png",
  "type": "background",
  "sprites": [
    {{ "name": "parallax_skyline", "x": 0, "y": 0, "xsize": 512, "ysize": 128, "colorKey": -1 }}
  ]
}}
```

---

## 6) Items — `sprites/ItemAnimations.json`

Point item animations to `xochi_items.png`. Typical remaps (16×16 unless noted):

| Item name       | x  | y  | frames | Notes                 |
|-----------------|----|----|--------|-----------------------|
| coin_spin       | 0  | 0  | 4      | star spin frames 0–3  |
| shrine          | 0  | 16 | 1      | **16×32**: set ysize 32|
| ui_mp           | 16 | 16 | 1      | star icon             |
| ui_token        | 32 | 16 | 1      | chip icon             |
| ui_heart        | 48 | 16 | 1      | health icon (optional)|

**Example animation entry:**
```jsonc
{{
  "name": "coin_spin",
  "images": [
    {{"x":0,"y":0}}, {{"x":16,"y":0}}, {{"x":32,"y":0}}, {{"x":48,"y":0}}
  ],
  "deltaTime": 90,
  "colorKey": -1
}}
```
**Shrine (16×32):**
```jsonc
{{ "name": "shrine", "x": 0, "y": 16, "xsize": 16, "ysize": 32, "colorKey": -1 }}
```

---

## 7) FX / Hazards — `sprites/Animations.json`

Point to `xochi_fx.png` and define sequences:

| Name        | frames (x,y)                     | ms  |
|-------------|----------------------------------|-----|
| fx_splash   | (0,0),(16,0),(32,0)              | 90  |
| fx_sparks   | (0,16),(16,16),(32,16)           | 80  |
| fx_petals   | (0,32),(16,32),(32,32),(48,32)   | 90  |
| fx_dash     | (0,48),(16,48)                   | 60  |

**Example:**
```jsonc
{{
  "name": "fx_splash",
  "images": [{{"x":0,"y":0}},{{"x":16,"y":0}},{{"x":32,"y":0}}],
  "deltaTime": 90,
  "colorKey": -1
}}
```

---

## 8) Sanity checks (common pitfalls)

- **Black box sprite?** Check `spriteSheetURL` path + filename; ensure PNG exists in `img/`.  
- **Misaligned feet / jitter?** Ensure each animation frame shares the same baseline; adjust `x,y` per frame.  
- **Bleeding edges when scaled?** Keep a 2‑px transparent gutter around frames in atlases.  
- **Water not animating?** Confirm your level references `water_surface_0..2` in order.  
- **Big form clipping?** Ensure big entries have `xsize:16, ysize:32`.

---

## 9) Quick test plan

1. Run `python main.py`.  
2. Verify:
   - Xóchi idle/run/jump/dead frames display (small and big states).  
   - Gull (Goomba) walks & squishes.  
   - Heron (Koopa) walks & “shell/guard” poses look acceptable.  
   - Tiles show chinampa/pier/stone; water animates.  
   - Picking a “coin” shows star spin; splash FX on water contact.  
3. Fix any offsets by editing the `x,y` in the corresponding JSON entry.

---

## 10) Rollback

All changes are in `img/*.png` and `sprites/*.json`. To revert, restore original PNGs/JSONs or reset those files via version control.

---

## 11) License note (placeholders)

These atlases are **placeholder art** generated for development. Replace with your final pixel art before shipping commercially.

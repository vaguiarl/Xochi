# Xóchi v0.3 — Beautiful Art Bundle (Drop‑in)

This bundle contains **improved sprites** with soft shading and harmonized colors. Sizes are kept engine‑safe:
- Player small **16×16**, big **16×32**
- Tiles **16×16**
- Enemies: gull **16×16**, heron **17×32**

## Files

### img/
- `xochi_characters_v3.png` — main character (small+big frames)
- `xochi_char_glow_v3.png` — optional additive glow layer (same layout)
- `birds_enemies_v3.png` — gull (Goomba) & heron (Koopa)
- `xochi_tiles_v3.png` — ground/pier/stone/water/reeds/bridge/sluice/lever
- `xochi_fx_v3.png` — splash/sparks/petals/dash
- `xochi_items_v3.png` — star spin, shrine (16×32), UI icons
- `xochi_parallax_v3.png` — wide skyline background

### sprites/
- `Mario.json` — points to `xochi_characters_v3.png`
- `MarioGlow.json` — (optional) points to `xochi_char_glow_v3.png`
- `Goomba.json`, `Koopa.json` — enemies
- `BackgroundSprites.json` — tiles & props
- `ItemAnimations.json` — items & UI
- `Animations.json` — FX sequences

## How to install
1. Copy **img/** files to your project’s `img/` folder.
2. Copy **sprites/** files to your project’s `sprites/` folder (back up originals).
3. Run the game. No Python changes needed.

## Optional glow overlay
If you wish to render `xochi_char_glow_v3.png` as an additive layer, draw the matching frame on top of the base frame using additive blending (e.g. `BLEND_ADD`). If your engine lacks this, you can ignore the glow sheet.

## Troubleshooting
- Black box sprite → check `spriteSheetURL` paths in JSON.
- Misaligned feet → tweak per‑sprite `x,y` or adjust baseline in your transform.
- Big form clipping → ensure big entries have `xsize:16, ysize:32` in `Mario.json`.

## License (placeholders)
This bundle is placeholder art for development and iteration. Replace with final art before commercial release.

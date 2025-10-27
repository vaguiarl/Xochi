# Xóchi v0.2 JSON Pack

Drop these files into your project's `sprites/` directory and ensure the PNG atlases are placed under `img/`:

- ./sprites/Mario.json              → ./img/xochi_characters_v2.png
- ./sprites/Goomba.json             → ./img/birds_enemies.png
- ./sprites/Koopa.json              → ./img/birds_enemies.png
- ./sprites/BackgroundSprites.json  → ./img/xochi_tiles.png
- ./sprites/ItemAnimations.json     → ./img/xochi_items.png
- ./sprites/Animations.json         → ./img/xochi_fx.png

Notes:
- Names are preserved where possible (e.g., mario_*), so engine code usually doesn't change.
- Heron (Koopa) uses 17x32 frames; entries include xsize/ysize.
- If your engine expects additional sprite names, duplicate nearby frames to those names.

# `xochi.md` — Product Spec for `xochi_side_scroller_v0_1.zip` (Cursor Context)

**Version:** 0.1 (sprite-swap MVP)
**Purpose:** Provide Cursor with everything needed to run, inspect, and iterate on the Xóchi sprite–swapped side-scroller.

---

## 0) TL;DR

* This is a Pygame **Mario clone** with **only the player sprites replaced** by **Xóchi** (axolotl).
* No gameplay logic changed. Enemies/tiles remain original.
* Run with: `pip install pygame && python main.py` from the project root.
* Player sprites now load from `img/xochi_sheet.png` via `sprites/Mario.json` (remapped frame coordinates).

**Download:** `xochi_side_scroller_v0_1.zip`
—> [sandbox:/mnt/data/xochi_side_scroller_v0_1.zip]

---

## 1) Project Layout (after unzip)

```
super-mario-python-master/
├─ main.py
├─ classes/
│  ├─ Sprites.py          # Loads JSON sprite packs → Sprite/Spritesheet/Animation
│  ├─ Animation.py, Sprite.py, Spritesheet.py, ...
│  ├─ Level.py, Camera.py, Collider.py, Input.py, ...
├─ entities/
│  ├─ Mario.py            # Player entity (still named Mario for now)
│  ├─ Goomba.py, Koopa.py, ...
├─ sprites/
│  ├─ Mario.json          # REMAPPED to Xóchi sheet
│  ├─ Goomba.json, Koopa.json, Animations.json, BackgroundSprites.json, ItemAnimations.json
├─ img/
│  ├─ xochi_sheet.png     # NEW 112×48 RGBA sprite sheet for Xóchi (16×16 & 16×32 frames)
│  ├─ characters.gif, koopas.png, tiles.png, Items.png   # originals, still used
├─ levels/
├─ sfx/
```

---

## 2) Runtime Requirements

* **Python**: 3.9+ recommended
* **Dependencies**: `pygame`

  ```bash
  pip install pygame
  ```
* **Run**:

  ```bash
  cd super-mario-python-master
  python main.py
  ```

**Controls**: same as original template (arrow keys to move, jump key per template’s Input.py). No changes in v0.1.

---

## 3) What Changed in v0.1 (and why it’s safe)

**Only the player sprite source changed**:

* **New sheet**: `img/xochi_sheet.png` (RGBA, 112×48)
* **Remapped**: `sprites/Mario.json`

  * `spriteSheetURL` → `./img/xochi_sheet.png`
  * `size` → `[16,16]` (base tile size)
  * Each `mario_*` and `mario_big_*` sprite now points to **new (x,y)** coords on `xochi_sheet.png`.
  * `scalefactor` kept at `2` for a 32×32 small on-screen look.
  * `colorKey: -1` → use PNG alpha (no magenta keying).

All code paths that referenced the Mario sprite names remain intact (e.g., `spriteCollection["mario_run1"]`), so **no Python code edits** were needed.

---

## 4) Xóchi Sprite Sheet Layout

**File:** `img/xochi_sheet.png` (112×48)

* **Row 1 (y=0), 16×16 “small” frames** — 7 columns:

  ```
  (0,0):   mario_idle
  (16,0):  mario_run1
  (32,0):  mario_run2
  (48,0):  mario_run3
  (64,0):  mario_break
  (80,0):  mario_jump
  (96,0):  mario_dead
  ```

* **Row 2 (y=16), 16×32 “big” frames** — 6 columns:

  ```
  (0,16):   mario_big_idle
  (16,16):  mario_big_run1
  (32,16):  mario_big_run2
  (48,16):  mario_big_run3
  (64,16):  mario_big_jump
  (80,16):  mario_big_break
  ```

**Frame sizes:**

* Small: `16×16`
* Big: `16×32` (explicit `xsize=16`, `ysize=32` in JSON for big frames)

---

## 5) Sprite Pack JSON (`sprites/Mario.json`)

Relevant fields used by `classes/Sprites.py` loader:

```json
{
  "spriteSheetURL": "./img/xochi_sheet.png",
  "type": "character",
  "size": [16, 16],
  "sprites": [
    {
      "name": "mario_idle",
      "x": 0, "y": 0,
      "scalefactor": 2, "colorKey": -1, "collision": false
    },
    {
      "name": "mario_run1",
      "x": 16, "y": 0,
      "scalefactor": 2, "colorKey": -1, "collision": false
    },
    ...
    {
      "name": "mario_big_break",
      "x": 80, "y": 16,
      "scalefactor": 2, "colorKey": -1, "collision": false,
      "xsize": 16, "ysize": 32
    }
  ]
}
```

**Loader path:**
`classes/Sprites.py` → `Sprites.loadSprites(urlList)` opens JSON, instantiates a `Spritesheet` with `spriteSheetURL`, and registers each sprite into `spriteCollection`.

**Where these are used:**
`entities/Mario.py` uses:

```python
spriteCollection = Sprites().spriteCollection
smallAnimation = Animation(
    [ spriteCollection["mario_run1"].image,
      spriteCollection["mario_run2"].image,
      spriteCollection["mario_run3"].image ],
    spriteCollection["mario_idle"].image,
    spriteCollection["mario_jump"].image,
)
bigAnimation = Animation(
    [ spriteCollection["mario_big_run1"].image,
      spriteCollection["mario_big_run2"].image,
      spriteCollection["mario_big_run3"].image ],
    spriteCollection["mario_big_idle"].image,
    spriteCollection["mario_big_jump"].image,
)
```

Since names didn’t change, animations pick up Xóchi frames automatically.

---

## 6) How to Swap In Your Own Xóchi Art (keep code stable)

1. Create your own `xochi_sheet.png` with the **same layout** or adjust `x,y` in `sprites/Mario.json`.

   * Small frames: 16×16, positions `(0..96 step 16, y=0)`
   * Big frames: 16×32, positions `(0..80 step 16, y=16)`
2. Maintain PNG **alpha** (no need for color key).
3. Keep the **same sprite names** in JSON (so code doesn’t change).
4. If you change sizes, update `size` at top and/or per-sprite `xsize/ysize`; ensure `Spritesheet.image_at()` supports it (it does).

---

## 7) Known Limits (v0.1 reality check)

* **Class names** still say “Mario” (e.g., `entities/Mario.py`). This is cosmetic; renaming will require search-and-replace and a quick smoke test.
* “Big” form frames are placeholder-style (functional, not polished).
* Enemies/tiles remain original. To re-theme enemies, repeat this process for `Goomba.json`, `Koopa.json`, etc., pointing to new sheets.
* No gameplay mechanics or physics have been modified.

---

## 8) Useful Code Entry Points for Cursor

* **Player entity:** `entities/Mario.py`

  * Movement traits: `traits/go.py`, `traits/jump.py`, `traits/leftrightwalk.py`
  * Collisions: `classes/Collider.py`, `classes/EntityCollider.py`
* **Sprite system:** `classes/Sprites.py`, `classes/Spritesheet.py`, `classes/Animation.py`, `classes/Sprite.py`
* **Input & Camera:** `classes/Input.py`, `classes/Camera.py`
* **Levels:** `classes/Level.py`, maps in `levels/`
* **Main loop:** `main.py`

If Xóchi appears as a black box:

* Confirm `img/xochi_sheet.png` path.
* Confirm `sprites/Mario.json` `spriteSheetURL` matches the path.
* Ensure `pygame` is installed and no console errors occur on load.

---

## 9) Quick Tasks Backlog (for v0.2+)

**Cosmetic rename**

* Rename `entities/Mario.py` → `entities/Xochi.py` and update imports.
* Update HUD strings (titles/menus) to “Xóchi”.

**Polish**

* Add more big-form frames (idle blink, landing, turnaround).
* Improve gill/tail animation timing.

**Theme pass (optional)**

* Swap `Goomba.json`, `Koopa.json` to themed birds/aquatic foes.
* Background palettes to Xochimilco style (see `BackgroundSprites.json`).

**Tech hygiene**

* Add `pygame.SCALED` or pixel-perfect scaling in `main.py`.
* Factor sprite-name constants into a small registry to avoid typos.

---

## 10) Sanity Checklist (Cursor CI)

* [ ] `python -m pip install pygame`
* [ ] Run `python main.py` at 60 FPS windowed (test on Win/macOS/Linux).
* [ ] Player idle/run/jump frames render (no magenta, no black boxes).
* [ ] Big form transitions draw with correct 16×32 frames.
* [ ] No missing file exceptions; JSON loads correctly.
* [ ] Zip integrity verified.

---

## 11) FAQ for Future You

**Q:** Can I increase sprite scale?
**A:** Change `scalefactor` in `sprites/Mario.json` (and ensure camera/collision don’t assume 32×32 screen size).

**Q:** Can I rearrange the sheet?
**A:** Yes—update each `x,y` in `sprites/Mario.json`. Keep frame sizes constant or provide `xsize/ysize`.

**Q:** Do I need color keys?
**A:** No—PNG alpha is used (`colorKey: -1`).

**Q:** Where do animations get their lists?
**A:** In `entities/Mario.py` where `smallAnimation`/`bigAnimation` are constructed from `spriteCollection[...]`.

---

## 12) Tough-love notes (so you don’t drift)

* Don’t rename sprite **names** unless you propagate changes in `entities/Mario.py` and any animation lists.
* Don’t mix frame sizes in the same animation row unless you know how `Spritesheet.image_at` clips—use `xsize/ysize`.
* Keep `xochi_sheet.png` small & aligned to 16-pixel grid; misalignment leads to jitter and bleeding.

---

If you need me to **rename the player to `Xochi` in code**, update the HUD strings, or theme the enemies next, say the word and I’ll produce a v0.2 patch.

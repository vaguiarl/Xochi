# Xochi — Project Bible

> Last updated: 2026-02-18 (after audit + critical bug fixes + asset cleanup)
> Branch: `xochi-2.0` | Deployed: GitHub Pages (`gh-pages` branch)

## What Is Xochi

A 2D platformer inspired by DKC, set in Mesoamerican mythology (Xochimilco, Day of the Dead, Aztec warriors). The player controls Xochi, an axolotl warrior navigating 11 levels across 6 worlds — fighting enemies, collecting cempasuchil flowers, and rescuing baby axolotls.

Originally built in Phaser 3, now rebuilt in Godot 4 (`xochi-godot/`). The Godot version is the active codebase. The old Phaser implementation has been removed from the active repo and survives only in git history and the `old-phaser-web-backup` tag.

---

## Repo Layout

```
/Users/victoraguiar/Documents/GitHub/Xochi/
├── xochi-godot/          # ACTIVE — Godot 4 rebuild (this is the game)
│   ├── project.godot
│   ├── autoloads/        # 5 singletons
│   ├── scenes/           # 8 .tscn + .gd scene files
│   ├── scripts/          # entities, systems, levels, managers
│   ├── assets/           # sprites, audio (music + sfx)
│   ├── build/web/        # Godot web export output
│   ├── export_presets.cfg
│   └── CLAUDE.md         # AI coding instructions
├── nanoart/              # Source art files from nano banana
└── xochi.md              # THIS FILE
```

---

## Tech Stack

- **Engine**: Godot 4.6 stable, GDScript only (no C#, no TypeScript)
- **Player/Enemies**: CharacterBody2D
- **Platforms**: StaticBody2D (one-way collision in upscroller levels)
- **Trajineras**: AnimatableBody2D (one-way collision, moving boats)
- **Export**: Web only (no-threads), deployed to GitHub Pages
- **Art pipeline**: ImageMagick 7 (`/opt/homebrew/bin/magick`) for sprite processing
- **Source art**: `/Users/victoraguiar/Documents/GitHub/Xochi/nanoart/`

---

## Architecture

### Autoloads (load order matters)

| Autoload | File | Purpose |
|---|---|---|
| ViewportManager | `autoloads/viewport_manager.gd` | Responsive layout, orientation, resize signals |
| Events | `autoloads/events.gd` | Global signal bus (19 signals, decoupled communication) |
| GameState | `autoloads/game_state.gd` | Player progress, difficulty, worlds, save/load JSON |
| AudioManager | `autoloads/audio_manager.gd` | Music per world (crossfade), SFX pool (4 players) |
| SceneManager | `autoloads/scene_manager.gd` | Fade transitions between scenes |

### Scenes

| Scene | File | Purpose |
|---|---|---|
| Main | `scenes/main/main.gd` | Entry point |
| Menu | `scenes/menu/menu_scene.gd` | Title screen, difficulty select |
| Story | `scenes/story/story_scene.gd` | Intro narrative |
| Game | `scenes/game/game_scene.gd` | **Core gameplay** (~2200 lines) |
| Pause | `scenes/pause/pause_scene.gd` | Pause overlay |
| End | `scenes/end/end_scene.gd` | Victory screen, confetti, baby parade |
| Test Level | `scenes/game/test_level.gd` | Dev testing |

### Entity Scripts (`scripts/entities/`)

| Entity | File | Type | HP | Score | Visual |
|---|---|---|---|---|---|
| Player | `player.gd` | CharacterBody2D | 3 lives | — | PNG sprites |
| EnemyBase | `enemy_base.gd` | CharacterBody2D | 1 | 100 | Base class |
| Gull | `gull.gd` | extends EnemyBase | 1 | 100 | ColorRect |
| Heron | `heron.gd` | extends EnemyBase | 1 | 100 | ColorRect + projectiles |
| Crowquistador | `crowquistador.gd` | extends EnemyBase | 1 | 100 | PNG rig (10 parts) |
| Ahuizotl | `ahuizotl.gd` | CharacterBody2D | 1 | 100 | ColorRect (water enemy) |
| Rabbitbrije | `rabbitbrije.gd` | CharacterBody2D | 1 | 50 | PNG sprite |
| Calaca | `calaca.gd` | CharacterBody2D | 1 | 75 | PNG sprite |
| Jaguar Warrior | `jaguar_warrior.gd` | CharacterBody2D | 2 | 200 | ColorRect rig |
| DarkXochi (Boss) | `boss.gd` | CharacterBody2D | 4-7 | — | ColorRect |

### System Scripts (`scripts/systems/`)

| System | Purpose |
|---|---|
| `combat_system.gd` | Stomp detection, melee, thunderbolt projectiles |
| `enemy_spawner.gd` | Dynamic `load()` of all enemy types from level data |
| `water_system.gd` | Rising water (upscroller), DKC2 swimming mechanics |
| `escape_system.gd` | Escape level camera chase logic |
| `collectible_system.gd` | Flowers, elotes, powerups, baby rescue |
| `luchador_system.gd` | Luchador power-up (invincibility + strength) |
| `inertial_deformer.gd` | Procedural squash/stretch/skew animation |

### Level Data (`scripts/levels/level_data.gd`)

All 11 levels are **handcrafted static data** (no procedural generation in production).

| Level | World | Name | Type | Size |
|---|---|---|---|---|
| 1 | 1 Canal Dawn | Floating Gardens Tutorial | Side-scroll | 2400x600 |
| 2 | 1 Canal Dawn | Floating Gardens Advanced | Side-scroll | 3200x600 |
| 3 | 2 Bright Trajineras | Upscroller - Ruins Entry | Upscroller | 800x2000 |
| 4 | 2 Bright Trajineras | Ancient Ruins | Side-scroll | 3200x700 |
| 5 | 3 Crystal Cave | Crystal Cave Boss | Boss arena | 1200x800 |
| 6 | 4 Floating Gardens | Night Canals | Side-scroll | 3000x700 |
| 7 | 4 Floating Gardens | Floating Gardens Escape | Escape | 3500x700 |
| 8 | 5 Night Canals | Night Canals Upscroller | Upscroller | 800x2500 |
| 9 | 5 Night Canals | Night Canals Escape | Escape | 4000x700 |
| 10 | 6 La Fiesta | La Fiesta Boss Arena | Boss arena | 1400x900 |
| 11 | 6 La Fiesta | La Gran Fiesta | Fiesta (celebration) | 3000x600 |

### World-Level Mapping (GameState.get_world_for_level)

```
Levels 1-2  → World 1 (Canal Dawn)
Levels 3-4  → World 2 (Bright Trajineras)
Level  5    → World 3 (Crystal Cave) — boss
Levels 6-7  → World 4 (Floating Gardens)
Levels 8-9  → World 5 (Night Canals)
Levels 10-11 → World 6 (La Fiesta)
```

### World → Music Mapping

| World | Track Key | File |
|---|---|---|
| 1 Canal Dawn | `music_menu` | `music_menu.ogg` |
| 2 Bright Trajineras | `music_world3` | `music_world3.ogg` |
| 3 Crystal Cave | `music_upscroller` | `music_upscroller.ogg` |
| 4 Floating Gardens | `music_night` | `music_night.ogg` |
| 5 Night Canals | `music_boss` | `music_boss.ogg` |
| 6 La Fiesta | `fiesta_de_xochi` | `fiesta_de_xochi.ogg` |

Music plays per world (not per level). AudioManager checks `current_track` to avoid restarts on death/retry.

---

## Physics (Celeste-inspired)

| Constant | Value | Notes |
|---|---|---|
| WALK_SPEED | 220 px/s | |
| RUN_SPEED | 340 px/s | |
| JUMP_VELOCITY | -480 | Max jump ~144px |
| GRAVITY | 800 px/s^2 | |
| FALL_GRAVITY_MULT | 1.6x | Asymmetric — falls faster than rises |
| APEX_GRAVITY_MULT | 0.4x | Hang time near jump peak (hold jump) |
| COYOTE_TIME | 0.20s | Generous grace period after leaving edge |
| JUMP_BUFFER | 0.15s | Pre-land jump buffering |
| CORNER_CORRECTION | 8px | Nudge when bonking corners |
| Platform gaps | max 130px | Comfortable reachability limit |

---

## Key Patterns & Rules

### Combat (duck typing)
```gdscript
# Stomp detection
if enemy.has_method("hit_by_stomp"):
    enemy.hit_by_stomp()
# Alive check
if enemy.get("alive"):
    # still kicking
```

### System lifecycle
```gdscript
system.setup(scene, player, enemies)  # Wire up
# runs in _physics_process(delta)
system.destroy()                       # Cleanup
```

### Loading rules
- **NEVER** use `preload()` — all resources use runtime `load()`
- **ALL** enemies dynamically loaded via `EnemySpawner._safe_load()`
- If `load()` returns null, `continue` (graceful degradation)

### class_name rules
**ONLY** these scripts may have `class_name`:
- `EnemyBase`, `Player`, `DarkXochi`
- All system scripts (`CombatSystem`, `WaterSystem`, etc.)
- `LevelData`, `TouchInputManager`

**NEVER** give `class_name` to dynamically-loaded enemy scripts (gull, heron, crowquistador, ahuizotl, jaguar, rabbitbrije, calaca). This prevents cascade failures from the class cache.

### Class cache
`.godot/global_script_class_cache.cfg` must exist for the game to run. **Never delete it entirely.** Edit it to remove stale entries. Godot only regenerates it on editor restart.

### Godot 4.6 type gotchas
- `abs()` returns Variant → use `absf()` for floats, `absi()` for ints
- Same for `sign()` → `signf()`/`signi()`, `clamp()` → `clampf()`/`clampi()`
- `var x := abs(...)` is a parse error in strict mode

---

## Assets Inventory (after cleanup)

### Music (9 tracks, ~31 MB total)
All `.ogg` in `assets/audio/music/`. Bitrates 157-253 kbps, durations 108-227s.

### SFX (8 effects, ~96 KB total)
`jump`, `jump_super`, `land`, `stomp`, `hurt`, `flower`, `menu_select`, `powerup`

### Sprites
- **Player**: `xochi_walk/run/jump/attack.png` + `big_xochi_big/idle_small.png`
- **Crowquistador**: 10 part PNGs in `prerendered/enemies/crowquistador_parts/`
- **Rabbitbrije**: `rabbitbrije.png` (PNG sprite, scaled to ~50px)
- **Calaca**: `calaca.png` (PNG sprite)
- **Collectibles**: `baby_axolotl.png`, `elote.png`, `flower.png`, `powerup.png`
- **Trajineras**: `trajinera_1/2/3.png` (prerendered 3D side-view)

### What still uses ColorRect (no sprites yet)
Gull, Heron, Ahuizotl, Jaguar Warrior, DarkXochi (Boss), all platforms, sky/background.

---

## Deployment

- **Platform**: Web only (GitHub Pages)
- **Branch**: `gh-pages` (flat files at root: `index.html`, `index.js`, `index.wasm`, `index.pck`)
- **Export preset**: "Web" in `export_presets.cfg`, no-threads template
- **Build command**: `godot --headless --path . --export-release "Web" build/web/index.html`
- **Deploy process**: Build → checkout `gh-pages` → copy `build/web/*` to root → commit → push
- **Current .pck size**: ~39 MB (under GitHub's 50 MB recommendation)

---

## Known Issues (moderate, not yet fixed)

| # | Issue | File:Line | Impact |
|---|---|---|---|
| 1 | Score display always "+100" regardless of enemy type | `combat_system.gd:91` | Visual only |
| 2 | Audio fallback `"music_gardens"` not in `MUSIC_PATHS` | `audio_manager.gd:148` | Silent fail for invalid world |
| 3 | Thunderbolt lambda lacks `is_instance_valid()` check | `combat_system.gd:147` | Rare crash on bolt expiry |
| 4 | Heron inline projectile may double-move | `heron.gd:151-169` | Projectile speed |
| 5 | End scene no null check on sprite load | `end_scene.gd:287` | Crash if file missing |
| 6 | End scene shows min 1 baby even if 0 rescued | `end_scene.gd:211` | Minor |
| 7 | Calaca `_sprite = null` in placeholder | `calaca.gd:489` | Direction flip broken |
| 8 | Crossfade volume not updated by `set_music_volume()` | `audio_manager.gd:206` | Volume glitch during crossfade |
| 9 | Debug `print()` on every resize | `viewport_manager.gd:89` | Console noise |
| 10 | Dead signals: `life_lost`, `super_jump_gained` | `events.gd` | Unused code |
| 11 | `game_won` emitted but nothing listens | `game_scene.gd:1661` | No game-won handling |
| 12 | Menu doesn't reflow on resize | `menu_scene.gd:738` | Layout breaks on resize |
| 13 | `level_data_backup.gd` dead code | `scripts/levels/` | Cleanup |
| 14 | `crowquistador.png` (full sprite) unused | `prerendered/enemies/` | 744K wasted |
| 15 | `export_web.sh` references preset `HTML5` not `Web` | `export_web.sh` | Script broken |

---

## Unused Enemy Scripts (written but not in any level)

- **Jaguar Warrior** (`jaguar_warrior.gd`) — Complete 4-state AI (patrol/stalk/pounce/recover), 2-hit HP. Ready to add to mid/late levels.
- **Heron** (`heron.gd`) — Complete with projectile attacks. Ready to add.
- **Gull ground type** — Only `"platform"` variant used (level 4). `"ground"` type untested in levels.

---

## Recommended Next Steps

### Phase 10 — Polish
1. Wire up pause trigger (ESC → PauseScene, noted as TODO in Phase 9)
2. Fix moderate issues from the table above
3. Implement ledge grab system (planned in `LEDGE_SYSTEM_PLAN.md`)
4. Replace ColorRect enemies with proper sprites (Gull, Heron, Ahuizotl, Jaguar, Boss)
5. Add Jaguar Warrior and Heron to level data for enemy variety
6. Fix score display to show correct per-enemy values

### Phase 11 — Content
7. Add missing SFX (water splash, baby rescue, enemy death)
8. Unique World 1 music (currently shares menu track)
9. Save system — `GameState` has save/load scaffolding but not wired to level progression
10. Wire `game_won` signal to victory flow

### Phase 12 — Platform Expansion
11. Mobile export presets (code already has touch input, orientation handling)
12. Enable PWA in export settings (single toggle)
13. Gamepad/controller bindings (only keyboard mapped currently)

---

## Custom Claude Skills (slash commands)

Located in `xochi-godot/.claude/commands/`:

| Command | Purpose |
|---|---|
| `/project:integrate-sprite` | Process sprites with ImageMagick green screen removal |
| `/project:deploy` | Build verification and deployment (written for old web version, needs update) |
| `/project:audit-game` | Comprehensive code audit |
| `/project:add-world` | Add complete world with levels, music, theming |
| `/project:add-level` | Add level with platforms, enemies, collectibles |
| `/project:add-enemy` | Add enemy type with AI, visuals, combat integration |

---

## Critical Gotchas (read before touching anything)

1. **class_name cascade**: Adding `class_name` to a dynamically-loaded enemy breaks ALL enemies. Only the allowed scripts (listed above) may have it.
2. **Zero preload()**: Every `preload()` is a potential crash if import cache is stale. Always use `load()`.
3. **Class cache**: Never delete `.godot/global_script_class_cache.cfg`. Edit out stale entries only.
4. **Boundary direction**: Wall reversal must check direction first (`if dir > 0: dir = -1`), never `dir *= -1` (causes jitter).
5. **Water position**: Starts at `level_height - 20` (not +50).
6. **Camera2D**: Use `get_screen_center_position()`, NOT `get_screen_center_of_mass()`.
7. **Music per world**: AudioManager checks `current_track` to avoid restarts. Don't call `play_music()` with a new key unless you want to change the song.
8. **Upscroller platforms**: Levels 3 and 8 use `one_way_collision = true` on platforms so Xochi can jump through from below (same as trajineras).

---

## Signals Reference (Events autoload)

```
# Collectibles
flower_collected(count), elote_collected(level, index), baby_rescued(level)

# Player
player_hit, player_died, life_lost*, super_jump_used, super_jump_gained*, mace_attack_used

# Combat
player_attacked(position, direction), thunderbolt_fired(position, direction)

# Boss
boss_damaged(health, max_health), boss_defeated

# Progression
level_completed(level_num), score_changed(score)

# Luchador
luchador_activated, luchador_ended

# Game state
game_over, game_won*, game_paused, game_resumed

* = declared but currently unused
```

---

## Git History (recent)

```
255e022 Remove orphaned assets to shrink web build (52MB -> 39MB)
e4c0053 Fix 6 critical bugs + one-way platforms in upscroller levels
c5aa161 Fix mobile touch support and improve game UX
0db0b0b Fix enemy spawner cascade failure and Godot 4.6 type inference errors
40d4e17 Fix: dynamic load ALL enemies to prevent cascade failures
65e5ebc Crowquistador Kirby Sword Knight AI: 6-state personality rewrite
```

---

## Running & Deploying

```bash
# Play in editor
godot --path /Users/victoraguiar/Documents/GitHub/Xochi/xochi-godot scenes/main/main.tscn

# Deploy to GitHub Pages (one command — builds, copies, pushes, switches back)
cd /Users/victoraguiar/Documents/GitHub/Xochi/xochi-godot
./deploy.sh "description of what changed"
```

### What `deploy.sh` does
1. Verifies you're on `xochi-2.0` with no uncommitted changes in `xochi-godot/`
2. Runs `godot --headless --export-release "Web"` to build `build/web/`
3. Checks `.pck` size (warns if over 50MB)
4. Stashes, switches to `gh-pages`, copies all build files to root
5. Commits and pushes to `gh-pages`
6. Switches back to `xochi-2.0` and pops stash
7. Skips deploy if nothing changed (no-op guard)

After deploy, **hard-refresh** (`Cmd+Shift+R`) to bypass browser cache.

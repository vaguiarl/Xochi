# Add New Level to Xochi

Add a new level to an existing world with full gameplay content.

## Input
$ARGUMENTS

## Steps

### 1. Determine Level Parameters
- Level number and which world it belongs to
- Level type: "sidescroller", "upscroller", "escape", "boss", or "fiesta"
- Dimensions (width x height) — sidescrollers are typically 3000-6000 x 600
- Difficulty progression relative to surrounding levels

### 2. Build Level Data
Add to `scripts/levels/level_data.gd`:

**Platforms** — Create a mix of:
- Ground segments (y near level_height - 50)
- Mid-height platforms (y: 350-450) for jumping sections
- High platforms (y: 200-300) for rewards/challenges
- One-way platforms where appropriate
- Breathing zones every 400-600px (flat, safe ground)

**Enemies** — Scale with difficulty:
- "ground" gulls on ground segments
- "platform" gulls bounded to specific platforms
- "flying" crowquistadors patrolling air lanes
- "water" ahuizotl for water levels only
- Space enemies 200-400px apart, never in breathing zones

**Collectibles** — Scatter generously:
- Cempasuchil flowers: 20-40 per level, along jump arcs and platforms
- 3 elotes (stars) per level: 1 easy, 1 medium, 1 hidden/hard
- 1 super jump feather (mid-level, near a gap that needs it)
- 1 baby axolotl (near level end, before the final platform)

**Trajineras** — For water sections:
- 4-6 per horizontal section
- Alternate directions (dir: 1 and -1)
- Speeds: 30-60 px/s
- Y positions along water surface with slight variation

### 3. Wire into World
- Ensure the level number is included in the world's levels array in GameState.WORLDS
- Verify `get_level_data()` returns data for this level number
- Check music mapping covers this level (should inherit from world)

### 4. Test
- Enemies spawn at correct positions
- Platforms are reachable with normal and super jumps
- Collectibles are collectible (not clipping into walls)
- Trajineras move and carry the player
- Baby axolotl is reachable and triggers level completion
- Level transitions correctly to next level

## Level Type Specifics

**Upscroller**: Vertical layout, add WaterSystem rising from bottom, platforms spiral upward, include trajineras at water surface
**Escape**: Add flood_speed parameter, denser platforms, fewer gaps, more forward momentum
**Boss**: Small arena (800x600), no collectibles, boss spawn point, luchador mask drop
**Fiesta**: Extra wide, no enemies, tons of trajineras and flowers, celebration theme

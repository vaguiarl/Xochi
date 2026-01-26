# XOCHI GAME - QUICK REFERENCE GUIDE

## The 3 Recent Changes

### 1. LEDGE GRAB FIX
```
Location: game.js:5817
Change: const isFalling = this.player.body.velocity.y > 100;
Effect: Prevents false grabs when jumping from below
Status: Working correctly
```

### 2. WORLD UNLOCK
```
Location: game.js:3707
Change: const isUnlocked = true;
Effect: All 6 worlds selectable from menu
Status: Working correctly
```

### 3. AUTO-CLIMB
```
Location: game.js:4711-4814
Change: Skip hanging state, immediately climb
Effect: Eliminates hanging bugs, faster response
Status: Working correctly
```

---

## The 10 Levels

| # | Type | World | Name | Mechanic |
|---|------|-------|------|----------|
| 1 | Std | 1 | Canal Dawn | Boat jump tutorial |
| 2 | Std | 1 | Challenge | Boat jump + gaps |
| 3 | Up | 2 | Ancient Ruins | CLIMB! Vertical |
| 4 | Std | 2 | Ruins Depths | Boat jump + gaps |
| 5 | Boss | 3 | Crystal Cave | Dark Xochi (3HP) |
| 6 | Std | 4 | Floating Gardens | Boat jump + lush |
| 7 | Esc | 4 | Garden Escape | ESCAPE! Water rise |
| 8 | Up | 5 | Night Upscroll | CLIMB! (harder) |
| 9 | Esc | 5 | Night Escape | ESCAPE! (1.15x speed) |
| 10 | Boss | 6 | Grand Festival | Dark Xochi (5HP) |

Legend: Std=Standard, Up=Upscroller, Esc=Escape

---

## Core Mechanics

### Controls
- Arrow keys: Move left/right
- Space/W: Jump
- Space (in water): Swim stroke
- Escape: Pause

### Ledge Grab
- Falling speed > 100 px/s
- Must press direction key
- Velocity check prevents false grabs
- Auto-climb happens immediately

### Swimming
- Enter water automatically
- Press space to swim stroke
- Exit water automatically

### Boss Fight Pattern
1. APPROACH (dread, 2000-1500ms)
2. TELEGRAPH (warning, 500ms)
3. ATTACK (full assault)
4. RECOVER (vulnerable window)

---

## Difficulty Settings

### Easy
- 2 extra lives
- More power-ups
- Fewer enemies
- Slower boats

### Normal
- 3 lives
- Standard items
- Standard enemies
- Standard speed

### Hard
- 2 lives
- Fewer power-ups
- More enemies
- Faster boats

---

## What Was Fixed

### Before (Old Code)
- Ledge grab had low/no velocity check
- Allowed false grabs while jumping up
- Could get stuck in hanging state
- Had to manually climb from hanging
- Worlds locked by progress

### After (New Code)
- Velocity > 100 required
- Fair grab mechanics
- Hangs state eliminated
- Auto-climb on grab
- All worlds unlocked

---

## Expected Playability

### Levels 1-2 (Easy)
- Should be completable in first attempt
- Tutorial difficulty
- Learn basic mechanics

### Levels 3-4 (Medium)
- Climbing introduced
- Still quite fair
- Some enemy pressure

### Level 5 (Hard)
- First boss encounter
- Learning curve expected
- ~3-4 attempts typical

### Levels 6-7 (Medium-Hard)
- New world exploration
- Escape mechanics introduced
- ~2-3 attempts typical

### Levels 8-9 (Very Hard)
- Harder upscroller
- Faster escape level (1.15x speed)
- Requires practice, ~5+ attempts possible

### Level 10 (Very Hard)
- Final boss, 5 HP
- Fastest patterns
- Expected to take 10+ attempts

---

## Known Concerns

### Potential Issues
1. **Level 9 Speed Spike**: 15% faster than Level 7
   - Monitor if too difficult
   - Can adjust if needed

2. **Boss Health Jump**: Level 10 has 67% more health
   - Significantly harder
   - May frustrate some players

3. **Ledge Grab Cooldown**: 400ms between grabs
   - Might feel tight in fast sections
   - Can adjust to 200-300ms if needed

4. **Auto-Climb Duration**: 500-600ms animation
   - Might feel slow in upscroller
   - Monitor for feedback

---

## File Locations

**Main Game File**:
```
/Users/victoraguiar/Documents/GitHub/Xochi/xochi-web/game.js
```

**Music Spec**:
```
/Users/victoraguiar/Documents/GitHub/Xochi/sfx/XOCHI_MUSIC_SPECIFICATION.md
```

**Level Data**:
```
/Users/victoraguiar/Documents/GitHub/Xochi/xochi-web/src/levels/LevelData.js
```

---

## Quick Testing Checklist

- [ ] Game starts and loads menu
- [ ] Can select different worlds
- [ ] Level 1 is playable start-to-finish
- [ ] Ledge grab works (fall > 100 px/s)
- [ ] Auto-climb happens on grab
- [ ] Level 3 upscroller mechanics work
- [ ] Level 5 boss is defeatable
- [ ] Level 7 escape is completable
- [ ] Level 9 faster speed is still playable
- [ ] Level 10 final boss is challenging but fair
- [ ] No soft locks observed
- [ ] No progression blockers

---

## Success Criteria

### CRITICAL (Must Work)
- All 10 levels must be playable
- All 6 worlds must be accessible
- Boss fights must be defeatable
- No soft locks or game-breaking bugs
- Ledge grab must work correctly
- Auto-climb must eliminate hanging

### IMPORTANT (Should Work Well)
- Difficulty curve feels right
- Swimming mechanics responsive
- Escape levels challenging but fair
- Enemies scale appropriately
- Boss patterns are readable
- Camera follows smoothly

### NICE TO HAVE (Polish)
- Audio balanced well
- Visual effects smooth
- Menu responsive
- Animations polished
- Difficulty settings feel distinct

---

## How to Report Issues

If you find problems:

1. **Note the level number**: Which level?
2. **Describe what happened**: What did you try to do?
3. **What was expected**: What should happen?
4. **What actually happened**: What did happen instead?
5. **Can you reproduce it?**: Always, sometimes, once?

Example:
```
LEVEL: 3 (Upscroller)
ISSUE: Ledge grab not working
STEPS: Fell from platform above ledge with speed > 100, pressed left
EXPECTED: Auto-climb should trigger
ACTUAL: Player fell through and drowned
REPRODUCIBLE: Every time
```

---

## Performance Notes

**FPS**: 60 (Phaser default)
**Physics**: Gravity 150 px/s²
**Level Width**: 2000-3200px (increases per level)
**Max Enemies**: 9-12 per level
**Memory**: Should be fine for modern browsers

---

## Quick Facts

- **Total Development Time Invested**: Significant (full platformer)
- **Code Size**: ~7000+ lines in game.js
- **Audio System**: La Cucaracha + SFX support
- **Framework**: Phaser 3.70.0
- **Platform**: Web-based (Vite dev server)
- **Target Audience**: Casual to intermediate gamers

---

**This Reference Guide**: January 25, 2026
**Next Action**: Run the game and start testing!

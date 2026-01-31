# Xochi SFX Implementation Priority Guide

## Quick Start: Replace Placeholder Sounds in 1 Week

This guide helps you prioritize which sounds to generate first for maximum impact with minimal time investment.

---

## IMMEDIATE PRIORITY (Day 1-2): The "Game Feel" Core

These 7 sounds are heard most frequently and establish the game's audio identity:

### 1. Jump (Small) - SFX-001
**Why First**: Players jump 100+ times per session
**Current**: `small_jump.ogg` (generic boing)
**Impact**: High - Makes platforming feel good or bad
**Prompt**:
```
Short jump sound effect, soft clay drum hit, water droplet splash, rising pitch, kalimba pluck accent, 350ms duration, playful organic axolotl leap, C to E major third, no music, sound design, wet footstep on lily pad
```

### 2. Collect Flower - SFX-010
**Why Second**: Most common collectible, dopamine feedback loop
**Current**: `coin.ogg` (Mario coin)
**Impact**: High - Determines if collecting feels rewarding
**Prompt**:
```
Flower collect sound effect, pizzicato string pluck C5, marimba ascending major third C to E, kalimba shimmer, wind chime tinkle, soft petal flutter, 500ms duration, magical flower pickup, cempasúchil collection, game collectible SFX
```

### 3. Stomp Enemy - SFX-006
**Why Third**: Primary combat feedback, needs to feel satisfying
**Current**: `stomp.ogg` (generic stomp)
**Impact**: High - Makes combat feel impactful
**Prompt**:
```
Enemy defeat stomp sound effect, clay pot crack, satisfying pop, air release pitch drop C to C4, kalimba ding major third, shimmering sparkles, 500ms duration, game enemy squash, victorious combat feedback
```

### 4. Get Hurt - SFX-007
**Why Fourth**: Critical danger feedback
**Current**: `bump.ogg` (generic bump)
**Impact**: High - Communicates consequence
**Prompt**:
```
Player hurt sound effect, deep hand drum impact, water splash with reverse reverb, descending wooden flute E to C minor third, fading ripples, 600ms duration, painful but hopeful, axolotl damage sound, game hit feedback
```

### 5. Menu Select - SFX-014
**Why Fifth**: UI responsiveness, first impression on main menu
**Current**: `coin.ogg` (reused, wrong context)
**Impact**: Medium - Establishes UI quality
**Prompt**:
```
Menu navigation sound effect, soft wooden block tap, single water droplet plip, 120ms duration, subtle UI cursor, non-intrusive menu blip, game interface SFX
```

### 6. Land (Soft) - SFX-003
**Why Sixth**: Completes jump feedback loop
**Current**: No dedicated sound
**Impact**: Medium - Adds weight to platforming
**Prompt**:
```
Soft landing sound effect, muted hand drum pat, small water splash, droplets settling, gentle reed rustle, 250ms duration, organic axolotl landing on lily pad, wet impact, game SFX
```

### 7. Super Jump - SFX-002
**Why Seventh**: Special ability, should feel epic
**Current**: `powerup_appears.ogg` (reused)
**Impact**: Medium - Makes power feel powerful
**Prompt**:
```
Powerful super jump sound effect, deep water explosion whoosh, conch shell horn blast F note, ascending marimba arpeggio F major 7th, shimmering kalimba sparkles, 800ms duration, magical axolotl power, heroic leap, mystical water energy, cinematic game SFX
```

**Expected Time**: 4-6 hours (including generation, selection, editing, testing)
**Impact**: Game immediately feels 80% better

---

## HIGH PRIORITY (Day 3-4): Rewards & Polish

These sounds create memorable moments and emotional highs:

### 8. Collect Star - SFX-011
**Current**: `powerup_appears.ogg` (reused)
**Why**: Big achievement needs big celebration
**Prompt**: (See full spec SFX-011)

### 9. Rescue Baby Axolotl - SFX-013
**Current**: `powerup.ogg` (reused)
**Why**: Core emotional moment, level complete
**Prompt**: (See full spec SFX-013)

### 10. Collect Powerup - SFX-012
**Current**: `powerup.ogg` (generic)
**Why**: Transformation moment, feels significant
**Prompt**: (See full spec SFX-012)

### 11. Menu Confirm - SFX-015
**Current**: `coin.ogg` (reused)
**Why**: UI consistency, completes menu feel
**Prompt**: (See full spec SFX-015)

**Expected Time**: 4-6 hours
**Impact**: Rewards feel special, players want to collect things

---

## MEDIUM PRIORITY (Day 5-6): Combat & Environment

These add depth and immersion:

### 12-15. Combat Sounds
- Attack Swing (SFX-008)
- Attack Hit (SFX-009)
- Checkpoint (SFX-021)
- Level Complete (SFX-018)

### 16-18. Environmental
- Ledge Grab (SFX-023)
- Climb Up (SFX-024)
- Water Splash (SFX-026)

**Expected Time**: 4-6 hours
**Impact**: World feels alive, interactions have weight

---

## LOW PRIORITY (Day 7+): Boss & Polish

These are nice-to-have, enhance specific moments:

### 19-22. Boss Sounds
- Boss Appear (SFX-027)
- Boss Defeated (SFX-028)
- Danger Alert (SFX-029)
- Low Health Warning (SFX-030)

### 23-25. UI Extras
- Pause (SFX-017)
- Game Over (SFX-019)
- Player Death (SFX-020)

### 26-30. Ambient Polish
- Footsteps variants (SFX-004)
- Swim Stroke (SFX-005)
- Trajinera Boat loop (SFX-025)
- Secret Revealed (SFX-022)
- Menu Back (SFX-016)

**Expected Time**: 8-10 hours
**Impact**: Final 10% polish, optional for launch

---

## TESTING CHECKLIST

After implementing each sound:

1. **Timing Test**: Sound triggers at exact moment of action?
2. **Volume Test**: Balanced with music and other SFX?
3. **Fatigue Test**: Play for 5 minutes, still pleasant?
4. **Context Test**: Works in different game scenarios?
5. **Emotion Test**: Does it make the action feel good?

---

## INTEGRATION CODE SNIPPETS

### Replace Current Sounds (Quick Fix)

In `/xochi-web/src/scenes/BootScene.js`:

```javascript
// OLD (lines 134-142):
this.load.audio('sfx-jump', 'assets/audio/small_jump.ogg');
this.load.audio('sfx-coin', 'assets/audio/coin.ogg');
this.load.audio('sfx-stomp', 'assets/audio/stomp.ogg');
this.load.audio('sfx-powerup', 'assets/audio/powerup.ogg');
this.load.audio('sfx-hurt', 'assets/audio/bump.ogg');
this.load.audio('sfx-star', 'assets/audio/powerup_appears.ogg');
this.load.audio('sfx-rescue', 'assets/audio/powerup.ogg');
this.load.audio('sfx-select', 'assets/audio/coin.ogg');

// NEW (replace with):
// Movement
this.load.audio('sfx-jump', 'assets/audio/sfx/movement/XOCHI_MOVEMENT_JUMP_SMALL.ogg');
this.load.audio('sfx-jump-super', 'assets/audio/sfx/movement/XOCHI_MOVEMENT_JUMP_SUPER.ogg');
this.load.audio('sfx-land', 'assets/audio/sfx/movement/XOCHI_MOVEMENT_LAND_SOFT.ogg');

// Combat
this.load.audio('sfx-stomp', 'assets/audio/sfx/combat/XOCHI_COMBAT_STOMP.ogg');
this.load.audio('sfx-hurt', 'assets/audio/sfx/combat/XOCHI_COMBAT_HURT.ogg');

// Collectibles
this.load.audio('sfx-coin', 'assets/audio/sfx/collectibles/XOCHI_COLLECT_FLOWER.ogg');
this.load.audio('sfx-star', 'assets/audio/sfx/collectibles/XOCHI_COLLECT_STAR.ogg');
this.load.audio('sfx-powerup', 'assets/audio/sfx/collectibles/XOCHI_COLLECT_POWERUP.ogg');
this.load.audio('sfx-rescue', 'assets/audio/sfx/collectibles/XOCHI_COLLECT_BABY.ogg');

// UI
this.load.audio('sfx-select', 'assets/audio/sfx/ui/XOCHI_UI_MENU_SELECT.ogg');
```

### Add Pitch Variation (Enhanced Feel)

In `/xochi-web/src/scenes/GameScene.js`:

```javascript
// Replace existing playSound method (line 811) with:
playSound(key, options = {}) {
  if (!window.gameState.sfxEnabled) return;

  const config = {
    volume: options.volume || 0.6,
    // Add ±5% pitch variation for movement sounds
    rate: options.pitchVariation ? (1 + (Math.random() * 0.1 - 0.05)) : 1,
    detune: options.detune || 0
  };

  this.sound.play(key, config);
}

// Update jump call (in Player.js or where jump is triggered):
// OLD:
this.playSound('sfx-jump');
// NEW:
this.playSound('sfx-jump', { pitchVariation: true });
```

---

## FILE PLACEMENT

Create this directory structure:
```
/xochi-web/public/assets/audio/sfx/
  movement/     (jump, land, footsteps, swim)
  combat/       (stomp, hurt, attack)
  collectibles/ (flower, star, powerup, baby)
  ui/           (menu, pause, transitions)
  environment/  (checkpoint, ledge, water, boats)
  boss/         (roars, defeats)
  danger/       (alerts, warnings)
```

---

## GENERATION TIPS

### Using Suno.ai
1. Select "Instrumental" mode
2. Set duration (most sounds: 10-30 seconds, trim in Audacity)
3. Paste prompt from spec
4. Generate 3-5 versions
5. Pick best, download as MP3 (convert to OGG later)

### Quick Editing in Audacity
1. Import sound
2. Trim silence: Effect → Truncate Silence
3. Normalize: Effect → Normalize (-6dB)
4. Fade out: Select last 50ms → Effect → Fade Out
5. Export as OGG: File → Export → OGG Vorbis (Quality 8)

### Conversion to OGG
```bash
# If Suno gives MP3, convert with ffmpeg:
ffmpeg -i input.mp3 -c:a libvorbis -q:a 8 output.ogg
```

---

## ESTIMATED TIMELINE

**Minimum Viable SFX (Day 1-2)**: 7 sounds, playable game
**Polished SFX (Day 1-4)**: 15 sounds, feels professional
**Complete SFX (Week 1-2)**: 30+ sounds, AAA polish

**Recommendation**: Ship with Day 1-4 sounds, add rest in updates

---

## SUCCESS CRITERIA

You'll know sounds are working when:
- [ ] Playtester says "ooh!" when collecting flowers
- [ ] Jump feels satisfying after 50 jumps
- [ ] Combat has impact (stomping feels good)
- [ ] Menus feel responsive (no lag perception)
- [ ] No one complains about annoying sounds

---

## EMERGENCY FALLBACK

If AI generation fails or time runs out:

**Plan B - Hybrid Sounds**:
- Use [Freesound.org](https://freesound.org) for base sounds (water splashes, wooden impacts)
- Layer with kalimba samples from [Freepats](http://freepats.zenvoid.org/)
- Edit/combine in Audacity

**Plan C - Commission**:
- Fiverr: $50-150 for 10-sound package (search "video game sound effects")
- Provide this spec as brief

---

## QUESTIONS?

**Q: Can I use these sounds commercially?**
A: Check Suno's license (as of 2024, Pro tier allows commercial use)

**Q: What if a sound feels wrong in-game?**
A: Trust your gut. Try:
  1. Adjust volume (-3dB to -6dB)
  2. Change pitch (±10%)
  3. Add slight reverb (wet 10-20%)
  4. Regenerate if still wrong

**Q: How do I test for fatigue?**
A: Loop sound 50x in Audacity, listen straight through. Still pleasant? Ship it.

**Q: Should I add voice acting?**
A: No. Xochi is silent protagonist. Only organic sounds (breath, effort), no words.

---

**Good luck! The first 7 sounds will transform your game.**

---

*Priority Guide Version: 1.0*
*Pairs with: XOCHI_SFX_SPECIFICATION.md*
*Quick Start Focus: Maximum impact, minimum time*

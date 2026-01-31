# Suno.ai Batch Generation Guide for Xochi SFX

## Quick Start: Generate All 30 Sounds in One Session

This guide provides copy-paste prompts for Suno.ai to generate all Xochi sound effects efficiently.

---

## SETUP

1. Go to [Suno.ai](https://suno.ai)
2. Sign up for Pro account ($10/month - needed for commercial use)
3. Select "Instrumental" mode
4. Set duration to 30 seconds (we'll trim in post)
5. Keep these tabs open:
   - Suno.ai (generation)
   - Audacity (trimming/editing)
   - Your project folder

---

## BATCH 1: CORE GAMEPLAY (Priority: URGENT)

### Generate these 7 sounds first - they're heard most often

---

#### Sound 1: Jump (Small)
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Short jump sound effect, soft clay drum hit, water droplet splash, rising pitch, kalimba pluck accent, 350ms duration, playful organic axolotl leap, C to E major third, no music, sound design, wet footstep on lily pad
```
**Post-Processing**: Trim to first 350ms, normalize to -6dB, export as `XOCHI_MOVEMENT_JUMP_SMALL.ogg`

---

#### Sound 2: Collect Flower
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Flower collect sound effect, pizzicato string pluck C5, marimba ascending major third C to E, kalimba shimmer, wind chime tinkle, soft petal flutter, 500ms duration, magical flower pickup, cempasúchil collection, game collectible SFX
```
**Post-Processing**: Trim to first 500ms, create 5 pitch variants (+0%, +5%, +10%, +15%, +20%), normalize, export

---

#### Sound 3: Stomp Enemy
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Enemy defeat stomp sound effect, clay pot crack, satisfying pop, air release pitch drop C to C4, kalimba ding major third, shimmering sparkles, 500ms duration, game enemy squash, victorious combat feedback
```
**Post-Processing**: Trim to first 500ms, add 50ms silence at start (impact anticipation), normalize, export as `XOCHI_COMBAT_STOMP.ogg`

---

#### Sound 4: Get Hurt
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Player hurt sound effect, deep hand drum impact, water splash with reverse reverb, descending wooden flute E to C minor third, fading ripples, 600ms duration, painful but hopeful, axolotl damage sound, game hit feedback
```
**Post-Processing**: Trim to first 600ms, add reverse reverb tail (50% wet), normalize, export as `XOCHI_COMBAT_HURT.ogg`

---

#### Sound 5: Menu Select
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Menu navigation sound effect, soft wooden block tap, single water droplet plip, 120ms duration, subtle UI cursor, non-intrusive menu blip, game interface SFX
```
**Post-Processing**: Trim to first 120ms, very short fade-out (20ms), normalize to -24dB (quieter for UI), export as `XOCHI_UI_MENU_SELECT.ogg`

---

#### Sound 6: Land (Soft)
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Soft landing sound effect, muted hand drum pat, small water splash, droplets settling, gentle reed rustle, 250ms duration, organic axolotl landing on lily pad, wet impact, game SFX
```
**Post-Processing**: Trim to first 250ms, normalize, export as `XOCHI_MOVEMENT_LAND_SOFT.ogg`

---

#### Sound 7: Super Jump
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Powerful super jump sound effect, deep water explosion whoosh, conch shell horn blast F note, ascending marimba arpeggio F major 7th, shimmering kalimba sparkles, 800ms duration, magical axolotl power, heroic leap, mystical water energy, cinematic game SFX
```
**Post-Processing**: Trim to first 800ms, normalize, export as `XOCHI_MOVEMENT_JUMP_SUPER.ogg`

---

**STOP HERE and test these 7 sounds in-game before continuing**

---

## BATCH 2: REWARDS & COLLECTIBLES (Priority: HIGH)

---

#### Sound 8: Collect Star
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Hidden star collect sound effect, reverse cymbal swell, kalimba arpeggio C major triad explosion, layered wind chimes, glass harmonics shimmer, marimba heroic melody C-Eb-F, fading reverb with night bird, 1500ms duration, epic rare collectible fanfare, game achievement SFX
```
**Post-Processing**: Trim to first 1500ms, add lush reverb (30% wet), normalize, export as `XOCHI_COLLECT_STAR.ogg`

---

#### Sound 9: Collect Powerup
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Powerup transformation sound effect, soft vegetable bite thud, water whoosh rising pitch, marimba ascending arpeggio F major octave, kalimba sustained chord, continuous shimmer texture, 1500ms duration, magical growth transformation, axolotl power-up, game upgrade SFX
```
**Post-Processing**: Trim to first 1500ms, normalize, export as `XOCHI_COLLECT_POWERUP.ogg`

---

#### Sound 10: Rescue Baby Axolotl (MOST IMPORTANT)
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Baby rescue emotional sound effect, gentle water ripples, dual kalimba duet C-G harmony, warm marimba C major add9 chord, ascending flute victory melody, layered sparkles, distant celebration sounds, birds chirping, 2500ms duration, tender reunion, family love, game level complete SFX
```
**Post-Processing**: Trim to first 2500ms, add celebration reverb, normalize, export as `XOCHI_COLLECT_BABY.ogg`
**NOTE**: Generate 3-5 versions, pick the one that makes you emotional

---

#### Sound 11: Menu Confirm
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Menu confirm sound effect, wooden claves click, kalimba note A4, water splash fading, 300ms duration, decisive selection, game UI confirm SFX
```
**Post-Processing**: Trim to first 300ms, normalize to -18dB, export as `XOCHI_UI_MENU_CONFIRM.ogg`

---

## BATCH 3: COMBAT & PLATFORMING (Priority: MEDIUM)

---

#### Sound 12: Attack Swing
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Melee attack swing sound effect, wooden weapon swish, air whoosh pitch bend, sharp breath exhale, 250ms duration, powerful strike windup, ceremonial mace swing, game combat SFX
```
**Post-Processing**: Trim to first 250ms, create 3 pitch variants (±8%), export as `XOCHI_COMBAT_ATTACK_SWING.ogg`

---

#### Sound 13: Attack Hit
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Attack hit connect sound effect, wooden mallet on clay pot impact, water splash burst, kalimba confirmation note B4, 300ms duration, solid weapon impact, game combat feedback SFX
```
**Post-Processing**: Trim to first 300ms, boost transient (compressor with fast attack), export as `XOCHI_COMBAT_ATTACK_HIT.ogg`

---

#### Sound 14: Checkpoint Activated
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Checkpoint activated sound effect, soft gong chime G4, marimba G major add9 chord, layered kalimba shimmer, water ripples, distant bird call, 1200ms duration, safe zone sanctuary, game checkpoint save SFX
```
**Post-Processing**: Trim to first 1200ms, add warm reverb (20% wet), export as `XOCHI_ENV_CHECKPOINT.ogg`

---

#### Sound 15: Ledge Grab
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Ledge grab sound effect, rapid claw scratching wood, solid hand thunk secure, subtle wood creak strain, 400ms duration, platform edge grab, game ledge catch SFX
```
**Post-Processing**: Trim to first 400ms, boost high frequencies (5kHz+) for scratch detail, export as `XOCHI_ENV_LEDGE_GRAB.ogg`

---

#### Sound 16: Climb Up from Ledge
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Climb up ledge sound effect, breath exertion effort, multiple claw scrapes ascending pitch, wooden platform thump, water droplets shaking off, 700ms duration, ledge climb up, game platforming SFX
```
**Post-Processing**: Trim to first 700ms, normalize, export as `XOCHI_ENV_CLIMB_UP.ogg`

---

#### Sound 17: Water Splash (Medium)
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Water splash sound effect, sharp water impact transient, droplets dispersing spray, ripples calming settle, 500ms duration, realistic canal splash, game environmental SFX
```
**Post-Processing**: Trim to first 500ms, create variants: small (200ms), medium (500ms), large (800ms + bass boost), export series

---

#### Sound 18: Secret Revealed
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Secret revealed sound effect, reverse cymbal swell, stone grinding door, kalimba cascade C-A-F-D mysterious chord, cave reverb water drips, 1500ms duration, hidden area discovery, game exploration SFX
```
**Post-Processing**: Trim to first 1500ms, add cavernous reverb (40% wet), export as `XOCHI_ENV_SECRET.ogg`

---

## BATCH 4: UI & TRANSITIONS (Priority: MEDIUM)

---

#### Sound 19: Level Complete
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Level complete transition sound effect, kalimba duet reprise, conch shell call, ascending marimba C major scale, wooden door creak, water rush, 1500ms duration, victory transition, game level end SFX
```
**Post-Processing**: Trim to first 1500ms, normalize, export as `XOCHI_UI_LEVEL_COMPLETE.ogg`

---

#### Sound 20: Pause Game
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Pause game sound effect, water splash reverse echo, sustained marimba C minor chord, fading ripple, 600ms duration, time freeze moment, game pause SFX
```
**Post-Processing**: Trim to first 600ms, apply reverse reverb, export as `XOCHI_UI_PAUSE.ogg`

---

#### Sound 21: Menu Back/Cancel
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Menu cancel sound effect, soft wooden block tap C4, water drip reverse, 200ms duration, gentle back navigation, game UI cancel SFX
```
**Post-Processing**: Trim to first 200ms, normalize to -20dB, export as `XOCHI_UI_MENU_BACK.ogg`

---

#### Sound 22: Player Death (Single Life)
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Player death sound effect, deep drum impact, water splash, underwater descent muffled, slowing heartbeat pulse hand drum, silence moment, reverse water rebirth, 2200ms duration, single life lost, game death respawn SFX
```
**Post-Processing**: Trim to first 2200ms, add underwater muffling (low-pass 4kHz) from 80-1200ms, export as `XOCHI_UI_PLAYER_DEATH.ogg`

---

#### Sound 23: Game Over
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Game over sound effect, descending marimba C major to minor, slow water trickling away, ambient night sounds crickets, single kalimba C5 note, 2500ms duration, gentle failure encouragement, game over retry SFX
```
**Post-Processing**: Trim to first 2500ms, fade out ambience naturally, export as `XOCHI_UI_GAME_OVER.ogg`

---

## BATCH 5: BOSS BATTLES (Priority: LOW - Can wait)

---

#### Sound 24: Boss Appear (Night Boss)
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Boss intro roar sound effect, low drone building 60-120Hz sweep, distorted heron bird cry, water explosion, ceremonial Aztec huehuetl drum three hits, fading reverb tritone bass, 3000ms duration, epic boss entrance, game boss fight intro SFX
```
**Post-Processing**: Trim to first 3000ms, boost sub-bass (60-80Hz), export as `XOCHI_BOSS_ROAR_NIGHT.ogg`

---

#### Sound 25: Boss Defeated
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Boss defeated epic victory sound effect, heavy water crash bubbles, brief silence pause, conch shell horn blast C4, full marimba kalimba axolotl motif major, layered water sounds birds returning, 5000ms duration, ultimate boss defeat, game victory fanfare SFX
```
**Post-Processing**: Trim to first 5000ms, add celebratory reverb, normalize, export as `XOCHI_BOSS_DEFEAT_NIGHT.ogg`

---

#### Sound 26: Final Boss Appear
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Final boss approach, deep industrial drone, distant Aztec huehuetl drum, corruption ambience, rising dread texture, 100 bpm, F Phrygian, ominous final confrontation intro, looping instrumental, no vocals, heart of darkness
```
**Post-Processing**: Trim to first 3000ms, add distortion (10% wet) for corruption feel, export as `XOCHI_BOSS_ROAR_FINAL.ogg`

---

#### Sound 27: Final Boss Defeated
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Boss defeat transition, corruption drone fading, pure ritual flute axolotl motif, ceremonial drum resolution, darkness dissolving, 100 bpm, F minor to major, peaceful victory emerging, looping instrumental, no vocals, corruption cleansed
```
**Post-Processing**: Trim to first 5000ms, crossfade corruption to purity, export as `XOCHI_BOSS_DEFEAT_FINAL.ogg`

---

## BATCH 6: DANGER & WARNINGS (Priority: LOW)

---

#### Sound 28: Danger Alert
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Danger alert sound effect, wooden block tap, kalimba tritone F#-C dissonance, sustained bass F# note, 400ms duration, enemy proximity warning, game danger cue SFX
```
**Post-Processing**: Trim to first 400ms, make it noticeable but not annoying, export as `XOCHI_DANGER_ALERT.ogg`

---

#### Sound 29: Low Health Warning (LOOP)
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Low health warning loop, deep hand drum heartbeat 80Hz, kalimba dissonant B note, random water drips, 1 second loop cycle, critical health anxiety, game danger state SFX
```
**Post-Processing**: Trim to exactly 1 second, ensure seamless loop, normalize to -18dB (background), export as `XOCHI_DANGER_LOW_HEALTH_LOOP.ogg`

---

## BATCH 7: MOVEMENT VARIANTS (Priority: POLISH)

---

#### Sound 30: Footstep (3 variants)
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Single footstep sound effect, soft wooden block tap, wet squelch, organic texture, 100ms duration, axolotl walking on lily pad, rhythmic footfall, game footstep SFX
```
**Post-Processing**:
- Generate once, trim to 100ms
- Create 3 copies with slight pitch variation (±3%)
- Export as `XOCHI_MOVEMENT_FOOTSTEP_01.ogg`, `02`, `03`

---

#### Sound 31: Swim Stroke
**Suno Settings**: Instrumental, 30 seconds
**Prompt**:
```
Swimming stroke sound effect, gentle water churn, bubbles rising, underwater flow swoosh, 300ms duration, axolotl swimming naturally, graceful aquatic movement, game SFX
```
**Post-Processing**: Trim to first 300ms, apply underwater filter (low-pass 6kHz), export as `XOCHI_MOVEMENT_SWIM_STROKE.ogg`

---

#### Sound 32: Trajinera Boat (AMBIENT LOOP)
**Suno Settings**: Instrumental, 30 seconds (generate longer 60-second version)
**Prompt**:
```
Moving boat platform ambient loop, soft water churning, periodic wood creaking every 2 seconds, subtle metal ornaments clinking every 4 seconds, seamless loop, trajinera boat sound, game environmental ambience SFX
```
**Post-Processing**: Create seamless loop, ensure creak and clink events phase correctly, export as `XOCHI_ENV_TRAJINERA_LOOP.ogg`

---

## POST-GENERATION WORKFLOW

### For Each Sound:

1. **Download** from Suno (MP3 format)
2. **Import** to Audacity
3. **Trim** to specified duration
4. **Apply effects**:
   - Normalize: -6dB (Effect → Normalize, check "Normalize peak amplitude")
   - High-pass filter: 60Hz (Effect → High-Pass Filter)
   - Fade out: Last 50ms (Select end → Effect → Fade Out)
5. **Export** as OGG:
   - File → Export → Export Audio
   - Format: Ogg Vorbis
   - Quality: 8 (good balance of size/quality)
   - Channels: Mono (unless noted stereo)
6. **Rename** to naming convention: `XOCHI_[CATEGORY]_[NAME].ogg`
7. **Move** to correct directory in `/xochi-web/public/assets/audio/sfx/`
8. **Test** in game

---

## QUALITY CONTROL CHECKLIST

Before marking sound as "done":

- [ ] Correct duration (not too long)
- [ ] No clicks/pops at start or end
- [ ] Volume appropriate (-6dB normalized)
- [ ] Fits thematic palette (water, organic, cultural)
- [ ] Fatigue test: listen 20x in row, still pleasant?
- [ ] Tested in-game: triggers at right moment?
- [ ] File size reasonable (<50KB for most sounds)

---

## TROUBLESHOOTING

### Problem: Suno adds vocals despite "instrumental" setting
**Solution**: Regenerate with prompt including "ABSOLUTELY NO VOCALS, no voice, no singing, instrumental only"

### Problem: Sound is too long (10+ seconds)
**Solution**: Trim to specified duration, Suno often generates longer than needed

### Problem: Sound has wrong mood (happy instead of sad)
**Solution**: Revise prompt emotional descriptors, regenerate

### Problem: Sound is too shrill/harsh
**Solution**: In Audacity, apply EQ: reduce 2-4kHz by -3dB

### Problem: Sound doesn't loop seamlessly (ambient sounds)
**Solution**: Use crossfade loop technique:
1. Copy last 200ms of sound
2. Paste at beginning
3. Apply crossfade (Effect → Crossfade Tracks)
4. Trim to exact loop length

### Problem: Sound clashes with music
**Solution**: Apply EQ to carve out space:
- If music has strong bass: high-pass SFX at 200Hz
- If music has bright kalimba: reduce SFX at 4-6kHz

---

## TIME ESTIMATES

**Per sound** (generation to implementation):
- Simple SFX (jump, select): 10-15 minutes
- Medium SFX (stomp, hurt): 15-25 minutes
- Complex SFX (baby rescue, boss): 30-45 minutes

**Total for all 32 sounds**: 15-25 hours
- Generation: 5-8 hours
- Editing: 6-10 hours
- Testing/iteration: 4-7 hours

**Recommended approach**: Batch generate 5-7 sounds, edit all, test all, then move to next batch

---

## SUNO CREDITS USAGE

**Suno Pro** ($10/month):
- 500 generations per month
- Each sound: 3-5 generations to find best version
- Average: 4 generations per sound
- 32 sounds × 4 attempts = 128 generations
- **Usage**: ~25% of monthly quota
- **Plenty of room for iteration and variants**

---

## EXPORT DIRECTORY STRUCTURE

After generation, organize files:

```
/xochi-web/public/assets/audio/sfx/
├── movement/
│   ├── XOCHI_MOVEMENT_JUMP_SMALL.ogg
│   ├── XOCHI_MOVEMENT_JUMP_SUPER.ogg
│   ├── XOCHI_MOVEMENT_LAND_SOFT.ogg
│   ├── XOCHI_MOVEMENT_FOOTSTEP_01.ogg
│   ├── XOCHI_MOVEMENT_FOOTSTEP_02.ogg
│   ├── XOCHI_MOVEMENT_FOOTSTEP_03.ogg
│   └── XOCHI_MOVEMENT_SWIM_STROKE.ogg
├── combat/
│   ├── XOCHI_COMBAT_STOMP.ogg
│   ├── XOCHI_COMBAT_HURT.ogg
│   ├── XOCHI_COMBAT_ATTACK_SWING.ogg
│   └── XOCHI_COMBAT_ATTACK_HIT.ogg
├── collectibles/
│   ├── XOCHI_COLLECT_FLOWER.ogg
│   ├── XOCHI_COLLECT_STAR.ogg
│   ├── XOCHI_COLLECT_POWERUP.ogg
│   └── XOCHI_COLLECT_BABY.ogg
├── ui/
│   ├── XOCHI_UI_MENU_SELECT.ogg
│   ├── XOCHI_UI_MENU_CONFIRM.ogg
│   ├── XOCHI_UI_MENU_BACK.ogg
│   ├── XOCHI_UI_PAUSE.ogg
│   ├── XOCHI_UI_LEVEL_COMPLETE.ogg
│   ├── XOCHI_UI_GAME_OVER.ogg
│   └── XOCHI_UI_PLAYER_DEATH.ogg
├── environment/
│   ├── XOCHI_ENV_CHECKPOINT.ogg
│   ├── XOCHI_ENV_SECRET.ogg
│   ├── XOCHI_ENV_LEDGE_GRAB.ogg
│   ├── XOCHI_ENV_CLIMB_UP.ogg
│   ├── XOCHI_ENV_TRAJINERA_LOOP.ogg
│   ├── XOCHI_ENV_WATER_SPLASH_SMALL.ogg
│   ├── XOCHI_ENV_WATER_SPLASH_MEDIUM.ogg
│   └── XOCHI_ENV_WATER_SPLASH_LARGE.ogg
├── boss/
│   ├── XOCHI_BOSS_ROAR_NIGHT.ogg
│   ├── XOCHI_BOSS_ROAR_FINAL.ogg
│   ├── XOCHI_BOSS_DEFEAT_NIGHT.ogg
│   └── XOCHI_BOSS_DEFEAT_FINAL.ogg
└── danger/
    ├── XOCHI_DANGER_ALERT.ogg
    └── XOCHI_DANGER_LOW_HEALTH_LOOP.ogg
```

---

## FINAL CHECKLIST

Before calling SFX complete:

- [ ] All 32 sounds generated
- [ ] All sounds trimmed and normalized
- [ ] All sounds tested in-game
- [ ] No fatigue complaints from playtesters
- [ ] Files organized in correct directories
- [ ] BootScene.js updated with new file paths
- [ ] Volume levels balanced (no sound too loud/quiet)
- [ ] Cultural authenticity verified
- [ ] Cohesion with music confirmed
- [ ] Accessibility features implemented (visual feedback, toggles)

---

**You're ready! Open Suno, start with Batch 1, and transform your game's audio.**

**Pro tip**: Generate sounds while doing other work. Queue up 5 generations, work on code for 20 minutes, come back to review and edit.

---

*Batch Generation Guide Version: 1.0*
*Pairs with: XOCHI_SFX_SPECIFICATION.md*
*Purpose: Turn spec into reality, efficiently*

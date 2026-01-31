# XOCHI - Complete Sound Effects (SFX) Specification
**Aztec Axolotl Warrior Platformer | Authentic Xochimilco Audio Design**

---

## EXECUTIVE SUMMARY

This document specifies a complete replacement for Xochi's generic placeholder sound effects with an authentic, cohesive Xochimilco/Aztec-themed audio palette. Every sound is designed to reinforce the game's identity: a magical axolotl warrior navigating the ancient canals and floating gardens of Xochimilco, Mexico.

**Core Philosophy**: Water + Nature + Ancient Culture = Magic

---

## I. SOUND DESIGN PILLARS

### 1. Xochimilco Authenticity
- **Water-centric**: Every sound considers the canal environment (splashes, drips, ripples)
- **Natural materials**: Clay, wood, reeds, stone - no synthetic/electronic sounds
- **Ecological richness**: Birds, frogs, insects, fish - a living ecosystem
- **Ceremonial tradition**: Subtle Aztec instrument influences without overwhelming

### 2. Axolotl Character Identity
- **Amphibian nature**: Wet, squishy, organic sounds for movement
- **Regenerative power**: Magical healing sounds with water/light textures
- **Warrior spirit**: Despite cuteness, this is a capable fighter - sounds need weight

### 3. Game Feel Excellence
- **Crisp feedback**: Every action has clear, satisfying audio response
- **Spatial clarity**: Sounds help players understand game state (danger, success, power-up)
- **Emotional arc**: Sounds evolve from peaceful to intense based on context
- **No fatigue**: Repeated sounds (jump, walk) must remain pleasant after hundreds of plays

### 4. Cohesion with Music System
- **Instrument palette alignment**: Use same timbres as music (marimba, kalimba, flutes, hand drums)
- **Key relationships**: Major sounds for success, minor for failure, match musical keys where possible
- **Rhythmic compatibility**: Percussive SFX should align with music's BPM feel
- **Dynamic integration**: SFX duck music appropriately (see mixing spec)

---

## II. COMPREHENSIVE SFX CATALOG

### A. MOVEMENT SOUNDS

#### SFX-001: Jump (Small)
**Current**: `small_jump.ogg` (generic boing)
**Context**: Basic jump, most common player action (heard 100+ times per session)
**Design Concept**: Wet axolotl feet pushing off lily pad + soft water splash

**Sound Layers**:
1. **Attack** (0-50ms): Soft clay drum thump (low pitch, ~120Hz fundamental)
2. **Body** (50-200ms): Water droplet burst with pitches rising (C to E, major third)
3. **Tail** (200-350ms): Kalimba single note pluck (E5, ~659Hz) for playful accent
4. **Ambience** (0-350ms): Subtle leaf rustle texture

**Emotional Target**: Playful confidence, light and bouncy, not cartoonish

**AI Generation Prompt (Suno/Audio Tool)**:
```
Short jump sound effect, soft clay drum hit, water droplet splash, rising pitch, kalimba pluck accent, 350ms duration, playful organic axolotl leap, C to E major third, no music, sound design, wet footstep on lily pad
```

**Implementation Notes**:
- Pitch variation: ±5% random per jump (prevents fatigue)
- Volume variation: ±2dB random
- If player jumps while swimming, use variant with more water splash, less drum

**Alternate Variants**:
- **Jump_Swim**: Replace drum with water bubble pop
- **Jump_Ledge**: Add slight echo/reverb for height
- **Jump_Tired**: Lower pitch -10%, reduce kalimba brightness (after many jumps in sequence)

---

#### SFX-002: Super Jump
**Current**: `powerup_appears.ogg` (reused, doesn't fit)
**Context**: Special ability jump, player has spent resource, should feel powerful
**Design Concept**: Magical water explosion + rising marimba arpeggio + ceremonial shell horn blast

**Sound Layers**:
1. **Charge** (0-100ms): Deep water whoosh, pitching down (preparing energy)
2. **Launch** (100-200ms): Conch shell horn blast (F3 fundamental, ~175Hz)
3. **Ascent** (200-600ms): Marimba arpeggio ascending (F-A-C-E, major 7th chord)
4. **Magic Trail** (200-800ms): Shimmering kalimba sparkles, fading

**Emotional Target**: Epic empowerment, this is a BIG DEAL, make player feel like a hero

**AI Generation Prompt**:
```
Powerful super jump sound effect, deep water explosion whoosh, conch shell horn blast F note, ascending marimba arpeggio F major 7th, shimmering kalimba sparkles, 800ms duration, magical axolotl power, heroic leap, mystical water energy, cinematic game SFX
```

**Implementation Notes**:
- Trigger particle effects synced to marimba arpeggio beats (every 150ms)
- Should briefly duck music to 70% volume during shell blast
- No pitch variation (this is a "signature move" sound, consistency = brand)

---

#### SFX-003: Land (Soft)
**Current**: No dedicated sound
**Context**: Xochi lands from jump onto platform
**Design Concept**: Wet pat + soft thud + water droplets settling

**Sound Layers**:
1. **Impact** (0-30ms): Muted hand drum (djembe bass tone, ~100Hz)
2. **Water Spray** (30-120ms): Small splash, multiple droplets
3. **Settle** (120-250ms): Gentle leaf/reed crinkle

**Emotional Target**: Satisfying weight, grounded, safe arrival

**AI Generation Prompt**:
```
Soft landing sound effect, muted hand drum pat, small water splash, droplets settling, gentle reed rustle, 250ms duration, organic axolotl landing on lily pad, wet impact, game SFX
```

**Implementation Notes**:
- Volume scales with fall distance (higher fall = louder, more splash)
- If landing from super jump, use variant with deeper drum and bigger splash
- Suppressed if landing immediately into next jump (footstep-cancel logic)

---

#### SFX-004: Walk/Run (Footsteps)
**Current**: No dedicated sound
**Context**: Xochi moving on ground (not swimming)
**Design Concept**: Rhythmic wet footsteps with lily pad/wood variations

**Sound Layers** (per footstep):
1. **Step** (0-50ms): Soft wooden block tap (like marimba mallet on wood)
2. **Moisture** (20-80ms): Tiny water squelch
3. **Material** (10-100ms): Surface-dependent layer (see variants)

**Emotional Target**: Presence without annoyance, rhythmic support, alive character

**AI Generation Prompt**:
```
Single footstep sound effect, soft wooden block tap, wet squelch, organic texture, 100ms duration, axolotl walking on lily pad, rhythmic footfall, game footstep SFX
```

**Implementation Notes**:
- Trigger every 180ms at walk speed (333ms during idle walk)
- Trigger every 120ms at run speed
- Alternate between 3-4 recorded variants to avoid machine-gun repetition
- Surface-aware system:
  - **Grass/Lily Pad**: Add soft leaf rustle
  - **Wood (trajinera boats)**: Add wooden creak
  - **Stone/Cave**: Add subtle echo, harder impact
  - **Mud**: Deeper squelch, slower attack

**Fatigue Prevention**:
- High-pass filter at 200Hz (remove low rumble that accumulates)
- Volume at -18dB in mix (should blend into background)
- Max 4 footstep sounds per second (if player moving faster, skip some triggers)

---

#### SFX-005: Swim (Stroke)
**Current**: No dedicated sound
**Context**: Xochi swimming through water (unique mechanic for axolotl)
**Design Concept**: Gentle underwater propulsion, bubbles, flow

**Sound Layers** (per stroke):
1. **Push** (0-100ms): Soft water churn (like hand cupping water)
2. **Bubbles** (50-200ms): Small bubble cluster rising
3. **Flow** (100-300ms): Water glide/swoosh tail

**Emotional Target**: Fluid grace, axolotls are natural swimmers, this should feel effortless

**AI Generation Prompt**:
```
Swimming stroke sound effect, gentle water churn, bubbles rising, underwater flow swoosh, 300ms duration, axolotl swimming naturally, graceful aquatic movement, game SFX
```

**Implementation Notes**:
- Trigger every 400ms while swim button held
- Pitch correlates with swim speed: faster = higher pitch (+10%)
- Stereo pan follows swim direction (left stroke = left channel louder)
- Underwater frequency filter: low-pass at 8kHz for muffled effect

---

### B. COMBAT SOUNDS

#### SFX-006: Stomp Enemy
**Current**: `stomp.ogg` (generic Mario stomp)
**Context**: Player jumps on enemy's head, defeats them
**Design Concept**: Satisfying squash + comedic pop + magical sparkle reward

**Sound Layers**:
1. **Squash** (0-80ms): Clay pot cracking sound (organic, not plastic)
2. **Pop** (80-150ms): Air release with pitch drop (like balloon deflating, C5 to C4)
3. **Reward** (150-400ms): Kalimba two-note "ding!" (C-E major third)
4. **Magic Dust** (200-500ms): Shimmering particles fading

**Emotional Target**: Triumphant satisfaction, skill confirmation, "YES! I did that!"

**AI Generation Prompt**:
```
Enemy defeat stomp sound effect, clay pot crack, satisfying pop, air release pitch drop C to C4, kalimba ding major third, shimmering sparkles, 500ms duration, game enemy squash, victorious combat feedback
```

**Implementation Notes**:
- Critical hit feel: brief 50ms pause in audio after squash (impact anticipation)
- Bigger enemies = lower pitch (-20% fundamental)
- Chain stomps: each stomp in combo gets +5% pitch, brighter sparkle (escalating excitement)
- Must never be annoying (kalimba bright but not shrill, cap at 2kHz fundamental)

---

#### SFX-007: Get Hurt / Take Damage
**Current**: `bump.ogg` (generic bump)
**Context**: Enemy hits player, player loses health/power
**Design Concept**: Painful but not horrifying, water disruption + low drum hit + reverse sound for magic loss

**Sound Layers**:
1. **Impact** (0-50ms): Deep hand drum hit (80Hz, djembe bass)
2. **Disruption** (50-200ms): Water splash with backwards reverb (magic being knocked out)
3. **Pain Accent** (100-300ms): Wooden flute descending note (E4 to C4, minor third, sad)
4. **Recovery** (300-600ms): Fading ripple (preparing to regenerate)

**Emotional Target**: Consequence without trauma, setback not death, player should feel "ouch" not "game over"

**AI Generation Prompt**:
```
Player hurt sound effect, deep hand drum impact, water splash with reverse reverb, descending wooden flute E to C minor third, fading ripples, 600ms duration, painful but hopeful, axolotl damage sound, game hit feedback
```

**Implementation Notes**:
- Trigger brief red screen flash + controller vibration in sync with drum hit
- If player has shield/powerup: replace drum with lighter wooden block, remove flute (deflected)
- If this damage kills player: extend to chain into death sound (see SFX-015)
- During invincibility frames: duck this sound and all other damage sounds

---

#### SFX-008: Attack (Melee/Mace Swing)
**Current**: No dedicated sound (game has attacks?)
**Context**: Xochi swings weapon or performs melee attack
**Design Concept**: Wooden ceremonial weapon swish + air displacement + power grunt (no voice, just breath)

**Sound Layers**:
1. **Wind-up** (0-80ms): Wooden stick swish (like bo staff)
2. **Swing** (80-200ms): Air whoosh with pitch bend (starts low, peaks high)
3. **Power** (100-250ms): Sharp breath exhale (organic, not voice)

**Emotional Target**: Capability and weight, this small axolotl is mighty

**AI Generation Prompt**:
```
Melee attack swing sound effect, wooden weapon swish, air whoosh pitch bend, sharp breath exhale, 250ms duration, powerful strike windup, ceremonial mace swing, game combat SFX
```

**Implementation Notes**:
- Pitch variation: ±8% random (prevents pattern recognition during combos)
- Direction-aware: swing left = pan left, swing right = pan right
- Charge attack variant: extend wind-up to 150ms, add deeper resonance

---

#### SFX-009: Attack Hit (Connect)
**Current**: No dedicated sound
**Context**: Attack successfully connects with enemy
**Design Concept**: Solid thwack + water splash (enemies are water-based or surrounded by moisture)

**Sound Layers**:
1. **Impact** (0-30ms): Wooden mallet on clay pot (sharp transient)
2. **Splash** (30-150ms): Water burst
3. **Feedback** (150-300ms): Kalimba single note (confirms hit, B4)

**Emotional Target**: Visceral satisfaction, combat clarity, "that landed!"

**AI Generation Prompt**:
```
Attack hit connect sound effect, wooden mallet on clay pot impact, water splash burst, kalimba confirmation note B4, 300ms duration, solid weapon impact, game combat feedback SFX
```

**Implementation Notes**:
- Volume scales with damage dealt (critical hits = +6dB, add extra sparkle layer)
- Enemy type variations:
  - **Gull (flying)**: Add feather flutter
  - **Heron (large)**: Lower pitch -30%, deeper thud
  - **Boss**: Extended impact, add ceremonial drum echo

---

### C. COLLECTIBLES & REWARDS

#### SFX-010: Collect Flower (Cempasúchil)
**Current**: `coin.ogg` (Mario coin)
**Context**: Player collects flower collectible (most common pickup)
**Design Concept**: Floral pluck + marimba sparkle + magical growth sound

**Sound Layers**:
1. **Pluck** (0-50ms): Pizzicato string pluck (C5, like picking flower)
2. **Bloom** (50-200ms): Marimba ascending two-note (C5 to E5, major third)
3. **Magic** (200-450ms): Kalimba shimmer + wind chime tinkle
4. **Ambience** (300-500ms): Soft petal flutter (organic texture)

**Emotional Target**: Joyful reward, "ooh pretty!", satisfying collection loop

**AI Generation Prompt**:
```
Flower collect sound effect, pizzicato string pluck C5, marimba ascending major third C to E, kalimba shimmer, wind chime tinkle, soft petal flutter, 500ms duration, magical flower pickup, cempasúchil collection, game collectible SFX
```

**Implementation Notes**:
- Pitch variation: cycle through C-D-E-F-G on consecutive pickups (major scale = happiness)
- Every 10th flower: trigger special "milestone" variant with fuller chord (C-E-G major triad)
- Chain collection bonus: if player collects 3+ flowers within 2 seconds, each subsequent flower gets +10% pitch, faster playback (escalating excitement)
- Visual sync: particle burst should align with marimba bloom (50ms mark)

**Why This Works Psychologically**:
- Major third interval = universally pleasant, non-fatiguing
- Ascending pitch = progress, growth, reward
- Pizzicato pluck = tactile feedback (you "picked" the flower)
- Kalimba timbre = already established in game's music (cohesion)

---

#### SFX-011: Collect Star (Hidden Collectible)
**Current**: `powerup_appears.ogg` (reused, generic)
**Context**: Player finds rare hidden star, this is a BIG achievement
**Design Concept**: Dramatic revelation + celestial sparkle + triumphant fanfare

**Sound Layers**:
1. **Discovery** (0-100ms): Reverse cymbal swell (building anticipation)
2. **Reveal** (100-200ms): Kalimba arpeggio explosion (C-E-G-C major triad, upward)
3. **Celestial** (200-800ms): Layered wind chimes + glass harmonics (shimmering)
4. **Triumph** (400-1200ms): Marimba melody fragment from Xochi motif (C-Eb-F, heroic)
5. **Echo** (1000-1500ms): Fading reverb tail with night bird call (environmental connection)

**Emotional Target**: Epic discovery, player should feel PROUD, share-worthy moment

**AI Generation Prompt**:
```
Hidden star collect sound effect, reverse cymbal swell, kalimba arpeggio C major triad explosion, layered wind chimes, glass harmonics shimmer, marimba heroic melody C-Eb-F, fading reverb with night bird, 1500ms duration, epic rare collectible fanfare, game achievement SFX
```

**Implementation Notes**:
- This is a mini-fanfare, pause gameplay for 800ms (camera zoom on star, slow-mo effect)
- Music ducks to 30% during this sound (SFX is star of the moment)
- Save game immediately after this sound completes
- Achievement popup should sync to kalimba explosion (100ms mark)
- No pitch variation (stars are rare, consistency builds brand recognition)

**Why This Works Psychologically**:
- Reverse swell = anticipation (brain predicts something important)
- Major triad = pure joy and completion
- Extended duration = rewards player's attention, makes moment special
- Xochi motif fragment = connects to game's identity (this is YOUR achievement in YOUR world)
- Environmental echo = grounds fantasy in Xochimilco setting

---

#### SFX-012: Collect Powerup (Mushroom)
**Current**: `powerup.ogg` (generic powerup)
**Context**: Player collects mushroom, grows from small to big form (like Mario)
**Design Concept**: Organic growth + magical transformation + energizing pulse

**Sound Layers**:
1. **Pickup** (0-100ms): Soft thud as mushroom absorbed (like biting vegetable)
2. **Activation** (100-300ms): Water whoosh with pitch rising (energy filling body)
3. **Growth Pulse** (300-800ms): Marimba ascending arpeggio (F-A-C-F, F major octave leap)
4. **Stabilization** (800-1200ms): Kalimba sustained chord (F major triad, fading)
5. **Energy Aura** (500-1500ms): Continuous shimmer texture (magical power active)

**Emotional Target**: Empowerment, transformation, "I'm stronger now!"

**AI Generation Prompt**:
```
Powerup transformation sound effect, soft vegetable bite thud, water whoosh rising pitch, marimba ascending arpeggio F major octave, kalimba sustained chord, continuous shimmer texture, 1500ms duration, magical growth transformation, axolotl power-up, game upgrade SFX
```

**Implementation Notes**:
- Synced animation: Xochi sprite scales up over 600ms, sync growth pulse to animation midpoint (300ms)
- Music transition: if player powers up during calm music, add percussion stem (energizing)
- Visual effects: particle burst at each marimba note (300, 450, 600, 800ms)
- Post-effect: while powered up, add subtle shimmer layer to jump sounds (player feels enhanced)

**Variant: Lose Powerup (Get Hit While Big)**:
- Reverse the sound: descending arpeggio, pitch dropping whoosh, sad minor chord
- Duration: 800ms (faster than gaining power, emphasizes loss)

---

#### SFX-013: Rescue Baby Axolotl
**Current**: `powerup.ogg` (reused, doesn't convey emotional weight)
**Context**: Player completes level by reaching baby, this is primary goal, deeply emotional
**Design Concept**: Tender reunion + water embrace + celebration + cultural significance

**Sound Layers**:
1. **Approach** (0-200ms): Gentle water ripples, soft footsteps slowing
2. **Reunion** (200-500ms): Dual kalimba duet (parent and baby "voices", C and G harmony)
3. **Embrace** (500-900ms): Warm marimba chord (C major add9, nurturing)
4. **Celebration** (900-1500ms): Ascending flute melody (Xochi victory motif in major)
5. **Joy Texture** (1200-2000ms): Layered sparkles, distant celebration sounds (community joy)
6. **Environmental Response** (1500-2500ms): Birds chirping, water settling, world rejoices

**Emotional Target**: Deep satisfaction, love, accomplishment, this is WHY we play

**AI Generation Prompt**:
```
Baby rescue emotional sound effect, gentle water ripples, dual kalimba duet C-G harmony, warm marimba C major add9 chord, ascending flute victory melody, layered sparkles, distant celebration sounds, birds chirping, 2500ms duration, tender reunion, family love, game level complete SFX
```

**Implementation Notes**:
- This is the most important non-music sound in the game, invest maximum effort
- Pause gameplay entirely for first 900ms (let moment breathe)
- Camera pans to show both Xochi and baby during reunion
- Music crossfades to victory theme at 1500ms mark
- Achievement tracking: this should trigger level completion logic
- Cultural note: consider adding subtle huehuetl drum at 900ms for ceremonial weight

**Why This Works Psychologically**:
- Dual kalimba = conversation, connection, two beings reuniting
- Major add9 chord = bittersweet joy (we found baby, but world is still in danger)
- Extended duration = respects player's effort (they spent 5-10 minutes reaching this)
- Environmental response = world acknowledges player's heroism
- Victory motif callback = ties to game's musical identity

**Accessibility Note**: For players with audio processing issues, ensure each layer is distinct and not overwhelming (test with volume at 50%)

---

### D. UI & FEEDBACK SOUNDS

#### SFX-014: Menu Select / Navigate
**Current**: `coin.ogg` (reused, wrong association)
**Context**: Player highlights menu options, UI interaction
**Design Concept**: Subtle cursor blip, water ripple, non-intrusive

**Sound Layers**:
1. **Blip** (0-30ms): Soft wooden block tap (like marimba dead note)
2. **Ripple** (30-120ms): Single water droplet "plip"

**Emotional Target**: Clear feedback without drawing attention, menu is not gameplay

**AI Generation Prompt**:
```
Menu navigation sound effect, soft wooden block tap, single water droplet plip, 120ms duration, subtle UI cursor, non-intrusive menu blip, game interface SFX
```

**Implementation Notes**:
- Very quiet: -24dB in mix (should never compete with menu music)
- Pitch varies by menu tier: main menu = C5, sub-menu = E5, settings = G5 (spatial hierarchy)
- No reverb (keeps it "in front" of spatial mix)

---

#### SFX-015: Menu Confirm / Select
**Current**: `coin.ogg` (reused, wrong context)
**Context**: Player confirms selection, starts level, opens sub-menu
**Design Concept**: Decisive action, wooden percussion + water splash, "yes, that choice"

**Sound Layers**:
1. **Decision** (0-50ms): Wooden claves click (sharp transient)
2. **Confirm** (50-150ms): Kalimba single note (A4, confident)
3. **Ripple** (150-300ms): Water splash fading

**Emotional Target**: Confident choice, forward momentum, positive action

**AI Generation Prompt**:
```
Menu confirm sound effect, wooden claves click, kalimba note A4, water splash fading, 300ms duration, decisive selection, game UI confirm SFX
```

**Implementation Notes**:
- Critical selections (Start Game, Continue): add extra kalimba octave above (A5) for emphasis
- Destructive selections (Delete Save): replace kalimba with descending note (sad variant)

---

#### SFX-016: Menu Back / Cancel
**Current**: No dedicated sound
**Context**: Player backs out of menu, cancels action
**Design Concept**: Gentle retreat, water receding, not a failure sound

**Sound Layers**:
1. **Reverse** (0-80ms): Soft wooden block (lower pitch than select, C4)
2. **Recede** (80-200ms): Water drip backward (reverse audio)

**Emotional Target**: Non-judgmental exit, "okay, take your time"

**AI Generation Prompt**:
```
Menu cancel sound effect, soft wooden block tap C4, water drip reverse, 200ms duration, gentle back navigation, game UI cancel SFX
```

---

#### SFX-017: Pause Game
**Current**: No dedicated sound
**Context**: Player presses pause (ESC key), game freezes
**Design Concept**: Time stop, water freezing, breath hold

**Sound Layers**:
1. **Freeze** (0-100ms): Water splash with reverse echo
2. **Suspension** (100-400ms): Sustained marimba chord (C minor, ambiguous)
3. **Silence Tail** (400-600ms): Fading ripple into quiet

**Emotional Target**: Suspension, "moment frozen", rest point

**AI Generation Prompt**:
```
Pause game sound effect, water splash reverse echo, sustained marimba C minor chord, fading ripple, 600ms duration, time freeze moment, game pause SFX
```

**Implementation Notes**:
- Music fades to 20% volume over 200ms after this sound
- When unpause: reverse this sound (ripple building, chord resolving to major)

---

#### SFX-018: Level Complete (Transition)
**Current**: No dedicated sound
**Context**: Player finishes level (after baby rescue), transitioning to next level
**Design Concept**: Triumphant closure + forward momentum + world evolution

**Sound Layers**:
1. **Victory Reprise** (0-400ms): Shortened version of rescue sound (kalimba duet)
2. **Transition** (400-800ms): Conch shell call (signaling new chapter)
3. **Onward** (800-1200ms): Ascending marimba scale (C major, climbing)
4. **Gate Open** (1200-1500ms): Wooden door creak + water rush (passage opening)

**Emotional Target**: Accomplishment + anticipation, "I won, what's next?"

**AI Generation Prompt**:
```
Level complete transition sound effect, kalimba duet reprise, conch shell call, ascending marimba C major scale, wooden door creak, water rush, 1500ms duration, victory transition, game level end SFX
```

**Implementation Notes**:
- Plays after baby rescue sound completes
- Screen fades to white at 800ms mark (sync to marimba ascent)
- Next level loads during gate open sound (mask loading time)

---

#### SFX-019: Game Over
**Current**: No dedicated sound
**Context**: Player loses all lives, must return to menu
**Design Concept**: Gentle failure, not harsh, encouraging retry, water receding

**Sound Layers**:
1. **Loss** (0-300ms): Descending marimba scale (C major to C minor, hope to sadness)
2. **Water Drain** (300-1000ms): Slow water trickling away
3. **Silence** (1000-2000ms): Ambient night sounds only (crickets, distant water)
4. **Hope Seed** (2000-2500ms): Single kalimba note (C5, alone but pure)

**Emotional Target**: Disappointment without punishment, "try again, you can do this"

**AI Generation Prompt**:
```
Game over sound effect, descending marimba C major to minor, slow water trickling away, ambient night sounds crickets, single kalimba C5 note, 2500ms duration, gentle failure encouragement, game over retry SFX
```

**Implementation Notes**:
- Screen fades to black slowly (over 2000ms)
- Music stops completely (silence is part of emotional weight)
- "Continue?" prompt appears at kalimba note (2000ms), offering hope

**Psychological Design**:
- Extended duration = respects player's investment (they tried hard)
- Hope seed = game believes in player, door is open to retry
- No loud/aggressive sounds = reduces frustration, maintains player motivation

---

#### SFX-020: Player Death (Single Life Lost)
**Current**: `bump.ogg` (reused, insufficient weight)
**Context**: Player dies but has lives remaining, respawns soon
**Design Concept**: Sudden loss + water submersion + fading consciousness + gentle respawn

**Sound Layers**:
1. **Fatal Hit** (0-80ms): Deep drum hit + water splash (more intense than hurt sound)
2. **Submersion** (80-500ms): Underwater muffled descent, low-pass filter sweeping down
3. **Fade Out** (500-1200ms): Heartbeat-like pulse slowing (hand drum, decreasing tempo)
4. **Darkness** (1200-1800ms): Complete silence (moment of loss)
5. **Respawn Breath** (1800-2200ms): Reverse water sounds, life returning

**Emotional Target**: Setback not trauma, "you'll be back, warrior"

**AI Generation Prompt**:
```
Player death sound effect, deep drum impact, water splash, underwater descent muffled, slowing heartbeat pulse hand drum, silence moment, reverse water rebirth, 2200ms duration, single life lost, game death respawn SFX
```

**Implementation Notes**:
- Screen desaturates during submersion (80-500ms)
- Complete black screen during darkness (1200-1800ms)
- Respawn animation begins at 1800ms with breath sound
- Music resumes at 2200ms, fading back in

**Variant: Final Death (Last Life)**:
- Extend darkness period to 3000ms
- Replace respawn breath with transition to Game Over sound

---

### E. ENVIRONMENTAL & SPECIAL SOUNDS

#### SFX-021: Checkpoint Activated
**Current**: No dedicated sound
**Context**: Player touches checkpoint, progress saved
**Design Concept**: Safety bell, water sanctuary, healing moment

**Sound Layers**:
1. **Touch** (0-50ms): Soft gong chime (like temple bell, G4)
2. **Activation** (50-200ms): Marimba chord spread (G major add9, peaceful)
3. **Healing Aura** (200-800ms): Layered kalimba shimmer + water ripples
4. **Confirmation** (800-1200ms): Distant bird call (environmental acknowledgment)

**Emotional Target**: Relief, safety, "you're okay now, rest here"

**AI Generation Prompt**:
```
Checkpoint activated sound effect, soft gong chime G4, marimba G major add9 chord, layered kalimba shimmer, water ripples, distant bird call, 1200ms duration, safe zone sanctuary, game checkpoint save SFX
```

**Implementation Notes**:
- Visual: golden water ripple expands from checkpoint during sound
- Heal player during this sound (sync healing animation to 200ms mark)
- Save game at 800ms (mask saving latency with bird call)

---

#### SFX-022: Secret Revealed / Hidden Area Found
**Current**: No dedicated sound
**Context**: Player discovers secret passage, hidden room, or Easter egg
**Design Concept**: Mystery unveiled, ancient door opening, magical discovery

**Sound Layers**:
1. **Discovery** (0-150ms): Reverse cymbal swell (smaller than star sound)
2. **Unveiling** (150-400ms): Stone grinding (ancient door mechanism)
3. **Magic Spill** (400-900ms): Kalimba cascade descending (C-A-F-D, mysterious chord)
4. **Echo** (900-1500ms): Cave reverb tail with water drips

**Emotional Target**: Curiosity rewarded, "ooh what's this?!", exploration joy

**AI Generation Prompt**:
```
Secret revealed sound effect, reverse cymbal swell, stone grinding door, kalimba cascade C-A-F-D mysterious chord, cave reverb water drips, 1500ms duration, hidden area discovery, game exploration SFX
```

**Implementation Notes**:
- Camera should pan to reveal secret area during unveiling (150-400ms)
- Lighting changes to highlight new path at 400ms (magic spill moment)

---

#### SFX-023: Ledge Grab
**Current**: No dedicated sound
**Context**: Xochi grabs ledge edge, new mechanic in game
**Design Concept**: Scramble grab, claws on wood, effort, secure hold

**Sound Layers**:
1. **Scramble** (0-80ms): Rapid scratching (claws on wood)
2. **Grab** (80-150ms): Solid thunk (hand/paw securing)
3. **Hold Strain** (150-400ms): Subtle wood creak (platform bearing weight)

**Emotional Target**: Effort and relief, "phew, got it!", tense moment resolved

**AI Generation Prompt**:
```
Ledge grab sound effect, rapid claw scratching wood, solid hand thunk secure, subtle wood creak strain, 400ms duration, platform edge grab, game ledge catch SFX
```

**Implementation Notes**:
- Trigger immediately when grab occurs (tight timing)
- If player climbs up after grab: chain into climb-up sound (see SFX-024)
- If player falls from grab: cross-fade into fall wind sound

---

#### SFX-024: Climb Up from Ledge
**Current**: No dedicated sound
**Context**: After grabbing ledge, Xochi pulls up onto platform
**Design Concept**: Effort exertion, wood scrape, triumphant scramble

**Sound Layers**:
1. **Pull Effort** (0-150ms): Breath exertion (organic, no voice)
2. **Scramble** (150-400ms): Multiple claw scrapes, ascending pitch
3. **Mount** (400-550ms): Final thump on platform (wooden landing)
4. **Settle** (550-700ms): Water droplets shaking off

**Emotional Target**: Achievement, "I made it up!", skillful navigation

**AI Generation Prompt**:
```
Climb up ledge sound effect, breath exertion effort, multiple claw scrapes ascending pitch, wooden platform thump, water droplets shaking off, 700ms duration, ledge climb up, game platforming SFX
```

**Implementation Notes**:
- Animation must be exactly 700ms to match sound duration
- Player invulnerable during this sound (commit to animation)

---

#### SFX-025: Moving Platform (Trajinera Boat)
**Current**: No dedicated sound (ambient loop needed)
**Context**: Colorful boat platforms that move, constant presence in levels
**Design Concept**: Gentle water churning, wood creaking, festive but not intrusive

**Sound Layers** (looping):
1. **Water Churn** (continuous): Soft splashing, boat displacing water
2. **Wood Creak** (every 2 seconds): Hull flexing under weight
3. **Decoration Jingle** (every 4 seconds): Subtle metal ornaments clinking

**Emotional Target**: Alive world, cultural authenticity, pleasant ambience

**AI Generation Prompt**:
```
Moving boat platform ambient loop, soft water churning, periodic wood creaking every 2 seconds, subtle metal ornaments clinking every 4 seconds, seamless loop, trajinera boat sound, game environmental ambience SFX
```

**Implementation Notes**:
- This is an ambient loop, not a one-shot
- Volume tied to camera distance from boat (3D audio, closer = louder)
- Multiple boats should phase-shift their creak timing (avoid sync issues)
- Decorative jingle adds cultural flavor without overwhelming

---

#### SFX-026: Water Splash (Generic)
**Current**: No dedicated sound
**Context**: Object or player enters water, enemy defeated into water, various uses
**Design Concept**: Realistic water impact, size-dependent variants

**Sound Layers**:
1. **Impact** (0-50ms): Initial water break (sharp transient)
2. **Spray** (50-200ms): Droplets dispersing
3. **Settle** (200-500ms): Ripples calming

**Emotional Target**: Physical realism, world consistency, splash should feel WET

**AI Generation Prompt**:
```
Water splash sound effect, sharp water impact transient, droplets dispersing spray, ripples calming settle, 500ms duration, realistic canal splash, game environmental SFX
```

**Variants by Size**:
- **Small** (player footstep): Soft, short (200ms)
- **Medium** (player dive): Full splash (500ms)
- **Large** (boss falls): Deep, extended (800ms), add bass rumble

---

#### SFX-027: Boss Appear (Intro Roar)
**Current**: No dedicated sound
**Context**: Boss enters arena, battle begins, intimidation moment
**Design Concept**: Predator call + distorted water + ceremonial drums warning

**Sound Layers**:
1. **Tension** (0-500ms): Low drone building (bass frequency sweep 60-120Hz)
2. **Roar/Call** (500-1200ms): Distorted bird cry (heron-like) + water explosion
3. **Drums** (1200-2000ms): Ceremonial huehuetl drum hits (three strikes: doom-doom-DOOM)
4. **Standoff** (2000-3000ms): Fading reverb with danger motif hint (tritone bass note)

**Emotional Target**: OH NO, epic threat, "this is serious", adrenaline spike

**AI Generation Prompt**:
```
Boss intro roar sound effect, low drone building 60-120Hz sweep, distorted heron bird cry, water explosion, ceremonial Aztec huehuetl drum three hits, fading reverb tritone bass, 3000ms duration, epic boss entrance, game boss fight intro SFX
```

**Implementation Notes**:
- Camera shake on each drum hit (at 1200, 1500, 1800ms)
- Screen flashes red briefly on final DOOM (1800ms)
- Boss music crossfades in at 2000ms (during standoff)
- Player controls locked during this sound (cutscene moment)

**Boss-Specific Variants**:
- **Boss 1 (Night Predator)**: More heron cry, less drums
- **Final Boss (Corruption)**: Add distorted Xochi motif (corrupted), more industrial textures

---

#### SFX-028: Boss Defeated (Epic Victory)
**Current**: No dedicated sound
**Context**: Boss health reaches zero, major accomplishment
**Design Concept**: Monster collapse + triumphant fanfare + world healing

**Sound Layers**:
1. **Collapse** (0-800ms): Heavy water crash, enemy sinking, bubbles rising
2. **Silence** (800-1200ms): Brief pause (let moment land)
3. **Victory Call** (1200-1800ms): Conch shell horn blast (C4, heroic)
4. **Celebration** (1800-3000ms): Full marimba + kalimba Xochi motif in major
5. **World Heals** (3000-5000ms): Layered water sounds, birds returning, life restored

**Emotional Target**: EPIC TRIUMPH, player is a HERO, share-worthy moment

**AI Generation Prompt**:
```
Boss defeated epic victory sound effect, heavy water crash bubbles, brief silence pause, conch shell horn blast C4, full marimba kalimba axolotl motif major, layered water sounds birds returning, 5000ms duration, ultimate boss defeat, game victory fanfare SFX
```

**Implementation Notes**:
- Camera dramatic zoom on collapsing boss (0-800ms)
- Slow-motion effect during silence (800-1200ms)
- Victory animation for Xochi during celebration (1800-3000ms)
- Level lighting shifts brighter during world heals (3000-5000ms)
- This is a MAJOR moment, invest in animation and screen effects

---

### F. DANGER & FEEDBACK SOUNDS

#### SFX-029: Danger Alert (Enemy Proximity)
**Current**: No dedicated sound
**Context**: Enemy enters detection range, player needs warning
**Design Concept**: Subtle warning, tritone tension, not alarming but noticeable

**Sound Layers**:
1. **Alert** (0-100ms): Wooden block tap + kalimba tritone (F#-C, dissonant)
2. **Tension Tail** (100-400ms): Brief sustained bass note (F#, uncomfortable)

**Emotional Target**: Awareness without panic, "watch out, something near"

**AI Generation Prompt**:
```
Danger alert sound effect, wooden block tap, kalimba tritone F#-C dissonance, sustained bass F# note, 400ms duration, enemy proximity warning, game danger cue SFX
```

**Implementation Notes**:
- Trigger only once per enemy (not constantly while enemy nearby)
- Volume based on enemy threat level (boss = louder)
- Directional audio: pan toward enemy direction (left enemy = left speaker louder)

---

#### SFX-030: Low Health Warning
**Current**: No dedicated sound
**Context**: Player at 1 health remaining, critical danger state
**Design Concept**: Heartbeat pulse, anxious rhythm, water dripping urgency

**Sound Layers** (looping while low health):
1. **Heartbeat** (every 1 second): Deep hand drum (80Hz, djembe bass)
2. **Anxiety Ripple** (offset 0.5 seconds): Kalimba dissonant note (B natural, doesn't resolve)
3. **Water Drip** (random): Droplets falling (time running out metaphor)

**Emotional Target**: Urgency without annoyance, "heal NOW", survival tension

**AI Generation Prompt**:
```
Low health warning loop, deep hand drum heartbeat 80Hz, kalimba dissonant B note, random water drips, 1 second loop cycle, critical health anxiety, game danger state SFX
```

**Implementation Notes**:
- Loops continuously while health = 1
- Stops immediately when player heals or dies
- Red screen vignette pulses in sync with heartbeat
- Volume: -18dB (should blend into background, not overwhelm)

**Accessibility Consideration**: Add toggle to disable in accessibility settings (can be stressful)

---

---

## III. SOUND PALETTE SUMMARY

### Instruments Used (Cohesion with Music)
- **Marimba**: Warm melodic tones, rewards, celebration
- **Kalimba**: Bright sparkles, success, magic
- **Hand Drums (Djembe)**: Impacts, footsteps, rhythmic elements
- **Wooden Blocks/Claves**: UI, sharp accents, attacks
- **Flutes (Quena-style)**: Emotional moments, boss themes, transitions
- **Conch Shell Horn**: Ceremonial moments, world changes, boss intros
- **Pizzicato Strings**: Plucks, pickups, light touches
- **Water Sounds**: Omnipresent, splashes, drips, flows (canal world)
- **Wind Chimes**: Magic, ambient, delicate moments

### Frequencies & Mixing Guidelines

**Low (60-250Hz)**: Hand drums, bass impacts, boss roars, grounding elements
- Reserve for important moments (boss hits, damage)
- Avoid frequency buildup (high-pass filter at 80Hz)

**Mid (250Hz-2kHz)**: Marimba, wooden blocks, flutes, core gameplay sounds
- Most common range, ensure clarity by EQ carving
- Jump, land, footsteps live here

**High (2kHz-8kHz)**: Kalimba, wind chimes, sparkles, reward sounds
- Bright and present, but not shrill
- Cap fundamentals at 4kHz for fatigue prevention

**Air (8kHz+)**: Shimmer textures, water spray, subtle ambience
- Use sparingly, adds polish without drawing attention

---

## IV. ADAPTIVE SOUND SYSTEM

### Dynamic Mixing Based on Game State

#### Exploration Mode (Default)
- SFX at 100% volume
- Music at 80% volume
- Ambience at 60% volume
- Priorities: Player movement sounds, collectible pickup

#### Combat Mode (Enemy Engaged)
- SFX at 110% volume (boost impacts +10%)
- Music at 100% volume (adds intensity)
- Ambience at 40% volume (reduced distraction)
- Priorities: Attack sounds, enemy feedback, hurt sounds

#### Underwater Mode
- All sounds low-pass filtered at 6kHz (muffled effect)
- SFX at 90% volume (distant feeling)
- Music at 70% volume (ethereal)
- Ambience at 80% volume (water ambience becomes foreground)
- Add subtle underwater reverb to all sounds

#### Danger Mode (Low Health)
- SFX at 100% volume
- Music at 60% volume (reduce distraction)
- Ambience at 30% volume
- Heartbeat warning loop at 70% volume (present but not overwhelming)
- High-pass filter music (remove bass, create tension)

#### Boss Battle Mode
- SFX at 120% volume (epic scale)
- Music at 100% volume (boss music is cinematic)
- Ambience at 20% volume (focus on battle)
- Boss sounds at 110% volume (intimidation)

---

## V. AI GENERATION WORKFLOW

### Tools Recommended
1. **Suno.ai**: Best for musical SFX (kalimba, marimba melodies, organic tones)
2. **ElevenLabs Sound Effects**: Good for layered, complex SFX with precise control
3. **AudioGen (Meta)**: Free, decent quality for environmental sounds
4. **Hybrid Approach**: AI generates base, manual layering/editing in DAW for polish

### Generation Process

#### Step 1: Generate Raw Audio
- Use prompts provided in each SFX entry
- Generate 3-5 variations per sound
- Download highest quality (48kHz WAV if available)

#### Step 2: Selection Criteria
- **Clarity**: Is the sound instantly recognizable?
- **Fatigue Test**: Listen 20 times in a row - still pleasant?
- **Cohesion**: Does it fit with music palette?
- **Game Feel**: Does it make you WANT to perform the action again?

#### Step 3: DAW Editing (Audacity, Reaper, Pro Tools)
- Trim silence at start (<5ms attack preferred for snappy feel)
- Normalize to -6dB (headroom for game mixing)
- Add 50ms fade-out tail to avoid clicks
- EQ adjustments:
  - High-pass at 60-80Hz (remove rumble)
  - Gentle cut at 2-3kHz if harsh (de-esser for sibilance)
  - Subtle boost at 5-8kHz for air/presence
- Compression (2:1 ratio, gentle): evens out dynamics for consistent volume

#### Step 4: Looping Sounds (Ambient Effects)
- Ensure seamless loop points (crossfade 100ms overlap)
- Pitch/tempo should not drift
- Test loop for 60 seconds - any artifacts?

#### Step 5: Export Settings
- **Format**: OGG Vorbis (smaller file size than WAV, quality 8-10)
- **Sample Rate**: 48kHz (matches game engine standard)
- **Bit Depth**: 16-bit (sufficient for game audio)
- **Channels**: Mono for most SFX (stereo only for ambient loops or wide effects)

#### Step 6: Implementation Testing
- Import into game engine
- Test in context (does it work with music?)
- Volume balance (should player adjust? too loud = re-export)
- Timing (does it sync with animation/visual feedback?)

---

## VI. FILE NAMING & ORGANIZATION

### Naming Convention
```
XOCHI_[CATEGORY]_[NAME]_[VARIANT].ogg

Examples:
XOCHI_MOVEMENT_JUMP_SMALL.ogg
XOCHI_MOVEMENT_JUMP_SUPER.ogg
XOCHI_COMBAT_STOMP.ogg
XOCHI_COLLECT_FLOWER.ogg
XOCHI_COLLECT_STAR.ogg
XOCHI_UI_MENU_SELECT.ogg
XOCHI_BOSS_ROAR_NIGHT.ogg
```

### Directory Structure
```
/xochi-web/public/assets/audio/sfx/
  /movement/
    XOCHI_MOVEMENT_JUMP_SMALL.ogg
    XOCHI_MOVEMENT_JUMP_SUPER.ogg
    XOCHI_MOVEMENT_LAND_SOFT.ogg
    XOCHI_MOVEMENT_FOOTSTEP_01.ogg
    XOCHI_MOVEMENT_FOOTSTEP_02.ogg
    XOCHI_MOVEMENT_FOOTSTEP_03.ogg
    XOCHI_MOVEMENT_SWIM_STROKE.ogg
  /combat/
    XOCHI_COMBAT_STOMP.ogg
    XOCHI_COMBAT_HURT.ogg
    XOCHI_COMBAT_ATTACK_SWING.ogg
    XOCHI_COMBAT_ATTACK_HIT.ogg
  /collectibles/
    XOCHI_COLLECT_FLOWER.ogg
    XOCHI_COLLECT_STAR.ogg
    XOCHI_COLLECT_POWERUP.ogg
    XOCHI_COLLECT_BABY.ogg
  /ui/
    XOCHI_UI_MENU_SELECT.ogg
    XOCHI_UI_MENU_CONFIRM.ogg
    XOCHI_UI_MENU_BACK.ogg
    XOCHI_UI_PAUSE.ogg
    XOCHI_UI_LEVEL_COMPLETE.ogg
    XOCHI_UI_GAME_OVER.ogg
    XOCHI_UI_PLAYER_DEATH.ogg
  /environment/
    XOCHI_ENV_CHECKPOINT.ogg
    XOCHI_ENV_SECRET.ogg
    XOCHI_ENV_LEDGE_GRAB.ogg
    XOCHI_ENV_CLIMB_UP.ogg
    XOCHI_ENV_TRAJINERA_LOOP.ogg
    XOCHI_ENV_WATER_SPLASH_SMALL.ogg
    XOCHI_ENV_WATER_SPLASH_MEDIUM.ogg
    XOCHI_ENV_WATER_SPLASH_LARGE.ogg
  /boss/
    XOCHI_BOSS_ROAR_NIGHT.ogg
    XOCHI_BOSS_ROAR_FINAL.ogg
    XOCHI_BOSS_DEFEAT_NIGHT.ogg
    XOCHI_BOSS_DEFEAT_FINAL.ogg
  /danger/
    XOCHI_DANGER_ALERT.ogg
    XOCHI_DANGER_LOW_HEALTH_LOOP.ogg
```

---

## VII. IMPLEMENTATION CODE REFERENCE

### Loading Sounds (BootScene.js)
```javascript
loadAudio() {
  // Music (existing)
  this.load.audio('music-menu', 'assets/audio/music_menu.ogg');
  // ... other music ...

  // SFX - Movement
  this.load.audio('sfx-jump', 'assets/audio/sfx/movement/XOCHI_MOVEMENT_JUMP_SMALL.ogg');
  this.load.audio('sfx-jump-super', 'assets/audio/sfx/movement/XOCHI_MOVEMENT_JUMP_SUPER.ogg');
  this.load.audio('sfx-land', 'assets/audio/sfx/movement/XOCHI_MOVEMENT_LAND_SOFT.ogg');
  this.load.audio('sfx-footstep-01', 'assets/audio/sfx/movement/XOCHI_MOVEMENT_FOOTSTEP_01.ogg');
  this.load.audio('sfx-footstep-02', 'assets/audio/sfx/movement/XOCHI_MOVEMENT_FOOTSTEP_02.ogg');
  this.load.audio('sfx-footstep-03', 'assets/audio/sfx/movement/XOCHI_MOVEMENT_FOOTSTEP_03.ogg');

  // SFX - Combat
  this.load.audio('sfx-stomp', 'assets/audio/sfx/combat/XOCHI_COMBAT_STOMP.ogg');
  this.load.audio('sfx-hurt', 'assets/audio/sfx/combat/XOCHI_COMBAT_HURT.ogg');

  // SFX - Collectibles
  this.load.audio('sfx-flower', 'assets/audio/sfx/collectibles/XOCHI_COLLECT_FLOWER.ogg');
  this.load.audio('sfx-star', 'assets/audio/sfx/collectibles/XOCHI_COLLECT_STAR.ogg');
  this.load.audio('sfx-powerup', 'assets/audio/sfx/collectibles/XOCHI_COLLECT_POWERUP.ogg');
  this.load.audio('sfx-rescue', 'assets/audio/sfx/collectibles/XOCHI_COLLECT_BABY.ogg');

  // SFX - UI
  this.load.audio('sfx-select', 'assets/audio/sfx/ui/XOCHI_UI_MENU_SELECT.ogg');
  this.load.audio('sfx-confirm', 'assets/audio/sfx/ui/XOCHI_UI_MENU_CONFIRM.ogg');
}
```

### Playing Sounds with Variations (GameScene.js)
```javascript
playSound(key, options = {}) {
  if (!window.gameState.sfxEnabled) return;

  const config = {
    volume: options.volume || 0.6,
    rate: options.pitchVariation ? 1 + (Math.random() * 0.1 - 0.05) : 1,
    ...options
  };

  this.sound.play(key, config);
}

// Example: Jump with pitch variation
jump() {
  this.playSound('sfx-jump', { pitchVariation: true });
}

// Example: Footstep rotation
playFootstep() {
  const footsteps = ['sfx-footstep-01', 'sfx-footstep-02', 'sfx-footstep-03'];
  const random = Phaser.Utils.Array.GetRandom(footsteps);
  this.playSound(random, { volume: 0.4 });
}
```

---

## VIII. PRODUCTION TIMELINE

### Phase 1: Core Gameplay (Week 1) - PRIORITY
- [ ] SFX-001: Jump (Small)
- [ ] SFX-002: Super Jump
- [ ] SFX-003: Land (Soft)
- [ ] SFX-006: Stomp Enemy
- [ ] SFX-007: Get Hurt
- [ ] SFX-010: Collect Flower
- [ ] SFX-014: Menu Select

**Why These First**: Most heard sounds in game, establish audio identity immediately

### Phase 2: Collectibles & Rewards (Week 2)
- [ ] SFX-011: Collect Star
- [ ] SFX-012: Collect Powerup
- [ ] SFX-013: Rescue Baby Axolotl
- [ ] SFX-018: Level Complete

**Why These Second**: These are "dopamine hit" sounds, critical for player satisfaction

### Phase 3: UI & Feedback (Week 3)
- [ ] SFX-015: Menu Confirm
- [ ] SFX-016: Menu Back
- [ ] SFX-017: Pause Game
- [ ] SFX-019: Game Over
- [ ] SFX-020: Player Death
- [ ] SFX-021: Checkpoint

**Why These Third**: Polish UI experience, make menus feel cohesive

### Phase 4: Combat & Environment (Week 4)
- [ ] SFX-008: Attack Swing
- [ ] SFX-009: Attack Hit
- [ ] SFX-022: Secret Revealed
- [ ] SFX-023: Ledge Grab
- [ ] SFX-024: Climb Up
- [ ] SFX-026: Water Splash variants

**Why These Fourth**: Add depth to combat and platforming, enhance world immersion

### Phase 5: Boss Battles & Advanced (Week 5)
- [ ] SFX-027: Boss Appear
- [ ] SFX-028: Boss Defeated
- [ ] SFX-029: Danger Alert
- [ ] SFX-030: Low Health Warning

**Why These Last**: Fewer occurrences in game, can be refined based on other SFX learnings

### Phase 6: Ambient & Polish (Week 6)
- [ ] SFX-004: Walk/Run Footsteps
- [ ] SFX-005: Swim Stroke
- [ ] SFX-025: Trajinera Boat (loop)
- All variants and alternate versions
- Surface-specific footstep variations

**Why These Last**: Nice-to-have polish, game is playable without them

---

## IX. TESTING & QUALITY ASSURANCE

### Playtest Checklist (Per Sound)

**Individual Sound Tests**:
- [ ] Plays at correct timing (no lag)
- [ ] Volume appropriate (not too loud/quiet)
- [ ] Pitch feels right (not shrill, not muddy)
- [ ] Fits thematic palette (Xochimilco/Aztec)
- [ ] No clicks/pops at start or end
- [ ] Duration appropriate (not too long)

**Fatigue Test** (Critical):
- [ ] Listen to sound 50 times in 3 minutes
- [ ] Still pleasant? Not annoying?
- [ ] Pitch variation working? (if applicable)
- [ ] Would you want to hear this again?

**Context Tests**:
- [ ] Works with background music (doesn't clash)
- [ ] Works with other SFX (can layer without mud)
- [ ] Clear in hectic moments (doesn't get lost)
- [ ] Supports gameplay (gives useful feedback)

**Cohesion Tests**:
- [ ] Matches music instrument palette
- [ ] Feels like same world as other SFX
- [ ] Contributes to emotional tone
- [ ] Cultural authenticity maintained

### Bug Report Template
```
Sound: SFX-XXX Name
Issue: [Description]
Context: [When does it occur?]
Expected: [What should happen?]
Actual: [What actually happens?]
Severity: [Critical/High/Medium/Low]
Repro Steps: [How to reproduce]
```

---

## X. ACCESSIBILITY CONSIDERATIONS

### Visual Impairment Support
- **Spatial Audio**: All important sounds (danger, collectibles) use stereo panning for direction
- **Distinct Timbres**: Each gameplay element has unique sound (no confusion between flower and star)
- **Verbal Cues** (Optional): Consider adding subtle voice whispers for critical events (accessibility toggle)

### Hearing Impairment Support
- **Visual Redundancy**: Every sound has visual feedback (particle, UI, animation)
- **Subtitles for Narrative Sounds**: Boss roars, victory fanfares have on-screen text
- **Vibration Patterns**: Controller rumble patterns match sound rhythms (jump = short pulse, hurt = long pulse)

### Sensory Sensitivity Support
- **Volume Control Per Category**: Separate sliders for SFX, Music, Ambience
- **Disable Warning Sounds**: Toggle for low health heartbeat, danger alerts (can cause anxiety)
- **Simplified Audio Mode**: Reduces layering complexity, removes high-frequency sparkles

---

## XI. CULTURAL AUTHENTICITY NOTES

### Respectful Use of Indigenous Instruments
- **Huehuetl & Teponaztli**: Used in ceremonial contexts (boss battles, world transitions), not casual gameplay
- **Conch Shell**: Reserved for significant moments (victories, level transitions), honors ceremonial significance
- **Research-Informed**: Instrument choices based on Aztec musical archaeology, not assumptions

### Avoiding Stereotypes
- **No Mariachi**: While culturally rich, mariachi is not historically Aztec or appropriate for Xochimilco's pre-colonial themes
- **No Generic "Mexican" Tropes**: No sombreros, mustaches, or tourist clichés
- **Ecological Accuracy**: Sounds reflect actual Xochimilco ecosystem (frogs, herons, insects native to region)

### Community Consultation (Recommended)
- **Beta Test with Mexican Players**: Gather feedback on cultural representation
- **Consultant Review**: Consider hiring Mexican game audio consultant to review final SFX palette
- **Sensitivity Readers**: Ensure no unintended cultural insensitivity

---

## XII. FINAL DELIVERABLES

### Complete SFX Package (30+ Sounds)
```
Movement: 10 sounds (jump, land, footsteps, swim)
Combat: 5 sounds (stomp, hurt, attack variants)
Collectibles: 4 sounds (flower, star, powerup, baby)
UI: 7 sounds (menu navigation, pause, transitions, death)
Environment: 8 sounds (checkpoint, secret, ledge, water, boats)
Boss: 4 sounds (roars, defeats)
Danger: 2 sounds (alert, low health)
Total: 40+ unique sounds + variants
```

### Documentation
- [x] This specification document
- [ ] Implementation guide for engineers
- [ ] Sound mixing reference chart
- [ ] Accessibility feature documentation

### Quality Standards
- **Technical**: 48kHz, 16-bit, OGG format, -6dB normalized
- **Artistic**: Cohesive palette, fatigue-tested, culturally respectful
- **Functional**: Clear feedback, supports gameplay, emotionally resonant

---

## XIII. BUDGET & RESOURCE ESTIMATES

### AI Generation Costs
- **Suno Pro**: $10/month (500 generations) - sufficient for iteration
- **ElevenLabs SFX**: $22/month (basic tier) - optional, good for layered sounds
- **Estimated Total**: $32/month for 2 months production = ~$64

### Labor (If Using Professional Sound Designer)
- **Hourly Rate**: $50-100/hour (indie game audio designer)
- **Estimated Hours**:
  - Sound generation/selection: 40 hours
  - Editing/mastering: 30 hours
  - Implementation testing: 20 hours
  - **Total**: 90 hours × $75/hr = $6,750

### Hybrid Approach (Recommended)
- **AI Generation**: 70% of sounds via Suno/AI tools
- **Manual Polish**: Edit in Audacity/Reaper (free tools)
- **Professional for Key Sounds**: Commission 5-10 critical SFX (baby rescue, boss roars) = ~$500-1000
- **Total Budget**: $500-1000 + AI subscription = ~$600-1100

---

## XIV. SUCCESS METRICS

### Quantitative Goals
- [ ] 100% of placeholder SFX replaced
- [ ] 0 audio bugs in QA testing
- [ ] <100MB total SFX file size (optimized)
- [ ] <5ms audio latency in game engine

### Qualitative Goals
- [ ] Playtester feedback: "Sounds fit the game perfectly"
- [ ] No fatigue complaints after 1-hour play sessions
- [ ] Cultural authenticity validated by Mexican players
- [ ] Memorable audio moments (players hum/reference sounds)

### Emotional Goals (The Real Metrics)
- Does rescuing a baby axolotl make you tear up? (Success)
- Does jumping feel satisfying after 1000 jumps? (Success)
- Does boss entrance send chills? (Success)
- Does collecting flowers feel rewarding? (Success)

---

## CONCLUSION

This specification provides a complete roadmap to replace Xochi's generic placeholder sounds with an authentic, emotionally resonant, and culturally respectful audio palette. Every sound is designed to reinforce the game's unique identity: a magical axolotl warrior navigating the ancient, bioluminescent canals of Xochimilco.

**Key Takeaways**:
1. **Water + Nature + Ancient Culture** = Xochi's sonic identity
2. **Fatigue prevention** is non-negotiable (100+ jump sounds per session)
3. **Cohesion with music** through shared instrument palette
4. **Cultural respect** via research and potential community consultation
5. **Game feel first** - every sound must make actions satisfying

**Next Steps**:
1. Review this spec with team
2. Prioritize Phase 1 sounds (core gameplay)
3. Begin AI generation using provided prompts
4. Test in-game and iterate based on feel
5. Celebrate when you hear players humming your sounds

**The Goal**: Create sound effects so good that players turn the volume UP, not down.

---

**Good luck, sound warrior. The canals await your audio magic.**

---

*Document Version: 1.0*
*Date: 2026-01-25*
*Author: UX Game Designer Specialist*
*Status: SPECIFICATION COMPLETE - READY FOR IMPLEMENTATION*

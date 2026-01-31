# Xochi Game - Manual Testing Checklist

This checklist provides step-by-step instructions to manually test the Xochi game and verify all features work correctly.

**Game URL:** https://vaguiarl.github.io/Xochi/

---

## Quick Start Testing (5 minutes)

### 1. Load the Game
- [ ] Navigate to https://vaguiarl.github.io/Xochi/
- [ ] Observe loading bar appears with "Loading..." text
- [ ] Wait for loading to complete (should see menu within 3-5 seconds)
- [ ] Verify page title is "Xochi - Axolotl Adventure"

### 2. Menu Interaction
- [ ] Verify menu displays with animated background
- [ ] Check "XOCHI" title is visible and centered
- [ ] Look for "NEW GAME" and "PLAY/CONTINUE" buttons
- [ ] Verify score display shows current and high scores
- [ ] Check difficulty selector shows Easy/Medium/Hard buttons

### 3. Start New Game
- [ ] Click "NEW GAME" button
- [ ] Observe world intro (should show "Canal Dawn - El Amanecer")
- [ ] Wait for intro to fade and level to load
- [ ] Verify you're in Level 1 with player character visible

### 4. Basic Movement Test
- [ ] Press Right Arrow or D key - character should move right
- [ ] Press Left Arrow or A key - character should move left
- [ ] Press X key - character should jump
- [ ] Press Space while moving - character should run faster
- [ ] Press Z key - character should perform attack animation

### 5. Verify Game Runs
- [ ] Game doesn't crash or freeze
- [ ] Character can move around level
- [ ] Collect at least one flower (coin) - should see score increase
- [ ] No console errors in browser DevTools (F12)

---

## Detailed Testing (30 minutes)

### Menu Testing

#### 3.1 Difficulty Settings
- [ ] Select "EASY" difficulty
  - [ ] Description shows "5 lives, 3 super jumps, easier gaps"
  - [ ] Game remembers selection when returning to menu
- [ ] Select "MEDIUM" difficulty
  - [ ] Description shows "3 lives, 2 super jumps, balanced"
- [ ] Select "HARD" difficulty
  - [ ] Description shows "2 lives, 1 super jump, challenging"

#### 3.2 World Selection
- [ ] World buttons visible at bottom of menu (W1-W6)
- [ ] Click on World 1 (W1) - should start Level 1
- [ ] Click on World 2 (W2) - should start Level 3
- [ ] Click on World 3 (W3) - should start Level 5
- [ ] Hover over world buttons - tooltip should show world name
- [ ] Current world indicator (white border) highlights correctly

#### 3.3 Keyboard Shortcuts
- [ ] Press X key on menu - should start game
- [ ] Press SPACE on menu - should start game

---

### Gameplay - Level 1 Testing

#### 4.1 Basic Mechanics
- [ ] **Movement:** Can move left/right smoothly
- [ ] **Jumping:** Jump feels responsive with good height
- [ ] **Running:** Hold SPACE while moving to run faster
- [ ] **Falling:** Gravity feels appropriate (not too fast/slow)
- [ ] **Landing:** Landing on platforms feels solid (no clipping)

#### 4.2 Collectibles
- [ ] Collect a flower (coin) - should hear sound effect
- [ ] Collect 5+ flowers - score should increase (16 coins in Level 1)
- [ ] Collect a star (hidden) - more points than flowers
- [ ] Flowers float gently (animation appears smooth)
- [ ] Stars sparkle and rotate

#### 4.3 Enemies
- [ ] Ground enemies (Gulls) patrol on ground level
- [ ] Can defeat ground enemy by jumping on it
- [ ] Flying enemies (Herons) move in air patterns
- [ ] Touching enemy without jumping on it - should lose life
- [ ] Defeated enemy disappears

#### 4.4 Objective
- [ ] Baby axolotl visible at level end (right side)
- [ ] Baby floats with sparkle effects
- [ ] Reaching baby triggers "Baby Rescued!" message
- [ ] Screen shows celebration particles
- [ ] Level auto-completes after 2 seconds

#### 4.5 Level Progression
- [ ] After completing Level 1, automatically loads Level 2
- [ ] Can see "Level 2" in world intro
- [ ] Score accumulates across levels

---

### Gameplay - Advanced Testing (Levels 2-6)

#### 5.1 Level 2 - Floating Gardens Advanced
- [ ] More platforms and enemies than Level 1
- [ ] Moving boats (Trajineras) act as platforms
- [ ] Can platform jump across larger gaps
- [ ] More complex enemy patterns
- [ ] Baby position requires precise jumping

#### 5.2 Level 3 - Crystal Cave (Upscroller)
- [ ] Level scrolls vertically instead of horizontally
- [ ] Gravity might be inverted or altered
- [ ] Platform layout is vertical/spiral
- [ ] New music plays (different from previous levels)

#### 5.3 Level 4 - Floating Gardens
- [ ] Bright yellow/gold color scheme (different theming)
- [ ] Sky platforms higher than previous levels
- [ ] Requires running jumps to clear larger gaps

#### 5.4 Level 5 - Crystal Cave (Boss Level)
- [ ] Darker, cave-like environment
- [ ] Special boss enemy or challenging layout
- [ ] Increased difficulty spike
- [ ] World transition scene before Level 6

#### 5.5 Level 6 - Floating Gardens Continued
- [ ] New music for this world
- [ ] Escape-type level mechanics (if implemented)

---

### Mobile/Touch Device Testing (if available)

#### 6.1 Touch Controls Detection
- [ ] On mobile browser, navigate to game
- [ ] Verify touch controls appear (circular buttons at bottom)
- [ ] Left side has movement buttons (D-pad style)
- [ ] Right side has action button (jump)

#### 6.2 Movement Control
- [ ] Tap left button to move left
- [ ] Tap right button to move right
- [ ] Drag left button away from center for running
- [ ] Movement feels responsive

#### 6.3 Action Controls
- [ ] Tap right button to jump
- [ ] Swipe on right button to attack
- [ ] Hold right button for super jump (if available)

#### 6.4 Responsive Layout
- [ ] Portrait mode (480x800): Game scales properly
- [ ] Landscape mode (800x480): Game scales properly
- [ ] Touch buttons stay in corners
- [ ] Game is playable at all orientations

---

### Audio Testing

#### 7.1 Music
- [ ] [ ] Menu: Ambient background music plays
- [ ] Level 1: Different music from menu (gardens theme)
- [ ] Level 2: Music continues
- [ ] Level 3: Music changes for new world
- [ ] Level 5: Boss music (if different)
- [ ] Music loops seamlessly without gaps
- [ ] Music volume is reasonable (not too loud/soft)

#### 7.2 Sound Effects
- [ ] Jump: "Jump" sound plays when jumping
- [ ] Land: "Land" sound plays when hitting ground
- [ ] Collect flower: Coin/pickup sound plays
- [ ] Collect star: Different sound for star
- [ ] Enemy defeat: Hit sound effect
- [ ] Baby rescue: Victory/celebration sound

#### 7.3 Audio Controls
- [ ] Game remembers music preference if toggled
- [ ] Game remembers SFX preference if toggled

---

### Save System Testing

#### 8.1 Progress Saving
- [ ] Complete Level 1 (rescue baby)
- [ ] Return to menu (ESC key)
- [ ] Reload browser page (F5)
- [ ] Menu should show you're at Level 2
- [ ] Score should be preserved

#### 8.2 High Score Tracking
- [ ] Complete a level with high flower collection
- [ ] Note the score
- [ ] Fail or complete another level with lower score
- [ ] Return to menu - high score should still be highest

#### 8.3 Unlocks
- [ ] Collect all available items
- [ ] Return to menu
- [ ] Check if customization options appear
- [ ] Collected items should persist

---

### Controls Verification

#### 9.1 Keyboard Layout
Test with keyboard:
- [ ] Arrow keys: Left, Right, Up, Down
- [ ] WASD: A (left), D (right), W (up), S (down)
- [ ] Space: Run/accelerate
- [ ] X: Jump
- [ ] Z: Attack
- [ ] ESC: Pause menu

#### 9.2 Control Response
- [ ] Controls feel responsive (minimal input lag)
- [ ] No key repeat issues
- [ ] Can press multiple keys simultaneously
- [ ] Actions execute immediately on input

---

### UI Elements Testing

#### 10.1 On-Screen Display
- [ ] HUD (Heads-Up Display) visible while playing
- [ ] Life counter shows current lives
- [ ] Score display updates in real-time
- [ ] Level indicator shows current level
- [ ] World name displayed at level start

#### 10.2 Messages
- [ ] "Baby Rescued!" appears when completing level
- [ ] World intro text appears at level start
- [ ] Enemy defeat shows visual feedback
- [ ] Collectible pickup shows +points feedback

#### 10.3 Pause Menu
- [ ] ESC key opens pause menu
- [ ] Game freezes while paused
- [ ] Can resume game
- [ ] Can return to menu from pause

---

### Edge Cases & Stress Testing

#### 11.1 Quick Succession
- [ ] Collect many flowers rapidly - no lag
- [ ] Jump repeatedly - smooth animation
- [ ] Defeat multiple enemies quickly - no crashes

#### 11.2 Boundary Testing
- [ ] Walk off edge of level - should fall or respawn
- [ ] Jump at extreme angle - behaves correctly
- [ ] Platform edges are well-defined

#### 11.3 Window Resizing (Desktop)
- [ ] Resize browser window while playing
- [ ] Game should rescale smoothly
- [ ] Game should remain playable at all sizes
- [ ] Touch buttons should reposition

#### 11.4 Long Play Session
- [ ] Play through multiple levels without closing
- [ ] No memory leaks or slowdown
- [ ] Game remains smooth and responsive

---

### Error Scenarios

#### 12.1 Expected Failure Cases
- [ ] Fall off bottom of level - respawn at checkpoint
- [ ] Touch enemy without jumping on it - lose life
- [ ] Lose all lives - game over screen appears
- [ ] Browser console (F12) shows no errors

#### 12.2 Network Issues
- [ ] If assets fail to load - game should handle gracefully
- [ ] If music fails to load - game continues without audio

---

## Issues Reporting Format

If you find any issues during testing, please report them with:

1. **What happened:** (description of the issue)
2. **When it happened:** (which level, what action)
3. **Expected behavior:** (what should have happened)
4. **Steps to reproduce:** (numbered list)
5. **Browser/Device:** (Chrome, Safari, mobile, etc.)
6. **Severity:** (Critical, Major, Minor)

**Example:**
- **What happened:** Game crashed when collecting 10th flower
- **When it happened:** Level 2, right side of level
- **Expected behavior:** Should continue playing, score should increase
- **Steps to reproduce:**
  1. Start Level 2
  2. Move to right side
  3. Collect 9 flowers quickly
  4. Collect the 10th flower
- **Browser:** Chrome 120 on Windows 10
- **Severity:** Critical

---

## Quick Test Summary Sheet

### Core Features Checklist
- [ ] Game loads without errors
- [ ] Menu system works
- [ ] Can start new game
- [ ] Keyboard controls work
- [ ] Touch controls work (if on mobile)
- [ ] Can complete Level 1
- [ ] Music plays
- [ ] Sound effects play
- [ ] Score increases
- [ ] Progress saves
- [ ] Game scales to different screen sizes

### Features to Highlight
- **6 Worlds:** Canal Dawn, Bright Trajineras, Crystal Cave, Floating Gardens, Night Canals, Grand Festival
- **10 Levels:** Mix of standard and special (boss, upscroller, escape)
- **Multiple Difficulties:** Easy, Medium, Hard with scaled mechanics
- **Responsive Design:** Works on desktop, tablet, and mobile
- **Touch Support:** Full mobile touch controls
- **Save System:** Progress and scores persist
- **Collectibles:** Flowers, stars, power-ups, baby axolotls

---

## Testing Completion Criteria

You can consider testing complete when:

- [ ] All menu features tested
- [ ] Levels 1-3 completed successfully
- [ ] Keyboard controls verified working
- [ ] Mobile controls tested (if applicable)
- [ ] Audio tested
- [ ] Save system tested
- [ ] Game runs without errors for 30+ minutes
- [ ] No critical or major issues found
- [ ] Game is responsive at different viewport sizes

---

**Last Updated:** January 30, 2026
**Test Version:** 1.0

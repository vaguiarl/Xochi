# Xochi Music System - Audio File Structure

This directory contains all music files for the Xochi dynamic music system.
See `/sfx/XOCHI_MUSIC_SPECIFICATION.md` for full musical requirements.

## Directory Structure

```
music/
  world1/           # Canal Dawn (Levels 1-2)
  world2/           # Bright Trajineras (Levels 3-4)
  world3/           # Crystal Cave (Level 5 Boss)
  world4/           # Floating Gardens (Levels 6-7)
  world5/           # Night Canals (Levels 8-9)
  world6/           # La Gran Fiesta (Level 10 Final Boss)
  boss/             # Boss battle tracks with phase variations
  stingers/         # Short musical cues (victory, death, etc.)
```

## File Naming Convention

### World Tracks (4 stems per track)
Each track type requires 4 stem files for dynamic mixing:
- `{tracktype}_base.ogg` - Pads, ambient textures (always plays)
- `{tracktype}_percussion.ogg` - Drums, shakers (intensity-based)
- `{tracktype}_harmony.ogg` - Bass, harmonic layers
- `{tracktype}_melody.ogg` - Lead instruments, motifs

**Track Types per World:**
- `peace.ogg` / `peace_*.ogg` - Exploration music
- `chase.ogg` / `chase_*.ogg` - Platforming/action music
- `underwater.ogg` / `underwater_*.ogg` - Swimming sections
- `upscroller.ogg` / `upscroller_*.ogg` - Rising water sections
- `menu.ogg` / `menu_*.ogg` - Hub/menu music

**Example (World 1 Peace track with stems):**
```
world1/
  peace_base.ogg
  peace_percussion.ogg
  peace_harmony.ogg
  peace_melody.ogg
```

**Fallback:** If stems are not available, the system will look for a single file:
```
world1/peace.ogg
```

### Boss Tracks
Located in `boss/` directory with phase-based naming:

**Boss 1 (World 5 - Night boss):**
- `boss1_approach.ogg` or stems (`boss1_approach_base.ogg`, etc.)
- `boss1_telegraph.ogg`
- `boss1_attack.ogg`
- `boss1_recover.ogg`

**Boss 2 (World 6 - Final boss):**
- `boss2_approach.ogg`
- `boss2_telegraph.ogg`
- `boss2_attack.ogg`
- `boss2_recover.ogg`

### Stingers
Located in `stingers/` directory:
- `victory.ogg` - Level complete (6 seconds)
- `baby_rescue.ogg` - Baby rescued (3 seconds)
- `checkpoint.ogg` - Checkpoint reached (2 seconds)
- `danger.ogg` - Enemy proximity alert (1.5 seconds)
- `world_transition.ogg` - New world fanfare (8 seconds)
- `death.ogg` - Player death (3 seconds)
- `level_complete.ogg` - Alternative victory stinger

## Technical Specifications

- **Format:** OGG Vorbis (preferred) or WAV
- **Sample Rate:** 48kHz
- **Bit Depth:** 24-bit
- **Normalization:** -3dB peak
- **Loop Points:** Stems must have identical length for seamless layering

## Stem Volume Presets (Reference)

The music system automatically adjusts stem volumes based on game context:

| Track Type   | Base | Percussion | Harmony | Melody |
|--------------|------|------------|---------|--------|
| Peace        | 100% | 30%        | 70%     | 50%    |
| Chase        | 80%  | 100%       | 50%     | 70%    |
| Underwater   | 100% | 20%        | 90%     | 60%    |
| Upscroller   | 70%  | 100%       | 40%     | 80%    |
| Menu         | 100% | 20%        | 80%     | 60%    |
| Boss Approach| 100% | 20%        | 20%     | 20%    |
| Boss Telegraph| 80% | 60%        | 30%     | 40%    |
| Boss Attack  | 100% | 100%       | 100%    | 100%   |
| Boss Recover | 90%  | 30%        | 50%     | 20%    |

## Fallback Behavior

If audio files are not present, the system automatically falls back to the
built-in MariachiMusic (La Cucaracha) placeholder. This ensures the game
remains playable while music assets are being developed.

Console messages will indicate which tracks are missing:
```
[XochiMusic] Track not found: world1_peace
[XochiMusic] Using MariachiMusic fallback
```

## Adding New Music

1. Generate/create tracks following the spec in XOCHI_MUSIC_SPECIFICATION.md
2. Extract stems using iZotope RX, Moises.ai, or LALAL.AI
3. Export as 48kHz/24-bit OGG files
4. Place in appropriate directory following naming convention
5. Test in-game to verify loop points and stem synchronization

## Crossfade Durations (Reference)

The system uses these crossfade durations for transitions:
- Peace to Underwater: 1000ms
- Chase to Peace: 1500ms
- Any to Upscroller: 300ms (urgent)
- Upscroller to Any: 1000ms
- Any to Menu: 2000ms
- World Transition: 1000ms fade out + stinger + 1000ms fade in

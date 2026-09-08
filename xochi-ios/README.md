# Xochi: The Song Home — iOS MVP

A complete, compact platforming chapter through the floating gardens of Xochimilco. Xochi brings three little friends home after a storm and helps her frightened reflection let go. English and Spanish are included.

Version **0.1.0 (1)** was successfully uploaded to TestFlight on 8 September 2026. Apple reported that the package was processing. See [upload receipt](ios/TESTFLIGHT-UPLOAD.md) and [verification record](TEST-RESULTS.md).

This is a standalone Godot 4.7 project in the existing Xochi repository. The original `xochi-godot` campaign remains intact. The chapter uses native Godot rendering and physics, with a narrow Swift bridge for Apple speech and optional Foundation Models support.

## Play

Open `project.godot` in Godot 4.7 and press Run, or run:

```sh
godot --path xochi-ios
```

| Action | Touch | Keyboard |
| --- | --- | --- |
| Travel | Swipe left/right and keep the finger down; release to coast | Arrows or A / D |
| Sprint | Two swipes in the same direction | Hold Shift while moving |
| Jump | Swipe up | Space |
| Hyper-jump | Tap; a second finger can tap while moving | X |
| Ripple Pop | Hold for 400 ms; a second finger can hold while moving | Z |
| Second Wind | Courage button or optional voice encouragement | C |
| Pause / resume | Pause button | Escape |

Two hyper-jumps are available per garden pocket. Courage grants one reserve jump, spent after the regular charges. Once earned, that reserve returns on every retry until the next checkpoint. Quiet Courage and voice encouragement have identical gameplay effects. Speaking is optional.

## Complete chapter

- Three traversal challenges and a final reflection encounter, with short checkpoint resets and unlimited attempts.
- Crow attacks predict once, visibly warn, then commit. Jaguars stalk, warn, pounce and recover. Their aim never follows a dodging player perfectly.
- The reflection alternates readable landing attacks and low waves, then opens for a Ripple. Three successful openings resolve the encounter.
- The music keeps its playback position through death, retries and pause. The reunion crossfades into the original finale music.
- Soft, weapon-free Xochi with prerendered movement/jump/Ripple art, marigold and jade scarf; a matching reflection and little friends.
- Rendered dawn canal plate, textured stone quays and painted trajineras, plus animated water glints, motes, foreground leaves and moving platforms.
- Versioned local progress, atomic replacement and a previous-save backup. Invalid saves recover safely. Checkpoints preserve only earned flower collection.
- A title, story opening, control instructions, pause menu, music toggle, resume, ending, flower count and replay loop.

This is deliberately a short first chapter. The validated expert route is approximately 34 seconds of simulated play; first-time discovery and retries take longer. Difficulty and comfort still benefit from people playing on actual phones.

## Validation

Run from this directory with Godot 4.7:

```sh
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/player_spec.gd
godot --headless --path . --script res://tests/enemy_spec.gd
godot --headless --path . --script res://tests/progress_spec.gd
godot --headless --path . --script res://tests/lifecycle_spec.gd
godot --headless --path . --script res://tests/voice_spec.gd
godot --headless --path . -- --mvp-smoke
godot --headless --path . --script res://tests/full_route_spec.gd
```

The full-route test starts through the menu and intro buttons and drives actual touch events. It does not teleport Xochi, give extra powers, override immunity, or call checkpoint/win shortcuts. Separate unit/setup probes deliberately isolate failure cases and are not presented as gameplay completion.

`tests/capture_spec.gd` renders six visual fixtures with a real display; its explicit scene setups are for layout review. Generated captures and build outputs are ignored by Git.

## Files

| File | Responsibility |
| --- | --- |
| `scripts/main.gd` | Chapter layout, checkpoint/retry state, audio, localized screens, story and finale |
| `scripts/player.gd` | Touch ownership, movement, jump buffering, coyote time, finite inertia and Xochi animation |
| `scripts/enemy.gd` / `boss.gd` | Deterministic, telegraphed combat with vulnerable recovery windows |
| `scripts/platform.gd` / `scenery.gd` | Moving collision surfaces, rendered art and inexpensive animation |
| `scripts/progress.gd` | Validated local save and backup recovery |
| `scripts/ui_input.gd` | Pause-safe interface input |
| `scripts/voice_support.gd` / `ios/` | Native optional cheering and iOS build integration |
| `assets/ART-PROMPTS.md` | Production image prompts and reference provenance |

Music and sound effects come from the existing Xochi project. Cormorant Garamond and Nunito use the bundled SIL Open Font Licenses. Production artwork was generated with the built-in ImageGen tool and is stored in `assets/`; no external image URLs are needed at runtime.

See `ios/` for native build details and the recorded device/simulator validation boundaries. Signing and physical-device distribution require the project's Apple development team.

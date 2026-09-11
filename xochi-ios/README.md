# Xochi — La fiesta de las voces

A Spanish-learning companion encounter through the floating gardens of Xochimilco. Hear an instruction, say or choose its meaning, and Xochi carries out the plan. Swipe at any moment to take over movement. The first encounter brings her friends past the Crowquistador to a small reunion.

See the [latest TestFlight receipt](ios/TESTFLIGHT-UPLOAD.md) and [verification record](TEST-RESULTS.md). Version 0.1.0 build 3 introduces the companion encounter.

This is a standalone Godot 4.7 project in the existing Xochi repository. It uses native rendering and physics with a narrow Swift bridge for on-device speech recognition and authored Spanish speech examples. Common directions use deterministic parsing, without a language-model dependency. The original `xochi-godot` campaign and earlier iOS traversal chapter remain available in source.

## Play

Open `project.godot` in Godot 4.7 and press Run, or run:

```sh
godot --path xochi-ios
```

## The companion crossing

- Eight authored steps introduce and reuse **ven**, **espera**, **al bote**, **ahora, salta** and **al puente**. Meanings choose the next physical action; simply walking to the ending cannot skip the lesson sequence.
- **Hear it** replays the Spanish through native speech synthesis. **Speak** listens for one short finalized direction on supported iPhones. When native recognition is unavailable, it opens a typed-guidance alternative. Touch choices remain available throughout.
- Interface language and listening language are independent. The interface supports English/Spanish; listening defaults to Spanish, with English rescue configurable from Pause.
- Xochi makes a small safe exploration, then follows bounded walk/jump plans using real collision and the ordinary double jump. She waits before new hazards. A new swipe immediately cancels automatic steering and stale voice results.
- Crowquistador retains his helmet, plume and little sword. He notices, investigates and returns; repeated distractions have shorter but still usable openings. An opening freezes while the player speaks and always returns if missed. Calabrija uses the original decorated flying-skull art.
- Correct choices earn evidence only after the action completes. Hints, typed input, Spanish speaking practice and independent touch choices are recorded separately. These are practice observations, not pronunciation or fluency grades.
- Unlimited 0.48-second Rejoin resets the unfinished step and preserves previous evidence. The original opening-world song, **Traviesa Axolotla en Xochimilco**, keeps its timeline through lessons, pause, retry and reunion; the mix softens briefly for speech.
- Local learning progress uses its own versioned save and leaves the earlier campaign save untouched.

This is a playable first encounter for testing the concept with learners. It is not a full Spanish course, and neither retention nor player enjoyment has been established by automated tests. See [the encounter notes](COMPANION-ENCOUNTER.md).

| Action | Touch | Keyboard |
| --- | --- | --- |
| Travel | Swipe left/right and keep the finger down; release to coast | Arrows or A / D |
| Sprint | Two swipes in the same direction | Hold Shift while moving |
| Jump | Swipe up | Space |
| Double jump | Swipe up again in the air; restores on landing | Space again in the air |
| Hyper-jump | Tap; a second finger can tap while moving | X |
| Ripple Pop | Hold for 400 ms; a second finger can hold while moving | Z |
| Guidance | Hear / Speak / two meaning choices | Type in the guidance dialog |
| Pause / resume | Pause button | Escape |

One ordinary double jump is available each time Xochi leaves the ground and restores on landing. It does not spend a hyper-jump. The companion encounter provides two hyper-jumps per retry for hands-on movement. Voice recognition errors cost no lives or progress.

## Earlier traversal chapter

The earlier iOS chapter remains at `main.tscn` and can be run with `godot --path xochi-ios res://main.tscn`. Its Courage/Second Wind feature and original save remain separate from companion learning.

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
godot --headless --fixed-fps 60 --path . --script res://tests/companion_route_spec.gd
godot --headless --path . --script res://tests/companion_controller_spec.gd
godot --headless --path . --script res://tests/companion_voice_spec.gd
godot --headless --path . --script res://tests/companion_scene_voice_spec.gd
godot --headless --path . --script res://tests/crow_guard_spec.gd
godot --headless --path . --script res://tests/learning_progress_spec.gd
godot --headless --path . --script res://tests/player_spec.gd
godot --headless --path . --script res://tests/enemy_spec.gd
godot --headless --path . --script res://tests/progress_spec.gd
godot --headless --path . --script res://tests/lifecycle_spec.gd
godot --headless --path . --script res://tests/voice_spec.gd
godot --headless --path . res://main.tscn -- --mvp-smoke
godot --headless --path . --script res://tests/full_route_spec.gd
```

The companion route activates displayed buttons and uses real physics through all eight steps; actual touch events test takeover. It also exercises a missed crow opening, pause during Rejoin and unchanged real save files. The earlier full-route test drives actual touch events through the original chapter. Neither route teleports Xochi, grants powers or directly triggers completion. Separate setup probes isolate failure cases and are not gameplay-completion evidence.

`tests/companion_capture_spec.gd` renders seven companion screens with a real display. `tests/capture_spec.gd` covers the earlier chapter. Their explicit scene setups are for layout review. Generated captures and build outputs are ignored by Git.

## Files

| File | Responsibility |
| --- | --- |
| `scripts/companion_main.gd` | Learning sequence, fixed encounter layout, UI, retry, story and music |
| `scripts/companion_controller.gd` | Bounded, interruptible movement plans and safe landing checks |
| `scripts/spanish_intents.gd` / `companion_voice.gd` | Authored bilingual directions, one-utterance native sessions and typed fallback |
| `scripts/learning_progress.gd` | Separate validated learning-evidence save |
| `scripts/crow_guard.gd` / `calabrija.gd` | Restored characters, visible guard states and repeated-trick response |
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

# Xochi — La fiesta de las voces

A Spanish-guided canal adventure: rescue two babies and Rabbitbrije, then escape aboard Esperanza. Follow Spanish clues, choose a destination and guide Xochi, or take over with touch. Physical arrivals rescue friends immediately.

Build 5 replaces the eight-step lesson gate with the Trajinera Rescue. See [gameplay details](COMPANION-ENCOUNTER.md), [verification](TEST-RESULTS.md), and [TestFlight status](ios/TESTFLIGHT-UPLOAD.md).

This is a standalone Godot 4.7 project in the existing Xochi repository. It uses native rendering and physics with a narrow Swift bridge for on-device speech recognition and authored Spanish speech examples. Common directions use deterministic parsing. On compatible devices, optional Apple Intelligence interprets a natural Spanish or English direction into the same bounded actions. The original `xochi-godot` campaign and earlier iOS traversal chapter remain available in source.

Run the current encounter checks with `./tests/run_rescue_checks.sh`.

## Play

Open `project.godot` in Godot 4.7 and press Run, or run:

```sh
godot --path xochi-ios
```

## The Trajinera Rescue

1. Meet the baby by the first lantern: **Ven**. Walking there also rescues the baby.
2. Board **La Lupita**, ride the canal, then choose **Jardín**. Boats wait two seconds at each end of an eight-second route.
3. Read the crow's warning. **Espera** in reeds hides Xochi; **Mira allá** sends Calabrija to the bell. Reach Rabbitbrije to rescue him.
4. Cross the chinampa to **Frida**, carrying the second baby. Ordinary double-jumps work; hyper-jumps are optional.
5. Cross the final guarded bridge and board **Esperanza** with all three friends. Its departure leads to the ending. Arriving early identifies a missing friend and offers a return plan.

Tap a destination marker, then **Guide**. **Speak** accepts a short Spanish or English direction at a safe refuge or aboard a boat. Pause → **Type a plan** provides the same exact-command path without a microphone. Hear replays an authored Spanish cue; `?` provides English support. Boat names can be spoken or typed directly.

| Action | Touch | Keyboard |
| --- | --- | --- |
| Move | Swipe left/right and hold | Arrows / A, D |
| Sprint | Two swipes in the same direction | Shift + move |
| Jump / double jump | Swipe up, then again in the air | Space, then Space |
| Hyper-jump | Tap open playfield | X |
| Distract | Mira allá | Type “mira allá” / “look over there” |
| Guide | Select marker, then Guide | Type one direction |
| Pause | Pause | Escape |

Manual touch cancels automatic steering. Destination and HUD taps are consumed before world input. The crow has a 0.75-second warning, a 255 px/s chase, sight-loss search after 1.5 seconds and repeatable four-to-three-second distractions. Followers never trigger detection or strand the party. Retries regroup at a lantern after 0.48 seconds, retaining rescued friends and the continuous Suno song, **Traviesa Axolotla en Xochimilco**.

Rescue checkpoints have a separate versioned sidecar beside the learning save; old lesson completion does not complete the new adventure. Manual rescue never fabricates language evidence. Touch directions with visible help are assisted practice, not independent mastery.

**Apple Intelligence remains experimental and optional.** Exact commands bypass the model. The prior host model probe missed its five-second deadline; compatible-iPhone natural-language quality and latency still need human validation. Speech and interpretation pause local boat/guard clocks only from safe planning locations. No transcript or model output is saved.

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
GODOT_BIN=godot ./tests/run_rescue_checks.sh
```

The current rescue suite completes three routes: real screen-touch Guide buttons, direct touch movement, and exact bilingual command delivery. All use real physics without teleporting Xochi or forcing rescue/ending state. Separate state fixtures cover pursuit, hiding, catch/retry, planning clocks, save reload and input cancellation. Native speech/model quality and novice enjoyment require physical-device play.

`tests/rescue_capture_spec.gd` renders opening/garden layout fixtures with a real display. The older `companion_*` scene/route and crow fixtures describe the retired eight-lesson prototype. The earlier traversal chapter remains covered by `full_route_spec.gd`, `lifecycle_spec.gd`, `enemy_spec.gd`, `progress_spec.gd` and `voice_spec.gd`. Generated captures and build products are ignored.

## Files

| File | Responsibility |
| --- | --- |
| `scripts/rescue_main.gd` | World progression, route plans, camera, checkpoints, HUD and departure |
| `scripts/trajinera.gd` / `rescue_friend.gd` | Named moving decks, rescue events and visible followers |
| `scripts/companion_main.gd` | Shared menu, pause, native voice dialog and uninterrupted music; earlier prototype |
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

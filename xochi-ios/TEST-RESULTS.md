# MVP verification — 11 September 2026

Project: Xochi: The Song Home 0.1.0, build 4. Godot 4.7 stable; native plugin and iPhone archive built with Xcode 26.6 / iOS 26.5 SDK. The minimum supported OS is iOS 26.

## Build 4 Apple Intelligence guidance — 11 September 2026

- Exact phrase parsing remains immediate. Optional Foundation Models interpretation returns constrained directions, while the existing scene decides whether they match the current lesson and the controller handles physical movement.
- CompanionVoiceSpec passes with a fake native bridge: typed and finalized spoken interpretation, exact fast path, unsupported states, independent typed/microphone availability, unknown-language provenance, invalid outputs, duplicate/stale results, background/locale/new-context cancellation and the six-second watchdog.
- CompanionSceneVoiceSpec passes through the real scene/controller: a natural Spanish transcript enters interpretation without movement, preserves the real crow opening across an old microphone terminal callback and inference delay, then performs a jump to the actual bank. Model-inferred practice stays separate from exact phrases. The real typed form routes through the shared adapter; wrong AI meanings and stale paused requests cannot advance the lesson. Saves are isolated and the real save bytes remain unchanged.
- CompanionRouteSpec still completes the eight displayed steps using real physics, with wrong-choice, retry, pause, touch takeover and continuous-song checks. Latest route duration: 20.72 simulated seconds. This is route validation, not human learning evidence.
- LearningProgressSpec and legacy VoiceSpec pass. The learning save accepts optional separate interpreted spoken/typed counters without discarding existing version-1 progress.
- The compact typed form keeps Send and Back beside the field and reserves space above the native keyboard. Spanish Pause and typed layouts were visually inspected. Capture fixtures now use their own temporary save and render nine screens.
- All four final native variants compile cleanly (device/Simulator × debug/release). Complete Simulator build 4 succeeds, installs and launches. Title, guidance, capability status and compact typed layout were inspected. The form stayed above the landscape keyboard's introduction panel; interaction with the completed keyboard was interrupted by simulator computer-use errors and remains unverified.
- Native request-shape guard: **15/15 PASS** using extracted production logic. It rejects praise, quoted stories, explanation requests, negation and sequences before inference, and admits the intended polite English/Spanish requests.
- Final real host-model probe: **9/15 PASS, 6 timeouts**. This was one process, a fresh single-use model session per request, five seconds of preparation and the app's five-second inference limit. All nine deterministic negative cases rejected; all six inference-backed cases timed out, including all five positive directions. Natural guidance is experimental. Successful build and fallback checks do not establish model usability; a compatible physical iPhone still needs semantic and latency evaluation. Reproducer: `tests/native_companion_model_probe.py`; log: `ios/build/companion-model-prewarmed-probe.log`.
- The final signed archive/upload command is currently waiting for macOS signing-key access. Build 4 has not been uploaded as of this record. `ios/build/testflight-build-upload-4-final.log` and the upload receipt record the next outcome.

## Build 3 companion encounter — 11 September 2026

- The default scene is now `companion.tscn`: eight Spanish-guided steps from the introduction to a reunion at the Crowquistador crossing. The original traversal chapter remains at `main.tscn`.
- CompanionRouteSpec passes cleanly through displayed UI buttons and real controller/physics: all eight steps, safe wrong choice, actual boat/bank landings, deferred learning credit, touch takeover, pause/Rejoin, a pause during the retry timer, returning missed crow openings, and one continuously advancing music stream. A 1420×720 viewport tests translated world coordinates. Latest route duration: 20.70 simulated seconds, including intentional waits; this is not a novice play-duration or learning-effectiveness measurement.
- CompanionControllerSpec passes for safe walks, the authored crossing, a genuine ordinary double jump, unchanged hyper stock, real input takeover and interrupted/unsafe plans. The existing PlayerSpec also passes.
- CompanionVoiceSpec and the existing VoiceSpec pass. CompanionSceneVoiceSpec additionally uses the real encounter/controller with a fake native service: it freezes an actual guard opening, accepts finalized “Ahora, salta.”, reaches the bank physically, rejects stale results after a swipe, protects active guided jumps, separates typed evidence, and checks microphone pause/resume. Its explicit stage fixture is not full-route evidence, and its fake microphone is not physical-device evidence.
- CrowGuardSpec passes for committed notice/investigation/return, nonlethal crossing observation, finite repeated-trick adaptation and resets. LearningProgressSpec passes for evidence separation, save round trip and invalid-data rejection.
- The earlier full traversal route still passes: 3/3 friends, zero deaths and three boss openings in 33.63 simulated seconds. Its longstanding audio/resource teardown warnings remain; the new companion route exits cleanly.
- All four native voice-plugin variants compile (iPhone/Simulator, debug/release). The final complete Simulator app builds, installs and launches on the iPhone 12 mini simulator with iOS 26.5. The native title, introduction, lesson choice and autonomous movement were inspected. The status strip was moved above the playfield so it cannot cover Xochi's landing.
- Seven rendered companion fixtures cover title, Spanish introduction, first lesson, boat choice, guard opening, pause and ending. These are layout fixtures, not route-completion evidence. Original Calabrija art and new crow/bridge assets were inspected; the new assets have verified real transparency.
- The final signed archive completed successfully at `ios/build/Xochi-0.1.0-3.xcarchive`; `testflight-archive-3-final.log` ends with ARCHIVE SUCCEEDED. Build 3 was not uploaded and is superseded by the build 4 candidate.
- Logs: `ios/build/simulator-build-3-final.log`, `ios/build/testflight-export-3-final.log`, `ios/build/testflight-archive-3-final.log`. Captures: `tests/captures/companion/`. Generated logs/captures/build products are excluded from Git.

The physical-device checks listed below still apply, especially recognizer availability, microphone/music feedback, Spanish speech examples and varied accents. No human learning or enjoyment claim is made from these automated checks.

## Build 2 feedback iteration

- Restored one ordinary airborne jump after takeoff, recharged on landing or retry. It spends no hyper-jump charge. Coyote takeoffs preserve it; hyper jumps, pause and input clearing cannot refill a spent air jump.
- Replaced scaled radius-one enemy circles with ellipses drawn at their final size, keeping a narrow antialiased edge. Enemy targeting, collision and attack timing are unchanged.
- Expanded PlayerSpec passes at normal timing and fixed 60 fps: keyboard and repeated upward swipes, simultaneous movement touch, third-jump rejection, actual landing/retry recharge, hyper/reserve interleaving, coyote grace and landing buffers. EnemySpec also passes.
- Full real-touch input route passes: 3/3 friends, zero deaths, ten normal jumps, two hyper jumps, three boss openings and reunion in 33.45 simulated gameplay seconds. This remains route-completion evidence, not a human difficulty rating.
- Integration smoke passes; retry measured 0.48 seconds, with music continuity, pause, checkpoint/Courage persistence and ending assertions intact.
- The complete iPhone Simulator build and signed Release archive both succeed. Archive: `ios/build/Xochi-0.1.0-2.xcarchive`; its app Info.plist confirms build 2.
- Native iPhone 12 mini simulator inspection confirms the sharper crow, safe-area layout and updated opening instructions fit. Six visual fixtures also render successfully. Physical-device limitations below still apply.
- Build logs: `ios/build/simulator-build-2.log` and `ios/build/testflight-archive-2.log`. The latest upload status is recorded in `ios/TESTFLIGHT-UPLOAD.md`.

## Gameplay and state

| Check | Result and scope |
| --- | --- |
| PlayerSpec | PASS. Real collision, coyote time, buffered jumps, finite inertia, ordinary/reserve hyper-jump order, simultaneous touch ownership, cancelled touches and input clearing. |
| EnemySpec | PASS. Committed targeting, readable tells, dodges, recovery, Ripple and stomp responses, coordinated nearby attacks and deterministic resets. |
| ProgressSpec | PASS. Save round trip, backup recovery after interruption, rejected invalid shapes/types/versions/ranges. Repeated after adding a free-space check before saving. |
| LifecycleSpec | PASS. Actual Escape pause/resume, intentional retry during spawn protection, boss activation latch, stale ending cancellation, replay, exact earned-flower restoration and title camera reset. |
| VoiceSpec | PASS with a fake native service. Permission-request versus listening state, stale session/checkpoint/attempt rejection, duplicate rewards, both award callback orders, stop, cancellation, EN/ES unavailability and focus loss. No microphone access in this test. |
| Integration smoke | PASS. In-place retry, uninterrupted music stream and playback position, frozen paused physics, checkpoint/Courage persistence and ending. Latest measured retry: 0.477 seconds. |
| Full input route | PASS. Menu → intro → all checkpoints → three actual boss openings → reunion. 3/3 friends, zero deaths, ten normal jumps, two finite hyper-jumps; 33.63 seconds of expert gameplay. See `tests/full-route.log`. |
| Visual fixtures | Six rendered screens inspected: title, Spanish story, garden, pause, reflection and ending. Fixtures use explicit scene setup and are separate from gameplay completion evidence. |

The full route drives real touch events. It does not teleport, refill powers, override immunity, call checkpoint shortcuts or directly trigger victory. Its completion time establishes that the route works; it does not establish a typical first-time play duration or human difficulty rating.

## Native build

- The corrected Swift/Objective-C++ voice bridge compiles in debug and release for both iPhone arm64 and Simulator arm64.
- The complete iPhone Debug application builds and links successfully.
- The final signed Release archive builds successfully with team `PG9XGM4JLG` and bundle ID `com.vaguiarl.xochi.songhome`.
- Final export includes English/Spanish permission descriptions, the opaque app icon, and a privacy manifest limited to local file metadata (`C617.1`), elapsed-time measurement (`35F9.1`) and storage checks before saving (`E174.1`). No tracking is declared or implemented.
- The official Godot 4.7 simulator archive lacks the arm64 slice advertised in its metadata. A matching-source arm64 simulator engine built successfully, and the complete Simulator app compiled, installed and launched on an iPhone 12 mini simulator running iOS 26.5. The device archive uses the official device engine.
- Native title, opening story, landscape safe-area layout, quiet Courage reward and reunion screen were visually verified. The native integration smoke reached its ending and restored the pre-test save, confirming completion through its final assertions. No microphone was enabled during this verification.
- Apple's complete validation checks passed for the signed 0.1.0 (1) candidate. The final startup-art polish was then rebuilt into `Xochi-TestFlight.xcarchive` and launched successfully in the simulator.

## Remaining physical-device checks

Microphone recognition quality, Apple Intelligence availability and response quality, speaker feedback, headset routing, interruption continuity, battery/thermal behavior and player comfort require testing on real iPhones. A simulator and fake-native tests cannot establish these properties. Courage remains available without voice or Apple Intelligence.

The paired iPhone is currently unavailable to this Mac. TestFlight upload succeeded on 8 September 2026 at 11:34:38 local time; Apple reported that the package was processing. See `ios/TESTFLIGHT-UPLOAD.md`. Processing completion and tester-group availability have not been verified.

## Evidence locations

Generated files under `ios/build/` and `tests/captures/` are intentionally excluded from Git. Build logs: `device-build.log`, `testflight-archive.log`, `simulator-build-final.log`; final archive: `Xochi-TestFlight.xcarchive`. Production source, prebuilt voice libraries, export scripts and automated tests are tracked.

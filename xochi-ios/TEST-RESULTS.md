# MVP verification — 8 September 2026

Project: Xochi: The Song Home 0.1.0, build 1. Godot 4.7 stable; native plugin and iPhone archive built with Xcode 26.6 / iOS 26.5 SDK. The minimum supported OS is iOS 26.

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

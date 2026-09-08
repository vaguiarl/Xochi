# Xochi native iOS build

This is a native Godot 4.7 iOS application with a small Swift/Objective-C++ plugin. It uses the Compatibility renderer, an iOS 26 minimum, and arm64 device and simulator libraries. The Swift plugin and a complete device app have been compiled against Xcode 26.6; Speech recognition explicitly requires on-device recognition.

## Build

1. Install Godot 4.7 stable and its iOS export template, and Xcode 26 with its iOS Simulator runtime. Use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`; no system developer-selection change is required.
2. The prebuilt `plugins/xochi_voice/XochiVoice.debug.xcframework` and `.release.xcframework` match the official Godot 4.7 template. Each includes iPhone arm64 and Simulator arm64 slices. Do not mix Godot engine versions or debug/release plugin variants: the C++ object layout is different.
3. From the project directory, run `./ios/export_simulator.sh`. It exports and compiles an unsigned simulator application at `ios/build/SimulatorDerivedData/Build/Products/Debug-iphonesimulator/Xochi.app`. Xcode project: `ios/build/simulator/Xochi.xcodeproj`. The official 4.7 template downloaded for this build advertises arm64 simulator support but contains only x86_64 objects. Supply the matching source-built arm64 library using `GODOT_SIMULATOR_ARM64_LIBRARY`; the script validates and combines the slices before linking.
4. For a physical iPhone, run `./ios/export_device.sh` to export and compile the release engine and release plugin at `ios/build/device-release/Xochi.xcodeproj`. The unsigned release app is `ios/build/ReleaseDerivedData/Build/Products/Release-iphoneos/Xochi.app`. The verified developer team is configured in the export preset; private certificates and provisioning profiles are never stored here. Archive this release project with Xcode automatic signing for TestFlight.

The Godot exporter requires a nonempty Team ID even for simulator project export. When the preset has no team, `export_project.sh` temporarily uses the literal `UNSIGNED`, immediately clears it from the generated Xcode project, and restores the original preset. A verified real team in the preset is preserved. Debug/simulator and unsigned device build commands use `CODE_SIGNING_ALLOWED=NO`; the script never guesses a team.

To rebuild the plugin, download the official `4.7-stable` Godot source; generate `core/version_generated.gen.h`, `core/disabled_classes.gen.h`, and the extension interface header with the source's Python generators (or SCons). Set `GODOT_SOURCE` to that directory and run `./ios/build_native.sh`. The script creates separate debug/release XCFrameworks using the official template's ABI flags.

## Voice contract

GDScript accesses the `XochiVoice` singleton via `scripts/voice_support.gd`. `begin_listening(locale, checkpoint, attempt, session)` emits `cheer(checkpoint, attempt, session)` and `status(state, message, checkpoint, attempt, session)`. State is STOPPED=0, REQUESTING=1, LISTENING=2, UNAVAILABLE=3 or AWARDED=4. A new session ID is allocated for every start and stop, so old callbacks cannot affect a new request even within the same attempt. The script exposes requesting separately from listening, invalidates consumed sessions and never derives lifecycle state by parsing localized text. Game code grants one Second Wind per checkpoint and restores it on retries. The quiet Courage button grants the same power with no microphone requirement.

The microphone is opt-in, listens for at most 20 seconds, and stops on app focus loss, route changes, interruption, manual stop and game pause/death. Capture buffers, transcripts and model output are not saved. No cloud service or network client is used. `SFSpeechAudioBufferRecognitionRequest.requiresOnDeviceRecognition` is always true; unsupported devices/locales explicitly fall back to Courage.

Common English and Spanish encouragement phrases use a fast deterministic match. A final novel utterance may be classified using a typed `@Generable` Boolean decision by Apple's on-device Foundation Models model only when available. This is asynchronous, optional, cannot block movement and cannot stack rewards. Model unavailability does not disable ordinary phrases. Responses are limited to an encouragement decision; no generated story text or enemy frame logic is executed.

The shared AVAudioSession stays in PlayAndRecord with mixing and speaker output; Godot project category is `2`, and the plugin never deactivates the audio session when stopping capture. Music playback is never stopped or restarted by this service. Physical-device validation remains required for microphone recognition, Apple Intelligence availability, speaker feedback, headset routing and interruption continuity; simulator execution cannot establish those properties.

## Primary references

- https://docs.godotengine.org/en/stable/tutorials/platform/ios/ios_plugin.html
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html
- https://developer.apple.com/documentation/speech/sfspeechaudiobufferrecognitionrequest
- https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/requiresondevicerecognition
- https://developer.apple.com/documentation/foundationmodels/languagemodelsession
- https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/playandrecord

## Native verification record

- Corrected Swift service, Foundation Models macros and Objective-C++ singleton compile cleanly for debug/release × physical iPhone/simulator arm64.
- Complete unsigned physical-device Debug app linked successfully with the official Godot 4.7 device engine and the native plugin (`ios/build/device-build.log`).
- The release Xcode project contains the release engine and byte-verified release plugin. Project plist, localized Spanish permission strings and Info.plist validate with `plutil`.
- Native state regressions are covered without microphone access by `tests/voice_spec.gd`, including permission-request state, stale same-attempt sessions, stop/restart races, duplicate rewards and reversed terminal-status ordering.
- Physical microphone recognition, Foundation Models runtime availability, speaker feedback and Bluetooth routes require an actual device session. Successful compilation is not evidence for those runtime behaviors.

The generated privacy manifest lives at the Xcode output root (`ios/build/device-release/PrivacyInfo.xcprivacy`) and is explicitly included in the app's Resources build phase. The opaque 1024×1024 App Store icon is generated by Godot from the source icon. `prepare_xcode.py` preserves verified team IDs, uses Apple Development for automatic archive provisioning (distribution signing happens during export), and adds both English and Spanish permission resources.

Privacy access reasons are explicitly narrowed in `export_presets.cfg`: C617.1 for local app-container file metadata, 35F9.1 for elapsed-time game/audio scheduling, and E174.1 for the save preflight that avoids writing when storage is low. The app does not display file timestamps or general disk-space information, so the broader default Godot display reasons are disabled. Apple documents these meanings at https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons .

Final TestFlight project: `ios/build/testflight/Xochi.xcodeproj`. Latest signed archive: `ios/build/Xochi-0.1.0-2.xcarchive`. This export includes ordinary double jump, sharper enemies, narrowed privacy declarations and canal artwork on both native launch and engine startup. The build 1 candidate passed Apple's complete validation checks; both uploaded archive builds succeeded.

Version 0.1.0 (2) uploaded successfully on 8 September 2026 at 12:03:36 local time; Apple reported that the package was processing. See [upload receipt](TESTFLIGHT-UPLOAD.md). For subsequent uploads, increment `application/version` in `export_presets.cfg`, then run `./ios/upload_testflight.sh`. This explicitly signs and uploads using the Xcode account and `ExportOptions.plist`, preserving a separate archive per version and build; no private signing material is stored in the repository. `ios/build/testflight-upload-2.log` records the latest upload result.

The missing arm64 simulator engine was built from matching official source with SCons 4.11.1. To reproduce it, install SCons 4.x in an isolated Python environment, set `GODOT_SOURCE` to the extracted `4.7-stable` source and `SCONS_BIN` to that environment's `scons`, then run `./ios/build_simulator_engine.sh`. Set `GODOT_SIMULATOR_ARM64_LIBRARY` to the resulting `bin/libgodot.ios.template_debug.arm64.simulator.a` when running `export_simulator.sh`. The minimal simulator engine is for functional/layout checks; its performance is not a device benchmark.

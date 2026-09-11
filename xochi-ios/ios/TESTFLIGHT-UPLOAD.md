# TestFlight upload receipt

## Build 3 candidate — signing pending

The companion encounter is implemented and verified on the iPhone simulator. The final Release project is `ios/build/testflight/Xochi.xcodeproj`; the archive command is waiting for macOS to grant access to the existing Apple Development signing key. Computer use cannot operate the SecurityAgent prompt.

**Build 3 has not been uploaded.** After the user approves the macOS signing prompt, finish the archive at `ios/build/Xochi-0.1.0-3.xcarchive`, then export/upload with `ExportOptions.plist`. The current build log is `ios/build/testflight-archive-3-final.log`.

Build 3 introduces the Spanish-learning companion crossing, bounded autonomous movement and immediate touch takeover, original character identities, local spoken directions and Spanish examples, separate learning evidence, and the recovered original opening song.

## Latest successful upload

- App: **Xochi: The Song Home**
- Version/build: **0.1.0 (2)**
- Bundle identifier: `com.vaguiarl.xochi.songhome`
- Development team: `PG9XGM4JLG`
- Upload completed: **8 September 2026, 12:03:36 local time (America/Vancouver)**
- Result: **Upload succeeded. Apple reported that the uploaded package was processing.**
- Uploaded archive: `ios/build/Xochi-0.1.0-2.xcarchive`
- Source Xcode project: `ios/build/testflight/Xochi.xcodeproj`

The final `xcodebuild` result was:

```text
Uploaded package is processing.
Upload succeeded.
Uploaded Xochi
** EXPORT SUCCEEDED **
```

Build 2 restores one ordinary double jump per flight, independent of hyper-jump charges, and draws enemy ellipses at their final size to remove the fuzzy edges. Updated English and Spanish instructions explain the second upward swipe.

The complete local log is `ios/build/testflight-upload-2.log`. Signing credentials and distribution logs are excluded from the repository.

Apple's processing completion and tester-group availability have not been verified in App Store Connect. No public beta link or tester invitation was created. Live microphone, Apple Intelligence and audio-route quality still require a physical iPhone session; see `../TEST-RESULTS.md`.

## Previous upload

Version **0.1.0 (1)** uploaded successfully on 8 September 2026 at **11:34:38 local time**. Apple reported that its package was processing. Its archive remains at `ios/build/Xochi-TestFlight.xcarchive`, with the receipt in `ios/build/testflight-upload.log`.

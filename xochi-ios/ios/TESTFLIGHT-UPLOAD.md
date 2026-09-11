# TestFlight upload receipt

## Build 4 candidate — awaiting macOS signing

Version 0.1.0 (4) adds experimental on-device Apple Intelligence for natural Spanish/English companion directions. Exact phrases and touch remain available without the model. Final four-variant native compilation, Simulator build and gameplay checks passed. The host model missed the five-second response deadline; physical-iPhone model validation remains outstanding.

**Build 4 has not been uploaded.** The active `./ios/upload_testflight.sh` command has completed release export and reached macOS access to the existing Apple Development signing key. After approval, that same command will finish the archive and automatically attempt the App Store Connect upload. Computer use cannot operate SecurityAgent; the macOS prompt needs the user.

- Build/upload log: `ios/build/testflight-build-upload-4-final.log`
- Target archive: `ios/build/Xochi-0.1.0-4.xcarchive`
- Final simulator log: `ios/build/simulator-build-4-final.log`
- Native plugin log: `ios/build/plugin-intelligence-build.log`

Verify the eventual log contains **Upload succeeded** and **EXPORT SUCCEEDED** before treating the upload as complete. Apple processing/tester availability is a further status.

## Build 3 archive

The companion encounter archive completed signing successfully at `ios/build/Xochi-0.1.0-3.xcarchive`. The log `ios/build/testflight-archive-3-final.log` ends with **ARCHIVE SUCCEEDED**. Build 3 was not uploaded; build 4 includes the same encounter plus Apple Intelligence.

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

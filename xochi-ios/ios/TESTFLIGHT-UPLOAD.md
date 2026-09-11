# TestFlight upload receipt

## Latest successful upload — build 4

- App: **Xochi: The Song Home**
- Version/build: **0.1.0 (4)**
- Bundle identifier: `com.vaguiarl.xochi.songhome`
- Development team: `PG9XGM4JLG`
- Upload completed: **11 September 2026, 16:39:29 local time (America/Vancouver)**
- Result: **Upload succeeded. Apple reported that the uploaded package was processing.**
- Uploaded archive: `ios/build/Xochi-0.1.0-4.xcarchive`
- Source Xcode project: `ios/build/testflight/Xochi.xcodeproj`
- Build/upload log: `ios/build/testflight-build-upload-4-final.log`
- Final simulator log: `ios/build/simulator-build-4-final.log`
- Native plugin log: `ios/build/plugin-intelligence-build.log`

The original upload script named the archive with unresolved Xcode placeholders. After confirming its embedded version/build, the archive was renamed locally to the versioned path above. The upload script now reads resolved build settings and rejects unresolved values before archiving.

The macOS signing approval completed the archive, and the queued command automatically uploaded it. The log confirms **ARCHIVE SUCCEEDED**, followed by:

```text
Uploaded package is processing.
Upload succeeded.
Uploaded Xochi
** EXPORT SUCCEEDED **
```

Build 4 includes the Spanish-learning companion encounter and experimental on-device Apple Intelligence for natural Spanish/English directions. Exact phrases and touch remain available without the model. Native compilation, Simulator build and gameplay checks passed. The host model missed the five-second response deadline; physical-iPhone model quality and latency validation remain outstanding.

Apple's processing completion and tester-group availability have not been verified in App Store Connect. No public beta link or tester invitation was created. Live microphone and audio-route quality also require a physical iPhone session; see `../TEST-RESULTS.md`. Signing credentials and generated distribution logs are excluded from Git.

## Build 3 archive

The companion encounter archive completed signing successfully at `ios/build/Xochi-0.1.0-3.xcarchive`. The log `ios/build/testflight-archive-3-final.log` ends with **ARCHIVE SUCCEEDED**. Build 3 was not uploaded; build 4 includes the same encounter plus Apple Intelligence.

## Previous uploads

Version **0.1.0 (2)** uploaded successfully on **8 September 2026 at 12:03:36 local time**. It restored one ordinary double jump per flight, independent of hyper-jump charges, and removed fuzzy enemy edges. Its archive remains at `ios/build/Xochi-0.1.0-2.xcarchive`; its receipt is `ios/build/testflight-upload-2.log`.

Version **0.1.0 (1)** uploaded successfully on **8 September 2026 at 11:34:38 local time**. Its archive remains at `ios/build/Xochi-TestFlight.xcarchive`, with the receipt in `ios/build/testflight-upload.log`. Apple reported that both earlier packages were processing at upload completion.

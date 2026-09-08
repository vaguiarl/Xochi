#!/bin/bash
# Explicitly rebuild, sign and upload the current version to App Store Connect.
# Increment application/version in export_presets.cfg before a subsequent upload.
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
./ios/export_project.sh release ios/build/testflight/Xochi
release_info=ios/build/testflight/Xochi/Xochi-Info.plist
release_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$release_info")
release_build=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$release_info")
release_archive="ios/build/Xochi-$release_version-$release_build.xcarchive"
"$DEVELOPER_DIR/usr/bin/xcodebuild" \
  -project ios/build/testflight/Xochi.xcodeproj -scheme Xochi \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -archivePath "$release_archive" \
  -derivedDataPath ios/build/TestFlightDerivedData -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY='Apple Development' archive
"$DEVELOPER_DIR/usr/bin/xcodebuild" -exportArchive \
  -archivePath "$release_archive" \
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath ios/build/TestFlightUpload -allowProvisioningUpdates

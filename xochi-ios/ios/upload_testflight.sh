#!/bin/bash
# Explicitly rebuild, sign and upload the current version to App Store Connect.
# Increment application/version in export_presets.cfg before a subsequent upload.
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
./ios/export_project.sh release ios/build/testflight/Xochi
# The exported Info.plist contains Xcode variables, not resolved version numbers.
release_settings=$(mktemp ios/build/upload-settings.XXXXXX)
trap 'rm -f "$release_settings"' EXIT
"$DEVELOPER_DIR/usr/bin/xcodebuild" \
  -project ios/build/testflight/Xochi.xcodeproj -scheme Xochi \
  -configuration Release -sdk iphoneos -showBuildSettings -json > "$release_settings"
release_numbers=$(python3 - "$release_settings" <<'PY'
import json
import re
import sys

with open(sys.argv[1]) as source:
    targets = json.load(source)
matches = [item["buildSettings"] for item in targets if item.get("target") == "Xochi"]
if len(matches) != 1:
    raise SystemExit("Cannot resolve the Xochi target's release version")
values = [matches[0].get(key, "") for key in ("MARKETING_VERSION", "CURRENT_PROJECT_VERSION")]
if not all(re.fullmatch(r"[0-9]+(?:\.[0-9]+){0,2}", value) for value in values):
    raise SystemExit("Release version/build must resolve to numeric values before archiving")
print(" ".join(values))
PY
)
read -r release_version release_build <<< "$release_numbers"
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

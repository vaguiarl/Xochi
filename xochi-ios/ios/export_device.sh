#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
./ios/export_project.sh release ios/build/device-release/Xochi
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project ios/build/device-release/Xochi.xcodeproj -scheme Xochi -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath ios/build/ReleaseDerivedData CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES build

#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
./ios/export_project.sh debug ios/build/simulator/Xochi
engine="ios/build/simulator/Xochi.xcframework/ios-arm64_x86_64-simulator/libgodot.a"
if ! xcrun lipo -verify_arch arm64 "$engine" >/dev/null 2>&1; then
  if [ -n "${GODOT_SIMULATOR_ARM64_LIBRARY:-}" ]; then
    xcrun lipo -create "$engine" "$GODOT_SIMULATOR_ARM64_LIBRARY" -output "$engine.universal"
    mv "$engine.universal" "$engine"
  else
    echo 'Godot template lacks its advertised arm64 simulator slice. Set GODOT_SIMULATOR_ARM64_LIBRARY to the matching source-built template_debug archive.' >&2
    exit 1
  fi
fi
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project ios/build/simulator/Xochi.xcodeproj -scheme Xochi -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath ios/build/SimulatorDerivedData CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES build

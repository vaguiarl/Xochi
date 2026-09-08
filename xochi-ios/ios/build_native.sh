#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
GODOT_SOURCE="${GODOT_SOURCE:-/private/tmp/xochi-native-deps/godot-4.7-stable}"
if [ ! -f "$GODOT_SOURCE/core/version_generated.gen.h" ]; then
  echo "Generate Godot 4.7 headers first; see ios/README.md" >&2
  exit 1
fi
for configuration in debug release; do
  flags=""
  [ "$configuration" = debug ] && flags="-DDEBUG_ENABLED"
  for sdk in iphoneos iphonesimulator; do
    target=arm64-apple-ios26.0
    [ "$sdk" = iphonesimulator ] && target=arm64-apple-ios26.0-simulator
    out="ios/build/$configuration/$sdk"
    mkdir -p "$out"
    sdkpath="$(xcrun --sdk "$sdk" --show-sdk-path)"
    xcrun --sdk "$sdk" swiftc -swift-version 5 -parse-as-library -emit-object -emit-objc-header -emit-objc-header-path "$out/XochiVoice-Swift.h" -module-name XochiVoice -target "$target" -sdk "$sdkpath" -module-cache-path /private/tmp/xochi-native-deps/swift-cache ios/src/XochiVoice.swift -o "$out/XochiVoice.swift.o"
    xcrun --sdk "$sdk" clang++ -std=gnu++17 -x objective-c++ -fobjc-arc -fblocks -fmodules -fcxx-modules -fno-exceptions -fvisibility=hidden -target "$target" -isysroot "$sdkpath" -I "$GODOT_SOURCE" -I "$GODOT_SOURCE/platform/ios" -I "$out" -DNDEBUG -DTHREADS_ENABLED -DUNIX_ENABLED -DAPPLE_EMBEDDED_ENABLED -DIOS_ENABLED -DCOREAUDIO_ENABLED $flags -fmodules-cache-path=/private/tmp/xochi-native-deps/clang-cache -c ios/src/xochi_voice.mm -o "$out/xochi_voice.o"
    xcrun libtool -static -o "$out/libXochiVoice.a" "$out/XochiVoice.swift.o" "$out/xochi_voice.o"
  done
  out="ios/plugins/xochi_voice/XochiVoice.$configuration.xcframework"
  if [ -d "$out" ]; then mv "$out" "ios/build/XochiVoice.$configuration.previous.$(date +%s).xcframework"; fi
  xcodebuild -create-xcframework -library "ios/build/$configuration/iphoneos/libXochiVoice.a" -library "ios/build/$configuration/iphonesimulator/libXochiVoice.a" -output "$out"
done
if [ -d ios/plugins/xochi_voice/XochiVoice.xcframework ]; then mv ios/plugins/xochi_voice/XochiVoice.xcframework "ios/build/XochiVoice.initial.$(date +%s).xcframework"; fi

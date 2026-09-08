#!/bin/bash
# Build the missing simulator slice from matching, official Godot source.
set -euo pipefail
: "${GODOT_SOURCE:?Set GODOT_SOURCE to the extracted Godot 4.7-stable source directory}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
cd "$GODOT_SOURCE"
"${SCONS_BIN:-scons}" \
  platform=ios target=template_debug arch=arm64 simulator=yes \
  APPLE_TOOLCHAIN_PATH="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain" \
  APPLE_SDK_PATH="$DEVELOPER_DIR/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk" \
  metal=no vulkan=no opengl3=yes sdl=no disable_3d=yes \
  debug_symbols=no optimize=none lto=none modules_enabled_by_default=no \
  module_gdscript_enabled=yes module_godot_physics_2d_enabled=yes \
  module_text_server_fb_enabled=yes module_freetype_enabled=yes \
  module_ogg_enabled=yes module_vorbis_enabled=yes module_webp_enabled=yes \
  -j"${BUILD_JOBS:-6}"
xcrun lipo -verify_arch arm64 bin/libgodot.ios.template_debug.arm64.simulator.a
printf 'Simulator engine: %s/bin/libgodot.ios.template_debug.arm64.simulator.a\n' "$GODOT_SOURCE"

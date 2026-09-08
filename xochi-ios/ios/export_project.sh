#!/bin/bash
# Export a version-matched native Xcode project; signing is configured in Xcode afterwards.
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
mode="${1:-debug}"
output="${2:-ios/build/Xochi}"
case "$mode" in debug|release) ;; *) echo 'Usage: export_project.sh [debug|release] [output/project-name]' >&2; exit 2 ;; esac
mkdir -p ios/build "$(dirname "$output")"
if ! mkdir ios/build/.export-lock 2>/dev/null; then
  echo 'Another Godot export is active; wait until it finishes.' >&2
  exit 1
fi
backup="$(mktemp ios/build/export-presets.XXXXXX)"
cp export_presets.cfg "$backup"
cleanup() { cp "$backup" export_presets.cfg; unlink "$backup"; rmdir ios/build/.export-lock; }
trap cleanup EXIT
# Godot requires a nonempty team even for an unsigned project; no account is inferred.
python3 - <<'PY'
p='export_presets.cfg'
s=open(p).read().replace('application/app_store_team_id=""', 'application/app_store_team_id="UNSIGNED"')
open(p,'w').write(s)
PY
"${GODOT_BIN:-/opt/homebrew/bin/godot}" --headless --path . "--export-$mode" iOS "$output.zip"
python3 ios/prepare_xcode.py "$output.xcodeproj" "$output"
printf 'Exported %s project: %s.xcodeproj\n' "$mode" "$output"

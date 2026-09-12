#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
godot_bin="${GODOT_BIN:-/opt/homebrew/bin/godot}"
for spec in player_spec companion_controller_spec companion_voice_spec learning_progress_spec rescue_route_spec rescue_manual_spec rescue_command_spec rescue_state_spec; do
  "$godot_bin" --headless --fixed-fps 60 --path . --script "res://tests/$spec.gd"
done

#!/usr/bin/env bash
# Run from any directory. No plugins, package installs, or network access needed.
set -euo pipefail
cd "$(dirname "$0")/.."
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/ignotum-cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-/tmp/ignotum-data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/tmp/ignotum-config}"
godot_bin="${GODOT_BIN:-godot}"
"$godot_bin" --headless --editor --path . --import --quit
XDG_DATA_HOME=/tmp/ignotum-automated-tests "$godot_bin" --headless --path . res://tests/smoke.tscn

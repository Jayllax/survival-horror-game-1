#!/usr/bin/env bash
# Run from any directory. No plugins, package installs, or network access needed.
set -euo pipefail
cd "$(dirname "$0")/.."
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/ignotum-cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-/tmp/ignotum-data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/tmp/ignotum-config}"
godot_bin="${GODOT_BIN:-godot}"
test_data_root="${IGNOTUM_TEST_DATA_DIR:-/tmp/ignotum-automated-tests}"
"$godot_bin" --headless --editor --path . --import --quit
for suite in smoke interface assets manual_saves; do
    XDG_DATA_HOME="$test_data_root/$suite" "$godot_bin" --headless --path . "res://tests/$suite.tscn"
done

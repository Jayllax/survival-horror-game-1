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
suites=("$@")
if (( ${#suites[@]} == 0 )); then
    suites=(smoke interface assets manual_saves grid_inventory aiming narrative combat stealth fences character_art interiors forest equipment item_use code_lock light_switch loot)
fi
for suite in "${suites[@]}"; do
    case "$suite" in
        smoke|interface|assets|manual_saves|grid_inventory|aiming|narrative|combat|stealth|fences|character_art|interiors|forest|equipment|item_use|code_lock|light_switch|loot) ;;
        *) echo "Unknown test suite: $suite" >&2; exit 2 ;;
    esac
    suite_log="$(mktemp)"
    XDG_DATA_HOME="$test_data_root/$suite" timeout 120 "$godot_bin" --headless --path . "res://tests/$suite.tscn" 2>&1 | tee "$suite_log"
    if rg -q 'SCRIPT ERROR:|ERROR:' "$suite_log" || ! rg -q 'checks, 0 failures' "$suite_log"; then
        rm -f "$suite_log"
        exit 1
    fi
    rm -f "$suite_log"
done

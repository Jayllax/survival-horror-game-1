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
    suites=(audio smoke interface assets manual_saves embedded_item_saves grid_inventory inventory_bounds aiming narrative dialogue_choices combat stealth fences character_art interiors forest equipment item_use code_lock light_switch loot pushables)
fi
run_suite() {
    local test_suite="$1"
    shift
    local suite_log
    suite_log="$(mktemp)"
    XDG_DATA_HOME="$test_data_root/$test_suite" timeout 120 "$godot_bin" --headless --path . "res://tests/$test_suite.tscn" "$@" 2>&1 | tee "$suite_log"
    if rg -q 'SCRIPT ERROR:|ERROR:' "$suite_log" || ! rg -q 'checks, 0 failures' "$suite_log"; then
        rm -f "$suite_log"
        exit 1
    fi
    rm -f "$suite_log"
}
for suite in "${suites[@]}"; do
    case "$suite" in
        audio|smoke|interface|assets|manual_saves|embedded_item_saves|grid_inventory|inventory_bounds|aiming|narrative|dialogue_choices|combat|stealth|fences|character_art|interiors|forest|equipment|item_use|code_lock|light_switch|loot|pushables) ;;
        *) echo "Unknown test suite: $suite" >&2; exit 2 ;;
    esac
    run_suite "$suite"
    if [[ "$suite" == "embedded_item_saves" ]]; then
        # Reopen the on-disk saves without any of the earlier scene/resource cache.
        run_suite "$suite" -- --verify-fresh-load
    fi
done

#!/usr/bin/env bash
# Runs every DetectiveNet selftest. Fails if any run prints a script error.
# Override the engine binary with GODOT=/path/to/Godot ./tools/run_tests.sh
set -u

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
cd "$(dirname "$0")/.."

fail=0

run_godot() {
    local label="$1" args="$2"
    echo "== $label"
    local out
    out=$("$GODOT" --path . $args 2>&1)
    echo "$out" | rg "CAPTURED|SELFTEST" || true
    if echo "$out" | rg -q "SCRIPT ERROR|Parse Error|Failed to load|Invalid call|Nonexistent function"; then
        echo "!! errors in $label:"
        echo "$out" | rg "SCRIPT ERROR|Parse Error|Failed to load|Invalid call|Nonexistent function" | head -10
        fail=1
    fi
}

run_godot "boot"  "--quit-after 700 res://spikes/shell/boot_selftest.tscn"
run_godot "shell" "--quit-after 1400 res://spikes/shell/shell_selftest.tscn"
run_godot "text"  "--quit-after 600 res://spikes/text/spike_text.tscn"

echo "== photo"
if ! python3 tools/process_photo.py --self-test; then
    echo "!! photo self-test failed"
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "ALL TESTS PASSED"
else
    echo "TESTS FAILED"
fi
exit "$fail"

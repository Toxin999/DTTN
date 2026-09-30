#!/usr/bin/env bash
# Runs every DetectiveNet selftest. Fails if any run prints a script error.
# Override the engine binary with GODOT=/path/to/Godot ./tools/run_tests.sh
set -u

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PYTHON="${PYTHON:-python3}"
cd "$(dirname "$0")/.."

# ripgrep if available, plain grep otherwise
if command -v rg >/dev/null 2>&1; then
    show() { rg "CAPTURED|SELFTEST"; }
    errors() { rg "SCRIPT ERROR|Parse Error|Failed to load|Invalid call|Nonexistent function"; }
    any_error() { rg -q "SCRIPT ERROR|Parse Error|Failed to load|Invalid call|Nonexistent function"; }
else
    show() { grep -E "CAPTURED|SELFTEST"; }
    errors() { grep -E "SCRIPT ERROR|Parse Error|Failed to load|Invalid call|Nonexistent function"; }
    any_error() { grep -Eq "SCRIPT ERROR|Parse Error|Failed to load|Invalid call|Nonexistent function"; }
fi

fail=0

echo "== import"
"$GODOT" --headless --path . --import >/dev/null 2>&1

run_godot() {
    local label="$1" args="$2"
    echo "== $label"
    local out
    out=$("$GODOT" --path . $args 2>&1)
    echo "$out" | show || true
    if echo "$out" | any_error; then
        echo "!! errors in $label:"
        echo "$out" | errors | head -10
        fail=1
    fi
}

run_godot "boot"    "--quit-after 700 res://spikes/shell/boot_selftest.tscn"
run_godot "shell"   "--quit-after 1600 res://spikes/shell/shell_selftest.tscn"
run_godot "browser" "--quit-after 6000 res://spikes/shell/browser_selftest.tscn"
run_godot "ring"    "--quit-after 6000 res://spikes/shell/ring_cache_selftest.tscn"
run_godot "text"    "--quit-after 600 res://spikes/text/spike_text.tscn"

echo "== photo"
if ! "$PYTHON" -c "import PIL" >/dev/null 2>&1; then
    echo "!! '$PYTHON' has no Pillow — install it or set PYTHON=/path/to/python3"
    fail=1
elif ! "$PYTHON" tools/process_photo.py --self-test; then
    echo "!! photo self-test failed"
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "ALL TESTS PASSED"
else
    echo "TESTS FAILED"
fi
exit "$fail"

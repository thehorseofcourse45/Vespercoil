#!/usr/bin/env bash
# Runs every headless test script. A test passes only if it exits 0, prints a
# "PASS" line, and logs no SCRIPT ERROR (a failed assert() stops the test
# without a non-zero exit, so the PASS line is the real signal).
# Usage: GODOT=/path/to/godot tests/run_all.sh [name ...]
set -u
GODOT="${GODOT:-godot}"
TIMEOUT="${TEST_TIMEOUT:-600}"
cd "$(dirname "$0")/.."
# Isolate user:// so tests never read the player's real save (it changes bonuses,
# curse and difficulty), and so wipe_save.gd agrees to run.
PROFILE="${LOCALAPPDATA:-$HOME/.cache}/large-tree-test-profile"
mkdir -p "$PROFILE"
export APPDATA="$PROFILE" XDG_DATA_HOME="$PROFILE"
# Screenshot captures need a graphics backend; the profilers are perf probes, not checks.
SKIP=" capture content_capture ground_capture keepers_capture zone_capture late_run_perf profile_phases "
if [ "$#" -gt 0 ]; then
	names="$*"
else
	names=$(ls tests/*.gd | xargs -n1 basename | sed 's/\.gd$//' | grep -v '^tmp_' | grep -v '^run_all$')
fi
failed=()
for name in $names; do
	case "$SKIP" in *" $name "*) continue ;; esac
	start=$(date +%s)
	output=$(timeout "$TIMEOUT" "$GODOT" --headless --path . --script "tests/$name.gd" 2>&1)
	code=$?
	took=$(( $(date +%s) - start ))
	if [ "$code" -eq 0 ] && grep -q "PASS" <<<"$output" && ! grep -q "SCRIPT ERROR" <<<"$output"; then
		echo "ok    $name (${took}s)"
	else
		echo "FAIL  $name (exit $code, ${took}s)"
		grep -E "SCRIPT ERROR|Assertion failed|FAIL|at: " <<<"$output" | head -20 | sed 's/^/      /'
		failed+=("$name")
	fi
done
if [ "${#failed[@]}" -gt 0 ]; then
	echo "${#failed[@]} failed: ${failed[*]}"
	exit 1
fi
echo "all passed"

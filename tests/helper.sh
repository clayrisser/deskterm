# Shared helpers for the deskterm bats suite. POSIX sh.
# shellcheck shell=sh

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${BATS_TEST_DIRNAME:-$(dirname -- "$0")}" && git rev-parse --show-toplevel)}"
# Consumed by the .bats files that `load` this helper.
# shellcheck disable=SC2034
DESKTERM="$PROJECT_ROOT/bin/deskterm"

# make_shim <name> [exit_code] — create a fake command in $SHIM_DIR that
# appends "<name> <args>" to $SHIM_LOG and exits with exit_code (default 0).
make_shim() {
	cat >"$SHIM_DIR/$1" <<EOF
#!/bin/sh
printf '%s %s\n' "$1" "\$*" >>"$SHIM_LOG"
exit ${2:-0}
EOF
	chmod +x "$SHIM_DIR/$1"
}

# wait_for_log <pattern> — wait (up to ~5s) for a line matching pattern to
# appear in $SHIM_LOG. Covers backgrounded shims (devilspie2) racing the
# assertion. Uses /bin/sleep because "sleep" itself may be shimmed.
wait_for_log() {
	i=0
	while [ "$i" -lt 50 ]; do
		grep -q "$1" "$SHIM_LOG" 2>/dev/null && return 0
		i=$((i + 1))
		/bin/sleep 0.1
	done
	echo "shim log never matched: $1" >&2
	cat "$SHIM_LOG" >&2 2>/dev/null || true
	return 1
}

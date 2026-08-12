#!/usr/bin/env bats
load ../helper.sh

# Headless smoke of the core wiring: inside a throwaway Debian container,
# devilspie2 + the bundled rule must re-type a window with the X window role
# "Deskterm" into the desktop window under Xvfb. gnome-terminal itself is not
# exercised here (it needs a D-Bus session); the launcher's command
# construction is covered by the unit suite.

@test "devilspie2 pins a Deskterm-role window as the desktop under Xvfb" {
	command -v docker >/dev/null 2>&1 || skip "docker is not available"
	run docker run --rm -v "$PROJECT_ROOT":/work:ro debian:bookworm-slim \
		sh /work/tests/e2e/container_smoke.sh
	echo "$output"
	[ "$status" -eq 0 ]
	echo "$output" | grep -q '_NET_WM_WINDOW_TYPE_DESKTOP'
}

#!/bin/sh
# Runs inside a throwaway Debian container (see 01_xvfb_smoke.bats) with the
# repo mounted read-only at /work. Brings up Xvfb + openbox + devilspie2 with
# the bundled rule, maps a window carrying the X window role "Deskterm", and
# asserts devilspie2 re-typed it as the desktop window.
set -eu

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -qq -y --no-install-recommends \
	devilspie2 openbox python3 python3-xlib x11-utils xvfb >/dev/null

export HOME=/tmp/deskterm-home DISPLAY=:99
mkdir -p "$HOME/.config/devilspie2"
cp /work/share/deskterm.lua "$HOME/.config/devilspie2/deskterm.lua"

Xvfb :99 -screen 0 1280x800x24 &
i=0
until xdpyinfo >/dev/null 2>&1; do
	i=$((i + 1))
	if [ "$i" -ge 30 ]; then
		echo "Xvfb did not start" >&2
		exit 1
	fi
	sleep 1
done

openbox &
sleep 1
devilspie2 --debug >/tmp/devilspie2.log 2>&1 &
sleep 1

python3 /work/tests/e2e/desktop_window.py &
i=0
until xprop -name deskterm-e2e _NET_WM_WINDOW_TYPE 2>/dev/null |
	grep _NET_WM_WINDOW_TYPE_DESKTOP; do
	i=$((i + 1))
	if [ "$i" -ge 30 ]; then
		echo "window was never re-typed as the desktop; devilspie2 log:" >&2
		cat /tmp/devilspie2.log >&2
		xprop -name deskterm-e2e >&2 || true
		exit 1
	fi
	sleep 1
done
echo "OK: deskterm rule pinned the Deskterm-role window as the desktop"

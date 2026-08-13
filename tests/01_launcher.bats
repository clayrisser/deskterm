#!/usr/bin/env bats
load helper.sh

setup() {
	SHIM_DIR="$BATS_TEST_TMPDIR/shims"
	SHIM_LOG="$BATS_TEST_TMPDIR/shim.log"
	HOME="$BATS_TEST_TMPDIR/home"
	XDG_CONFIG_HOME="$HOME/.config"
	mkdir -p "$SHIM_DIR" "$HOME"
	: >"$SHIM_LOG"
	PATH="$SHIM_DIR:$PATH"
	export SHIM_DIR SHIM_LOG HOME XDG_CONFIG_HOME PATH
	export XDG_SESSION_TYPE=x11 DISPLAY=:0
	unset DESKTERM_RULE DESKTERM_PROFILE
	make_shim devilspie2
	make_shim gnome-terminal
	make_shim pgrep 1
	make_shim sleep
}

@test "--help prints usage" {
	run "$DESKTERM" --help
	[ "$status" -eq 0 ]
	echo "$output" | grep -q '^Usage: deskterm'
}

@test "rejects unknown arguments" {
	run "$DESKTERM" --bogus
	[ "$status" -eq 2 ]
	echo "$output" | grep -q '^Usage: deskterm'
}

@test "refuses to run under wayland" {
	XDG_SESSION_TYPE=wayland run "$DESKTERM"
	[ "$status" -eq 1 ]
	echo "$output" | grep -q 'X11 session is required'
}

@test "refuses to run without DISPLAY" {
	DISPLAY= run "$DESKTERM"
	[ "$status" -eq 1 ]
	echo "$output" | grep -q 'DISPLAY is not set'
}

@test "errors when devilspie2 is missing" {
	rm "$SHIM_DIR/devilspie2"
	run env PATH="$SHIM_DIR" "$DESKTERM"
	[ "$status" -eq 1 ]
	echo "$output" | grep -q 'devilspie2 is missing'
}

@test "errors when gnome-terminal is missing" {
	rm "$SHIM_DIR/gnome-terminal"
	run env PATH="$SHIM_DIR" "$DESKTERM"
	[ "$status" -eq 1 ]
	echo "$output" | grep -q 'gnome-terminal is missing'
}

@test "installs the rule into XDG_CONFIG_HOME" {
	run "$DESKTERM"
	[ "$status" -eq 0 ]
	cmp -s "$PROJECT_ROOT/share/deskterm.lua" "$XDG_CONFIG_HOME/devilspie2/deskterm.lua"
}

@test "refreshes an outdated rule in XDG_CONFIG_HOME" {
	mkdir -p "$XDG_CONFIG_HOME/devilspie2"
	echo '-- stale' >"$XDG_CONFIG_HOME/devilspie2/deskterm.lua"
	run "$DESKTERM"
	[ "$status" -eq 0 ]
	cmp -s "$PROJECT_ROOT/share/deskterm.lua" "$XDG_CONFIG_HOME/devilspie2/deskterm.lua"
}

@test "respects DESKTERM_RULE override" {
	echo '-- custom rule' >"$BATS_TEST_TMPDIR/custom.lua"
	DESKTERM_RULE="$BATS_TEST_TMPDIR/custom.lua" run "$DESKTERM"
	[ "$status" -eq 0 ]
	cmp -s "$BATS_TEST_TMPDIR/custom.lua" "$XDG_CONFIG_HOME/devilspie2/deskterm.lua"
}

@test "errors when the rule file cannot be found" {
	DESKTERM_RULE="$BATS_TEST_TMPDIR/nope.lua" run "$DESKTERM"
	[ "$status" -eq 1 ]
	echo "$output" | grep -q 'rule file not found'
}

@test "starts devilspie2 when it is not running" {
	run "$DESKTERM"
	[ "$status" -eq 0 ]
	wait_for_log '^devilspie2'
	grep -q '^sleep 2$' "$SHIM_LOG"
}

@test "does not start devilspie2 when already running" {
	make_shim pgrep 0
	run "$DESKTERM"
	[ "$status" -eq 0 ]
	wait_for_log '^gnome-terminal'
	! grep -q '^devilspie2' "$SHIM_LOG"
}

@test "launches gnome-terminal with the Deskterm profile and role" {
	run "$DESKTERM"
	[ "$status" -eq 0 ]
	wait_for_log '^gnome-terminal --window --profile=Deskterm --role=Deskterm --hide-menubar$'
}

@test "honours DESKTERM_PROFILE" {
	DESKTERM_PROFILE=Custom run "$DESKTERM"
	[ "$status" -eq 0 ]
	wait_for_log '^gnome-terminal --window --profile=Custom --role=Deskterm --hide-menubar$'
}

.POSIX:
export ROOTDIR ?= $(eval ROOTDIR := $(shell git rev-parse --show-toplevel))$(ROOTDIR)
include $(ROOTDIR)/make.mk

.DEFAULT_GOAL := lint

ASDF_VERSION ?= v0.18.0
.PHONY: prepare prepare/asdf prepare/cloc
prepare: sudo
	@command -v asdf >/dev/null 2>&1 || $(MAKE) prepare/asdf
	@command -v cloc >/dev/null 2>&1 || $(MAKE) prepare/cloc
	@awk '!/^#/ && NF {print $$1}' .tool-versions | \
		while read t; do asdf plugin add "$$t" 2>/dev/null || true; done
	@rcfile=$$(mktemp); \
		{ asdf install 2>&1; echo $$? >$$rcfile; } | grep --line-buffered -v 'is already installed' || true; \
		rc=$$(cat $$rcfile); rm -f $$rcfile; exit $$rc
prepare/asdf:
	@command -v brew >/dev/null 2>&1 && brew install asdf || { \
		o=$$(uname | tr A-Z a-z); a=$$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/'); \
		curl -fsSL "https://github.com/asdf-vm/asdf/releases/download/$(ASDF_VERSION)/asdf-$(ASDF_VERSION)-$$o-$$a.tar.gz" \
			| $(SUDO) tar -xz -C /usr/local/bin asdf; \
	}
prepare/cloc:
	@$(PKG_INSTALL) cloc

.PHONY: configure
configure:
	@for cmd in asdf $(CLOC); do \
		command -v $$cmd >/dev/null 2>&1 || { echo "$$cmd is missing, run \`make prepare\`"; exit 1; }; \
	done
	@awk '!/^#/ && NF {print $$1}' .tool-versions | \
		while read t; do asdf plugin add "$$t" 2>/dev/null || true; done
	@rcfile=$$(mktemp); \
		{ asdf install 2>&1; echo $$? >$$rcfile; } | grep --line-buffered -v 'is already installed' || true; \
		rc=$$(cat $$rcfile); rm -f $$rcfile; exit $$rc
	@for cmd in $(SHFMT) $(BATS) $(SHELLCHECK); do \
		command -v $$cmd >/dev/null 2>&1 || { echo "$$cmd is missing, run \`make prepare\`"; exit 1; }; \
	done

# Shared by format and lint. bin/deskterm has no extension, so it's listed
# explicitly alongside the tracked *.sh and *.bats files.
SHFILES ?= $(eval SHFILES := bin/deskterm $(shell $(GIT) ls-files '*.sh' '*.bats'))$(SHFILES)

.PHONY: format
format: configure
	@$(SHFMT) -w $(SHFILES)

.PHONY: lint
lint: configure
	@$(SHFMT) -d $(SHFILES)
	@$(SHELLCHECK) bin/deskterm $$($(GIT) ls-files '*.sh')

.PHONY: test
test: test/unit

.PHONY: test/unit
test/unit: configure
	@$(BATS) tests

# Headless smoke of the core wiring (devilspie2 + rule under Xvfb) in a
# throwaway Debian container. Needs a running docker daemon.
.PHONY: test/e2e
test/e2e: configure
	@$(BATS) tests/e2e

.PHONY: count
count: configure
	@$(CLOC) $$($(GIT) ls-files)

PROJECT := deskterm
PREFIX ?= /usr/local
DESTDIR ?=

bindir := $(DESTDIR)$(PREFIX)/bin
datadir := $(DESTDIR)$(PREFIX)/share
sysconfdir := $(DESTDIR)$(PREFIX)/etc
pkgdatadir := $(datadir)/$(PROJECT)
autostartdir := $(sysconfdir)/xdg/autostart

.PHONY: install
install:
	@install -d $(bindir) $(pkgdatadir) $(autostartdir)
	@install -m 755 bin/deskterm $(bindir)/deskterm
	@install -m 644 share/deskterm.lua $(pkgdatadir)/deskterm.lua
	@install -m 644 share/deskterm.desktop $(autostartdir)/deskterm.desktop

.PHONY: uninstall
uninstall:
	@rm -f $(bindir)/deskterm $(autostartdir)/deskterm.desktop
	@rm -rf $(pkgdatadir)

.PHONY: clean
clean:
	@rm -rf $(MAKEDIR)

.PHONY: purge
purge: clean
	@$(GIT) clean -fxd

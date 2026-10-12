APP := build/AirDrop CLI.app
BIN := $(APP)/Contents/MacOS/airdrop-cli

.PHONY: build install test clean

build:
	mkdir -p "$(APP)/Contents/MacOS"
	cp Support/Info.plist "$(APP)/Contents/Info.plist"
	swiftc -O Sources/main.swift -o "$(BIN)"
	codesign --force --sign - "$(APP)"

install: build
	mkdir -p "$(HOME)/Applications" "$(HOME)/.local/bin"
	rm -rf "$(HOME)/Applications/AirDrop CLI.app"
	cp -R "$(APP)" "$(HOME)/Applications/AirDrop CLI.app"
	printf '%s\n' '#!/bin/sh' 'exec "$(HOME)/Applications/AirDrop CLI.app/Contents/MacOS/airdrop-cli" "$$@"' > "$(HOME)/.local/bin/airdrop-cli"
	chmod 755 "$(HOME)/.local/bin/airdrop-cli"

test: build
	"$(BIN)" --help
	! "$(BIN)" --to "Example iPhone" /this/file/does/not/exist
	! "$(BIN)" --to "Example iPhone" https://
	@tmp=$$(mktemp -d); AIRDROP_CLI_CONFIG_DIR="$$tmp" "$(BIN)" clear; AIRDROP_CLI_CONFIG_DIR="$$tmp" "$(BIN)" setup --device "Test iPhone"; test "$$(cat "$$tmp/device")" = "Test iPhone"; AIRDROP_CLI_CONFIG_DIR="$$tmp" "$(BIN)" clear; test ! -e "$$tmp/device"; rmdir "$$tmp"

clean:
	rm -rf build

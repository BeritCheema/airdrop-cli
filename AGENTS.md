# Agent workflow

Build and install with `make install`. The default device starts as none. Run `airdrop-cli setup` for interactive discovery and selection, or `airdrop-cli devices` followed by `airdrop-cli setup --device "<exact label>"` for agent setup. Send a file or `http(s)` URL with `airdrop-cli <item>`. Use `--to` for a one-time destination; `airdrop-cli clear` removes the saved default. Do not guess among multiple plausible devices. Treat a nonzero exit as a failed transfer.

The app needs one-time macOS Accessibility authorization. Keep this CLI standalone: use Apple's `NSSharingService` and Accessibility API, with no third-party AirDrop CLI dependency. Contacts Only works through the Mac's own Apple AirDrop service. OpenDrop is a protocol reference only; its GPL code must not be copied into this MIT project.

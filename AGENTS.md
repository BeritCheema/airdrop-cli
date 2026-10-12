# Agent workflow

Build and install with `make install`. To send a file, run `airdrop-cli devices`, save the user's exact iPhone label once with `airdrop-cli use "<label>"`, then run `airdrop-cli <path>`. For an explicit target, use `--to`. Do not guess among multiple plausible devices. Treat a nonzero exit as a failed transfer.

The app needs one-time macOS Accessibility authorization. Keep this CLI standalone: use Apple's `NSSharingService` and Accessibility API, with no third-party AirDrop CLI dependency. Contacts Only works through the Mac's own Apple AirDrop service. OpenDrop is a protocol reference only; its GPL code must not be copied into this MIT project.

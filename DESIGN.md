# Design notes

[OpenDrop](https://github.com/seemoo-lab/opendrop) discovers `_airdrop._tcp.local.` peers over AWDL, then uses `/Discover`, `/Ask`, and `/Upload`. For Contacts Only, its independent sender needs Apple-signed identity material; [its extractor](https://github.com/seemoo-lab/airdrop-keychain-extractor) requires changing macOS security settings.

This CLI calls [Apple's AirDrop sharing service](https://developer.apple.com/documentation/appkit/nssharingservice/name/sendviaairdrop) so macOS handles discovery, identity, and transfer. It reads recipient names from the system picker's Accessibility tree and presses only a button whose label exactly matches the saved or requested device. This avoids private frameworks and credential extraction. The picker UI is an undocumented integration point, so it should be checked after major macOS updates.

OpenDrop's GPL source was studied as a protocol reference; no OpenDrop code is included.

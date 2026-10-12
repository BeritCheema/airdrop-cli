# airdrop-cli

A standalone macOS CLI for sending files to an exact AirDrop device. It uses Apple's native AirDrop service, so Contacts Only works without extracting credentials.

```sh
make install
airdrop-cli devices
airdrop-cli use "My iPhone"      # once
airdrop-cli ~/Pictures/photo.jpg # later
```

`airdrop-cli --to "Other Device" photo.jpg` overrides the saved target. On first use, grant **AirDrop CLI** Accessibility access in System Settings. The receiving device needs Wi-Fi, Bluetooth, and AirDrop enabled.

MIT license. Protocol reference: [OpenDrop](https://github.com/seemoo-lab/opendrop).

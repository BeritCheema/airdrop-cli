# airdrop-cli

[Watch the demo](demo/airdrop-cli-demo.mp4)

A standalone macOS CLI for sending files and links to an exact AirDrop device. It uses Apple's native AirDrop service, so Contacts Only works without extracting credentials.

```sh
make install
airdrop-cli setup               # discover and choose a default, once
airdrop-cli ~/Pictures/photo.jpg
airdrop-cli https://example.com
```

The default starts as **none**. Agents can set it with `airdrop-cli setup --device "Exact iPhone Name"`; `airdrop-cli clear` removes it. `--to "Other Device"` overrides it for one send. On first use, grant **AirDrop CLI** Accessibility access in System Settings.

MIT license. Protocol reference: [OpenDrop](https://github.com/seemoo-lab/opendrop).

# airdrop-now

Send a file from a Mac to a chosen AirDrop device with one command. Built for coding agents; uses [auto-airdrop-cli](https://github.com/owensantoso/auto-airdrop-cli) for native AirDrop, discovery, exact device matching, and transfer completion.

```sh
./install.sh
airdrop-now devices
airdrop-now use "My iPhone"       # once
airdrop-now ~/Pictures/photo.jpg  # every time after
```

Use `airdrop-now --to "Other Device" photo.jpg` for a one-time target. First use needs macOS Accessibility permission for your terminal, plus Wi-Fi, Bluetooth, and a discoverable iPhone. Same Apple Account devices accept AirDrops automatically.

MIT license. See [LICENSE](LICENSE).

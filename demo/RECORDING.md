# Demo

The [video](airdrop-cli-demo.mp4) cuts together an actual Mac AirDrop send of this repository's URL and an iPhone screen recording opening it in Safari. The Mac background was cleaned to remove unrelated windows; the AirDrop picker is from the live transfer.

To make the same cut with source recordings:

```sh
python3 demo/cut-real.py --mac mac.mp4 --iphone iphone.mov --desktop clean-mac.png
```

The cut script uses capture timing and screen sizes from this recording.

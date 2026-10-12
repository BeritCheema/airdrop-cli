# Demo

The [17-second video](airdrop-cli-demo.mp4) shows a real AirDrop of this repository's URL from a Mac to `ipon`, followed by the iPhone opening the repository in Safari. The command card is designed; the AirDrop picker and iPhone screen are recorded footage.

To recreate the cut from your own Mac and iPhone recordings:

```sh
python3 demo/cut-real.py --mac mac.mp4 --iphone iphone.mov
```

The cut script expects the same capture timing and screen size as the source recordings for this demo. The finished MP4 is the portable deliverable.

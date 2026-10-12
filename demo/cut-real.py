#!/usr/bin/env python3
"""Cut actual Mac AirDrop and iPhone recordings into a plain screen demo."""

import argparse
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).parent
WIDTH, HEIGHT, FPS = 1512, 982, 24
MAC_START, MAC_SECONDS = 5.0, 5.3
PHONE_START, PHONE_SECONDS = 0.4, 6.8


def frames(source: Path, folder: Path, start: float, seconds: float, filters: str):
    folder.mkdir()
    subprocess.run(
        [
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
            "-ss", str(start), "-t", str(seconds), "-i", str(source),
            "-vf", f"{filters},fps={FPS}", str(folder / "%04d.png"),
        ],
        check=True,
    )
    return sorted(folder.glob("*.png"))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mac", type=Path, required=True)
    parser.add_argument("--iphone", type=Path, required=True)
    parser.add_argument("--desktop", type=Path, required=True)
    parser.add_argument("--out", type=Path, default=ROOT / "airdrop-cli-demo.mp4")
    args = parser.parse_args()

    desktop = Image.open(args.desktop).convert("RGB").resize((WIDTH, HEIGHT))
    with tempfile.TemporaryDirectory() as tmp:
        temp = Path(tmp)
        picker = frames(args.mac, temp / "picker", MAC_START, MAC_SECONDS,
                        "crop=720:520:1152:720,scale=420:303")
        menu = frames(args.mac, temp / "menu", MAC_START, MAC_SECONDS,
                      "crop=3024:50:0:0,scale=1512:25")
        phone = frames(args.iphone, temp / "phone", PHONE_START, PHONE_SECONDS,
                       "scale=452:982")

        if not picker or not phone:
            raise RuntimeError("source recording has no frames")

        x, y = (WIDTH - 420) // 2, (HEIGHT - 303) // 2 - 28
        mask = Image.new("L", (420, 303))
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, 419, 302), radius=13, fill=255)
        shadow = Image.new("RGBA", (WIDTH, HEIGHT))
        shadow_mask = Image.new("L", (WIDTH, HEIGHT))
        ImageDraw.Draw(shadow_mask).rounded_rectangle(
            (x - 9, y - 5, x + 429, y + 315), radius=21, fill=105
        )
        shadow.putalpha(shadow_mask.filter(ImageFilter.GaussianBlur(18)))

        command = [
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
            "-f", "rawvideo", "-pixel_format", "rgb24",
            "-video_size", f"{WIDTH}x{HEIGHT}", "-framerate", str(FPS),
            "-i", "-", "-an", "-c:v", "libx264", "-preset", "medium",
            "-crf", "19", "-pix_fmt", "yuv420p", "-movflags", "+faststart",
            str(args.out),
        ]
        with subprocess.Popen(command, stdin=subprocess.PIPE) as process:
            for index, path in enumerate(picker):
                frame = desktop.copy()
                frame.paste(Image.open(menu[min(index, len(menu) - 1)]), (0, 0))
                frame.paste(shadow, (0, 0), shadow)
                frame.paste(Image.open(path).convert("RGB"), (x, y), mask)
                process.stdin.write(frame.tobytes())
            for path in phone:
                frame = Image.new("RGB", (WIDTH, HEIGHT), "black")
                frame.paste(Image.open(path).convert("RGB"), ((WIDTH - 452) // 2, 0))
                process.stdin.write(frame.tobytes())
            process.stdin.close()
            if process.wait() != 0:
                raise RuntimeError("ffmpeg failed")
    print(args.out)


if __name__ == "__main__":
    main()

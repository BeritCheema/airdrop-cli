#!/usr/bin/env python3
"""Render the real AirDrop URL transfer from Mac and iPhone recordings."""
import argparse
import subprocess
import tempfile
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).parent
W, H, FPS, LENGTH = 1280, 720, 24, 17
SANS = "/System/Library/Fonts/Avenir Next.ttc"
MONO = "/System/Library/Fonts/Menlo.ttc"
MINT, WHITE, MUTED = (174, 244, 202), (244, 247, 242), (153, 178, 172)

def font(size, mono=False):
    return ImageFont.truetype(MONO if mono else SANS, size)

def canvas():
    image = Image.new("RGB", (W, H))
    px = image.load()
    for y in range(H):
        for x in range(W):
            r = y/H*.8 + x/W*.2
            px[x, y] = (int(11+19*r), int(19+38*r), int(28+34*r))
    draw = ImageDraw.Draw(image)
    for radius in (180, 280, 390):
        draw.ellipse((930-radius, 340-radius, 930+radius, 340+radius), outline=(44, 92, 77), width=2)
    draw.rounded_rectangle((66, 47, 257, 90), radius=15, fill=MINT)
    draw.text((84, 51), "airdrop-cli", fill=(20, 56, 43), font=font(28))
    return image

BASE = canvas()

def intro():
    im = BASE.copy(); d = ImageDraw.Draw(im)
    d.text((69, 217), "FROM MAC", fill=WHITE, font=font(95))
    d.text((69, 317), "TO IPHONE.", fill=WHITE, font=font(95))
    d.text((72, 447), "One command.", fill=MINT, font=font(58))
    d.text((72, 614), "REAL AIRDROP TRANSFER  /  GITHUB LINK", fill=MUTED, font=font(20, True))
    return im

def command(t):
    im = BASE.copy(); d = ImageDraw.Draw(im)
    d.text((66, 128), "Send a link from your Mac.", fill=WHITE, font=font(51))
    d.rounded_rectangle((65, 246, 1215, 554), radius=24, fill=(13, 21, 30), outline=(67, 100, 91), width=2)
    for x, c in ((89,(229,131,116)), (110,(230,195,113)), (131,(111,194,137))):
        d.ellipse((x,270,x+12,282), fill=c)
    d.text((958,263), "TERMINAL / MAC", fill=(103,134,129), font=font(17, True))
    d.line((65,301,1215,301), fill=(52,75,74), width=2)
    lines = ["$ airdrop-cli --to ipon", "  https://github.com/BeritCheema/airdrop-cli"]
    n = int(sum(map(len, lines)) * min(1, max(0, (t-2.0)/1.5)))
    d.text((94,356), lines[0][:min(n,len(lines[0]))], fill=WHITE, font=font(29, True))
    d.text((94,412), lines[1][:max(0,n-len(lines[0]))], fill=MINT, font=font(29, True))
    if t >= 3.6: d.text((94,487), "Sending to ipon...", fill=MUTED, font=font(23, True))
    d.text((70,636), "ONE COMMAND  /  ONE SAVED DEVICE", fill=MUTED, font=font(18, True))
    return im

def mac_scene(t, frames):
    im = BASE.copy(); d = ImageDraw.Draw(im)
    d.text((66,140), "Mac sends.", fill=WHITE, font=font(57))
    d.text((68,224), "ipon", fill=MINT, font=font(34, True))
    d.text((68,288), "GitHub repo URL", fill=WHITE, font=font(26))
    d.text((68,553), "Sent 1 item to ipon", fill=MINT if t>6.1 else MUTED, font=font(23, True))
    d.text((68,640), "REAL MAC SCREEN RECORDING", fill=MUTED, font=font(17, True))
    i = min(len(frames)-1, max(0, int((t-4.2)/3.1*len(frames))))
    im.paste(frames[i], (510,142))
    return im

def phone_scene(t, frames):
    im = BASE.copy(); d = ImageDraw.Draw(im)
    d.text((68,184), "iPhone opens.", fill=WHITE, font=font(65))
    d.text((71,289), "The repo lands in Safari.", fill=MINT, font=font(36))
    d.text((72,399), "github.com/BeritCheema/", fill=WHITE, font=font(24, True))
    d.text((72,435), "airdrop-cli", fill=WHITE, font=font(24, True))
    d.text((70,641), "REAL IPHONE SCREEN RECORDING", fill=MUTED, font=font(17, True))
    i = min(len(frames)-1, max(0, int((t-7.3)/6.3*len(frames))))
    d.rounded_rectangle((851,23,1169,697), radius=36, fill=(6,9,13), outline=(101,137,123), width=3)
    im.paste(frames[i], (860,34))
    return im

def outro():
    im = BASE.copy(); d = ImageDraw.Draw(im)
    d.text((69,243), "One command.", fill=WHITE, font=font(100))
    d.text((70,355), "Your iPhone.", fill=MINT, font=font(100))
    d.line((70,493,1190,493), fill=(85,142,113), width=3)
    d.text((71,542), "github.com/BeritCheema/airdrop-cli", fill=WHITE, font=font(39))
    d.text((72,635), "macOS  /  OPEN SOURCE  /  MIT", fill=MUTED, font=font(17, True))
    return im

def extract(source, folder, start, length, vf):
    subprocess.run(["ffmpeg","-hide_banner","-loglevel","error","-y","-ss",str(start),
                    "-t",str(length),"-i",str(source),"-vf",f"{vf},fps={FPS}",
                    str(folder/"%04d.png")], check=True)
    return [Image.open(p).convert("RGB") for p in sorted(folder.glob("*.png"))]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mac", type=Path, required=True)
    parser.add_argument("--iphone", type=Path, required=True)
    parser.add_argument("--out", type=Path, default=ROOT/"airdrop-cli-demo.mp4")
    args = parser.parse_args()
    with tempfile.TemporaryDirectory() as tmp:
        md, pd = Path(tmp)/"mac", Path(tmp)/"phone"
        md.mkdir(); pd.mkdir()
        mac = extract(args.mac, md, 8.35, 2.10, "crop=720:520:1152:720")
        phone = extract(args.iphone, pd, 1.30, 6.00, "scale=300:652")
        opening, ending = intro(), outro()
        ff = ["ffmpeg","-hide_banner","-loglevel","error","-y","-f","rawvideo",
              "-pixel_format","rgb24","-video_size",f"{W}x{H}","-framerate",str(FPS),
              "-i","-","-an","-c:v","libx264","-preset","medium","-crf","18",
              "-pix_fmt","yuv420p","-movflags","+faststart",str(args.out)]
        with subprocess.Popen(ff, stdin=subprocess.PIPE) as process:
            for n in range(FPS*LENGTH):
                t = n/FPS
                if t<1.7: frame=opening
                elif t<2.1: frame=Image.blend(opening,command(t),(t-1.7)/.4)
                elif t<4.2: frame=command(t)
                elif t<7.3: frame=mac_scene(t,mac)
                elif t<13.6: frame=phone_scene(t,phone)
                elif t<14.0: frame=Image.blend(phone_scene(t,phone),ending,(t-13.6)/.4)
                else: frame=ending
                process.stdin.write(frame.tobytes())
            process.stdin.close()
            if process.wait()!=0: raise RuntimeError("ffmpeg failed")
    print(args.out)

if __name__ == "__main__": main()

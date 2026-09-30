#!/usr/bin/env python3
"""Era-style photo processing for DetectiveNet (2000-2003 look).

Two modes:
  scan    - printed photo, scanned: white border, slight rotation, paper grain,
            warm tint, vignette, low contrast, JPEG ~72
  digicam - early digital camera: 640x480, soft focus, noise, orange date stamp,
            heavy JPEG compression

Usage:
  python3 tools/process_photo.py scan    assets/photos/raw/*.jpg
  python3 tools/process_photo.py digicam assets/photos/raw/*.jpg
  python3 tools/process_photo.py both    assets/photos/raw/*.jpg
  python3 tools/process_photo.py --self-test

Output: assets/photos/processed/<name>_scan.jpg / <name>_digicam.jpg
"""

from __future__ import annotations

import argparse
import glob
import os
import random
import sys

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageOps

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROCESSED = os.path.join(ROOT, "assets", "photos", "processed")

MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
          "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]


def _stamp_font(size: int):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def paper_scan(img: Image.Image, rng: random.Random) -> Image.Image:
    img = img.convert("RGB")
    long_edge = max(img.size)
    if long_edge > 800:
        scale = 800 / long_edge
        img = img.resize((int(img.width * scale), int(img.height * scale)), Image.LANCZOS)

    paper = (250, 247, 240)
    canvas = Image.new("RGB", (img.width + 48, img.height + 48), paper)
    canvas.paste(img, (24, 24))
    canvas = canvas.rotate(rng.uniform(-1.8, 1.8), resample=Image.BICUBIC,
                           expand=True, fillcolor=paper)

    noise = Image.effect_noise(canvas.size, 16).convert("RGB")
    canvas = Image.blend(canvas, noise, 0.05)

    vig = Image.radial_gradient("L").resize(canvas.size)
    vig = vig.point(lambda v: 255 - int(v * 0.22))
    canvas = ImageChops.multiply(canvas, Image.merge("RGB", [vig] * 3))

    warm = Image.new("RGB", canvas.size, (255, 248, 232))
    canvas = ImageChops.multiply(canvas, warm)
    canvas = ImageEnhance.Contrast(canvas).enhance(0.92)
    return canvas


def digicam(img: Image.Image, rng: random.Random) -> Image.Image:
    img = ImageOps.fit(img.convert("RGB"), (640, 480), Image.LANCZOS)
    img = img.filter(ImageFilter.GaussianBlur(0.4))
    noise = Image.effect_noise((640, 480), 10).convert("RGB")
    img = Image.blend(img, noise, 0.06)
    img = ImageEnhance.Brightness(img).enhance(rng.uniform(0.96, 1.05))

    stamp = "%s %d '%02d" % (MONTHS[rng.randrange(12)], rng.randint(1, 28),
                             rng.randint(0, 3))
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    font = _stamp_font(22)
    d.text((486, 448), stamp, font=font, fill=(0, 0, 0, 120))
    d.text((484, 446), stamp, font=font, fill=(255, 150, 40, 255))
    blur = layer.filter(ImageFilter.GaussianBlur(1.2))
    img = Image.alpha_composite(img.convert("RGBA"), blur)
    img = Image.alpha_composite(img, layer)
    return img.convert("RGB")


def process(path: str, modes: list[str], seed: int, dest_dir: str = PROCESSED) -> None:
    os.makedirs(dest_dir, exist_ok=True)
    stem = os.path.splitext(os.path.basename(path))[0]
    raw = Image.open(path)
    for mode in modes:
        rng = random.Random(f"{stem}:{mode}:{seed}")
        out = paper_scan(raw, rng) if mode == "scan" else digicam(raw, rng)
        dest = os.path.join(dest_dir, f"{stem}_{mode}.jpg")
        if mode == "scan":
            out.save(dest, "JPEG", quality=72)
        else:
            out.save(dest, "JPEG", quality=52, subsampling=2)
        print("processed", os.path.relpath(dest, ROOT), out.size)


def synth_raw(seed: int) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new("RGB", (1600, 1200), (140, 175, 205))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 720, 1600, 1200], fill=(105, 145, 78))
    for i in range(7):
        x = 80 + i * 230
        d.polygon([(x, 760), (x + 70, 520), (x + 140, 760)], fill=(46, 92, 44))
    for i in range(4):
        x = 180 + i * 340
        d.ellipse([x, 660, x + 90, 750], fill=(rng.randint(120, 220),) * 3)
        d.rectangle([x + 15, 750, x + 75, 900], fill=tuple(rng.randint(40, 160) for _ in range(3)))
    d.ellipse([1200, 120, 1420, 340], fill=(250, 240, 180))
    d.text((60, 60), "PLACEHOLDER", font=_stamp_font(40), fill=(255, 255, 255))
    return img


def self_test() -> None:
    out_dir = os.path.join(ROOT, "spikes", "out")
    proc_dir = os.path.join(out_dir, "processed")
    os.makedirs(out_dir, exist_ok=True)
    raw_path = os.path.join(out_dir, "raw_selftest.jpg")
    synth_raw(7).save(raw_path, "JPEG", quality=90)
    print("synthetic raw ->", os.path.relpath(raw_path, ROOT))
    process(raw_path, ["scan", "digicam"], seed=3, dest_dir=proc_dir)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("mode", nargs="?", choices=["scan", "digicam", "both"])
    ap.add_argument("inputs", nargs="*")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        self_test()
        return
    if args.mode is None:
        ap.error("mode is required (scan | digicam | both)")
    paths: list[str] = []
    for pattern in args.inputs:
        paths.extend(sorted(glob.glob(pattern)))
    if not paths:
        ap.error("no input files (use --self-test to try the pipeline)")
    modes = ["scan", "digicam"] if args.mode == "both" else [args.mode]
    for p in paths:
        process(p, modes, args.seed)


if __name__ == "__main__":
    sys.exit(main())

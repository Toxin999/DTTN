#!/usr/bin/env python3
"""Generate original WEXP UI art (XP-inspired, not copied) with Pillow.

Everything is drawn from scratch: gradients, gloss, rounded corners, glyphs.
No Microsoft assets are used. Output goes to assets/ui/luna/.

Run:  python3 tools/gen_ui_assets.py
"""

from __future__ import annotations

import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "ui", "luna")
SS = 4  # supersample factor for masks/glyphs

# ---------------------------------------------------------------- helpers


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def shade(c, delta):
    return tuple(max(0, min(255, v + delta)) for v in c)


def vgrad(size, stops):
    w, h = size
    img = Image.new("RGBA", size)
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        col = stops[-1][1]
        for i in range(len(stops) - 1):
            t0, c0 = stops[i]
            t1, c1 = stops[i + 1]
            if t0 <= t <= t1:
                u = 0.0 if t1 == t0 else (t - t0) / (t1 - t0)
                col = lerp(c0, c1, max(0.0, min(1.0, u)))
                break
        for x in range(w):
            px[x, y] = (*col, 255)
    return img


def gloss(img, fraction=0.5, alpha=70):
    w, h = img.size
    band = Image.new("L", (1, h))
    bp = band.load()
    for y in range(h):
        t = y / max(1, h - 1)
        bp[0, y] = int(alpha * (1 - t / fraction)) if t < fraction else 0
    band = band.resize((w, h))
    img.paste(Image.new("RGBA", img.size, (255, 255, 255, 255)), (0, 0), band)
    return img


def rounded_mask(size, radii):
    """radii: (tl, tr, br, bl) in pixels."""
    W, H = size[0] * SS, size[1] * SS
    r = [max(0, v * SS) for v in radii]
    m = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(m)

    def rect(x0, y0, x1, y1):
        if x1 >= x0 and y1 >= y0:
            d.rectangle([x0, y0, x1, y1], fill=255)

    rect(r[0], 0, W - 1 - r[1], H - 1)
    rect(0, r[0], W - 1, H - 1 - r[3])
    if r[0]:
        d.pieslice([0, 0, 2 * r[0], 2 * r[0]], 180, 270, fill=255)
    if r[1]:
        d.pieslice([W - 2 * r[1], 0, W, 2 * r[1]], 270, 360, fill=255)
    if r[2]:
        d.pieslice([W - 2 * r[2], H - 2 * r[2], W, H], 0, 90, fill=255)
    if r[3]:
        d.pieslice([0, H - 2 * r[3], 2 * r[3], H], 90, 180, fill=255)
    return m.resize(size, Image.LANCZOS)


def add_border(img, color, width=1):
    a = img.getchannel("A")
    inner = a.filter(ImageFilter.MinFilter(width * 2 + 1))
    ring = ImageChops.subtract(a, inner)
    img.paste(Image.new("RGBA", img.size, (*color, 255)), (0, 0), ring)
    return img


def save(img, name):
    path = os.path.join(OUT, name)
    img.save(path)
    print("wrote", os.path.relpath(path, ROOT))


# ---------------------------------------------------------------- pieces

TITLE_H = 30
CAP_W = 30


def titlebar_caps(active: bool):
    if active:
        stops = [(0.0, (0, 84, 230)), (0.45, (59, 138, 255)),
                 (0.55, (52, 130, 250)), (1.0, (11, 74, 200))]
        ga = 90
    else:
        stops = [(0.0, (122, 156, 222)), (0.5, (178, 200, 240)),
                 (1.0, (122, 156, 222))]
        ga = 60
    for name, radii in (("left", (8, 0, 0, 0)), ("right", (0, 8, 0, 0))):
        img = vgrad((CAP_W, TITLE_H), stops)
        gloss(img, 0.5, ga)
        img.putalpha(rounded_mask((CAP_W, TITLE_H), radii))
        save(img, f"titlebar_{'active' if active else 'inactive'}_{name}.png")
    center = vgrad((16, TITLE_H), stops)
    gloss(center, 0.5, ga)
    save(center, f"titlebar_{'active' if active else 'inactive'}_center.png")


def window_buttons():
    base = {
        "normal": ((104, 160, 240), (38, 88, 190), (24, 58, 130)),
        "hover": ((150, 195, 255), (58, 120, 225), (24, 70, 150)),
        "pressed": ((60, 100, 180), (20, 50, 120), (12, 34, 80)),
    }
    for state, (c0, c1, border) in base.items():
        for glyph in ("min", "max", "close"):
            W, H = 21 * SS, 21 * SS
            img = vgrad((W, H), [(0.0, c0), (1.0, c1)])
            gloss(img, 0.5, 60)
            m = rounded_mask((21, 21), (4, 4, 4, 4))
            img = img.resize((21, 21), Image.LANCZOS)
            img.putalpha(m)
            add_border(img, border)
            # glyph drawn small on final size, 2px strokes (chunky like the era)
            d = ImageDraw.Draw(img)
            fg = (248, 252, 255) if state != "pressed" else (222, 232, 248)
            sh = (12, 30, 70)
            if glyph == "close":
                d.line([6, 6, 15, 15], fill=sh, width=2)
                d.line([15, 6, 6, 15], fill=sh, width=2)
                d.line([5, 5, 14, 14], fill=fg, width=2)
                d.line([14, 5, 5, 14], fill=fg, width=2)
            elif glyph == "min":
                d.line([5, 16, 15, 16], fill=sh, width=2)
                d.line([5, 15, 15, 15], fill=fg, width=2)
            elif glyph == "max":
                d.rectangle([6, 5, 14, 13], outline=sh, width=1)
                d.rectangle([5, 6, 13, 14], outline=fg, width=1)
            save(img, f"win_{glyph}_{state}.png")


def taskbar():
    img = vgrad((64, 34), [
        (0.0, (128, 176, 255)),
        (0.06, (60, 118, 235)),
        (0.5, (44, 96, 210)),
        (1.0, (18, 52, 148)),
    ])
    save(img, "taskbar_tile.png")


def start_button():
    for state, delta in (("normal", 0), ("hover", 16), ("pressed", -26)):
        stops = [
            (0.0, shade((116, 200, 92), delta)),
            (0.45, shade((86, 168, 58), delta)),
            (0.5, shade((74, 150, 48), delta)),
            (1.0, shade((40, 102, 26), delta)),
        ]
        img = vgrad((100, 30), stops)
        gloss(img, 0.55, 90)
        img.putalpha(rounded_mask((100, 30), (15, 15, 15, 15)))
        add_border(img, shade((22, 66, 12), delta))
        save(img, f"start_{state}.png")


def wallpaper():
    W, H = 1280, 720
    sky = vgrad((W, H), [
        (0.0, (38, 96, 176)),
        (0.62, (150, 198, 236)),
        (1.0, (196, 222, 244)),
    ])
    clouds = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(clouds)
    for cx, cy, rw, rh, a in (
        (260, 130, 180, 46, 120), (420, 105, 140, 38, 100),
        (840, 160, 220, 52, 110), (1080, 120, 150, 40, 90),
        (620, 210, 260, 44, 70),
    ):
        d.ellipse([cx - rw, cy - rh, cx + rw, cy + rh], fill=(255, 255, 255, a))
    clouds = clouds.filter(ImageFilter.GaussianBlur(26))
    sky.alpha_composite(clouds)

    hill = vgrad((W, H), [(0.0, (152, 198, 98)), (1.0, (72, 126, 42))])
    mask = Image.new("L", (W, H), 0)
    dm = ImageDraw.Draw(mask)
    dm.ellipse([-100, 330, 1380, 1330], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(1))
    sky.paste(hill, (0, 0), mask)

    hill2 = vgrad((W, H), [(0.0, (120, 170, 70)), (1.0, (50, 100, 32))])
    mask2 = Image.new("L", (W, H), 0)
    d2 = ImageDraw.Draw(mask2)
    d2.ellipse([700, 470, 2000, 1400], fill=255)
    d2.ellipse([-500, 430, 700, 1300], fill=255)
    mask2 = mask2.filter(ImageFilter.GaussianBlur(1))
    sky.paste(hill2, (0, 0), mask2)
    sky.convert("RGB").save(os.path.join(OUT, "wallpaper_hills.png"))
    print("wrote assets/ui/luna/wallpaper_hills.png")


def main():
    os.makedirs(OUT, exist_ok=True)
    titlebar_caps(True)
    titlebar_caps(False)
    window_buttons()
    taskbar()
    start_button()
    wallpaper()


if __name__ == "__main__":
    main()

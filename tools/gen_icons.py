#!/usr/bin/env python3
"""
Calm Corner - procedural app icon + splash generator (no stock art needed).

Usage:
    pip install pillow numpy
    python3 tools/gen_icons.py --out assets/brand

Writes (all PNG):
    icon_1024.png        opaque square, for iOS / store listing (iOS rounds the corners itself)
    icon_bg_1024.png     Android adaptive icon background (gradient)
    icon_fg_1024.png     Android adaptive icon foreground (bubble inside the 66% safe zone, transparent)
    icon_mono_1024.png   Android 13 themed icon (single colour silhouette, transparent)
    splash_logo_1152.png bubble on transparent, for flutter_native_splash
    preview.png          the above on one sheet, for a quick look
"""
import argparse, os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 2048  # work size; downsampled for crisp edges


def lerp(a, b, t): return a + (b - a) * t


def gradient_bg(size):
    stops = [(0.0, (255, 221, 196)), (0.55, (214, 190, 245)), (1.0, (150, 190, 235))]   # peach -> lavender -> sky
    y = np.linspace(0, 1, size)[:, None]
    img = np.zeros((size, size, 3))
    for (p0, c0), (p1, c1) in zip(stops[:-1], stops[1:]):
        m = (y >= p0) & (y <= p1)
        t = np.clip((y - p0) / (p1 - p0), 0, 1)
        for ch in range(3):
            img[..., ch] = np.where(m, lerp(c0[ch], c1[ch], t), img[..., ch])
    x = np.linspace(-1, 1, size)[None, :]
    img *= (1 - 0.06 * x ** 2)[..., None]                                             # faint vignette
    return Image.fromarray(img.clip(0, 255).astype("uint8"), "RGB")


def bubble(size, scale=1.0, mono=False):
    """Soap bubble: translucent body, iridescent rim, two highlights, soft shadow. RGBA."""
    cx, cy, r = size * 0.5, size * 0.5, size * 0.30 * scale
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    d = np.hypot(xx - cx, yy - cy) / r
    inside = d <= 1.0
    out = np.zeros((size, size, 4), np.float32)
    if mono:
        ring = (d > 0.86) & inside
        out[ring] = (0, 0, 0, 255)
        hl = np.hypot(xx - (cx - r * 0.38), yy - (cy - r * 0.42)) / (r * 0.16) <= 1
        out[hl & inside] = (0, 0, 0, 255)
        return Image.fromarray(out.astype("uint8"), "RGBA")
    rim = np.clip((d - 0.62) / 0.38, 0, 1) ** 2
    ang = np.arctan2(yy - cy, xx - cx)
    hue = 0.5 + 0.5 * np.sin(ang * 2 + 0.8)
    pink, cyan, white = np.array([255, 170, 210]), np.array([150, 225, 255]), np.array([255, 255, 255])
    tint = pink[None, None] * hue[..., None] + cyan[None, None] * (1 - hue[..., None])
    col = white[None, None] * (1 - 0.55 * rim[..., None]) + tint * (0.55 * rim[..., None])
    alpha = (0.14 + 0.62 * rim) * 255
    edge = np.clip((1.0 - d) * r / 2.0, 0, 1)                                         # anti-aliased edge
    out[..., :3] = col
    out[..., 3] = np.where(inside, alpha * edge, 0)
    img = Image.fromarray(out.astype("uint8"), "RGBA")
    hl = Image.new("RGBA", (size, size), (255, 255, 255, 0))   # white-transparent: blur must not darken edges
    d1 = ImageDraw.Draw(hl)
    d1.ellipse([cx - r * 0.60, cy - r * 0.66, cx - r * 0.12, cy - r * 0.30], fill=(255, 255, 255, 235))
    d1.ellipse([cx + r * 0.30, cy + r * 0.42, cx + r * 0.56, cy + r * 0.62], fill=(255, 255, 255, 120))
    hl = hl.filter(ImageFilter.GaussianBlur(size * 0.006))
    return Image.alpha_composite(img, hl)


def shadow(size, scale=1.0):
    sh = Image.new("RGBA", (size, size), (90, 70, 150, 0))
    r = size * 0.30 * scale
    ImageDraw.Draw(sh).ellipse([size * 0.5 - r * 0.8, size * 0.5 + r * 1.12, size * 0.5 + r * 0.8, size * 0.5 + r * 1.26], fill=(90, 70, 150, 70))
    return sh.filter(ImageFilter.GaussianBlur(size * 0.012))


def save(img, path, px):
    img.resize((px, px), Image.LANCZOS).save(path)


def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--out", default="assets/brand"); a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    bg = gradient_bg(S).convert("RGBA")
    icon = Image.alpha_composite(Image.alpha_composite(bg, shadow(S)), bubble(S)).convert("RGB")
    save(icon, f"{a.out}/icon_1024.png", 1024)
    save(bg.convert("RGB"), f"{a.out}/icon_bg_1024.png", 1024)
    fg = Image.alpha_composite(shadow(S, 0.66), bubble(S, 0.66))                      # inside the 66% adaptive safe zone
    save(fg, f"{a.out}/icon_fg_1024.png", 1024)
    save(bubble(S, 0.66, mono=True), f"{a.out}/icon_mono_1024.png", 1024)
    save(Image.alpha_composite(shadow(S, 0.62), bubble(S, 0.62)), f"{a.out}/splash_logo_1152.png", 1152)
    sheet = Image.new("RGB", (4 * 360, 360), (245, 245, 245))
    for i, name in enumerate(["icon_1024", "icon_bg_1024", "icon_fg_1024", "icon_mono_1024"]):
        im = Image.open(f"{a.out}/{name}.png").convert("RGBA").resize((340, 340))
        base = Image.new("RGBA", (340, 340), (230, 230, 230, 255)); base.alpha_composite(im)
        sheet.paste(base.convert("RGB"), (i * 360 + 10, 10))
    sheet.save(f"{a.out}/preview.png")
    print("wrote icons to", a.out)


if __name__ == "__main__":
    main()
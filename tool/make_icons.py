# SPDX-License-Identifier: GPL-3.0-or-later
"""Renders Cairn's launcher and notification icons into android/app/src/main/res.

A cairn: four stacked stones in paper on the larch background, the top stone
gold (the brand accent). Drawn at 8x and downsampled so the edges stay clean at
every density. Adaptive icon (foreground + background color + monochrome),
legacy square icons, and a white-on-transparent status-bar icon for the
recording notification.

Run: python3 tool/make_icons.py   (needs Pillow)
"""
from pathlib import Path

from PIL import Image, ImageDraw

RES = Path(__file__).resolve().parent.parent / "android/app/src/main/res"

BACKGROUND = (0x15, 0x20, 0x1B, 255)  # larch surface
PAPER = (0xF6, 0xF3, 0xEC, 255)
GOLD = (0xD9, 0xA4, 0x41, 255)
WHITE = (255, 255, 255, 255)

# Stones as (center_x, center_y, width, height) on a 108 dp adaptive canvas.
# The safe zone is the centered 66 dp circle; everything stays inside it.
STONES = [
    (54.0, 74.0, 40.0, 11.0),
    (52.5, 63.5, 32.0, 10.0),
    (55.0, 54.0, 25.0, 9.0),
    (53.5, 45.5, 15.0, 8.0),
]

DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
SUPER = 8


def draw_stones(size_px, canvas_dp, color_fn, offset_dp=(0.0, 0.0), scale=1.0):
    """Returns an RGBA image of the stones, transparent elsewhere."""
    px = size_px * SUPER
    img = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    k = px / canvas_dp
    for i, (cx, cy, w, h) in enumerate(STONES):
        cx = (cx - 54.0) * scale + 54.0 + offset_dp[0]
        cy = (cy - 60.0) * scale + 60.0 + offset_dp[1]
        w *= scale
        h *= scale
        box = [
            (cx - w / 2) * k,
            (cy - h / 2) * k,
            (cx + w / 2) * k,
            (cy + h / 2) * k,
        ]
        d.rounded_rectangle(box, radius=h / 2 * k, fill=color_fn(i))
    return img.resize((size_px, size_px), Image.LANCZOS)


def stone_color(i):
    return GOLD if i == len(STONES) - 1 else PAPER


def write(img, rel):
    out = RES / rel
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, "PNG", optimize=True)
    print(f"wrote {out.relative_to(RES)} {img.size[0]}x{img.size[1]}")


def main():
    for name, scale in DENSITIES.items():
        # Adaptive foreground and monochrome: 108 dp canvas.
        fg = int(108 * scale)
        write(draw_stones(fg, 108, stone_color), f"mipmap-{name}/ic_launcher_foreground.png")
        write(draw_stones(fg, 108, lambda i: WHITE), f"mipmap-{name}/ic_launcher_monochrome.png")

        # Legacy launcher (pre-Android 8): a rounded square of the background
        # with the stones scaled up, since there is no system mask to allow for.
        side = int(48 * scale)
        px = side * SUPER
        legacy = Image.new("RGBA", (px, px), (0, 0, 0, 0))
        ImageDraw.Draw(legacy).rounded_rectangle(
            [0, 0, px - 1, px - 1], radius=px * 0.18, fill=BACKGROUND
        )
        legacy = legacy.resize((side, side), Image.LANCZOS)
        stones = draw_stones(side, 48, stone_color, offset_dp=(-30.0, -36.0), scale=0.62)
        legacy.alpha_composite(stones)
        write(legacy, f"mipmap-{name}/ic_launcher.png")

        # Status-bar icon for the recording notification: 24 dp, white only.
        small = int(24 * scale)
        write(
            draw_stones(small, 24, lambda i: WHITE, offset_dp=(-42.0, -48.0), scale=0.42),
            f"drawable-{name}/ic_stat_cairn.png",
        )

    (RES / "mipmap-anydpi-v26").mkdir(exist_ok=True)
    (RES / "mipmap-anydpi-v26/ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>\n'
        "</adaptive-icon>\n"
    )
    (RES / "values/ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        '    <color name="ic_launcher_background">#15201B</color>\n'
        "</resources>\n"
    )
    print("wrote mipmap-anydpi-v26/ic_launcher.xml and values/ic_launcher_background.xml")


if __name__ == "__main__":
    main()

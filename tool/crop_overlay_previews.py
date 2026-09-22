# SPDX-License-Identifier: GPL-3.0-or-later
"""Crop overlay preview thumbnails for the layer sheet.

Usage: python3 tool/crop_overlay_previews.py SRC_DIR key:screenshot.png[:cx,cy] [...]

Each screenshot is a full-screen emulator capture with that one overlay on
over the Outdoors base map; a 7:5 window around the map center (or the
given center, for a sparse overlay) becomes
assets/map_previews/overlay_<key>.png at 280 by 200 px (a 70 by 50 dp
thumbnail at up to 4x).
"""
import sys
from pathlib import Path

from PIL import Image

OUT = Path("assets/map_previews")
SIZE = (280, 200)
CROP = (520, 372)  # source pixels on a 1080 px wide capture
CENTER = (540, 820)  # away from the top controls and the bottom sheet


def main() -> None:
    src_dir = Path(sys.argv[1])
    OUT.mkdir(parents=True, exist_ok=True)
    for spec in sys.argv[2:]:
        parts = spec.split(":")
        key, name = parts[0], parts[1]
        img = Image.open(src_dir / name).convert("RGB")
        cx, cy = CENTER
        if len(parts) > 2:
            cx, cy = (int(v) for v in parts[2].split(","))
        w, h = CROP
        box = (cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2)
        tile = img.crop(box).resize(SIZE, Image.LANCZOS)
        target = OUT / f"overlay_{key}.png"
        tile.save(target, optimize=True)
        print(f"{target}: {SIZE[0]}x{SIZE[1]}, {target.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()

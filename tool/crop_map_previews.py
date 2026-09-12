# SPDX-License-Identifier: GPL-3.0-or-later
"""Crop base-map preview tiles for the layer sheet (Addendum A5.2).

Usage: python3 tool/crop_map_previews.py SRC_DIR key:screenshot.png [...]

Each screenshot is a full-screen emulator capture of that base map over the
same view; a square around the map center becomes
assets/map_previews/<key>.png at 280 px (a 72 dp tile at up to 3x).
"""
import sys
from pathlib import Path

from PIL import Image

OUT = Path("assets/map_previews")
SIZE = 280
CROP = 520  # source pixels on a 1080 px wide capture
CENTER = (540, 820)  # away from the top controls and the bottom sheet


def main() -> None:
    src_dir = Path(sys.argv[1])
    OUT.mkdir(parents=True, exist_ok=True)
    for spec in sys.argv[2:]:
        key, name = spec.split(":", 1)
        img = Image.open(src_dir / name).convert("RGB")
        cx, cy = CENTER
        box = (cx - CROP // 2, cy - CROP // 2, cx + CROP // 2, cy + CROP // 2)
        tile = img.crop(box).resize((SIZE, SIZE), Image.LANCZOS)
        target = OUT / f"{key}.png"
        tile.save(target, optimize=True)
        print(f"{target}: {SIZE}x{SIZE}, {target.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()

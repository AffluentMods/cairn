# SPDX-License-Identifier: GPL-3.0-or-later
"""Downscale emulator screenshots for the F-Droid listing.

Usage: python3 tool/shrink_screenshots.py SRC_DIR N:src.png [N:src.png ...]

Each argument maps a listing index to a source PNG inside SRC_DIR; the
result lands in metadata/en-US/images/phoneScreenshots/<N>.png at 720 px
wide (F-Droid shows them small; full 1080 px captures only bloat the repo).
"""
import sys
from pathlib import Path

from PIL import Image

OUT = Path("metadata/en-US/images/phoneScreenshots")
WIDTH = 720


def main() -> None:
    src_dir = Path(sys.argv[1])
    OUT.mkdir(parents=True, exist_ok=True)
    for spec in sys.argv[2:]:
        index, name = spec.split(":", 1)
        img = Image.open(src_dir / name).convert("RGB")
        h = round(img.height * WIDTH / img.width)
        img = img.resize((WIDTH, h), Image.LANCZOS)
        target = OUT / f"{index}.png"
        img.save(target, optimize=True)
        print(f"{target}: {WIDTH}x{h}, {target.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()

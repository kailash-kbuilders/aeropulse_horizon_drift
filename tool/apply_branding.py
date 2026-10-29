#!/usr/bin/env python3
"""Generate the Android launcher icon and splash screen from branding/*.png.

Runs inside CI, right after the android/ folder has been generated (android/ is
not committed, so this has to be re-applied on every build).

    python3 tool/apply_branding.py

Produces:
  * mipmap-anydpi-v26/ic_launcher.xml  — adaptive icon (white background layer
    + the car as the foreground layer), so the launcher draws it with the normal
    rounded / circular mask instead of a plain square.
  * mipmap-*/ic_launcher.png           — legacy fallback, already rounded.
  * mipmap-*/ic_launcher_foreground.png
  * drawable-nodpi/splash_logo.png     — white splash art.
"""
import pathlib
import sys

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
ART = ROOT / "branding/icon_art.png"
SPLASH_MASTER = ROOT / "branding/splash_master.png"

WHITE = (255, 255, 255, 255)
ICON_BG = "#FFFFFF"

# legacy launcher icon (48dp)
LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
# adaptive icon canvas is 108dp; the art must stay inside the 66dp safe circle
ADAPTIVE = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}

ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/icon_bg" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"""

LAUNCH_BACKGROUND = """<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_bg" />
    <item>
        <bitmap android:gravity="center" android:src="@drawable/splash_logo" />
    </item>
</layer-list>
"""

COLORS_XML = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="splash_bg">#FFFFFF</color>
    <color name="icon_bg">%s</color>
</resources>
""" % ICON_BG


def rounded_icon(art: Image.Image, size: int) -> Image.Image:
    """White rounded tile with the car centred — the pre-Android-8 look."""
    scale = 4  # draw big, then downscale for clean edges
    s = size * scale
    tile = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(tile)
    draw.rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * 0.22), fill=WHITE)

    target = s * 0.68
    ratio = target / max(art.size)
    scaled = art.resize((max(1, int(art.width * ratio)), max(1, int(art.height * ratio))), Image.LANCZOS)
    tile.paste(scaled, ((s - scaled.width) // 2, (s - scaled.height) // 2), scaled)
    return tile.resize((size, size), Image.LANCZOS)


def adaptive_foreground(art: Image.Image, size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    target = size * 0.58  # stays inside the 66dp safe zone
    ratio = target / max(art.size)
    scaled = art.resize((max(1, int(art.width * ratio)), max(1, int(art.height * ratio))), Image.LANCZOS)
    canvas.paste(scaled, ((size - scaled.width) // 2, (size - scaled.height) // 2), scaled)
    return canvas


def main() -> int:
    if not RES.is_dir():
        print("android/ res folder not found - nothing to brand")
        return 0

    art = Image.open(ART).convert("RGBA")

    for density, size in LEGACY.items():
        folder = RES / ("mipmap-" + density)
        folder.mkdir(parents=True, exist_ok=True)
        rounded_icon(art, size).save(folder / "ic_launcher.png")
        adaptive_foreground(art, ADAPTIVE[density]).save(folder / "ic_launcher_foreground.png")
        print("icon ->", density, size)

    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    for leftover in anydpi.iterdir():
        leftover.unlink()
    (anydpi / "ic_launcher.xml").write_text(ADAPTIVE_XML)
    print("adaptive icon ->", anydpi / "ic_launcher.xml")

    splash = Image.open(SPLASH_MASTER).convert("RGB")
    nodpi = RES / "drawable-nodpi"
    nodpi.mkdir(parents=True, exist_ok=True)
    splash.resize((1024, 1024), Image.LANCZOS).save(nodpi / "splash_logo.png")
    print("splash ->", nodpi / "splash_logo.png")

    colors = RES / "values/colors.xml"
    colors.parent.mkdir(parents=True, exist_ok=True)
    colors.write_text(COLORS_XML)

    for variant in ("drawable", "drawable-v21"):
        target = RES / variant / "launch_background.xml"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(LAUNCH_BACKGROUND)
        print("launch background ->", target)

    return 0


if __name__ == "__main__":
    sys.exit(main())

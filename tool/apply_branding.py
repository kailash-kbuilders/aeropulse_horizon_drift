#!/usr/bin/env python3
"""Generate the Android launcher icon and splash screen from branding/*.png.

Runs inside CI, right after the android/ folder has been generated (android/ is
not committed, so this has to be re-applied on every build).

    python3 tool/apply_branding.py
"""
import pathlib
import sys

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
ICON_MASTER = ROOT / "branding/icon_master.png"
SPLASH_MASTER = ROOT / "branding/splash_master.png"

# Must match the background baked into the master images.
SPLASH_BG = "#1D252C"

DENSITIES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

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
    <color name="splash_bg">%s</color>
</resources>
""" % SPLASH_BG


def main() -> int:
    if not RES.is_dir():
        print("android/ res folder not found - nothing to brand")
        return 0

    icon = Image.open(ICON_MASTER).convert("RGB")
    for density, size in DENSITIES.items():
        folder = RES / ("mipmap-" + density)
        folder.mkdir(parents=True, exist_ok=True)
        icon.resize((size, size), Image.LANCZOS).save(folder / "ic_launcher.png")
        print("icon ->", folder / "ic_launcher.png")

    # An adaptive icon would crop the art to the device mask and lose the
    # padding we baked in, so drop it and let Android use the plain PNGs.
    anydpi = RES / "mipmap-anydpi-v26"
    if anydpi.is_dir():
        for item in anydpi.iterdir():
            item.unlink()
        anydpi.rmdir()
        print("removed mipmap-anydpi-v26 (adaptive icon)")

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

"""Generate Android launcher icons from the artwork in assets/icon/.

The android/ folder is not committed (the CI workflow generates it), so the
launcher icon is written here at build time.

Two flavours are produced:
  * a legacy rounded-square PNG for older launchers, and
  * a proper adaptive icon (foreground + background colour) so Android 8+
    masks the icon to the launcher's own shape - circle, squircle or rounded
    square - exactly like every other app on the device.
"""
import pathlib

from PIL import Image, ImageDraw, ImageFilter

ICON_DIR = pathlib.Path("assets/icon")
MASTER = ICON_DIR / "app_icon.png"                 # rounded square, full bleed
FOREGROUND = ICON_DIR / "app_icon_foreground.png"  # transparent mark
RES = pathlib.Path("android/app/src/main/res")

BACKGROUND_COLOR = "#15171D"

# folder -> (legacy icon px, adaptive foreground px)
DENSITIES = {
    "mipmap-mdpi": (48, 108),
    "mipmap-hdpi": (72, 162),
    "mipmap-xhdpi": (96, 216),
    "mipmap-xxhdpi": (144, 324),
    "mipmap-xxxhdpi": (192, 432),
}

ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"""

COLORS_XML = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">{color}</color>
</resources>
"""


def circular(image):
    size = image.size[0]
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, size - 1, size - 1], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(size * 0.004))
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(image, (0, 0), mask)
    return out


def main():
    if not MASTER.exists() or not RES.exists():
        print("skip: artwork or res folder missing")
        return

    master = Image.open(MASTER).convert("RGBA")
    foreground = Image.open(FOREGROUND).convert("RGBA")

    for folder, (legacy_px, adaptive_px) in DENSITIES.items():
        target = RES / folder
        target.mkdir(parents=True, exist_ok=True)

        square = master.resize((legacy_px, legacy_px), Image.LANCZOS)
        square.save(target / "ic_launcher.png")
        circular(square).save(target / "ic_launcher_round.png")

        foreground.resize((adaptive_px, adaptive_px), Image.LANCZOS).save(
            target / "ic_launcher_foreground.png"
        )
        print("wrote", folder)

    # Adaptive icon descriptors (Android 8+).
    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(ADAPTIVE_XML)
    (anydpi / "ic_launcher_round.xml").write_text(ADAPTIVE_XML)

    values = RES / "values"
    values.mkdir(parents=True, exist_ok=True)
    (values / "ic_launcher_background.xml").write_text(
        COLORS_XML.format(color=BACKGROUND_COLOR)
    )
    print("adaptive icon + background colour written")


if __name__ == "__main__":
    main()

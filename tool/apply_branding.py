"""Generate Android launcher icons from assets/icon/app_icon.png.

The android/ folder is not committed (the CI workflow generates it), so the
launcher icon is written here at build time instead.
"""
import os
import pathlib

from PIL import Image

SOURCE = pathlib.Path("assets/icon/app_icon.png")
RES = pathlib.Path("android/app/src/main/res")

DENSITIES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def main() -> None:
    if not SOURCE.exists() or not RES.exists():
        print("skip: source icon or res folder missing")
        return

    master = Image.open(SOURCE).convert("RGBA")
    for folder, size in DENSITIES.items():
        target = RES / folder
        target.mkdir(parents=True, exist_ok=True)
        icon = master.resize((size, size), Image.LANCZOS)
        icon.save(target / "ic_launcher.png")
        icon.save(target / "ic_launcher_round.png")
        print("wrote", target / "ic_launcher.png", size)


if __name__ == "__main__":
    main()

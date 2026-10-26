"""Generate the BioSense launcher icons from the original artwork.

The source image contains an opaque black canvas around the rounded blue icon.
This script removes only the black region connected to the image border, crops
the artwork without changing its aspect ratio, and creates native Android/iOS
sizes with high-quality Lanczos resampling.
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT.parent / "doc" / "image" / "Icono_App_BioSense.png"
ASSET = ROOT / "assets" / "branding" / "biosense_icon.png"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
IOS_SET = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
BLUE_BACKGROUND = (0, 65, 145, 255)


def cleaned_source() -> Image.Image:
    image = Image.open(SOURCE).convert("RGBA")
    draw = ImageDraw.Draw(image)

    # Remove only dark pixels connected to the four exterior corners. This
    # preserves the intentional dark shadows inside the icon artwork.
    for point in ((0, 0), (image.width - 1, 0), (0, image.height - 1),
                  (image.width - 1, image.height - 1)):
        ImageDraw.floodfill(image, point, (0, 0, 0, 0), thresh=22)

    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise RuntimeError("The icon became fully transparent")
    image = image.crop(bounds)

    # Keep a square canvas and center the art instead of stretching it.
    side = max(image.size)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.alpha_composite(
        image,
        ((side - image.width) // 2, (side - image.height) // 2),
    )
    return square


def save_resized(image: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.Resampling.LANCZOS).save(path, optimize=True)


def generate_android(image: Image.Image) -> None:
    legacy_sizes = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }
    foreground_sizes = {
        "mdpi": 108,
        "hdpi": 162,
        "xhdpi": 216,
        "xxhdpi": 324,
        "xxxhdpi": 432,
    }

    for density, size in legacy_sizes.items():
        directory = ANDROID_RES / f"mipmap-{density}"
        save_resized(image, directory / "ic_launcher.png", size)
        save_resized(image, directory / "ic_launcher_round.png", size)

    # Adaptive icons get a little breathing room so Android's circle/squircle
    # masks do not cut the sensor symbols near the perimeter.
    for density, size in foreground_sizes.items():
        canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        art_size = round(size * 0.9)
        artwork = image.resize((art_size, art_size), Image.Resampling.LANCZOS)
        offset = (size - art_size) // 2
        canvas.alpha_composite(artwork, (offset, offset))
        path = ANDROID_RES / f"drawable-{density}" / "ic_launcher_foreground.png"
        path.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(path, optimize=True)


def generate_ios(image: Image.Image) -> None:
    contents = json.loads((IOS_SET / "Contents.json").read_text(encoding="utf-8"))
    for entry in contents["images"]:
        filename = entry.get("filename")
        if not filename:
            continue
        points = float(entry["size"].split("x", 1)[0])
        scale = int(entry["scale"].removesuffix("x"))
        pixels = round(points * scale)

        resized = image.resize((pixels, pixels), Image.Resampling.LANCZOS)
        # App Store icons cannot contain transparency. A deep blue backing also
        # prevents white corners before iOS applies its launcher mask.
        opaque = Image.new("RGBA", (pixels, pixels), BLUE_BACKGROUND)
        opaque.alpha_composite(resized)
        opaque.convert("RGB").save(IOS_SET / filename, optimize=True)


def main() -> None:
    image = cleaned_source()
    ASSET.parent.mkdir(parents=True, exist_ok=True)
    image.save(ASSET, optimize=True)
    generate_android(image)
    generate_ios(image)
    print(f"Generated launcher icons from {SOURCE.name} ({image.width}x{image.height})")


if __name__ == "__main__":
    main()

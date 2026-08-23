"""Regenerates the Wolevo brand mark PNGs from a traced vector outline.

The source artwork supplied by the client is a 762x203 raster in which the mark
occupies only 143x129 pixels — far too small to upscale for a splash screen.
The mark is made of straight-edged bars plus a circular dot, so it was traced
once into the normalised polygon below and is re-rasterised at whatever size is
needed. Run with:  python3 tool/generate_brand_assets.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

# Brand green, sampled from the supplied artwork (AppColors.primary).
GREEN = (1, 255, 105, 255)
# The client also supplied an inverted lockup: dark mark on a neon field.
FOREST = (10, 51, 7, 255)
LIME = (223, 255, 124, 255)

# Traced from the source at a 143x129 mark bounding box, then normalised to 0..1.
_MARK_W, _MARK_H = 143.0, 129.0
_ORIGIN_X, _ORIGIN_Y = 0.0, 26.0

_W_OUTLINE = [
    (34, 26), (40, 28), (40, 65), (9, 96), (10, 104), (82, 32), (88, 33),
    (87, 72), (63, 96), (64, 104), (136, 32), (142, 33), (141, 73), (62, 152),
    (56, 153), (54, 151), (53, 106), (6, 153), (2, 153), (0, 151), (0, 60),
]

# The dot: a 35px-diameter circle, fill ratio 0.78 ≈ pi/4 confirmed it is round.
_DOT_CENTRE = (122.0, 137.0)
_DOT_RADIUS = 17.5

W_OUTLINE = [
    ((x - _ORIGIN_X) / _MARK_W, (y - _ORIGIN_Y) / _MARK_H) for x, y in _W_OUTLINE
]
DOT_CENTRE = (
    (_DOT_CENTRE[0] - _ORIGIN_X) / _MARK_W,
    (_DOT_CENTRE[1] - _ORIGIN_Y) / _MARK_H,
)
DOT_RADIUS = _DOT_RADIUS / _MARK_W


def render_mark(canvas: int, mark_width_ratio: float, colour=GREEN) -> Image.Image:
    """Draws the mark centred on a transparent square canvas."""
    # Supersample, then downscale, so the diagonals stay clean.
    scale = 4
    size = canvas * scale
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    mark_w = size * mark_width_ratio
    mark_h = mark_w * (_MARK_H / _MARK_W)
    off_x = (size - mark_w) / 2
    off_y = (size - mark_h) / 2

    draw.polygon(
        [(off_x + x * mark_w, off_y + y * mark_h) for x, y in W_OUTLINE],
        fill=colour,
    )

    cx = off_x + DOT_CENTRE[0] * mark_w
    cy = off_y + DOT_CENTRE[1] * mark_h
    r = DOT_RADIUS * mark_w
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=colour)

    return img.resize((canvas, canvas), Image.LANCZOS)


# ---------------------------------------------------------------------------
# App icons.
#
# Each entry is (name, background, mark colour). Launcher icons must be opaque —
# iOS rejects alpha — so every icon is a solid brand field with the mark on top.
# Adding a seasonal icon means adding one line here and re-running: the palette
# is the only thing that varies, so a variant can never drift off-brand.
ICON_VARIANTS = {
    "default": ((10, 51, 7, 255), GREEN),      # forest field, neon mark
    "lime": ((1, 255, 105, 255), FOREST),      # the client's inverted lockup
    "midnight": ((13, 17, 12, 255), GREEN),    # near-black, for dark seasons
    "festive": ((10, 51, 7, 255), LIME),       # forest field, lime mark
}

# Alternate icons the OS needs as real files.
#   iOS  — 60pt at @2x/@3x, referenced by name from Info.plist.
#   Android — one PNG per density bucket, referenced by an activity-alias.
IOS_ALTERNATE_SIZES = {"@2x": 120, "@3x": 180}
ANDROID_DENSITIES = {
    "mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192,
}


def render_icon(canvas: int, background, mark_colour) -> Image.Image:
    """Opaque square icon: solid field with the mark centred."""
    icon = Image.new("RGBA", (canvas, canvas), background)
    # 52% keeps the mark clear of iOS's corner radius and Android's mask.
    mark = render_mark(canvas, 0.52, mark_colour)
    icon.alpha_composite(mark)
    return icon


if __name__ == "__main__":
    # iOS/Android splash image.
    render_mark(768, 0.39).save("assets/brand/splash_mark.png")
    # Android 12+ splash icon: the OS masks to a circle, so keep the art well
    # inside the 2/3 safe zone.
    render_mark(1152, 0.255).save("assets/brand/splash_mark_android12.png")
    # General-purpose asset for in-app use.
    render_mark(512, 0.86).save("assets/brand/wolevo_mark.png")
    # Inverted lockup, for use on a neon field.
    render_mark(768, 0.39, FOREST).save("assets/brand/splash_mark_dark.png")
    render_mark(1152, 0.255, FOREST).save("assets/brand/splash_mark_dark_android12.png")
    for name, (background, mark_colour) in ICON_VARIANTS.items():
        render_icon(1024, background, mark_colour).save(f"assets/brand/icon_{name}.png")
        # Android adaptive icons supply the foreground separately, with the
        # background as a flat colour, so the mark needs extra breathing room:
        # the OS crops to a circle/squircle from a 108dp canvas.
        render_mark(1024, 0.40, mark_colour).save(
            f"assets/brand/icon_{name}_foreground.png"
        )

    # Alternate icons, written straight into the platform folders. Only the
    # non-default variants need these — "default" ships as the primary icon.
    ios_dir = Path("ios/Runner")
    for name, (background, mark_colour) in ICON_VARIANTS.items():
        if name == "default":
            continue
        for suffix, px in IOS_ALTERNATE_SIZES.items():
            render_icon(px, background, mark_colour).convert("RGB").save(
                ios_dir / f"AppIcon-{name}{suffix}.png"
            )
        for bucket, px in ANDROID_DENSITIES.items():
            out = Path(f"android/app/src/main/res/mipmap-{bucket}")
            out.mkdir(parents=True, exist_ok=True)
            render_icon(px, background, mark_colour).save(
                out / f"ic_launcher_{name}.png"
            )

    print("wrote assets/brand/*.png and platform alternate icons")

#!/usr/bin/env python3

"""Generate a macOS app icon inspired by the unMineable mint "U" mark.

The goal is not to ship the site favicon unchanged. Instead, this script builds
an original rounded-square application icon that keeps the recognizable mint
color language and central "U" silhouette while fitting the native macOS app
icon style more cleanly.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


SIZE = 1024
MINT = (156, 202, 191, 255)
MINT_BRIGHT = (183, 235, 222, 255)
MINT_DARK = (103, 163, 148, 255)
GOLD = (232, 191, 116, 255)
BG_TOP = (19, 23, 28, 255)
BG_BOTTOM = (8, 10, 14, 255)


def vertical_gradient(size: int, top: tuple[int, int, int, int], bottom: tuple[int, int, int, int]) -> Image.Image:
    image = Image.new("RGBA", (size, size))
    draw = ImageDraw.Draw(image)
    for y in range(size):
        t = y / max(1, size - 1)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(4))
        draw.line((0, y, size, y), fill=color)
    return image


def add_glow(base: Image.Image, mask: Image.Image, color: tuple[int, int, int, int], blur: int, alpha_scale: float = 1.0) -> None:
    glow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    tinted = Image.new("RGBA", base.size, color)
    blurred = mask.filter(ImageFilter.GaussianBlur(blur))
    if alpha_scale != 1.0:
        alpha = blurred.getchannel("A").point(lambda v: max(0, min(255, int(v * alpha_scale))))
        blurred.putalpha(alpha)
    glow = Image.composite(tinted, glow, blurred.getchannel("A"))
    base.alpha_composite(glow)


def draw_icon() -> Image.Image:
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    background = vertical_gradient(SIZE, BG_TOP, BG_BOTTOM)

    outer_mask = Image.new("L", (SIZE, SIZE), 0)
    outer_draw = ImageDraw.Draw(outer_mask)
    outer_draw.rounded_rectangle((48, 48, SIZE - 48, SIZE - 48), radius=220, fill=255)

    shaped_background = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shaped_background = Image.composite(background, shaped_background, outer_mask)
    canvas.alpha_composite(shaped_background)

    vignette = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    vignette_draw = ImageDraw.Draw(vignette)
    vignette_draw.rounded_rectangle((48, 48, SIZE - 48, SIZE - 48), radius=220, outline=(255, 255, 255, 28), width=4)
    canvas.alpha_composite(vignette)

    glow_mask = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_mask)
    glow_draw.ellipse((168, 148, 856, 836), fill=(255, 255, 255, 72))
    add_glow(canvas, glow_mask, (102, 190, 173, 90), blur=60, alpha_scale=0.55)

    ornament = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ornament_draw = ImageDraw.Draw(ornament)
    ornament_draw.ellipse((136, 140, 280, 284), fill=(255, 255, 255, 18))
    ornament_draw.ellipse((760, 730, 892, 862), fill=(255, 255, 255, 14))
    ornament_draw.rounded_rectangle((162, 694, 312, 728), radius=16, fill=(255, 255, 255, 10))
    canvas.alpha_composite(ornament)

    u_mask = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    u_draw = ImageDraw.Draw(u_mask)

    stroke = 112
    left_x = 332
    right_x = 692
    top_y = 248
    bottom_y = 722

    # Two vertical stems.
    u_draw.rounded_rectangle((left_x - stroke // 2, top_y, left_x + stroke // 2, bottom_y), radius=stroke // 2, fill=(255, 255, 255, 255))
    u_draw.rounded_rectangle((right_x - stroke // 2, top_y, right_x + stroke // 2, bottom_y), radius=stroke // 2, fill=(255, 255, 255, 255))
    # Bottom curve.
    u_draw.pieslice((left_x - stroke // 2, bottom_y - 248, right_x + stroke // 2, bottom_y + 112), start=0, end=180, fill=(255, 255, 255, 255))
    # Clear the top half of the bowl so the lower curve becomes a true U.
    cutout = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cutout_draw = ImageDraw.Draw(cutout)
    cutout_draw.rounded_rectangle((left_x + 42, top_y + 36, right_x - 42, bottom_y - 12), radius=110, fill=(0, 0, 0, 255))
    u_mask = ImageChops.subtract(u_mask, cutout)

    add_glow(canvas, u_mask, MINT_BRIGHT, blur=28, alpha_scale=0.75)

    u_fill = Image.new("RGBA", (SIZE, SIZE), MINT)
    u_gradient = vertical_gradient(SIZE, MINT_BRIGHT, MINT_DARK)
    u_fill = Image.composite(u_gradient, u_fill, u_mask.getchannel("A"))
    canvas.alpha_composite(u_fill)

    inner_highlight = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    highlight_draw = ImageDraw.Draw(inner_highlight)
    highlight_draw.rounded_rectangle((left_x - stroke // 2 + 10, top_y + 6, left_x - stroke // 2 + 34, bottom_y - 56), radius=12, fill=(255, 255, 255, 40))
    highlight_draw.rounded_rectangle((right_x - stroke // 2 + 10, top_y + 6, right_x - stroke // 2 + 34, bottom_y - 56), radius=12, fill=(255, 255, 255, 24))
    canvas.alpha_composite(inner_highlight)

    # Mining-flavored accent: a compact angled chip/pick detail in the corner.
    accent = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    accent_draw = ImageDraw.Draw(accent)
    accent_draw.rounded_rectangle((706, 210, 836, 260), radius=25, fill=GOLD)
    accent_draw.rounded_rectangle((776, 148, 824, 326), radius=24, fill=GOLD)
    accent = accent.rotate(18, center=(784, 238), resample=Image.Resampling.BICUBIC)
    accent_blur = accent.filter(ImageFilter.GaussianBlur(10))
    canvas.alpha_composite(Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0)))
    canvas.alpha_composite(accent_blur)
    canvas.alpha_composite(accent)

    final = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    final = Image.composite(canvas, final, outer_mask)
    return final


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, help="Destination PNG path")
    args = parser.parse_args()

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    draw_icon().save(output, format="PNG")
    print(output)


if __name__ == "__main__":
    main()

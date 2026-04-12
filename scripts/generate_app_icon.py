#!/usr/bin/env python3

"""Generate a macOS app icon inspired by the unMineable "u" mark.

The goal is not to ship the site favicon unchanged. Instead, this script builds
an original rounded-square application icon with a lowercase "u" silhouette and
a cooler blue/slate palette that fits the native macOS app icon style more
cleanly than the earlier mint-heavy version.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


SIZE = 1024
INDIGO = (115, 145, 255, 255)
INDIGO_BRIGHT = (210, 223, 255, 255)
INDIGO_DARK = (63, 90, 185, 255)
STEEL = (210, 221, 235, 255)
BG_TOP = (22, 27, 40, 255)
BG_BOTTOM = (8, 11, 18, 255)


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
    add_glow(canvas, glow_mask, (103, 132, 247, 90), blur=60, alpha_scale=0.55)

    ornament = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ornament_draw = ImageDraw.Draw(ornament)
    ornament_draw.ellipse((136, 140, 280, 284), fill=(255, 255, 255, 18))
    ornament_draw.ellipse((760, 730, 892, 862), fill=(255, 255, 255, 14))
    ornament_draw.rounded_rectangle((162, 694, 312, 728), radius=16, fill=(255, 255, 255, 10))
    canvas.alpha_composite(ornament)

    u_mask = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    u_draw = ImageDraw.Draw(u_mask)

    stroke = 112
    left_x = 348
    right_x = 668
    left_top_y = 352
    right_top_y = 246
    bottom_y = 728

    # Lowercase "u": shorter left stem, taller right stem, and a rounded bowl.
    u_draw.rounded_rectangle((left_x - stroke // 2, left_top_y, left_x + stroke // 2, bottom_y), radius=stroke // 2, fill=(255, 255, 255, 255))
    u_draw.rounded_rectangle((right_x - stroke // 2, right_top_y, right_x + stroke // 2, bottom_y), radius=stroke // 2, fill=(255, 255, 255, 255))
    u_draw.pieslice((left_x - stroke // 2, bottom_y - 254, right_x + stroke // 2, bottom_y + 106), start=0, end=180, fill=(255, 255, 255, 255))

    # Clear the upper bowl so the lower curve reads as a lowercase glyph.
    cutout = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cutout_draw = ImageDraw.Draw(cutout)
    cutout_draw.rounded_rectangle((left_x + 42, left_top_y + 28, right_x - 42, bottom_y - 12), radius=114, fill=(0, 0, 0, 255))
    u_mask = ImageChops.subtract(u_mask, cutout)

    # Add a subtle glossy terminal cap on the ascender to reinforce the
    # lowercase silhouette.
    terminal = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    terminal_draw = ImageDraw.Draw(terminal)
    terminal_draw.rounded_rectangle((right_x - stroke // 2 - 18, right_top_y - 12, right_x + stroke // 2 + 22, right_top_y + 54), radius=34, fill=(255, 255, 255, 255))
    u_mask = ImageChops.lighter(u_mask, terminal)

    add_glow(canvas, u_mask, INDIGO_BRIGHT, blur=28, alpha_scale=0.75)

    u_fill = Image.new("RGBA", (SIZE, SIZE), INDIGO)
    u_gradient = vertical_gradient(SIZE, INDIGO_BRIGHT, INDIGO_DARK)
    u_fill = Image.composite(u_gradient, u_fill, u_mask.getchannel("A"))
    canvas.alpha_composite(u_fill)

    inner_highlight = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    highlight_draw = ImageDraw.Draw(inner_highlight)
    highlight_draw.rounded_rectangle((left_x - stroke // 2 + 10, left_top_y + 8, left_x - stroke // 2 + 34, bottom_y - 54), radius=12, fill=(255, 255, 255, 38))
    highlight_draw.rounded_rectangle((right_x - stroke // 2 + 10, right_top_y + 8, right_x - stroke // 2 + 34, bottom_y - 46), radius=12, fill=(255, 255, 255, 26))
    canvas.alpha_composite(inner_highlight)

    # Add a restrained metallic accent so the icon does not collapse into a
    # flat monochrome blob at smaller macOS sizes.
    accent = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    accent_draw = ImageDraw.Draw(accent)
    accent_draw.rounded_rectangle((708, 198, 826, 246), radius=24, fill=STEEL)
    accent_draw.rounded_rectangle((772, 142, 816, 314), radius=22, fill=STEEL)
    accent = accent.rotate(14, center=(784, 228), resample=Image.Resampling.BICUBIC)
    canvas.alpha_composite(accent.filter(ImageFilter.GaussianBlur(8)))
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

#!/usr/bin/env python3
"""Draws the Learn Tcl app icon: Tcl's [ ] (command substitution) around a terminal prompt.

  python3 tools/make-icon.py        -> assets/icon/icon-foreground.png  (432x432, transparent, adaptive-icon layer)
                                       assets/icon/icon-512.png         (512x512, full icon for store listings)
Brand colours come from lib/theme.tcl: background #6B58EC (primary), prompt #34D8A0 (success).
"""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "icon")
BG, WHITE, MINT = (0x6B, 0x58, 0xEC, 255), "#FFFFFF", "#34D8A0"
N, S = 432, 4          # 108 dp at xxxhdpi; draw at 4x and downsample


def stroke(d, pts, w, col):
    pts = [(x * S, y * S) for x, y in pts]
    w *= S
    for a, b in zip(pts, pts[1:]):
        d.line([a, b], fill=col, width=int(w))
    for x, y in pts:
        d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=col)


def foreground():
    im = Image.new("RGBA", (N * S, N * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # everything stays inside the 66 dp circle Android guarantees to show
    stroke(d, [(158, 112), (116, 112), (116, 320), (158, 320)], 26, WHITE)   # [
    stroke(d, [(274, 112), (316, 112), (316, 320), (274, 320)], 26, WHITE)   # ]
    stroke(d, [(172, 176), (222, 216), (172, 256)], 24, MINT)                # >
    stroke(d, [(236, 262), (262, 262)], 24, MINT)                            # _
    return im.resize((N, N), Image.LANCZOS)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    fg = foreground()
    fg.save(os.path.join(OUT, "icon-foreground.png"))
    full = Image.new("RGBA", (N, N), BG)
    full.alpha_composite(fg)
    full.resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, "icon-512.png"))
    print("wrote", os.path.normpath(OUT))

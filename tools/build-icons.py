#!/usr/bin/env python3
"""Genereert de app-iconen: het boodschappentasje uit de tabbalk.

Kleuren volgen de app: accent #c67139 op zand #f5ead8.
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ZAND = (245, 234, 216, 255)
ACCENT = (198, 113, 57, 255)
LICHT = (249, 244, 237, 255)


def tasje(d, cx, cy, b, kleur, lijn):
    """Boodschappentas: trapezium met hengsel, plus drie streepjes."""
    h = b * 1.06
    x0, x1 = cx - b / 2, cx + b / 2
    y0, y1 = cy - h / 2 + b * 0.16, cy + h / 2
    d.rounded_rectangle([x0, y0, x1, y1], radius=b * 0.22, fill=kleur)
    # hengsel
    dikte = max(2, int(b * 0.085))
    d.arc([cx - b * 0.26, y0 - b * 0.30, cx + b * 0.26, y0 + b * 0.22],
          start=180, end=360, fill=kleur, width=dikte)
    # streepjes op de tas
    for i, breedte in enumerate((0.46, 0.46, 0.30)):
        y = y0 + b * (0.34 + i * 0.20)
        d.rounded_rectangle(
            [cx - b * breedte / 2, y - dikte / 2, cx - b * breedte / 2 + b * breedte, y + dikte / 2],
            radius=dikte / 2, fill=lijn)


def maak(pad, maat, rond, marge):
    img = Image.new("RGBA", (maat * 4, maat * 4), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    m, r = maat * 4, rond * 4
    if r:
        d.rounded_rectangle([0, 0, m, m], radius=r, fill=ZAND)
    else:
        d.rectangle([0, 0, m, m], fill=ZAND)
    tasje(d, m / 2, m / 2, m * marge, ACCENT, LICHT)
    img.resize((maat, maat), Image.LANCZOS).save(ROOT / pad)
    print(pad)


if __name__ == "__main__":
    maak("icon-180.png", 180, 40, 0.52)
    maak("icon-192.png", 192, 43, 0.52)
    maak("icon-512.png", 512, 115, 0.52)
    # maskable: inhoud binnen de veilige zone (80%), vlak vlak eromheen
    maak("icon-maskable-512.png", 512, 0, 0.40)

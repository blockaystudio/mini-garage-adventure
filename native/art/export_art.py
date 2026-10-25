#!/usr/bin/env python3
"""Optional development-only raster exports; never used by the native runtime.

Install in an isolated environment: pip install cairosvg==2.8.2 pillow==13.0.0
The feature source uses the installed DejaVu Sans font. No font is redistributed.
"""
from pathlib import Path
import cairosvg
from PIL import Image

ROOT = Path(__file__).resolve().parent
for source, name, width, height in (
    ('icon.svg', 'icon-1024.png', 1024, 1024),
    ('icon.svg', 'icon-512.png', 512, 512),
    ('feature.svg', 'feature-1024x500.png', 1024, 500),
):
    output = ROOT / name
    cairosvg.svg2png(url=str(ROOT / source), write_to=str(output), output_width=width, output_height=height)
    with Image.open(output) as image:
        image.convert('RGB').save(output)
    print(f'{name}: {width}x{height}, opaque RGB PNG')

#!/usr/bin/env python3
"""Create dependency-free browser prototypes. No package manager or network needed."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parent
GAMES={'garage': ('mini-garage-adventure', 'Mini Garage Adventure')}
def read(p):return (ROOT/p).read_text(encoding='utf-8')
(ROOT/'play').mkdir(parents=True, exist_ok=True)
for key,(slug,title) in GAMES.items():
    css=read('shared/style.css')+'\n'+read(f'games/{key}.css')
    js='\n'.join(read(p) for p in ['shared/core.js','shared/art.js','shared/ui.js',f'games/{key}.js'])
    html=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"><meta name="color-scheme" content="light dark"><meta name="referrer" content="no-referrer"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src data:; connect-src 'none'; base-uri 'none'; form-action 'none'"><title>{title} — Play Prototype 01</title><style>{css}</style></head><body>{read(f'games/{key}.body.html')}<noscript><p>This prototype needs JavaScript enabled.</p></noscript><script>{js}</script></body></html>'''
    (ROOT/'play'/f'{slug}.html').write_text(html,encoding='utf-8')
print('Built Mini Garage Adventure standalone prototype.')

(ROOT/"play/index.html").write_text((ROOT/"play/mini-garage-adventure.html").read_text(), encoding="utf-8")

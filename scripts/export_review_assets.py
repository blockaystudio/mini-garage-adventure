"""Re-export existing original vector artwork and capture real browser previews."""
from pathlib import Path
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from threading import Thread
import json
from PIL import Image
from playwright.sync_api import sync_playwright
ROOT = Path.cwd()
project = json.loads((ROOT / 'project.json').read_text())
key, slug = project['prototype_key'], project['slug']
settings = {
 'pet': ('Pocket Pet Village', '#F5D987', '#504067', 'Little pets. Big imagination.', 'Adopt → decorate → play → remember', 'KidsArt.pet("clover","excited")'),
 'garage': ('Mini Garage Adventure', '#73D3D9', '#21344C', 'Build it. Paint it. Drive it.', 'Build → drive → discover → rebuild', 'KidsArt.car()'),
 'lab': ('Wonder Lab Adventures', '#CCD4F3', '#394B78', 'Small experiments. Big ideas.', 'Explore → experiment → solve → discover', 'KidsArt.robot()')
}
name, bg, ink, headline, loop, expression = settings[key]
class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass
server = ThreadingHTTPServer(('127.0.0.1', 0), partial(QuietHandler, directory=str(ROOT / 'play')))
thread = Thread(target=server.serve_forever, daemon=True)
thread.start()
errors = []
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True, args=['--no-sandbox'])
        page = browser.new_page(viewport={'width': 1024, 'height': 1024})
        page.on('pageerror', lambda error: errors.append(str(error)))
        icon = (ROOT / 'art' / f'{slug}-icon-draft.svg').read_text()
        page.set_content('<style>html,body{margin:0;width:1024px;height:1024px}</style>' + icon)
        master = ROOT / 'art' / f'{slug}-icon-draft-1024.png'
        page.screenshot(path=str(master))
        with Image.open(master) as image:
            image.resize((512, 512), Image.Resampling.LANCZOS).save(ROOT / 'art' / f'{slug}-icon-draft-512.png')
        page.set_content('<script>' + (ROOT / 'shared/core.js').read_text() + '\n' + (ROOT / 'shared/art.js').read_text() + '</script>')
        art = page.evaluate(expression)
        page.set_viewport_size({'width': 1024, 'height': 500})
        feature = f'''<style>*{{box-sizing:border-box}}body{{margin:0;font-family:'Trebuchet MS',sans-serif;background:{bg};color:{ink};width:1024px;height:500px;padding:64px;overflow:hidden}}.art{{position:absolute;width:370px;height:370px;right:34px;top:69px}}.art svg{{width:100%;height:100%}}.eyebrow{{font-size:12px;letter-spacing:3px;font-weight:800}}h1{{font-size:54px;line-height:1.1;letter-spacing:-2px;width:570px;margin:27px 0 22px}}p{{font-size:20px;max-width:540px;line-height:1.5}}.draft{{position:absolute;bottom:26px;font-size:10px;letter-spacing:1px}}</style><div class="eyebrow">{name.upper()}</div><h1>{headline}</h1><p>{loop}</p><div class="art">{art}</div><div class="draft">INTERNAL ART DIRECTION · BUILD 01 PROTOTYPE · NOT A PUBLISHED APP</div>'''
        page.set_content(feature)
        page.screenshot(path=str(ROOT / 'art' / f'{slug}-feature-draft-1024x500.png'))
        page.close()
        for label, viewport, mobile in [('desktop', {'width': 1440, 'height': 1000}, False), ('mobile', {'width': 390, 'height': 844}, True)]:
            context = browser.new_context(viewport=viewport, is_mobile=mobile, has_touch=mobile, device_scale_factor=1, reduced_motion='reduce')
            game = context.new_page()
            game.on('pageerror', lambda error: errors.append(str(error)))
            game.goto(f'http://127.0.0.1:{server.server_port}/index.html', wait_until='networkidle')
            game.locator('body').wait_for(state='visible')
            if name not in game.title():
                raise RuntimeError('Wrong game preview')
            game.screenshot(path=str(ROOT / 'evidence' / f'{key}-{label}.png'), full_page=True)
            context.close()
        browser.close()
    if errors:
        raise RuntimeError('Browser errors: ' + '; '.join(errors))
    print('Regenerated three PNG artwork exports and two actual browser screenshots from original source.')
finally:
    server.shutdown()
    server.server_close()

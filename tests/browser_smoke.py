#!/usr/bin/env python3
"""Chromium regression against real HTTP-origin storage; no fixture storage.

Run after `python build.py`: python tests/browser_smoke.py
Install tests/requirements-browser.txt and `python -m playwright install chromium`,
or set GARAGE_CHROMIUM to an installed executable. Synthetic cancellation and
focus events are explicitly named; these checks do not certify mobile devices.
"""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import json
import os
import shutil
import sys
from threading import Thread
import time
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
KEY = 'kidslab.v1.mini-garage-adventure'
RESULT = ROOT / 'evidence/reference-browser-results.json'

class Quiet(SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def main():
    server = ThreadingHTTPServer(('127.0.0.1', 0), partial(Quiet, directory=str(ROOT / 'play')))
    Thread(target=server.serve_forever, daemon=True).start()
    origin = f'http://127.0.0.1:{server.server_port}'
    checks, errors, outbound = [], [], []
    def check(name, operation):
        try:
            operation()
            checks.append({'name': name, 'passed': True})
        except Exception as exc:
            checks.append({'name': name, 'passed': False, 'error': str(exc)})
    def require(condition, message):
        assert condition, message
    try:
        with sync_playwright() as pw:
            executable = os.environ.get('GARAGE_CHROMIUM') or shutil.which('chromium')
            browser = pw.chromium.launch(executable_path=executable, args=['--no-sandbox'])
            context = browser.new_context(viewport={'width': 1366, 'height': 1000}, has_touch=True)
            page = context.new_page()
            page.on('pageerror', lambda error: errors.append(str(error)))
            page.on('request', lambda request: outbound.append(request.url) if not request.url.startswith(origin + '/') else None)
            page.goto(origin, wait_until='networkidle')
            page.evaluate("""() => {const original=KidsCore.stepCar;KidsCore.stepCar=(...args)=>{window.__input={throttle:args[2],brake:args[3],car:args[0]};return original(...args);};}""")
            check('first launch renders actual game', lambda: require(page.locator('#drive').is_visible(), 'Drive unavailable'))
            def persistence():
                page.locator('[data-tires="giant"]').click()
                page.locator('[data-suspension="firm"]').click()
                page.locator('[data-paint="purple"]').click()
                page.locator('#edit-track').click()
                page.locator('[data-slot="1"]').click()
                page.locator('#save-track').click()
                before = page.evaluate('(key)=>JSON.parse(localStorage.getItem(key)).data', KEY)
                page.reload(wait_until='networkidle')
                after = page.evaluate('(key)=>JSON.parse(localStorage.getItem(key)).data', KEY)
                require(after['tires'] == 'giant' and after['suspension'] == 'firm' and after['paint'] == 'purple', 'Build did not persist')
                require(after['custom'] == before['custom'] and after['track'] == 'custom', 'Track did not persist')
            check('build and edited track survive actual HTTP reload', persistence)
            page.evaluate("""() => {const original=KidsCore.stepCar;KidsCore.stepCar=(...args)=>{window.__input={throttle:args[2],brake:args[3],car:args[0]};return original(...args);};}""")
            def combined_input():
                page.keyboard.down('ArrowRight')
                page.locator('#drive').hover()
                page.mouse.down()
                page.mouse.up()
                page.wait_for_timeout(100)
                require(page.evaluate('window.__input.throttle'), 'Releasing a pointer cancelled a still-held keyboard control')
            check('keyboard and pointer sources release independently', combined_input)
            page.keyboard.up('ArrowRight')
            def multi_touch():
                page.locator('#restart').click()
                box = page.locator('#drive').bounding_box()
                points = [{'id': i, 'x': box['x'] + 40 + i * 15, 'y': box['y'] + box['height'] / 2} for i in (1, 2)]
                cdp = context.new_cdp_session(page)
                cdp.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': [points[0]]})
                cdp.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': points})
                cdp.send('Input.dispatchTouchEvent', {'type': 'touchEnd', 'touchPoints': [points[1]]})
                page.wait_for_timeout(100)
                active = page.evaluate('window.__input.throttle')
                cdp.send('Input.dispatchTouchEvent', {'type': 'touchEnd', 'touchPoints': []})
                page.wait_for_timeout(100)
                require(active, 'Releasing one touch cancelled another held touch')
                require(not page.evaluate('window.__input.throttle'), 'Throttle remained after all touches ended')
            check('two actual CDP touches release independently', multi_touch)
            def blur():
                page.locator('#drive').hover()
                page.mouse.down()
                page.evaluate("window.dispatchEvent(new Event('blur'))")
                page.wait_for_timeout(100)
                page.mouse.up()
                require(not page.evaluate('window.__input.throttle'), 'Synthetic blur left throttle held')
                require('pressed' not in page.locator('#drive').get_attribute('class'), 'Blur left a misleading pressed control')
            check('synthetic focus loss clears input and pressed state', blur)
            def cancellation():
                page.locator('#drive').hover()
                page.mouse.down()
                page.locator('#drive').dispatch_event('pointercancel', {'pointerId': 1})
                page.wait_for_timeout(100)
                require(not page.evaluate('window.__input.throttle'), 'Synthetic cancellation left throttle held')
                page.mouse.up()
            check('synthetic pointer cancellation clears throttle', cancellation)
            def restart():
                page.keyboard.down('ArrowRight')
                page.wait_for_timeout(120)
                for _ in range(8):
                    page.locator('#restart').click()
                page.wait_for_timeout(100)
                require(not page.evaluate('window.__input.throttle'), 'Rapid restart left throttle held')
                page.keyboard.up('ArrowRight')
            check('rapid restart clears active input', restart)
            def complete():
                page.locator('[data-tires="trail"]').click()
                page.locator('[data-track="meadow"]').click()
                page.keyboard.down('ArrowRight')
                page.locator('#race-result').wait_for(state='visible', timeout=30000)
                page.keyboard.up('ArrowRight')
                count = int(page.locator('#finished-count').inner_text())
                require(count >= 1, 'Finish did not update progress')
                page.locator('#restart').click()
                require(not page.locator('#race-result').is_visible(), 'Restart left finish visible')
                page.reload(wait_until='networkidle')
                require(int(page.locator('#finished-count').inner_text()) == count, 'Completion lost on reload')
            check('actual keyboard driving finishes and persists progress', complete)
            def corrupt_recovery():
                data = page.evaluate('(key)=>JSON.parse(localStorage.getItem(key)).data', KEY)
                page.evaluate('(key)=>localStorage.setItem(key,"{broken")', KEY)
                page.reload(wait_until='networkidle')
                restored = page.evaluate('(key)=>JSON.parse(localStorage.getItem(key)).data', KEY)
                require(restored['tires'] == data['tires'], 'Backup build not recovered')
                require('Recovered' in page.locator('#save-status').inner_text(), 'Recovery warning missing')
            check('corrupt primary recovers real-origin backup', corrupt_recovery)
            def invalid_parts():
                page.evaluate('''(key)=>{const s=JSON.parse(localStorage.getItem(key));s.data.tires='bad';s.data.suspension='bad';s.data.custom=['bad'];localStorage.setItem(key,JSON.stringify(s));}''', KEY)
                page.reload(wait_until='networkidle')
                state = page.evaluate('(key)=>JSON.parse(localStorage.getItem(key)).data', KEY)
                require(state['tires'] == 'trail' and state['suspension'] == 'soft' and len(state['custom']) == 4, 'Invalid saved parts did not normalize')
            check('invalid persisted parts safely normalize', invalid_parts)
            def layouts():
                for width, height in [(390, 844), (844, 390), (768, 1024), (1024, 768)]:
                    page.set_viewport_size({'width': width, 'height': height})
                    require(page.evaluate('document.documentElement.scrollWidth<=innerWidth'), f'Horizontal overflow at {width}x{height}')
                page.set_viewport_size({'width': 1366, 'height': 1000})
            check('phone and tablet portrait and landscape avoid overflow', layouts)
            page.screenshot(path=str(ROOT / 'evidence/reference-browser-desktop.png'), full_page=True)
            def storage_failure():
                fresh = browser.new_context()
                fresh.add_init_script("Storage.prototype.setItem=function(){throw new DOMException('Test quota exhausted','QuotaExceededError')}")
                failure_page = fresh.new_page()
                failure_page.on('pageerror', lambda error: errors.append(str(error)))
                failure_page.goto(origin, wait_until='networkidle')
                failure_page.locator('[data-tires="giant"]').click()
                require('cannot save' in failure_page.locator('#save-status').inner_text(), 'Storage warning missing')
                require(failure_page.locator('#drive').is_enabled(), 'Failed storage blocked gameplay')
                fresh.close()
            check('injected quota failure warns while game stays usable', storage_failure)
            check('no browser script errors', lambda: require(not errors, str(errors)))
            check('no unexpected outbound requests', lambda: require(not outbound, str(outbound)))
            version = browser.version
            browser.close()
    finally:
        server.shutdown()
        server.server_close()
    report = {'date': time.strftime('%Y-%m-%d', time.gmtime()), 'browser': f'Chromium {version}', 'environment': 'Linux headless desktop browser; real HTTP origin; no physical devices', 'storage': 'Real Chromium localStorage; isolated context, separate injected quota context', 'checks': checks, 'passed': sum(c['passed'] for c in checks), 'failed': sum(not c['passed'] for c in checks), 'errors': errors, 'outbound': outbound}
    RESULT.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    return 1 if report['failed'] else 0

if __name__ == '__main__':
    sys.exit(main())

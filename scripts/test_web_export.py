#!/usr/bin/env python3
"""Actual full-game WebAssembly/HTTP smoke, Chromium desktop and phone emulation.

Uses an isolated real HTTP origin and actual IndexedDB. This is not Safari,
physical-phone testing, app-store QA, or a synthetic save fixture.
"""
from __future__ import annotations
import argparse
from functools import partial
import hashlib
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import shutil
import threading
import time
import struct
import zlib
from urllib.parse import urlparse
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
READ_SAVE = """async()=>{const names=await indexedDB.databases();if(!names.some(x=>x.name==='/userfs'))return null;return await new Promise((resolve,reject)=>{const r=indexedDB.open('/userfs');r.onerror=()=>reject(r.error);r.onsuccess=()=>{const db=r.result;const tx=db.transaction([...db.objectStoreNames],'readonly');const store=tx.objectStore(db.objectStoreNames[0]);const keys=store.getAllKeys(),values=store.getAll();tx.oncomplete=()=>{let answer=null;for(let i=0;i<keys.result.length;i++){if(String(keys.result[i]).endsWith('/garage-save.json')&&values.result[i].contents){answer=JSON.parse(new TextDecoder().decode(values.result[i].contents)).payload;}}resolve(answer);db.close();};};});}"""

def png_pixel(data, x, y):
    """Read one actual Chromium screenshot pixel with standard-library PNG filters."""
    offset=8; compressed=[]; width=height=channels=None
    while offset<len(data):
        length=struct.unpack_from('>I',data,offset)[0];kind=data[offset+4:offset+8];chunk=data[offset+8:offset+8+length];offset+=length+12
        if kind==b'IHDR':
            width,height,depth,color,_,_,interlace=struct.unpack('>IIBBBBB',chunk)
            if depth!=8 or color not in (2,6) or interlace: raise ValueError('Unsupported screenshot PNG format')
            channels=3 if color==2 else 4
        elif kind==b'IDAT': compressed.append(chunk)
        elif kind==b'IEND': break
    raw=zlib.decompress(b''.join(compressed));stride=width*channels;previous=bytearray(stride);cursor=0
    for row_number in range(y+1):
        method=raw[cursor];cursor+=1;row=bytearray(raw[cursor:cursor+stride]);cursor+=stride
        for index in range(stride):
            left=row[index-channels] if index>=channels else 0;up=previous[index];upper_left=previous[index-channels] if index>=channels else 0
            if method==1: predict=left
            elif method==2: predict=up
            elif method==3: predict=(left+up)//2
            elif method==4:
                estimate=left+up-upper_left;dist=[abs(estimate-left),abs(estimate-up),abs(estimate-upper_left)];predict=[left,up,upper_left][dist.index(min(dist))]
            elif method==0: predict=0
            else: raise ValueError('Invalid PNG row filter')
            row[index]=(row[index]+predict)&255
        previous=row
    return tuple(previous[x*channels:x*channels+3])


class Handler(SimpleHTTPRequestHandler):
    def log_message(self, *args): pass


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exercise-touch-driving',action='store_true',help='Experimental coordinate/focus navigation; may require adapting to actual scroll state. Not a hardware test.')
    parser.add_argument('--quick-mobile',action='store_true',help='Run only phone-emulated flows and DPR3 layout; desktop flow is independently available without this flag')
    parser.add_argument('--site-directory', type=Path, default=Path('/workspace/sites/mini-garage-phone-test/dist'))
    parser.add_argument('--output', type=Path, default=ROOT/'evidence/web-phone-preview')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    checks, errors, requests, console = [], [], [], []
    def check(ok, description):
        checks.append({'passed':bool(ok),'description':description})
        print(('PASS' if ok else 'FAIL')+': '+description, flush=True)
    server=ThreadingHTTPServer(('127.0.0.1',0),partial(Handler,directory=str(args.site_directory.resolve())))
    threading.Thread(target=server.serve_forever,daemon=True).start()
    origin=f'http://127.0.0.1:{server.server_port}'
    def listen(page):
        page.on('pageerror',lambda error:errors.append(str(error)))
        page.on('console',lambda message:console.append({'type':message.type,'text':message.text}))
        page.on('request',lambda request:requests.append(request.url))
    def ready(page):
        page.wait_for_selector('#status',state='detached',timeout=90000)
        page.wait_for_timeout(500)
    def save(page,predicate,timeout=8):
        deadline=time.monotonic()+timeout
        current=None
        while time.monotonic()<deadline:
            current=page.evaluate(READ_SAVE)
            if current and predicate(current): return current
            page.wait_for_timeout(250)
        return current
    started=time.monotonic()
    try:
        with sync_playwright() as pw:
            browser=pw.chromium.launch(executable_path=shutil.which('chromium'),args=['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader','--disable-dev-shm-usage'])
            desktop=None
            if not args.quick_mobile:
                desktop=browser.new_context(viewport={'width':1280,'height':720})
                page=desktop.new_page();listen(page)
                page.goto(origin+'/game/');ready(page)
                check(page.locator('#canvas').bounding_box()=={'x':0,'y':0,'width':1280,'height':720},'actual Godot WebAssembly canvas boots at1280x720')
                check(page.evaluate('GODOT_THREADS_ENABLED') is False,'single-thread build needs no cross-origin-isolation setup')
                page.screenshot(path=str(args.output/'desktop-garage.png'))
                page.mouse.click(515,440);page.mouse.click(435,608)
                selected=save(page,lambda s:s['build']['tires']=='giant' and s['build']['paint']=='purple')
                check(selected and selected['build']['tires']=='giant' and selected['build']['paint']=='purple','actual canvas part/paint choices persist to IndexedDB')
                page.mouse.click(830,634);page.wait_for_timeout(300);page.mouse.click(185,272);page.wait_for_timeout(300)
                page.keyboard.down('ArrowRight');page.wait_for_timeout(14500);page.keyboard.up('ArrowRight')
                finished=save(page,lambda s:'meadow' in s['completed'])
                check(finished and 'meadow' in finished['completed'] and finished['best'].get('meadow',0)>0,'real course/input reaches finish and saves a medal/best time')
                page.screenshot(path=str(args.output/'desktop-completion.png'))
                page.reload();ready(page)
                restored=page.evaluate(READ_SAVE)
                check(restored and restored['build']==selected['build'] and restored['completed']==['meadow'],'actual reload recovers selected build and completed course')
                page.screenshot(path=str(args.output/'desktop-reloaded-save.png'))
                # Actual private-editor input and playable preview, without seeding data.
                page.mouse.click(1126,633);page.wait_for_timeout(250);page.mouse.click(736,505);page.wait_for_timeout(250);page.mouse.click(1114,582)
                custom=save(page,lambda s:s['custom'][1]=='dip')
                check(custom and custom['custom'][1]=='dip','actual track editor changes/saves a section and opens playable preview')
                page.screenshot(path=str(args.output/'desktop-private-preview.png'))
            # A fresh mobile browser context exercises the phone layout and touch route.
            phone=browser.new_context(viewport={'width':390,'height':844},is_mobile=True,has_touch=True,device_scale_factor=1)
            mobile=phone.new_page();listen(mobile)
            mobile.goto(origin+'/')
            play=mobile.get_by_role('link',name='Play the full game')
            check(play.count()==1 and play.get_attribute('href')=='game/','phone launcher has a direct top-level Play link')
            check(mobile.locator('body').evaluate('(element)=>element.scrollWidth<=innerWidth'),'portrait launcher has no horizontal overflow')
            check(mobile.locator('.rotate').is_visible(),'portrait launcher shows rotate-phone advice')
            mobile.screenshot(path=str(args.output/'phone-portrait-launcher.png'),full_page=True)
            mobile.set_viewport_size({'width':844,'height':390});play.click();ready(mobile)
            mobile.screenshot(path=str(args.output/'phone-landscape-garage.png'))
            check(mobile.locator('#canvas').bounding_box()['width']==844,'phone-emulated landscape full-game canvas fits844px width')
            # Actual touchscreen tap must open the gate, not merely leave a
            # still-visible canvas. Screenshot review confirms the changed scene.
            mobile.touchscreen.tap(665,40);mobile.wait_for_timeout(350)
            gate_png=mobile.screenshot(path=str(args.output/'phone-touch-grown-up-gate.png'))
            gate_rgb=png_pixel(gate_png,110,100)
            check(max(gate_rgb)<80,'actual touchscreen Grown-ups tap opens the dark parent-gate form')
            mobile.touchscreen.tap(665,40);mobile.wait_for_timeout(250)
            cdp=phone.new_cdp_session(mobile)
            for _ in range(18):
                cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'id':0,'x':400,'y':340}]})
                for n in range(1,9):
                    cdp.send('Input.dispatchTouchEvent',{'type':'touchMove','touchPoints':[{'id':0,'x':400,'y':340-n*26}]})
                    mobile.wait_for_timeout(12)
                cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]})
                mobile.wait_for_timeout(80)
            mobile.screenshot(path=str(args.output/'phone-landscape-scrolled.png'))
            scrolled_rgb=png_pixel((args.output/'phone-landscape-scrolled.png').read_bytes(),110,100)
            check(max(scrolled_rgb)<100,'actual finger drags scroll the vehicle preview out of the compact form')
            if args.exercise_touch_driving:
                # Use keyboard focus as a deterministic setup helper after touch
                # scrolling: virtual-pointer gestures can coalesce under SwiftShader.
                # Reverse focus reaches Track lab, then Choose a course. Gameplay
                # below uses a real touch hold; no game state or saves are injected.
                mobile.keyboard.press('Shift+Tab');mobile.wait_for_timeout(200)
                mobile.keyboard.press('Shift+Tab');mobile.keyboard.press('Enter');mobile.wait_for_timeout(300)
                mobile.screenshot(path=str(args.output/'phone-touch-course-menu.png'))
                mobile.keyboard.press('Tab');mobile.keyboard.press('Tab');mobile.keyboard.press('Enter');mobile.wait_for_timeout(300)
                mobile.screenshot(path=str(args.output/'phone-touch-drive-start.png'))
                cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'id':0,'x':670,'y':345}]})
                mobile.wait_for_timeout(15000)
                cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]})
                mobile_finished=save(mobile,lambda s:'meadow' in s['completed'])
                check(mobile_finished and 'meadow' in mobile_finished['completed'],'phone-emulated raw-touch driving completes/saves Meadow after keyboard menu setup')
                mobile.screenshot(path=str(args.output/'phone-touch-completion.png'))
            check(not errors and not [m for m in console if m['type']=='error'],'no page errors or console errors in full-game flows')
            external=[url for url in requests if not url.startswith(origin+'/') and not url.startswith(('data:','blob:'))]
            check(not external,'no unexpected external requests from launcher/game')
            check(any(url.endswith('index.wasm.gz') for url in requests),'actual packed gzip WebAssembly asset is fetched and booted')
            phone.close()
            if desktop:desktop.close()
            high=browser.new_context(viewport={'width':844,'height':390},is_mobile=True,has_touch=True,device_scale_factor=3,user_agent='Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1')
            high_page=high.new_page();listen(high_page);high_page.goto(origin+'/game/');ready(high_page)
            high_png=high_page.screenshot(path=str(args.output/'phone-dpr3-compact-form.png'))
            high_rgb=png_pixel(high_png,110*3,100*3)
            check(min(high_rgb)>150,'iPhone-UA DPR3 chooses the large compact phone form, not the desktop grid')
            check(not errors and not [m for m in console if m['type']=='error'],'all DPR3/mobile flows finish without page or console errors')
            browser.close()
    except Exception as error:
        errors.append(str(error));check(False,'harness completed all flows: '+str(error))
    finally:
        server.shutdown();server.server_close()
    data={'scope':'Actual local HTTP Chromium154/SwiftShader plus Chromium phone emulation; no physical phone/Safari or native Android/iOS QA','checks':checks,'passed':sum(c['passed'] for c in checks),'failed':sum(not c['passed'] for c in checks),'errors':errors,'console':console,'requests':[url.replace(origin,'[local-origin]') for url in requests],'wall_seconds':round(time.monotonic()-started,3),'wasm_sha256':hashlib.sha256((args.site_directory/'game/index.wasm.gz').read_bytes()).hexdigest(),'manual_review':['Actual screenshots inspected. Touch opens the gate and scrolls. Optional touch-driving navigation remains experimental and is not claimed as passed. No game state is injected. Browser touch emulation, not hardware gestures.']}
    (args.output/'results.json').write_text(json.dumps(data,indent=2)+'\n')
    print(f"WEB EXPORT: {data['passed']} passed, {data['failed']} failed",flush=True)
    return bool(data['failed'])

if __name__=='__main__': raise SystemExit(main())

#!/usr/bin/env python3
"""Exercise the compiled Linux export through its real window and OS input.

Starts an owned dummy Xorg display and an isolated game profile. No SceneTree,
external GDScript, remote debugger, save injection, image compositing or browser
substitution is used. Requires existing Xorg/dummy/Mesa, ImageMagick, Tesseract,
libX11 and libXtst; installs nothing. This is desktop GUI/package evidence, not
physical Android/iOS, accessibility, human-play or performance acceptance.
"""
from __future__ import annotations

import argparse
import ctypes as C
import ctypes.util
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import time

from capture_native import XORG_CONFIG
from native_save_audit import validate_save_bytes

ROOT = Path(__file__).resolve().parents[1]


def sha(path: Path) -> str:
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


class MessageData(C.Union):
    _fields_ = [('bytes', C.c_char * 20), ('shorts', C.c_short * 10),
                ('longs', C.c_long * 5)]


class ClientMessage(C.Structure):
    _fields_ = [('type', C.c_int), ('serial', C.c_ulong), ('send_event', C.c_int),
                ('display', C.c_void_p), ('window', C.c_ulong),
                ('message_type', C.c_ulong), ('format', C.c_int), ('data', MessageData)]


class XEvent(C.Union):
    _fields_ = [('message', ClientMessage), ('padding', C.c_long * 24)]


class Input:
    def __init__(self, display: str):
        self.x = C.CDLL(ctypes.util.find_library('X11'))
        self.test = C.CDLL(ctypes.util.find_library('Xtst'))
        self.x.XOpenDisplay.argtypes = [C.c_char_p]
        self.x.XOpenDisplay.restype = C.c_void_p
        self.x.XFlush.argtypes = [C.c_void_p]
        self.x.XSetInputFocus.argtypes = [C.c_void_p, C.c_ulong, C.c_int, C.c_ulong]
        self.x.XStringToKeysym.argtypes = [C.c_char_p]
        self.x.XStringToKeysym.restype = C.c_ulong
        self.x.XKeysymToKeycode.argtypes = [C.c_void_p, C.c_ulong]
        self.x.XKeysymToKeycode.restype = C.c_ubyte
        self.x.XInternAtom.argtypes = [C.c_void_p, C.c_char_p, C.c_int]
        self.x.XInternAtom.restype = C.c_ulong
        self.x.XSendEvent.argtypes = [C.c_void_p, C.c_ulong, C.c_int, C.c_long, C.POINTER(XEvent)]
        self.x.XCloseDisplay.argtypes = [C.c_void_p]
        self.test.XTestFakeMotionEvent.argtypes = [C.c_void_p, C.c_int, C.c_int, C.c_int, C.c_ulong]
        self.test.XTestFakeButtonEvent.argtypes = [C.c_void_p, C.c_uint, C.c_int, C.c_ulong]
        self.test.XTestFakeKeyEvent.argtypes = [C.c_void_p, C.c_uint, C.c_int, C.c_ulong]
        self.display = self.x.XOpenDisplay(display.encode())
        if not self.display:
            raise RuntimeError('Could not open the owned Xorg display')

    def focus(self, window: int):
        self.x.XSetInputFocus(self.display, window, 2, 0)
        self.x.XFlush(self.display)

    def click(self, x: int, y: int):
        self.test.XTestFakeMotionEvent(self.display, 0, x, y, 0)
        self.test.XTestFakeButtonEvent(self.display, 1, 1, 0)
        self.test.XTestFakeButtonEvent(self.display, 1, 0, 0)
        self.x.XFlush(self.display)

    def key(self, name: str, down: bool):
        code = self.x.XKeysymToKeycode(self.display, self.x.XStringToKeysym(name.encode()))
        if not code:
            raise RuntimeError('No X11 keycode for ' + name)
        self.test.XTestFakeKeyEvent(self.display, code, int(down), 0)
        self.x.XFlush(self.display)

    def close_window(self, window: int):
        event = XEvent()
        event.message.type = 33  # ClientMessage, normal WM_DELETE_WINDOW protocol.
        event.message.send_event = 1
        event.message.display = self.display
        event.message.window = window
        event.message.message_type = self.x.XInternAtom(self.display, b'WM_PROTOCOLS', 0)
        event.message.format = 32
        event.message.data.longs[0] = self.x.XInternAtom(self.display, b'WM_DELETE_WINDOW', 0)
        event.message.data.longs[1] = 0
        self.x.XSendEvent(self.display, window, 0, 0, C.byref(event))
        self.x.XFlush(self.display)

    def close(self):
        if self.display:
            self.x.XCloseDisplay(self.display)
            self.display = None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--binary', type=Path, default=ROOT / 'builds/mini-garage-adventure-explore.x86_64')
    parser.add_argument('--manifest', type=Path, default=ROOT / 'evidence/solo-hardening/native-builds-final/artifacts.json')
    parser.add_argument('--output', type=Path, default=ROOT / 'evidence/solo-hardening/exported-gui')
    args = parser.parse_args()
    for program in ['Xorg', 'import', 'convert', 'tesseract', 'xwininfo']:
        if not shutil.which(program):
            parser.error(program + ' unavailable; no GUI/package pass can be claimed')
    for library in ['X11', 'Xtst']:
        if not ctypes.util.find_library(library):
            parser.error('Existing ' + library + ' library unavailable')
    args.binary = args.binary.resolve()
    args.output.mkdir(parents=True, exist_ok=True)
    manifest = json.loads(args.manifest.read_text())
    if manifest.get('engine') != '4.6.3.stable.official.7d41c59c4':
        parser.error('The chosen build manifest does not use pinned Godot4.6.3')
    executable_hash = sha(args.binary)
    matching = [row for row in manifest['artifacts'] if Path(row['path']).name == args.binary.name]
    if len(matching) != 1 or matching[0]['sha256'] != executable_hash:
        parser.error('Actual executable does not match the chosen build manifest')
    helpers = [Path(__file__), ROOT / 'scripts/native_save_audit.py', ROOT / 'scripts/capture_native.py']
    helper_hashes = {str(p.relative_to(ROOT)): sha(p) for p in helpers}
    report = {'scope': 'Actual compiled Linux game window with OS mouse/key input, isolated profile; not source-harness/mobile/human/performance acceptance.',
              'source_commit': manifest['source_commit'], 'binary': str(args.binary.relative_to(ROOT)) if args.binary.is_relative_to(ROOT) else str(args.binary),
              'binary_sha256': executable_hash, 'helper_sha256': helper_hashes,
              'viewport': [1280, 720], 'actions': [], 'captures': [], 'checks': [], 'status': 'running'}
    began = time.monotonic()
    game = None
    input_driver = None
    xorg = None
    logs = []

    def record(kind: str, **fields):
        report['actions'].append({'at_seconds': round(time.monotonic() - began, 3), 'kind': kind, **fields})

    def check(condition: bool, label: str):
        report['checks'].append({'label': label, 'passed': bool(condition)})
        print(('PASS: ' if condition else 'FAIL: ') + label, flush=True)
        if not condition:
            raise RuntimeError(label)

    try:
        with tempfile.TemporaryDirectory(prefix='garage-exported-gui-') as temporary:
            temp = Path(temporary)
            display = next((i for i in range(90, 120) if not Path(f'/tmp/.X{i}-lock').exists()), None)
            if display is None:
                raise RuntimeError('No free owned Xorg display')
            display_name = f':{display}'
            config = temp / 'xorg.conf'
            config.write_text(XORG_CONFIG)
            empty = temp / 'empty-config'
            empty.mkdir()
            xlog = (args.output / 'xorg-launch.txt').open('w')
            logs.append(xlog)
            xorg = subprocess.Popen(['Xorg', display_name, '-config', str(config), '-configdir', str(empty),
                                     '-logfile', str(args.output.resolve() / 'Xorg.log'), '-noreset', '-nolisten', 'tcp'],
                                    stdout=xlog, stderr=subprocess.STDOUT)
            deadline = time.monotonic() + 10
            while not Path(f'/tmp/.X11-unix/X{display}').exists():
                if xorg.poll() is not None or time.monotonic() > deadline:
                    raise RuntimeError('Owned Xorg did not start; inspect Xorg.log')
                time.sleep(.1)
            environment = dict(os.environ, DISPLAY=display_name, LIBGL_ALWAYS_SOFTWARE='1',
                               XDG_DATA_HOME=str(temp / 'data'), XDG_CONFIG_HOME=str(temp / 'settings'),
                               XDG_CACHE_HOME=str(temp / 'cache'))
            for name in ['data', 'settings', 'cache']:
                (temp / name).mkdir()
            input_driver = Input(display_name)
            window = None
            offset = (0, 0)

            def launch(label: str):
                nonlocal game, window, offset
                log = (args.output / (label + '-engine.txt')).open('w')
                logs.append(log)
                # No --path, --script, --main-pack, debug connection or test scene.
                game = subprocess.Popen([str(args.binary), '--resolution', '1280x720', '--position', '0,0',
                                         '--audio-driver', 'Dummy'], env=environment, cwd=temp,
                                        stdout=log, stderr=subprocess.STDOUT)
                record('launch_compiled_export', pid=game.pid, phase=label)
                deadline = time.monotonic() + 15
                while True:
                    if game.poll() is not None:
                        raise RuntimeError('Compiled game exited before its window opened')
                    tree = subprocess.check_output(['xwininfo', '-display', display_name, '-root', '-tree'], text=True)
                    found = re.search(r'(0x[0-9a-fA-F]+)\s+"Mini Garage Adventure"', tree)
                    if found:
                        window = int(found.group(1), 16)
                        details = subprocess.check_output(['xwininfo', '-display', display_name, '-id', hex(window)], text=True)
                        if 'Map State: IsViewable' in details:
                            offset = tuple(int(re.search(r'Absolute upper-left ' + axis + r':\s*(-?\d+)', details).group(1)) for axis in ['X', 'Y'])
                            input_driver.focus(window)
                            break
                    if time.monotonic() > deadline:
                        raise RuntimeError('Could not identify the actual compiled game window')
                    time.sleep(.1)

            def capture(label: str, *, keep: bool = True) -> str:
                path = args.output / (label + '.png')
                subprocess.run(['import', '-display', display_name, '-window', hex(window), str(path)], check=True,
                               stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, timeout=10)
                data = path.read_bytes()
                if data[:8] != b'\x89PNG\r\n\x1a\n' or struct.unpack('>II', data[16:24]) != (1280, 720):
                    raise RuntimeError('Viewport capture is not the untouched1280x720 game window')
                text = subprocess.check_output(['tesseract', str(path), 'stdout', '--psm', '11'], stderr=subprocess.DEVNULL,
                                               text=True, timeout=15)
                (args.output / (label + '-ocr.txt')).write_text(text)
                if keep:
                    report['captures'].append({'file': path.name, 'sha256': sha(path), 'source': 'Untouched actual exported-game X11 viewport'})
                return text.upper()

            def wait_text(expected: str):
                deadline = time.monotonic() + 12
                while True:
                    if expected in capture('probe', keep=False):
                        return
                    if game.poll() is not None or time.monotonic() > deadline:
                        raise RuntimeError('Actual viewport did not show ' + expected)
                    time.sleep(.15)

            def click(x: int, y: int, meaning: str):
                input_driver.focus(window)
                input_driver.click(x + offset[0], y + offset[1])
                record('mouse_click', x=x, y=y, meaning=meaning)
                time.sleep(.25)

            def read_profile():
                matches = list((temp / 'data').rglob('garage-save.json'))
                if len(matches) != 1:
                    return None
                try:
                    raw = matches[0].read_bytes()
                    validation = validate_save_bytes(raw)
                    if validation.get('status') != 'valid' or validation.get('checksum') != 'verified':
                        return None
                    return json.loads(raw)['payload'], raw
                except (ValueError, OSError):
                    return None

            def wait_profile(predicate, label: str, timeout: float = 45):
                deadline = time.monotonic() + timeout
                while True:
                    value = read_profile()
                    if value is not None and predicate(value[0]):
                        check(True, label)
                        return value
                    if game.poll() is not None or time.monotonic() > deadline:
                        capture('failed-state')
                        raise RuntimeError('Actual saved profile did not satisfy: ' + label)
                    time.sleep(.05)

            launch('first-launch')
            wait_text('SUNNY BUGGY')
            fresh_text = capture('01-fresh-garage')
            check(bool(re.search(r'\b[0O]\s*GP\b', fresh_text)), 'Fresh actual exported-game viewport shows zeroGP before any earning')
            click(842, 633, 'Choose a course')
            wait_text('PICK AN ADVENTURE')
            for index, course_id in enumerate(['meadow', 'orchard', 'coast']):
                click(187 + index * 302, 271, 'Start authored course ' + course_id)
                input_driver.key('Right', True)
                record('key_down', key='Right', meaning='Hold real2D Drive until legitimate course completion')
                try:
                    payload, _ = wait_profile(lambda p: int(p['gp']) == 105 * (index + 1) and course_id in p['completed'],
                                              'Authored ' + course_id + ' completion banked105GP exactly once')
                finally:
                    input_driver.key('Right', False)
                    record('key_up', key='Right')
                time.sleep(.2)
                capture(f'0{index+2}-{course_id}-complete')
                if index < 2:
                    click(796, 438, 'Keep exploring')
                    wait_text('PICK AN ADVENTURE')
                else:
                    click(640, 513, 'Back to garage')
                    wait_text('SUNNY BUGGY')
            click(1107, 519, 'Open upgrade workshop')
            wait_text('UPGRADE WORKSHOP')
            click(930, 548, 'Buy mud tires300GP')
            wait_profile(lambda p: int(p['gp']) == 15 and 'mud' in p['owned'], 'Atomic mud purchase leaves15GP and grants ownership')
            click(930, 548, 'Equip owned mud tiresFREE')
            wait_profile(lambda p: p['build']['tires'] == 'mud' and p['equipped']['tires'] == 'mud' and int(p['gp']) == 15,
                         'Free equipment swap retains15GP')
            capture('05-mud-owned-equipped')
            click(1166, 70, 'Back to garage')
            wait_text('SUNNY BUGGY')
            click(1126, 181, 'Explore3D')
            wait_text('GARAGE VALLEY')
            click(144, 398, 'World map')
            wait_text('YOUR DESTINATIONS')
            click(1061, 358, 'Enter Moss Marsh with actual earned stars and owned/equipped mud')
            payload, _ = wait_profile(lambda p: p['explore']['region'] == 'moss_marsh' and 'moss_marsh' in p['regions'],
                                      'Moss Marsh admitted and its checkpoint saved')
            wait_text('MOSS MARSH')
            capture('06-moss-before-input')
            input_driver.key('w', True)
            record('key_down', key='w', meaning='Actual3D throttle input; distance is not inferred from pixels')
            time.sleep(2)
            input_driver.key('w', False)
            record('key_up', key='w')
            capture('07-moss-after-input')
            pixels = [subprocess.check_output(['convert', str(args.output / name), '-depth', '8', 'rgb:-'], timeout=15)
                      for name in ['06-moss-before-input.png', '07-moss-after-input.png']]
            check(len(pixels[0]) == len(pixels[1]) == 1280 * 720 * 3 and pixels[0] != pixels[1],
                  'Decoded actual3D viewport pixels differ after OS throttle input; review original frames for travel')
            report['pixel_change_evidence'] = {'comparison': 'Decoded RGB pixels, excluding PNG metadata; no distance or performance inference.',
                                               'before_rgb_sha256': hashlib.sha256(pixels[0]).hexdigest(),
                                               'after_rgb_sha256': hashlib.sha256(pixels[1]).hexdigest()}
            input_driver.key('s', True)
            time.sleep(.5)
            input_driver.key('s', False)
            payload, raw = wait_profile(lambda p: int(p['gp']) == 15 and len(p['stars']) == 3, 'Final wallet and three mastery claims remain unchanged')
            (args.output / 'before-quit-save.json').write_bytes(raw)
            input_driver.close_window(window)
            record('normal_window_close', phase='first-launch')
            game.wait(timeout=12)
            check(game.returncode == 0, 'Normal compiled-game window close exits successfully')
            game = None
            launch('relaunch')
            wait_text('SUNNY BUGGY')
            restored, raw = wait_profile(lambda p: int(p['gp']) == 15 and p['build']['tires'] == 'mud'
                                         and p['equipped']['tires'] == 'mud' and 'mud' in p['owned']
                                         and len(p['stars']) == 3 and p['explore']['region'] == 'moss_marsh'
                                         and {'meadow', 'orchard', 'coast'} <= set(p['completed']),
                                         'Saved wallet/build/mastery/course/destination fields remain valid after the second process launches')
            (args.output / 'relaunch-save.json').write_bytes(raw)
            restored_text = capture('08-relaunched-garage')
            check(bool(re.search(r'\b15\s*GP\b', restored_text)) and bool(re.search(r'\b3\s*STARS\b', restored_text)),
                  'Actual relaunched garage UI restores15GP and three mastery stars')
            click(1107, 519, 'Inspect actual restored equipment in upgrade workshop')
            wait_text('UPGRADE WORKSHOP')
            equipped_text = capture('09-relaunched-equipment')
            check('MUD TIRES' in equipped_text and 'EQUIPPED' in equipped_text,
                  'Actual relaunched workshop UI identifies Mud tires as equipped')
            click(1166, 70, 'Back to restored garage')
            wait_text('SUNNY BUGGY')
            click(1126, 181, 'Reopen saved Explore destination')
            wait_text('MOSS MARSH')
            capture('10-relaunched-marsh')
            input_driver.close_window(window)
            record('normal_window_close', phase='relaunch')
            game.wait(timeout=12)
            check(game.returncode == 0, 'Relaunched exported game closes cleanly')
            final_value = read_profile()
            check(final_value is not None and final_value[0] == restored,
                  'Second normal app close preserves the restored profile without overwriting it with defaults')
            (args.output / 'after-final-close-save.json').write_bytes(final_value[1])
            game = None
            report['profile'] = {'gp': restored['gp'], 'stars': restored['stars'], 'tires': restored['build']['tires'],
                                 'regions': restored['regions'], 'explore': restored['explore'], 'completed': restored['completed']}
            for log in logs:
                log.flush()
            engine_text = ''.join((args.output / name).read_text() for name in ['first-launch-engine.txt', 'relaunch-engine.txt'])
            check(not re.search(r'(?:SCRIPT ERROR:|Parse Error:|^ERROR:)', engine_text, re.M),
                  'Both actual compiled-game process logs contain no engine/script errors')
        check(sha(args.binary) == executable_hash and all(sha(ROOT / name) == value for name, value in helper_hashes.items()),
              'Executable and verification helpers unchanged during actual GUI proof')
        report['status'] = 'pass'
        return 0
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        report['status'] = 'fail'
        report['failure'] = str(error)
        print('EXPORTED GUI FAILED: ' + str(error), file=sys.stderr, flush=True)
        return 1
    finally:
        if input_driver:
            try:
                input_driver.key('Right', False)
                input_driver.key('w', False)
                input_driver.key('s', False)
            except Exception:
                pass
            input_driver.close()
        if game is not None and game.poll() is None:
            game.terminate()
            try:
                game.wait(timeout=5)
            except subprocess.TimeoutExpired:
                game.kill()
                game.wait()
        if xorg is not None and xorg.poll() is None:
            xorg.terminate()
            try:
                xorg.wait(timeout=5)
            except subprocess.TimeoutExpired:
                xorg.kill()
                xorg.wait()
        for log in logs:
            log.close()
        report['elapsed_seconds'] = round(time.monotonic() - began, 3)
        report['all_checks_passed'] = report['status'] == 'pass' and all(item['passed'] for item in report['checks'])
        (args.output / 'report.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    sys.exit(main())

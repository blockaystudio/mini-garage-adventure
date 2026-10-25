#!/usr/bin/env python3
"""Serve only play/ for local testing. No uploads, admin API, analytics, or request logs."""
import argparse
from pathlib import Path
from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
from functools import partial
ROOT=Path(__file__).resolve().parents[1]/'play'
class Handler(SimpleHTTPRequestHandler):
    def log_message(self,*args):pass
    def end_headers(self):
        self.send_header('X-Content-Type-Options','nosniff')
        self.send_header('Referrer-Policy','no-referrer')
        self.send_header('Cache-Control','no-store')
        super().end_headers()
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--port',type=int,default=8080);p.add_argument('--bind',default='127.0.0.1',help='For same-Wi-Fi phone testing use 0.0.0.0; never expose publicly without a security/privacy review.')
a=p.parse_args()
if not 1<=a.port<=65535:p.error('Port must be between 1 and 65535')
server=ThreadingHTTPServer((a.bind,a.port),partial(Handler,directory=str(ROOT)))
print(f'Preview at http://{a.bind}:{a.port}/ (Ctrl+C stops it). Not a public deployment.')
try:server.serve_forever()
except KeyboardInterrupt:pass
finally:server.server_close()

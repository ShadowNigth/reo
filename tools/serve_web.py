#!/usr/bin/env python3
"""Static preview server. No COOP/COEP required (single-threaded Godot wasm)."""
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import functools, os
ROOT=Path(__file__).resolve().parents[1]/'web'
class Handler(SimpleHTTPRequestHandler):
    extensions_map={**SimpleHTTPRequestHandler.extensions_map,'.wasm':'application/wasm','.pck':'application/octet-stream','.js':'application/javascript'}
    def end_headers(self):
        self.send_header('Cache-Control','no-cache')
        self.send_header('X-Content-Type-Options','nosniff')
        super().end_headers()
    def do_GET(self):
        # Preview proxy may mount this server under a path; all assets are relative.
        super().do_GET()
if __name__=='__main__':
    port=int(os.environ.get('PORT','8060'))
    server=ThreadingHTTPServer(('0.0.0.0',port),functools.partial(Handler,directory=str(ROOT)))
    print(f'UMBRAL preview listening on 0.0.0.0:{port}',flush=True)
    server.serve_forever()

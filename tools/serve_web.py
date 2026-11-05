#!/usr/bin/env python3
"""Serve build/web with caching disabled, so every rebuild shows up on reload.
Usage: python3 tools/serve_web.py [port]"""
import http.server, os, sys

class NoCache(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, must-revalidate")
        self.send_header("Expires", "0")
        super().end_headers()

port = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
os.chdir(os.path.join(os.path.dirname(__file__), "..", "build", "web"))
http.server.ThreadingHTTPServer(("127.0.0.1", port), NoCache).serve_forever()

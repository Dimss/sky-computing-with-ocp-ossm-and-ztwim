#!/usr/bin/env python3
import http.server
import os
import socket

APP_NAME = os.environ.get("APP_NAME", socket.gethostname())
PORT = int(os.environ.get("PORT", 8080))


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        cookies = self.headers.get("Cookie", "(none)")
        body = f"app={APP_NAME} path={self.path} cookies=[{cookies}]\n"
        encoded = body.encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", len(encoded))
        self.end_headers()
        self.wfile.write(encoded)

    def log_message(self, fmt, *args):
        print(f"[{APP_NAME}] {fmt % args}")


if __name__ == "__main__":
    print(f"[{APP_NAME}] listening on :{PORT}")
    http.server.HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
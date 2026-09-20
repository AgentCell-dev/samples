"""streamlit-app: the marker/proxy front door, run next to Streamlit in the same container.

Streamlit does not speak the "GET / returns exactly one line" contract every sample here follows
-- its own "/" always serves its UI shell, and there is no supported option to make it answer a
plain GET with a bare text line instead. Rather than run a second container in front of it (this
platform is one container per cell, no sidecar -- see the top-level README's one-container rule),
this single stdlib-only process listens on 8080, answers the marker line itself for an exact
"GET /", and otherwise forwards the raw connection, byte for byte, to Streamlit's own server on
127.0.0.1:8501 (started by entrypoint.sh next to this one, same container, same process tree).

The forwarding is deliberately not HTTP-aware past the first request line: once a connection is
not a plain "GET /", every byte from then on -- including Streamlit's websocket upgrade, used for
every rerun -- is relayed unparsed in both directions. Streamlit itself is told
(--server.baseUrlPath app) to serve its UI and assets under /app instead of /, so its own "/" is
never in play; the dashboard lives at /app.
"""

import os
import socket
import socketserver
import threading

from marker import marker

PORT = int(os.environ.get("PORT", "8080"))
UPSTREAM_HOST = "127.0.0.1"
UPSTREAM_PORT = 8501
MAX_HEAD = 16384

MARKER = marker()
ROOT_BODY = f"agentcell sample: streamlit-app {MARKER}\n".encode()


def read_request_head(conn: socket.socket) -> bytes:
    """Read until the end of the HTTP request head (\\r\\n\\r\\n) or MAX_HEAD bytes, whichever
    comes first. An incomplete or unparsable head just falls through to being forwarded untouched,
    same as any other non-"/" request -- this is a sniff, not a validator."""
    buf = b""
    conn.settimeout(5)
    try:
        while b"\r\n\r\n" not in buf and len(buf) < MAX_HEAD:
            chunk = conn.recv(4096)
            if not chunk:
                break
            buf += chunk
    except OSError:
        pass
    finally:
        conn.settimeout(None)
    return buf


def is_plain_root_get(head: bytes) -> bool:
    line = head.split(b"\r\n", 1)[0]
    parts = line.split(b" ")
    if len(parts) < 2:
        return False
    method, path = parts[0], parts[1]
    return method == b"GET" and path == b"/"


def relay(src: socket.socket, dst: socket.socket) -> None:
    try:
        while True:
            chunk = src.recv(65536)
            if not chunk:
                break
            dst.sendall(chunk)
    except OSError:
        pass
    finally:
        for sock in (src, dst):
            try:
                sock.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass


class Handler(socketserver.BaseRequestHandler):
    def handle(self) -> None:
        conn: socket.socket = self.request
        head = read_request_head(conn)

        if is_plain_root_get(head):
            response = (
                b"HTTP/1.1 200 OK\r\n"
                b"Content-Type: text/plain; charset=utf-8\r\n"
                b"Content-Length: " + str(len(ROOT_BODY)).encode() + b"\r\n"
                b"Connection: close\r\n"
                b"\r\n" + ROOT_BODY
            )
            try:
                conn.sendall(response)
            except OSError:
                pass
            return

        # Anything else -- Streamlit's own assets, its /app UI, its websocket upgrade -- gets
        # forwarded untouched to Streamlit's own server.
        try:
            upstream = socket.create_connection((UPSTREAM_HOST, UPSTREAM_PORT), timeout=10)
        except OSError as exc:
            print(f"cannot reach streamlit at {UPSTREAM_HOST}:{UPSTREAM_PORT}: {exc}", flush=True)
            try:
                conn.sendall(b"HTTP/1.1 502 Bad Gateway\r\nConnection: close\r\n\r\n")
            except OSError:
                pass
            return

        if head:
            try:
                upstream.sendall(head)
            except OSError:
                upstream.close()
                return

        forward = threading.Thread(target=relay, args=(conn, upstream), daemon=True)
        forward.start()
        relay(upstream, conn)


class ThreadingServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


if __name__ == "__main__":
    # 0.0.0.0: a bind address inside the cell's own network namespace, not an address naming
    # another service -- same note as every other sample here.
    with ThreadingServer(("0.0.0.0", PORT), Handler) as server:
        print(
            f"streamlit-app proxy listening on 0.0.0.0:{PORT}, "
            f"forwarding non-'/' requests to {UPSTREAM_HOST}:{UPSTREAM_PORT}",
            flush=True,
        )
        server.serve_forever()

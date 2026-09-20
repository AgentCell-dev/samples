"""hello-static: the smallest possible AgentCell cell.

Serves one page: the marker line every sample here serves, plus a few static files read straight
off disk. No framework, no dependency, no /data write of its own (the marker file that lives in
/data is the only thing this app persists, and that only exists so a redeploy can be told from a
restart — see the top-level README).

Stdlib only, same reasoning as infra/images/deploy-fixture/app.py: a cell whose first act is a pip
install has a cold start that includes a network round trip, and a Kata cell has no network for its
first couple of seconds.
"""

import http.server
import os
import pathlib
import uuid

DATA = pathlib.Path(os.environ.get("AGENTCELL_DATA", "/data"))
MARKER_FILE = DATA / "marker"
PORT = int(os.environ.get("PORT", "8080"))
STATIC_DIR = pathlib.Path(__file__).parent / "static"


def marker() -> str:
    """AGENTCELL_SAMPLE_MARKER if the deploy set one; otherwise a value generated once at
    container start and kept in /data/marker, so a redeploy (new marker) can be told from a
    restart (same marker, because /data survived it) — see the top-level README."""
    env_marker = os.environ.get("AGENTCELL_SAMPLE_MARKER")
    if env_marker:
        return env_marker
    generated = uuid.uuid4().hex[:12]
    try:
        DATA.mkdir(parents=True, exist_ok=True)
        if MARKER_FILE.exists():
            return MARKER_FILE.read_text().strip()
        MARKER_FILE.write_text(generated + "\n")
    except OSError as exc:
        # Printed rather than swallowed, same reasoning as infra/images/deploy-fixture/app.py: a
        # cell that cannot write its own /data must say so out loud rather than presenting as an
        # application bug. It still starts, with a marker that cannot be told from a restart.
        print(f"cannot persist marker to {MARKER_FILE}: {exc}", flush=True)
    return generated


MARKER = marker()


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/" or self.path == "":
            body = f"agentcell sample: hello-static {MARKER}\n".encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        # Anything else: serve a static file by name if it exists under static/, 404 otherwise.
        # No path traversal above STATIC_DIR — resolve and check the prefix before opening.
        requested = (STATIC_DIR / self.path.lstrip("/")).resolve()
        if STATIC_DIR.resolve() not in requested.parents and requested != STATIC_DIR.resolve():
            self.send_error(404)
            return
        if requested.is_file():
            body = requested.read_bytes()
            self.send_response(200)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_error(404)

    def log_message(self, *_):
        pass


if __name__ == "__main__":
    # 0.0.0.0: a bind address inside the cell's own network namespace, not an address naming
    # another service — the same note as infra/images/deploy-fixture/app.py.
    http.server.ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()

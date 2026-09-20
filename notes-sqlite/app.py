"""notes-sqlite: a form and a JSON API backed by sqlite3 at /data/notes.db.

This is the sample that exercises the volume contract (plan section 6.1: /data is a cell's only
persistent location): a note written here must survive a redeploy and a drain, the same property
`make deploy-smoke` checks for the platform fixture with a plain text file. Here it is a real
database, opened fresh on every request rather than held across restarts -- sqlite3 handles its own
file locking, and a long-lived connection would need to survive the same crash-and-restart cycle
the notes are supposed to.

Stdlib only: http.server plus sqlite3, both in every CPython build. No framework, no dependency,
same cold-start reasoning as every other sample here.
"""

import http.server
import json
import os
import pathlib
import sqlite3
import uuid
from urllib.parse import parse_qs

DATA = pathlib.Path(os.environ.get("AGENTCELL_DATA", "/data"))
DB_PATH = DATA / "notes.db"
MARKER_FILE = DATA / "marker"
PORT = int(os.environ.get("PORT", "8080"))


def marker() -> str:
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
        print(f"cannot persist marker to {MARKER_FILE}: {exc}", flush=True)
    return generated


MARKER = marker()


def get_db() -> sqlite3.Connection:
    DATA.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.execute(
        "CREATE TABLE IF NOT EXISTS notes ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  body TEXT NOT NULL,"
        "  created_at TEXT NOT NULL DEFAULT (datetime('now'))"
        ")"
    )
    return conn


FORM_PAGE = """<!doctype html>
<html>
<head><title>notes-sqlite</title></head>
<body>
<h1>agentcell sample: notes-sqlite {marker}</h1>
<form method="POST" action="/notes">
  <input name="body" placeholder="a note" required>
  <button type="submit">save</button>
</form>
<ul>
{items}
</ul>
</body>
</html>
"""


class Handler(http.server.BaseHTTPRequestHandler):
    def _send(self, status: int, body: bytes, content_type: str = "text/plain; charset=utf-8"):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/":
            body = f"agentcell sample: notes-sqlite {MARKER}\n".encode()
            self._send(200, body)
            return

        if self.path == "/notes":
            conn = get_db()
            rows = conn.execute(
                "SELECT id, body, created_at FROM notes ORDER BY id DESC"
            ).fetchall()
            conn.close()
            body = json.dumps(
                [{"id": r[0], "body": r[1], "created_at": r[2]} for r in rows]
            ).encode()
            self._send(200, body, "application/json")
            return

        if self.path == "/form":
            conn = get_db()
            rows = conn.execute(
                "SELECT body FROM notes ORDER BY id DESC"
            ).fetchall()
            conn.close()
            items = "\n".join(f"<li>{r[0]}</li>" for r in rows)
            self._send(200, FORM_PAGE.format(marker=MARKER, items=items).encode(), "text/html; charset=utf-8")
            return

        self.send_error(404)

    def do_POST(self):
        if self.path != "/notes":
            self.send_error(404)
            return
        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length)
        content_type = self.headers.get("Content-Type", "")

        if content_type.startswith("application/json"):
            payload = json.loads(raw or b"{}")
            note_body = payload.get("body", "")
        else:
            form = parse_qs(raw.decode())
            note_body = form.get("body", [""])[0]

        if not note_body:
            self._send(400, b'{"error": "body is required"}\n', "application/json")
            return

        conn = get_db()
        conn.execute("INSERT INTO notes (body) VALUES (?)", (note_body,))
        conn.commit()
        note_id = conn.execute("SELECT last_insert_rowid()").fetchone()[0]
        conn.close()
        self._send(201, json.dumps({"id": note_id, "body": note_body}).encode(), "application/json")

    def log_message(self, *_):
        pass


if __name__ == "__main__":
    http.server.ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()

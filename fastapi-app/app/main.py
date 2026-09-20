"""fastapi-app: FastAPI + uvicorn, the ASGI stack coding agents reach for as often as a plain
stdlib server. A small in-memory JSON API (no persistence beyond the marker -- see notes-sqlite
for the volume contract exercised with a real database) plus one HTML page, so this sample proves
routing, request validation via Pydantic, and template-free HTML rendering all in one small app.

GET / returns the marker line every sample here serves, as plain text -- not FastAPI's default
JSON response, so this route builds a PlainTextResponse by hand rather than just returning a dict.
"""

import os
import pathlib
import uuid
from typing import List

from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse, PlainTextResponse
from pydantic import BaseModel

DATA = pathlib.Path(os.environ.get("AGENTCELL_DATA", "/data"))
MARKER_FILE = DATA / "marker"

app = FastAPI(title="agentcell sample: fastapi-app")


def marker() -> str:
    """AGENTCELL_SAMPLE_MARKER if the deploy set one; otherwise a value generated once at
    container start and kept in /data/marker, so a redeploy (new marker) can be told from a
    restart (same marker, because /data survived it) -- see the top-level README."""
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

# In-memory only -- this sample's point is FastAPI's request/response shape, not the volume
# contract (notes-sqlite already covers that with a real database at /data/notes.db). A restart
# empties this list; the marker is the only thing this app keeps in /data.
WIDGETS: List[dict] = [{"id": 1, "name": "sprocket"}, {"id": 2, "name": "cog"}]
NEXT_ID = 3


class Widget(BaseModel):
    name: str


@app.get("/", response_class=PlainTextResponse)
def root() -> str:
    return f"agentcell sample: fastapi-app {MARKER}\n"


@app.get("/api/widgets")
def list_widgets() -> List[dict]:
    return WIDGETS


@app.post("/api/widgets", status_code=201)
def create_widget(widget: Widget) -> dict:
    global NEXT_ID
    created = {"id": NEXT_ID, "name": widget.name}
    WIDGETS.append(created)
    NEXT_ID += 1
    return created


@app.get("/api/widgets/{widget_id}")
def get_widget(widget_id: int) -> dict:
    for widget in WIDGETS:
        if widget["id"] == widget_id:
            return widget
    raise HTTPException(status_code=404, detail="widget not found")


@app.get("/widgets", response_class=HTMLResponse)
def widgets_page() -> str:
    items = "\n".join(f"<li>#{w['id']}: {w['name']}</li>" for w in WIDGETS)
    return f"""<!doctype html>
<html>
<head><title>fastapi-app</title></head>
<body>
<h1>agentcell sample: fastapi-app {MARKER}</h1>
<p>Widgets, served from an in-memory list -- see <code>GET /api/widgets</code> for the JSON.</p>
<ul>
{items}
</ul>
</body>
</html>
"""

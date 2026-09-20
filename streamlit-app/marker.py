"""marker(): shared by proxy.py and dashboard.py so both agree on the same value. See
entrypoint.sh, which calls this once before starting either process, precisely so the two never
race to generate two different markers on a fresh /data volume."""

import os
import pathlib
import uuid

DATA = pathlib.Path(os.environ.get("AGENTCELL_DATA", "/data"))
MARKER_FILE = DATA / "marker"


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

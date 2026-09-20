# streamlit-app

AgentCell is an AI-native deployment platform for small web apps and internal tools. This sample
is a tiny Streamlit dashboard — a slider, a couple of metrics, and a chart, the fastest path from
a Python script to an internal tool with a UI.

## Deploy it

```sh
agentcell login
agentcell deploy --cell streamlit-app .
```

Open the URL `agentcell deploy` prints, then visit `/app` for the dashboard.

## What it shows

`GET /` returns the marker line every sample here serves:

```
agentcell sample: streamlit-app <marker>
```

Streamlit's own `/` always serves its UI shell — there is no supported way to make it answer this
repo's one-line marker contract instead. Running a second container in front of it was not an
option either: this platform is one container per cell, no sidecar (see the top-level README's
one-container-per-cell rule). So this sample runs one small stdlib-only process (`proxy.py`) on
8080 that answers an exact `GET /` itself with the marker line, and forwards every other request
— raw, unparsed past the first line, so Streamlit's websocket still works for every rerun — to
Streamlit's own server on `127.0.0.1:8501`. `entrypoint.sh` starts both under the same PID tree in
the same image; Streamlit itself runs with `--server.baseUrlPath app`, so its UI and assets live
under `/app` rather than colliding with the proxy's `/`.

## What it stores in /data

Only `marker`: `AGENTCELL_SAMPLE_MARKER` if the deploy set one, else a value this app generates
itself the first time it starts, kept so a restart can be told from a redeploy. `proxy.py` and
`dashboard.py` share the same `marker.py`; `entrypoint.sh` materializes the marker once before
starting either, so the two never race to generate two different values on a fresh volume's first
start.

## Deploy from your coding agent

Point your agent's MCP client at AgentCell:

```json
{"mcpServers":{"agentcell":{"command":"agentcell","args":["mcp"]}}}
```

See <https://agentcell.dev/docs/for-ai-agents.md> for the full tool reference.

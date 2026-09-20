# fastapi-app

AgentCell is an AI-native deployment platform for small web apps and internal tools. This sample
is FastAPI + uvicorn — a small in-memory JSON API plus one HTML page, the ASGI stack a coding
agent reaches for as often as a plain stdlib server.

## Deploy it

```sh
agentcell login
agentcell deploy --cell fastapi-app .
```

Open the URL `agentcell deploy` prints, then visit `/widgets` for the HTML page, or use the JSON
API directly:

```sh
curl https://<cell>.agentcell.cloud/api/widgets
curl -X POST https://<cell>.agentcell.cloud/api/widgets -H 'content-type: application/json' -d '{"name":"gear"}'
```

## What it shows

`GET /` returns the marker line every sample here serves, as plain text — built by hand with
`PlainTextResponse` rather than FastAPI's default JSON response. `GET /api/widgets` and
`POST /api/widgets` are a small JSON API over an in-memory list, validated with a Pydantic model;
`GET /api/widgets/{id}` returns one or 404s. `GET /widgets` renders the same list as an HTML page.

The widget list lives in memory only — this sample's point is FastAPI's request/response and
validation shape, not the volume contract (see `notes-sqlite` for that, with a real database at
`/data/notes.db`).

## What it stores in /data

Only `marker`: `AGENTCELL_SAMPLE_MARKER` if the deploy set one, else a value this app generates
itself the first time it starts, kept so a restart can be told from a redeploy.

## Deploy from your coding agent

Point your agent's MCP client at AgentCell:

```json
{"mcpServers":{"agentcell":{"command":"agentcell","args":["mcp"]}}}
```

See <https://agentcell.dev/docs/for-ai-agents.md> for the full tool reference.

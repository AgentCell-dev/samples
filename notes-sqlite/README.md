# notes-sqlite

A form and a JSON API for notes, backed by SQLite at `/data/notes.db`. This is the sample that
exercises the volume contract: a note written here survives a redeploy and a drain, because
`/data` is a cell's only persistent location and the platform guarantees it stays attached across
both.

## Deploy it

```sh
agentcell login
agentcell deploy --cell notes-sqlite .
```

Open the URL `agentcell deploy` prints, then visit `/form` for the HTML form, or use the JSON API
directly:

```sh
curl -X POST https://<cell>.agentcell.cloud/notes -d body="first note"
curl https://<cell>.agentcell.cloud/notes
```

## What it shows

`GET /` returns the marker line every sample here serves:

```
agentcell sample: notes-sqlite <marker>
```

`GET /form` renders a small HTML page with a form and the current notes. `GET /notes` returns them
as JSON. `POST /notes` (form-encoded or JSON body, `body=<text>`) adds one.

## What it stores in /data

- `notes.db` — a SQLite database, one `notes` table, created on first request.
- `marker` — same as every other sample: the value this app generates itself if
  `AGENTCELL_SAMPLE_MARKER` was not set, kept so a restart can be told from a redeploy.

Redeploy this cell (`agentcell deploy --cell notes-sqlite .` again) and the notes you wrote are
still there — the volume outlives the container.

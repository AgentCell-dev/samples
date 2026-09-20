# AgentCell samples

AgentCell is an AI-native deployment platform for small web apps and internal tools. These are
working apps to start from, or to hand to a coding agent as the pattern to copy.

Four small apps, each one directory, each deployable with three commands:

```sh
agentcell login
agentcell deploy --cell <name> .
```

then open the URL `agentcell deploy` prints.

| app | stack | what it exercises |
|---|---|---|
| [`hello-static`](hello-static/) | Python stdlib `http.server` | the minimum: build, route, Access gate |
| [`notes-sqlite`](notes-sqlite/) | Python stdlib + `sqlite3` at `/data/notes.db` | the volume contract — a note survives a redeploy and a drain |
| [`echo-go`](echo-go/) | Go, `net/http`, no deps | a compiled build, and a non-Python runtime |
| [`worker-node`](worker-node/) | Node 22, an HTTP server plus a background loop | a long-running process with state, the shape an agent-built app usually has |

Every app serves `GET /` with one line:

```
agentcell sample: <name> <marker>
```

`<marker>` comes from the `AGENTCELL_SAMPLE_MARKER` environment variable if the deploy set one,
otherwise the app generates a value itself the first time it starts and keeps it in
`/data/marker` — so a fresh redeploy (a new marker, one way or the other) can be told from a
restart of the same deployment (the same marker, because `/data` survived it).

## The one-container-per-cell rule

**Every sample here is a single container.** A sample that needs Redis or Postgres does not exist
in this repository, on purpose: AgentCell runs one container per cell, with `/data` as its only
persistent location (see each app's README for what it keeps there), and no sidecar. An app that
needs a second process talks to a *hosted* database over the network, the same way it would talk to
any other external service — it does not get a second container inside its own cell. These four
apps are the tutorial for that constraint as much as they are a tutorial for `agentcell deploy`.

## Building and checking locally

```sh
make check
```

builds every image with `docker`, runs each container once, and checks its marker line. For
`notes-sqlite` it additionally writes a note, restarts the container against the same volume, and
reads the note back — the same "survives a restart" property a redeploy relies on. See
[`Makefile`](Makefile) for what each check actually asserts, and its header comment for the volume
permission step it performs before each run (see `infra/STATUS.md`, "A cell can use its own
`/data` as a non-root user").

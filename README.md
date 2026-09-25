# AgentCell samples

AgentCell is an AI-native deployment platform for small web apps and internal tools. These are
working apps to start from, or to hand to a coding agent as the pattern to copy.

Nine small apps, each one directory, each deployable with three commands:

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
| [`nextjs-app`](nextjs-app/) | Next.js (App Router, TypeScript), `output: "standalone"` | a multi-stage frontend build, the stack coding agents most often produce |
| [`fastapi-app`](fastapi-app/) | FastAPI + uvicorn | a small JSON API plus an HTML page, on the ASGI stack |
| [`streamlit-app`](streamlit-app/) | Streamlit, fronted by a small stdlib proxy | a UI framework that cannot itself speak the marker contract, and the one-container proxy pattern that answers it |
| [`static-plain`](static-plain/) | plain HTML, CSS and JS; no `Dockerfile`, no build | a static site served as-is: the directory index, `404.html`, and dotfiles left unpublished |
| [`vite-react`](vite-react/) | Vite + React + react-router; no `Dockerfile` | a frontend built by the platform and served from `dist/`, with a client-side route that survives a reload |

Every app serves `GET /` with one line:

```
agentcell sample: <name> <marker>
```

`<marker>` comes from the `AGENTCELL_SAMPLE_MARKER` environment variable if the deploy set one,
otherwise the app generates a value itself the first time it starts and keeps it in
`/data/marker` — so a fresh redeploy (a new marker, one way or the other) can be told from a
restart of the same deployment (the same marker, because `/data` survived it).

The two static samples, `static-plain` and `vite-react`, are the exception. A static site has no
process and no `/data`, so its `index.html` holds the line without a marker,
`agentcell sample: <name>`, and the platform supplies the marker as an `X-AgentCell-Marker`
response header naming the deploy that served it. Deploy `vite-react` with client 0.1.4 or later,
which leaves `node_modules/` out of the upload; an older client uploads it too, and that usually
pushes a frontend project over the upload limit.

## The one-container-per-cell rule

**Every container sample here is a single container**, and the two static samples have no
container at all. A sample that needs Redis or Postgres does not exist
in this repository, on purpose: AgentCell runs one container per cell, with `/data` as its only
persistent location (see each app's README for what it keeps there), and no sidecar. An app that
needs a second process talks to a *hosted* database over the network, the same way it would talk to
any other external service — it does not get a second container inside its own cell. These apps
are the tutorial for that constraint as much as they are a tutorial for `agentcell deploy`.

## Building and checking locally

```sh
make check
```

builds every image with `docker`, runs each container once, and checks its marker line. For
`notes-sqlite` it additionally writes a note, restarts the container against the same volume, and
reads the note back — the same "survives a restart" property a redeploy relies on. For the static
samples there is no container: `check-static-plain` checks the files the platform will detect and
publish, and `check-vite-react` builds the app the way the platform does (`npm ci` then
`npm run build`, in the pinned Node image, still through `docker`) and checks `dist/index.html`. See
[`Makefile`](Makefile) for what each check actually asserts, and its header comment for the volume
permission step it performs before each run (see `infra/STATUS.md`, "A cell can use its own
`/data` as a non-root user").

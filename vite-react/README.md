# vite-react

AgentCell is an AI-native deployment platform for small web apps and internal tools. This sample
is a Vite + React single-page app with react-router: the frontend coding agents most often produce
when there is no server to write. It has no `Dockerfile`. AgentCell builds it and serves the output
as a static site, with no container behind it.

**Static sites are rolling out.** They work once the platform side is live; until then
`agentcell deploy` refuses a directory with no `Dockerfile`.

## Deploy it

```sh
agentcell login
agentcell deploy --cell vite-react .
```

Open the URL `agentcell deploy` prints. The site is private, behind the same sign-in as every cell.

You do not need to run `npm install` or `npm run build` first. The platform sees a `package.json`
with a `build` script and builds on its side: `npm ci` from the committed `package-lock.json`,
then `npm run build`. It serves `dist/`, the first of `dist/`, `build/` and `out/` that holds an
`index.html`. The client leaves `node_modules/` out of the upload, so a local install does not slow
the deploy down. `agentcell logs --build vite-react` shows the build output.

## What it shows

`GET /` is the built `dist/index.html`, whose body holds the marker line every sample here serves:

```
agentcell sample: vite-react
```

The line is in `index.html` itself, not rendered by React, so a plain `curl` sees it. A static cell
has no process to keep a per-deploy marker in `/data`, so the line has no `<marker>` field. The
platform supplies it instead: every response carries an `X-AgentCell-Marker` header naming the
deploy that served it.

`/about` is a **client-side route**: `dist/` has no `about.html`, and react-router renders the page
in the browser. It survives a reload or a direct link because this site has no `404.html`. With no
`404.html`, the platform answers an unknown path with no file extension (like `/about`) with
`index.html` and status 200, and the router takes it from there. An unknown path *with* an
extension, like `/missing.js`, is still a plain 404. Add a `public/404.html` (Vite copies it to
`dist/`) and the fallback turns off. `"agentcell": {"spa": true}` in `package.json` forces it back
on.

Vite writes the bundle to `dist/assets/` under hashed names (`index-CP-RjAbN.js`). The platform
tells browsers to cache anything under `assets/` for a year and `index.html` not at all, so a
redeploy is picked up on the next load.

## Building locally

```sh
npm ci
npm run build     # writes dist/
npm run preview   # serves dist/ with the same SPA fallback, on http://localhost:4173
```

`node_modules/` and `dist/` are in `.gitignore`. `make check-vite-react` at the repository root
builds this directory the way the platform does and checks the result.

## Deploy from your coding agent

Point your agent's MCP client at AgentCell:

```json
{"mcpServers":{"agentcell":{"command":"agentcell","args":["mcp"]}}}
```

See <https://agentcell.dev/docs/for-ai-agents.md> for the full tool reference.

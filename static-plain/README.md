# static-plain

AgentCell is an AI-native deployment platform for small web apps and internal tools. This sample
is a folder of plain HTML, CSS and JavaScript with no `Dockerfile`, no `package.json` and no build:
the directory is the site. It is served by AgentCell's edge directly, with no container behind it.

## Deploy it

```sh
agentcell login
agentcell deploy --cell static-plain .
```

Open the URL `agentcell deploy` prints. The site is private, behind the same sign-in as every cell.

## What it shows

`GET /` is `index.html`, whose body holds the marker line every sample here serves:

```
agentcell sample: static-plain
```

A static cell has no process to generate or keep a per-deploy marker in `/data`, so the line has
no `<marker>` field. The platform supplies it instead: every response carries an
`X-AgentCell-Marker` header naming the deploy that served it, and it changes on each redeploy.

The path rules, one file each:

| request | served from | rule |
|---|---|---|
| `/` | `index.html` | the directory index |
| `/about`, `/about/` | `about/index.html` | the directory index, in a subdirectory |
| `/contact` | `contact.html` | `<path>.html` |
| `/style.css`, `/app.js` | themselves | the exact path |
| `/.well-known/security.txt` | itself | `.well-known/` is the one dot-directory published |
| `/no-such-page` | `404.html`, status 404 | the site has a `404.html` |
| `/.env` | a plain 404 from the edge (not `404.html`) | **not published**: names beginning with `.` are left out, and the edge refuses dot paths before it looks for a page |

Because this site has a `404.html`, an unknown path gets that page with status 404. A site without
one gets `index.html` with status 200 instead, which is what a single-page app with client-side
routes needs; see [`vite-react`](../vite-react/).

`style.css` and `app.js` sit at the root rather than in `assets/` on purpose: the platform tells
browsers to cache anything under `assets/` for a year, which is right for a bundler's hashed file
names (`index-BfX3k2a.js`) and wrong for a hand-named file you will edit.

## The `.env` check

`.env` is committed here deliberately, holding no secret, only a canary value. `agentcell deploy`
sends it (the client uploads dotfiles), and the platform must leave it out when it publishes the
site. After a deploy, check both:

```sh
# expect 404, and a body that does NOT contain the canary
curl -s -o /dev/null -w '%{http_code}\n' "$URL/.env"
curl -s "$URL/.env" | grep -c static-plain-dotfile-canary   # expect 0
# the positive control: .well-known IS published
curl -s -o /dev/null -w '%{http_code}\n' "$URL/.well-known/security.txt"   # expect 200
```

(`$URL` is the URL `agentcell deploy` printed; send the same sign-in cookie or token you use for the
site.) Never put a real secret in a static site's folder: a static site has no server-side code, so
nothing in it is private from the people who can open the site.

## Deploy from your coding agent

Point your agent's MCP client at AgentCell:

```json
{"mcpServers":{"agentcell":{"command":"agentcell","args":["mcp"]}}}
```

See <https://agentcell.dev/docs/for-ai-agents.md> for the full tool reference.

# nextjs-app

AgentCell is an AI-native deployment platform for small web apps and internal tools. This sample
is a minimal Next.js App Router app in TypeScript — the stack coding agents most often produce for
a web frontend, with no dependency beyond `next`, `react`, and `react-dom`.

## Deploy it

```sh
agentcell login
agentcell deploy --cell nextjs-app .
```

Open the URL `agentcell deploy` prints.

## What it shows

`GET /` returns the marker line every sample here serves:

```
agentcell sample: nextjs-app <marker>
```

It is a route handler (`app/route.ts`), not a page component — App Router pages always render
wrapped in `<html><body>`, and the contract here is one exact plain-text line. `GET /about` is an
ordinary server-rendered page (`app/about/page.tsx`), the ordinary shape most of a real Next.js app
would actually use.

The Dockerfile builds with `next build` (`output: "standalone"` in `next.config.js`) in one stage,
then copies only `.next/standalone`, `.next/static`, and `public/` into a second, much smaller
runtime image — no dev toolchain, no source, no unpruned `node_modules`.

## What it stores in /data

Only `marker`: `AGENTCELL_SAMPLE_MARKER` if the deploy set one, else a value this app generates
itself the first time it starts, kept so a restart can be told from a redeploy.

## Deploy from your coding agent

Point your agent's MCP client at AgentCell:

```json
{"mcpServers":{"agentcell":{"command":"agentcell","args":["mcp"]}}}
```

See <https://agentcell.dev/docs/for-ai-agents.md> for the full tool reference.

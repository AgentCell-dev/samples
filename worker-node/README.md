# worker-node

An HTTP server plus a background loop — the shape an agent-built app usually has: something
long-running that does work on its own schedule, not only in response to a request. The loop
writes the current timestamp to `/data/heartbeat` every 10 seconds.

## Deploy it

```sh
agentcell login
agentcell deploy --cell worker-node .
```

Open the URL `agentcell deploy` prints.

## What it shows

`GET /` returns the marker line every sample here serves:

```
agentcell sample: worker-node <marker>
```

`GET /heartbeat` returns the timestamp the background loop last wrote — fetch it twice, ten
seconds apart, and the value changes. That is the proof the loop is actually running, not just the
HTTP server answering.

## What it stores in /data

- `heartbeat` — an ISO-8601 timestamp, overwritten every 10 s.
- `marker` — same as every other sample: the value this app generates itself if
  `AGENTCELL_SAMPLE_MARKER` was not set, kept so a restart can be told from a redeploy.

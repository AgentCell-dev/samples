# hello-static

The smallest AgentCell cell: one Python stdlib `http.server`, no dependencies, no framework. It
exercises the minimum a cell needs to prove: it builds, it gets a route, and it answers behind the
Access gate.

## Deploy it

```sh
agentcell login
agentcell deploy --cell hello-static .
```

Open the URL `agentcell deploy` prints.

## What it shows

`GET /` returns one line:

```
agentcell sample: hello-static <marker>
```

`<marker>` is either the value of the `AGENTCELL_SAMPLE_MARKER` environment variable, if the
deploy set one, or a value this app generates itself the first time it starts and then keeps in
`/data/marker`. That difference is the point: redeploying a cell gives it a NEW image, so a fresh
`AGENTCELL_SAMPLE_MARKER` (if the deploy sets one) or a value read back from `/data/marker`
(otherwise) tells you whether you are looking at a genuinely new deployment or the same one that
merely restarted.

`GET /about.txt` serves a static file straight off disk, unrelated to the marker — the other half
of what "static" means here.

## What it stores in /data

Only `marker` (see above). Nothing else. This is the one sample here with no real persistent
state — see `notes-sqlite` for that.

# echo-go

A compiled Go binary with no dependencies beyond `net/http`. This is the sample that exercises a
non-Python runtime and a real compiled build on `build-1`, rather than a script laid into an image
unchanged.

## Deploy it

```sh
agentcell login
agentcell deploy --cell echo-go .
```

Open the URL `agentcell deploy` prints.

## What it shows

`GET /` returns the marker line every sample here serves:

```
agentcell sample: echo-go <marker>
```

`GET /echo` reflects the request back — method, path, headers and body — which is what an "echo"
service is for.

## What it stores in /data

Only `marker`: `AGENTCELL_SAMPLE_MARKER` if the deploy set one, else a value this app generates
itself the first time it starts, kept so a restart can be told from a redeploy.

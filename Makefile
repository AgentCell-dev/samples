# make check: build every sample image locally with docker, run each container once, curl / and
# assert the marker line; for notes-sqlite, additionally write a note, restart the container
# against the same volume, and read it back.
#
# THE VOLUME PERMISSION STEP. infra/STATUS.md records that Nomad's mkdir plugin creates a cell's
# /data volume 0700 root and ignores a mode parameter, and that "the agent sets the mode" before
# the cell's server task starts -- the platform's backup agent, running on the prestart path
# (infra/jobs/cell.nomad.hcl.tmpl's "wait-for-data" task), fixes ownership before a cell's own
# process ever touches /data. A plain `docker run -v name:/data` has no such agent: a fresh named
# volume is created root:root 0755, unwritable by the cell user (uid 10001, matching every
# Dockerfile here). So each check below chowns the volume to that uid first, standing in for what
# the platform's agent does for real. This is the one place local docker and the real platform
# genuinely differ, and it is called out rather than left to look like a coincidence.
#
# Each check target is one shell recipe line per app (no $(call) macro with embedded newlines --
# those would run as separate `make` recipe lines under separate shells and lose the trap/vars),
# so there is some repetition between hello-static / echo-go / worker-node. notes-sqlite is its
# own target because it does more.
SHELL := /bin/bash

APPS := hello-static notes-sqlite echo-go worker-node nextjs-app fastapi-app streamlit-app
CELL_UID := 10001

# The static samples (static-plain, vite-react) have no image and no container, so they are not in
# APPS and `clean` has nothing of theirs to remove. Their directories are variables only so a check
# can be pointed at a deliberately broken copy to watch it fail.
STATIC_PLAIN_DIR ?= static-plain
VITE_REACT_DIR ?= vite-react

# The Node image a static-build cell is built in (infra/STATIC-CELLS.md §3: "the pin
# samples/nextjs-app uses"). Read from that Dockerfile rather than restated, so there is one place
# holding the digest; check-vite-react refuses to run if the read comes back empty.
NODE_IMAGE := $(shell sed -n 's/^FROM \(node@sha256:[0-9a-f]\{64\}\) AS build$$/\1/p' nextjs-app/Dockerfile)

.PHONY: check clean check-hello-static check-echo-go check-worker-node check-notes-sqlite \
	check-nextjs-app check-fastapi-app check-streamlit-app check-static-plain check-vite-react

check: check-hello-static check-echo-go check-worker-node check-notes-sqlite \
	check-nextjs-app check-fastapi-app check-streamlit-app check-static-plain check-vite-react
	@echo "== all sample checks passed =="

clean:
	@for app in $(APPS); do \
		docker rm -f agentcell-sample-$$app-check >/dev/null 2>&1 || true; \
		docker volume rm agentcell-sample-$$app-check-data >/dev/null 2>&1 || true; \
	done

# --- hello-static, echo-go, worker-node: build, run, curl /, assert the marker line -------------

check-hello-static:
	@set -eu; \
	app=hello-static; \
	image="agentcell-sample-$$app:check"; \
	container="agentcell-sample-$$app-check"; \
	volume="agentcell-sample-$$app-check-data"; \
	marker="check-marker-$$app-$$$$"; \
	echo "== building $$app =="; \
	docker build -q -t "$$image" "$$app" >/dev/null; \
	docker rm -f "$$container" >/dev/null 2>&1 || true; \
	docker volume rm "$$volume" >/dev/null 2>&1 || true; \
	docker volume create "$$volume" >/dev/null; \
	docker run --rm -v "$$volume:/data" alpine:3.20 chown $(CELL_UID):$(CELL_UID) /data >/dev/null; \
	trap 'docker rm -f "$$container" >/dev/null 2>&1; docker volume rm "$$volume" >/dev/null 2>&1' EXIT; \
	port=$$(( 20000 + RANDOM % 10000 )); \
	docker run -d --name "$$container" -p "$$port:8080" -v "$$volume:/data" \
		-e AGENTCELL_SAMPLE_MARKER="$$marker" "$$image" >/dev/null; \
	ok=0; \
	for i in $$(seq 1 20); do \
		if body=$$(curl -sf "http://localhost:$$port/" 2>/dev/null); then ok=1; break; fi; \
		sleep 0.5; \
	done; \
	if [ "$$ok" != "1" ]; then \
		echo "FAIL: $$app never answered on / -- docker logs:"; docker logs "$$container" || true; exit 1; \
	fi; \
	want="agentcell sample: $$app $$marker"; \
	if [ "$$body" != "$$want" ]; then \
		echo "FAIL: $$app / returned:"; echo "  $$body"; echo "expected exactly:"; echo "  $$want"; exit 1; \
	fi; \
	echo "OK: $$app served '$$body'"

check-echo-go:
	@set -eu; \
	app=echo-go; \
	image="agentcell-sample-$$app:check"; \
	container="agentcell-sample-$$app-check"; \
	volume="agentcell-sample-$$app-check-data"; \
	marker="check-marker-$$app-$$$$"; \
	echo "== building $$app =="; \
	docker build -q -t "$$image" "$$app" >/dev/null; \
	docker rm -f "$$container" >/dev/null 2>&1 || true; \
	docker volume rm "$$volume" >/dev/null 2>&1 || true; \
	docker volume create "$$volume" >/dev/null; \
	docker run --rm -v "$$volume:/data" alpine:3.20 chown $(CELL_UID):$(CELL_UID) /data >/dev/null; \
	trap 'docker rm -f "$$container" >/dev/null 2>&1; docker volume rm "$$volume" >/dev/null 2>&1' EXIT; \
	port=$$(( 20000 + RANDOM % 10000 )); \
	docker run -d --name "$$container" -p "$$port:8080" -v "$$volume:/data" \
		-e AGENTCELL_SAMPLE_MARKER="$$marker" "$$image" >/dev/null; \
	ok=0; \
	for i in $$(seq 1 20); do \
		if body=$$(curl -sf "http://localhost:$$port/" 2>/dev/null); then ok=1; break; fi; \
		sleep 0.5; \
	done; \
	if [ "$$ok" != "1" ]; then \
		echo "FAIL: $$app never answered on / -- docker logs:"; docker logs "$$container" || true; exit 1; \
	fi; \
	want="agentcell sample: $$app $$marker"; \
	if [ "$$body" != "$$want" ]; then \
		echo "FAIL: $$app / returned:"; echo "  $$body"; echo "expected exactly:"; echo "  $$want"; exit 1; \
	fi; \
	echo "OK: $$app served '$$body'"

check-worker-node:
	@set -eu; \
	app=worker-node; \
	image="agentcell-sample-$$app:check"; \
	container="agentcell-sample-$$app-check"; \
	volume="agentcell-sample-$$app-check-data"; \
	marker="check-marker-$$app-$$$$"; \
	echo "== building $$app =="; \
	docker build -q -t "$$image" "$$app" >/dev/null; \
	docker rm -f "$$container" >/dev/null 2>&1 || true; \
	docker volume rm "$$volume" >/dev/null 2>&1 || true; \
	docker volume create "$$volume" >/dev/null; \
	docker run --rm -v "$$volume:/data" alpine:3.20 chown $(CELL_UID):$(CELL_UID) /data >/dev/null; \
	trap 'docker rm -f "$$container" >/dev/null 2>&1; docker volume rm "$$volume" >/dev/null 2>&1' EXIT; \
	port=$$(( 20000 + RANDOM % 10000 )); \
	docker run -d --name "$$container" -p "$$port:8080" -v "$$volume:/data" \
		-e AGENTCELL_SAMPLE_MARKER="$$marker" "$$image" >/dev/null; \
	ok=0; \
	for i in $$(seq 1 20); do \
		if body=$$(curl -sf "http://localhost:$$port/" 2>/dev/null); then ok=1; break; fi; \
		sleep 0.5; \
	done; \
	if [ "$$ok" != "1" ]; then \
		echo "FAIL: $$app never answered on / -- docker logs:"; docker logs "$$container" || true; exit 1; \
	fi; \
	want="agentcell sample: $$app $$marker"; \
	if [ "$$body" != "$$want" ]; then \
		echo "FAIL: $$app / returned:"; echo "  $$body"; echo "expected exactly:"; echo "  $$want"; exit 1; \
	fi; \
	echo "OK: $$app served '$$body'"; \
	echo "== checking the heartbeat loop =="; \
	h1=$$(curl -sf "http://localhost:$$port/heartbeat"); \
	sleep 11; \
	h2=$$(curl -sf "http://localhost:$$port/heartbeat"); \
	if [ "$$h1" = "$$h2" ]; then \
		echo "FAIL: $$app heartbeat did not change after 11s (h1=$$h1 h2=$$h2)"; exit 1; \
	fi; \
	echo "OK: $$app heartbeat advanced from '$$h1' to '$$h2'"

# --- notes-sqlite: marker check, then write -> restart -> read back -----------------------------

check-notes-sqlite:
	@set -eu; \
	app=notes-sqlite; \
	image="agentcell-sample-$$app:check"; \
	container="agentcell-sample-$$app-check"; \
	volume="agentcell-sample-$$app-check-data"; \
	marker="check-marker-$$app-$$$$"; \
	echo "== building $$app =="; \
	docker build -q -t "$$image" "$$app" >/dev/null; \
	docker rm -f "$$container" >/dev/null 2>&1 || true; \
	docker volume rm "$$volume" >/dev/null 2>&1 || true; \
	docker volume create "$$volume" >/dev/null; \
	docker run --rm -v "$$volume:/data" alpine:3.20 chown $(CELL_UID):$(CELL_UID) /data >/dev/null; \
	trap 'docker rm -f "$$container" >/dev/null 2>&1; docker volume rm "$$volume" >/dev/null 2>&1' EXIT; \
	port=$$(( 20000 + RANDOM % 10000 )); \
	docker run -d --name "$$container" -p "$$port:8080" -v "$$volume:/data" \
		-e AGENTCELL_SAMPLE_MARKER="$$marker" "$$image" >/dev/null; \
	ok=0; \
	for i in $$(seq 1 20); do \
		if body=$$(curl -sf "http://localhost:$$port/" 2>/dev/null); then ok=1; break; fi; \
		sleep 0.5; \
	done; \
	if [ "$$ok" != "1" ]; then \
		echo "FAIL: $$app never answered on / -- docker logs:"; docker logs "$$container" || true; exit 1; \
	fi; \
	want="agentcell sample: $$app $$marker"; \
	if [ "$$body" != "$$want" ]; then \
		echo "FAIL: $$app / returned '$$body', expected '$$want'"; exit 1; \
	fi; \
	echo "OK: $$app served '$$body'"; \
	note="the volume survived a restart $$$$"; \
	if ! curl -sf -X POST "http://localhost:$$port/notes" -d "body=$$note" >/dev/null; then \
		echo "FAIL: $$app refused to write a note"; docker logs "$$container" || true; exit 1; \
	fi; \
	echo "OK: $$app accepted a note"; \
	echo "== restarting $$app against the same volume =="; \
	docker rm -f "$$container" >/dev/null; \
	docker run -d --name "$$container" -p "$$port:8080" -v "$$volume:/data" \
		-e AGENTCELL_SAMPLE_MARKER="$$marker" "$$image" >/dev/null; \
	ok=0; \
	for i in $$(seq 1 20); do \
		if curl -sf "http://localhost:$$port/" >/dev/null 2>&1; then ok=1; break; fi; \
		sleep 0.5; \
	done; \
	if [ "$$ok" != "1" ]; then \
		echo "FAIL: $$app never came back up after restart -- docker logs:"; docker logs "$$container" || true; exit 1; \
	fi; \
	notes_json=$$(curl -sf "http://localhost:$$port/notes"); \
	case "$$notes_json" in \
		*"$$note"*) echo "OK: $$app read the note back after a restart: $$notes_json" ;; \
		*) echo "FAIL: $$app did not read the note back after a restart. /notes returned:"; \
		   echo "  $$notes_json"; \
		   exit 1 ;; \
	esac

# --- nextjs-app: marker check, then assert /about (a real page, not the marker route) is 200 ----

check-nextjs-app:
	@set -eu; \
	app=nextjs-app; \
	image="agentcell-sample-$$app:check"; \
	container="agentcell-sample-$$app-check"; \
	volume="agentcell-sample-$$app-check-data"; \
	marker="check-marker-$$app-$$$$"; \
	echo "== building $$app =="; \
	docker build -q -t "$$image" "$$app" >/dev/null; \
	docker rm -f "$$container" >/dev/null 2>&1 || true; \
	docker volume rm "$$volume" >/dev/null 2>&1 || true; \
	docker volume create "$$volume" >/dev/null; \
	docker run --rm -v "$$volume:/data" alpine:3.20 chown $(CELL_UID):$(CELL_UID) /data >/dev/null; \
	trap 'docker rm -f "$$container" >/dev/null 2>&1; docker volume rm "$$volume" >/dev/null 2>&1' EXIT; \
	port=$$(( 20000 + RANDOM % 10000 )); \
	docker run -d --name "$$container" -p "$$port:8080" -v "$$volume:/data" \
		-e AGENTCELL_SAMPLE_MARKER="$$marker" "$$image" >/dev/null; \
	ok=0; \
	for i in $$(seq 1 20); do \
		if body=$$(curl -sf "http://localhost:$$port/" 2>/dev/null); then ok=1; break; fi; \
		sleep 0.5; \
	done; \
	if [ "$$ok" != "1" ]; then \
		echo "FAIL: $$app never answered on / -- docker logs:"; docker logs "$$container" || true; exit 1; \
	fi; \
	want="agentcell sample: $$app $$marker"; \
	if [ "$$body" != "$$want" ]; then \
		echo "FAIL: $$app / returned:"; echo "  $$body"; echo "expected exactly:"; echo "  $$want"; exit 1; \
	fi; \
	echo "OK: $$app served '$$body'"; \
	about_code=$$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:$$port/about"); \
	if [ "$$about_code" != "200" ]; then \
		echo "FAIL: $$app /about returned HTTP $$about_code, expected 200"; docker logs "$$container" || true; exit 1; \
	fi; \
	echo "OK: $$app /about returned HTTP 200"

# --- fastapi-app: marker check, then assert the JSON API returns the seeded widgets ------------

check-fastapi-app:
	@set -eu; \
	app=fastapi-app; \
	image="agentcell-sample-$$app:check"; \
	container="agentcell-sample-$$app-check"; \
	volume="agentcell-sample-$$app-check-data"; \
	marker="check-marker-$$app-$$$$"; \
	echo "== building $$app =="; \
	docker build -q -t "$$image" "$$app" >/dev/null; \
	docker rm -f "$$container" >/dev/null 2>&1 || true; \
	docker volume rm "$$volume" >/dev/null 2>&1 || true; \
	docker volume create "$$volume" >/dev/null; \
	docker run --rm -v "$$volume:/data" alpine:3.20 chown $(CELL_UID):$(CELL_UID) /data >/dev/null; \
	trap 'docker rm -f "$$container" >/dev/null 2>&1; docker volume rm "$$volume" >/dev/null 2>&1' EXIT; \
	port=$$(( 20000 + RANDOM % 10000 )); \
	docker run -d --name "$$container" -p "$$port:8080" -v "$$volume:/data" \
		-e AGENTCELL_SAMPLE_MARKER="$$marker" "$$image" >/dev/null; \
	ok=0; \
	for i in $$(seq 1 20); do \
		if body=$$(curl -sf "http://localhost:$$port/" 2>/dev/null); then ok=1; break; fi; \
		sleep 0.5; \
	done; \
	if [ "$$ok" != "1" ]; then \
		echo "FAIL: $$app never answered on / -- docker logs:"; docker logs "$$container" || true; exit 1; \
	fi; \
	want="agentcell sample: $$app $$marker"; \
	if [ "$$body" != "$$want" ]; then \
		echo "FAIL: $$app / returned:"; echo "  $$body"; echo "expected exactly:"; echo "  $$want"; exit 1; \
	fi; \
	echo "OK: $$app served '$$body'"; \
	widgets_json=$$(curl -sf "http://localhost:$$port/api/widgets"); \
	case "$$widgets_json" in \
		*"sprocket"*) echo "OK: $$app /api/widgets returned JSON: $$widgets_json" ;; \
		*) echo "FAIL: $$app /api/widgets did not return the seeded widgets. Returned:"; \
		   echo "  $$widgets_json"; \
		   exit 1 ;; \
	esac

# --- streamlit-app: marker check, then assert the proxy forwards /app to Streamlit's own UI -----

check-streamlit-app:
	@set -eu; \
	app=streamlit-app; \
	image="agentcell-sample-$$app:check"; \
	container="agentcell-sample-$$app-check"; \
	volume="agentcell-sample-$$app-check-data"; \
	marker="check-marker-$$app-$$$$"; \
	echo "== building $$app =="; \
	docker build -q -t "$$image" "$$app" >/dev/null; \
	docker rm -f "$$container" >/dev/null 2>&1 || true; \
	docker volume rm "$$volume" >/dev/null 2>&1 || true; \
	docker volume create "$$volume" >/dev/null; \
	docker run --rm -v "$$volume:/data" alpine:3.20 chown $(CELL_UID):$(CELL_UID) /data >/dev/null; \
	trap 'docker rm -f "$$container" >/dev/null 2>&1; docker volume rm "$$volume" >/dev/null 2>&1' EXIT; \
	port=$$(( 20000 + RANDOM % 10000 )); \
	docker run -d --name "$$container" -p "$$port:8080" -v "$$volume:/data" \
		-e AGENTCELL_SAMPLE_MARKER="$$marker" "$$image" >/dev/null; \
	ok=0; \
	for i in $$(seq 1 40); do \
		if body=$$(curl -sf "http://localhost:$$port/" 2>/dev/null); then ok=1; break; fi; \
		sleep 0.5; \
	done; \
	if [ "$$ok" != "1" ]; then \
		echo "FAIL: $$app never answered on / -- docker logs:"; docker logs "$$container" || true; exit 1; \
	fi; \
	want="agentcell sample: $$app $$marker"; \
	if [ "$$body" != "$$want" ]; then \
		echo "FAIL: $$app / returned:"; echo "  $$body"; echo "expected exactly:"; echo "  $$want"; exit 1; \
	fi; \
	echo "OK: $$app served '$$body'"; \
	app_code=$$(curl -sfL -o /dev/null -w '%{http_code}' "http://localhost:$$port/app"); \
	if [ "$$app_code" != "200" ]; then \
		echo "FAIL: $$app /app (via the proxy, forwarded to Streamlit) returned HTTP $$app_code, expected 200"; \
		docker logs "$$container" || true; exit 1; \
	fi; \
	echo "OK: $$app /app (proxied to Streamlit) returned HTTP 200"

# --- static-plain, vite-react: static cells (infra/STATIC-CELLS.md) ------------------------------
#
# A static cell has no container to run, so these check what the platform reads: the shape it will
# detect at the root (§1), and the files it will publish. The serving rules themselves -- the
# directory index, the SPA fallback, dotfiles left out -- belong to the edge, and the live
# `make static-smoke` in infra is what exercises them against these two directories.
#
# static-plain must be detected as static-plain: an index.html at the root and neither a Dockerfile
# nor a package.json (either would win the detection order). It must also still carry the inputs
# its README's checks need: about/index.html for the directory-index rule, 404.html so unknown
# paths are 404s, .well-known/ as the published dot-directory, and .env as the one that must not be.

check-static-plain:
	@set -eu; \
	app=static-plain; dir="$(STATIC_PLAIN_DIR)"; \
	echo "== checking $$app (static-plain shape, no build) =="; \
	for f in Dockerfile package.json; do \
		if [ -e "$$dir/$$f" ]; then echo "FAIL: $$app has $$f, which would win detection over index.html"; exit 1; fi; \
	done; \
	for f in index.html about/index.html contact.html 404.html .well-known/security.txt .env; do \
		if [ ! -f "$$dir/$$f" ]; then echo "FAIL: $$app lacks $$f"; exit 1; fi; \
	done; \
	want="agentcell sample: $$app"; \
	if ! grep -qxF "$$want" "$$dir/index.html"; then \
		echo "FAIL: $$app index.html has no line exactly:"; echo "  $$want"; exit 1; \
	fi; \
	echo "OK: $$app index.html holds '$$want', and every file its README checks is present"

# vite-react is built exactly as the platform builds a static-build cell: in the pinned Node image,
# `npm ci` from the committed lockfile, then `npm run build`. The source goes in and dist/ comes out
# through tar on stdin/stdout rather than a bind mount, so node_modules and dist never land in the
# working tree and the check behaves the same on a hosted runner as on a workstation. It then
# asserts dist/index.html holds the marker line (Vite keeps index.html's body as written), that
# dist/ has no 404.html (so the SPA fallback is on by rule and /about survives a reload), and that
# the bundle Vite emitted is there.

check-vite-react:
	@set -eu -o pipefail; \
	app=vite-react; dir="$(VITE_REACT_DIR)"; image="$(NODE_IMAGE)"; \
	if [ -z "$$image" ]; then echo "FAIL: could not read the node@sha256 build pin from nextjs-app/Dockerfile"; exit 1; fi; \
	for f in package.json package-lock.json index.html; do \
		if [ ! -f "$$dir/$$f" ]; then echo "FAIL: $$app lacks $$f"; exit 1; fi; \
	done; \
	if [ -e "$$dir/Dockerfile" ]; then echo "FAIL: $$app has a Dockerfile, which would win detection over package.json"; exit 1; fi; \
	out=$$(mktemp -d); trap 'rm -rf "$$out"' EXIT; \
	echo "== building $$app (npm ci && npm run build, in the pinned node image) =="; \
	COPYFILE_DISABLE=1 tar -C "$$dir" --exclude=./node_modules --exclude=./dist -cf - . \
		| docker run --rm -i "$$image" sh -c \
			'mkdir /src && cd /src && tar -xf - && npm ci --no-audit --no-fund >&2 && npm run build >&2 && tar -cf - dist' \
		| tar -C "$$out" -xf -; \
	if [ ! -f "$$out/dist/index.html" ]; then echo "FAIL: $$app build produced no dist/index.html"; exit 1; fi; \
	want="agentcell sample: $$app"; \
	if ! grep -qxF "$$want" "$$out/dist/index.html"; then \
		echo "FAIL: $$app dist/index.html has no line exactly:"; echo "  $$want"; exit 1; \
	fi; \
	if [ -e "$$out/dist/404.html" ]; then echo "FAIL: $$app dist/ has a 404.html, which turns the SPA fallback off"; exit 1; fi; \
	if ! ls "$$out"/dist/assets/*.js >/dev/null 2>&1; then echo "FAIL: $$app dist/assets/ holds no .js bundle"; exit 1; fi; \
	echo "OK: $$app built dist/index.html holding '$$want', with no 404.html (SPA fallback on)"

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

.PHONY: check clean check-hello-static check-echo-go check-worker-node check-notes-sqlite \
	check-nextjs-app check-fastapi-app check-streamlit-app

check: check-hello-static check-echo-go check-worker-node check-notes-sqlite \
	check-nextjs-app check-fastapi-app check-streamlit-app
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

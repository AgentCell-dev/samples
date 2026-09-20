#!/bin/sh
set -e

# Materialize the marker (env var, or generate one and persist it to /data/marker) before either
# process starts, so proxy.py and dashboard.py -- which both import marker.py -- agree on the
# same value instead of racing to generate two different ones on a fresh volume's first start.
python3 -c "from marker import marker; marker()"

streamlit run /app/dashboard.py \
	--server.port 8501 \
	--server.address 127.0.0.1 \
	--server.baseUrlPath app \
	--server.headless true \
	--browser.gatherUsageStats false &

# exec, not a plain call: this process (the marker/proxy front door on 8080) becomes pid 1's
# direct child in its place, so a `docker stop` signal reaches it without an extra shell hop.
exec python3 -u /app/proxy.py

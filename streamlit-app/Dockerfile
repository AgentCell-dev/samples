# streamlit-app: a tiny Streamlit dashboard. Streamlit's own "/" always serves its UI shell and
# cannot be made to answer this repo's one-line marker contract -- see proxy.py for the choice
# made instead of a second container: a small stdlib-only proxy answers "/" itself and forwards
# every other request, raw and unparsed past the first line (so Streamlit's websocket still
# works), to Streamlit's own server on 127.0.0.1:8501. entrypoint.sh starts both under one PID
# tree in this one image -- still one container, no sidecar (see the top-level README's
# one-container-per-cell rule).
#
# Pinned by digest. `python:3.12-slim` as of 20 September 2026 -- slim rather than alpine for the
# same reason as fastapi-app: Streamlit's dependency tree (pandas, pyarrow, pillow, ...) ships
# manylinux wheels for glibc, not musl, and alpine would rebuild several of them from source.
FROM python@sha256:2f17fc044b579bab302c2e8054d3a686e2cb9a83de48e70534b94cd8ebbe06a9

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY marker.py dashboard.py proxy.py entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

RUN adduser --disabled-password --uid 10001 cell
USER cell

WORKDIR /app
EXPOSE 8080
CMD ["/app/entrypoint.sh"]

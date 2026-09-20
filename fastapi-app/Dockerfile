# fastapi-app: FastAPI + uvicorn, the ASGI stack a coding agent reaches for as often as a plain
# stdlib server. `python:3.12-slim` rather than the `-alpine` the other Python samples here use:
# uvicorn's optional C extensions and FastAPI's own dependency tree ship manylinux wheels for
# glibc, not musl, so slim avoids a from-source compile during `pip install` and keeps the build
# fast.
#
# Pinned by digest. `python:3.12-slim` as of 20 September 2026.
FROM python@sha256:2f17fc044b579bab302c2e8054d3a686e2cb9a83de48e70534b94cd8ebbe06a9

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY app /app/app

RUN adduser --disabled-password --uid 10001 cell
USER cell

WORKDIR /app
EXPOSE 8080
# Shell form so ${PORT:-8080} actually expands -- the platform sets PORT=8080 for every cell, and
# the default here matches so a plain `docker run` behaves the same way.
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}"]

# hello-static: a directory of source with a Dockerfile, exactly the shape a partner's own app
# will have. Nothing here knows about AgentCell beyond reading the two env vars the platform sets
# (AGENTCELL_DATA, PORT, AGENTCELL_SAMPLE_MARKER) -- see infra/jobs/cell.nomad.hcl.tmpl.
#
# Pinned by digest, same rule as infra/images/deploy-fixture/Dockerfile: a tag is a mutable
# pointer. `python:3.12-alpine` as of 20 September 2026.
FROM python@sha256:c4634f578a412db396771b61b064c6e546c9d6414c7fb5b1b05d5871f1885f7b

COPY app.py /app/app.py
COPY static /app/static

# Non-root, same reasoning as the deploy fixture: a cell that runs as root would never notice a
# /data permission problem, and most well-built images do not run as root.
RUN adduser -D -u 10001 cell
USER cell

EXPOSE 8080
CMD ["python3", "-u", "/app/app.py"]

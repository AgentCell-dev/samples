# notes-sqlite: the volume contract, exercised with a real database. Same shape as
# infra/images/deploy-fixture/Dockerfile -- nothing here knows about AgentCell beyond the env vars
# the platform sets.
#
# Pinned by digest. `python:3.12-alpine` as of 20 September 2026.
FROM python@sha256:c4634f578a412db396771b61b064c6e546c9d6414c7fb5b1b05d5871f1885f7b

COPY app.py /app/app.py

RUN adduser -D -u 10001 cell
USER cell

EXPOSE 8080
CMD ["python3", "-u", "/app/app.py"]

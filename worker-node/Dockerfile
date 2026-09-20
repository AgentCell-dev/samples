# worker-node: an HTTP server plus a background loop, the shape an agent-built app usually has.
#
# Pinned by digest. `node:22-alpine` as of 20 September 2026.
FROM node@sha256:b6f26b36c8ff49624cfdac716b8ea1138d606df02586a77d364bb5536a634f85

COPY server.js /app/server.js

RUN adduser -D -u 10001 cell
USER cell

EXPOSE 8080
CMD ["node", "/app/server.js"]

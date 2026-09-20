# nextjs-app: the stack coding agents most often reach for. Two stages -- install and build with
# the full npm toolchain, then run on the same base with only what `next build` (output:
# "standalone" in next.config.js) actually needs: a pruned node_modules and a server.js
# entrypoint, no dev toolchain, no source.
#
# Pinned by digest, same rule as every other Dockerfile here. `node:22-alpine` as of 20 September
# 2026 -- the same digest worker-node already pins, since it is the same tag.
FROM node@sha256:b6f26b36c8ff49624cfdac716b8ea1138d606df02586a77d364bb5536a634f85 AS build
WORKDIR /src
COPY package.json ./
RUN npm install
COPY . .
RUN npm run build

FROM node@sha256:b6f26b36c8ff49624cfdac716b8ea1138d606df02586a77d364bb5536a634f85
WORKDIR /app
COPY --from=build /src/.next/standalone ./
COPY --from=build /src/.next/static ./.next/static
COPY --from=build /src/public ./public

RUN adduser -D -u 10001 cell
USER cell

# The standalone server.js reads PORT itself; the platform sets it to 8080 for every cell, and the
# default here matches so a plain `docker run` behaves the same way.
ENV PORT=8080
EXPOSE 8080
CMD ["node", "server.js"]

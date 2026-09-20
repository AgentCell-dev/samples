# echo-go: a compiled build, the sample that exercises a non-Python runtime and build-1's actual
# job -- compiling something, not just laying files into an image.
#
# Two stages: build with the Go toolchain, run on a bare alpine base with nothing but the static
# binary. Both pinned by digest, same rule as every other Dockerfile here.
# `golang:1.23-alpine` and `alpine:3.20` as of 20 September 2026.
FROM golang@sha256:383395b794dffa5b53012a212365d40c8e37109a626ca30d6151c8348d380b5f AS build
WORKDIR /src
COPY go.mod main.go ./
# CGO_ENABLED=0: a static binary that needs nothing from the runtime image's libc, so the runtime
# stage can be as bare as alpine's base without a glibc/musl mismatch.
RUN CGO_ENABLED=0 go build -o /echo-go .

FROM alpine@sha256:d9e853e87e55526f6b2917df91a2115c36dd7c696a35be12163d44e6e2a4b6bc
COPY --from=build /echo-go /app/echo-go

RUN adduser -D -u 10001 cell
USER cell

EXPOSE 8080
CMD ["/app/echo-go"]

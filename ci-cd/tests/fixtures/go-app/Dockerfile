FROM --platform=$BUILDPLATFORM golang:1.27.3-alpine AS builder
ARG TARGETOS
ARG TARGETARCH
WORKDIR /app
COPY go.mod ./
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -o /go-app .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /go-app /go-app
USER nonroot:nonroot
ENTRYPOINT ["/go-app"]

# Multi-stage build for Claude Code metrics exporter
# Stage 1: Build the Go binary
FROM golang:1.22-alpine AS builder

WORKDIR /build

# Copy go mod files
COPY go.mod go.sum* ./

# Download dependencies
RUN go mod download

# Copy source code
COPY *.go ./

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -o metrics-exporter \
    .

# Stage 2: Create minimal runtime image
FROM alpine:3.19

# Add ca-certificates for HTTPS (if needed in future)
RUN apk --no-cache add ca-certificates

# Create non-root user
RUN addgroup -g 10001 exporter && \
    adduser -D -u 10001 -G exporter exporter

WORKDIR /app

# Copy binary from builder
COPY --from=builder /build/metrics-exporter /app/metrics-exporter

# Run as non-root
USER exporter

# Expose metrics port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run the exporter
ENTRYPOINT ["/app/metrics-exporter"]

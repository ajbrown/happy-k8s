# Claude Code Metrics Exporter

A lightweight Prometheus metrics exporter that monitors Claude Code and Happy CLI activity to enable intelligent autoscaling of claude-agent pods.

## Overview

This exporter runs as a sidecar container alongside happy-k8s pods and exposes Prometheus metrics about agent activity. It watches filesystem activity in the `.claude` and `.happy` directories to determine whether an agent is actively processing commands or sitting idle.

## How It Works

The exporter monitors:

1. **Claude Code Session Files** - `~/.claude/projects/*/session-*.jsonl`
   - Tracks when sessions are created or modified
   - Counts total number of sessions

2. **Claude History** - `~/.claude/history.jsonl`
   - Monitors session metadata updates

3. **Happy Daemon Logs** - `~/.happy/logs/*.log`
   - Tracks Happy CLI activity and connections

Based on the most recent modification time across all these files, the exporter calculates:
- **Last activity timestamp** - Unix epoch seconds
- **Minutes since last activity** - Floating point minutes
- **Active/Idle status** - Boolean based on configurable idle timeout (default: 10 minutes)

## Metrics Exposed

All metrics are exposed on port 8080 at `/metrics` in Prometheus format.

### `claude_last_activity_timestamp_seconds`

Unix timestamp (seconds since epoch) of the last detected activity.

```prometheus
claude_last_activity_timestamp_seconds{pod="hoopgenie-happy-k8s-0",repository="hoopgenie"} 1736832400
```

### `claude_session_active`

Boolean indicator of whether the agent is active (1) or idle (0).

An agent is considered **active** if activity was detected within the last N minutes (configurable via `IDLE_TIMEOUT_MINUTES`, default 10).

```prometheus
claude_session_active{pod="hoopgenie-happy-k8s-0",repository="hoopgenie"} 1
```

### `claude_sessions_total`

Total number of Claude Code session files found in `~/.claude/projects/`.

```prometheus
claude_sessions_total{pod="hoopgenie-happy-k8s-0",repository="hoopgenie"} 42
```

### `claude_minutes_since_last_activity`

Floating point minutes since the last activity was detected.

```prometheus
claude_minutes_since_last_activity{pod="hoopgenie-happy-k8s-0",repository="hoopgenie"} 3.5
```

### `claude_exporter_healthy`

Health indicator for the exporter itself (1 = healthy, 0 = unhealthy).

```prometheus
claude_exporter_healthy{pod="hoopgenie-happy-k8s-0"} 1
```

## Configuration

Configuration is done via environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `CLAUDE_DIR` | Path to Claude Code directory | `/home/agent/.claude` |
| `HAPPY_DIR` | Path to Happy CLI directory | `/home/agent/.happy` |
| `IDLE_TIMEOUT_MINUTES` | Minutes of inactivity before marking as idle | `10` |
| `METRICS_PORT` | Port to expose metrics on | `8080` |
| `POD_NAME` | Kubernetes pod name (injected by downward API) | `unknown` |
| `REPOSITORY_NAME` | Repository name label for metrics | `unknown` |
| `UPDATE_INTERVAL_SECONDS` | How often to update metrics | `30` |

## Building

```bash
# Build locally
cd /Users/ajbrown/Projects/cybertron/workloads/happy-k8s/metrics-exporter
go mod download
go build -o metrics-exporter .

# Build Docker image
docker build -t ghcr.io/ajbrown/happy-k8s-metrics:latest .

# Push to registry
docker push ghcr.io/ajbrown/happy-k8s-metrics:latest
```

## Running Locally (for testing)

```bash
# Set required environment variables
export POD_NAME=test-pod
export REPOSITORY_NAME=test-repo
export CLAUDE_DIR=$HOME/.claude
export HAPPY_DIR=$HOME/.happy
export IDLE_TIMEOUT_MINUTES=5

# Run the exporter
go run main.go

# Or run the binary
./metrics-exporter
```

Then access metrics at http://localhost:8080/metrics

## Running in Kubernetes

The exporter is deployed as a sidecar container in the happy-k8s StatefulSet. See the Helm chart configuration:

```yaml
# In values.yaml
metricsExporter:
  enabled: true
  image:
    repository: ghcr.io/ajbrown/happy-k8s-metrics
    tag: latest
    pullPolicy: Always
  resources:
    requests:
      cpu: 10m
      memory: 16Mi
    limits:
      cpu: 50m
      memory: 64Mi
  idleTimeoutMinutes: 10
  updateIntervalSeconds: 30
```

## Endpoints

- `GET /metrics` - Prometheus metrics (text format)
- `GET /health` - Health check endpoint (returns 200 OK)
- `GET /` - HTML info page with links

## Architecture

The exporter uses:
- **Go 1.22** - Compiled to static binary
- **Prometheus client library** - Official Go client for metrics
- **Filesystem watching** - Polls files every N seconds (configurable)
- **Alpine Linux** - Minimal runtime container (~15MB total)

## Resource Usage

- **Memory**: ~10-20 MB
- **CPU**: <0.01 cores (mostly idle, spikes during updates)
- **Disk I/O**: Minimal (only stat() calls, no file reads)
- **Network**: HTTP server on one port

## Integration with HPA

The metrics exposed by this exporter are consumed by Prometheus, then translated to Kubernetes custom metrics via Prometheus Adapter. The HorizontalPodAutoscaler (HPA) uses these custom metrics to make scaling decisions.

See the main happy-k8s README for details on the autoscaling logic.

## Troubleshooting

### No metrics appearing

1. Check that the exporter container is running:
   ```bash
   kubectl logs <pod-name> -c metrics-exporter -n happy-k8s
   ```

2. Verify the metrics endpoint is accessible:
   ```bash
   kubectl port-forward <pod-name> 8080:8080 -n happy-k8s
   curl http://localhost:8080/metrics
   ```

3. Check that .claude and .happy directories are mounted correctly

### Always shows as idle

1. Verify `IDLE_TIMEOUT_MINUTES` is set correctly
2. Check that activity files exist and are being modified:
   ```bash
   kubectl exec <pod-name> -c happy-k8s -n happy-k8s -- \
     ls -ltr /home/agent/.claude/projects/
   ```

### Exporter crashes

1. Check resource limits aren't too restrictive
2. Verify file permissions on .claude and .happy directories
3. Check logs for specific errors

## Development

To modify the exporter:

1. Update `main.go` with your changes
2. Test locally with `go run main.go`
3. Update version/tag in Helm chart
4. Build and push new Docker image
5. Deploy updated Helm chart

## License

Part of the Cybertron homelab infrastructure.

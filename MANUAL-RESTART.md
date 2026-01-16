# Manual Restart Trigger

## Overview

In addition to automatic health-check based restarts, you can manually trigger a pod restart from your phone using the Happy mobile app. This is useful when:

- Claude becomes unresponsive but health checks haven't detected it yet
- You want to force a fresh start without waiting for auto-recovery
- You're troubleshooting and want to test restart behavior
- You want to apply configuration changes that require a restart

## How It Works

The system provides **multiple ways** to trigger a manual restart, giving you flexibility based on your situation:

### Method 1: Send `/restart-pod` Command via Happy App (Easiest)

**When to use**: Claude is somewhat responsive and can execute commands

1. Open the Happy mobile app
2. Send a message with the text: `/restart-pod`
3. Claude will process this (even if slow/unresponsive)
4. Watchdog detects the command in Claude's history
5. Pod gracefully restarts within ~30 seconds
6. Session continues with `--continue` flag

**Example**:
```
You: /restart-pod
Claude: [Processing may be slow if unresponsive]
[Pod restarts automatically]
[Session resumes with full history preserved]
```

### Method 2: Create Trigger File via Claude (Alternative)

**When to use**: You want to trigger restart through file system

1. Ask Claude to create a file: "Create a file at `/workspace/.restart-trigger`"
2. Watchdog detects the file
3. Pod restarts automatically

**Example**:
```
You: Please create an empty file at /workspace/.restart-trigger
Claude: [Creates file using Write tool]
[Pod restarts within 30 seconds]
```

### Method 3: HTTP Trigger (Advanced)

**When to use**: You have kubectl access or a custom tool

Port-forward to the restart trigger server and send POST request:

```bash
# Port-forward to the trigger server
kubectl port-forward <pod-name> -n happy-k8s 8888:8888

# In another terminal, trigger restart
curl -X POST http://localhost:8888/restart

# Response: {"status":"ok","message":"Restart triggered"}
```

### Method 4: Direct File Creation via kubectl (Emergency)

**When to use**: Claude is completely unresponsive and you have kubectl access

```bash
kubectl exec <pod-name> -n happy-k8s -- touch /workspace/.restart-trigger
```

## Architecture

### Components

1. **Restart Watchdog** (`/restart-watchdog.sh`)
   - Runs in background
   - Monitors for restart triggers every 30 seconds
   - Triggers graceful shutdown when detected

2. **Trigger Server** (`/restart-trigger-server.sh`) [Optional]
   - HTTP server on port 8888
   - Provides `/restart` endpoint
   - Useful for custom integrations

3. **Trigger Mechanisms**
   - File: `/workspace/.restart-trigger`
   - Command: `/restart-pod` in Claude history
   - HTTP: POST to `/restart` endpoint

### Restart Flow

```
┌─────────────────┐
│ Trigger Restart │
│ (any method)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Watchdog Detects│
│ (within 30s)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Send SIGTERM to │
│ Happy Daemon    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Wait 5s for     │
│ Graceful Save   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Exit Container  │
│ (kill PID 1)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Kubernetes      │
│ Restarts Pod    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Happy Starts    │
│ with --continue │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Session Resumes │
│ History Intact  │
└─────────────────┘
```

## Configuration

### Enable Restart Watchdog

Add to your `values.yaml`:

```yaml
restartWatchdog:
  # Enable the restart watchdog
  enabled: true
  # How often to check for restart triggers (seconds)
  checkInterval: 30
```

### Enable HTTP Trigger Server (Optional)

```yaml
restartTriggerServer:
  # Enable HTTP trigger server
  enabled: false  # Disabled by default
  # Port to listen on
  port: 8888
```

## Monitoring

### Check if Watchdog is Running

```bash
kubectl exec <pod-name> -n happy-k8s -- pgrep -f restart-watchdog
```

### View Restart History

```bash
kubectl exec <pod-name> -n happy-k8s -- cat /workspace/.restart-history.log
```

Example output:
```
[2026-01-16 17:30:45] Manual restart: Command trigger detected (/restart-pod in Claude history)
[2026-01-16 18:15:22] Manual restart: File trigger detected (/workspace/.restart-trigger)
```

### Check Trigger Server Status

```bash
# Port-forward
kubectl port-forward <pod-name> -n happy-k8s 8888:8888

# Check status
curl http://localhost:8888/status

# Response example:
# {"watchdog":true,"happy":true,"trigger":false}
```

## Troubleshooting

### Command Not Triggering Restart

**Problem**: Sent `/restart-pod` but nothing happened

**Solutions**:
1. Wait up to 30 seconds (watchdog check interval)
2. Verify watchdog is running: `kubectl exec <pod> -- pgrep -f restart-watchdog`
3. Check Claude history file exists: `kubectl exec <pod> -- ls ~/.claude/history.jsonl`
4. Try file-based trigger instead: Ask Claude to create `/workspace/.restart-trigger`

### Watchdog Not Running

**Problem**: `pgrep -f restart-watchdog` returns nothing

**Solutions**:
1. Check if disabled in values.yaml
2. View pod logs for startup errors: `kubectl logs <pod> -n happy-k8s`
3. Restart pod manually via kubectl: `kubectl delete pod <pod> -n happy-k8s`
4. Verify restart-watchdog.sh exists in image

### False Triggers

**Problem**: Pod restarting unexpectedly

**Causes**:
- Old trigger file not cleaned up
- `/restart-pod` command in old history

**Solutions**:
```bash
# Remove trigger file
kubectl exec <pod> -- rm -f /workspace/.restart-trigger

# Check for recent /restart-pod in history
kubectl exec <pod> -- tail -20 ~/.claude/history.jsonl | grep restart-pod
```

### HTTP Trigger Not Working

**Problem**: POST to `/restart` fails

**Solutions**:
1. Verify trigger server is enabled in values.yaml
2. Check server is running: `kubectl exec <pod> -- pgrep -f restart-trigger-server`
3. Verify port-forward: `curl -v http://localhost:8888/health`
4. Check server logs: `kubectl logs <pod> -n happy-k8s | grep "Restart trigger server"`

## Security Considerations

### Protecting Against Accidental Triggers

The watchdog only acts on **recent** triggers (within 5 minutes). This prevents:
- Old trigger files from causing restarts after pod recovery
- Historical `/restart-pod` commands from re-triggering on restart

### HTTP Trigger Security

If you enable the HTTP trigger server:

**⚠️ Important**: The server is **not authenticated** by default.

**Best Practices**:
1. **Don't expose publicly** - Use `kubectl port-forward` for access
2. **Firewall the port** - Only allow from trusted sources
3. **Consider disabling** - Use command/file triggers instead
4. **Add authentication** - Customize the script to require a token

**Example**: Add token auth to restart-trigger-server.sh:
```bash
# In restart-trigger-server.sh, check for Authorization header
AUTH_TOKEN="your-secret-token-here"
if ! echo "$REQUEST_LINE" | grep -q "Authorization: Bearer $AUTH_TOKEN"; then
    echo "HTTP/1.1 401 Unauthorized"
    # ... send error response
    continue
fi
```

## Advanced Use Cases

### Scheduled Restarts

Create a CronJob that triggers restart daily:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: restart-happy-pods
  namespace: happy-k8s
spec:
  schedule: "0 3 * * *"  # 3 AM daily
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: trigger
            image: curlimages/curl
            command:
            - /bin/sh
            - -c
            - |
              for pod in $(kubectl get pods -l app.kubernetes.io/name=happy-k8s -o name); do
                kubectl exec $pod -- touch /workspace/.restart-trigger
              done
          restartPolicy: OnFailure
```

### Custom Health Integration

Trigger restart from external monitoring:

```bash
#!/bin/bash
# External monitoring script

# Check if Happy is healthy via custom metrics
if ! check_happy_health; then
    # Trigger restart
    kubectl exec hoopgenie-happy-k8s-0 -n happy-k8s -- \
        touch /workspace/.restart-trigger

    # Send notification
    slack_notify "Triggered Happy pod restart due to health check failure"
fi
```

### Mobile App Integration (Future)

The command-based trigger (`/restart-pod`) is designed for eventual Happy app integration:

**Potential Feature**: Add a "Restart" button in the Happy mobile app that sends `/restart-pod` automatically.

## Best Practices

1. **Try command trigger first** - Use `/restart-pod` via Happy app (easiest)
2. **Use HTTP trigger cautiously** - Only enable if needed, keep secure
3. **Monitor restart frequency** - Frequent manual restarts indicate underlying issues
4. **Check logs before restart** - Capture state for debugging: `kubectl logs <pod>`
5. **Document why you restart** - Helps identify patterns

## Comparison with kubectl delete

| Method | Speed | Preserves Session | Requires kubectl | Safe |
|--------|-------|------------------|------------------|------|
| `/restart-pod` | ~30s | ✅ Yes | ❌ No | ✅ Yes |
| File trigger | ~30s | ✅ Yes | Optional | ✅ Yes |
| HTTP trigger | ~30s | ✅ Yes | Optional | ⚠️ If secured |
| `kubectl delete pod` | Immediate | ✅ Yes | ✅ Yes | ✅ Yes |

**Recommendation**: Use `/restart-pod` from Happy app for convenience, `kubectl delete pod` for emergencies.

## Next Steps

- See [HEALTHCHECK.md](./HEALTHCHECK.md) for automatic recovery
- See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues
- See [CONTRIBUTING.md](./CONTRIBUTING.md) to enhance restart mechanisms

## Feedback

Have ideas for better restart triggers? Open an issue: https://github.com/ajbrown/happy-k8s/issues

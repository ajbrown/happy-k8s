# Health Check & Auto-Recovery

## Overview

The happy-k8s deployment includes an enhanced health check system that automatically detects and recovers from unresponsive Claude sessions. This ensures your agents remain available even if Claude becomes stuck or unresponsive.

## How It Works

### Health Check Components

The health check (`/healthcheck.sh`) verifies multiple aspects of agent health:

1. **Happy Process Running**: Verifies the Happy daemon process is active
2. **Claude Responsiveness**: Detects if Claude processes are stuck (uninterruptible sleep)
3. **Activity Detection**: Monitors file modifications to detect recent activity
4. **Daemon Health**: Checks Happy daemon logs for critical errors
5. **Filesystem Access**: Ensures the container can write to the filesystem
6. **Working Directory**: Verifies the repository directory is accessible

### Automatic Restart Behavior

When the liveness probe fails:

1. **Kubernetes restarts the container** after 2 consecutive failures (4 minutes)
2. **Session continuity is preserved** via the `--continue` flag
3. **Claude session history is maintained** (stored in persistent volume)
4. **Happy reconnects** to the server with the same credentials
5. **Your conversation continues** from where it left off

### Configuration

```yaml
# values.yaml
healthCheck:
  # Max idle time before considering unhealthy (default: 30 minutes)
  maxIdleMinutes: 30
  # Enable activity checking in Happy logs (default: true)
  activityCheckEnabled: true

livenessProbe:
  initialDelaySeconds: 60    # Startup time
  periodSeconds: 120          # Check every 2 minutes
  timeoutSeconds: 30         # Health check timeout
  failureThreshold: 2        # Restart after 2 failures (4 min)
```

## Common Scenarios

### Scenario 1: Claude Becomes Unresponsive

**Symptoms**: Happy shows "online" but messages don't get responses

**What happens**:
1. Health check detects no recent activity (Claude history unchanged)
2. Health check finds Happy daemon has no connection activity in logs
3. After 4 minutes (2 failures @ 2 min interval), Kubernetes restarts container
4. Container starts with `--continue` flag
5. Happy reconnects and Claude resumes from previous session

**Result**: Service restored within ~5 minutes, session history preserved

### Scenario 2: Claude Process Crashes

**Symptoms**: Claude exits unexpectedly

**What happens**:
1. Health check detects Happy process is still running (healthy)
2. No recent Claude activity detected
3. Health check passes (Claude not required when idle)
4. Next message to Happy will spawn a new Claude session
5. Session continues from history due to `--continue` flag

**Result**: Transparent recovery, no restart needed

### Scenario 3: Happy Daemon Stuck

**Symptoms**: Happy process exists but logs show errors

**What happens**:
1. Health check finds critical errors in Happy daemon logs
2. Liveness probe fails immediately
3. Container restarts after 4 minutes
4. Fresh Happy daemon starts with preserved credentials

**Result**: Daemon recovered, sessions resume

### Scenario 4: Filesystem Issues

**Symptoms**: Cannot write to disk

**What happens**:
1. Health check fails to write test file
2. Liveness probe fails
3. Container restart triggers
4. Kubernetes may reschedule pod to healthy node

**Result**: Pod moved to healthy infrastructure

## Monitoring

### View Health Check Logs

```bash
# Get recent health check output
kubectl logs <pod-name> -n happy-k8s | grep "Health check"

# Watch health checks in real-time
kubectl logs <pod-name> -n happy-k8s -f | grep "Health check"
```

### Check Health Status

```bash
# Describe pod to see probe results
kubectl describe pod <pod-name> -n happy-k8s | grep -A 10 "Liveness"

# View events for restart history
kubectl get events -n happy-k8s --field-selector involvedObject.name=<pod-name>
```

### Health Check Indicators

- `✓` = Check passed
- `✗` = Check failed (will cause restart)
- `⚠` = Warning (non-fatal)

## Tuning for Your Workload

### More Aggressive Recovery (detect issues faster)

```yaml
livenessProbe:
  periodSeconds: 60          # Check every minute
  failureThreshold: 2        # Restart after 2 min
healthCheck:
  maxIdleMinutes: 15         # Shorter idle threshold
```

### More Lenient (avoid unnecessary restarts)

```yaml
livenessProbe:
  periodSeconds: 300         # Check every 5 minutes
  failureThreshold: 3        # Restart after 15 min
healthCheck:
  maxIdleMinutes: 60         # Longer idle threshold
  activityCheckEnabled: false # Disable log checking
```

### Disable Auto-Restart (not recommended)

```yaml
# Remove liveness probe entirely (keeps readiness probe)
livenessProbe: {}
```

## Session Continuity

The `--continue` flag is **enabled by default** (`continueSession: true`), which means:

- ✅ Conversation history is preserved across restarts
- ✅ Claude remembers previous context
- ✅ No loss of work when container restarts
- ✅ Seamless recovery from failures

To disable (not recommended):

```yaml
happy:
  continueSession: false  # Each restart starts fresh
```

## Best Practices

1. **Monitor restart frequency**: Frequent restarts indicate underlying issues
2. **Check Happy daemon logs**: Look for patterns before restarts
3. **Verify network connectivity**: Network issues can trigger false failures
4. **Test health check locally**: Run `/healthcheck.sh` manually in pod
5. **Adjust thresholds**: Tune based on your workload patterns

## Troubleshooting

### Health Check Always Failing

```bash
# Run health check manually
kubectl exec <pod-name> -n happy-k8s -- /healthcheck.sh

# Check Happy daemon logs
kubectl exec <pod-name> -n happy-k8s -- tail -100 ~/.happy/logs/daemon.log

# Verify Claude can start
kubectl exec <pod-name> -n happy-k8s -- pgrep -fa claude
```

### Container Restarting Too Often

```bash
# Check restart count
kubectl get pods -n happy-k8s

# View restart events
kubectl describe pod <pod-name> -n happy-k8s

# Possible causes:
# - Network issues preventing Happy from connecting
# - Insufficient resources (CPU/memory limits too low)
# - Filesystem full or slow
# - Happy daemon bugs

# Solutions:
# - Increase resource limits
# - Check PVC storage space
# - Lengthen health check intervals
# - Disable activity checking temporarily
```

### False Positives

If health checks fail but agent is actually healthy:

```yaml
# Increase failure threshold
livenessProbe:
  failureThreshold: 5  # Allow more failures before restart

# Increase timeout
livenessProbe:
  timeoutSeconds: 60   # Give health check more time

# Disable strict checks
healthCheck:
  activityCheckEnabled: false
```

## Next Steps

See [MANUAL-RESTART.md](./MANUAL-RESTART.md) for information about triggering manual restarts from the Happy mobile app.

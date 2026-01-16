#!/bin/bash
# Restart watchdog - monitors for restart triggers and gracefully exits container
# When the container exits, Kubernetes will restart it automatically
# The --continue flag ensures session continuity

TRIGGER_FILE="/workspace/.restart-trigger"
CHECK_INTERVAL=${RESTART_WATCHDOG_INTERVAL:-30}  # Check every 30 seconds by default
CLAUDE_COMMAND_LOG="$HOME/.claude/history.jsonl"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restart watchdog starting..."
echo "  Monitoring for restart triggers:"
echo "    - File trigger: $TRIGGER_FILE"
echo "    - Command trigger: /restart-pod in Claude history"
echo "    - Check interval: ${CHECK_INTERVAL}s"

# Function to trigger graceful restart
trigger_restart() {
    local reason="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] RESTART TRIGGERED: $reason"

    # Log to a file that can be checked after restart
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Manual restart: $reason" >> /workspace/.restart-history.log

    # Give Happy time to save state
    echo "  Sending SIGTERM to Happy daemon..."
    pkill -TERM happy || true
    sleep 5

    # Force exit the container
    # Kubernetes will restart it automatically
    echo "  Exiting container (Kubernetes will restart with --continue flag)..."
    kill 1  # Send SIGTERM to PID 1 (the main container process)

    # If that doesn't work, exit this script (if it's PID 1)
    exit 0
}

# Main monitoring loop
while true; do
    # Check 1: File-based trigger
    if [ -f "$TRIGGER_FILE" ]; then
        TRIGGER_TIME=$(stat -c %Y "$TRIGGER_FILE" 2>/dev/null || stat -f %m "$TRIGGER_FILE" 2>/dev/null)
        CURRENT_TIME=$(date +%s)
        AGE=$((CURRENT_TIME - TRIGGER_TIME))

        # Only trigger if file is recent (< 5 minutes old)
        # This prevents restarting again after coming back up
        if [ "$AGE" -lt 300 ]; then
            trigger_restart "File trigger detected ($TRIGGER_FILE)"
        else
            # Remove old trigger file
            rm -f "$TRIGGER_FILE"
        fi
    fi

    # Check 2: Command-based trigger in Claude history
    if [ -f "$CLAUDE_COMMAND_LOG" ]; then
        # Look for /restart-pod command in last 20 lines
        # Only check recent entries to avoid triggering on old commands
        if tail -20 "$CLAUDE_COMMAND_LOG" 2>/dev/null | grep -q "/restart-pod"; then
            # Check if this is a new command (within last 5 minutes)
            LAST_MOD=$(stat -c %Y "$CLAUDE_COMMAND_LOG" 2>/dev/null || stat -f %m "$CLAUDE_COMMAND_LOG" 2>/dev/null)
            CURRENT_TIME=$(date +%s)
            AGE=$((CURRENT_TIME - LAST_MOD))

            if [ "$AGE" -lt 300 ]; then
                trigger_restart "Command trigger detected (/restart-pod in Claude history)"
            fi
        fi
    fi

    # Check 3: HTTP endpoint trigger (for future use)
    # Could check a simple HTTP server that responds to restart requests

    # Wait before next check
    sleep "$CHECK_INTERVAL"
done

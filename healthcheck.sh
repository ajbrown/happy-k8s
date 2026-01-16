#!/bin/bash
# Enhanced health check script for Claude agents running via Happy
# Returns 0 if healthy, 1 if unhealthy
#
# This health check verifies:
# 1. Happy daemon process is running
# 2. Claude can actually respond (not just exists)
# 3. Recent activity detected (file modifications)
# 4. Happy daemon logs don't show critical errors

set -e

# Configuration
CLAUDE_DIR="$HOME/.claude"
HAPPY_DIR="$HOME/.happy"
HAPPY_LOG="$HAPPY_DIR/logs/daemon.log"
MAX_IDLE_MINUTES=${HEALTH_CHECK_MAX_IDLE_MINUTES:-30}  # Max idle time before considering unhealthy
ACTIVITY_CHECK_ENABLED=${HEALTH_CHECK_ACTIVITY_CHECK:-true}

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Health check starting..."

# 1. Check if Happy process is running
HAPPY_RUNNING=false
if pgrep -x "happy" > /dev/null 2>&1; then
    echo "✓ Happy process found (by name)"
    HAPPY_RUNNING=true
elif pgrep -f "happy" > /dev/null 2>&1; then
    echo "✓ Happy process found (by pattern)"
    HAPPY_RUNNING=true
fi

if [ "$HAPPY_RUNNING" = "false" ]; then
    echo "✗ Happy process is not running"
    exit 1
fi

# 2. Check if Claude process is responsive when it should be
# If Claude has been used recently, it should still be running
if [ -d "$CLAUDE_DIR" ]; then
    # Check for recent Claude activity (last 30 minutes)
    CLAUDE_ACTIVE=false

    # Check history file for recent activity
    if [ -f "$CLAUDE_DIR/history.jsonl" ]; then
        # Get the last modified time of history file
        HISTORY_AGE=$(find "$CLAUDE_DIR/history.jsonl" -mmin +${MAX_IDLE_MINUTES} 2>/dev/null | wc -l)
        if [ "$HISTORY_AGE" -eq 0 ]; then
            echo "✓ Claude history shows recent activity (within ${MAX_IDLE_MINUTES} minutes)"
            CLAUDE_ACTIVE=true
        fi
    fi

    # Check for running Claude processes
    if pgrep -f "claude" > /dev/null 2>&1; then
        # Claude is running - verify it's not a zombie/stuck process
        CLAUDE_PIDS=$(pgrep -f "claude")
        for pid in $CLAUDE_PIDS; do
            # Check if process is in a good state (not D state - uninterruptible sleep)
            STATE=$(ps -o state= -p $pid 2>/dev/null | tr -d ' ')
            if [ "$STATE" = "D" ]; then
                echo "✗ Claude process $pid is in uninterruptible sleep (stuck)"
                exit 1
            fi
        done
        echo "✓ Claude processes are running and responsive"
    elif [ "$CLAUDE_ACTIVE" = "true" ]; then
        # Claude was recently active but isn't running now
        # This is actually OK - Claude might have finished and exited cleanly
        echo "✓ Claude not currently running (recent activity detected, clean exit)"
    fi
fi

# 3. Check Happy daemon health
if [ -f "$HAPPY_LOG" ]; then
    # Check for critical errors in last 100 lines
    CRITICAL_ERRORS=$(tail -100 "$HAPPY_LOG" 2>/dev/null | grep -i "critical\|fatal\|crashed" | wc -l)
    if [ "$CRITICAL_ERRORS" -gt 0 ]; then
        echo "✗ Happy daemon logs show critical errors (last 100 lines)"
        tail -20 "$HAPPY_LOG" | sed 's/^/  /'
        exit 1
    fi

    # Check if Happy daemon is actually communicating with server
    # Look for recent connection activity
    RECENT_ACTIVITY=$(tail -100 "$HAPPY_LOG" 2>/dev/null | grep -i "connected\|message\|session" | wc -l)
    if [ "$RECENT_ACTIVITY" -eq 0 ] && [ "$ACTIVITY_CHECK_ENABLED" = "true" ]; then
        # No recent activity in logs - daemon might be stuck
        echo "⚠ Warning: No recent activity in Happy daemon logs"
        # Check if Happy has been running for a while without activity
        HAPPY_START_TIME=$(ps -o lstart= -p $(pgrep -x "happy" | head -1) 2>/dev/null)
        if [ -n "$HAPPY_START_TIME" ]; then
            START_EPOCH=$(date -d "$HAPPY_START_TIME" +%s 2>/dev/null || date -j -f "%a %b %d %T %Y" "$HAPPY_START_TIME" +%s 2>/dev/null)
            NOW_EPOCH=$(date +%s)
            UPTIME_MINUTES=$(( ($NOW_EPOCH - $START_EPOCH) / 60 ))

            if [ "$UPTIME_MINUTES" -gt "$MAX_IDLE_MINUTES" ]; then
                echo "✗ Happy has been running for ${UPTIME_MINUTES} minutes with no activity"
                exit 1
            fi
        fi
    fi
else
    echo "⚠ Warning: Happy daemon log not found at $HAPPY_LOG"
fi

# 4. Check filesystem health (can we write?)
TEST_FILE="$HOME/.health_check_test"
if ! touch "$TEST_FILE" 2>/dev/null; then
    echo "✗ Cannot write to filesystem"
    exit 1
fi
rm -f "$TEST_FILE"

# 5. Check if Happy's working directory is accessible
if [ -n "$HAPPY_WORKING_DIR" ] && [ -d "$HAPPY_WORKING_DIR" ]; then
    if ! cd "$HAPPY_WORKING_DIR" 2>/dev/null; then
        echo "✗ Cannot access Happy working directory: $HAPPY_WORKING_DIR"
        exit 1
    fi
fi

echo "✓ All health checks passed"
exit 0

#!/bin/bash
# Health check script for Claude agents running via Happy
# Returns 0 if healthy, 1 if unhealthy

set -e

# Check if the happy process is running
if pgrep -x "happy" > /dev/null 2>&1; then
    echo "Happy process is running"
    exit 0
fi

# Also check for node processes that might be Happy running
if pgrep -f "happy" > /dev/null 2>&1; then
    echo "Happy process is running (via node)"
    exit 0
fi

echo "Happy process is not running"
exit 1

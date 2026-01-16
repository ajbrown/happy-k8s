#!/bin/bash
# Simple HTTP server that listens for restart triggers
# Can be triggered via: curl -X POST http://localhost:8888/restart

TRIGGER_FILE="/workspace/.restart-trigger"
PORT=${RESTART_TRIGGER_PORT:-8888}

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restart trigger server starting on port $PORT..."

# Simple HTTP server using netcat
while true; do
    {
        read -r REQUEST_LINE
        read -r _  # Skip headers

        # Parse the request
        if echo "$REQUEST_LINE" | grep -q "POST /restart"; then
            # Trigger restart by creating the file
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restart request received via HTTP"
            touch "$TRIGGER_FILE"

            # Send HTTP response
            echo "HTTP/1.1 200 OK"
            echo "Content-Type: application/json"
            echo "Content-Length: 47"
            echo ""
            echo '{"status":"ok","message":"Restart triggered"}'
        elif echo "$REQUEST_LINE" | grep -q "GET /health"; then
            # Health check endpoint
            echo "HTTP/1.1 200 OK"
            echo "Content-Type: application/json"
            echo "Content-Length: 25"
            echo ""
            echo '{"status":"ok","healthy":true}'
        elif echo "$REQUEST_LINE" | grep -q "GET /status"; then
            # Status endpoint
            WATCHDOG_RUNNING=$(pgrep -f "restart-watchdog" > /dev/null && echo "true" || echo "false")
            HAPPY_RUNNING=$(pgrep -x "happy" > /dev/null && echo "true" || echo "false")
            TRIGGER_EXISTS=$([ -f "$TRIGGER_FILE" ] && echo "true" || echo "false")

            RESPONSE="{\"watchdog\":${WATCHDOG_RUNNING},\"happy\":${HAPPY_RUNNING},\"trigger\":${TRIGGER_EXISTS}}"
            LENGTH=${#RESPONSE}

            echo "HTTP/1.1 200 OK"
            echo "Content-Type: application/json"
            echo "Content-Length: $LENGTH"
            echo ""
            echo "$RESPONSE"
        else
            # 404 for unknown routes
            echo "HTTP/1.1 404 Not Found"
            echo "Content-Type: application/json"
            echo "Content-Length: 35"
            echo ""
            echo '{"status":"error","message":"Not found"}'
        fi
    } | nc -l -p "$PORT" -w 1 || true
done

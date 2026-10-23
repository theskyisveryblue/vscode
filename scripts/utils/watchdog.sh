#!/bin/bash

# Watchdog daemon - continuously monitors for stuck states and auto-recovers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VSCODE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$VSCODE_ROOT" || exit 1

CHECK_INTERVAL="${CHECK_INTERVAL:-60}"  # Check every 60 seconds
PIDFILE="$SCRIPT_DIR/.watchdog.pid"
LOGFILE="$SCRIPT_DIR/.watchdog.log"

start_watchdog() {
    if [ -f "$PIDFILE" ]; then
        OLD_PID=$(cat "$PIDFILE")
        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            echo "Watchdog is already running (PID: $OLD_PID)"
            return 1
        else
            rm -f "$PIDFILE"
        fi
    fi

    echo "Starting watchdog daemon..."
    echo "Check interval: ${CHECK_INTERVAL}s"
    echo "Log file: $LOGFILE"
    echo "PID file: $PIDFILE"

    cat > "$SCRIPT_DIR/.watchdog_loop.sh" <<EOF
#!/bin/bash
cd "$VSCODE_ROOT"
trap 'rm -f "$PIDFILE"; exit' TERM INT
echo \$\$ > "$PIDFILE"
echo "[\$(date +%Y-%m-%d\\ %H:%M:%S)] Watchdog started (interval: ${CHECK_INTERVAL}s)" >> "$LOGFILE"

while true; do
    CHECK_RESULT=\$("$SCRIPT_DIR/health_check.sh" check 2>&1)
    EXIT_CODE=\$?

    if [ \$EXIT_CODE -ne 0 ]; then
        echo "[\$(date +%Y-%m-%d\\ %H:%M:%S)] Health check failed:" >> "$LOGFILE"
        echo "\$CHECK_RESULT" >> "$LOGFILE"
        echo "[\$(date +%Y-%m-%d\\ %H:%M:%S)] Attempting auto-recovery..." >> "$LOGFILE"
        "$SCRIPT_DIR/health_check.sh" recover >> "$LOGFILE" 2>&1
    else
        echo "[\$(date +%Y-%m-%d\\ %H:%M:%S)] Health check passed" >> "$LOGFILE"
    fi

    sleep $CHECK_INTERVAL
done
EOF

    chmod +x "$SCRIPT_DIR/.watchdog_loop.sh"
    nohup "$SCRIPT_DIR/.watchdog_loop.sh" > /dev/null 2>&1 &

    sleep 2

    if [ -f "$PIDFILE" ]; then
        DAEMON_PID=$(cat "$PIDFILE")
        if ps -p "$DAEMON_PID" > /dev/null 2>&1; then
            echo "Watchdog started (PID: $DAEMON_PID)"
            echo "To stop: $0 stop"
            echo "To view logs: tail -f $LOGFILE"
        else
            echo "Failed to start watchdog"
            rm -f "$PIDFILE" "$SCRIPT_DIR/.watchdog_loop.sh"
            return 1
        fi
    else
        echo "Failed to start watchdog (PID file not created)"
        rm -f "$SCRIPT_DIR/.watchdog_loop.sh"
        return 1
    fi
}

stop_watchdog() {
    if [ ! -f "$PIDFILE" ]; then
        echo "Watchdog is not running"
        return 0
    fi

    PID=$(cat "$PIDFILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Stopping watchdog (PID: $PID)..."
        kill "$PID" 2>/dev/null || true
        sleep 1
        if ps -p "$PID" > /dev/null 2>&1; then
            kill -9 "$PID" 2>/dev/null || true
        fi
        rm -f "$PIDFILE" "$SCRIPT_DIR/.watchdog_loop.sh"
        echo "Stopped"
    else
        echo "Process not found, cleaning up..."
        rm -f "$PIDFILE" "$SCRIPT_DIR/.watchdog_loop.sh"
    fi
}

status_watchdog() {
    if [ ! -f "$PIDFILE" ]; then
        echo "Watchdog is not running"
        return 1
    fi

    PID=$(cat "$PIDFILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Watchdog is running (PID: $PID)"
        echo "Log file: $LOGFILE"
        echo "Check interval: ${CHECK_INTERVAL}s"
        return 0
    else
        echo "PID file exists but process is not running"
        rm -f "$PIDFILE"
        return 1
    fi
}

case "${1:-start}" in
    start)
        start_watchdog
        ;;
    stop)
        stop_watchdog
        ;;
    status)
        status_watchdog
        ;;
    restart)
        stop_watchdog
        sleep 1
        start_watchdog
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        echo ""
        echo "Environment variables:"
        echo "  CHECK_INTERVAL - Health check interval in seconds (default: 60)"
        exit 1
        ;;
esac






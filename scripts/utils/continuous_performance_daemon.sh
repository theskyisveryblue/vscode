#!/bin/bash

# Continuous Performance Monitoring Daemon
# Runs performance benchmarks periodically and tracks improvements/regressions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VSCODE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$VSCODE_ROOT" || exit 1

PYTHON="${PYTHON:-python3}"
INTERVAL="${INTERVAL:-60}"
PIDFILE="$SCRIPT_DIR/.continuous_performance.pid"
LOGFILE="$SCRIPT_DIR/.continuous_performance.log"

start_daemon() {
    if [ -f "$PIDFILE" ]; then
        OLD_PID=$(cat "$PIDFILE")
        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            echo "Continuous performance monitoring is already running (PID: $OLD_PID)"
            return 1
        else
            rm -f "$PIDFILE"
        fi
    fi

    echo "Starting continuous performance monitoring..."
    echo "Interval: ${INTERVAL}s"
    echo "Log file: $LOGFILE"
    echo "PID file: $PIDFILE"

    # Create daemon loop script
    cat > "$SCRIPT_DIR/.daemon_performance_loop.sh" <<EOF
#!/bin/bash
cd "$VSCODE_ROOT"
trap 'rm -f "$PIDFILE"; exit' TERM INT
echo \$\$ > "$PIDFILE"
echo "[\$(date +%Y-%m-%d\\ %H:%M:%S)] Performance monitoring started (interval: ${INTERVAL}s)" >> "$LOGFILE"
while true; do
    $PYTHON -B "$SCRIPT_DIR/continuous_performance.py" >> "$LOGFILE" 2>&1 || true
    sleep $INTERVAL
done
EOF

    chmod +x "$SCRIPT_DIR/.daemon_performance_loop.sh"
    nohup "$SCRIPT_DIR/.daemon_performance_loop.sh" > /dev/null 2>&1 &

    # Wait a moment for PID file to be created
    sleep 2

    if [ -f "$PIDFILE" ]; then
        DAEMON_PID=$(cat "$PIDFILE")
        if ps -p "$DAEMON_PID" > /dev/null 2>&1; then
            echo "Continuous performance monitoring started (PID: $DAEMON_PID)"
            echo "To stop: $0 stop"
            echo "To view logs: tail -f $LOGFILE"
        else
            echo "Failed to start daemon (process not running)"
            rm -f "$PIDFILE" "$SCRIPT_DIR/.daemon_performance_loop.sh"
            return 1
        fi
    else
        echo "Failed to start daemon (PID file not created)"
        rm -f "$SCRIPT_DIR/.daemon_performance_loop.sh"
        return 1
    fi
}

stop_daemon() {
    if [ ! -f "$PIDFILE" ]; then
        echo "Continuous performance monitoring is not running"
        return 0
    fi

    PID=$(cat "$PIDFILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Stopping continuous performance monitoring (PID: $PID)..."
        kill "$PID" 2>/dev/null || true
        sleep 1
        if ps -p "$PID" > /dev/null 2>&1; then
            kill -9 "$PID" 2>/dev/null || true
        fi
        rm -f "$PIDFILE" "$SCRIPT_DIR/.daemon_performance_loop.sh"
        echo "Stopped"
    else
        echo "Process not found, cleaning up..."
        rm -f "$PIDFILE" "$SCRIPT_DIR/.daemon_performance_loop.sh"
    fi
}

status_daemon() {
    if [ ! -f "$PIDFILE" ]; then
        echo "Continuous performance monitoring is not running"
        return 1
    fi

    PID=$(cat "$PIDFILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Continuous performance monitoring is running (PID: $PID)"
        echo "Log file: $LOGFILE"
        echo "History: $SCRIPT_DIR/.performance_history.json"
        return 0
    else
        echo "PID file exists but process is not running"
        rm -f "$PIDFILE"
        return 1
    fi
}

case "${1:-start}" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    status)
        status_daemon
        ;;
    restart)
        stop_daemon
        sleep 1
        start_daemon
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        echo ""
        echo "Environment variables:"
        echo "  INTERVAL - Benchmark interval in seconds (default: 60)"
        echo "  PYTHON   - Python interpreter (default: python3)"
        exit 1
        ;;
esac






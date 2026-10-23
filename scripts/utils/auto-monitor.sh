#!/bin/bash

# Auto-start monitoring utilities - runs continuously in background
# This script automatically starts relevant monitors when VS Code development starts

set -e

WORK_DIR="${1:-$(pwd)}"
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="/tmp/vscode-auto-monitor.pid"
LOG_DIR="/tmp/vscode-monitors"

mkdir -p "$LOG_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}Auto-monitor already running (PID: $OLD_PID)${NC}"
        exit 0
    else
        rm -f "$PID_FILE"
    fi
fi

echo -e "${CYAN}Starting auto-monitoring system...${NC}"

# Function to start a monitor in background
start_monitor() {
    local name=$1
    local script=$2
    local args=$3

    if [ -f "$UTILS_DIR/$script" ]; then
        nohup "$UTILS_DIR/$script" $args > "$LOG_DIR/${name}.log" 2>&1 &
        echo $! >> "$PID_FILE"
        echo -e "${GREEN}Started ${name} (PID: $!)${NC}"
    fi
}

# Main monitoring loop
monitor_loop() {
    cd "$WORK_DIR" || exit 1

    while true; do
        # Check if watch processes are running
        if pgrep -f "yarn watch" > /dev/null || pgrep -f "gulp.*watch" > /dev/null; then
            # Build is running - ensure build monitor is active
            if ! pgrep -f "watch-build.sh" > /dev/null; then
                echo -e "${CYAN}[$(date '+%H:%M:%S')] Build detected, starting build monitor...${NC}"
                # Use fast watch if available
                WATCH_CMD="yarn watch"
                if command -v yarn > /dev/null && yarn run 2>/dev/null | grep -q "watch-fast"; then
                    WATCH_CMD="yarn watch-fast"
                fi
                start_monitor "build-monitor" "watch-build.sh" "\"$WATCH_CMD\" \"$LOG_DIR/build.log\" \"$WORK_DIR\""
            fi

            # Monitor system resources if build is active
            if ! pgrep -f "monitor-system.sh" > /dev/null; then
                start_monitor "system-monitor" "monitor-system.sh" "5 \"node.*gulp|yarn.*watch\""
            fi
        else
            # No build running - clean up monitors
            pkill -f "watch-build.sh" 2>/dev/null || true
            pkill -f "monitor-system.sh" 2>/dev/null || true
        fi

        # Always keep log tailer available if log files exist
        if [ -f "$LOG_DIR/build.log" ] && ! pgrep -f "tail-logs.sh.*build.log" > /dev/null; then
            start_monitor "log-tailer" "tail-logs.sh" "\"$LOG_DIR/build.log\" \"\" \"error|warning|fail\""
        fi

        sleep 10
    done
}

# Start main loop in background
monitor_loop &
MAIN_PID=$!
echo $MAIN_PID > "$PID_FILE"

echo -e "${GREEN}Auto-monitor started (PID: $MAIN_PID)${NC}"
echo -e "${CYAN}Logs: ${LOG_DIR}${NC}"
echo -e "${YELLOW}Stop with: ./scripts/utils/stop-monitors.sh${NC}"

# Keep script running
wait $MAIN_PID






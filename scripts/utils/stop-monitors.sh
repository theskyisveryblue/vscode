#!/bin/bash

# Stop all auto-monitoring utilities

PID_FILE="/tmp/vscode-auto-monitor.pid"
LOG_DIR="/tmp/vscode-monitors"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Stopping all monitors...${NC}"

# Stop main monitor process
if [ -f "$PID_FILE" ]; then
    MAIN_PID=$(cat "$PID_FILE")
    if ps -p "$MAIN_PID" > /dev/null 2>&1; then
        kill "$MAIN_PID" 2>/dev/null || true
        echo -e "${GREEN}Stopped main monitor (PID: $MAIN_PID)${NC}"
    fi
    rm -f "$PID_FILE"
fi

# Stop all utility processes
pkill -f "watch-build.sh" 2>/dev/null && echo -e "${GREEN}Stopped build monitor${NC}" || true
pkill -f "monitor-system.sh" 2>/dev/null && echo -e "${GREEN}Stopped system monitor${NC}" || true
pkill -f "tail-logs.sh" 2>/dev/null && echo -e "${GREEN}Stopped log tailer${NC}" || true
pkill -f "watch-process.sh" 2>/dev/null && echo -e "${GREEN}Stopped process watcher${NC}" || true

echo -e "${GREEN}All monitors stopped${NC}"






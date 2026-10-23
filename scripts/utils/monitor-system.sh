#!/bin/bash

# Continuous system resource monitor
# Usage: ./monitor-system.sh [interval_seconds] [process_name]

INTERVAL="${1:-5}"
PROCESS_NAME="${2:-}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}System Resource Monitor${NC}"
echo -e "${CYAN}========================================${NC}"
[ -n "$PROCESS_NAME" ] && echo -e "Monitoring process: ${GREEN}${PROCESS_NAME}${NC}"
echo -e "Update interval: ${YELLOW}${INTERVAL}s${NC}"
echo -e "Press Ctrl+C to stop"
echo ""

cleanup() {
    echo -e "\n${GREEN}Stopped${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

while true; do
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}System Monitor - $(date '+%H:%M:%S')${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    # CPU and Memory
    echo -e "${BLUE}CPU & Memory:${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        top -l 1 | head -n 10 | tail -n 7
        echo ""
        echo -e "${BLUE}Memory:${NC}"
        vm_stat | head -n 10
    else
        # Linux
        top -bn1 | head -n 5
        echo ""
        echo -e "${BLUE}Memory:${NC}"
        free -h
    fi

    echo ""

    # Process-specific monitoring
    if [ -n "$PROCESS_NAME" ]; then
        echo -e "${BLUE}Process: ${PROCESS_NAME}${NC}"
        if pgrep -f "$PROCESS_NAME" > /dev/null; then
            PIDS=$(pgrep -f "$PROCESS_NAME")
            for PID in $PIDS; do
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    ps -p "$PID" -o pid,pcpu,pmem,time,command | tail -n 1
                else
                    ps -p "$PID" -o pid,pcpu,pmem,time,cmd | tail -n 1
                fi
            done
        else
            echo -e "${YELLOW}Process not found${NC}"
        fi
        echo ""
    fi

    # Disk usage
    echo -e "${BLUE}Disk Usage:${NC}"
    df -h . | tail -n 1
    echo ""

    sleep "$INTERVAL"
done






#!/bin/bash

# Continuous process monitor - watches a process and restarts it if it dies
# Usage: ./watch-process.sh <command> [restart_delay]

set -e

COMMAND="${1}"
RESTART_DELAY="${2:-2}"
LOG_FILE="${3:-/tmp/watch-process.log}"

if [ -z "$COMMAND" ]; then
    echo "Usage: $0 <command> [restart_delay] [log_file]"
    echo "Example: $0 'yarn watch-client' 2 /tmp/watch.log"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Continuous Process Monitor${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "Command: ${GREEN}${COMMAND}${NC}"
echo -e "Restart delay: ${YELLOW}${RESTART_DELAY}s${NC}"
echo -e "Log file: ${CYAN}${LOG_FILE}${NC}"
echo -e "Press Ctrl+C to stop"
echo ""

RESTART_COUNT=0

cleanup() {
    echo -e "\n${YELLOW}Stopping process monitor...${NC}"
    if [ ! -z "$PID" ]; then
        kill "$PID" 2>/dev/null || true
        wait "$PID" 2>/dev/null || true
    fi
    echo -e "${GREEN}Stopped${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

while true; do
    START_TIME=$(date +%s)
    echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} Starting: ${COMMAND}"

    # Run command in background and capture PID
    eval "$COMMAND" >> "$LOG_FILE" 2>&1 &
    PID=$!

    # Wait for process to finish
    wait $PID
    EXIT_CODE=$?

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    RESTART_COUNT=$((RESTART_COUNT + 1))

    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} Process exited successfully (ran for ${DURATION}s)"
        echo -e "${CYAN}Total restarts: ${RESTART_COUNT}${NC}"
        break
    else
        echo -e "${RED}[$(date '+%H:%M:%S')]${NC} Process crashed with exit code ${EXIT_CODE} (ran for ${DURATION}s)"
        echo -e "${YELLOW}Restarting in ${RESTART_DELAY} seconds... (restart #${RESTART_COUNT})${NC}"
        sleep "$RESTART_DELAY"
    fi
done






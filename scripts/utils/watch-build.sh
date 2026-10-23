#!/bin/bash

# Continuous build watcher - monitors build process and shows progress
# Usage: ./watch-build.sh [watch_command] [log_file]

WATCH_CMD="${1:-yarn watch}"
LOG_FILE="${2:-/tmp/vscode-build.log}"
WORK_DIR="${3:-$(pwd)}"

cd "$WORK_DIR" || exit 1

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Continuous Build Watcher${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "Command: ${GREEN}${WATCH_CMD}${NC}"
echo -e "Log file: ${BLUE}${LOG_FILE}${NC}"
echo -e "Working dir: ${BLUE}${WORK_DIR}${NC}"
echo ""

# Start build process in background
echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} Starting build process..."
eval "$WATCH_CMD" >> "$LOG_FILE" 2>&1 &
BUILD_PID=$!

echo -e "${GREEN}Build process started (PID: ${BUILD_PID})${NC}"
echo -e "${YELLOW}Monitoring logs... Press Ctrl+C to stop${NC}"
echo ""

# Monitor log file
LAST_LINE_COUNT=0
ERROR_COUNT=0
WARNING_COUNT=0

cleanup() {
    echo -e "\n${YELLOW}Stopping build watcher...${NC}"
    kill "$BUILD_PID" 2>/dev/null || true
    wait "$BUILD_PID" 2>/dev/null || true
    echo -e "${CYAN}Final stats:${NC}"
    echo -e "  Errors: ${RED}${ERROR_COUNT}${NC}"
    echo -e "  Warnings: ${YELLOW}${WARNING_COUNT}${NC}"
    echo -e "${GREEN}Stopped${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

while kill -0 "$BUILD_PID" 2>/dev/null; do
    if [ -f "$LOG_FILE" ]; then
        CURRENT_LINE_COUNT=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")

        if [ "$CURRENT_LINE_COUNT" -gt "$LAST_LINE_COUNT" ]; then
            NEW_LINES=$((CURRENT_LINE_COUNT - LAST_LINE_COUNT))

            # Show new lines with highlighting
            tail -n "$NEW_LINES" "$LOG_FILE" | while IFS= read -r line; do
                if echo "$line" | grep -qiE "error|fail|fatal"; then
                    echo -e "${RED}${line}${NC}"
                    ERROR_COUNT=$((ERROR_COUNT + 1))
                elif echo "$line" | grep -qiE "warning|warn"; then
                    echo -e "${YELLOW}${line}${NC}"
                    WARNING_COUNT=$((WARNING_COUNT + 1))
                elif echo "$line" | grep -qiE "compiled|success|done"; then
                    echo -e "${GREEN}${line}${NC}"
                else
                    echo "$line"
                fi
            done

            LAST_LINE_COUNT=$CURRENT_LINE_COUNT
        fi
    fi

    sleep 1
done

# Process finished
wait "$BUILD_PID"
EXIT_CODE=$?

echo ""
echo -e "${CYAN}========================================${NC}"
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}Build completed successfully${NC}"
else
    echo -e "${RED}Build failed with exit code ${EXIT_CODE}${NC}"
fi
echo -e "${CYAN}========================================${NC}"
echo -e "Total errors: ${RED}${ERROR_COUNT}${NC}"
echo -e "Total warnings: ${YELLOW}${WARNING_COUNT}${NC}"

exit $EXIT_CODE






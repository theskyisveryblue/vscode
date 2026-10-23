#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PID=${1:-19719}
LOG_FILE=${2:-/tmp/yarn-install.log}
WORK_DIR=${3:-/Users/theone/Documents/GitHub/vscode}

cd "$WORK_DIR" || exit 1

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Waiting for installation to complete...${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${BLUE}Process ID: ${PID}${NC}"
echo -e "${BLUE}Log file: ${LOG_FILE}${NC}"
echo -e "${BLUE}Working directory: ${WORK_DIR}${NC}"
echo ""

# Check if process exists
if ! ps -p "$PID" > /dev/null 2>&1; then
    echo -e "${YELLOW}Warning: Process ${PID} not found. It may have already finished.${NC}"
    echo ""
fi

# Start time for elapsed time calculation
START_TIME=$(date +%s)

# Function to show elapsed time
show_elapsed() {
    local current=$(date +%s)
    local elapsed=$((current - START_TIME))
    local minutes=$((elapsed / 60))
    local seconds=$((elapsed % 60))
    printf "${YELLOW}[%02d:%02d]${NC} " "$minutes" "$seconds"
}

# Function to show spinner
show_spinner() {
    local spinstr='|/-\'
    printf "${CYAN}%s${NC}\r" "${spinstr:i++%${#spinstr}:1}"
}

# Track last log line count to show only new lines
LAST_LINE_COUNT=0

# Main waiting loop with progress indication
ITERATION=0
while ps -p "$PID" > /dev/null 2>&1; do
    ITERATION=$((ITERATION + 1))

    # Every 5 iterations (10 seconds), show status and new log lines
    if [ $((ITERATION % 5)) -eq 0 ]; then
        show_elapsed
        echo -e "${BLUE}Still running...${NC} (checking every 2s)"

        # Show new log lines if log file exists
        if [ -f "$LOG_FILE" ]; then
            CURRENT_LINE_COUNT=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
            if [ "$CURRENT_LINE_COUNT" -gt "$LAST_LINE_COUNT" ]; then
                NEW_LINES=$((CURRENT_LINE_COUNT - LAST_LINE_COUNT))
                echo -e "${GREEN}New log entries (last ${NEW_LINES} lines):${NC}"
                tail -n "$NEW_LINES" "$LOG_FILE" 2>/dev/null | sed 's/^/  /'
                LAST_LINE_COUNT=$CURRENT_LINE_COUNT
                echo ""
            fi
        fi
    else
        # Show spinner on other iterations
        show_spinner
    fi

    sleep 2
done

# Clear spinner line
printf "\r\033[K"

# Final status
echo ""
echo -e "${GREEN}========================================${NC}"
show_elapsed
echo -e "${GREEN}INSTALL FINISHED${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Show final log output
if [ -f "$LOG_FILE" ]; then
    echo -e "${CYAN}Last 20 lines of log:${NC}"
    echo -e "${CYAN}----------------------------------------${NC}"
    tail -20 "$LOG_FILE"
    echo -e "${CYAN}----------------------------------------${NC}"
else
    echo -e "${YELLOW}Warning: Log file ${LOG_FILE} not found${NC}"
fi

echo ""
echo -e "${GREEN}Done!${NC}"






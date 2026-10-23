#!/bin/bash

# Continuous log tailer with filtering and highlighting
# Usage: ./tail-logs.sh <log_file> [filter_pattern] [highlight_pattern]

LOG_FILE="${1}"
FILTER="${2:-}"
HIGHLIGHT="${3:-error|warning|fail}"

if [ -z "$LOG_FILE" ] || [ ! -f "$LOG_FILE" ]; then
    echo "Usage: $0 <log_file> [filter_pattern] [highlight_pattern]"
    echo "Example: $0 /tmp/build.log 'compile|error' 'ERROR|WARN'"
    exit 1
fi

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Continuous Log Monitor${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "Log file: ${GREEN}${LOG_FILE}${NC}"
[ -n "$FILTER" ] && echo -e "Filter: ${YELLOW}${FILTER}${NC}"
[ -n "$HIGHLIGHT" ] && echo -e "Highlight: ${RED}${HIGHLIGHT}${NC}"
echo -e "Press Ctrl+C to stop"
echo ""

# Function to colorize output
colorize() {
    while IFS= read -r line; do
        if [ -n "$HIGHLIGHT" ] && echo "$line" | grep -qiE "$HIGHLIGHT"; then
            # Highlight errors/warnings in red/yellow
            if echo "$line" | grep -qiE "error|fail|fatal"; then
                echo -e "${RED}${line}${NC}"
            elif echo "$line" | grep -qiE "warning|warn"; then
                echo -e "${YELLOW}${line}${NC}"
            else
                echo -e "${GREEN}${line}${NC}"
            fi
        else
            echo "$line"
        fi
    done
}

# Tail with optional filter
if [ -n "$FILTER" ]; then
    tail -f "$LOG_FILE" 2>/dev/null | grep --line-buffered -iE "$FILTER" | colorize
else
    tail -f "$LOG_FILE" 2>/dev/null | colorize
fi






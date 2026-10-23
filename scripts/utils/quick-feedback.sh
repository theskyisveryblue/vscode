#!/bin/bash

# Quick feedback loop - compiles only changed files immediately
# Usage: ./quick-feedback.sh [file_pattern]

FILE_PATTERN="${1:-src/**/*.ts}"
WORK_DIR="${2:-$(pwd)}"

cd "$WORK_DIR" || exit 1

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Quick Feedback Mode${NC}"
echo -e "Watching: ${GREEN}${FILE_PATTERN}${NC}"
echo ""

# Use faster file watching with minimal delay
export VSCODE_FAST_WATCH=1

# Watch for changes and compile immediately
if command -v fswatch > /dev/null 2>&1; then
    # macOS - use fswatch (faster than gulp watch)
    echo -e "${GREEN}Using fswatch for ultra-fast file watching${NC}"
    fswatch -o -r --latency=0.1 "$FILE_PATTERN" | while read; do
        echo -e "${CYAN}[$(date '+%H:%M:%S')] File changed, compiling...${NC}"
        yarn compile 2>&1 | grep -E "error|Error|compiled|Compiled" | head -20
        echo -e "${GREEN}Ready${NC}\n"
    done
elif command -v inotifywait > /dev/null 2>&1; then
    # Linux - use inotifywait
    echo -e "${GREEN}Using inotifywait for fast file watching${NC}"
    while inotifywait -r -e modify,create,delete --format '%w%f' "$FILE_PATTERN" 2>/dev/null; do
        echo -e "${CYAN}[$(date '+%H:%M:%S')] File changed, compiling...${NC}"
        yarn compile 2>&1 | grep -E "error|Error|compiled|Compiled" | head -20
        echo -e "${GREEN}Ready${NC}\n"
    done
else
    # Fallback to gulp watch with minimal delay
    echo -e "${YELLOW}Using gulp watch (install fswatch/inotifywait for faster watching)${NC}"
    exec yarn watch
fi






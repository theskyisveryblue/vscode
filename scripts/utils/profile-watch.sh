#!/bin/bash

# Profile watch process performance - tracks file changes, compile times, etc.
# Usage: ./profile-watch.sh [duration_seconds]

DURATION="${1:-60}"
LOG_FILE="/tmp/vscode-watch-profile.log"
PROFILE_FILE="/tmp/vscode-watch-profile.json"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Watch Process Profiler${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "Duration: ${YELLOW}${DURATION}s${NC}"
echo -e "Log: ${BLUE}${LOG_FILE}${NC}"
echo ""

# Check if watch is running
if ! pgrep -f "yarn watch\|gulp.*watch" > /dev/null; then
    echo -e "${YELLOW}Warning: No watch process detected. Start 'yarn watch' first.${NC}"
    echo -e "${CYAN}Profiling system resources anyway...${NC}"
    echo ""
fi

START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION))

FILE_CHANGES=0
COMPILE_EVENTS=0
CPU_SAMPLES=()
MEM_SAMPLES=()

cleanup() {
    echo -e "\n${CYAN}Generating profile report...${NC}"

    # Calculate averages
    CPU_AVG=0
    MEM_AVG=0
    if [ ${#CPU_SAMPLES[@]} -gt 0 ]; then
        CPU_SUM=0
        MEM_SUM=0
        for cpu in "${CPU_SAMPLES[@]}"; do
            CPU_SUM=$((CPU_SUM + cpu))
        done
        for mem in "${MEM_SAMPLES[@]}"; do
            MEM_SUM=$((MEM_SUM + mem))
        done
        CPU_AVG=$((CPU_SUM / ${#CPU_SAMPLES[@]}))
        MEM_AVG=$((MEM_SUM / ${#MEM_SAMPLES[@]}))
    fi

    # Generate JSON report
    cat > "$PROFILE_FILE" <<EOF
{
  "duration_seconds": $DURATION,
  "file_changes_detected": $FILE_CHANGES,
  "compile_events": $COMPILE_EVENTS,
  "cpu_avg_percent": $CPU_AVG,
  "memory_avg_mb": $MEM_AVG,
  "cpu_samples": [$(IFS=','; echo "${CPU_SAMPLES[*]}")],
  "memory_samples": [$(IFS=','; echo "${MEM_SAMPLES[*]}")],
  "timestamp": "$(date -Iseconds)"
}
EOF

    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Profile Results${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "File changes: ${BLUE}${FILE_CHANGES}${NC}"
    echo -e "Compile events: ${BLUE}${COMPILE_EVENTS}${NC}"
    echo -e "Avg CPU: ${YELLOW}${CPU_AVG}%${NC}"
    echo -e "Avg Memory: ${YELLOW}${MEM_AVG}MB${NC}"
    echo ""
    echo -e "${GREEN}Full profile: ${PROFILE_FILE}${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

echo -e "${GREEN}Profiling... Press Ctrl+C to stop early${NC}"
echo ""

# Monitor loop
while [ $(date +%s) -lt $END_TIME ]; do
    # Sample CPU and memory
    if pgrep -f "node.*gulp\|yarn.*watch" > /dev/null; then
        PID=$(pgrep -f "node.*gulp\|yarn.*watch" | head -1)
        if [ -n "$PID" ]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                CPU=$(ps -p "$PID" -o %cpu= | tr -d ' ')
                MEM=$(ps -p "$PID" -o rss= | awk '{print $1/1024}')
            else
                CPU=$(ps -p "$PID" -o %cpu= | tr -d ' ')
                MEM=$(ps -p "$PID" -o rss= | awk '{print $1/1024}')
            fi
            CPU_SAMPLES+=(${CPU%.*})
            MEM_SAMPLES+=(${MEM%.*})
        fi
    fi

    # Count file changes in log (if log exists)
    if [ -f "$LOG_FILE" ]; then
        NEW_CHANGES=$(tail -100 "$LOG_FILE" | grep -c "File.*changed\|compiling\|Compiling" || echo "0")
        FILE_CHANGES=$((FILE_CHANGES + NEW_CHANGES))
    fi

    sleep 2
done

cleanup






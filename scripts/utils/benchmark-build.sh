#!/bin/bash

# Performance benchmarking for build/watch operations
# Usage: ./benchmark-build.sh [command] [iterations]

COMMAND="${1:-yarn compile}"
ITERATIONS="${2:-3}"
LOG_FILE="/tmp/vscode-build-benchmark.log"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Build Performance Benchmark${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "Command: ${GREEN}${COMMAND}${NC}"
echo -e "Iterations: ${YELLOW}${ITERATIONS}${NC}"
echo ""

TIMES=()
TOTAL_START=$(date +%s)

for i in $(seq 1 $ITERATIONS); do
    echo -e "${BLUE}Run ${i}/${ITERATIONS}...${NC}"

    # Clear caches if not first run
    if [ $i -gt 1 ]; then
        echo -e "${YELLOW}Clearing build cache...${NC}"
        rm -rf .build/electron/out 2>/dev/null || true
    fi

    RUN_START=$(date +%s%N)
    eval "$COMMAND" >> "$LOG_FILE" 2>&1
    EXIT_CODE=$?
    RUN_END=$(date +%s%N)

    if [ $EXIT_CODE -ne 0 ]; then
        echo -e "${RED}Build failed with exit code ${EXIT_CODE}${NC}"
        exit $EXIT_CODE
    fi

    RUN_TIME_MS=$(( (RUN_END - RUN_START) / 1000000 ))
    RUN_TIME_S=$(( RUN_TIME_MS / 1000 ))
    TIMES+=($RUN_TIME_MS)

    echo -e "${GREEN}Completed in ${RUN_TIME_S}.$(( (RUN_TIME_MS % 1000) / 100 ))s${NC}"
    echo ""
done

TOTAL_END=$(date +%s)
TOTAL_TIME=$((TOTAL_END - TOTAL_START))

# Calculate statistics
IFS=$'\n' SORTED=($(sort -n <<<"${TIMES[*]}"))
MIN=${SORTED[0]}
MAX=${SORTED[${#SORTED[@]}-1]}

# Calculate average
SUM=0
for time in "${TIMES[@]}"; do
    SUM=$((SUM + time))
done
AVG=$((SUM / ${#TIMES[@]}))

# Calculate median
MID=$(( ${#TIMES[@]} / 2 ))
if [ $((${#TIMES[@]} % 2)) -eq 0 ]; then
    MEDIAN=$(( (${SORTED[$MID-1]} + ${SORTED[$MID]}) / 2 ))
else
    MEDIAN=${SORTED[$MID]}
fi

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Benchmark Results${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "Total time: ${BLUE}$((TOTAL_TIME / 60))m $((TOTAL_TIME % 60))s${NC}"
echo ""
echo -e "Per-run times:"
for i in "${!TIMES[@]}"; do
    TIME_S=$(( ${TIMES[$i]} / 1000 ))
    TIME_MS=$(( ${TIMES[$i]} % 1000 ))
    echo -e "  Run $((i+1)): ${GREEN}${TIME_S}.${TIME_MS}s${NC}"
done
echo ""
echo -e "Statistics:"
echo -e "  Min:    ${GREEN}$((MIN / 1000)).$((MIN % 1000))s${NC}"
echo -e "  Max:    ${RED}$((MAX / 1000)).$((MAX % 1000))s${NC}"
echo -e "  Avg:    ${BLUE}$((AVG / 1000)).$((AVG % 1000))s${NC}"
echo -e "  Median: ${CYAN}$((MEDIAN / 1000)).$((MEDIAN % 1000))s${NC}"
echo ""

# Save results
RESULTS_FILE="/tmp/vscode-benchmark-results.json"
cat > "$RESULTS_FILE" <<EOF
{
  "command": "$COMMAND",
  "iterations": $ITERATIONS,
  "total_time_seconds": $TOTAL_TIME,
  "times_ms": [$(IFS=','; echo "${TIMES[*]}")],
  "min_ms": $MIN,
  "max_ms": $MAX,
  "avg_ms": $AVG,
  "median_ms": $MEDIAN,
  "timestamp": "$(date -Iseconds)"
}
EOF

echo -e "${GREEN}Results saved to: ${RESULTS_FILE}${NC}"






#!/bin/bash

# Health check and stuck state detection for continuous monitoring systems

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VSCODE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

STUCK_THRESHOLD=300  # 5 minutes without activity = stuck
LOG_STALE_THRESHOLD=120  # 2 minutes without log updates = stuck

check_process_health() {
    local pid=$1
    local name=$2
    local log_file=$3

    if ! ps -p "$pid" > /dev/null 2>&1; then
        echo -e "${RED}✗${NC} $name: Process not running (PID: $pid)"
        return 1
    fi

    # Check if log file exists and is being updated
    if [ -n "$log_file" ] && [ -f "$log_file" ]; then
        local last_modified=$(stat -f %m "$log_file" 2>/dev/null || stat -c %Y "$log_file" 2>/dev/null || echo "0")
        local now=$(date +%s)
        local age=$((now - last_modified))

        if [ $age -gt $LOG_STALE_THRESHOLD ]; then
            echo -e "${YELLOW}⚠${NC} $name: Log file stale (${age}s old, PID: $pid)"
            return 2
        fi
    fi

    # Check process CPU time - if it's been running but using no CPU, might be stuck
    local cpu_time_str=$(ps -p "$pid" -o cputime= 2>/dev/null || echo "0:0:0")
    local cpu_time=$(echo "$cpu_time_str" | awk -F: '{if(NF==3) print ($1*3600)+($2*60)+int($3); else if(NF==2) print ($1*60)+int($2); else print int($1)}' || echo "0")
    local runtime_str=$(ps -p "$pid" -o etime= 2>/dev/null || echo "0:0:0")
    local runtime=$(echo "$runtime_str" | awk -F: '{if(NF==3) print ($1*3600)+($2*60)+int($3); else if(NF==2) print ($1*60)+int($2); else print int($1)}' || echo "0")

    if [ "$runtime" -gt $STUCK_THRESHOLD ] && [ "$cpu_time" -lt 10 ]; then
        echo -e "${YELLOW}⚠${NC} $name: Low CPU usage for long runtime (${runtime}s, CPU: ${cpu_time}s, PID: $pid)"
        return 2
    fi

    echo -e "${GREEN}✓${NC} $name: Healthy (PID: $pid)"
    return 0
}

check_continuous_performance() {
    local pid_file="$SCRIPT_DIR/.continuous_performance.pid"
    local log_file="$SCRIPT_DIR/.continuous_performance.log"

    if [ ! -f "$pid_file" ]; then
        echo -e "${YELLOW}⚠${NC} Continuous performance: Not running (no PID file)"
        return 0
    fi

    local pid=$(cat "$pid_file" 2>/dev/null)
    if [ -z "$pid" ]; then
        echo -e "${RED}✗${NC} Continuous performance: Invalid PID file"
        return 1
    fi

    # For monitoring daemons, check if process is running and log is updating
    # Low CPU is expected (they sleep between checks)
    if ! ps -p "$pid" > /dev/null 2>&1; then
        echo -e "${RED}✗${NC} Continuous performance: Process not running (PID: $pid)"
        return 1
    fi

    # Check log activity - this is the real indicator of health
    if [ -f "$log_file" ]; then
        local last_modified=$(stat -f %m "$log_file" 2>/dev/null || stat -c %Y "$log_file" 2>/dev/null || echo "0")
        local now=$(date +%s)
        local age=$((now - last_modified))

        if [ $age -gt $LOG_STALE_THRESHOLD ]; then
            echo -e "${RED}✗${NC} Continuous performance: Log stale (${age}s old, PID: $pid)"
            return 1
        fi
    fi

    echo -e "${GREEN}✓${NC} Continuous performance: Healthy (PID: $pid)"
    return 0
}

check_auto_monitor() {
    local pid_file="$SCRIPT_DIR/../.vscode-auto-monitor.pid"
    local log_dir="/tmp/vscode-monitors"

    # Find auto-monitor processes
    local pids=$(pgrep -f "auto-monitor.sh" || true)

    if [ -z "$pids" ]; then
        echo -e "${YELLOW}⚠${NC} Auto-monitor: Not running"
        return 0
    fi

    local healthy=0
    local warnings=0
    for pid in $pids; do
        # For monitoring daemons, low CPU is expected (they sleep between checks)
        # Only check if process is running, not CPU usage
        if ps -p "$pid" > /dev/null 2>&1; then
            # Check if it's actually stuck by looking at log activity
            local log_updated=false
            if [ -d "$log_dir" ]; then
                local recent_log=$(find "$log_dir" -type f -mmin -5 2>/dev/null | head -1)
                if [ -n "$recent_log" ]; then
                    log_updated=true
                fi
            fi

            if [ "$log_updated" = true ] || [ -f "$pid_file" ]; then
                echo -e "${GREEN}✓${NC} Auto-monitor ($pid): Running"
                healthy=$((healthy + 1))
            else
                echo -e "${YELLOW}⚠${NC} Auto-monitor ($pid): Running but no recent activity"
                warnings=$((warnings + 1))
            fi
        else
            echo -e "${RED}✗${NC} Auto-monitor ($pid): Process not running"
        fi
    done

    # Only fail if no healthy processes, warnings are OK for monitoring daemons
    if [ $healthy -eq 0 ]; then
        return 1
    fi

    return 0
}

check_log_activity() {
    local log_file=$1
    local name=$2
    local threshold=${3:-$LOG_STALE_THRESHOLD}

    if [ ! -f "$log_file" ]; then
        echo -e "${YELLOW}⚠${NC} $name: Log file not found"
        return 1
    fi

    local last_modified=$(stat -f %m "$log_file" 2>/dev/null || stat -c %Y "$log_file" 2>/dev/null || echo "0")
    local now=$(date +%s)
    local age=$((now - last_modified))

    if [ $age -gt $threshold ]; then
        echo -e "${RED}✗${NC} $name: Log file not updated for ${age}s (threshold: ${threshold}s)"
        return 1
    fi

    # Check if log has recent activity (contains recent timestamps)
    local today=$(date +%Y-%m-%d)
    local hour_min=$(date +%H:%M)
    local recent_lines=$(tail -20 "$log_file" 2>/dev/null | grep -E "$today.*$hour_min" | wc -l || echo "0")
    if [ "$recent_lines" -eq 0 ] && [ $age -gt 60 ]; then
        echo -e "${YELLOW}⚠${NC} $name: No recent activity in log (${age}s old)"
        return 2
    fi

    echo -e "${GREEN}✓${NC} $name: Log active (updated ${age}s ago)"
    return 0
}

check_performance_history() {
    local history_file="$SCRIPT_DIR/.performance_history.json"

    if [ ! -f "$history_file" ]; then
        echo -e "${YELLOW}⚠${NC} Performance history: File not found"
        return 1
    fi

    # Check if history is being updated
    local last_modified=$(stat -f %m "$history_file" 2>/dev/null || stat -c %Y "$history_file" 2>/dev/null || echo "0")
    local now=$(date +%s)
    local age=$((now - last_modified))

    if [ $age -gt $STUCK_THRESHOLD ]; then
        echo -e "${RED}✗${NC} Performance history: Not updated for ${age}s"
        return 1
    fi

    # Check if history has recent entries
    local recent_count=$(python3 -B -c "import json, sys; h=json.load(open('$history_file')); from datetime import datetime, timedelta; recent=[e for e in h if (datetime.now() - datetime.fromisoformat(e['timestamp'])).total_seconds() < 600]; print(len(recent))" 2>/dev/null || echo "0")

    if [ "$recent_count" -eq 0 ]; then
        echo -e "${YELLOW}⚠${NC} Performance history: No recent entries (last update: ${age}s ago)"
        return 2
    fi

    echo -e "${GREEN}✓${NC} Performance history: Active ($recent_count recent entries)"
    return 0
}

detect_stuck_states() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Health Check & Stuck State Detection${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    local critical_issues=0
    local warnings=0

    # Check continuous performance daemon (critical - should be active)
    if ! check_continuous_performance; then
        critical_issues=$((critical_issues + 1))
    fi

    # Check auto-monitor (warnings OK - monitoring daemons can be idle)
    local auto_monitor_result
    if ! check_auto_monitor; then
        # Auto-monitor not running is a warning, not critical
        warnings=$((warnings + 1))
    fi

    # Check log activity (critical - logs should be updating)
    if ! check_log_activity "$SCRIPT_DIR/.continuous_performance.log" "Performance log"; then
        local log_result=$?
        if [ $log_result -eq 1 ]; then
            critical_issues=$((critical_issues + 1))
        else
            warnings=$((warnings + 1))
        fi
    fi

    # Check performance history (critical - should be updating)
    if ! check_performance_history; then
        local history_result=$?
        if [ $history_result -eq 1 ]; then
            critical_issues=$((critical_issues + 1))
        else
            warnings=$((warnings + 1))
        fi
    fi

    echo ""
    echo -e "${CYAN}========================================${NC}"

    if [ $critical_issues -eq 0 ]; then
        if [ $warnings -gt 0 ]; then
            echo -e "${GREEN}✓ All systems healthy${NC} (${warnings} warning(s) - non-critical)"
        else
            echo -e "${GREEN}✓ All systems healthy${NC}"
        fi
        return 0
    else
        echo -e "${RED}✗ Found $critical_issues critical issue(s)${NC}"
        if [ $warnings -gt 0 ]; then
            echo -e "${YELLOW}  (${warnings} warning(s))${NC}"
        fi
        return 1
    fi
}

auto_recover() {
    echo -e "${CYAN}Attempting auto-recovery...${NC}"

    # Restart continuous performance if stuck
    if ! check_continuous_performance > /dev/null 2>&1; then
        echo "Restarting continuous performance monitoring..."
        "$SCRIPT_DIR/continuous_performance_daemon.sh" stop 2>/dev/null || true
        sleep 1
        "$SCRIPT_DIR/continuous_performance_daemon.sh" start
    fi

    # Restart auto-monitor if stuck
    if ! check_auto_monitor > /dev/null 2>&1; then
        echo "Restarting auto-monitor..."
        "$SCRIPT_DIR/stop-monitors.sh" 2>/dev/null || true
        sleep 1
        "$SCRIPT_DIR/start-auto-monitor.sh" 2>/dev/null || true
    fi
}

case "${1:-check}" in
    check)
        detect_stuck_states
        ;;
    recover)
        detect_stuck_states
        echo ""
        auto_recover
        ;;
    *)
        echo "Usage: $0 {check|recover}"
        echo "  check   - Check for stuck states (default)"
        echo "  recover - Check and auto-recover from stuck states"
        exit 1
        ;;
esac






#!/bin/bash
cd "/Users/theone/Documents/GitHub/vscode"
trap 'rm -f "/Users/theone/Documents/GitHub/vscode/scripts/utils/.watchdog.pid"; exit' TERM INT
echo $$ > "/Users/theone/Documents/GitHub/vscode/scripts/utils/.watchdog.pid"
echo "[$(date +%Y-%m-%d\ %H:%M:%S)] Watchdog started (interval: 30s)" >> "/Users/theone/Documents/GitHub/vscode/scripts/utils/.watchdog.log"

while true; do
    CHECK_RESULT=$("/Users/theone/Documents/GitHub/vscode/scripts/utils/health_check.sh" check 2>&1)
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)] Health check failed:" >> "/Users/theone/Documents/GitHub/vscode/scripts/utils/.watchdog.log"
        echo "$CHECK_RESULT" >> "/Users/theone/Documents/GitHub/vscode/scripts/utils/.watchdog.log"
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)] Attempting auto-recovery..." >> "/Users/theone/Documents/GitHub/vscode/scripts/utils/.watchdog.log"
        "/Users/theone/Documents/GitHub/vscode/scripts/utils/health_check.sh" recover >> "/Users/theone/Documents/GitHub/vscode/scripts/utils/.watchdog.log" 2>&1
    else
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)] Health check passed" >> "/Users/theone/Documents/GitHub/vscode/scripts/utils/.watchdog.log"
    fi
    
    sleep 30
done

#!/bin/bash
cd "/Users/theone/Documents/GitHub/vscode"
trap 'rm -f "/Users/theone/Documents/GitHub/vscode/scripts/utils/.continuous_performance.pid"; exit' TERM INT
echo $$ > "/Users/theone/Documents/GitHub/vscode/scripts/utils/.continuous_performance.pid"
echo "[$(date +%Y-%m-%d\ %H:%M:%S)] Performance monitoring started (interval: 60s)" >> "/Users/theone/Documents/GitHub/vscode/scripts/utils/.continuous_performance.log"
while true; do
    python3 -B "/Users/theone/Documents/GitHub/vscode/scripts/utils/continuous_performance.py" >> "/Users/theone/Documents/GitHub/vscode/scripts/utils/.continuous_performance.log" 2>&1 || true
    sleep 60
done

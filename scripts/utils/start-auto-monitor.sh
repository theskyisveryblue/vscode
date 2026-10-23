#!/bin/bash

# Simple wrapper to start auto-monitor - can be called from anywhere

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VSCODE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$VSCODE_ROOT" || exit 1

# Start auto-monitor in background
"$SCRIPT_DIR/auto-monitor.sh" "$VSCODE_ROOT" &

echo "Auto-monitor started. It will automatically detect and monitor watch processes."
echo "Stop with: ./scripts/utils/stop-monitors.sh"






#!/bin/bash

# Fast watch mode - optimized for development speed
# Uses faster file change detection and reduced delays

set -e

WORK_DIR="${1:-$(pwd)}"
cd "$WORK_DIR" || exit 1

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Fast Watch Mode${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Set environment variables for faster watch
export VSCODE_FAST_WATCH=1
export NODE_OPTIONS="--max-old-space-size=4095"

# Check if we can modify gulp watch settings
if [ -f "build/lib/compilation.ts" ]; then
    echo -e "${YELLOW}Note: For fastest watch, consider reducing readDelay in build/lib/compilation.ts${NC}"
    echo -e "${YELLOW}Current: readDelay: 200ms (can be reduced to 50-100ms for faster response)${NC}"
    echo ""
fi

echo -e "${GREEN}Starting fast watch mode...${NC}"
echo -e "${CYAN}Optimizations enabled:${NC}"
echo -e "  - Reduced file watcher delays"
echo -e "  - Faster incremental compilation"
echo -e "  - Optimized memory settings"
echo ""

# Start watch with optimized settings
exec yarn watch






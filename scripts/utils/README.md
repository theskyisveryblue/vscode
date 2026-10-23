# Development Utilities

This folder contains reusable utility scripts for VS Code development workflow.

## Available Tools

### `wait-for-install.sh`

**Purpose:** Monitor a long-running installation process and show real-time progress.

**Usage:**
```bash
./scripts/utils/wait-for-install.sh [PID] [LOG_FILE] [WORK_DIR]
```

**Parameters:**
- `PID` (optional, default: 19719) - Process ID to monitor
- `LOG_FILE` (optional, default: /tmp/yarn-install.log) - Log file to tail
- `WORK_DIR` (optional, default: /Users/theone/Documents/GitHub/vscode) - Working directory

**Example:**
```bash
# Start yarn install in background and capture PID
yarn install > /tmp/yarn-install.log 2>&1 &
YARN_PID=$!

# Monitor it
./scripts/utils/wait-for-install.sh $YARN_PID /tmp/yarn-install.log
```

**Features:**
- Shows elapsed time
- Displays new log entries as they appear
- Shows spinner while waiting
- Displays final status and last 20 log lines when complete

**When to use:**
- Monitoring `yarn install` or `npm install`
- Watching any long-running build/install process
- When you need visibility into background processes

---

### `watch-process.sh`

**Purpose:** Continuously monitor a process and automatically restart it if it crashes.

**Usage:**
```bash
./scripts/utils/watch-process.sh <command> [restart_delay] [log_file]
```

**Parameters:**
- `command` (required) - Command to run and monitor
- `restart_delay` (optional, default: 2) - Seconds to wait before restarting
- `log_file` (optional, default: /tmp/watch-process.log) - Log file for output

**Example:**
```bash
# Monitor watch-client and restart if it crashes
./scripts/utils/watch-process.sh "yarn watch-client" 3 /tmp/watch-client.log
```

**Features:**
- Auto-restart on crash
- Restart counter
- Duration tracking
- Graceful shutdown with Ctrl+C

**When to use:**
- Keeping watch processes alive
- Development servers that need to stay running
- Any process that might crash and needs auto-recovery

---

### `tail-logs.sh`

**Purpose:** Continuously tail log files with filtering and syntax highlighting.

**Usage:**
```bash
./scripts/utils/tail-logs.sh <log_file> [filter_pattern] [highlight_pattern]
```

**Parameters:**
- `log_file` (required) - Log file to tail
- `filter_pattern` (optional) - Regex pattern to filter lines
- `highlight_pattern` (optional, default: error|warning|fail) - Pattern to highlight

**Example:**
```bash
# Tail build log with error highlighting
./scripts/utils/tail-logs.sh /tmp/build.log

# Tail only compile-related lines
./scripts/utils/tail-logs.sh /tmp/build.log "compile|error"

# Custom highlight pattern
./scripts/utils/tail-logs.sh /tmp/build.log "" "ERROR|WARN|SUCCESS"
```

**Features:**
- Real-time log streaming
- Pattern filtering
- Color-coded highlighting (red for errors, yellow for warnings)
- Line buffering for immediate output

**When to use:**
- Monitoring build/compile logs
- Debugging with filtered output
- Watching for specific log patterns

---

### `watch-build.sh`

**Purpose:** Monitor continuous build processes with progress tracking and error counting.

**Usage:**
```bash
./scripts/utils/watch-build.sh [watch_command] [log_file] [work_dir]
```

**Parameters:**
- `watch_command` (optional, default: yarn watch) - Build/watch command to run
- `log_file` (optional, default: /tmp/vscode-build.log) - Log file location
- `work_dir` (optional, default: current directory) - Working directory

**Example:**
```bash
# Monitor default watch command
./scripts/utils/watch-build.sh

# Monitor specific watch command
./scripts/utils/watch-build.sh "yarn watch-client" /tmp/client-build.log

# Monitor from specific directory
./scripts/utils/watch-build.sh "yarn watch-extensions" /tmp/ext.log /path/to/vscode
```

**Features:**
- Real-time log monitoring with color coding
- Error and warning counters
- Progress tracking
- Automatic cleanup on exit

**When to use:**
- Monitoring VS Code watch builds
- Tracking compilation progress
- Getting real-time feedback on build status

---

### `monitor-system.sh`

**Purpose:** Continuously monitor system resources (CPU, memory, disk) with optional process tracking.

**Usage:**
```bash
./scripts/utils/monitor-system.sh [interval_seconds] [process_name]
```

**Parameters:**
- `interval_seconds` (optional, default: 5) - Update interval in seconds
- `process_name` (optional) - Process name/pattern to monitor specifically

**Example:**
```bash
# General system monitoring (updates every 5s)
./scripts/utils/monitor-system.sh

# Faster updates (every 2s)
./scripts/utils/monitor-system.sh 2

# Monitor specific process
./scripts/utils/monitor-system.sh 3 "node.*gulp"
```

**Features:**
- CPU and memory usage
- Process-specific resource tracking
- Disk usage
- Cross-platform (macOS and Linux)
- Auto-refreshing display

**When to use:**
- Monitoring resource usage during builds
- Debugging performance issues
- Tracking specific process resource consumption

---

## Adding New Utilities

When adding a new utility script:

1. Place it in this `scripts/utils/` folder
2. Make it executable: `chmod +x scripts/utils/your-script.sh`
3. Add documentation to this README with:
   - Purpose
   - Usage syntax
   - Parameters
   - Examples
   - When to use it

---

### `auto-monitor.sh`

**Purpose:** Automatically starts and manages monitoring utilities when VS Code development processes are detected.

**Usage:**
```bash
./scripts/utils/auto-monitor.sh [work_dir]
```

**How it works:**
- Runs continuously in the background
- Automatically detects when `yarn watch` or `gulp watch` processes start
- Starts build monitor and system monitor when builds are active
- Cleans up monitors when builds stop
- Manages all monitoring processes automatically

**Auto-start integration:**
The auto-monitor can be started automatically with watch commands:
```bash
# Start watch with auto-monitoring
yarn watch:monitor

# Or start manually
./scripts/utils/start-auto-monitor.sh
```

**Stop monitoring:**
```bash
./scripts/utils/stop-monitors.sh
```

**Features:**
- Zero-configuration - just start it and it works
- Automatic process detection
- Resource-efficient (only monitors when needed)
- All logs saved to `/tmp/vscode-monitors/`

**When to use:**
- Always - it automatically manages itself
- When you want continuous monitoring without manual intervention
- For hands-off development workflow

---

### `start-auto-monitor.sh` / `stop-monitors.sh`

**Purpose:** Simple wrappers to start/stop the auto-monitoring system.

**Usage:**
```bash
# Start
./scripts/utils/start-auto-monitor.sh

# Stop
./scripts/utils/stop-monitors.sh
```

---

## For AI Assistants

This folder is a reference point for available development utilities. When suggesting solutions or automating tasks, check this folder first to see if a utility already exists that can help.

**Auto-monitoring:** The `auto-monitor.sh` script runs continuously and automatically starts relevant monitors when development processes are detected. It requires no manual intervention once started.

---

## Performance Tools

### `benchmark-build.sh`

**Purpose:** Measure and compare build performance across multiple runs.

**Usage:**
```bash
./scripts/utils/benchmark-build.sh [command] [iterations]
```

**Example:**
```bash
# Benchmark compile (3 runs)
./scripts/utils/benchmark-build.sh "yarn compile" 3
```

**Output:** Min, max, average, median times + JSON report

---

### `profile-watch.sh`

**Purpose:** Profile running watch processes to identify performance bottlenecks.

**Usage:**
```bash
./scripts/utils/profile-watch.sh [duration_seconds]
```

**Example:**
```bash
# Profile for 60 seconds
./scripts/utils/profile-watch.sh 60
```

**Tracks:** File changes, compile events, CPU/memory usage

---

### `fast-watch.sh`

**Purpose:** Start watch mode with optimized performance settings.

**Usage:**
```bash
./scripts/utils/fast-watch.sh
```

**Features:** Reduced delays, faster incremental compilation

---

See `PERFORMANCE.md` for detailed optimization guide.

---

## Health Check & Stuck State Detection

### `health_check.sh`

**Purpose:** Detects stuck states, hung processes, and health issues in continuous monitoring systems.

**Usage:**
```bash
# Check for stuck states
./scripts/utils/health_check.sh check

# Check and auto-recover
./scripts/utils/health_check.sh recover
```

**What it checks:**
- Process health (running, CPU usage, runtime)
- Log file activity (stale logs = stuck)
- Performance history updates
- Auto-detects hung processes

**Stuck state detection:**
- Log files not updated for > 2 minutes
- Processes running but using no CPU for > 5 minutes
- Performance history not updating

---

### `watchdog.sh`

**Purpose:** Continuous watchdog daemon that monitors health and auto-recovers from stuck states.

**Usage:**
```bash
# Start watchdog (checks every 60s)
./scripts/utils/watchdog.sh start

# Start with custom interval
CHECK_INTERVAL=30 ./scripts/utils/watchdog.sh start

# Check status
./scripts/utils/watchdog.sh status

# Stop
./scripts/utils/watchdog.sh stop
```

**Features:**
- Continuously monitors all systems
- Auto-detects stuck states
- Auto-recovers from issues
- Logs all health checks

**Output:**
- Logs: `scripts/utils/.watchdog.log`
- PID: `scripts/utils/.watchdog.pid`

---

---

## Continuous Performance Monitoring

### `continuous_performance.py`

**Purpose:** Continuously monitor build/watch performance over time, detect regressions, and track improvements.

**Usage:**
```bash
# Run once
python3 scripts/utils/continuous_performance.py

# Run continuously (daemon mode)
./scripts/utils/continuous_performance_daemon.sh start

# Check status
./scripts/utils/continuous_performance_daemon.sh status

# Stop
./scripts/utils/continuous_performance_daemon.sh stop
```

**Features:**
- Tracks performance metrics over time
- Detects regressions automatically
- Shows improvements and learning insights
- Saves history to `.performance_history.json`
- Runs continuously in background

**Configuration:**
```bash
# Set interval (default: 60 seconds)
INTERVAL=30 ./scripts/utils/continuous_performance_daemon.sh start

# Custom Python interpreter
PYTHON=python3.11 ./scripts/utils/continuous_performance_daemon.sh start
```

**What it monitors:**
- Watch process startup time
- Compile operation duration
- Gulp task listing performance
- Tracks improvements and regressions over time

---

### `continuous_performance_daemon.sh`

**Purpose:** Daemon wrapper to run continuous performance monitoring in the background.

**Usage:**
```bash
# Start (runs every 60s by default)
./scripts/utils/continuous_performance_daemon.sh start

# Start with custom interval
INTERVAL=30 ./scripts/utils/continuous_performance_daemon.sh start

# Check status
./scripts/utils/continuous_performance_daemon.sh status

# View logs
tail -f scripts/utils/.continuous_performance.log

# Stop
./scripts/utils/continuous_performance_daemon.sh stop

# Restart
./scripts/utils/continuous_performance_daemon.sh restart
```

**Output:**
- Logs: `scripts/utils/.continuous_performance.log`
- History: `scripts/utils/.performance_history.json`
- PID: `scripts/utils/.continuous_performance.pid`

---

---

## Fast Watch Mode

**New:** Optimized watch mode with reduced delays for faster development feedback.

**Usage:**
```bash
# Fast watch mode (50ms readDelay, 200ms debounce vs 200ms/500ms default)
yarn watch-fast

# Fast watch with auto-monitoring
yarn watch-fast:monitor
```

**Performance improvements:**
- 75% faster file change detection (50ms vs 200ms)
- 60% faster compilation start (200ms vs 500ms debounce)
- Same stability, faster feedback

**Files:**
- `build/gulpfile-fast.js` - Fast watch gulpfile
- `build/lib/util-fast.js` - Fast utility functions






# Health Check & Stuck State Detection - Explained

## What is a "Stuck State"?

A **stuck state** is when a process or system is:
- **Not making progress** - Should be working but isn't
- **Hung/frozen** - Process running but not responding
- **Dead but not cleaned up** - Process died but PID file still exists
- **Not updating** - Logs/history should be updating but aren't

## What the Health Check Does

The health check monitors your continuous systems to detect when they're stuck:

### 1. **Process Health**
- ✅ **Good**: Process is running
- ❌ **Stuck**: Process not running (should be)
- ⚠️ **Warning**: Process running but idle (normal for monitoring daemons)

### 2. **Log Activity**
- ✅ **Good**: Log file updated recently (< 2 minutes ago)
- ❌ **Stuck**: Log file not updated for > 2 minutes (process might be hung)

### 3. **Performance History**
- ✅ **Good**: History file has recent entries (< 10 minutes)
- ❌ **Stuck**: No recent entries (system not collecting data)

## Why Distinguish Critical vs Warnings?

### **Critical Issues** (Real Stuck States)
These mean something is **actually broken**:
- Process died unexpectedly
- Logs stopped updating (process hung)
- History not updating (data collection stopped)

**Action**: Auto-recover by restarting the process

### **Warnings** (Normal Behavior)
These are **expected** for monitoring systems:
- Low CPU usage (monitoring daemons sleep between checks)
- No recent activity (no builds running = nothing to monitor)

**Action**: Nothing needed - this is normal

## Example Scenarios

### Scenario 1: Everything Working ✅
```
✓ Continuous performance: Healthy (PID: 11140)
⚠ Auto-monitor: Running but no recent activity  ← Normal (no builds running)
✓ Performance log: Log active (updated 4s ago)
✓ Performance history: Active (37 recent entries)

Result: ✓ All systems healthy (warnings are non-critical)
```

### Scenario 2: Process Actually Stuck ❌
```
✗ Continuous performance: Log stale (300s old, PID: 11140)  ← STUCK!
⚠ Auto-monitor: Running but no recent activity
✗ Performance log: Log file not updated for 300s  ← STUCK!
✗ Performance history: Not updated for 300s  ← STUCK!

Result: ✗ Found 3 critical issue(s) → Auto-recover!
```

## How It Works

1. **Check every 60 seconds** (configurable)
2. **Detect stuck states** by checking:
   - Are processes running?
   - Are logs updating?
   - Is data being collected?
3. **Auto-recover** if critical issues found:
   - Restart stuck processes
   - Clean up stale PID files
   - Restart monitoring systems

## Usage

```bash
# Check health manually
./scripts/utils/health_check.sh check

# Check and auto-recover if needed
./scripts/utils/health_check.sh recover

# Run continuously (watchdog)
./scripts/utils/watchdog.sh start
```

## Why This Matters

Without stuck state detection:
- Processes can hang silently
- You don't know if monitoring is working
- Performance data stops being collected
- You waste time debugging "why isn't this working?"

With stuck state detection:
- Automatically detects when things break
- Auto-recovers from common issues
- You know immediately if something is wrong
- System is self-healing






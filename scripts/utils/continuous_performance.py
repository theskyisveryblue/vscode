#!/usr/bin/env python3
"""
Continuous Performance Monitoring for VS Code Build System
Tracks build/watch performance over time and detects regressions
"""

import json
import os
import subprocess
import time
import statistics
from datetime import datetime
from pathlib import Path

HISTORY_FILE = Path(__file__).parent / '.performance_history.json'
MAX_HISTORY = 1000

class PerformanceTracker:
    def __init__(self):
        self.history = self.load_history()

    def load_history(self):
        if HISTORY_FILE.exists():
            try:
                with open(HISTORY_FILE, 'r') as f:
                    return json.load(f)
            except:
                return []
        return []

    def save_history(self):
        # Keep only last MAX_HISTORY entries
        if len(self.history) > MAX_HISTORY:
            self.history = self.history[-MAX_HISTORY:]

        with open(HISTORY_FILE, 'w') as f:
            json.dump(self.history, f, indent=2)

    def add_measurement(self, operation, duration_ms, metadata=None):
        entry = {
            "timestamp": datetime.now().isoformat(),
            "operation": operation,
            "duration_ms": duration_ms,
            "metadata": metadata or {}
        }
        self.history.append(entry)
        self.save_history()

    def get_operation_stats(self, operation, last_n=20):
        """Get statistics for an operation from last N measurements"""
        recent = [e for e in self.history[-last_n:] if e["operation"] == operation]
        if not recent:
            return None

        durations = [e["duration_ms"] for e in recent]
        return {
            "count": len(durations),
            "mean": statistics.mean(durations),
            "median": statistics.median(durations),
            "min": min(durations),
            "max": max(durations),
            "stddev": statistics.stdev(durations) if len(durations) > 1 else 0
        }

    def detect_regression(self, operation, threshold=1.5):
        """Detect if performance has regressed (slower by threshold factor)"""
        stats = self.get_operation_stats(operation, last_n=10)
        if not stats or stats["count"] < 5:
            return None

        # Compare recent 5 vs previous 5
        recent = [e["duration_ms"] for e in self.history[-5:] if e["operation"] == operation]
        previous = [e["duration_ms"] for e in self.history[-10:-5] if e["operation"] == operation]

        if len(recent) < 3 or len(previous) < 3:
            return None

        recent_mean = statistics.mean(recent)
        previous_mean = statistics.mean(previous)

        if recent_mean > previous_mean * threshold:
            return {
                "operation": operation,
                "recent_mean": recent_mean,
                "previous_mean": previous_mean,
                "degradation": (recent_mean / previous_mean - 1) * 100
            }
        return None

    def detect_improvement(self, operation, threshold=0.9):
        """Detect if performance has improved (faster by threshold factor)"""
        recent = [e["duration_ms"] for e in self.history[-5:] if e["operation"] == operation]
        previous = [e["duration_ms"] for e in self.history[-10:-5] if e["operation"] == operation]

        if len(recent) < 3 or len(previous) < 3:
            return None

        recent_mean = statistics.mean(recent)
        previous_mean = statistics.mean(previous)

        if recent_mean < previous_mean * threshold:
            return {
                "operation": operation,
                "recent_mean": recent_mean,
                "previous_mean": previous_mean,
                "improvement": (1 - recent_mean / previous_mean) * 100
            }
        return None

def measure_operation(operation_name, command, work_dir):
    """Measure time for a single operation"""
    start = time.perf_counter()
    try:
        result = subprocess.run(
            command,
            shell=True,
            cwd=work_dir,
            capture_output=True,
            timeout=300,
            text=True
        )
        elapsed_ms = (time.perf_counter() - start) * 1000

        return {
            "success": result.returncode == 0,
            "duration_ms": elapsed_ms,
            "output": result.stdout[:500] if result.stdout else "",
            "error": result.stderr[:500] if result.stderr else ""
        }
    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "duration_ms": (time.perf_counter() - start) * 1000,
            "error": "Timeout"
        }
    except Exception as e:
        return {
            "success": False,
            "duration_ms": (time.perf_counter() - start) * 1000,
            "error": str(e)
        }

def run_benchmark(work_dir):
    """Run a full benchmark suite"""
    print("=" * 70)
    print("CONTINUOUS PERFORMANCE MONITORING")
    print("=" * 70)

    tracker = PerformanceTracker()
    history_count = len(tracker.history)
    print(f"History: {history_count} previous measurements\n")

    print("Measuring operations...")

    operations = [
        ("watch_startup", "timeout 3 yarn watch-client 2>&1 | head -1 || true", "Start watch process"),
        ("gulp_tasks_list", "node ./node_modules/gulp/bin/gulp.js --tasks 2>&1 | head -3 || true", "List gulp tasks"),
        ("fast_watch_available", "node --max-old-space-size=4095 ./node_modules/gulp/bin/gulp.js --gulpfile build/gulpfile-fast.js --tasks 2>&1 | grep -q watch-fast && echo 'OK' || echo 'FAIL'", "Fast watch mode available"),
    ]

    results = {}
    for op_name, command, description in operations:
        print(f"  {op_name:30s}: ", end="", flush=True)
        result = measure_operation(op_name, command, work_dir)
        duration_ms = result["duration_ms"]
        print(f"{duration_ms:7.3f}ms")

        tracker.add_measurement(op_name, duration_ms, {
            "description": description,
            "success": result["success"]
        })
        results[op_name] = duration_ms

    print("\n" + "=" * 70)
    print("PERFORMANCE ANALYSIS")
    print("=" * 70)
    print("\nOperation Statistics (last 20 measurements):\n")

    for op_name, _, _ in operations:
        stats = tracker.get_operation_stats(op_name, last_n=20)
        if stats:
            print(f"{op_name}:")
            print(f"  Count:    {stats['count']}")
            print(f"  Mean:     {stats['mean']:.3f}ms")
            print(f"  Median:   {stats['median']:.3f}ms")
            print(f"  Min:      {stats['min']:.3f}ms")
            print(f"  Max:      {stats['max']:.3f}ms")
            if stats['stddev'] > 0:
                print(f"  StdDev:   {stats['stddev']:.3f}ms")
            print()

    print("=" * 70)
    print("REGRESSION DETECTION")
    print("=" * 70)
    print()

    regressions = []
    for op_name, _, _ in operations:
        regression = tracker.detect_regression(op_name)
        if regression:
            regressions.append(regression)
            print(f"⚠ REGRESSION detected in {op_name}:")
            print(f"  Recent:   {regression['recent_mean']:.3f}ms")
            print(f"  Previous: {regression['previous_mean']:.3f}ms")
            print(f"  Degradation: {regression['degradation']:.1f}%")
            print()

    if not regressions:
        print("✓ No regressions detected\n")

    print("=" * 70)
    print("IMPROVEMENT DETECTION")
    print("=" * 70)
    print()

    improvements = []
    for op_name, _, _ in operations:
        improvement = tracker.detect_improvement(op_name)
        if improvement:
            improvements.append(improvement)
            print(f"✓ {op_name}: {improvement['improvement']:.1f}% faster")

    if improvements:
        print()
    else:
        print("No significant improvements detected\n")

    print("=" * 70)
    print("LEARNING INSIGHTS")
    print("=" * 70)
    print()

    total = len(tracker.history)
    print(f"Total measurements: {total}")
    print(f"Learning from {total} data points")

    if improvements:
        print("\n✓ Operations showing improvement:")
        for imp in improvements:
            print(f"  {imp['operation']}: {imp['improvement']:.1f}% faster")

    print("\n" + "=" * 70)
    print(f"✓ Benchmark complete. Data saved to {HISTORY_FILE}")
    print("=" * 70)

if __name__ == "__main__":
    work_dir = Path(__file__).parent.parent.parent
    run_benchmark(work_dir)






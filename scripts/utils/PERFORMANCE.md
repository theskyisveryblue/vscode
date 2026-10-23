# Performance Optimization Guide

This document outlines performance optimizations and monitoring tools for VS Code development.

## Performance Bottlenecks Identified

### 1. File Watch Delays
- **Current**: `readDelay: 200ms` in watch tasks
- **Impact**: 200ms delay before processing file changes
- **Optimization**: Can be reduced to 50-100ms for faster feedback

### 2. Debounce Delays
- **Current**: 500ms default debounce in incremental compilation
- **Impact**: Waits 500ms before starting compilation after file changes
- **Optimization**: Can be reduced to 200-300ms for faster builds

### 3. File Change Throttling
- **Current**: Processes 500 changes at once, then 200ms rest
- **Impact**: Can buffer up to 30,000 events
- **Status**: Already optimized, but can be tuned per use case

## Performance Monitoring Tools

### `benchmark-build.sh`
Measures build performance across multiple runs.

```bash
# Benchmark compile command (3 iterations)
./scripts/utils/benchmark-build.sh "yarn compile" 3

# Benchmark watch startup
./scripts/utils/benchmark-build.sh "yarn watch-client" 1
```

**Output**: Min, max, average, median times + JSON report

### `profile-watch.sh`
Profiles running watch processes to identify bottlenecks.

```bash
# Profile for 60 seconds
./scripts/utils/profile-watch.sh 60

# Profile for 5 minutes
./scripts/utils/profile-watch.sh 300
```

**Tracks**:
- File change frequency
- Compile event frequency
- CPU usage over time
- Memory usage over time

### `fast-watch.sh`
Optimized watch mode with faster settings.

```bash
./scripts/utils/fast-watch.sh
```

**Optimizations**:
- Reduced file watcher delays
- Faster incremental compilation
- Optimized memory settings

## Optimization Recommendations

### For Faster Development Feedback

1. **Reduce readDelay** (in `build/lib/compilation.ts`):
   ```typescript
   // Change from 200ms to 50-100ms
   const watchSrc = watch('src/**', { base: 'src', readDelay: 50 });
   ```

2. **Reduce debounce** (in `build/lib/util.ts`):
   ```typescript
   // Change from 500ms to 200-300ms
   const eventuallyRun = _debounce(() => { ... }, 200);
   ```

3. **Use fast-watch mode**:
   ```bash
   ./scripts/utils/fast-watch.sh
   ```

### For Production Builds

- Keep default delays (more stable)
- Use benchmark tools to measure impact
- Profile before/after optimizations

## Performance Targets

Based on analysis:
- **Watch startup**: < 5 seconds
- **Incremental compile**: < 2 seconds per file change
- **Full compile**: < 60 seconds (cold), < 30 seconds (warm)

## Monitoring in Production

The auto-monitor system automatically tracks:
- Build times
- System resources
- Error rates

Check logs at: `/tmp/vscode-monitors/`

## Continuous Monitoring

The continuous performance monitoring system runs automatically and tracks:
- Build/watch performance over time
- Regressions and improvements
- Learning insights from historical data

**Start continuous monitoring:**
```bash
./scripts/utils/continuous_performance_daemon.sh start
```

**View live metrics:**
```bash
tail -f scripts/utils/.continuous_performance.log
```

**Check status:**
```bash
./scripts/utils/continuous_performance_daemon.sh status
```

The system automatically detects when performance improves or degrades and provides insights.

## Next Steps

1. ✓ Run benchmarks to establish baseline
2. ✓ Apply optimizations incrementally
3. ✓ Measure impact with profiling tools
4. ✓ Document improvements
5. ✓ Continuous monitoring system running






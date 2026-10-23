# Performance Optimizations

This document tracks performance optimizations applied to the codebase, including references to other projects like Void Editor.

## Fast Watch Mode

Use `yarn watch-fast` for faster development builds with reduced debounce delays (200ms vs 500ms).

## Fast Launch Script

Use `./scripts/code-fast.sh` to skip prelaunch checks and monitoring for faster startup.

## Optimizations Applied (Void Editor Inspired)

### Memory Optimizations (30-40% reduction target)
- **Model Reference Collection**: Reduced maxLength from 80MB to 50MB (~37% reduction)
- **Model Reference Collection**: Reduced maxSize from 50 to 35 references (30% reduction)
- **Model Reference Collection**: Reduced maxAge from 3min to 2min (faster cleanup)
- **Undo Stack Memory**: Reduced from 20MB to 12MB (40% reduction)
- **Large File Thresholds**: More aggressive thresholds for better memory usage
  - Size threshold: 20MB → 15MB
  - Line count: 300K → 200K lines
  - Heap operation: 256M → 180M characters

### Build System
- **Fast watch mode**: Reduced debounce from 500ms to 150ms
- **Fast watch mode**: Reduced readDelay from 200ms to 30ms
- **Incremental compilation**: Faster file change detection
- **Skip prelaunch**: When Electron is already built (within 1 hour)

### Launch Scripts
- **code-fast.sh**: Skips VSCODE_SKIP_PRELAUNCH and VSCODE_SKIP_AUTO_MONITOR
- **Optimized code.sh**: Skips prelaunch if Electron was recently built

### Terminal
- **ghostty-web**: WASM-based terminal with better Unicode support and performance

## References

### Void Editor
- Repository: https://github.com/voideditor/void
- Performance claims: 30-40% less memory usage
- Fast Apply feature for code modifications
- Optimized for large files (up to 1,000 lines)

### Ghostty Web
- Repository: https://github.com/coder/ghostty-web
- WASM-compiled terminal emulator
- Better Unicode/complex script support
- API-compatible with xterm.js

## Future Optimizations

Consider implementing:
- Memory usage optimizations (reference Void's approach)
- Faster file watching (reduce readDelay further)
- Lazy loading of extensions
- Optimized rendering for large files


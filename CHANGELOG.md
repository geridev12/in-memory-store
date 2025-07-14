## 2.0.0

### Breaking Changes
- Constructor signatures updated with new optional parameters

### New Features
- LRU eviction with configurable memory limits
- Batch operations: `insertAll()` and `removeAll()`
- `forLargeDatasets()` constructor for high-performance use cases
- Memory usage statistics via `stats` getter
- `dispose()` method for cleanup

### Performance Improvements
- Single cleanup timer instead of per-entry timers
- Better performance for bulk operations
- Support for 100K+ entries

### Bug Fixes
- Fixed timer leaks with rapid insertions
- Improved expiry handling accuracy

## 1.0.1

- Improve key expiry mechanism by replacing Future.delayed with cancellable Timer.

## 1.0.0

- Initial Version of the library.

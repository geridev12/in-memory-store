import 'dart:async';
import 'dart:collection';

/// Entry wrapper for storing value with metadata
class _StoreEntry<V> {
  _StoreEntry(this.value, this.expiryTime, this.accessTime);

  final V value;
  final int? expiryTime; // null means no expiry
  int accessTime; // for LRU tracking
}

/// A class representing an in-memory key-value store with optional expiry.
///
/// This store allows you to insert, retrieve, and manage key-value pairs
/// in memory. It supports optional expiry for entries, where each entry
/// can be automatically removed after a specified duration.
///
/// Features for large datasets:
/// - Memory limits with LRU eviction
/// - Efficient expiry management with periodic cleanup
/// - Batch operations for better performance
/// - Memory usage tracking
class InMemoryStore<K extends Object, V extends Object?> {
  /// Private constructor for [InMemoryStore]. Used internally by the factory
  /// constructors.
  ///
  /// [expiryDuration]: The duration after which entries will expire, or null
  /// if no expiry is set.
  /// [maxEntries]: Maximum number of entries allowed. When exceeded,
  /// LRU entries are evicted.
  /// [cleanupInterval]: How often to run expired entry cleanup.
  InMemoryStore._({
    this.expiryDuration,
    this.maxEntries,
    this.cleanupInterval = const Duration(minutes: 5),
  }) {
    if (expiryDuration != null || maxEntries != null) {
      _startPeriodicCleanup();
    }
  }

  /// Factory constructor to create a store with a specified expiry duration.
  ///
  /// [expiryDuration]: The duration after which stored entries will expire.
  /// [maxEntries]: Maximum number of entries. When exceeded,
  /// LRU entries are evicted.
  /// [cleanupInterval]: How often to run cleanup of expired entries.
  /// Returns an instance of [InMemoryStore] with expiry enabled.
  factory InMemoryStore.withExpiry({
    required Duration expiryDuration,
    int? maxEntries,
    Duration cleanupInterval = const Duration(minutes: 5),
  }) {
    return InMemoryStore<K, V>._(
      expiryDuration: expiryDuration,
      maxEntries: maxEntries,
      cleanupInterval: cleanupInterval,
    );
  }

  /// Factory constructor to create a store with no expiry.
  ///
  /// [maxEntries]: Maximum number of entries. When exceeded,
  /// LRU entries are evicted.
  /// Returns an instance of [InMemoryStore] with no expiry set.
  factory InMemoryStore.persistent({int? maxEntries}) {
    return InMemoryStore<K, V>._(maxEntries: maxEntries);
  }

  /// Factory constructor to create a store optimized for large datasets.
  ///
  /// [maxEntries]: Maximum number of entries (required for large datasets).
  /// [expiryDuration]: Optional expiry duration for entries.
  /// [cleanupInterval]: How often to run cleanup operations.
  /// Returns an instance of [InMemoryStore] optimized for large datasets.
  factory InMemoryStore.forLargeDatasets({
    required int maxEntries,
    Duration? expiryDuration,
    Duration cleanupInterval = const Duration(minutes: 2),
  }) {
    return InMemoryStore<K, V>._(
      expiryDuration: expiryDuration,
      maxEntries: maxEntries,
      cleanupInterval: cleanupInterval,
    );
  }

  /// The duration after which entries in the store will expire, or null if no
  /// expiry is set.
  final Duration? expiryDuration;

  /// Maximum number of entries allowed in the store.
  final int? maxEntries;

  /// How often to run cleanup of expired entries.
  final Duration cleanupInterval;

  /// Internal storage for the store's key-value pairs.
  ///
  /// This is a [HashMap] that holds the actual data in memory.
  final HashMap<K, _StoreEntry<V>> _store = HashMap<K, _StoreEntry<V>>();

  /// Timer for periodic cleanup of expired entries.
  Timer? _cleanupTimer;

  /// Counter for access times (for LRU tracking).
  int _accessCounter = 0;

  /// Starts the periodic cleanup timer.
  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) => _performCleanup());
  }

  /// Performs cleanup of expired entries and LRU eviction if needed.
  void _performCleanup() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final keysToRemove = <K>[];

    // Remove expired entries
    if (expiryDuration != null) {
      for (final entry in _store.entries) {
        final storeEntry = entry.value;
        if (storeEntry.expiryTime != null && now > storeEntry.expiryTime!) {
          keysToRemove.add(entry.key);
        }
      }
    }

    // Remove expired entries
    for (final key in keysToRemove) {
      _store.remove(key);
    }

    // Perform LRU eviction if over limit
    _evictIfNeeded();
  }

  /// Evicts least recently used entries if over the limit.
  void _evictIfNeeded() {
    if (maxEntries == null || _store.length <= maxEntries!) return;

    final entries = _store.entries.toList()
      ..sort((a, b) => a.value.accessTime.compareTo(b.value.accessTime));

    final entriesToRemove = _store.length - maxEntries!;
    for (final entry in entries.take(entriesToRemove)) {
      _store.remove(entry.key);
    }
  }

  /// Inserts a key-value pair into the store.
  ///
  /// If an [expiryDuration] is set, schedules removal of the entry after the
  /// specified duration. If [maxEntries] is set, may evict LRU entries.
  ///
  /// [key]: The key to insert.
  /// [value]: The value to associate with the key.
  void insert(K key, V value) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiryTime =
        expiryDuration != null ? now + expiryDuration!.inMilliseconds : null;

    _store[key] = _StoreEntry<V>(value, expiryTime, ++_accessCounter);

    // Evict if necessary
    _evictIfNeeded();
  }

  /// Inserts multiple key-value pairs efficiently.
  ///
  /// [entries]: Map of key-value pairs to insert.
  void insertAll(Map<K, V> entries) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiryTime =
        expiryDuration != null ? now + expiryDuration!.inMilliseconds : null;

    for (final entry in entries.entries) {
      _store[entry.key] =
          _StoreEntry<V>(entry.value, expiryTime, ++_accessCounter);
    }

    // Evict if necessary
    _evictIfNeeded();
  }

  /// Retrieves the value associated with the given key.
  ///
  /// [key]: The key to look up.
  /// Returns the value associated with the key, or null if the key does not
  /// exist in the store or has expired.
  V? get(K key) {
    final entry = _store[key];
    if (entry == null) return null;

    // Check if expired
    if (entry.expiryTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now > entry.expiryTime!) {
        _store.remove(key);
        return null;
      }
    }

    // Update access time for LRU
    entry.accessTime = ++_accessCounter;
    return entry.value;
  }

  /// Checks if the store contains the given key.
  ///
  /// [key]: The key to check.
  /// Returns true if the key exists in the store and hasn't expired,
  /// false otherwise.
  bool containsKey(K key) {
    final entry = _store[key];
    if (entry == null) return false;

    // Check if expired
    if (entry.expiryTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now > entry.expiryTime!) {
        _store.remove(key);
        return false;
      }
    }

    return true;
  }

  /// Removes the entry associated with the given key.
  ///
  /// [key]: The key to remove.
  void remove(K key) {
    _store.remove(key);
  }

  /// Removes multiple keys efficiently.
  ///
  /// [keys]: Iterable of keys to remove.
  void removeAll(Iterable<K> keys) {
    for (final key in keys) {
      _store.remove(key);
    }
  }

  /// Clears all entries and cancels cleanup timer.
  ///
  /// This method removes all key-value pairs from the store and cancels the
  /// periodic cleanup timer.
  void clear() {
    _store.clear();
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _accessCounter = 0;
  }

  /// Manually triggers cleanup of expired entries.
  ///
  /// Returns the number of entries that were cleaned up.
  int cleanup() {
    final initialSize = _store.length;
    _performCleanup();
    return initialSize - _store.length;
  }

  /// Returns an iterable of all keys currently in the store.
  ///
  /// This provides a view of all keys stored in the in-memory store.
  /// Note: This may include keys with expired entries that
  /// haven't been cleaned up yet.
  Iterable<K> get keys => _store.keys;

  /// Returns an iterable of all values currently in the store.
  ///
  /// This provides a view of all values stored in the in-memory store.
  /// Note: This may include expired entries that haven't been cleaned up yet.
  Iterable<V> get values => _store.values.map((entry) => entry.value);

  /// Returns the current number of entries in the store.
  int get length => _store.length;

  /// Returns true if the store is empty.
  bool get isEmpty => _store.isEmpty;

  /// Returns true if the store is not empty.
  bool get isNotEmpty => _store.isNotEmpty;

  /// Returns memory usage statistics for the store.
  ///
  /// Returns a map containing information
  /// about memory usage and store statistics.
  Map<String, dynamic> get stats => {
        'entries': _store.length,
        'maxEntries': maxEntries,
        'hasExpiry': expiryDuration != null,
        'expiryDurationMs': expiryDuration?.inMilliseconds,
        'cleanupIntervalMs': cleanupInterval.inMilliseconds,
        'accessCounter': _accessCounter,
      };

  /// Disposes of the store and releases resources.
  ///
  /// Should be called when the store is no longer needed
  /// to prevent memory leaks.
  void dispose() {
    clear();
  }
}

import 'dart:async';
import 'dart:collection';

/// A class representing an in-memory key-value store with optional expiry.
/// 
/// This store allows you to insert, retrieve, and manage key-value pairs
/// in memory. It supports optional expiry for entries, where each entry
/// can be automatically removed after a specified duration.
class InMemoryStore<K extends Object, V extends Object?> {
  /// Private constructor for [InMemoryStore]. Used internally by the factory
  /// constructors.
  ///
  /// [expiryDuration]: The duration after which entries will expire, or null
  /// if no expiry is set.
  InMemoryStore._({this.expiryDuration});

  /// Factory constructor to create a store with a specified expiry duration.
  ///
  /// [expiryDuration]: The duration after which stored entries will expire.
  /// Returns an instance of [InMemoryStore] with expiry enabled.
  factory InMemoryStore.withExpiry({required Duration expiryDuration}) {
    return InMemoryStore<K, V>._(expiryDuration: expiryDuration);
  }

  /// Factory constructor to create a store with no expiry.
  ///
  /// Returns an instance of [InMemoryStore] with no expiry set.
  factory InMemoryStore.persistent() {
    return InMemoryStore<K, V>._();
  }

  /// The duration after which entries in the store will expire, or null if no
  /// expiry is set.
  final Duration? expiryDuration;

  /// Internal storage for the store's key-value pairs.
  ///
  /// This is a [HashMap] that holds the actual data in memory.
  final HashMap<K, V> _store = HashMap<K, V>();

  /// Internal timers to manage expiry for each key.
  ///
  /// This is a [HashMap] that maps keys to their respective [Timer] objects,
  /// which are used to schedule the removal of expired entries.
  final HashMap<K, Timer> _timers = HashMap<K, Timer>();

  /// Inserts a key-value pair into the store.
  ///
  /// If an [expiryDuration] is set, schedules removal of the entry after the
  /// specified duration. Any existing timer for the key is canceled before
  /// scheduling a new one.
  ///
  /// [key]: The key to insert.
  /// [value]: The value to associate with the key.
  void insert(K key, V value) {
    _store[key] = value;
    // Cancel any existing timer for this key.
    _timers[key]?.cancel();

    if (expiryDuration != null) {
      _timers[key] = Timer(expiryDuration!, () {
        _store.remove(key);
        _timers.remove(key);
      });
    }
  }

  /// Retrieves the value associated with the given key.
  ///
  /// [key]: The key to look up.
  /// Returns the value associated with the key, or null if the key does not
  /// exist in the store.
  V? get(K key) => _store[key];

  /// Checks if the store contains the given key.
  ///
  /// [key]: The key to check.
  /// Returns true if the key exists in the store, false otherwise.
  bool containsKey(K key) => _store.containsKey(key);

  /// Removes the entry associated with the given key.
  ///
  /// [key]: The key to remove.
  /// Cancels any associated expiry timer and removes the key-value pair from
  /// the store.
  void remove(K key) {
    _store.remove(key);
    _timers[key]?.cancel();
    _timers.remove(key);
  }

  /// Clears all entries and cancels all scheduled timers.
  ///
  /// This method removes all key-value pairs from the store and cancels any
  /// active timers for expiry.
  void clear() {
    _store.clear();
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// Returns an iterable of all keys currently in the store.
  ///
  /// This provides a view of all keys stored in the in-memory store.
  Iterable<K> get keys => _store.keys;

  /// Returns an iterable of all values currently in the store.
  ///
  /// This provides a view of all values stored in the in-memory store.
  Iterable<V> get values => _store.values;
}

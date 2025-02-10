import 'dart:collection';

/// A class representing an in-memory key-value store with optional expiry.
class InMemoryStore<K extends Object, V extends Object?> {
  /// Private constructor for [InMemoryStore]. Used internally by the factory
  /// constructors.
  InMemoryStore._({this.expiryDuration});

  /// Factory constructor to create a store with a specified expiry duration.
  ///
  /// - [expiryDuration]: The duration after which stored entries will expire.
  ///
  /// Example:
  /// ```dart
  /// var store = InMemoryStore<String, String>.withExpiry(expiryDuration: Duration(seconds: 5));/
  /// ```
  factory InMemoryStore.withExpiry({
    required Duration expiryDuration,
  }) {
    return InMemoryStore<K, V>._(
      expiryDuration: expiryDuration,
    );
  }

  /// Factory constructor to create a store with no expiry.
  ///
  /// This will create a persistent store where entries never expire unless
  /// explicitly removed.
  ///
  /// Example:
  /// ```dart
  /// var store = InMemoryStore<String, String>.persistent();
  /// ```
  factory InMemoryStore.persistent() {
    return InMemoryStore<K, V>._();
  }

  /// The duration after which entries in the store will expire, or null if no
  /// expiry is set.
  final Duration? expiryDuration;

  /// Internal storage for the store's key-value pairs.
  final HashMap<K, V> _store = HashMap<K, V>();

  /// Inserts a key-value pair into the store.
  ///
  /// - [key]: The key to store the value under.
  /// - [value]: The value to associate with the key.
  ///
  /// If an [expiryDuration] is set, the entry will be automatically removed
  /// after the specified duration.
  ///
  /// Example:
  /// ```dart
  /// store.insert('user1', 'John Doe');
  /// ```
  void insert(K key, V value) {
    _store[key] = value;

    // If expiry duration is set, schedule the removal of the entry.
    if (expiryDuration != null) {
      Future.delayed(
        expiryDuration!,
        () {
          if (_store.containsKey(key)) {
            _store.remove(key);
          }
        },
      );
    }
  }

  /// Retrieves the value associated with the given key.
  ///
  /// - [key]: The key whose associated value is to be retrieved.
  ///
  /// Returns the value associated with the key, or `null` if the key does not
  /// exist in the store.
  ///
  /// Example:
  /// ```dart
  /// var value = store.get('user1');
  /// ```
  V? get(K key) {
    return _store[key];
  }

  /// Checks if the store contains the given key.
  ///
  /// - [key]: The key to check.
  ///
  /// Returns `true` if the key is present in the store, or `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// bool hasKey = store.containsKey('user1');
  /// ```
  bool containsKey(K key) {
    return _store.containsKey(key);
  }

  /// Removes the entry associated with the given key.
  ///
  /// - [key]: The key of the entry to remove.
  ///
  /// Example:
  /// ```dart
  /// store.remove('user1');
  /// ```
  void remove(K key) {
    _store.remove(key);
  }

  /// Clears all entries from the store.
  ///
  /// This will remove all key-value pairs stored in the store.
  ///
  /// Example:
  /// ```dart
  /// store.clear();
  /// ```
  void clear() {
    _store.clear();
  }

  /// An iterable of all the keys currently stored in the store.
  ///
  /// Example:
  /// ```dart
  /// var keys = store.keys;
  /// ```
  Iterable<K> get keys => _store.keys;

  /// An iterable of all the values currently stored in the store.
  ///
  /// Example:
  /// ```dart
  /// var values = store.values;
  /// ```
  Iterable<V> get values => _store.values;
}

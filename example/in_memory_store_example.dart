// ignore_for_file: avoid_print

import 'package:in_memory_store/in_memory_store.dart';

void main() {
  print('=== Basic Usage ===');
  basicUsage();

  print('\n=== Large Dataset Usage ===');
  largeDatasetUsage();

  print('\n=== Advanced Features ===');
  advancedFeatures();
}

void basicUsage() {
  // Cache with expiry
  final cacheWithExpiry = InMemoryStore<String, String>.withExpiry(
    expiryDuration: const Duration(seconds: 5),
  )..insert('user1', 'John Doe');
  print('Inserted: user1 -> John Doe');

  Future<void>.delayed(
    const Duration(seconds: 6),
    () {
      print('Value after expiry: ${cacheWithExpiry.get('user1')}');
    },
  );

  // Persistent cache
  final persistentCache = InMemoryStore<String, int>.persistent()
    ..insert('score', 100);
  print('Inserted: score -> 100');
  print('Retrieved: score -> ${persistentCache.get('score')}');

  print('Contains key "score": ${persistentCache.containsKey('score')}');

  persistentCache.dispose();
}

void largeDatasetUsage() {
  // Optimized store for large datasets
  final largeStore = InMemoryStore<int, String>.forLargeDatasets(
    maxEntries: 100000,
    expiryDuration: const Duration(minutes: 30),
    cleanupInterval: const Duration(minutes: 5),
  );

  print('Creating large dataset store...');

  // Batch insert for better performance
  final batchData = <int, String>{};
  for (var i = 0; i < 10000; i++) {
    batchData[i] = 'user_data_$i';
  }

  final stopwatch = Stopwatch()..start();
  largeStore.insertAll(batchData);
  stopwatch.stop();

  print('Batch inserted 10,000 entries in ${stopwatch.elapsedMilliseconds}ms');
  print('Store stats: ${largeStore.stats}');

  // Test retrieval performance
  final retrievalStopwatch = Stopwatch()..start();
  for (var i = 0; i < 1000; i++) {
    largeStore.get(i);
  }
  retrievalStopwatch.stop();

  print(
    'Retrieved 1,000 entries in ${retrievalStopwatch.elapsedMilliseconds}ms',
  );

  largeStore.dispose();
}

void advancedFeatures() {
  // Store with memory limits and LRU eviction
  final limitedStore = InMemoryStore<String, String>.persistent(maxEntries: 5)

    // Fill beyond capacity
    ..insertAll({
      'key1': 'value1',
      'key2': 'value2',
      'key3': 'value3',
      'key4': 'value4',
      'key5': 'value5',
    });

  print('Store length after filling to capacity: ${limitedStore.length}');

  // Access some keys to make them recently used
  limitedStore
    ..get('key1')
    ..get('key2')

    // Add more entries - should trigger LRU eviction
    ..insertAll({
      'key6': 'value6',
      'key7': 'value7',
    });

  print('Store length after adding more entries: ${limitedStore.length}');
  print('Recently used key1 still exists: ${limitedStore.containsKey('key1')}');
  print('Old key3 evicted: ${!limitedStore.containsKey('key3')}');

  // Manual cleanup
  final cleanedUp = limitedStore.cleanup();
  print('Manual cleanup removed $cleanedUp entries');

  // Batch removal
  limitedStore.removeAll(['key1', 'key2']);
  print('After batch removal, length: ${limitedStore.length}');

  limitedStore.dispose();
}

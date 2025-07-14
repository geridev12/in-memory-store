// ignore_for_file: unnecessary_statements

import 'dart:collection';
import 'package:in_memory_store/in_memory_store.dart';
import 'package:test/test.dart';

void main() {
  group('Performance Tests', () {
    test('Compare HashMap vs Map performance', () {
      const iterations = 100000;
      final normalMap = <String, int>{};
      final hashMap = HashMap<String, int>();

      final mapStopwatch = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        normalMap[r'key$i'] = i;
      }
      mapStopwatch.stop();
      final mapInsertionTime = mapStopwatch.elapsedMicroseconds;

      final hashMapStopwatch = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        hashMap[r'key$i'] = i;
      }
      hashMapStopwatch.stop();
      final hashMapInsertionTime = hashMapStopwatch.elapsedMicroseconds;

      expect(hashMapInsertionTime, lessThan(mapInsertionTime));

      mapStopwatch
        ..reset()
        ..start();
      for (var i = 0; i < iterations; i++) {
        normalMap[r'key$i'];
      }
      mapStopwatch.stop();
      final mapRetrievalTime = mapStopwatch.elapsedMicroseconds;

      hashMapStopwatch
        ..reset()
        ..start();
      for (var i = 0; i < iterations; i++) {
        hashMap[r'key$i'];
      }
      hashMapStopwatch.stop();
      final hashMapRetrievalTime = hashMapStopwatch.elapsedMicroseconds;

      expect(hashMapRetrievalTime, lessThan(mapRetrievalTime));
    });

    test('InMemoryStore single operations performance', () {
      const iterations = 50000;
      final store = InMemoryStore<String, int>.persistent();

      final insertStopwatch = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        store.insert('key$i', i);
      }
      insertStopwatch.stop();

      final retrievalStopwatch = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        store.get('key$i');
      }
      retrievalStopwatch.stop();

      expect(insertStopwatch.elapsedMicroseconds, lessThan(5000000));
      expect(retrievalStopwatch.elapsedMicroseconds, lessThan(5000000));
    });

    test('InMemoryStore batch operations performance', () {
      const batchSize = 10000;
      final store = InMemoryStore<String, int>.persistent();

      final batchData = <String, int>{};
      for (var i = 0; i < batchSize; i++) {
        batchData['key$i'] = i;
      }

      final batchInsertStopwatch = Stopwatch()..start();
      store.insertAll(batchData);
      batchInsertStopwatch.stop();

      final individualInsertStopwatch = Stopwatch()..start();
      final individualStore = InMemoryStore<String, int>.persistent();
      for (var i = 0; i < batchSize; i++) {
        individualStore.insert('key$i', i);
      }
      individualInsertStopwatch.stop();

      expect(store.length, batchSize);
      expect(individualStore.length, batchSize);
      expect(batchInsertStopwatch.elapsedMicroseconds, lessThan(10000000));
      expect(individualInsertStopwatch.elapsedMicroseconds, lessThan(10000000));
    });

    test('LRU eviction performance with large dataset', () {
      const maxEntries = 1000;
      const totalEntries = 2000;

      final store = InMemoryStore<int, String>.forLargeDatasets(
        maxEntries: maxEntries,
      );

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < totalEntries; i++) {
        store.insert(i, 'value$i');
      }
      stopwatch.stop();

      expect(store.length, maxEntries);
      expect(stopwatch.elapsedMicroseconds, lessThan(1000000));
    });

    test('Expiry cleanup performance', () async {
      const entries = 1000;
      final store = InMemoryStore<String, int>.withExpiry(
        expiryDuration: const Duration(milliseconds: 10),
        cleanupInterval: const Duration(seconds: 10),
      );

      for (var i = 0; i < entries; i++) {
        store.insert('key$i', i);
      }

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final stopwatch = Stopwatch()..start();
      final cleanedCount = store.cleanup();
      stopwatch.stop();

      expect(cleanedCount, greaterThan(0));
      expect(stopwatch.elapsedMicroseconds, lessThan(500000));
    });

    test('Memory efficiency with large values', () {
      const entries = 1000;
      final store = InMemoryStore<String, List<int>>.persistent();

      final largeValue = List.generate(1000, (i) => i);

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < entries; i++) {
        store.insert('key$i', largeValue);
      }
      stopwatch.stop();

      expect(store.length, entries);
      expect(stopwatch.elapsedMicroseconds, lessThan(1000000));
    });

    test('Access pattern performance for LRU', () {
      const maxEntries = 100;
      final store = InMemoryStore<int, String>.persistent(
        maxEntries: maxEntries,
      );

      for (var i = 0; i < maxEntries; i++) {
        store.insert(i, 'value$i');
      }

      final accessStopwatch = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        store.get(i % maxEntries);
      }
      accessStopwatch.stop();

      expect(accessStopwatch.elapsedMicroseconds, lessThan(100000));
    });

    test('Concurrent access simulation', () {
      final store = InMemoryStore<String, int>.persistent(maxEntries: 1000);
      const operations = 10000;

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < operations; i++) {
        final operation = i % 4;
        switch (operation) {
          case 0:
            store.insert('key${i % 500}', i);
          case 1:
            store.get('key${i % 500}');
          case 2:
            store.containsKey('key${i % 500}');
          case 3:
            store.remove('key${i % 500}');
        }
      }
      stopwatch.stop();

      expect(stopwatch.elapsedMicroseconds, lessThan(2000000));
    });

    test('Stats retrieval performance', () {
      final store = InMemoryStore<String, int>.withExpiry(
        expiryDuration: const Duration(minutes: 5),
        maxEntries: 1000,
      );

      for (var i = 0; i < 100; i++) {
        store.insert('key$i', i);
      }

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        store.stats;
      }
      stopwatch.stop();

      expect(stopwatch.elapsedMicroseconds, lessThan(50000));
    });
  });
}

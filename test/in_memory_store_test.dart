import 'package:in_memory_store/in_memory_store.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryStore Basic Operations', () {
    test('should insert and retrieve a value', () {
      final store = InMemoryStore<String, String>.persistent()
        ..insert('key1', 'value1');
      expect(store.get('key1'), 'value1');
    });

    test('should return null for a non-existent key', () {
      final store = InMemoryStore<String, String>.persistent();
      expect(store.get('key1'), isNull);
    });

    test('should remove a value', () {
      final store = InMemoryStore<String, String>.persistent()
        ..insert('key1', 'value1')
        ..remove('key1');
      expect(store.get('key1'), isNull);
    });

    test('should clear all values', () {
      final store = InMemoryStore<String, String>.persistent()
        ..insert('key1', 'value1')
        ..insert('key2', 'value2')
        ..clear();
      expect(store.get('key1'), isNull);
      expect(store.get('key2'), isNull);
      expect(store.length, 0);
    });

    test('should contain key after insertion', () {
      final store = InMemoryStore<String, String>.persistent()
        ..insert('key1', 'value1');
      expect(store.containsKey('key1'), isTrue);
    });

    test('should not contain key after removal', () {
      final store = InMemoryStore<String, String>.persistent()
        ..insert('key1', 'value1')
        ..remove('key1');
      expect(store.containsKey('key1'), isFalse);
    });
  });

  group('InMemoryStore Expiry', () {
    test('should expire a value after duration', () async {
      final store = InMemoryStore<String, String>.withExpiry(
        expiryDuration: const Duration(milliseconds: 100),
      )..insert('key1', 'value1');
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(store.get('key1'), isNull);
    });

    test('should reset expiry timer when updating a key', () async {
      final store = InMemoryStore<String, String>.withExpiry(
        expiryDuration: const Duration(milliseconds: 200),
      )..insert('key1', 'value1');

      await Future<void>.delayed(const Duration(milliseconds: 100));
      store.insert('key1', 'value2');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(store.get('key1'), 'value2');

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(store.get('key1'), isNull);
    });

    test('should not contain expired key', () async {
      final store = InMemoryStore<String, String>.withExpiry(
        expiryDuration: const Duration(milliseconds: 100),
      )..insert('key1', 'value1');

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(store.containsKey('key1'), isFalse);
    });

    test('should cleanup expired entries manually', () async {
      final store = InMemoryStore<String, String>.withExpiry(
        expiryDuration: const Duration(milliseconds: 100),
      )
        ..insert('key1', 'value1')
        ..insert('key2', 'value2');

      await Future<void>.delayed(const Duration(milliseconds: 150));
      final cleanedCount = store.cleanup();

      expect(cleanedCount, 2);
      expect(store.length, 0);
    });
  });

  group('InMemoryStore Batch Operations', () {
    test('should insert multiple entries', () {
      final store = InMemoryStore<String, String>.persistent();
      final entries = {'key1': 'value1', 'key2': 'value2', 'key3': 'value3'};

      store.insertAll(entries);

      expect(store.get('key1'), 'value1');
      expect(store.get('key2'), 'value2');
      expect(store.get('key3'), 'value3');
      expect(store.length, 3);
    });

    test('should remove multiple entries', () {
      final store = InMemoryStore<String, String>.persistent()
        ..insert('key1', 'value1')
        ..insert('key2', 'value2')
        ..insert('key3', 'value3')
        ..removeAll(['key1', 'key3']);

      expect(store.get('key1'), isNull);
      expect(store.get('key2'), 'value2');
      expect(store.get('key3'), isNull);
      expect(store.length, 1);
    });

    test('should handle empty batch operations', () {
      final store = InMemoryStore<String, String>.persistent()
        ..insertAll(<String, String>{})
        ..removeAll(<String>[]);

      expect(store.length, 0);
    });
  });

  group('InMemoryStore LRU Eviction', () {
    test('should evict least recently used entries when max entries exceeded',
        () {
      final store = InMemoryStore<String, String>.persistent(maxEntries: 2)
        ..insert('key1', 'value1')
        ..insert('key2', 'value2')
        ..insert('key3', 'value3');

      expect(store.length, 2);
      expect(store.get('key1'), isNull);
      expect(store.get('key2'), 'value2');
      expect(store.get('key3'), 'value3');
    });

    test('should update access time when getting values for LRU', () {
      final store = InMemoryStore<String, String>.persistent(maxEntries: 2)
        ..insert('key1', 'value1')
        ..insert('key2', 'value2')
        ..get('key1')
        ..insert('key3', 'value3');

      expect(store.get('key1'), 'value1');
      expect(store.get('key2'), isNull);
      expect(store.get('key3'), 'value3');
    });

    test('should handle max entries with batch insert', () {
      final store = InMemoryStore<String, String>.persistent(maxEntries: 2)
        ..insertAll({'key1': 'value1', 'key2': 'value2', 'key3': 'value3'});

      expect(store.length, 2);
    });
  });

  group('InMemoryStore Large Datasets', () {
    test('should create store optimized for large datasets', () {
      final store = InMemoryStore<String, String>.forLargeDatasets(
        maxEntries: 1000,
        expiryDuration: const Duration(minutes: 10),
        cleanupInterval: const Duration(minutes: 1),
      );

      expect(store.maxEntries, 1000);
      expect(store.expiryDuration, const Duration(minutes: 10));
      expect(store.cleanupInterval, const Duration(minutes: 1));
    });

    test('should handle large dataset operations efficiently', () {
      final store =
          InMemoryStore<int, String>.forLargeDatasets(maxEntries: 100);

      final entries = <int, String>{};
      for (var i = 0; i < 150; i++) {
        entries[i] = 'value$i';
      }

      store.insertAll(entries);

      expect(store.length, 100);
    });
  });

  group('InMemoryStore Properties and Stats', () {
    test('should return correct keys', () {
      final store = InMemoryStore<String, String>.persistent()
        ..insert('key1', 'value1')
        ..insert('key2', 'value2');

      final keys = store.keys.toList();
      expect(keys.length, 2);
      expect(keys.contains('key1'), isTrue);
      expect(keys.contains('key2'), isTrue);
    });

    test('should return correct values', () {
      final store = InMemoryStore<String, String>.persistent()
        ..insert('key1', 'value1')
        ..insert('key2', 'value2');

      final values = store.values.toList();
      expect(values.length, 2);
      expect(values.contains('value1'), isTrue);
      expect(values.contains('value2'), isTrue);
    });

    test('should return correct length', () {
      final store = InMemoryStore<String, String>.persistent();
      expect(store.length, 0);

      store.insert('key1', 'value1');
      expect(store.length, 1);

      store.insert('key2', 'value2');
      expect(store.length, 2);
    });

    test('should return correct isEmpty status', () {
      final store = InMemoryStore<String, String>.persistent();
      expect(store.isEmpty, isTrue);
      expect(store.isNotEmpty, isFalse);

      store.insert('key1', 'value1');
      expect(store.isEmpty, isFalse);
      expect(store.isNotEmpty, isTrue);
    });

    test('should return correct stats', () {
      final store = InMemoryStore<String, String>.withExpiry(
        expiryDuration: const Duration(minutes: 5),
        maxEntries: 100,
        cleanupInterval: const Duration(minutes: 2),
      )..insert('key1', 'value1');

      final stats = store.stats;
      expect(stats['entries'], 1);
      expect(stats['maxEntries'], 100);
      expect(stats['hasExpiry'], isTrue);
      expect(stats['expiryDurationMs'], 300000);
      expect(stats['cleanupIntervalMs'], 120000);
      expect(stats['accessCounter'], greaterThan(0));
    });
  });

  group('InMemoryStore Resource Management', () {
    test('should dispose resources properly', () {
      final store = InMemoryStore<String, String>.withExpiry(
        expiryDuration: const Duration(minutes: 5),
      )
        ..insert('key1', 'value1')
        ..dispose();

      expect(store.length, 0);
      expect(store.isEmpty, isTrue);
    });

    test('should cancel cleanup timer on clear', () {
      final store = InMemoryStore<String, String>.withExpiry(
        expiryDuration: const Duration(minutes: 5),
      )
        ..insert('key1', 'value1')
        ..clear();

      expect(store.length, 0);
    });
  });

  group('InMemoryStore Edge Cases', () {
    test('should handle null values', () {
      final store = InMemoryStore<String, String?>.persistent()
        ..insert('key1', null);

      expect(store.get('key1'), isNull);
      expect(store.containsKey('key1'), isTrue);
    });

    test('should handle different key types', () {
      final store = InMemoryStore<int, String>.persistent()
        ..insert(1, 'value1')
        ..insert(2, 'value2');

      expect(store.get(1), 'value1');
      expect(store.get(2), 'value2');
    });

    test('should handle overwriting existing keys', () {
      final store = InMemoryStore<String, String>.persistent()
        ..insert('key1', 'value1')
        ..insert('key1', 'value2');

      expect(store.get('key1'), 'value2');
      expect(store.length, 1);
    });

    test('should handle removing non-existent keys', () {
      final store = InMemoryStore<String, String>.persistent()
        ..remove('nonexistent');

      expect(store.length, 0);
    });

    test('should handle cleanup with no expired entries', () {
      final store = InMemoryStore<String, String>.persistent()
        ..insert('key1', 'value1');

      final cleanedCount = store.cleanup();
      expect(cleanedCount, 0);
      expect(store.length, 1);
    });
  });
}

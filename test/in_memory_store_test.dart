import 'package:in_memory_store/in_memory_store.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryStore', () {
    test('should insert and retrieve a value', () {
      final store = InMemoryStore<String, String>.persistent()
        ..insert(
          'key1',
          'value1',
        );
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
    });

    test('should expire a value after duration', () async {
      final store = InMemoryStore<String, String>.withExpiry(
        expiryDuration: const Duration(milliseconds: 100),
      )..insert('key1', 'value1');
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(store.get('key1'), isNull);
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
  });
}

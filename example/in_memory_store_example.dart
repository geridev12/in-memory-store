// ignore_for_file: avoid_print, cascade_invocations

import 'package:in_memory_store/in_memory_store.dart';

void main() {
  final cacheWithExpiry = InMemoryStore<String, String>.withExpiry(
    expiryDuration: const Duration(seconds: 5),
  );
  cacheWithExpiry.insert('user1', 'John Doe');
  print('Inserted: user1 -> John Doe');

  Future<Null>.delayed(
    const Duration(seconds: 6),
    () {
      print('Value after expiry: ${cacheWithExpiry.get('user1')}');
    },
  );

  final persistentCache = InMemoryStore<String, int>.persistent();
  persistentCache.insert('score', 100);
  print('Inserted: score -> 100');
  print('Retrieved: score -> ${persistentCache.get('score')}');

  print('Contains key "score": ${persistentCache.containsKey('score')}');
  print('Contains key "user1": ${persistentCache.containsKey('user1')}');

  persistentCache.remove('score');
  print(
      'Removed key "score". Contains key "score": ${persistentCache.containsKey(
    'score',
  )}');

  persistentCache.insert('temp', 42);
  print('Inserted: temp -> 42');
  print('Cache keys before clear: ${persistentCache.keys.toList()}');
  persistentCache.clear();
  print('Cache keys after clear: ${persistentCache.keys.toList()}');
}

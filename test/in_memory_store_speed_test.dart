// ignore_for_file: avoid_print, unnecessary_statements

import 'dart:collection';
import 'package:test/test.dart';

void main() {
  test(
    'Compare HashMap vs Map performance',
    () {
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

      expect(
        hashMapRetrievalTime,
        lessThan(
          mapRetrievalTime,
        ),
      );
    },
  );
}

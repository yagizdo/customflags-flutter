import 'dart:async';

import 'package:customflags/customflags.dart';
import 'package:customflags/src/cache/flag_cache.dart';
import 'package:customflags/src/cache/flag_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FlagCache — sync reads', () {
    test('[FlagCache] getFlag returns Flag with null value when cache is empty', () {
      final cache = FlagCache(storage: FlagStorage());
      final flag = cache.getFlag('nonexistent');

      expect(flag.key, 'nonexistent');
      expect(flag.value, isNull);
    });

    test('[FlagCache] getFlag returns cached flag after update', () async {
      final cache = FlagCache(storage: FlagStorage());
      final flags = [
        const Flag(key: 'dark_mode', value: true),
        const Flag(key: 'theme', value: 'blue'),
      ];

      await cache.update('user_42', flags);

      expect(cache.getFlag('dark_mode').getBool(), true);
      expect(cache.getFlag('theme').getString(), 'blue');
    });

    test('[FlagCache] getAllFlags returns empty map when cache is empty', () {
      final cache = FlagCache(storage: FlagStorage());
      expect(cache.getAllFlags(), isEmpty);
    });

    test('[FlagCache] getAllFlags returns all cached flags after update', () async {
      final cache = FlagCache(storage: FlagStorage());
      await cache.update('user_42', [
        const Flag(key: 'a', value: 1),
        const Flag(key: 'b', value: 2),
      ]);

      final all = cache.getAllFlags();
      expect(all.length, 2);
      expect(all['a']!.getInt(), 1);
      expect(all['b']!.getInt(), 2);
    });
  });

  group('FlagCache — disk persistence', () {
    test('[FlagCache] update writes to disk and load restores', () async {
      final storage = FlagStorage();
      final cache1 = FlagCache(storage: storage);

      await cache1.update('user_42', [
        const Flag(key: 'dark_mode', value: true),
      ]);

      final cache2 = FlagCache(storage: storage);
      await cache2.load('user_42');

      expect(cache2.getFlag('dark_mode').getBool(), true);
    });

    test('[FlagCache] load populates cache from disk', () async {
      final storage = FlagStorage();
      await storage.write('user_42', {
        'saved': const Flag(key: 'saved', value: 'from_disk'),
      });

      final cache = FlagCache(storage: storage);
      await cache.load('user_42');

      expect(cache.getFlag('saved').getString(), 'from_disk');
    });

    test('[FlagCache] load with no disk data leaves cache empty', () async {
      final cache = FlagCache(storage: FlagStorage());
      await cache.load('nonexistent_user');

      expect(cache.getAllFlags(), isEmpty);
    });
  });

  group('FlagCache — stream notifications', () {
    test('[FlagCache] stream emits after update', () async {
      final cache = FlagCache(storage: FlagStorage());
      final emissions = <Map<String, Flag>>[];
      cache.stream.listen(emissions.add);

      await cache.update('user_42', [
        const Flag(key: 'dark_mode', value: true),
      ]);

      await Future<void>.delayed(Duration.zero);
      expect(emissions.length, 1);
      expect(emissions.first['dark_mode']!.getBool(), true);
    });

    test('[FlagCache] stream emits after load when disk has data', () async {
      final storage = FlagStorage();
      await storage.write('user_42', {
        'flag': const Flag(key: 'flag', value: 'cached'),
      });

      final cache = FlagCache(storage: storage);
      final emissions = <Map<String, Flag>>[];
      cache.stream.listen(emissions.add);

      await cache.load('user_42');

      await Future<void>.delayed(Duration.zero);
      expect(emissions.length, 1);
      expect(emissions.first['flag']!.getString(), 'cached');
    });

    test('[FlagCache] stream does not emit on load when disk is empty', () async {
      final cache = FlagCache(storage: FlagStorage());
      final emissions = <Map<String, Flag>>[];
      cache.stream.listen(emissions.add);

      await cache.load('nonexistent');

      await Future<void>.delayed(Duration.zero);
      expect(emissions, isEmpty);
    });

    test('[FlagCache] multiple listeners receive the same emission', () async {
      final cache = FlagCache(storage: FlagStorage());
      final a = <Map<String, Flag>>[];
      final b = <Map<String, Flag>>[];
      cache.stream.listen(a.add);
      cache.stream.listen(b.add);

      await cache.update('user_42', [
        const Flag(key: 'k', value: true),
      ]);

      await Future<void>.delayed(Duration.zero);
      expect(a.length, 1);
      expect(b.length, 1);
    });
  });

  group('FlagCache — clear', () {
    test('[FlagCache] clear empties in-memory cache', () async {
      final cache = FlagCache(storage: FlagStorage());
      await cache.update('user_42', [
        const Flag(key: 'dark_mode', value: true),
      ]);

      cache.clear();

      expect(cache.getAllFlags(), isEmpty);
      expect(cache.getFlag('dark_mode').value, isNull);
    });
  });

  group('FlagCache — clearAll', () {
    test('[FlagCache] clearAll empties the in-memory cache', () async {
      final cache = FlagCache(storage: FlagStorage());
      await cache.update('user_42', [
        const Flag(key: 'dark_mode', value: true),
      ]);

      await cache.clearAll('user_42');

      expect(cache.getAllFlags(), isEmpty);
      expect(cache.getFlag('dark_mode').value, isNull);
    });

    test('[FlagCache] clearAll removes the disk entry for the identifier', () async {
      final storage = FlagStorage();
      final cache = FlagCache(storage: storage);
      await cache.update('user_42', [
        const Flag(key: 'dark_mode', value: true),
      ]);

      await cache.clearAll('user_42');
      final reloaded = await storage.read('user_42');

      expect(reloaded, isEmpty);
    });

    test('[FlagCache] clearAll emits an empty snapshot on the stream', () async {
      final cache = FlagCache(storage: FlagStorage());
      await cache.update('user_42', [
        const Flag(key: 'dark_mode', value: true),
      ]);

      final emissions = <Map<String, Flag>>[];
      cache.stream.listen(emissions.add);

      await cache.clearAll('user_42');
      await Future<void>.delayed(Duration.zero);

      expect(emissions, isNotEmpty);
      expect(emissions.last, isEmpty);
    });

    test('[FlagCache] clearAll does not clear in-memory or emit when storage throws', () async {
      final cache = FlagCache(storage: _ThrowingStorage());
      await cache.update('user_42', [
        const Flag(key: 'dark_mode', value: true),
      ]);

      final emissions = <Map<String, Flag>>[];
      cache.stream.listen(emissions.add);

      await expectLater(
        cache.clearAll('user_42'),
        throwsA(isA<StateError>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cache.getAllFlags(), isNotEmpty,
          reason: 'in-memory map must remain populated when disk clear fails');
      expect(emissions.where((m) => m.isEmpty), isEmpty,
          reason: 'no empty snapshot must be emitted when disk clear fails');
    });
  });

  group('FlagCache — dispose', () {
    test('[FlagCache] dispose closes the stream', () async {
      final cache = FlagCache(storage: FlagStorage());

      final completer = Completer<void>();
      cache.stream.listen(null, onDone: completer.complete);

      cache.dispose();

      await completer.future;
    });
  });
}

class _ThrowingStorage implements FlagStorage {
  @override
  Future<Map<String, Flag>> read(String identifier) async => {};

  @override
  Future<void> write(String identifier, Map<String, Flag> flags) async {}

  @override
  Future<void> clear(String identifier) async =>
      throw StateError('disk failure');
}

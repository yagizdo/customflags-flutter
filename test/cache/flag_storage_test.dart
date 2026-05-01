import 'package:customflags/customflags.dart';
import 'package:customflags/src/cache/flag_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FlagStorage', () {
    test('[FlagStorage] read returns empty map when nothing is stored', () async {
      final storage = FlagStorage();
      final result = await storage.read('user_42');
      expect(result, isEmpty);
    });

    test('[FlagStorage] write then read returns the stored flags', () async {
      final storage = FlagStorage();
      final flags = {
        'dark_mode': const Flag(key: 'dark_mode', value: true),
        'theme': const Flag(key: 'theme', value: 'blue'),
      };

      await storage.write('user_42', flags);
      final result = await storage.read('user_42');

      expect(result, equals(flags));
    });

    test('[FlagStorage] write overwrites previous data for the same identity', () async {
      final storage = FlagStorage();
      await storage.write('user_42', {
        'old': const Flag(key: 'old', value: 'stale'),
      });
      await storage.write('user_42', {
        'new_key': const Flag(key: 'new_key', value: 'fresh'),
      });

      final result = await storage.read('user_42');
      expect(result.length, 1);
      expect(result['new_key']!.getString(), 'fresh');
    });

    test('[FlagStorage] different identities are isolated', () async {
      final storage = FlagStorage();
      await storage.write('user_a', {
        'flag': const Flag(key: 'flag', value: 'a_value'),
      });
      await storage.write('user_b', {
        'flag': const Flag(key: 'flag', value: 'b_value'),
      });

      final a = await storage.read('user_a');
      final b = await storage.read('user_b');

      expect(a['flag']!.getString(), 'a_value');
      expect(b['flag']!.getString(), 'b_value');
    });

    test('[FlagStorage] clear removes data for the given identity', () async {
      final storage = FlagStorage();
      await storage.write('user_42', {
        'flag': const Flag(key: 'flag', value: true),
      });

      await storage.clear('user_42');
      final result = await storage.read('user_42');

      expect(result, isEmpty);
    });

    test('[FlagStorage] clear does not affect other identities', () async {
      final storage = FlagStorage();
      await storage.write('user_a', {
        'flag': const Flag(key: 'flag', value: 'keep'),
      });
      await storage.write('user_b', {
        'flag': const Flag(key: 'flag', value: 'delete'),
      });

      await storage.clear('user_b');

      expect((await storage.read('user_a')).isNotEmpty, isTrue);
      expect((await storage.read('user_b')).isEmpty, isTrue);
    });

    test('[FlagStorage] round-trips all supported value types', () async {
      final storage = FlagStorage();
      final flags = {
        'b': const Flag(key: 'b', value: true),
        's': const Flag(key: 's', value: 'hello'),
        'i': const Flag(key: 'i', value: 42),
        'd': const Flag(key: 'd', value: 3.14),
        'n': const Flag(key: 'n', value: null),
        'j': const Flag(key: 'j', value: <String, dynamic>{'k': 'v'}),
      };

      await storage.write('user_42', flags);
      final result = await storage.read('user_42');

      expect(result, equals(flags));
    });
  });
}

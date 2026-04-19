import 'dart:convert';
import 'dart:io';

import 'package:customflags/customflags.dart';
import 'package:customflags/src/core/models/flag_response_model.dart';
import 'package:flutter_test/flutter_test.dart';

Future<FlagResponse> _fromFixture(String fileName) async {
  final raw = await File('test/fixtures/$fileName').readAsString();
  return FlagResponse.fromJson(json.decode(raw) as Map<String, dynamic>);
}

FlagResponse _fromInlineJson(String source) {
  return FlagResponse.fromJson(json.decode(source) as Map<String, dynamic>);
}

void main() {
  group('FlagResponse', () {
    test('[FlagResponse] stores flags list when constructed directly', () {
      const a = Flag(key: 'a', value: true);
      const b = Flag(key: 'b', value: 'x');
      const response = FlagResponse(flags: [a, b]);

      expect(response.flags, [a, b]);
    });

    test('[FlagResponse] instances with identical flags are equal', () {
      const a = FlagResponse(flags: [Flag(key: 'k', value: true)]);
      const b = FlagResponse(flags: [Flag(key: 'k', value: true)]);

      expect(a, equals(b));
    });

    test('[FlagResponse] instances with different flags are not equal', () {
      const a = FlagResponse(flags: [Flag(key: 'k', value: true)]);
      const b = FlagResponse(flags: [Flag(key: 'k', value: false)]);

      expect(a, isNot(equals(b)));
    });
  });

  group('FlagResponse.fromJson — invariants (fixture-independent)', () {
    // These tests assert properties that must hold for ANY valid input.
    // The assertion is derived from the input itself, not from the
    // author's hand-picked expected value — so a logic bug that produces
    // a hard-coded output cannot slip through regardless of what we feed.

    test('[FlagResponse] fromJson produces one Flag per input map entry', () {
      final input = <String, dynamic>{
        'a': true,
        'b': 'x',
        'c': 42,
        'd': 3.14,
        'e': <String, dynamic>{'nested': true},
      };

      final response = FlagResponse.fromJson({'flags': input});

      expect(response.flags.length, input.length);
    });

    test('[FlagResponse] fromJson preserves every key-value pair from the input map', () {
      final input = <String, dynamic>{
        'a': true,
        'b': 'x',
        'c': 42,
        'd': 3.14,
        'e': <String, dynamic>{'nested': 'y'},
      };

      final response = FlagResponse.fromJson({'flags': input});

      for (final entry in input.entries) {
        final flag = response.flags.firstWhere((f) => f.key == entry.key);
        expect(flag.value, entry.value);
      }
    });

    test('[FlagResponse] fromJson preserves the full set of input keys', () {
      final keys = <String>{'alpha', 'beta', 'gamma', 'delta'};
      final input = {for (final k in keys) k: true};

      final response = FlagResponse.fromJson({'flags': input});

      expect(response.flags.map((f) => f.key).toSet(), keys);
    });
  });

  group('FlagResponse.fromJson — mixed-type fixture', () {
    // A realistic backend response mixes value types in one payload —
    // bools, strings, numbers, and nested JSON can all sit under
    // different keys of the same "flags" object. This group exercises
    // that shape instead of artificially segregating by type.

    test('[FlagResponse] flags_mixed.json parses one Flag per fixture entry', () async {
      final response = await _fromFixture('flags_mixed.json');
      expect(response.flags.length, 7);
    });

    test('[FlagResponse] flags_mixed.json exposes bool-valued flags via getBool', () async {
      final response = await _fromFixture('flags_mixed.json');

      expect(response.flags.firstWhere((f) => f.key == 'dark_mode').getBool(), true);
      expect(response.flags.firstWhere((f) => f.key == 'notifications_enabled').getBool(), false);
    });

    test('[FlagResponse] flags_mixed.json exposes String-valued flags via getString', () async {
      final response = await _fromFixture('flags_mixed.json');

      expect(response.flags.firstWhere((f) => f.key == 'theme_color').getString(), 'blue');
      expect(response.flags.firstWhere((f) => f.key == 'language').getString(), 'en');
    });

    test('[FlagResponse] flags_mixed.json exposes int-valued flag via getInt', () async {
      final response = await _fromFixture('flags_mixed.json');

      expect(response.flags.firstWhere((f) => f.key == 'max_retries').getInt(), 3);
    });

    test('[FlagResponse] flags_mixed.json exposes double-valued flag via getDouble', () async {
      final response = await _fromFixture('flags_mixed.json');

      expect(response.flags.firstWhere((f) => f.key == 'font_scale').getDouble(), 1.25);
    });

    test('[FlagResponse] flags_mixed.json exposes Map-valued flag via getJson', () async {
      final response = await _fromFixture('flags_mixed.json');
      final config = response.flags.firstWhere((f) => f.key == 'ui_config').getJson();

      expect(config['primary_color'], 'blue');
      expect(config['font_size'], 'large');
    });

    test('[FlagResponse] flags_mixed.json preserves heterogeneous value types side by side', () async {
      // Invariant-style assertion: each key's value type in the parsed
      // output matches what was in the fixture. Catches any accidental
      // type coercion in the dynamic pipeline.
      final response = await _fromFixture('flags_mixed.json');

      expect(response.flags.firstWhere((f) => f.key == 'dark_mode').value, isA<bool>());
      expect(response.flags.firstWhere((f) => f.key == 'theme_color').value, isA<String>());
      expect(response.flags.firstWhere((f) => f.key == 'max_retries').value, isA<int>());
      expect(response.flags.firstWhere((f) => f.key == 'font_scale').value, isA<double>());
      expect(response.flags.firstWhere((f) => f.key == 'ui_config').value, isA<Map<String, dynamic>>());
    });
  });

  group('FlagResponse.fromJson — numeric values (inline)', () {
    test('[FlagResponse] preserves int value through the dynamic pipeline', () {
      final response = _fromInlineJson('{"flags": {"max_retries": 3}}');
      final flag = response.flags.single;

      expect(flag.getInt(), 3);
    });

    test('[FlagResponse] preserves double value through the dynamic pipeline', () {
      final response = _fromInlineJson('{"flags": {"font_scale": 1.25}}');
      final flag = response.flags.single;

      expect(flag.getDouble(), 1.25);
    });

    test('[FlagResponse] allows getDouble on JSON integer values', () {
      // JSON "1" deserializes as int; getDouble widens via num.toDouble().
      final response = _fromInlineJson('{"flags": {"font_scale": 1}}');
      final flag = response.flags.single;

      expect(flag.getDouble(), 1.0);
    });
  });

  group('FlagResponse.fromJson — edge cases', () {
    test('[FlagResponse] empty flags map yields an empty list', () {
      final response = _fromInlineJson('{"flags": {}}');
      expect(response.flags, isEmpty);
    });
  });
}

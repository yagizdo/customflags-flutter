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

  group('FlagResponse.fromJson — bool values', () {
    test('[FlagResponse] flags_bool.json yields two flags', () async {
      final response = await _fromFixture('flags_bool.json');
      expect(response.flags.length, 2);
    });

    test('[FlagResponse] flags_bool.json contains dark_mode=true and notifications=false', () async {
      final response = await _fromFixture('flags_bool.json');
      final darkMode = response.flags.firstWhere((f) => f.key == 'dark_mode');
      final notifications =
          response.flags.firstWhere((f) => f.key == 'notifications');

      expect(darkMode.getBool(), true);
      expect(notifications.getBool(), false);
    });
  });

  group('FlagResponse.fromJson — String values', () {
    test('[FlagResponse] flags_string.json yields two flags', () async {
      final response = await _fromFixture('flags_string.json');
      expect(response.flags.length, 2);
    });

    test('[FlagResponse] flags_string.json contains theme_color=blue and language=en', () async {
      final response = await _fromFixture('flags_string.json');
      final theme = response.flags.firstWhere((f) => f.key == 'theme_color');
      final language = response.flags.firstWhere((f) => f.key == 'language');

      expect(theme.getString(), 'blue');
      expect(language.getString(), 'en');
    });
  });

  group('FlagResponse.fromJson — Map values', () {
    test('[FlagResponse] flags_json.json yields one flag', () async {
      final response = await _fromFixture('flags_json.json');
      expect(response.flags.length, 1);
    });

    test('[FlagResponse] flags_json.json ui_config holds primary_color=blue and font_size=large', () async {
      final response = await _fromFixture('flags_json.json');
      final config = response.flags.firstWhere((f) => f.key == 'ui_config');
      final value = config.getJson();

      expect(value['primary_color'], 'blue');
      expect(value['font_size'], 'large');
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

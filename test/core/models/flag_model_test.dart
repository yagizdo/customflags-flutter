import 'package:customflags/customflags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Flag', () {
    test('[Flag] stores key and value when constructed', () {
      const flag = Flag(key: 'dark_mode', value: true);

      expect(flag.key, 'dark_mode');
      expect(flag.value, true);
    });

    test('[Flag] instances with identical key and value are equal', () {
      const a = Flag(key: 'dark_mode', value: true);
      const b = Flag(key: 'dark_mode', value: true);

      expect(a, equals(b));
    });

    test('[Flag] instances with different keys are not equal', () {
      const a = Flag(key: 'dark_mode', value: true);
      const b = Flag(key: 'notifications', value: true);

      expect(a, isNot(equals(b)));
    });

    test('[Flag] instances with different values are not equal', () {
      const a = Flag(key: 'dark_mode', value: true);
      const b = Flag(key: 'dark_mode', value: false);

      expect(a, isNot(equals(b)));
    });

    test('[Flag] instances with structurally equal Map values are equal (deep equality)', () {
      // Map.from forces distinct runtime instances so const canonicalization
      // can't make this test pass via identity. Equatable's deep equality on
      // Map props is what must hold.
      final mapA = Map<String, dynamic>.from({'color': 'blue', 'size': 10});
      final mapB = Map<String, dynamic>.from({'color': 'blue', 'size': 10});
      expect(identical(mapA, mapB), isFalse);

      final flagA = Flag(key: 'ui_config', value: mapA);
      final flagB = Flag(key: 'ui_config', value: mapB);

      expect(flagA, equals(flagB));
    });

    test('[Flag] instances with differing Map contents are not equal', () {
      final flagA = Flag(
        key: 'ui_config',
        value: Map<String, dynamic>.from({'color': 'blue'}),
      );
      final flagB = Flag(
        key: 'ui_config',
        value: Map<String, dynamic>.from({'color': 'red'}),
      );

      expect(flagA, isNot(equals(flagB)));
    });
  });

  group('Flag.getBool', () {
    test('[Flag.getBool] returns true when value is true', () {
      const flag = Flag(key: 'dark_mode', value: true);
      expect(flag.getBool(), true);
    });

    test('[Flag.getBool] returns false when value is false', () {
      const flag = Flag(key: 'dark_mode', value: false);
      expect(flag.getBool(), false);
    });

    test('[Flag.getBool] throws TypeMismatchException when value is a String', () {
      const flag = Flag(key: 'dark_mode', value: 'true');
      expect(flag.getBool, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getBool] throws TypeMismatchException when value is an int', () {
      const flag = Flag(key: 'dark_mode', value: 1);
      expect(flag.getBool, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getBool] exception reports flag key, expected and actual types', () {
      const flag = Flag(key: 'dark_mode', value: 'yes');

      expect(
        flag.getBool,
        throwsA(
          isA<TypeMismatchException>()
              .having((e) => e.flagKey, 'flagKey', 'dark_mode')
              .having((e) => e.expectedType, 'expectedType', bool)
              .having((e) => e.actualType, 'actualType', String),
        ),
      );
    });

    test('[Flag.getBool] throws TypeMismatchException when value is null', () {
      const flag = Flag(key: 'dark_mode', value: null);
      expect(flag.getBool, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getBool] null exception reports flag key and Null type', () {
      const flag = Flag(key: 'dark_mode', value: null);
      expect(
        flag.getBool,
        throwsA(
          isA<TypeMismatchException>()
              .having((e) => e.flagKey, 'flagKey', 'dark_mode')
              .having((e) => e.actualType, 'actualType', Null),
        ),
      );
    });

    test('[Flag.getBool] returns fallback when value is null and fallback is provided', () {
      const flag = Flag(key: 'dark_mode', value: null);
      expect(flag.getBool(fallback: false), false);
    });

    test('[Flag.getBool] returns fallback when value is the wrong type and fallback is provided', () {
      const flag = Flag(key: 'dark_mode', value: 'true');
      expect(flag.getBool(fallback: false), false);
    });

    test('[Flag.getBool] returns the typed value when fallback is provided but value is valid', () {
      const flag = Flag(key: 'dark_mode', value: true);
      expect(flag.getBool(fallback: false), true);
    });

    test('[Flag.getBool] throws TypeMismatchException when fallback is explicitly null', () {
      const flag = Flag(key: 'dark_mode', value: null);
      expect(
        () => flag.getBool(fallback: null),
        throwsA(isA<TypeMismatchException>()),
      );
    });

    test('[Flag.getBool] returns the provided fallback for any non-bool value (invariant)', () {
      // Invariant: for any non-null fallback X, getBool(fallback: X) returns X
      // whenever value is null or non-bool. The assertion is derived from the
      // input (the fallback the caller passed in), not from a magic constant.
      for (final invalid in <Object?>[null, 'true', 0, 1.5, <int>[], <String, int>{}]) {
        final flag = Flag(key: 'k', value: invalid);
        expect(
          flag.getBool(fallback: true),
          true,
          reason: 'getBool should return fallback=true for value=$invalid',
        );
        expect(
          flag.getBool(fallback: false),
          false,
          reason: 'getBool should return fallback=false for value=$invalid',
        );
      }
    });
  });

  group('Flag.getString', () {
    test('[Flag.getString] returns value when value is a String', () {
      const flag = Flag(key: 'theme_color', value: 'blue');
      expect(flag.getString(), 'blue');
    });

    test('[Flag.getString] throws TypeMismatchException when value is a bool', () {
      const flag = Flag(key: 'theme_color', value: true);
      expect(flag.getString, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getString] throws TypeMismatchException when value is an int', () {
      const flag = Flag(key: 'theme_color', value: 42);
      expect(flag.getString, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getString] throws TypeMismatchException when value is null', () {
      const flag = Flag(key: 'theme_color', value: null);
      expect(flag.getString, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getString] returns fallback when value is null and fallback is provided', () {
      const flag = Flag(key: 'theme_color', value: null);
      expect(flag.getString(fallback: 'default'), 'default');
    });

    test('[Flag.getString] returns fallback when value is the wrong type and fallback is provided', () {
      const flag = Flag(key: 'theme_color', value: 42);
      expect(flag.getString(fallback: 'default'), 'default');
    });

    test('[Flag.getString] returns the typed value when fallback is provided but value is valid', () {
      const flag = Flag(key: 'theme_color', value: 'blue');
      expect(flag.getString(fallback: 'default'), 'blue');
    });

    test('[Flag.getString] throws TypeMismatchException when fallback is explicitly null', () {
      const flag = Flag(key: 'theme_color', value: null);
      expect(
        () => flag.getString(fallback: null),
        throwsA(isA<TypeMismatchException>()),
      );
    });

    test('[Flag.getString] returns the provided fallback for any non-String value (invariant)', () {
      for (final invalid in <Object?>[null, true, 0, 1.5, <int>[], <String, int>{}]) {
        final flag = Flag(key: 'k', value: invalid);
        expect(
          flag.getString(fallback: 'X'),
          'X',
          reason: 'getString should return fallback="X" for value=$invalid',
        );
      }
    });
  });

  group('Flag.getInt', () {
    test('[Flag.getInt] returns value when value is an int', () {
      const flag = Flag(key: 'max_retries', value: 3);
      expect(flag.getInt(), 3);
    });

    test('[Flag.getInt] throws TypeMismatchException when value is a double (no silent truncation)', () {
      const flag = Flag(key: 'max_retries', value: 3.7);
      expect(flag.getInt, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getInt] throws TypeMismatchException when value is a String', () {
      const flag = Flag(key: 'max_retries', value: '3');
      expect(flag.getInt, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getInt] throws TypeMismatchException when value is null', () {
      const flag = Flag(key: 'max_retries', value: null);
      expect(flag.getInt, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getInt] returns fallback when value is null and fallback is provided', () {
      const flag = Flag(key: 'max_retries', value: null);
      expect(flag.getInt(fallback: 0), 0);
    });

    test('[Flag.getInt] returns fallback when value is the wrong type and fallback is provided', () {
      const flag = Flag(key: 'max_retries', value: '3');
      expect(flag.getInt(fallback: 0), 0);
    });

    test('[Flag.getInt] returns fallback when value is a double and fallback is provided', () {
      // Doubles are not silently truncated even with fallback — the strict path
      // throws TypeMismatchException, and the fallback path returns the fallback.
      const flag = Flag(key: 'max_retries', value: 3.7);
      expect(flag.getInt(fallback: 5), 5);
    });

    test('[Flag.getInt] returns the typed value when fallback is provided but value is valid', () {
      const flag = Flag(key: 'max_retries', value: 3);
      expect(flag.getInt(fallback: 0), 3);
    });

    test('[Flag.getInt] throws TypeMismatchException when fallback is explicitly null', () {
      const flag = Flag(key: 'max_retries', value: null);
      expect(
        () => flag.getInt(fallback: null),
        throwsA(isA<TypeMismatchException>()),
      );
    });

    test('[Flag.getInt] returns the provided fallback for any non-int value (invariant)', () {
      for (final invalid in <Object?>[null, true, '3', 3.7, <int>[], <String, int>{}]) {
        final flag = Flag(key: 'k', value: invalid);
        expect(
          flag.getInt(fallback: 99),
          99,
          reason: 'getInt should return fallback=99 for value=$invalid',
        );
      }
    });
  });

  group('Flag.getDouble', () {
    test('[Flag.getDouble] returns value when value is a double', () {
      const flag = Flag(key: 'font_scale', value: 1.25);
      expect(flag.getDouble(), 1.25);
    });

    test('[Flag.getDouble] widens int to double when value is an int', () {
      // JSON deserializes whole numbers as int — num check + .toDouble()
      // covers both numeric types without forcing callers to know the
      // wire-level representation.
      const flag = Flag(key: 'font_scale', value: 1);
      expect(flag.getDouble(), 1.0);
    });

    test('[Flag.getDouble] throws TypeMismatchException when value is a String', () {
      const flag = Flag(key: 'font_scale', value: '1.25');
      expect(flag.getDouble, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getDouble] throws TypeMismatchException when value is a bool', () {
      const flag = Flag(key: 'font_scale', value: true);
      expect(flag.getDouble, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getDouble] throws InvalidFlagValueException when value is NaN', () {
      // NaN is num, so a naive `is num` check would let it through. Rejecting
      // it here prevents silent propagation — e.g. NaN > 1.0 evaluates false
      // and surfaces far from the source as a render/layout bug.
      const flag = Flag(key: 'font_scale', value: double.nan);
      expect(flag.getDouble, throwsA(isA<InvalidFlagValueException>()));
    });

    test('[Flag.getDouble] throws InvalidFlagValueException when value is positive infinity', () {
      const flag = Flag(key: 'font_scale', value: double.infinity);
      expect(flag.getDouble, throwsA(isA<InvalidFlagValueException>()));
    });

    test('[Flag.getDouble] throws InvalidFlagValueException when value is negative infinity', () {
      const flag = Flag(key: 'font_scale', value: double.negativeInfinity);
      expect(flag.getDouble, throwsA(isA<InvalidFlagValueException>()));
    });

    test('[Flag.getDouble] non-finite exception message includes the not-finite-number explanation', () {
      const flag = Flag(key: 'font_scale', value: double.nan);
      expect(
        flag.getDouble,
        throwsA(
          isA<InvalidFlagValueException>()
              .having((e) => e.message, 'message', contains('not a finite number')),
        ),
      );
    });

    test('[Flag.getDouble] throws TypeMismatchException when value is null', () {
      const flag = Flag(key: 'font_scale', value: null);
      expect(flag.getDouble, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getDouble] returns fallback when value is null and fallback is provided', () {
      const flag = Flag(key: 'font_scale', value: null);
      expect(flag.getDouble(fallback: 1.0), 1.0);
    });

    test('[Flag.getDouble] returns fallback when value is the wrong type and fallback is provided', () {
      const flag = Flag(key: 'font_scale', value: 'big');
      expect(flag.getDouble(fallback: 1.0), 1.0);
    });

    test('[Flag.getDouble] returns fallback when value is NaN and fallback is provided', () {
      const flag = Flag(key: 'font_scale', value: double.nan);
      expect(flag.getDouble(fallback: 1.0), 1.0);
    });

    test('[Flag.getDouble] returns fallback when value is positive infinity and fallback is provided', () {
      const flag = Flag(key: 'font_scale', value: double.infinity);
      expect(flag.getDouble(fallback: 1.0), 1.0);
    });

    test('[Flag.getDouble] returns the typed value when fallback is provided but value is valid', () {
      const flag = Flag(key: 'font_scale', value: 1.25);
      expect(flag.getDouble(fallback: 0.5), 1.25);
    });

    test('[Flag.getDouble] widens int to double when fallback is provided', () {
      // Numeric widening (int → double) is part of the strict happy path; the
      // fallback should not preempt it.
      const flag = Flag(key: 'font_scale', value: 2);
      expect(flag.getDouble(fallback: 0.5), 2.0);
    });

    test('[Flag.getDouble] throws TypeMismatchException when fallback is explicitly null and value is null', () {
      const flag = Flag(key: 'font_scale', value: null);
      expect(
        () => flag.getDouble(fallback: null),
        throwsA(isA<TypeMismatchException>()),
      );
    });

    test('[Flag.getDouble] throws InvalidFlagValueException when fallback is explicitly null and value is NaN', () {
      // The strict path for non-finite numbers must remain reachable so callers
      // who omit fallback (or pass null) still see the misconfig signal.
      const flag = Flag(key: 'font_scale', value: double.nan);
      expect(
        () => flag.getDouble(fallback: null),
        throwsA(isA<InvalidFlagValueException>()),
      );
    });

    test('[Flag.getDouble] returns the provided fallback for any non-finite or non-num value (invariant)', () {
      for (final invalid in <Object?>[
        null,
        true,
        '1.5',
        double.nan,
        double.infinity,
        double.negativeInfinity,
        <int>[],
        <String, int>{},
      ]) {
        final flag = Flag(key: 'k', value: invalid);
        expect(
          flag.getDouble(fallback: 7.5),
          7.5,
          reason: 'getDouble should return fallback=7.5 for value=$invalid',
        );
      }
    });
  });

  group('Flag.getJson', () {
    test('[Flag.getJson] returns value when value is a Map<String, dynamic>', () {
      const flag = Flag(
        key: 'ui_config',
        value: <String, dynamic>{'color': 'blue', 'size': 10},
      );

      expect(flag.getJson(), <String, dynamic>{'color': 'blue', 'size': 10});
    });

    test('[Flag.getJson] throws TypeMismatchException when value is a String', () {
      const flag = Flag(key: 'ui_config', value: '{}');
      expect(flag.getJson, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getJson] throws TypeMismatchException when value is a List', () {
      const flag = Flag(key: 'ui_config', value: [1, 2, 3]);
      expect(flag.getJson, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getJson] throws TypeMismatchException when value is null', () {
      const flag = Flag(key: 'ui_config', value: null);
      expect(flag.getJson, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getJson] returns fallback when value is null and fallback is provided', () {
      const flag = Flag(key: 'ui_config', value: null);
      expect(
        flag.getJson(fallback: const <String, dynamic>{'theme': 'light'}),
        <String, dynamic>{'theme': 'light'},
      );
    });

    test('[Flag.getJson] returns fallback when value is the wrong type and fallback is provided', () {
      const flag = Flag(key: 'ui_config', value: '{}');
      expect(
        flag.getJson(fallback: const <String, dynamic>{'theme': 'light'}),
        <String, dynamic>{'theme': 'light'},
      );
    });

    test('[Flag.getJson] returns the typed value when fallback is provided but value is valid', () {
      const flag = Flag(
        key: 'ui_config',
        value: <String, dynamic>{'color': 'blue'},
      );
      expect(
        flag.getJson(fallback: const <String, dynamic>{'theme': 'light'}),
        <String, dynamic>{'color': 'blue'},
      );
    });

    test('[Flag.getJson] throws TypeMismatchException when fallback is explicitly null', () {
      const flag = Flag(key: 'ui_config', value: null);
      expect(
        () => flag.getJson(fallback: null),
        throwsA(isA<TypeMismatchException>()),
      );
    });

    test('[Flag.getJson] returns the provided fallback for any non-Map value (invariant)', () {
      const fallback = <String, dynamic>{'k': 'v'};
      for (final invalid in <Object?>[null, true, 'json', 42, 1.5, <int>[1, 2]]) {
        final flag = Flag(key: 'k', value: invalid);
        expect(
          flag.getJson(fallback: fallback),
          fallback,
          reason: 'getJson should return fallback for value=$invalid',
        );
      }
    });
  });

  group('Flag.toJson', () {
    test('[Flag.toJson] serializes key and value to a map', () {
      const flag = Flag(key: 'dark_mode', value: true);
      expect(flag.toJson(), {'key': 'dark_mode', 'value': true});
    });

    test('[Flag.toJson] serializes null value', () {
      const flag = Flag(key: 'missing', value: null);
      expect(flag.toJson(), {'key': 'missing', 'value': null});
    });

    test('[Flag.toJson] serializes Map value', () {
      const flag = Flag(
        key: 'config',
        value: <String, dynamic>{'color': 'blue'},
      );
      expect(flag.toJson(), {
        'key': 'config',
        'value': {'color': 'blue'},
      });
    });

    test('[Flag.toJson] round-trips through fromJson for every supported type (invariant)', () {
      final flags = [
        const Flag(key: 'b', value: true),
        const Flag(key: 's', value: 'hello'),
        const Flag(key: 'i', value: 42),
        const Flag(key: 'd', value: 3.14),
        const Flag(key: 'n', value: null),
        const Flag(key: 'j', value: <String, dynamic>{'k': 'v'}),
      ];
      for (final original in flags) {
        final restored = Flag.fromJson(original.toJson());
        expect(restored, equals(original), reason: 'round-trip failed for $original');
      }
    });
  });

  group('Flag.fromJson', () {
    test('[Flag.fromJson] deserializes key and value from a map', () {
      final flag = Flag.fromJson(const {'key': 'dark_mode', 'value': true});
      expect(flag.key, 'dark_mode');
      expect(flag.value, true);
    });

    test('[Flag.fromJson] deserializes null value', () {
      final flag = Flag.fromJson(const {'key': 'missing', 'value': null});
      expect(flag.key, 'missing');
      expect(flag.value, isNull);
    });

    test('[Flag.fromJson] deserializes Map value', () {
      final flag = Flag.fromJson(const {
        'key': 'config',
        'value': <String, dynamic>{'color': 'blue'},
      });
      expect(flag.getJson(), {'color': 'blue'});
    });
  });
}
